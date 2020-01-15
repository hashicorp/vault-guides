using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using VaultSharp;
using VaultSharp.Backends.Authentication.Models;
using VaultSharp.Backends.Authentication.Models.Token;


namespace RewrapExample
{
    class VaultClient
    {
        IVaultClient client;
        string transitKeyName;
        const string keyPath = "/transit/keys/";
        
        public VaultClient(string vaultAddr, string vaultToken, string keyName)
        {
            Uri vaultUri = new Uri(vaultAddr);
            IAuthenticationInfo tokenAuthenticationInfo = new TokenAuthenticationInfo(vaultToken);
            client = VaultClientFactory.CreateVaultClient(vaultUri, tokenAuthenticationInfo);
            transitKeyName = keyName;
        } 
        
        // get latest transit key version
        public async Task<int> GetLatestTransitKeyVersion()
        {
            int keyVersion = -1;
            var resp = await client.ReadSecretAsync(keyPath + transitKeyName);
            if (resp.Data.ContainsKey("latest_version"))
            {
                keyVersion = (int)(long)resp.Data["latest_version"];
            }
            
            return keyVersion;
        }
        
        // rewrap endpoint, possible to upload batches of records,  but that is
        // not currently supported by the VaultSharp client.  You can specify things like
        // alternate mount point, context for derived keys, etc.  Please see the documentation:
        // https://github.com/rajanadar/VaultSharp
        public async Task<string> ReWrapValue(string ciphertext)
        {
            var result = await client.TransitRewrapWithLatestEncryptionKeyAsync(transitKeyName, ciphertext);
            return result.Data.CipherText;
        }

        private string base64(string value)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(value);
            return Convert.ToBase64String(bytes);
        }

        // encrypt data, required for seeding 
        public async Task<string> EncryptValue(string plainText)
        {
            var ciphertext = await client.TransitEncryptAsync(transitKeyName, base64(plainText));
            return ciphertext.Data.CipherText;
        }  
        
        public async Task ReWrapRecords(ICollection<Record> users)
        {
            int count = 0;
            ICollection<Task> tasks = new  List<Task>();
            foreach (Record user in users)
            {
                count++;
                user.Location.City = await ReWrapValue(user.Location.City);
                user.Email = await ReWrapValue(user.Email);
                
                tasks.Add(DBHelper.UpdateRecordAsyc(user));
                if (count % 10 == 0) 
                {
                    Console.WriteLine($"Wrapped another 10 records: {count} so far...");
                    await Task.WhenAll();
                }
            }
            await Task.WhenAll(tasks);
        }
    }
}