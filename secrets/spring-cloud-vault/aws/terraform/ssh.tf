resource "tls_private_key" "springboot" {
  algorithm = "RSA"
}

resource "null_resource" "springboot" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.springboot.private_key_pem}\" > springboot.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 springboot.pem"
  }
}
