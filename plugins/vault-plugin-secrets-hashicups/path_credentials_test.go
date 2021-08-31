package secretsengine

import (
	"context"
	"os"
	"testing"
	"time"

	log "github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vault/sdk/helper/logging"
	"github.com/hashicorp/vault/sdk/logical"
)

// newAcceptanceTestEnv creates a test environment for credentials
func newAcceptanceTestEnv() (*testEnv, error) {
	ctx := context.Background()

	maxLease, _ := time.ParseDuration("60s")
	defaultLease, _ := time.ParseDuration("30s")
	conf := &logical.BackendConfig{
		System: &logical.StaticSystemView{
			DefaultLeaseTTLVal: defaultLease,
			MaxLeaseTTLVal:     maxLease,
		},
		Logger: logging.NewVaultLogger(log.Debug),
	}
	b, err := Factory(ctx, conf)
	if err != nil {
		return nil, err
	}
	return &testEnv{
		Username: os.Getenv(envVarHashiCupsUsername),
		Password: os.Getenv(envVarHashiCupsPassword),
		URL:      os.Getenv(envVarHashiCupsURL),
		Backend:  b,
		Context:  ctx,
		Storage:  &logical.InmemStorage{},
	}, nil
}

// TestAcceptanceUserToken tests a series of steps to make
// sure the role and token creation work correctly.
func TestAcceptanceUserToken(t *testing.T) {
	if !runAcceptanceTests {
		t.SkipNow()
	}

	acceptanceTestEnv, err := newAcceptanceTestEnv()
	if err != nil {
		t.Fatal(err)
	}

	t.Run("add config", acceptanceTestEnv.AddConfig)
	t.Run("add user token role", acceptanceTestEnv.AddUserTokenRole)
	t.Run("read user token cred", acceptanceTestEnv.ReadUserToken)
	t.Run("read user token cred", acceptanceTestEnv.ReadUserToken)
	t.Run("cleanup user tokens", acceptanceTestEnv.CleanupUserTokens)
}
