# HashiCorp Vault HTTP Client with .NET Core Example

These assets are provided to perform the tasks described in the [Using Hashicorp Vault HTTP Client with .NET Core]() tutorial.

---

## Requirements

- [Docker Compose](https://docs.docker.com/compose/)
- [Docker](https://docs.docker.com/get-docker/)
- [.NET Core 5.0+](https://dotnet.microsoft.com/download/dotnet/5.0)

## Demo Script Guide

The following files are provided as demo scripts:

- `demo_setup.sh`
  * Pulls and builds a Microsoft SQL Server (MSSQL) database and Vault development instance
  * Enable MSSQL database secrets engine and AppRole auth method
  * Configures the MSSQL database secrets engine at `projects-api/database` to create
    users for the database.
  * Creates a Vault policy to limit access to only retrieving database credentials and
    static secrets
- `run_app.sh`
  * Retrieves a secret ID from Vault
  * Runs the example app
- `cleanup.sh` re-set your environment


### Demo Workflow

> **NOTE:** DON'T FORGET that this demo requires .NET Core and Docker Compose to run the example application!

1. Run `demo_setup.sh`. This creates a Vault instance (in development mode) and
   a Microsoft SQL Server database with a table prepopulated with data.

1. Go to `ProjectApi/Program.cs`.

1. Uncomment the line wih `.ConfigureAppConfiguration(builder => builder.AddVault())` in
   the `CreateHostBuilder` method.

1. Go to `ProjectApi/appsettings.json`.

1. Update the `UseVaultStaticCredentials` to true.

1. Run `run_app.sh`.

1. Try to access the API endpoint at `https://localhost:5001/api/projects`. It will return a JSON.
   ```shell
   $ curl -k -X GET "https://localhost:5001/api/Projects" -H  "accept: text/plain"
     [{"id":"Vagrant","yearOfFirstCommit":2010,"gitHubLink":"https://github.com/hashicorp/vagrant"},{"id":"Packer","yearOfFirstCommit":2013,"gitHubLink":"https://github.com/hashicorp/packer"},{"id":"Terraform","yearOfFirstCommit":2014,"gitHubLink":"https://github.com/hashicorp/terraform"},{"id":"Nomad","yearOfFirstCommit":2015,"gitHubLink":"https://github.com/hashicorp/nomad"},{"id":"Consul","yearOfFirstCommit":2013,"gitHubLink":"https://github.com/hashicorp/consul"},{"id":"Vault","yearOfFirstCommit":2015,"gitHubLink":"https://github.com/hashicorp/vault"},{"id":"Waypoint","yearOfFirstCommit":2020,"gitHubLink":"https://github.com/hashicorp/waypoint"},{"id":"Boundary","yearOfFirstCommit":2020,"gitHubLink":"https://github.com/hashicorp/boundary"}]
   ```

1. Exit out of `run_app.sh`.

1. Go to `ProjectApi/appsettings.json`.

1. Update the `UseVaultDynamicCredentials` to true.

1. Run `run_app.sh`.

1. Try to access the API endpoint at `https://localhost:5001/api/projects`. It will return a JSON.
   ```shell
   $ curl -k -X GET "https://localhost:5001/api/Projects" -H  "accept: text/plain"
    [{"id":"Vagrant","yearOfFirstCommit":2010,"gitHubLink":"https://github.com/hashicorp/vagrant"},{"id":"Packer","yearOfFirstCommit":2013,"gitHubLink":"https://github.com/hashicorp/packer"},{"id":"Terraform","yearOfFirstCommit":2014,"gitHubLink":"https://github.com/hashicorp/terraform"},{"id":"Nomad","yearOfFirstCommit":2015,"gitHubLink":"https://github.com/hashicorp/nomad"},{"id":"Consul","yearOfFirstCommit":2013,"gitHubLink":"https://github.com/hashicorp/consul"},{"id":"Vault","yearOfFirstCommit":2015,"gitHubLink":"https://github.com/hashicorp/vault"},{"id":"Waypoint","yearOfFirstCommit":2020,"gitHubLink":"https://github.com/hashicorp/waypoint"},{"id":"Boundary","yearOfFirstCommit":2020,"gitHubLink":"https://github.com/hashicorp/boundary"}]
   ```

1. Run `list_passwords.sh`. This sends a request to Vault to check your dynamically generated database passwords.
   ```shell
   $ bash list_passwords.sh
     Keys
     ----
     kz8oxnnO7BxRih57PX7d0HWs
   ```

1. Run `revoke_passwords.sh`. This will revoke the database password you've generated for your application.

1. Try to access the API endpoint at `https://localhost:5001/api/projects`. It will return a 500
   error because the database log in fails.
   ```shell
   $ curl -k -X GET "https://localhost:5001/api/Projects" -H  "accept: text/plain"
     Microsoft.Data.SqlClient.SqlException (0x80131904): Login failed for user 'v-approle-projects-api-role-rOrdDahOU9G28eL6tWyD-1605535468'.
   ```

1. To get the application working again, exit out of `run_app.sh` and restart the .NET Core application.
   This issues a new set of database credentials.

Finally, run `cleanup.sh` to re-set your environment so that you can repeat the demo as necessary.

> **WARNING:** The `cleanup.sh` removes the Vault instance.
