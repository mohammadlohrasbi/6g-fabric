package main

import (
	"encoding/json"
	"fmt"
	"math"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// AntennaLoadBalancer defines the Smart Contract structure
type AntennaLoadBalancer struct {
	contractapi.Contract
}

// Antenna represents an antenna with coordinates and load capacity
type Antenna struct {
	ID        string  `json:"id"`
	X         float64 `json:"x"`
	Y         float64 `json:"y"`
	MaxLoad   float64 `json:"maxLoad"`
	CurrentLoad float64 `json:"currentLoad"`
}

// User represents a user or IoT device with coordinates and assigned antenna
type User struct {
	ID        string `json:"id"`
	X         float64 `json:"x"`
	Y         float64 `json:"y"`
	AntennaID string `json:"antennaID"`
}

// RegisterAntenna registers an antenna with its coordinates and max load
func (s *AntennaLoadBalancer) RegisterAntenna(ctx contractapi.TransactionContextInterface, antennaID string, x, y, maxLoad float64) error {
	antenna := Antenna{
		ID:        antennaID,
		X:         x,
		Y:         y,
		MaxLoad:   maxLoad,
		CurrentLoad: 0,
	}
	antennaJSON, err := json.Marshal(antenna)
	if err != nil {
		return fmt.Errorf("failed to marshal antenna: %v", err)
	}
	return ctx.GetStub().PutState("ANTENNA_"+antennaID, antennaJSON)
}

// RegisterUser registers a user or IoT device with its coordinates
func (s *AntennaLoadBalancer) RegisterUser(ctx contractapi.TransactionContextInterface, userID string, x, y float64) error {
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

// AssignToBalancedAntenna assigns a user to an antenna considering load balance
func (s *AntennaLoadBalancer) AssignToBalancedAntenna(ctx contractapi.TransactionContextInterface, userID string, userLoad float64) error {
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
	minScore := math.MaxFloat64

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

		if antenna.CurrentLoad+userLoad > antenna.MaxLoad {
			continue
		}

		distance := math.Sqrt(math.Pow(user.X-antenna.X, 2) + math.Pow(user.Y-antenna.Y, 2))
		if distance == 0 {
			distance = 0.01
		}
		loadRatio := antenna.CurrentLoad / antenna.MaxLoad
		score := distance * (1 + loadRatio)
		if score < minScore {
			minScore = score
			bestAntennaID = antenna.ID
		}
	}

	if bestAntennaID == "" {
		return fmt.Errorf("no suitable antenna found")
	}

	antennaBytes, err := ctx.GetStub().GetState("ANTENNA_" + bestAntennaID)
	if err != nil {
		return fmt.Errorf("failed to read antenna %s: %v", bestAntennaID, err)
	}
	var bestAntenna Antenna
	err = json.Unmarshal(antennaBytes, &bestAntenna)
	if err != nil {
		return fmt.Errorf("failed to unmarshal antenna: %v", err)
	}

	bestAntenna.CurrentLoad += userLoad
	antennaJSON, err := json.Marshal(bestAntenna)
	if err != nil {
		return fmt.Errorf("failed to marshal updated antenna: %v", err)
	}
	err = ctx.GetStub().PutState("ANTENNA_"+bestAntennaID, antennaJSON)
	if err != nil {
		return fmt.Errorf("failed to update antenna %s: %v", bestAntennaID, err)
	}

	user.AntennaID = bestAntennaID
	userJSON, err := json.Marshal(user)
	if err != nil {
		return fmt.Errorf("failed to marshal updated user: %v", err)
	}
	return ctx.GetStub().PutState("USER_"+userID, userJSON)
}

// QueryAssignment queries the assigned antenna for a user
func (s *AntennaLoadBalancer) QueryAssignment(ctx contractapi.TransactionContextInterface, userID string) (string, error) {
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
	chaincode, err := contractapi.NewChaincode(&AntennaLoadBalancer{})
	if err != nil {
		fmt.Printf("Error creating AntennaLoadBalancer chaincode: %v", err)
		return
	}
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting AntennaLoadBalancer chaincode: %v", err)
	}
}
