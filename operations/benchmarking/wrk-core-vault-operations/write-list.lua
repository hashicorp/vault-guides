-- Script that writes a list of secrets to k/v engine in Vault
-- Indicate number of secrets to write to secret/list-test path with "-- <n>"

local counter = 1
local threads = {}

function setup(thread)
   thread:set("id", counter)
   table.insert(threads, thread)
   counter = counter + 1
end

function init(args)
   if args[1] == nil then
      list_size = 100
   else
      list_size = tonumber(args[1])
   end
   print("list size is: " .. list_size)
   requests  = 0
   writes = 0
   responses = 0
   method = "POST"
   path = "/v1/secret/list-test/secret-0"
   body = '{"key" : "1234567890"}'
   local msg = "thread %d created"
   print(msg:format(id))
end

function request()
   -- First request is not actually invoked
   -- So, don't process it in order to get secret-1 as first secret
   if requests > 0 then
      writes = writes + 1
      -- cycle through paths from 1 to list_size in order
      path = "/v1/secret/list-test/secret-" .. writes
   end
   requests = requests + 1
   return wrk.format(method, path, nil, body)
end

function response(status, headers, body)
   responses = responses + 1
   if responses == list_size then
      os.exit()
   end
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
