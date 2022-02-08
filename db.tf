resource "random_password" "password" { #A
  length           = 16
  special          = true
  override_special = "_%@/'\""
}
# resource "aws_db_instance" "default" {
#   allocated_storage    = 10
#   engine               = "mysql"
#   engine_version       = "8.0"
#   instance_class       = "db.t2.micro"
#   identifier           = "${var.namespace}dbinstance"
#   name                 = "${var.namespace}dbinstance"
#   username             = "admin"
#   password             = random_password.password.result
#   db_subnet_group_name = module.vpc.database_subnet_group
#   vpc_security_group_ids = [module.lb_sg.security_group.id]
#   skip_final_snapshot  = true
# }
# resource “aws_rds_cluster” “default” {
# 	cluster_identifier = var.namespace
# 	engine = var.cluster_engine
# 	engine_version = var.engine_version
# 	database_name = var.identifier
# 	master_username = var.username
# 	master_password = random_password.password.result
# 	db_subnet_group_name = aws_db_subnet_group.db.name
# 	skip_final_snapshot = true #used to delete the repo in the future without this you cant delete. There are bugs reported
# 	vpc_security_group_ids = [
# 		aws_security_group.db.id
# 	]
# }
# resource “aws_rds_cluster_instance” “cluster_instances” {
# 	count = 1
# 	identifier = “aurora-cluster-demo-${count.index +1}”
# 	cluster_identifier = var.identifier
# 	instance_class = “db.r4.large”
# 	engine_version = var.engine_version
# 	engine = var.engine
# 	publicly_accessible = var.publicly_accessible
	
# }
# resource “aws_rds_cluster_instance” “cluster_instances-reader” {
# 	count = 2
# 	identifier = “aurora-cluster-demo-reader-${count.index +2}”
# 	cluster_identifier = var.identifier
# 	instance_class = “db.r4.large”
# 	engine_version = var.engine_version
# 	engine = var.engine
# 	publicly_accessible = var.publicly_accessible
	
# }
