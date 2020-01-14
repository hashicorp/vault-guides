using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Threading.Tasks;

namespace RewrapExample
{

    class DBHelper 
    {
        public static async Task CreateTablesAsync()
        {
            using (var db = new AppDb())
            {
                await db.Connection.OpenAsync();
                using (var cmd = db.Connection.CreateCommand())
                {
                    string command = "CREATE TABLE IF NOT EXISTS `user_data`(" +
                        "`user_id` INT(11) NOT NULL AUTO_INCREMENT, " +
                        "`user_name` VARCHAR(256) NOT NULL," +
                        "`first_name` VARCHAR(256) NULL, " +
                        "`last_name` VARCHAR(256) NULL, " +
                        "`city` VARCHAR(256) NOT NULL," +
                        "`state` VARCHAR(256) NOT NULL," +
                        "`country` VARCHAR(256) NOT NULL," +
                        "`postcode` VARCHAR(256) NOT NULL," +
                        "`email` VARCHAR(256) NOT NULL," +
                        "PRIMARY KEY (user_id) " +
                        ") engine=InnoDB;";
                    cmd.CommandText = command;


                    await cmd.ExecuteNonQueryAsync();
                    Console.WriteLine("Create (if not exist) user_data table");
                }
            }
        }

        public static async Task CreateDBAsync()
        {
            using (var db = new AppDb())
            {
                await db.Connection.OpenAsync();
                using (var cmd = db.Connection.CreateCommand())
                {
                    string command = "CREATE DATABASE IF NOT EXISTS my_app";
                    cmd.CommandText = command;

                    await cmd.ExecuteNonQueryAsync();
                    Console.WriteLine("Created (if not exist) my_app DB");
                }
            }
        }

        public static async Task InsertRecordAsyc(Record r)
        {
            using (var db = new AppDb())
            {
                await db.Connection.OpenAsync();
                using (var cmd = db.Connection.CreateCommand())
                {
                    
                    string command = "INSERT INTO `user_data` " + 
                    "(`user_name`, `first_name`, `last_name`, " +
                    "`city`, `state`, `country`, `postcode`, `email`) " +
                    $"VALUES (\"{r.Login.Username}\", \"{r.Name.First}\", \"{r.Name.Last}\", " +
                    $"\"{r.Location.City}\", \"{r.Location.State}\", \"{r.Location.Country}\", " +
                    $"\"{r.Location.Postcode}\", \"{r.Email}\");";
                    
                    cmd.CommandText = command;

                    var rowsAffected = await cmd.ExecuteNonQueryAsync();
                }
            }
        }
        
        // update encrypted fields with rewrapped data
        public static async Task UpdateRecordAsyc(Record r)
        {
            using (var db = new AppDb())
            {
                await db.Connection.OpenAsync();
                using (var cmd = db.Connection.CreateCommand())
                {
                    string command = "UPDATE `user_data` " + 
                    $"SET `city` = \"{r.Location.City}\", " +
                    $"`email` = \"{r.Email}\" " +
                    $"WHERE `user_id` = {r.Id.Value}";
                    
                    cmd.CommandText = command;
                    
                    await cmd.ExecuteNonQueryAsync();
                }
            }
        }

        // Find records that need to be rewrapped
        public static async Task<List<Record>> FindRecordsToRewrap(int keyVersion)
        {
            // select fields  that are encrypted
            using (var db = new AppDb())
            {
                var users = new List<Record>();
                await db.Connection.OpenAsync();
                using (var cmd = db.Connection.CreateCommand())
                {
                    int count = 0;
                    string command = "SELECT `user_id`, `email`, `city` " +
                    "FROM `user_data` " + 
                    $"WHERE `email` NOT LIKE \"vault:v{keyVersion}:%\" " + 
                    $"OR `city` NOT LIKE \"vault:v{keyVersion}:%\" ";
                        
                    cmd.CommandText = command;

                    var reader = await cmd.ExecuteReaderAsync();
                    
                    while (reader.Read())
                    {
                        count++;
                        var user_id = reader.GetInt32(0);
                        var email = reader.GetString(1);
                        var city = reader.GetString(2);
                        
                        RewrapExample.Location addr = new Location();
                        addr.City = city;
                        RewrapExample.Id id = new Id();
                        id.Value = user_id.ToString();

                        Record r = new Record
                        {
                            Id = id,
                            Email = email,
                            Location = addr,
                        };
                        users.Add(r);
                    }
                }
                return users;
            }
        }
    }
}
