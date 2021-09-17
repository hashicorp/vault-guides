package mock

import (
	"context"
	"fmt"

	dbplugin "github.com/hashicorp/vault/sdk/database/dbplugin/v5"
	"github.com/hashicorp/vault/sdk/helper/strutil"
	"github.com/hashicorp/vault/sdk/helper/template"
)

const (
	defaultUserCreationCQL   = `CREATE USER '{{username}}' WITH PASSWORD '{{password}}' NOSUPERUSER;`
	defaultUserDeletionCQL   = `DROP USER '{{username}}';`
	defaultChangePasswordCQL = `ALTER USER '{{username}}' WITH PASSWORD '{{password}}';`
	mockTypeName             = "mock"

	defaultUserNameTemplate = `{{ printf "v_%s_%s_%s_%s" (.DisplayName | truncate 15) (.RoleName | truncate 15) (random 20) (unix_time) | truncate 100 | replace "-" "_" | lowercase }}`
)

// backend wraps the backend framework and adds a map for storing key value pairs
type Mock struct {
	*mockConnectionProducer

	usernameProducer template.StringTemplate
}

// New returns a new Mock instance
func New() (interface{}, error) {
	db := new()
	dbType := dbplugin.NewDatabaseErrorSanitizerMiddleware(db, db.secretValues)

	return dbType, nil
}

func new() *Mock {
	connProducer := &mockConnectionProducer{}
	connProducer.Type = mockTypeName

	return &Mock{
		mockConnectionProducer: connProducer,
	}
}

// Initialize the database plugin. This is the equivalent of a constructor for the
// database object itself.
func (m *Mock) Initialize(ctx context.Context, req dbplugin.InitializeRequest) (dbplugin.InitializeResponse, error) {
	usernameTemplate, err := strutil.GetString(req.Config, "username_template")
	if err != nil {
		return dbplugin.InitializeResponse{}, fmt.Errorf("failed to retrieve username_template: %w", err)
	}
	if usernameTemplate == "" {
		usernameTemplate = defaultUserNameTemplate
	}

	up, err := template.NewTemplate(template.Template(usernameTemplate))
	if err != nil {
		return dbplugin.InitializeResponse{}, fmt.Errorf("unable to initialize username template: %w", err)
	}
	m.usernameProducer = up

	return m.mockConnectionProducer.Initialize(ctx, req)
}

// Type returns the Name for the particular database backend implementation.
// This type name is usually set as a constant within the database backend
// implementation, e.g. "mysql" for the MySQL database backend. This is used
// for things like metrics and logging. No behavior is switched on this.
func (n *Mock) Type() (string, error) {
	return mockTypeName, nil
}

// NewUser creates a new user within the database. This user is temporary in that it
// will exist until the TTL expires.
func (m *Mock) NewUser(ctx context.Context, req dbplugin.NewUserRequest) (dbplugin.NewUserResponse, error) {
	m.Lock()
	defer m.Unlock()

	username, err := m.usernameProducer.Generate(req.UsernameConfig)
	if err != nil {
		return dbplugin.NewUserResponse{}, err
	}

	client, err := m.Connection(ctx)
	if err != nil {
		return dbplugin.NewUserResponse{}, err
	}

	user := client.CreateUser(username, req.Password)

	resp := dbplugin.NewUserResponse{
		Username: user.Username,
	}

	return resp, nil
}

// UpdateUser updates an existing user within the database.
func (m *Mock) UpdateUser(ctx context.Context, req dbplugin.UpdateUserRequest) (dbplugin.UpdateUserResponse, error) {
	m.Lock()
	defer m.Unlock()

	if req.Password == nil {
		return dbplugin.UpdateUserResponse{}, fmt.Errorf("no changes requested")
	}

	client, err := m.Connection(ctx)
	if err != nil {
		return dbplugin.UpdateUserResponse{}, err
	}

	err = client.UpdateUser(req.Username, req.Password.NewPassword)
	if err != nil {
		return dbplugin.UpdateUserResponse{}, err
	}

	return dbplugin.UpdateUserResponse{}, nil
}

// DeleteUser from the database. This should not error if the user didn't
// exist prior to this call.
func (m *Mock) DeleteUser(ctx context.Context, req dbplugin.DeleteUserRequest) (dbplugin.DeleteUserResponse, error) {
	m.Lock()
	defer m.Unlock()

	client, err := m.Connection(ctx)
	if err != nil {
		return dbplugin.DeleteUserResponse{}, err
	}

	err = client.DeleteUser(req.Username)
	return dbplugin.DeleteUserResponse{}, err
}
