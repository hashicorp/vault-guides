using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace RewrapExample
{
    class Program
    {
        static VaultClient client = null;
        static void Main(string[] args)
        {
            // Get our env vars
            string vaultUri = Environment.GetEnvironmentVariable("VAULT_ADDR");
            string token = Environment.GetEnvironmentVariable("VAULT_TOKEN");
            string transitKeyName = Environment.GetEnvironmentVariable("VAULT_TRANSIT_KEY");
            string shouldSeed = Environment.GetEnvironmentVariable("SHOULD_SEED_USERS");
            string numRecords = Environment.GetEnvironmentVariable("NUMBER_SEED_USERS");

            Console.WriteLine("Connecting to Vault server...");

            // initialize Vault client
            if (null == client)
            {
                client = new VaultClient(vaultUri, token, transitKeyName);
            }

            InitDBAsync().GetAwaiter().GetResult();

            // seed the database with random user records if necessary
            if (null != shouldSeed) {
                SeedDB(numRecords).GetAwaiter().GetResult();
                Console.WriteLine("Seeded the database...");
            }

            // get latest key version and rewrap if necessary
            Console.WriteLine("Moving rewrap...");
            RewrapAsync().GetAwaiter().GetResult();
        }

        static async Task InitDBAsync()
        {
            await DBHelper.CreateDBAsync();
            await DBHelper.CreateTablesAsync();

        }

        // Download records from the randomuser api, and encrypt some 
        // fields so we can rewrap them later
        static async Task SeedDB(string numRecords)
        {
            WebHelper.ApiResults apiResults = await WebHelper.GetUserRecordsAsync(numRecords);
            var tasks = new List<Task>();
            foreach (var record in apiResults.Records) {
                ICollection<Task> encryptValues = new List<Task>();
                record.Location.City = await client.EncryptValue(record.Location.City);
                record.Email = await client.EncryptValue(record.Email);
                tasks.Add(DBHelper.InsertRecordAsyc(record));
            }
            await Task.WhenAll(tasks);
            
        }
        static async Task RewrapAsync() {
            int v = await client.GetLatestTransitKeyVersion();
            Console.WriteLine($"Current Key Version: {v}");
            List<Record> users = await DBHelper.FindRecordsToRewrap(v);
            Console.WriteLine($"Found {users.Count} records to rewrap.");
            await client.ReWrapRecords(users);
            
        }
    }
}
