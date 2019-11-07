#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200
export PUBLIC_VAULT_ADDR=http://test.mylocalvault.com:8200
export TPP_ADDR=https://example.venafi.com/vedsdk
export TPP_USER=<username>
export TPP_PASS=<password>

echo -e "===== Create a PKI mount called venafi ====="
vault secrets enable -path=subca -plugin-name=vault-pki-monitor-venafi_strict plugin
vault secrets list

# May need to reference locally trusted certificate in the below config. In this example Venafi TPP has a publically trusted cert
# Download the certificate policy from Venafi. This policy which controls the configuration of the subca.

vault write subca/venafi-policy/default \
    tpp_url="$TPP_ADDR" \
    tpp_user="$TPP_USER" \
    tpp_password="$TPP_PASS" \
    zone="Certificates\\HashiCorp Vault\\VaultSubCA"

echo -e "\r\n===== Generate a key pair and CSR in the Vault for subordinate CA ====="
CSR=$(vault write -field=csr subca/intermediate/generate/internal \
	common_name="Vault Sub-CA" ou="Vault Issuing Authority" organization="Venafidemo Inc." locality="Salt Lake City" province="Utah" country="US" \
	ttl=35064h key_bits=2048 exclude_cn_from_sans=true | sed 's/$/\\n/' | tr -d '\n')
echo $CSR

echo -e "\r\n===== Authenticate with TPP ====="
APIKEY=$(curl -k -s -X POST -H "Content-Type:application/json" \
	$TPP_ADDR'/authorize/' -d '{"Username":"'$TPP_USER'","Password":"'$TPP_PASS'"}' \
	| sed 's/^.*"APIKey":"\([^"]*\)".*$/\1/')
echo $APIKEY

#PolicyDN should reflect the location of the policy in Venafi
echo -e "\r\n===== Request a certificate from TPP using the CSR ====="
CERT_DN=$(curl -k -s -X POST -H "Content-Type:application/json" \
	-H "X-Venafi-Api-Key:$APIKEY" $TPP_ADDR'/certificates/request' \
	-d '{"PolicyDN":"\\VED\\Policy\\Certificates\\HashiCorp Vault\\VaultSubCA","PKCS10":"'"$CSR"'"}' \
	| sed 's/^.*"CertificateDN":"\([^"]*\)".*$/\1/' | sed 's/\\\+/%5C/g' | sed 's/ /%20/g')
echo $CERT_DN

echo -e "\r\n(waiting 10 seconds to make sure certificate is issued)"
sleep 10

echo -e "\r\n===== Retrieve the certificate from TPP ====="
curl -k -s -X GET -H "X-Venafi-Api-Key:$APIKEY" \
	$TPP_ADDR'/certificates/retrieve?CertificateDN='$CERT_DN'&Format=Base64' -o subca.crt
cat subca.crt

echo -e "\r\n===== Install the CA certificate into the Vault ====="
vault write subca/intermediate/set-signed certificate=@subca.crt

vault write subca/config/urls \
	issuing_certificates="$PUBLIC_VAULT_ADDR/v1/venafi/ca" \
	crl_distribution_points="$PUBLIC_VAULT_ADDR/v1/venafi/crl"

vault write subca/venafi-policy/vaultissued \
    tpp_url="$TPP_ADDR" \
    tpp_user="$TPP_USER" \
    tpp_password="$TPP_PASS" \
    zone="Certificates\\HashiCorp Vault\\Vault Issued"

vault write subca/roles/web_server \
    venafi_check_policy="vaultissued" \
    venafi_import=true \
    tpp_url="$TPP_ADDR" \
    tpp_user="$TPP_USER" \
    tpp_password="$TPP_PASS" \
    generate_lease=true ttl=24h max_ttl=48h allow_any_name=true \
    zone="Certificates\\HashiCorp Vault\\Vault Issued" \
	ou="HashiCorp" organization="Venafidemo Inc." locality="Salt Lake City" province="Utah" country="US"
