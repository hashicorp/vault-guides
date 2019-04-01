-- Script that deletes secrets from k/v engine in Vault
-- Pass the path from which you want to delete secrets
-- by adding "-- <path>" after the URL
local counter = 1
local threads = {}

function setup(thread)
   thread:set("id", counter)
   table.insert(threads, thread)
   counter = counter + 1
end

function init(args)
   if args[1] == nil then
      path_prefix = "secret/test"
   else
      path_prefix = args[1]
   end
   requests  = 0
   deletes = 0
   responses = 0
   method = "DELETE"
   path = "/v1/" .. path_prefix .. "/secret-0"
   body = ''
   local msg = "thread %d created"
   print(msg:format(id))
end

function request()
   -- First request is not actually invoked
   -- So, don't process it in order to delete secret-1
   if requests > 0 then
      deletes = deletes + 1
      -- Set the path to the desired path with secrets you want to delete
      path = "/v1/" .. path_prefix .. "/secret-" .. deletes
      body = ''
   end
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
      local deletes   = thread:get("deletes")
      local responses = thread:get("responses")
      local msg = "thread %d made %d requests including % deletes and got %d responses"
      print(msg:format(id, requests, deletes, responses))
   end
end
