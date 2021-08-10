// WARNING: The code in this hello-world file is potentially insecure. It is not safe for use in production.
// This is just a quickstart for trying out the Vault client library for the first time.

package main

import (
	"fmt"
	"os"

	vault "github.com/hashicorp/vault/api"
)

// Fetches a key-value secret (kv-v2 secrets engine) after authenticating with a token
func getSecret() (string, error) {
	config := vault.DefaultConfig() // modify for more granular configuration

	client, err := vault.NewClient(config)
	if err != nil {
		return "", fmt.Errorf("unable to initialize Vault client: %w", err)
	}

	// WARNING: Storing any long-lived token with secret access in an environment variable poses a security risk.
	// Additionally, root tokens should never be used in production or against Vault installations containing real secrets.
	// See approle-with-response-wrapping.go for an example of how to use wrapping tokens for greater security.
	client.SetToken(os.Getenv("TOKEN")) // If this line is omitted, Vault will use whatever the env var VAULT_TOKEN is set to.

	secret, err := client.Logical().Read("kv-v2/data/creds")
	if err != nil {
		return "", fmt.Errorf("unable to read secret: %w", err)
	}

	data, ok := secret.Data["data"].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("data type assertion failed: %T %#v", secret.Data["data"], secret.Data["data"])
	}

	// data map can contain more than one key-value pair, in this case we're just grabbing one of them
	key := "password"
	value, ok := data[key].(string)
	if !ok {
		return "", fmt.Errorf("value type assertion failed: %T %#v", data[key], data[key])
	}

	return value, nil
}
