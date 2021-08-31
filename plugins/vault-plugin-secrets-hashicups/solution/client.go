package secretsengine

import (
	"errors"

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
	if config == nil {
		return nil, errors.New("client configuration was nil")
	}

	if config.Username == "" {
		return nil, errors.New("client username was not defined")
	}

	if config.Password == "" {
		return nil, errors.New("client password was not defined")
	}

	if config.URL == "" {
		return nil, errors.New("client URL was not defined")
	}

	c, err := hashicups.NewClient(&config.URL, &config.Username, &config.Password)
	if err != nil {
		return nil, err
	}
	return &hashiCupsClient{c}, nil
}
