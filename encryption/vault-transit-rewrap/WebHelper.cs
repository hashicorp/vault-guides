using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace RewrapExample
{
    class WebHelper
    {
        public static HttpClient client = new HttpClient();
        
        public class ApiResults
        {
            [JsonProperty("results")]
            public IEnumerable<Record> Records { get; set; }
        }

        public static async Task<ApiResults> GetUserRecordsAsync(string numRecords)
        {
            var n = null == numRecords ? "500" : numRecords; 
            string baseUrl = "https://randomuser.me";
            string query = $"/api/?results={n}&nat=us";
            //WebHelper.client.BaseAddress = new Uri(baseUrl);
            WebHelper.client.DefaultRequestHeaders.Accept.Clear();
            WebHelper.client.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json")
            );    
            
            ApiResults records = null;
            HttpResponseMessage response = await client.GetAsync(baseUrl + query);
            if (response.IsSuccessStatusCode)
            {
                string resp = await response.Content.ReadAsStringAsync();
                records = JsonConvert.DeserializeObject<ApiResults>(resp);
            }
            return records;
        } 
    }
}