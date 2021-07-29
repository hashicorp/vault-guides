package secretsengine

import (
	"fmt"
	"os"
	"sync"
	"testing"

	stepwise "github.com/hashicorp/vault-testing-stepwise"
	dockerEnvironment "github.com/hashicorp/vault-testing-stepwise/environments/docker"
	"github.com/hashicorp/vault/api"
	"github.com/stretchr/testify/require"
)

// TestAccUserToken runs a series of acceptance tests to check the
// end-to-end workflow of the backend. It creates a Vault Docker container
// and loads a temporary plugin.
func TestAccUserToken(t *testing.T) {
	t.Parallel()
	if !runAcceptanceTests {
		t.SkipNow()
	}
	envOptions := &stepwise.MountOptions{
		RegistryName:    "hashicups",
		PluginType:      stepwise.PluginTypeSecrets,
		PluginName:      "vault-plugin-secrets-hashicups",
		MountPathPrefix: "hashicups",
	}

	roleName := "vault-stepwise-user-role"
	username := os.Getenv(envVarHashiCupsUsername)

	cred := new(string)
	stepwise.Run(t, stepwise.Case{
		Precheck:    func() { testAccPreCheck(t) },
		Environment: dockerEnvironment.NewEnvironment("hashicups", envOptions),
		Steps: []stepwise.Step{
			testAccConfig(t),
			testAccUserRole(t, roleName, username),
			testAccUserRoleRead(t, roleName, username),
			testAccUserCredRead(t, roleName, cred),
		},
	})
}

var initSetup sync.Once

func testAccPreCheck(t *testing.T) {
	initSetup.Do(func() {
		// Ensure test variables are set
		if v := os.Getenv(envVarHashiCupsUsername); v == "" {
			t.Skip(fmt.Printf("%s not set", envVarHashiCupsUsername))
		}
		if v := os.Getenv(envVarHashiCupsPassword); v == "" {
			t.Skip(fmt.Printf("%s not set", envVarHashiCupsPassword))
		}
		if v := os.Getenv(envVarHashiCupsURL); v == "" {
			t.Skip(fmt.Printf("%s not set", envVarHashiCupsURL))
		}
	})
}

func testAccConfig(t *testing.T) stepwise.Step {
	return stepwise.Step{
		Operation: stepwise.UpdateOperation,
		Path:      "config",
		Data: map[string]interface{}{
			"username": os.Getenv(envVarHashiCupsUsername),
			"password": os.Getenv(envVarHashiCupsPassword),
			"url":      os.Getenv(envVarHashiCupsURL),
		},
	}
}

func testAccUserRole(t *testing.T, roleName, username string) stepwise.Step {
	return stepwise.Step{
		Operation: stepwise.UpdateOperation,
		Path:      "role/" + roleName,
		Data: map[string]interface{}{
			"username": username,
			"ttl":      "1m",
			"max_ttl":  "5m",
		},
		Assert: func(resp *api.Secret, err error) error {
			require.Nil(t, resp)
			require.Nil(t, err)
			return nil
		},
	}
}

func testAccUserRoleRead(t *testing.T, roleName, username string) stepwise.Step {
	return stepwise.Step{
		Operation: stepwise.ReadOperation,
		Path:      "role/" + roleName,
		Assert: func(resp *api.Secret, err error) error {
			require.NotNil(t, resp)
			require.Equal(t, username, resp.Data["username"])
			return nil
		},
	}
}

func testAccUserCredRead(t *testing.T, roleName string, userToken *string) stepwise.Step {
	return stepwise.Step{
		Operation: stepwise.ReadOperation,
		Path:      "creds/" + roleName,
		Assert: func(resp *api.Secret, err error) error {
			require.NotNil(t, resp)
			require.NotEmpty(t, resp.Data["token"])
			*userToken = resp.Data["token"].(string)
			return nil
		},
	}
}
