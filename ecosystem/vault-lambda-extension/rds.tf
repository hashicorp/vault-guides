resource "random_password" "password" {
  length  = 32
  special = false
}

resource "aws_db_instance" "main" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "12.3"
  instance_class         = var.db_instance_type
  name                   = "lambdadb"
  username               = "vaultadmin"
  password               = random_password.password.result
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
}
