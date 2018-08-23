die('Failed to compute value for VAULT_ADDR!') unless \
  VAULT_ADDR = %x(minikube service --url vault-ui).chomp

puts "VAULT_ADDR: #{VAULT_ADDR}..."

describe http("#{VAULT_ADDR}/v1/sys/leader") do
  its('status') { should cmp 200 }
end

describe http("#{VAULT_ADDR}/v1/sys/init") do
  its('status') { should cmp 200 }
end

describe http("#{VAULT_ADDR}/v1/sys/seal-status") do
  its('status') { should cmp 200 }
end
