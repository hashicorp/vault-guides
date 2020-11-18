package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/hashicorp/vault/api"

	"database/sql"

	_ "github.com/lib/pq"
)

const functionName = "demo-function"

// Payload captures the basic payload we're sending for demonstration
// Ex: {"payload": "hello"}
type Payload struct {
	Message string `json:"payload"`
}

// String prints the payload recieved
func (m Payload) String() string {
	return m.Message
}

// HandleRequest reads credentials from /tmp and uses them to query the database
// for users. The database is determined by the DATABASE_URL environment
// variable, and the username and password are retrieved from the secret.
func HandleRequest(ctx context.Context, payload Payload) error {
	logger := log.New(os.Stderr, fmt.Sprintf("[%s] ", functionName), 0)
	logger.Println("Received:", payload.String())
	logger.Println("Reading file /tmp/vault_secret.json")
	secretRaw, err := ioutil.ReadFile("/tmp/vault_secret.json")
	if err != nil {
		return fmt.Errorf("error reading file: %w", err)
	}

	// read token
	// tokenRaw, err := ioutil.ReadFile("/tmp/vault/token")
	// if err != nil {
	// 	return fmt.Errorf("error reading file: %w", err)
	// }

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		return errors.New("no DATABASE_URL, exiting")
	}

	// First decode the JSON into a map[string]interface{}
	var secret api.Secret
	b := bytes.NewBuffer(secretRaw)
	dec := json.NewDecoder(b)
	// While decoding JSON values, interpret the integer values as `json.Number`s
	// instead of `float64`.
	dec.UseNumber()

	if err := dec.Decode(&secret); err != nil {
		return err
	}

	// read users from database
	connStr := fmt.Sprintf("postgres://%s:%s@%s/lambdadb?sslmode=disable", secret.Data["username"], secret.Data["password"], dbURL)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return err
	}

	var users []string
	rows, err := db.QueryContext(ctx, "SELECT usename FROM pg_catalog.pg_user")
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		var user string
		if err = rows.Scan(&user); err != nil {
			return err
		}
		users = append(users, user)
	}
	logger.Println("users: ")
	for i := range users {
		logger.Println("    ", users[i])
	}

	return nil
}

func main() {
	lambda.Start(HandleRequest)
}
