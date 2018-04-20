package com.hashicorp.vault.spring.demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RefreshScope
@RestController
public class SecretController {

	@Value("${secret:n/a}")
	String secret;

	@RequestMapping("/api/secret")
	public Secret secret() {
		return new Secret("secret", secret);
	}

}