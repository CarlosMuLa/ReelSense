terraform{
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    backend "s3" {
    bucket = var.terraform_state_bucket # El bucket manual que creaste
    key    = "reelsense/terraform.tfstate"  # La ruta y nombre del archivo que se guardará
    region = "us-east-1"
  }
}



resource "aws_s3_bucket" "reelsense_storage" {
  bucket = "reelsense-dataset-mlops-carlos" 
}

# 3. Seguridad y Redes (Security Groups)
resource "aws_security_group" "ec2_sg" {
  name        = "reelsense-ec2-sg"
  description = "Permitir SSH y trafico de salida"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # En produccion usa solo tu IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "reelsense-rds-sg"
  description = "Permitir acceso a Postgres"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # Permite acceso desde la EC2
    cidr_blocks     = ["0.0.0.0/0"]                  # Permite acceso desde tu PC
  }
}

# 4. Identidad (IAM)
resource "aws_iam_role" "reelsense_ec2_role" {
  name = "ReelSense_EC2_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "reelsense_s3_rw" {
  name = "ReelSenseS3ReadWritePolicy"
  role = aws_iam_role.reelsense_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.reelsense_storage.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.reelsense_storage.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "reelsense_profile" {
  name = "ReelSenseEC2Profile"
  role = aws_iam_role.reelsense_ec2_role.name
}

# 5. Cómputo (EC2)
resource "aws_instance" "reelsense_ec2" {
  ami                  = "ami-098e39bafa7e7303d"
  instance_type        = "t3.micro"
  key_name             = var.key_pair_name
  iam_instance_profile = aws_iam_instance_profile.reelsense_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y unzip

    mkdir -p /root/.kaggle
    echo '{"username":"${var.kaggle_username}","key":"${var.kaggle_key}"}' > /root/.kaggle/kaggle.json
    chmod 600 /root/.kaggle/kaggle.json
    
    curl -L -o /tmp/letterboxd.zip https://www.kaggle.com/api/v1/datasets/download/gsimonx37/letterboxd
    unzip /tmp/letterboxd.zip -d /tmp/letterboxd
    aws s3 sync /tmp/letterboxd s3://${aws_s3_bucket.reelsense_storage.bucket}/dataset
  EOF

  tags = { Name = "ReelSense_EC2" }
}

# 6. Base de Datos (RDS con pgvector)
resource "aws_db_instance" "reelsense_db" {
  identifier             = "mlops-vector-db"
  engine                 = "postgres"
  engine_version         = "17" # Soporta pgvector
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

output "db_endpoint" {
  value = aws_db_instance.reelsense_db.endpoint
}