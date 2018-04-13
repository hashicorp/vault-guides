package com.hashicorp.vault.spring.demo;

import javax.persistence.AttributeConverter;
import org.springframework.vault.core.VaultOperations;
import org.springframework.vault.support.Ciphertext;
import org.springframework.vault.support.Plaintext;

public class TransitConverter implements AttributeConverter<String, String> {
	
	@Override
	public String convertToDatabaseColumn(String customer) {	
		VaultOperations vaultOps = BeanUtil.getBean(VaultOperations.class);
		Plaintext plaintext = Plaintext.of(customer);	
		String cipherText = vaultOps.opsForTransit().encrypt("order", plaintext).getCiphertext();
		return cipherText;
	}

	@Override
	public String convertToEntityAttribute(String customer) {
		VaultOperations vaultOps = BeanUtil.getBean(VaultOperations.class);
		Ciphertext ciphertext = Ciphertext.of(customer);
        String plaintext = vaultOps.opsForTransit().decrypt("order", ciphertext).asString();
		return plaintext;
	}

}
