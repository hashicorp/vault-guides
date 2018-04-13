package com.hashicorp.vault.spring.demo;

import javax.annotation.PostConstruct;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.vault.authentication.SessionManager;

@SpringBootApplication
public class VaultDemoOrderServiceApplication  {
	
	private static final Logger logger = LoggerFactory.getLogger(VaultDemoOrderServiceApplication.class);	
	
	@Autowired
    	private SessionManager sessionManager;

	@Value("${spring.datasource.username}")
	private String dbUser;

	@Value("${spring.datasource.password}")
	private String dbPass;

	public static void main(String[] args) {
		SpringApplication.run(VaultDemoOrderServiceApplication.class, args);
	}

	@PostConstruct
	public void initIt() throws Exception {
		logger.info("Got Vault Token: " + sessionManager.getSessionToken().getToken());
		logger.info("Got DB User: " + dbUser);
		//logger.info("Got DB Pass: " + dbPass);
	}
}
