resource "random_password" "password" { #A
  length           = 16
  special          = true
  override_special = "_%@/'\""
}
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  identifier           = "${var.namespace}dbinstance"
  name                 = "${var.namespace}dbinstance"
  username             = "admin"
  password             = "password"
  db_subnet_group_name = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.lb_sg.security_group.id]
  skip_final_snapshot  = true
}
