.PHONY: install dvc-pull run-frontend tf-init tf-plan tf-apply tf-destroy run-etl clean

FRONTEND_DIR = frontend/ReelSense
ETL_DIR = etl
TF_DIR = terraform

install:
	@echo "Instalando dependencias del Frontend..."
	cd $(FRONTEND_DIR) && npm install
	@echo "Instalando dependencias de ETL (Python)..."
	cd $(ETL_DIR) && pip install -r requirements.txt

dvc-pull:
	@echo "Descargando datos y modelos desde DVC..."
	dvc pull

run-frontend:
	@echo "Iniciando el servidor de desarrollo del Frontend..."
	cd $(FRONTEND_DIR) && npm run dev

tf-init:
	@echo "Inicializando Terraform..."
	cd $(TF_DIR) && terraform init

tf-plan:
	@echo "Generando plan de Terraform..."
	cd $(TF_DIR) && terraform plan

tf-apply:
	@echo "Aplicando cambios en Terraform (AWS)..."
	cd $(TF_DIR) && terraform apply -auto-approve

tf-destroy:
	@echo "Destruyendo infraestructura..."
	cd $(TF_DIR) && terraform destroy -auto-approve

run-etl:
	@echo "Ejecutando script de inferencia..."
	cd $(ETL_DIR) && python upload_inference.py

clean:
	@echo "Limpiando archivos temporales locales..."
	rm -rf $(FRONTEND_DIR)/node_modules
	rm -rf $(TF_DIR)/.terraform
