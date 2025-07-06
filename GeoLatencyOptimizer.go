package main

import (
	"encoding/json"
	"fmt"
	"math"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// GeoLatencyOptimizer defines the Smart Contract structure
type GeoLatencyOptimizer struct {
	contractapi.Contract
}

// Antenna represents an antenna with coordinates and latency
type Antenna struct {
	ID      string  `json:"id"`
	X       float64 `json:"x"`
	Y       float64 `json:"y"`
	Latency float64 `json:"latency"`
}

// User represents a user or IoT device with coordinates and assigned antenna
type User struct {
	ID        string `json:"id"`
	X         float64 `json:"x"`
	Y         float64 `json:"y"`
	AntennaID string `json:"antennaID"`
}

// RegisterAntenna registers an antenna with its coordinates and latency
func (s *GeoLatencyOptimizer) RegisterAntenna(ctx contractapi.TransactionContextInterface, antennaID string, x, y, latency float64) error {
	antenna := Antenna{
		ID:      antennaID,
		X:       x,
		Y:       y,
		Latency: latency,
	}
	antennaJSON, err := json.Marshal(antenna)
	if err != nil {
		return fmt.Errorf("failed to marshal antenna: %v", err)
	}
	return ctx.GetStub().PutState("ANTENNA_"+antennaID, antennaJSON)
}

// RegisterUser registers a user or IoT device with its coordinates
func (s *GeoLatencyOptimizer) RegisterUser(ctx contractapi.TransactionContextInterface, userID string, x, y float64) error {
	user := User{
		ID:        userID,
		X:         x,
		Y:         y,
		AntennaID: "",
	}
	userJSON, err := json.Marshal(user)
	if err != nil {
		return fmt.Errorf("failed to marshal user: %v", err)
	}
	return ctx.GetStub().PutState("USER_"+userID, userJSON)
}

// AssignByLatency assigns a user to the antenna with the lowest latency within a distance threshold
func (s *GeoLatencyOptimizer) AssignByLatency(ctx contractapi.TransactionContextInterface, userID string, maxDistance float64) error {
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

	var bestAntennaID string
	minLatency := math.MaxFloat64

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
		if distance <= maxDistance && antenna.Latency < minLatency {
			minLatency = antenna.Latency
			bestAntennaID = antenna.ID
		}
	}

	if bestAntennaID == "" {
		return fmt.Errorf("no suitable antenna found within distance %v", maxDistance)
	}

	user.AntennaID = bestAntennaID
	userJSON, err := json.Marshal(user)
	if err != nil {
		return fmt.Errorf("failed to marshal updated user: %v", err)
	}
	return ctx.GetStub().PutState("USER_"+userID, userJSON)
}

// QueryAssignment queries the assigned antenna for a user
func (s *GeoLatencyOptimizer) QueryAssignment(ctx contractapi.TransactionContextInterface, userID string) (string, error) {
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
	return user.AntennaID, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&GeoLatencyOptimizer{})
	if err != nil {
		fmt.Printf("Error creating GeoLatencyOptimizer chaincode: %v", err)
		return
	}
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting GeoLatencyOptimizer chaincode: %v", err)
	}
}
