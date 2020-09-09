# Java Sample App using Spring Cloud Vault (Vagrant)

Refer to the [Java Sample App using Spring Cloud Vault](https://learn.hashicorp.com/vault/developer/eaas-spring-demo) guide for step-by-step instruction.

----


## Command List

### Setup

```shell
# Create and configure a Linux machine. This takes about 3 minutes
$ vagrant up

# Connect to the demo machine
$ vagrant ssh demo

# On the demo machine, you should see 3 containers running
[vagrant@demo ~]$ docker ps
CONTAINER ID     IMAGE            COMMAND                  CREATED           STATUS           NAMES
684d8fb23ae5     spring           "java -Djava.secur..."   7 minutes ago     Up 7 minutes     spring
dc6a3454b323     vault:0.10.0     "docker-entrypoint..."   7 minutes ago     Up 7 minutes     vault
4093a45c209f     postgres         "docker-entrypoint..."   7 minutes ago     Up 7 minutes     postgres

# Check to verify that Vault is running
[vagrant@demo ~]$ docker logs vault

# The Spring server takes about 20 seconds to start. Check the Spring logs
[vagrant@demo ~]$ sleep 20s; docker logs spring -f
```

### Test the App

Invoke the `orders` API at http://localhost:8080/api/orders

```shell
# Create a new order data
$ tee payload.json<<EOF
{
  "customerName": "John",
  "productName": "Nomad"
}
EOF

# Send an order request using cURL
$ curl --request POST --header "Content-Type: application/json" \
       --data @payload.json http://localhost:8080/api/orders | jq

# Retrieve orders from DB using the app API
$ curl --header "Content-Type: application/json" \
       http://localhost:8080/api/orders | jq
```

Verify the data stored in the PostgreSQL DB to be encrypted:

```shell
# Check the 'orders' table in PostgreSQL DB
[vagrant@demo ~]$ docker exec -it postgres psql -U postgres -d postgres

postgres# select * from orders;
id |                     customer_name                     | product_name |       order_date
----+-------------------------------------------------------+--------------+-------------------------
 1 | vault:v1:Qj0lx5DSZvwcHeMOX/5UX/ErHTaDPA3mVlSSpaXd1tbM | VE           | 2018-04-18 21:56:37.924
 2 | vault:v1:UwL3HnyqTUac5ElS5WYAuNg3NdIMFtd6vvwukL+FaKun | Nomad        | 2018-04-18 22:07:42.916
(2 rows)

postgres# \q
```
