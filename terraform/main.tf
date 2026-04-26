terraform{
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_iam_role_policy" "reelsense_s3_rw" {
  name = "ReelSenseS3ReadWritePolicy"
  role = aws_iam_role.ReelSense_EC2_Role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::ReelSense_DB"
      },
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::ReelSense_DB/*"
      }
    ]
  })
}
resource "aws_iam_instance_profile" "reelsense_profile" {
  name = "ReelSenseEC2Profile"
  role = aws_iam_role.ReelSense_EC2_Role.name
}

resource "aws_ec2_instance" "ReelSense_EC2" {
  ami           = "ami-098e39bafa7e7303d" # Amazon Linux 2
  instance_type = "t3.micro"
  key_name      = var.key_pair_name # Asegúrate de tener un par de claves creado en AWS
  user_data     = <<-EOF
    #!/bin/bash
    
  EOF
  iam_instance_profile = aws_iam_instance_profile.reelsense_profile.name
  tags = {
    Name = "ReelSense_EC2"
  }
}

resource "aws_db_instance" "ReelSense_DB" {
  identifier           = "mlops-vector-db"
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.micro" 
  allocated_storage    = 20
  username             = var.db_username
  password             = var.db_password # Cámbiala por una tuya
  publicly_accessible  = true              # Necesario para conectarnos desde tu compu al inicio
  skip_final_snapshot  = true              # Para no generar respaldos costosos al borrarla
}

# Muestra el endpoint al terminar para que nos podamos conectar
output "db_endpoint" {
  value = aws_db_instance.ReelSense_DB.endpoint
}