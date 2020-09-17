provider "aws" {
	region = "ap-south-1"
	profile = "Akshat"
}

resource "aws_vpc" "task3-vpc" {
	cidr_block = "192.170.0.0/16"
	instance_tenancy = "default"
	enable_dns_hostnames= "true"

	tags = {
		Name = "Task3_VPC"
       }
}

resource "aws_subnet" "task3-subnet-1a" {
	vpc_id = "${aws_vpc.task3-vpc.id}"
	cidr_block = "192.170.1.0/24"
	availability_zone = "ap-south-1a"
	map_public_ip_on_launch = true

	tags = {
		Name = "Public_Subnet"
       }
}

resource "aws_subnet" "task3-subnet-1b" {
	vpc_id = "${aws_vpc.task3-vpc.id}"
	cidr_block = "192.170.2.0/24"
	availability_zone = "ap-south-1b"

	tags = {
		Name = "Private_Subnet"
       }
}

resource "aws_internet_gateway" "task3-internet-gateway" {
	vpc_id = "${aws_vpc.task3-vpc.id}"
	tags = {
		Name = "Task3_internet_gateway"
	}
}

resource "aws_route_table" "task3-route-table" {
	vpc_id = "${aws_vpc.task3-vpc.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.task3-internet-gateway.id}"
	}

	tags = {
		Name = "Task3_route_table"
	}
}

resource "aws_route_table_association" "task3-route-1a" {
	subnet_id = aws_subnet.task3-subnet-1a.id
	route_table_id = "${aws_route_table.task3-route-table.id}"
}

resource "tls_private_key"  "task3key"{
	algorithm= "RSA"
}

resource  "aws_key_pair"   "generate_key"{
	key_name= "task3key"
	public_key= "${tls_private_key.task3key.public_key_openssh}"
	
	depends_on = [
		tls_private_key.task3key
		]
}

resource "local_file"  "store_key_value"{
	content= "${tls_private_key.task3key.private_key_pem}"
 	filename= "task3key.pem"
	
	depends_on = [
		tls_private_key.task3key
	]
}

resource "aws_security_group" "sg1" {
	name = "wordpress-sg"
	description = "Allow ssh and http"
	vpc_id = "${aws_vpc.task3-vpc.id}"
	
ingress {
	description = "http"
	from_port = 0
	to_port = 80
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
}

ingress {
	description = "ssh"
	from_port = 0
	to_port = 22
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
}

egress {
	from_port = 0
	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
}

tags = {
	Name = "wordpress-sg"
	}
}

resource "aws_security_group" "sg2" {
	name = "mysql-sg"
	description = "Allow MySQL"
	vpc_id = "${aws_vpc.task3-vpc.id}"

ingress {
	description = "MYSQL/Aurora"
	from_port = 0
	to_port = 3306
	protocol = "tcp"
}

egress {
	from_port = 0
	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
}
	tags = {
		Name = "mysql-sg"
	}
}

resource "aws_instance"  "task3_wordpressOS"{
		ami= "ami-00116985822eb866a"
		instance_type= "t2.micro"
		key_name=  "task3key"
		vpc_security_group_ids= ["${aws_security_group.sg1.id}"]
 		subnet_id="${aws_subnet.task3-subnet-1a.id}"
tags= {
     name= "Task3_WordPress_OS"
         }
}


resource "aws_instance"  "task3_MySQLOS"{
		ami= "ami-08706cb5f68222d09"
		instance_type= "t2.micro"
		key_name=  "task3key"
		vpc_security_group_ids= ["${aws_security_group.sg2.id}"]
 		subnet_id="${aws_subnet.task3-subnet-1b.id}"
tags= {
     name= "Task3_MYSQL_OS"
         }
}

output "myos_ip" {
  value = aws_instance.task3_wordpressOS.public_ip
}
