using System;
using MySql.Data.MySqlClient;

namespace RewrapExample
{
    public class AppDb : IDisposable
    {
        public readonly MySqlConnection Connection;

        public AppDb()
        {
            Connection = new MySqlConnection("host=127.0.0.1;port=3306;user id=vault;password=vaultpw;database=my_app;");
        }

        public void Dispose()
        {
            Connection.Close();
        }
    }
}
