using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

using VaultSharp;
using VaultSharp.V1.AuthMethods.AppRole;
using VaultSharp.V1.Commons;
using VaultSharp.V1.SecretsEngines;
using System.Data.SqlClient;

namespace ProjectApi
{
  public class Program
  {
    public static void Main(string[] args)
    {
      CreateHostBuilder(args).Build().Run();
    }

    public static IHostBuilder CreateHostBuilder(string[] args) =>
        Host.CreateDefaultBuilder(args)
            // .ConfigureAppConfiguration(builder => builder.AddVault())
            .ConfigureWebHostDefaults(webBuilder =>
            {
              webBuilder.UseStartup<Startup>();
            });
  }

  public static class EntityFrameworkExtensions
  {
    public static IConfigurationBuilder AddVault(this IConfigurationBuilder builder)
    {
      try
      {
        var buildConfig = builder.Build();

        var vaultClientSettings = new VaultClientSettings(
            buildConfig.GetConnectionString("VaultAddress"),
            new AppRoleAuthMethodInfo(buildConfig.GetConnectionString("VaultRole"),
                                      Environment.GetEnvironmentVariable("VAULT_SECRET_ID"))
        );

        IVaultClient vaultClient = new VaultClient(vaultClientSettings);

        var dbBuilder = new SqlConnectionStringBuilder(
          buildConfig.GetConnectionString("Database")
        );

        if (buildConfig.GetValue<bool>("UseVaultStaticCredentials"))
        {
          Secret<SecretData> password = vaultClient.V1.Secrets.KeyValue.V2.ReadSecretAsync(
            "static", null, buildConfig.GetConnectionString("VaultSecretsMountPath")).Result;

          dbBuilder.Password = password.Data.Data["password"].ToString();
        }

        if (buildConfig.GetValue<bool>("UseVaultDynamicCredentials"))
        {
          Secret<UsernamePasswordCredentials> dynamicDatabaseCredentials = vaultClient.V1.Secrets.Database.GetCredentialsAsync(
            buildConfig.GetConnectionString("VaultRole"),
            buildConfig.GetConnectionString("VaultDatabaseMountPath")).Result;

          dbBuilder.UserID = dynamicDatabaseCredentials.Data.Username;
          dbBuilder.Password = dynamicDatabaseCredentials.Data.Password;

        }

        var vaultSecrets = new Dictionary<string, string>();
        vaultSecrets.Add("vault:database", dbBuilder.ConnectionString);
        builder.AddInMemoryCollection(vaultSecrets);
      }
      catch (Exception ex)
      {
        throw new Exception("Cannot connect to Vault: " + ex.Message);
      }
      return builder;
    }
  }
}
