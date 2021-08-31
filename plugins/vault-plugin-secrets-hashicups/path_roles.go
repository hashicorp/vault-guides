package secretsengine

import (
	"time"

	"github.com/hashicorp/vault/sdk/framework"
	"github.com/hashicorp/vault/sdk/logical"
)

// hashiCupsRoleEntry defines the data required
// for a Vault role to access and call the HashiCups
// token endpoints
type hashiCupsRoleEntry struct {
	Username string        `json:"username"`
	UserID   int           `json:"user_id"`
	Token    string        `json:"token"`
	TokenID  string        `json:"token_id"`
	TTL      time.Duration `json:"ttl"`
	MaxTTL   time.Duration `json:"max_ttl"`
}

// toResponseData returns response data for a role
func (r *hashiCupsRoleEntry) toResponseData() map[string]interface{} {
	respData := map[string]interface{}{
		"ttl":      r.TTL.Seconds(),
		"max_ttl":  r.MaxTTL.Seconds(),
		"username": r.Username,
	}
	return respData
}

// pathRole extends the Vault API with a `/role`
// endpoint for the backend. You can choose whether
// or not certain attributes should be displayed,
// required, and named. You can also define different
// path patterns to list all roles.
func pathRole(b *hashiCupsBackend) []*framework.Path {
	return []*framework.Path{
		{
			Pattern:         "role/" + framework.GenericNameRegex("name"),
			Fields:          map[string]*framework.FieldSchema{},
			Operations:      map[logical.Operation]framework.OperationHandler{},
			HelpSynopsis:    pathRoleHelpSynopsis,
			HelpDescription: pathRoleHelpDescription,
		},
		{
			Pattern:         "role/?$",
			Operations:      map[logical.Operation]framework.OperationHandler{},
			HelpSynopsis:    pathRoleListHelpSynopsis,
			HelpDescription: pathRoleListHelpDescription,
		},
	}
}

const (
	pathRoleHelpSynopsis    = `Manages the Vault role for generating HashiCups tokens.`
	pathRoleHelpDescription = `
This path allows you to read and write roles used to generate HashiCups tokens.
You can configure a role to manage a user's token by setting the username field.
`

	pathRoleListHelpSynopsis    = `List the existing roles in HashiCups backend`
	pathRoleListHelpDescription = `Roles will be listed by the role name.`
)
