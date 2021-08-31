package secretsengine

import (
	"context"
	"fmt"

	"github.com/hashicorp/vault/sdk/framework"
	"github.com/hashicorp/vault/sdk/logical"
)

const (
	hashiCupsTokenType = "hashicups_token"
)

// hashiCupsToken defines a secret for the HashiCups token
type hashiCupsToken struct {
	UserID   int    `json:"user_id"`
	Username string `json:"username"`
	TokenID  string `json:"token_id"`
	Token    string `json:"token"`
}

// hashiCupsToken defines a secret to store for a given role
// and how it should be revoked or renewed.
func (b *hashiCupsBackend) hashiCupsToken() *framework.Secret {
	return &framework.Secret{}
}

// tokenRevoke removes the token from the Vault storage API and calls the client to revoke the token
func (b *hashiCupsBackend) tokenRevoke(ctx context.Context, req *logical.Request, d *framework.FieldData) (*logical.Response, error) {
	return nil, fmt.Errorf("no user token workflow implemented")
}

// tokenRenew calls the client to create a new token and stores it in the Vault storage API
func (b *hashiCupsBackend) tokenRenew(ctx context.Context, req *logical.Request, d *framework.FieldData) (*logical.Response, error) {
	return nil, nil
}
