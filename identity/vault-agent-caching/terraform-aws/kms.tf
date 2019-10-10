//--------------------------------------------------------------------
// Resources

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 7

  tags = {
    Name = "${var.environment_name}-vault-kms-unseal-key"
  }
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.environment_name}-vault-kms-unseal-key"
  target_key_id = aws_kms_key.vault.key_id
}

