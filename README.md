# ReelSense 🎬

ReelSense es un proyecto de MLOps centrado en un sistema de recomendaciones de películas. Integra un pipeline completo de Machine Learning, infraestructura gestionada como código en la nube (AWS), y una interfaz de usuario interactiva.

## 🏗️ Arquitectura del Proyecto

El repositorio está organizado en los siguientes directorios principales:

- **`etl/`**: Contiene scripts de Python y Jupyter Notebooks para la extracción, transformación de datos, y entrenamiento de modelos. Utiliza **MLflow** para el seguimiento de experimentos y **DVC** para el versionado de datos y modelos.
- **`frontend/ReelSense/`**: Aplicación web desarrollada con **React, TypeScript y Vite** que consume las recomendaciones generadas.
- **`terraform/`**: Código de **Terraform** para aprovisionar y gestionar automáticamente la infraestructura requerida en **AWS**.
- **`.github/workflows/`**: Pipelines de **GitHub Actions** que configuran la Integración y Despliegue Continuo (CI/CD) para el frontend, la infraestructura y los flujos de ETL.

## 🛠️ Requisitos Previos

Para ejecutar y desarrollar en este proyecto, necesitas:

- [Node.js](https://nodejs.org/) y npm
- [Python 3.8+](https://www.python.org/)
- [Terraform](https://www.terraform.io/)
- [DVC](https://dvc.org/)
- [AWS CLI](https://aws.amazon.com/cli/) configurado con tus credenciales

## 🚀 Guía Rápida con `make`

Puedes utilizar el `Makefile` incluido para ejecutar rápidamente las tareas principales:

| Comando | Descripción |
|---------|-------------|
| `make install` | Instala dependencias del frontend (npm) y backend/ETL (pip) |
| `make dvc-pull` | Descarga los datos y modelos versionados con DVC |
| `make run-frontend` | Levanta el servidor de desarrollo en local (Vite) |
| `make tf-init` | Inicializa el entorno de Terraform |
| `make tf-apply` | Despliega la infraestructura en AWS |
| `make run-etl` | Ejecuta el script para la subida de inferencia (`upload_inference.py`) |
