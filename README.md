# AWS Three-tier Architecture Using Terraform

This project is used to automate the process of a three tier architecture in AWS.
We will create a total of 46 AWS resources through Terraform, including;

* Creates a VPC with the CIDR blocks provided in the region 
* Creates subnets for each layer
* Creates an IGW and NAT gateway
* Creates Route tables
* Creates a RDS instance
* Configures security group for Web layer
* EC2 instances for webservers
* Application load balancer

## Architecture
![Updated_diagram]https://drive.google.com/drive/folders/1x90RXp6580xV7I1w5Rsuu--DsSJ_leHy


## Prerequisites

1. The AWS CLI configured with AWS account credentials, and a familiarity with AWS cloud architecture
2. Terraform locally installed 
3. A text editor such as Atom, Visual Studio Code, or PyCharm, with the Terraform plug-in installed
4. A source code management tool such as github,
5. Create a new directory for the four Terraform source files we will be working with: provider.tf,vpc.tf, asg.tf, db.tf, variable.tf and wordpress.sh

## provider.tf 

AWS will be our plug-in provider, so the top of provider.tf should include:
```
provider "aws" {
  region = var.region
}
```
## vpc.tf

This code will create a VPC along with 3 Public and 6 Private subnets, IGW to Public Subnets and NG to Private Subnets. Route Tables to configure traffic through IGW to Public Subnets and NG to Private Subnets and security grups. By configuring security grups which will set of firewall rules for loadbalancer, database and server. It will open neccesary ports to control the traffic to your load balancer through your VPC.


```
data "aws_availability_zones" "available" {}
module "vpc" {
  source                       = "terraform-aws-modules/vpc/aws"
  version                      = "2.64.0"
  name                         = "${var.namespace}-my-vpc"
  cidr                         = "10.0.0.0/16"
  azs                          = data.aws_availability_zones.available.names
  private_subnets              = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets               = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets             = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  create_database_subnet_group = true
  enable_nat_gateway           = true
  map_public_ip_on_launch      = true
}
module "lb_sg" {
  source = "terraform-in-action/sg/aws"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [{
    port        = 80
    cidr_blocks = ["0.0.0.0/0"]
  }]
}
module "websvr_sg" {
  source = "terraform-in-action/sg/aws"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port            = 8080
      security_groups = [module.lb_sg.security_group.id]
    },
    {
      port        = 22
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}
module "db_sg" {
  source = "terraform-in-action/sg/aws"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port            = 3306
      port            = 80
      security_groups = [module.websvr_sg.security_group.id]
  }]
}

```
## asg.tf

Load Balancer works with Launh templeted Auto Scaling to distribute incoming HTTP traffic across your targets to servers (healthy Amazon EC2 instances), database. This increases the scalability and availability of your application. You can enable  Load Balancer within multiple Availability Zones to increase the fault tolerance of your applications. 
Please make sure modify correct path of user_data under webserver aws launch templete resources.

```   
data "aws_ami" "centos" {
  owners      = ["125523088429"]
  most_recent = true
  filter {
    name   = "name"
    values = ["CentOS 7.9.2009 *"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
resource "aws_launch_template" "webserver" {
  name_prefix   = "${var.namespace}-template"
  image_id      = data.aws_ami.centos.id
  instance_type = "t2.micro"
  user_data     = filebase64("/home/ec2-user/project1_v2/wordpress.sh")
  key_name      = var.ssh_keypair

  vpc_security_group_ids = [aws_security_group.allow_tls.id]
}
resource "aws_autoscaling_group" "webserver" {
  name                = "${var.namespace}-asg"
  max_size            = 99
  min_size            = 1
  vpc_zone_identifier = module.vpc.public_subnets
  target_group_arns   = module.alb.target_group_arns
  launch_template {
    id      = aws_launch_template.webserver.id
    version = aws_launch_template.webserver.latest_version
  }
}
module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "~> 5.0"
  name               = "${var.namespace}-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.lb_sg.security_group.id]
  http_tcp_listeners = [
    {
      port               = 80,
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
  target_groups = [
    {
      name_prefix      = "websvr"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "instance"
    }
  ]
}
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "allow_tls"
  }
}
```

## db.tf

Rds instance supported by MySQL will be created

```
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
```

## variable.tf
 Please alter desired region on "default region variable" 

```
variable "namespace" {
  description = "The project namespace for resource naming"
  default     = "threetier"
}
variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}
variable "ssh_keypair" {
  description = "SSH keypair to use for autoscaling"
  default     = null
  type        = string
}
variable "cluster_engine" {
  description = "Aurora cluster engine"
  type        = string
  default     = "MySQL"
}
```

## Initilazing the Terraform

To install and create the resources:
1-Before creating all so you need to initialise Terraform which needs to be done only once in a folder.Initialise Terraform with the following command:

```
terraform init
```
You can check any syntax by using:

```
terraform validate 
```

you can see all changes on terraform plan then create with terraform apply commands:

```
terraform plan  --auto-approve
terraform apply --auto-approve

```

## Deleting the Resoruces

To delete the Application,

* Destroy Terraform configuration:

```
terraform destroy 
```


