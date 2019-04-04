. demo-magic.sh

echo $(green "Removing certificates")
rm -f /etc/certs/*
echo
echo $(green "Removing temporary config files")
rm -f /var/tmp/*.{json,pem}
echo
echo $(green "Stopping Vault")
systemctl stop docker-vault
echo
echo $(green "Removing Vault entries from Consul")
docker exec -it consul consul kv delete -recurse vault/ &> /dev/null
