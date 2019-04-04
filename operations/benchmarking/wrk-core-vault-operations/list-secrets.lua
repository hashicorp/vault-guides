-- Script that lists secrets from k/v engine in Vault
-- If you want to print the secrets found for each list, add "-- true" after the URL

json = require "json"

local counter = 1
local threads = {}

function setup(thread)
   thread:set("id", counter)
   table.insert(threads, thread)
   counter = counter + 1
end

function init(args)
   if args[1] == nil then
      print_secrets = "false"
   else
      print_secrets = args[1]
   end
   print_secrets = args[1]
   requests  = 0
   lists = 0
   responses = 0
   method = "GET"
   path = "/v1/secret/list-test?list=true"
   body = ""
   local msg = "thread %d created with print_secrets set to %s"
   print(msg:format(id, print_secrets))
end

function request()
   lists = lists + 1
   requests = requests + 1
   return wrk.format(method, path, nil, body)
end

function response(status, headers, body)
   responses = responses + 1
   if print_secrets == "true" then
      body_object = json.decode(body)
      for k,v in pairs(body_object) do 
         if k == "data" then
            local count = 0
            for k1,v1 in pairs(v) do
               for _, v2 in pairs(v1) do
                  count = count + 1
                  local msg = "response %d found secret: %s"
                  print(msg:format(responses,v2)) 
               end
               local msg = "Found %d secrets in list"
               print(msg:format(count))
            end
         end
      end
   end 
end

function done(summary, latency, requests)
   for index, thread in ipairs(threads) do
      local id        = thread:get("id")
      local requests  = thread:get("requests")
      local lists     = thread:get("lists")
      local responses = thread:get("responses")
      local msg = "thread %d made %d requests including %d lists and got %d responses"
      print(msg:format(id, requests, lists, responses))
   end
end
