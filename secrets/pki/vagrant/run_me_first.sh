#!/bin/bash
# 
# generate-provisioners.sh
#
# PURPOSE: Generates the user-data file used by Vagrant by sourcing environment variables in demo/default_env.sh.   This allows for easily updating consul and vault versions without having to re-write versions directly.

. demo/default_env.sh

cat > provision.sh <<EOL
. /demo/default_env.sh

IP=\$(ip -f inet addr show eth1 | grep -Po 'inet \K[\d.]+')
echo \${IP} vault1.\${DEMO_DOMAIN} >> /etc/hosts

mkdir -p /etc/vault
cat > /etc/vault/config.hcl <<EOF
storage "consul" {
  address = "\${IP}:8500"
  path    = "vault"
}

listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_cert_file      = "/etc/certs/\${VAULT_HOST}_crt.pem"
  tls_key_file       = "/etc/certs/\${VAULT_HOST}_key.pem"
  tls_client_ca_file = "/etc/certs/\${VAULT_HOST}_ca_chain.pem"
}
EOF

mkdir -p /etc/bash/bashrc.d
echo "alias ll='ls -latr'" >> /etc/bash/bashrc.d/jake_preferences
echo "set -o vi" >> /etc/bash/bashrc.d/jake_preferences

mkdir -p /opt/bin
cd /opt/bin
wget -q ${CONSUL_TEMPLATE_URL} && tar -xzvf ${CONSUL_TEMPLATE_BIN} && chmod 0755 consul-template
EOL

cat > user-data <<EOF 
#cloud-config

systemd:
  units:
    - name: update-engine.service
      mask: true
    - name: locksmithd.service
      mask: true

coreos:
  update:
    reboot-strategy: off
  units:
   - name: docker-consul.service
     enable: true
     command: start
     content: |
       [Unit]
       Description=Daemon for consul
       After=docker.service
       Requires=docker.service
       
       [Service]
       Restart=on-failure
       StartLimitInterval=20
       StartLimitBurst=5
       TimeoutStartSec=0
       Environment="HOME=/root"
       ExecStartPre=-/usr/bin/docker kill consul
       ExecStartPre=-/usr/bin/docker rm consul
       ExecStartPre=-/usr/bin/docker pull ${CONSUL_IMAGE}
       ExecStart=/usr/bin/docker run \\
         --rm \\
         --net bridge -m 0b \\
         -p 8300:8300 -p 8301:8301 -p 8301:8301/udp \\
         -p 8302:8302 -p 8302:8302/udp -p 8400:8400 \\
         -p 8500:8500 \\
         -v /var/consul/data:/consul/data \\
         -v /etc/certs:/etc/certs \\
         -h ${CONSUL_HOST} \\
         --name consul \\
         ${CONSUL_IMAGE} agent -ui \\
         -node=${CONSUL_HOST} -datacenter=dev -advertise=172.17.8.101 \\
         -bind=0.0.0.0 -client=0.0.0.0 -encrypt=D8Er0YYpXOkM4QFm0eErFw== \\
         -data-dir=/consul/data -config-dir=/consul/config  -bootstrap-expect=1 -server
       
       ExecStop=-/usr/bin/docker stop -t 45 consul
       
       [Install]
       WantedBy=multi-user.target

   - name: docker-vault.service
     enable: true
     content: |
       [Unit]
       Description=Daemon for vault
       After=docker.service
       Requires=docker.service
       
       [Service]
       Restart=on-failure
       StartLimitInterval=20
       StartLimitBurst=5
       TimeoutStartSec=0
       Environment="HOME=/root"
       ExecStartPre=-/usr/bin/docker kill vault
       ExecStartPre=-/usr/bin/docker rm vault
       ExecStartPre=-/usr/bin/docker pull ${VAULT_IMAGE}
       ExecStart=/usr/bin/docker run \\
         --net bridge -m 0b \\
         --log-driver=json-file --log-opt max-size=50m --log-opt max-file=10 \\
         -p 8200:8200 \\
         -v /etc/certs:/etc/certs \\
         -v /etc/vault:/vault/config \\
         --name vault \\
         --cap-add=IPC_LOCK \\
         ${VAULT_IMAGE} vault server -config /vault/config
       
       ExecStop=-/usr/bin/docker stop -t 45 vault
       
       [Install]
       WantedBy=multi-user.target

   - name: docker-vault-dev.service
     enable: true
     content: |
       [Unit]
       Description=Dev Daemon for vault
       After=docker.service
       Requires=docker.service
       
       [Service]
       Restart=on-failure
       StartLimitInterval=20
       StartLimitBurst=5
       TimeoutStartSec=0
       Environment="HOME=/root"
       ExecStartPre=-/usr/bin/docker kill dev-vault
       ExecStartPre=-/usr/bin/docker rm dev-vault
       ExecStartPre=-/usr/bin/docker pull ${VAULT_IMAGE}
       ExecStart=/usr/bin/docker run \\
         --net bridge -m 0b \\
         -p 8200:8200 \\
         --name dev-vault \\
         --cap-add=IPC_LOCK \\
         ${VAULT_IMAGE} server -dev
       
       ExecStop=-/usr/bin/docker stop -t 45 dev-vault
       
       [Install]
       WantedBy=multi-user.target
EOF

