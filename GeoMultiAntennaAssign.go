package main

import (
	"encoding/json"
	"fmt"
	"math"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// GeoMultiAntennaAssign defines the Smart Contract structure
type GeoMultiAntennaAssign struct {
	contractapi.Contract
}

// Antenna represents an antenna with coordinates
type Antenna struct {
	ID string  `json:"id"`
	X  float64 `json:"x"`
	Y  float64 `json:"y"`
}

// User represents a user or IoT device with coordinates and assigned antennas
type User struct {
	ID         string   `json:"id"`
	X          float64  `json:"x"`
	Y          float64  `json:"y"`
	AntennaIDs []string `json:"antennaIDs"`
}

// RegisterAntenna registers an antenna with its coordinates
func (s *GeoMultiAntennaAssign) RegisterAntenna(ctx contractapi.TransactionContextInterface, antennaID string, x, y float64) error {
	antenna := Antenna{
		ID: antennaID,
		X:  x,
		Y:  y,
	}
	antennaJSON, err := json.Marshal(antenna)
	if err != nil {
		return fmt.Errorf("failed to marshal antenna: %v", err)
	}
	return ctx.GetStub().PutState("ANTENNA_"+antennaID, antennaJSON)
}

// RegisterUser registers a user or IoT device with its coordinates
func (s *GeoMultiAntennaAssign) RegisterUser(ctx contractapi.TransactionContextInterface, userID string, x, y float64) error {
	user := User{
		ID:         userID,
		X:          x,
		Y:          y,
		AntennaIDs: []string{},
	}
	userJSON, err := json.Marshal(user)
	if err != nil {
		return fmt.Errorf("failed to marshal user: %v", err)
	}
	return ctx.GetStub().PutState("USER_"+userID, userJSON)
}

// AssignToMultipleAntennas assigns a user to the top N nearest antennas
func (s *GeoMultiAntennaAssign) AssignToMultipleAntennas(ctx contractapi.TransactionContextInterface, userID string, numAntennas int) error {
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

	type antennaDistance struct {
		ID       string
		Distance float64
	}
	var distances []antennaDistance

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
		distances = append(distances, antennaDistance{ID: antenna.ID, Distance: distance})
	}

	if len(distances) < numAntennas {
		return fmt.Errorf("not enough antennas available")
	}

	// Sort by distance
	for i := 0; i < len(distances)-1; i++ {
		for j := i + 1; j < len(distances); j++ {
			if distances[i].Distance > distances[j].Distance {
				distances[i], distances[j] = distances[j], distances[i]
			}
		}
	}

	user.AntennaIDs = []string{}
	for i := 0; i < numAntennas && i < len(distances); i++ {
		user.AntennaIDs = append(user.AntennaIDs, distances[i].ID)
	}

	userJSON, err := json.Marshal(user)
	if err != nil {
		return fmt.Errorf("failed to marshal updated user: %v", err)
	}
	return ctx.GetStub().PutState("USER_"+userID, userJSON)
}

// QueryAssignment queries the assigned antennas for a user
func (s *GeoMultiAntennaAssign) QueryAssignment(ctx contractapi.TransactionContextInterface, userID string) ([]string, error) {
	userBytes, err := ctx.GetStub().GetState("USER_" + userID)
	if err != nil {
		return nil, fmt.Errorf("failed to read user %s: %v", userID, err)
	}
	if userBytes == nil {
		return nil, fmt.Errorf("user %s does not exist", userID)
	}

	var user User
	err = json.Unmarshal(userBytes, &user)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal user: %v", err)
	}
	return user.AntennaIDs, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&GeoMultiAntennaAssign{})
	if err != nil {
		fmt.Printf("Error creating GeoMultiAntennaAssign chaincode: %v", err)
		return
	}
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting GeoMultiAntennaAssign chaincode: %v", err)
	}
}
