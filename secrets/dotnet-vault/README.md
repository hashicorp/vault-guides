# HashiCorp Vault with .NET Example

These assets are provided to show how to use HashiCorp Vault with .NET.
It uses two patterns:

- Vault C# Library for Static Secrets Injection
- Vault Agent for Dynamic Secrets

For complete instructions, visit the following links:

- [Using HashiCorp Vault C# Client with .NET](https://learn.hashicorp.com/tutorials/vault/dotnet-httpclient)
- [Using HashiCorp Vault Agent with .NET](https://learn.hashicorp.com/tutorials/vault/dotnet-vault-agent)


---

## Requirements

- [Docker Compose](https://docs.docker.com/compose/)
- [Docker](https://docs.docker.com/get-docker/)
- [.NET 5.0+](https://dotnet.microsoft.com/download/dotnet/5.0)
- [VaultSharp](https://github.com/rajanadar/VaultSharp)

## Demo Script Guide

The following files are provided as demo scripts:

- `demo_setup.sh`
  * Pulls and builds a Microsoft SQL Server (MSSQL) database and Vault development instance
  * Enable KV secrets engine, MSSQL database secrets engine, and AppRole auth method
  * Configures the KV secrets engine at `projects-api/secrets` to store root password
    for database.
  * Configures the MSSQL database secrets engine at `projects-api/database` to create
    users for the database.
  * Creates a Vault policy to limit access to only retrieving database credentials and
    static secrets
  * Writes out the role and secret id to `ProjectApi/vault-agent`.
- `run_app.sh`
  * Retrieves a secret ID
  * Runs the example app
- `vault_agent_template.sh`
  * Runs Vault agent to authenticate to Vault
  * Writes token to file
  * Creates `appsettings.json` file with database connection string.
- `vault_agent_token.sh`
  * Runs Vault agent to authenticate to Vault
  * Writes token to file
  * Runs Consul template to reload application each time template changes.
- `cleanup_vault_agent.sh`: remove Vault agent containers
- `cleanup.sh`: re-set your environment
- `list_passwords.sh`: show a list of Vault-generated database passwords
- `revoke_passwords.sh`: revoke all of the Vault-generated database passwords

### Demo Workflow

> **NOTE:** DON'T FORGET that this demo requires .NET 5.0+ and Docker Compose to run the example application!

1. Run `demo_setup.sh`. This creates a Vault instance (in development mode) and
   a Microsoft SQL Server database with a table prepopulated with data.

1. Go to `ProjectApi/appsettings.json`.

1. Check that `Vault.SecretType` is set to `secrets`. This tells `ProjectApi/CustomOptions/VaultConfiguration.cs`
   to use the root database password stored in Vault's key-value store. The application will use the
   Vault client to retrieve static values from a key-value endpoint.
   ```json
   {
      "Logging": {
         "LogLevel": {
            "Default": "Information",
            "Microsoft": "Warning",
            "Microsoft.Hosting.Lifetime": "Information"
         }
      },
      "AllowedHosts": "*",
      "ConnectionStrings": {
         "Database": "Server=.;Database=HashiCorp"
      },
      "Vault": {
         "Address": "http://127.0.0.1:8200",
         "Role": "projects-api-role",
         "MountPath": "projects-api/",
         "SecretType": "secrets"
      }
   }
   ```

1. Run `run_app.sh`.

1. Try to access the API endpoint at `https://localhost:5001/api/projects`. It will return a JSON.
   ```shell
   $ curl -k -X GET "https://localhost:5001/api/Projects" -H  "accept: text/plain"
     [{"id":"Vagrant","yearOfFirstCommit":2010,"gitHubLink":"https://github.com/hashicorp/vagrant"},{"id":"Packer","yearOfFirstCommit":2013,"gitHubLink":"https://github.com/hashicorp/packer"},{"id":"Terraform","yearOfFirstCommit":2014,"gitHubLink":"https://github.com/hashicorp/terraform"},{"id":"Nomad","yearOfFirstCommit":2015,"gitHubLink":"https://github.com/hashicorp/nomad"},{"id":"Consul","yearOfFirstCommit":2013,"gitHubLink":"https://github.com/hashicorp/consul"},{"id":"Vault","yearOfFirstCommit":2015,"gitHubLink":"https://github.com/hashicorp/vault"},{"id":"Waypoint","yearOfFirstCommit":2020,"gitHubLink":"https://github.com/hashicorp/waypoint"},{"id":"Boundary","yearOfFirstCommit":2020,"gitHubLink":"https://github.com/hashicorp/boundary"}]
   ```

1. Exit out of `run_app.sh`.

Now, try to retrieve a dynamic database password from Vault. Vault can be configured to
generate a database username and password. Vault has been pre-configured to generate a
username and password with a lifetime of five minutes.

1. Go to `ProjectApi/appsettings.json`.

1. Set `Vault.SecretType` to `database`.
   ```json
   {
      "Logging": {
         "LogLevel": {
            "Default": "Information",
            "Microsoft": "Warning",
            "Microsoft.Hosting.Lifetime": "Information"
         }
      },
      "AllowedHosts": "*",
      "ConnectionStrings": {
         "Database": "Server=.;Database=HashiCorp"
      },
      "Vault": {
         "Address": "http://127.0.0.1:8200",
         "Role": "projects-api-role",
         "MountPath": "projects-api/",
         "SecretType": "database"
      }
   }
   ```

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

1. To get the application working again, exit out of `run_app.sh` and restart the .NET application.
   This issues a new set of database credentials.

To handle dynamic database credentials (rotate them every five minutes), you can use Vault Agent
to create an `appsettings.json` and the .NET application can be configured to reload each time a
new `appsettings.json` is updated.

1. To reload the application each time the database string is updated, open `ProjectApi/Program.cs` and
   check that the application configuration includes `config.AddJsonFile` to `reloadOnChange` the `appsettings.json` file.
   ```csharp
   public static IHostBuilder CreateHostBuilder(string[] args) =>
      Host.CreateDefaultBuilder(args)
         .ConfigureAppConfiguration((hostingContext, config) =>
         {
            config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
         });
   ```

1. Open the file `ProjectApi/Models/ProjectContext.cs` and check that the context has the `OnConfiguring` method.
   ```csharp
   protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
   {
      optionsBuilder.UseSqlServer(Startup.Configuration.GetSection("ConnectionStrings")["Database"]);
   }
   ```

1. Run `bash vault_agent_template.sh`.

1. Open `ProjectApi/appsettings.json`. You will see the database connection string update with the Vault generated
   username and password.

1. Run `bash run_app.sh`.

1. Try to access the API endpoint at `https://localhost:5001/api/projects`. It will return a JSON.
   ```shell
   $ curl -k -X GET "https://localhost:5001/api/Projects" -H  "accept: text/plain"
    [{"id":"Vagrant","yearOfFirstCommit":2010,"gitHubLink":"https://github.com/hashicorp/vagrant"},{"id":"Packer","yearOfFirstCommit":2013,"gitHubLink":"https://github.com/hashicorp/packer"},{"id":"Terraform","yearOfFirstCommit":2014,"gitHubLink":"https://github.com/hashicorp/terraform"},{"id":"Nomad","yearOfFirstCommit":2015,"gitHubLink":"https://github.com/hashicorp/nomad"},{"id":"Consul","yearOfFirstCommit":2013,"gitHubLink":"https://github.com/hashicorp/consul"},{"id":"Vault","yearOfFirstCommit":2015,"gitHubLink":"https://github.com/hashicorp/vault"},{"id":"Waypoint","yearOfFirstCommit":2020,"gitHubLink":"https://github.com/hashicorp/waypoint"},{"id":"Boundary","yearOfFirstCommit":2020,"gitHubLink":"https://github.com/hashicorp/boundary"}]
   ```

1. Wait five minutes and access the API endpoint again. You will still be able to
   access the database with new passwords and usernames!

Finally, run `cleanup.sh` to re-set your environment so that you can repeat the demo as necessary.

> **WARNING:** The `cleanup.sh` removes the Vault instance.
