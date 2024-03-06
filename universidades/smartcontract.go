package chaincode

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing an Student
type SmartContract struct {
	contractapi.Contract
}

// Student describes basic details of what makes up a simple student
// Insert struct field in alphabetic order => to achieve determinism across languages
// golang keeps the order when marshal to json but doesn't order automatically
type Student struct {
	ID           string `json:"ID"`
	Name         string `json:"Name"`
	Surname      string `json:"Surname"`
	Country      string `json:"Country"`
	UniversityID string `json:"UniversityID"`
}

// InitLedger adds a base set of students to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	students := []Student{
		{ID: "student1", Name: "Lino", Surname: "Pitini", Country: "Spain", UniversityID: "Madrid1"},
		{ID: "student2", Name: "Jorge", Surname: "Puerta", Country: "Colombia", UniversityID: "Bogota2"},
		{ID: "student3", Name: "Sergio", Surname: "Torres", Country: "Spain", UniversityID: "Madrid1"},
		{ID: "student4", Name: "William", Surname: "Giraldo", Country: "Spain", UniversityID: "Madrid1"},
		{ID: "student5", Name: "Diana", Surname: "Orozco", Country: "Spain", UniversityID: "Madrid1"},
		{ID: "student6", Name: "Cris", Surname: "Michel", Country: "Colombia", UniversityID: "Bogota2"},
	}

	for _, student := range students {
		studentJSON, err := json.Marshal(student)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(student.ID, studentJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// CreateStudent issues a new student to the world state with given details.
func (s *SmartContract) CreateStudent(ctx contractapi.TransactionContextInterface, id string, name string, surname string, country string, universityid string) error {
	exists, err := s.StudentExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the student %s already exists", id)
	}

	student := Student{
		ID:           id,
		Name:         name,
		Surname:      surname,
		Country:      country,
		UniversityID: universityid,
	}
	studentJSON, err := json.Marshal(student)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, studentJSON)
}

// ReadStudent returns the student stored in the world state with given id.
func (s *SmartContract) ReadStudent(ctx contractapi.TransactionContextInterface, id string) (*Student, error) {
	studentJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if studentJSON == nil {
		return nil, fmt.Errorf("the student %s does not exist", id)
	}

	var student Student
	err = json.Unmarshal(studentJSON, &student)
	if err != nil {
		return nil, err
	}

	return &student, nil
}

// UpdateStudent updates an existing student in the world state with provided parameters.
func (s *SmartContract) UpdateStudent(ctx contractapi.TransactionContextInterface, id string, name string, surname string, country string, universityid string) error {
	exists, err := s.StudentExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("the student %s does not exist", id)
	}

	// overwriting original student with new student
	student := Student{
		ID:           id,
		Name:         name,
		Surname:      surname,
		Country:      country,
		UniversityID: universityid,
	}
	studentJSON, err := json.Marshal(student)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, studentJSON)
}

// DeleteStudent deletes an given student from the world state.
func (s *SmartContract) DeleteStudent(ctx contractapi.TransactionContextInterface, id string) error {
	exists, err := s.StudentExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("the student %s does not exist", id)
	}

	return ctx.GetStub().DelState(id)
}

// StudentExists returns true when student with given ID exists in world state
func (s *SmartContract) StudentExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	studentJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return studentJSON != nil, nil
}

// TransferStudent updates the owner field of student with given id in world state, and returns the old university id.
func (s *SmartContract) TransferStudent(ctx contractapi.TransactionContextInterface, id string, newUniversityId string) (string, error) {
	student, err := s.ReadStudent(ctx, id)
	if err != nil {
		return "", err
	}

	oldUniversityID := student.UniversityID
	student.UniversityID = newUniversityId

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return "", err
	}

	err = ctx.GetStub().PutState(id, studentJSON)
	if err != nil {
		return "", err
	}

	return oldUniversityID, nil
}

// GetAllStudents returns all students found in world state
func (s *SmartContract) GetAllStudents(ctx contractapi.TransactionContextInterface) ([]*Student, error) {
	// range query with empty string for startKey and endKey does an
	// open-ended query of all students in the chaincode namespace.
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var students []*Student
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var student Student
		err = json.Unmarshal(queryResponse.Value, &student)
		if err != nil {
			return nil, err
		}
		students = append(students, &student)
	}

	return students, nil
}
