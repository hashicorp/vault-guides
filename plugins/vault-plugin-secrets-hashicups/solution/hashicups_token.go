package secretsengine

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
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
	return &framework.Secret{
		Type: hashiCupsTokenType,
		Fields: map[string]*framework.FieldSchema{
			"token": {
				Type:        framework.TypeString,
				Description: "HashiCups Token",
			},
		},
		Revoke: b.tokenRevoke,
		Renew:  b.tokenRenew,
	}
}

// tokenRevoke removes the token from the Vault storage API and calls the client to revoke the token
func (b *hashiCupsBackend) tokenRevoke(ctx context.Context, req *logical.Request, d *framework.FieldData) (*logical.Response, error) {
	client, err := b.getClient(ctx, req.Storage)
	if err != nil {
		return nil, fmt.Errorf("error getting client: %w", err)
	}

	token := ""
	// We passed the token using InternalData from when we first created
	// the secret. This is because the HashiCups API uses the exact token
	// for revocation. From a security standpoint, your target API and client
	// should use a token ID instead!
	tokenRaw, ok := req.Secret.InternalData["token"]
	if ok {
		token, ok = tokenRaw.(string)
		if !ok {
			return nil, fmt.Errorf("invalid value for token in secret internal data")
		}
	}

	if err := deleteToken(ctx, client, token); err != nil {
		return nil, fmt.Errorf("error revoking user token: %w", err)
	}
	return nil, nil
}

// tokenRenew calls the client to create a new token and stores it in the Vault storage API
func (b *hashiCupsBackend) tokenRenew(ctx context.Context, req *logical.Request, d *framework.FieldData) (*logical.Response, error) {
	roleRaw, ok := req.Secret.InternalData["role"]
	if !ok {
		return nil, fmt.Errorf("secret is missing role internal data")
	}

	// get the role entry
	role := roleRaw.(string)
	roleEntry, err := b.getRole(ctx, req.Storage, role)
	if err != nil {
		return nil, fmt.Errorf("error retrieving role: %w", err)
	}

	if roleEntry == nil {
		return nil, errors.New("error retrieving role: role is nil")
	}

	resp := &logical.Response{Secret: req.Secret}

	if roleEntry.TTL > 0 {
		resp.Secret.TTL = roleEntry.TTL
	}
	if roleEntry.MaxTTL > 0 {
		resp.Secret.MaxTTL = roleEntry.MaxTTL
	}

	return resp, nil
}

// createToken calls the HashiCups client to sign in and returns a new token
func createToken(ctx context.Context, c *hashiCupsClient, username string) (*hashiCupsToken, error) {
	response, err := c.SignIn()
	if err != nil {
		return nil, fmt.Errorf("error creating HashiCups token: %w", err)
	}

	tokenID := uuid.New().String()

	return &hashiCupsToken{
		UserID:   response.UserID,
		Username: username,
		TokenID:  tokenID,
		Token:    response.Token,
	}, nil
}

// deleteToken calls the HashiCups client to sign out and revoke the token
func deleteToken(ctx context.Context, c *hashiCupsClient, token string) error {
	c.Client.Token = token
	err := c.SignOut()

	if err != nil {
		return nil
	}

	return nil
}
