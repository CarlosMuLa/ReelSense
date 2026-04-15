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