resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet"
  subnet_ids = data.aws_subnets.default.ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-db"
  engine         = var.db_engine
  engine_version = var.db_engine == "postgres" ? "16" : "8.0"
  instance_class = var.db_instance_class

  allocated_storage = var.db_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = replace(var.name, "-", "_")
  username = "admin_user"
  password = var.db_password

  multi_az               = var.db_multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = var.tags
}
