package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/hashicorp/vault/api"
)

func main() {
	config := api.DefaultConfig()
	vaultClient, err := api.NewClient(config)
	if err != nil {
		log.Fatal(err)
	}

	//Read service account token
	content, err := ioutil.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/token")
	if err != nil {
		log.Fatal(err)
	}

	//Lookup VAULT_ROLE Environment variable
	role, set := os.LookupEnv("VAULT_ROLE")
	if !set {
		role = "demo"
	}
	fmt.Printf("Using role=%s", role)

	//Lookup VAULT_LOGIN_PATH Environment variable
	mount_path, set := os.LookupEnv("VAULT_LOGIN_PATH")
	if !set {
		mount_path = "auth/kubernetes/login"
	}
	fmt.Printf("Using mount_path=%s", mount_path)

	//Attempt Vault login
	s, err := vaultClient.Logical().Write(mount_path, map[string]interface{}{
		"role": role,
		"jwt":  string(content[:]),
	})
	if err != nil {
		fmt.Println(err)
		return
	}

	log.Println("==> WARNING: Don't ever write secrets to logs.")
	log.Println("==>          This is for demonstration only.")
	log.Println(s.Auth.ClientToken)

	//Lookup SECRET_PATH Environment variable
	keyName, set := os.LookupEnv("SECRET_PATH")
	if !set {
		//Looking SECRET_KEY for previous version compatibility
		keyName, set := os.LookupEnv("SECRET_KEY")
		if !set {
			keyName = "secret/creds"
			fmt.Printf("Using default secret key=%s", keyName)
		} else {
			fmt.Printf("Using secret key=%s", keyName)
		}
	} else {
		fmt.Printf("Using secret path=%s", keyName)
	}

	//Read secret
	vaultClient.SetToken(s.Auth.ClientToken)
	secretValues, err := vaultClient.Logical().Read(keyName)
	if err != nil {
		fmt.Println(err)
	}
	log.Printf("secret %s -> %v", keyName, secretValues)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	// Keep token renewed
	renewer, err := vaultClient.NewRenewer(&api.RenewerInput{
		Secret: s,
		Grace:  1 * time.Second,
	})
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Starting renewal loop")
	go renewer.Renew()
	defer renewer.Stop()

	for {
		select {
		case err := <-renewer.DoneCh():
			if err != nil {
				log.Fatal(err)
			}
		case renewal := <-renewer.RenewCh():
			log.Printf("Successfully renewed: %#v", renewal)
			secretValues, err := vaultClient.Logical().Read(keyName)
			if err != nil {
				fmt.Println(err)
			}
			log.Printf("secret %s -> %v", keyName, secretValues)
		case <-quit:
			log.Fatal("Shutdown signal received, exiting...")
		}
	}

}
