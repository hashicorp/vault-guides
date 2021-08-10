package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	vault "github.com/hashicorp/vault/api"
)

// Fetches a key-value secret (kv-v2) after authenticating via AppRole,
// an auth method used by machines that are unable to use platform-based authentication mechanisms like AWS Auth, Kubernetes Auth, etc.
func getSecretWithAppRole() (string, error) {
	config := vault.DefaultConfig() // modify for more granular configuration

	client, err := vault.NewClient(config)
	if err != nil {
		return "", fmt.Errorf("unable to initialize Vault client: %w", err)
	}

	// A combination of a Role ID and Secret ID is required to log in to Vault with an AppRole.
	// The Secret ID is a value that needs to be protected, so instead of the app having knowledge of the secret ID directly,
	// we have a trusted orchestrator (https://learn.hashicorp.com/tutorials/vault/secure-introduction?in=vault/app-integration#trusted-orchestrator)
	// give the app access to a short-lived response-wrapping token (https://www.vaultproject.io/docs/concepts/response-wrapping).
	// Read more at: https://learn.hashicorp.com/tutorials/vault/approle-best-practices?in=vault/auth-methods#secretid-delivery-best-practices

	wrappingToken, err := ioutil.ReadFile("path/to/wrapping-token") // placed here by a trusted orchestrator
	if err != nil {
		return "", fmt.Errorf("unable to read file containing wrapping token: %w", err)
	}

	unwrappedToken, err := client.Logical().Unwrap(strings.TrimSuffix(string(wrappingToken), "\n"))
	if err != nil {
		// a good opportunity to alert, in case the one-time use wrapping token appears to have already been used
		return "", fmt.Errorf("unable to unwrap token: %w", err)
	}
	secretID := unwrappedToken.Data["secret_id"]

	// the role ID given to you by your administrator
	roleID := os.Getenv("APPROLE_ROLE_ID")
	if roleID == "" {
		return "", fmt.Errorf("no role ID was provided in APPROLE_ROLE_ID env var")
	}

	params := map[string]interface{}{
		"role_id":   roleID,
		"secret_id": secretID,
	}
	resp, err := client.Logical().Write("auth/approle/login", params)
	if err != nil {
		return "", fmt.Errorf("unable to log in with approle: %w", err)
	}
	client.SetToken(resp.Auth.ClientToken)

	secret, err := client.Logical().Read("kv-v2/data/creds")
	if err != nil {
		return "", fmt.Errorf("unable to read secret: %w", err)
	}

	data, ok := secret.Data["data"].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("data type assertion failed: %T %#v", secret.Data["data"], secret.Data["data"])
	}

	key := "password"
	value, ok := data[key].(string)
	if !ok {
		return "", fmt.Errorf("value type assertion failed: %T %#v", data[key], data[key])
	}

	return value, nil
}
