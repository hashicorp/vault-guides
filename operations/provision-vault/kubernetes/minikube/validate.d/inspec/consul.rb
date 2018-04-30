die('Failed to compute value for CONSUL_HTTP_ADDR!') unless \
  CONSUL_HTTP_ADDR = %x(minikube service --url consul-ui).chomp

puts "CONSUL_HTTP_ADDR: #{CONSUL_HTTP_ADDR}..."

describe http("#{CONSUL_HTTP_ADDR}/v1/status/leader") do
  its('status') { should cmp 200 }
end

describe http("#{CONSUL_HTTP_ADDR}/v1/status/peers") do
  its('status') { should cmp 200 }
  # How would one count the items in the array of peers?
end
