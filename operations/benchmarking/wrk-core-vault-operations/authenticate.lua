-- Script that authenticates a user against Vault's userpass system.
-- This script should be used with batch tokens only. Any Leases (if issued) are not revoked.

local counter = 1
local threads = {}

function setup(thread)
   thread:set("id", counter)
   table.insert(threads, thread)
   counter = counter + 1
end

function init(args)
   requests  = 0
   authentications = 0
   revocations = 0
   responses = 0
   local msg = "thread %d created"
   print(msg:format(id))
end

function request()
   requests = requests + 1

   -- Authenticate
   authentications = authentications + 1
   method = "POST"
   path = "/v1/auth/userpass/login/loadtester"
   body = '{"password" : "benchmark" }'
   -- print("Authenticating")

return wrk.format(method, path, nil, body)
end

function delay()
   return 0
end

function response(status, headers, body)
   if status == 200  or status == 204 then
      responses = responses + 1
   end
   -- print("Status: " .. status)
end

function done(summary, latency, requests)
   for index, thread in ipairs(threads) do
      local id        = thread:get("id")
      local requests  = thread:get("requests")
      local authentications    = thread:get("authentications")
      local revocations    = thread:get("revocations")
      local responses = thread:get("responses")
      local msg = "thread %d made %d authentications and %d revocations and got %d responses"
      print(msg:format(id, authentications, revocations, responses))
   end
end