package secretsengine

import (
	"context"
	"os"
	"testing"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vault/sdk/logical"
	"github.com/stretchr/testify/require"
)

const (
	envVarRunAccTests       = "VAULT_ACC"
	envVarHashiCupsUsername = "TEST_HASHICUPS_USERNAME"
	envVarHashiCupsPassword = "TEST_HASHICUPS_PASSWORD"
	envVarHashiCupsURL      = "TEST_HASHICUPS_URL"
)

// getTestBackend will help you construct a test backend object.
// Update this function with your target backend.
func getTestBackend(tb testing.TB) (*hashiCupsBackend, logical.Storage) {
	tb.Helper()

	config := logical.TestBackendConfig()
	config.StorageView = new(logical.InmemStorage)
	config.Logger = hclog.NewNullLogger()
	config.System = logical.TestSystemView()

	b, err := Factory(context.Background(), config)
	if err != nil {
		tb.Fatal(err)
	}

	return b.(*hashiCupsBackend), config.StorageView
}

// runAcceptanceTests will separate unit tests from
// acceptance tests, which will make active requests
// to your target API.
var runAcceptanceTests = os.Getenv(envVarRunAccTests) == "1"

// testEnv creates an object to store and track testing environment
// resources
type testEnv struct {
	Username string
	Password string
	URL      string

	Backend logical.Backend
	Context context.Context
	Storage logical.Storage

	// SecretToken tracks the API token, for checking rotations
	SecretToken string

	// Tokens tracks the generated tokens, to make sure we clean up
	Tokens []string
}

// AddConfig adds the configuration to the test backend.
// Make sure data includes all of the configuration
// attributes you need and the `config` path!
func (e *testEnv) AddConfig(t *testing.T) {
	req := &logical.Request{
		Operation: logical.CreateOperation,
		Path:      "config",
		Storage:   e.Storage,
		Data: map[string]interface{}{
			"username": e.Username,
			"password": e.Password,
			"url":      e.URL,
		},
	}
	resp, err := e.Backend.HandleRequest(e.Context, req)
	require.Nil(t, resp)
	require.Nil(t, err)
}

// AddUserTokenRole adds a role for the HashiCups
// user token.
func (e *testEnv) AddUserTokenRole(t *testing.T) {
	req := &logical.Request{
		Operation: logical.UpdateOperation,
		Path:      "role/test-user-token",
		Storage:   e.Storage,
		Data: map[string]interface{}{
			"username": e.Username,
		},
	}
	resp, err := e.Backend.HandleRequest(e.Context, req)
	require.Nil(t, resp)
	require.Nil(t, err)
}

// ReadUserToken retrieves the user token
// based on a Vault role.
func (e *testEnv) ReadUserToken(t *testing.T) {
	req := &logical.Request{
		Operation: logical.ReadOperation,
		Path:      "creds/test-user-token",
		Storage:   e.Storage,
	}
	resp, err := e.Backend.HandleRequest(e.Context, req)
	require.Nil(t, err)
	require.NotNil(t, resp)

	if t, ok := resp.Data["token"]; ok {
		e.Tokens = append(e.Tokens, t.(string))
	}
	require.NotEmpty(t, resp.Data["token"])

	if e.SecretToken != "" {
		require.NotEqual(t, e.SecretToken, resp.Data["token"])
	}

	// collect secret IDs to revoke at end of test
	require.NotNil(t, resp.Secret)
	if t, ok := resp.Secret.InternalData["token"]; ok {
		e.SecretToken = t.(string)
	}
}

// CleanupUserTokens removes the tokens
// when the test completes.
func (e *testEnv) CleanupUserTokens(t *testing.T) {
	if len(e.Tokens) == 0 {
		t.Fatalf("expected 2 tokens, got: %d", len(e.Tokens))
	}

	for _, token := range e.Tokens {
		b := e.Backend.(*hashiCupsBackend)
		client, err := b.getClient(e.Context, e.Storage)
		if err != nil {
			t.Fatal("fatal getting client")
		}
		client.Client.Token = string(token)
		if err := client.SignOut(); err != nil {
			t.Fatalf("unexpected error deleting user token: %s", err)
		}
	}
}
