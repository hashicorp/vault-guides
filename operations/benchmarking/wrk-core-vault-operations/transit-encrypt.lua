local counter = 1
local threads = {}

function setup(thread)
  thread:set("id", counter)
  table.insert(threads, thread)
  counter = counter + 1
end

function init(args)
  requests = 0
  writes = 0
  responses = 0
  body = ''
  method = "POST"

  local msg = "thread %d created"
end

function request()
  -- base64 of desired secret - in this case, "my cool secret"
  plaintext_secret = "bXkgY29vbCB0ZXN0IHNlY3JldA=="
  body = '{"plaintext": "' .. plaintext_secret .. '"}'
  -- this test expects there to be an encryption key named "load-test" in a transit engine
  --   available at the following path:
  path = "/v1/transit/encrypt/load-test"

  writes = writes + 1
  requests = requests + 1

  http_req = wrk.format(method, path, nil, body)
  print(http_req)
  return http_req
end

function response(status, headers, body)
  print("Response")
  print(body)
  print("\n")
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
