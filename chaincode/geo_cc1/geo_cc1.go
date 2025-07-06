package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

type Resource struct {
	ResourceID string `json:"resourceID"`
	Amount     string `json:"amount"`
	Start      string `json:"start"`
	End        string `json:"end"`
}

func (s *SmartContract) Init(ctx contractapi.TransactionContextInterface) error {
	return nil
}

func (s *SmartContract) AssignResource(ctx contractapi.TransactionContextInterface, resourceID, amount, start, end string) error {
	resource := Resource{
		ResourceID: resourceID,
		Amount:     amount,
		Start:      start,
		End:        end,
	}

	resourceJSON, err := json.Marshal(resource)
	if err != nil {
		return fmt.Errorf("failed to marshal resource: %v", err)
	}

	err = ctx.GetStub().PutState(resourceID, resourceJSON)
	if err != nil {
		return fmt.Errorf("failed to put resource to world state: %v", err)
	}

	return nil
}

func (s *SmartContract) QueryResource(ctx contractapi.TransactionContextInterface, resourceID string) (string, error) {
	resourceJSON, err := ctx.GetStub().GetState(resourceID)
	if err != nil {
		return "", fmt.Errorf("failed to read from world state: %v", err)
	}
	if resourceJSON == nil {
		return "", fmt.Errorf("resource %s does not exist", resourceID)
	}

	return string(resourceJSON), nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating geo_cc1 chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting geo_cc1 chaincode: %v\n", err)
	}
}
