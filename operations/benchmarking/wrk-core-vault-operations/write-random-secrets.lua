-- Script that writes secrets to k/v engine in Vault
-- You can specify the number of distinct secrets to write by adding "-- <N>" after the URL

local counter = 1
local threads = {}

function setup(thread)
   thread:set("id", counter)
   table.insert(threads, thread)
   counter = counter + 1
end

function init(args)
   if args[1] == nil then
      num_secrets = 1000
   else
      num_secrets = tonumber(args[1])
   end
   print("Number of secrets is: " .. num_secrets)
   requests  = 0
   writes = 0
   responses = 0
   method = "POST"
   -- give each thread different random seed
   math.randomseed(os.time() + id*1000)
   local msg = "thread %d created"
   print(msg:format(id))
end

function request()
   writes = writes + 1
   -- randomize path to secret
   path = "/v1/secret/write-random-test-" .. math.random(num_secrets)
   -- minimal secret giving thread id and # of write
   -- body = '{"foo-' .. id .. '" : "bar-' .. writes ..'"}'
   -- add extra key with 100 bytes
   body = '{"thread-' .. id .. '" : "write-' .. writes ..'","extra" : "1xxxxxxxxx2xxxxxxxxx3xxxxxxxxx4xxxxxxxxx5xxxxxxxxx6xxxxxxxxx7xxxxxxxxx8xxxxxxxxx9xxxxxxxxx0xxxxxxxxx"}'
   requests = requests + 1
   return wrk.format(method, path, nil, body)
end

function response(status, headers, body)
   responses = responses + 1
end

function done(summary, latency, requests)
   for index, thread in ipairs(threads) do
      local id        = thread:get("id")
      local requests  = thread:get("requests")
      local writes    = thread:get("writes")
      local responses = thread:get("responses")
      local msg = "thread %d made %d requests including %d writes and got %d responses"
      print(msg:format(id, requests, writes, responses))
   end
end
