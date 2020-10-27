package mock

import (
	"context"
	"crypto/subtle"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/hashicorp/vault/sdk/framework"
	"github.com/hashicorp/vault/sdk/logical"
)

// backend wraps the backend framework and adds a map for storing key value pairs.
type backend struct {
	*framework.Backend

	users map[string]string
}

var _ logical.Factory = Factory

// Factory configures and returns Mock backends
func Factory(ctx context.Context, conf *logical.BackendConfig) (logical.Backend, error) {
	b, err := newBackend()
	if err != nil {
		return nil, err
	}

	if conf == nil {
		return nil, fmt.Errorf("configuration passed into backend is nil")
	}

	if err := b.Setup(ctx, conf); err != nil {
		return nil, err
	}

	return b, nil
}

func newBackend() (*backend, error) {
	b := &backend{
		users: make(map[string]string),
	}

	b.Backend = &framework.Backend{
		Help:        strings.TrimSpace(mockHelp),
		BackendType: logical.TypeCredential,
		AuthRenew:   b.pathAuthRenew,
		PathsSpecial: &logical.Paths{
			Unauthenticated: []string{
				"login",
			},
		},
		Paths: framework.PathAppend(
			[]*framework.Path{
				b.pathLogin(),
				b.pathUsersList(),
			},
			b.pathUsers(),
		),
	}

	return b, nil
}

func (b *backend) pathLogin() *framework.Path {
	return &framework.Path{
		Pattern: "login$",
		Fields: map[string]*framework.FieldSchema{
			"password": {
				Type:        framework.TypeString,
				Description: "Password to login",
			},
			"user": {
				Type:        framework.TypeString,
				Description: "User to login",
			},
		},
		Operations: map[logical.Operation]framework.OperationHandler{
			logical.UpdateOperation: &framework.PathOperation{
				Callback: b.handleLogin,
				Summary:  "Log in using a username and password",
			},
		},
	}
}

func (b *backend) handleLogin(ctx context.Context, req *logical.Request, data *framework.FieldData) (*logical.Response, error) {
	user := data.Get("user").(string)
	if user == "" {
		return logical.ErrorResponse("user must be provided"), nil
	}

	password := data.Get("password").(string)
	if password == "" {
		return logical.ErrorResponse("password must be provided"), nil
	}

	pw, ok := b.users[user]
	if !ok {
		return nil, logical.ErrPermissionDenied
	}

	if subtle.ConstantTimeCompare([]byte(password), []byte(pw)) != 1 {
		return nil, logical.ErrPermissionDenied
	}

	// Compose the response
	resp := &logical.Response{
		Auth: &logical.Auth{
			InternalData: map[string]interface{}{
				"password": password,
			},
			// Policies can be passed in as a parameter to the request
			Policies: []string{"my-policy", "other-policy"},
			Metadata: map[string]string{
				"user": user,
			},
			// Lease options can be passed in as parameters to the request
			LeaseOptions: logical.LeaseOptions{
				TTL:       30 * time.Second,
				MaxTTL:    60 * time.Minute,
				Renewable: true,
			},
		},
	}

	return resp, nil
}

func (b *backend) pathUsers() []*framework.Path {
	return []*framework.Path{
		{
			Pattern: "user/" + framework.GenericNameRegex("name"),

			Fields: map[string]*framework.FieldSchema{
				"name": {
					Type:        framework.TypeString,
					Description: "Specifies the user name",
				},
				"password": {
					Type:        framework.TypeString,
					Description: "Specifies the password for the user",
				},
			},

			Operations: map[logical.Operation]framework.OperationHandler{
				logical.UpdateOperation: &framework.PathOperation{
					Callback: b.handleUserWrite,
					Summary:  "Adds a new user to the auth method.",
				},
				logical.CreateOperation: &framework.PathOperation{
					Callback: b.handleUserWrite,
					Summary:  "Updates a user on the auth method.",
				},
				logical.DeleteOperation: &framework.PathOperation{
					Callback: b.handleUserDelete,
					Summary:  "Deletes a user on the auth method.",
				},
			},

			ExistenceCheck: b.handleExistenceCheck,
		},
	}
}

func (b *backend) handleExistenceCheck(ctx context.Context, req *logical.Request, data *framework.FieldData) (bool, error) {
	username := data.Get("name").(string)
	_, ok := b.users[username]

	return ok, nil
}

func (b *backend) pathUsersList() *framework.Path {
	return &framework.Path{
		Pattern: "users/?$",
		Operations: map[logical.Operation]framework.OperationHandler{
			logical.ListOperation: &framework.PathOperation{
				Callback: b.handleUsersList,
				Summary:  "List existing users.",
			},
		},
	}
}

func (b *backend) handleUsersList(ctx context.Context, req *logical.Request, data *framework.FieldData) (*logical.Response, error) {
	userList := make([]string, len(b.users))

	i := 0
	for u, _ := range b.users {
		userList[i] = u
		i++
	}

	sort.Strings(userList)

	return logical.ListResponse(userList), nil
}

func (b *backend) handleUserWrite(ctx context.Context, req *logical.Request, data *framework.FieldData) (*logical.Response, error) {
	username := data.Get("name").(string)
	if username == "" {
		return logical.ErrorResponse("user name must be provided"), nil
	}

	password := data.Get("password").(string)
	if password == "" {
		return logical.ErrorResponse("password must be provided"), nil
	}

	// Store kv pairs in map at specified path
	b.users[username] = password

	return nil, nil
}

func (b *backend) handleUserDelete(ctx context.Context, req *logical.Request, data *framework.FieldData) (*logical.Response, error) {
	username := data.Get("name").(string)
	if username == "" {
		return logical.ErrorResponse("user name must be provided"), nil
	}

	// Remove entry for specified path
	delete(b.users, username)

	return nil, nil
}

func (b *backend) pathAuthRenew(ctx context.Context, req *logical.Request, d *framework.FieldData) (*logical.Response, error) {
	username := req.Auth.Metadata["user"]
	pw := req.Auth.InternalData["password"].(string)

	storedPassword, ok := b.users[username]
	if !ok {
		return nil, errors.New("user on the token could not be found")
	}

	if subtle.ConstantTimeCompare([]byte(pw), []byte(storedPassword)) != 1 {
		return nil, errors.New("internal data does not match")
	}

	resp := &logical.Response{Auth: req.Auth}
	resp.Auth.TTL = 30 * time.Second
	resp.Auth.MaxTTL = 60 * time.Minute

	return resp, nil
}

const mockHelp = `
The Mock backend is a dummy auth backend that stores user and password data in
memory and allows for Vault login and token renewal using these credentials.
`
