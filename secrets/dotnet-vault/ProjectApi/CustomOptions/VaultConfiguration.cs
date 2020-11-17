using System;
using System.Threading.Tasks;
using VaultSharp;
using VaultSharp.V1.AuthMethods.AppRole;
using VaultSharp.V1.Commons;
using VaultSharp.V1.SecretsEngines;
using Microsoft.Extensions.Configuration;

namespace ProjectApi.CustomOptions
{
  public class VaultConfigurationProvider : ConfigurationProvider
  {
    public VaultOptions _config;
    private IVaultClient _client;

    public VaultConfigurationProvider(VaultOptions config)
    {
      _config = config;

      var vaultClientSettings = new VaultClientSettings(
          _config.Address,
          new AppRoleAuthMethodInfo(_config.Role,
                                    _config.Secret)
      );

      _client = new VaultClient(vaultClientSettings);
    }

    public override void Load()
    {
      LoadAsync().Wait();
    }

    public async Task LoadAsync()
    {
      await GetDatabaseCredentials();
    }

    public async Task GetDatabaseCredentials()
    {
      var userID = "";
      var password = "";

      if (_config.SecretType == "secrets")
      {
        Secret<SecretData> secrets = await _client.V1.Secrets.KeyValue.V2.ReadSecretAsync(
          "static", null, _config.MountPath + _config.SecretType);

        userID = "sa";
        password = secrets.Data.Data["password"].ToString();
      }

      if (_config.SecretType == "database")
      {
        Secret<UsernamePasswordCredentials> dynamicDatabaseCredentials =
        await _client.V1.Secrets.Database.GetCredentialsAsync(
          _config.Role,
          _config.MountPath + _config.SecretType);

        userID = dynamicDatabaseCredentials.Data.Username;
        password = dynamicDatabaseCredentials.Data.Password;
      }

      Data.Add("database:userID", userID);
      Data.Add("database:password", password);
    }
  }

  public class VaultConfigurationSource : IConfigurationSource
  {
    private VaultOptions _config;

    public VaultConfigurationSource(Action<VaultOptions> config)
    {
      _config = new VaultOptions();
      config.Invoke(_config);
    }

    public IConfigurationProvider Build(IConfigurationBuilder builder)
    {
      return new VaultConfigurationProvider(_config);
    }
  }

  public class VaultOptions
  {
    public string Address { get; set; }
    public string Role { get; set; }

    public string Secret { get; set; }
    public string MountPath { get; set; }
    public string SecretType { get; set; }
  }

  public static class VaultExtensions
  {
    public static IConfigurationBuilder AddVault(this IConfigurationBuilder configuration,
    Action<VaultOptions> options)
    {
      var vaultOptions = new VaultConfigurationSource(options);
      configuration.Add(vaultOptions);
      return configuration;
    }
  }
}