terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Roles: LabRole 
data "aws_iam_role" "labrole" {
  name = "LabRole"
}

# =========================================================================
# RED (VPC, Subnets, Internet Gateway, Route Tables)
# =========================================================================

# VPC para el clúster
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true  # Agregado para facilitar la resolución interna de Kubernetes
  enable_dns_support   = true

  tags = {
    Name = "proyecto-devops-vpc"
  }
}

# Subnets Públicas con las etiquetas requeridas para balanceadores de carga en EKS
resource "aws_subnet" "eks_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "eks-subnet-1"
    "kubernetes.io/role/elb" = "1" # Indica a AWS dónde poner los Balanceadores de Carga externos
  }
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "eks-subnet-2"
    "kubernetes.io/role/elb" = "1"
  }
}

# Internet Gateway y Tablas de Ruteo
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "eks-route-table"
  }
}

resource "aws_route_table_association" "rta_1" {
  subnet_id      = aws_subnet.eks_subnet_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_2" {
  subnet_id      = aws_subnet.eks_subnet_2.id
  route_table_id = aws_route_table.rt.id
}

# =========================================================================
# SECURITY GROUPS (Grupos de Seguridad)
# =========================================================================

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-security-group"
  description = "Grupo de seguridad basico para el cluster EKS y comunicacion de nodos"
  vpc_id      = aws_vpc.eks_vpc.id

  # Regla de Entrada (Ingress): Permite tráfico en puertos comunes de apps (80, 443, 8080) desde internet

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de Salida (Egress): Permite que el clúster y nodos salgan a internet (necesario para descargar imágenes de ECR/Docker Hub)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # "-1" significa todos los protocolos
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

# =========================================================================
# EKS (Elastic Kubernetes Service)
# =========================================================================

resource "aws_eks_cluster" "eks" {
  name     = "despachos-ventas-cluster"
  role_arn = data.aws_iam_role.labrole.arn
  
  vpc_config {
    subnet_ids = [
      aws_subnet.eks_subnet_1.id,
      aws_subnet.eks_subnet_2.id
    ]
    # Se añade el grupo de seguridad personalizado al clúster
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "workers"
  node_role_arn   = data.aws_iam_role.labrole.arn
  subnet_ids = [
    aws_subnet.eks_subnet_1.id,
    aws_subnet.eks_subnet_2.id
  ]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  # Los nodos heredarán la configuración de red y las reglas básicas del clúster automáticamente,
  # pero si en el futuro necesitas añadir configuraciones de lanzamiento avanzadas, puedes asociar el SG aquí.
}

# =========================================================================
# ECR (Elastic Container Registry)
# =========================================================================

# 1. Registro para el Microservicio de Despachos (Backend 1)
resource "aws_ecr_repository" "back_despachos_repo" {
  name         = "back-despachos-springboot"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "back-despachos"
  }
}

# 2. Registro para el Microservicio de Ventas (Backend 2)
resource "aws_ecr_repository" "back_ventas_repo" {
  name         = "back-ventas-springboot"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "back-ventas"
  }
}

# 3. Registro para la aplicación Frontend
resource "aws_ecr_repository" "frontend_repo" {
  name         = "front-despacho"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "front-despacho"
  }
}

# =========================================================================
# OUTPUTS
# =========================================================================
output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "ecr_url_back_despachos" {
  value = aws_ecr_repository.back_despachos_repo.repository_url
}

output "ecr_url_back_ventas" {
  value = aws_ecr_repository.back_ventas_repo.repository_url
}

output "ecr_url_frontend" {
  value = aws_ecr_repository.frontend_repo.repository_url
}