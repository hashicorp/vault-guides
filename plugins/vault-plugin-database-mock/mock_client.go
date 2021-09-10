package mock

import "fmt"

type mockUser struct {
	Username string
	Password string
}

// A mock database client used as an example, in a real world this
// would be an external library provided by a database provider.
type MockClient struct {
	Username string
	Password string
	URL      string
	users    map[string]mockUser
}

func NewMockClient(url, username, password string) (MockClient, error) {
	return MockClient{URL: url, Username: username, Password: password, users: make(map[string]mockUser)}, nil
}

func (c *MockClient) CreateUser(username, password string) mockUser {
	user := mockUser{Username: username, Password: password}
	c.users[username] = user
	return user
}

func (c *MockClient) UpdateUser(username, password string) error {
	if val, ok := c.users[username]; ok {
		val.Password = password
		c.users[username] = val
		return nil
	}

	return fmt.Errorf("user does not exist")
}

func (c *MockClient) DeleteUser(username string) error {
	if _, ok := c.users[username]; ok {
		delete(c.users, username)
		return nil
	}

	return fmt.Errorf("user does not exist")
}
