package main

import (
	"encoding/json"
	"fmt"
	"math"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// GeoClusterAssign defines the Smart Contract structure
type GeoClusterAssign struct {
	contractapi.Contract
}

// Antenna represents an antenna with coordinates and cluster ID
type Antenna struct {
	ID        string  `json:"id"`
	X         float64 `json:"x"`
	Y         float64 `json:"y"`
	ClusterID string  `json:"clusterID"`
}

// User represents a user or IoT device with coordinates and assigned cluster
type User struct {
	ID        string `json:"id"`
	X         float64 `json:"x"`
	Y         float64 `json:"y"`
	ClusterID string `json:"clusterID"`
}

// RegisterAntenna registers an antenna with its coordinates and cluster ID
func (s *GeoClusterAssign) RegisterAntenna(ctx contractapi.TransactionContextInterface, antennaID string, x, y, clusterID string) error {
	antenna := Antenna{
		ID:        antennaID,
		X:         x,
		Y:         y,
		ClusterID: clusterID,
	}
	antennaJSON, err := json.Marshal(antenna)
	if err != nil {
		return fmt.Errorf("failed to marshal antenna: %v", err)
	}
	return ctx.GetStub().PutState("ANTENNA_"+antennaID, antennaJSON)
}

// RegisterUser registers a user or IoT device with its coordinates
func (s *GeoClusterAssign) RegisterUser(ctx contractapi.TransactionContextInterface, userID string, x, y float64) error {
	user := User{
		ID:        userID,
		X:         x,
		Y:         y,
		ClusterID: "",
	}
	userJSON, err := json.Marshal(user)
	if err != nil {
		return fmt.Errorf("failed to marshal user: %v", err)
	}
	return ctx.GetStub().PutState("USER_"+userID, userJSON)
}

// AssignToCluster assigns a user to the nearest cluster based on antenna coordinates
func (s *GeoClusterAssign) AssignToCluster(ctx contractapi.TransactionContextInterface, userID string) error {
	userBytes, err := ctx.GetStub().GetState("USER_" + userID)
	if err != nil {
		return fmt.Errorf("failed to read user %s: %v", userID, err)
	}
	if userBytes == nil {
		return fmt.Errorf("user %s does not exist", userID)
	}

	var user User
	err = json.Unmarshal(userBytes, &user)
	if err != nil {
		return fmt.Errorf("failed to unmarshal user: %v", err)
	}

	iterator, err := ctx.GetStub().GetStateByRange("ANTENNA_", "ANTENNA_~")
	if err != nil {
		return fmt.Errorf("failed to get antennas: %v", err)
	}
	defer iterator.Close()

	clusterDistances := make(map[string]float64)
	clusterCounts := make(map[string]int)

	for iterator.HasNext() {
		item, err := iterator.Next()
		if err != nil {
			return fmt.Errorf("failed to iterate antennas: %v", err)
		}
		var antenna Antenna
		err = json.Unmarshal(item.Value, &antenna)
		if err != nil {
			return fmt.Errorf("failed to unmarshal antenna: %v", err)
		}

		distance := math.Sqrt(math.Pow(user.X-antenna.X, 2) + math.Pow(user.Y-antenna.Y, 2))
		if currentDistance, exists := clusterDistances[antenna.ClusterID]; exists {
			clusterDistances[antenna.ClusterID] += distance
			clusterCounts[antenna.ClusterID]++
		} else {
			clusterDistances[antenna.ClusterID] = distance
			clusterCounts[antenna.ClusterID] = 1
		}
	}

	var bestClusterID string
	minAvgDistance := math.MaxFloat64

	for clusterID, totalDistance := range clusterDistances {
		avgDistance := totalDistance / float64(clusterCounts[clusterID])
		if avgDistance < minAvgDistance {
			minAvgDistance = avgDistance
			bestClusterID = clusterID
		}
	}

	if bestClusterID == "" {
		return fmt.Errorf("no clusters found")
	}

	user.ClusterID = bestClusterID
	userJSON, err := json.Marshal(user)
	if err != nil {
		return fmt.Errorf("failed to marshal updated user: %v", err)
	}
	return ctx.GetStub().PutState("USER_"+userID, userJSON)
}

// QueryAssignment queries the assigned cluster for a user
func (s *GeoClusterAssign) QueryAssignment(ctx contractapi.TransactionContextInterface, userID string) (string, error) {
	userBytes, err := ctx.GetStub().GetState("USER_" + userID)
	if err != nil {
		return "", fmt.Errorf("failed to read user %s: %v", userID, err)
	}
	if userBytes == nil {
		return "", fmt.Errorf("user %s does not exist", userID)
	}

	var user User
	err = json.Unmarshal(userBytes, &user)
	if err != nil {
		return "", fmt.Errorf("failed to unmarshal user: %v", err)
	}
	return user.ClusterID, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&GeoClusterAssign{})
	if err != nil {
		fmt.Printf("Error creating GeoClusterAssign chaincode: %v", err)
		return
	}
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting GeoClusterAssign chaincode: %v", err)
	}
}
