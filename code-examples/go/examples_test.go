package main

import (
	"os"
	"testing"
)

var expected = os.Getenv("EXPECTED_SECRET_VALUE")

func TestGetSecret(t *testing.T) {
	value, err := getSecret()
	if err != nil {
		t.Fatalf("Failed to get secret with token: %v", err)
	}
	if value != expected {
		t.Fatalf("Expected %s, but got %s", expected, value)
	}
}

func TestGetSecretWithAppRole(t *testing.T) {
	value, err := getSecretWithAppRole()
	if err != nil {
		t.Fatalf("Failed to get secret with app role: %v", err)
	}
	if value != expected {
		t.Fatalf("Expected %s, but got %s", expected, value)
	}
}
