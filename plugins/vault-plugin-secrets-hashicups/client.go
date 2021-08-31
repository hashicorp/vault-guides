package secretsengine

import (
	hashicups "github.com/hashicorp-demoapp/hashicups-client-go"
)

// hashiCupsClient creates an object storing
// the client.
type hashiCupsClient struct {
	*hashicups.Client
}

// newClient creates a new client to access HashiCups
// and exposes it for any secrets or roles to use.
func newClient(config *hashiCupsConfig) (*hashiCupsClient, error) {
	return &hashiCupsClient{nil}, nil
}
