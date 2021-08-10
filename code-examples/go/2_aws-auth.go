package main

import (
	"fmt"
	"os"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-secure-stdlib/awsutil"
	vault "github.com/hashicorp/vault/api"
)

// Fetches a key-value secret (kv-v2) after authenticating to Vault via AWS IAM,
// one of two auth methods used to authenticate with AWS (the other is EC2 auth).
// A role must first be created in Vault bound to the IAM ARN you wish to authenticate with, like so:
// vault write auth/aws/role/dev-role-iam \
//     auth_type=iam \
//     bound_iam_principal_arn="arn:aws:iam::AWS-ACCOUNT-NUMBER:role/AWS-IAM-ROLE-NAME" \
//     ttl=24h
// Learn more about the available parameters at https://www.vaultproject.io/api/auth/aws#parameters-10
func getSecretWithAWSAuthIAM() (string, error) {
	config := vault.DefaultConfig() // modify for more granular configuration

	client, err := vault.NewClient(config)
	if err != nil {
		return "", fmt.Errorf("unable to initialize Vault client: %w", err)
	}

	logger := hclog.Default()

	// If environment variables are empty, will fall back on other AWS-provided mechanisms to retrieve credentials.
	creds, err := awsutil.RetrieveCreds(os.Getenv("AWS_ACCESS_KEY_ID"), os.Getenv("AWS_SECRET_ACCESS_KEY"), os.Getenv("AWS_SESSION_TOKEN"), logger)
	if err != nil {
		return "", fmt.Errorf("unable to retrieve creds from STS: %w", err)
	}

	// the optional second parameter can be used to help mitigate replay attacks,
	// when the role in Vault is configured with resolve_aws_unique_ids = true: https://www.vaultproject.io/docs/auth/aws#iam-auth-method
	params, err := awsutil.GenerateLoginData(creds, "Replace-With-IAM-Server-Id", os.Getenv("AWS_DEFAULT_REGION"), logger)
	if err != nil {
		return "", err
	}
	if params == nil {
		return "", fmt.Errorf("got nil response from GenerateLoginData")
	}
	params["role"] = "dev-role-iam" // the name of the role in Vault that was created with this IAM principal ARN bound to it

	resp, err := client.Logical().Write("auth/aws/login", params)
	if err != nil {
		return "", fmt.Errorf("unable to log in with AWS IAM auth: %w", err)
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

	// data map can contain more than one key-value pair, in this case we're just grabbing one of them
	key := "password"
	value, ok := data[key].(string)
	if !ok {
		return "", fmt.Errorf("value type assertion failed: %T %#v", data[key], data[key])
	}

	return value, nil
}
