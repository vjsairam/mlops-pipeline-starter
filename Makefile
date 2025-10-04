.PHONY: help init install install-dev clean test lint format type-check security-check docs serve-docs docker-build docker-run deploy-pipelines deploy-serving

PYTHON := python3
PIP := $(PYTHON) -m pip
PROJECT_NAME := mlops-pipeline
DOCKER_REGISTRY := your-registry.io
VERSION := $(shell git describe --tags --always --dirty)

# Default target
help:
	@echo "MLOps Pipeline - Development Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make init          - Initialize project (create venv, install deps)"
	@echo "  make install       - Install production dependencies"
	@echo "  make install-dev   - Install development dependencies"
	@echo ""
	@echo "Development:"
	@echo "  make test          - Run all tests"
	@echo "  make test-unit     - Run unit tests only"
	@echo "  make test-integration - Run integration tests"
	@echo "  make test-e2e      - Run end-to-end tests"
	@echo "  make lint          - Run linting checks"
	@echo "  make format        - Format code with black"
	@echo "  make type-check    - Run type checking with mypy"
	@echo "  make security-check - Run security checks"
	@echo "  make clean         - Clean build artifacts"
	@echo ""
	@echo "Documentation:"
	@echo "  make docs          - Build documentation"
	@echo "  make serve-docs    - Serve documentation locally"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build  - Build Docker images"
	@echo "  make docker-push   - Push Docker images to registry"
	@echo "  make docker-run    - Run services locally with docker-compose"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-pipelines ENV=<env> - Deploy pipelines to environment"
	@echo "  make deploy-serving ENV=<env>   - Deploy serving to environment"
	@echo "  make deploy-all ENV=<env>       - Deploy everything"
	@echo ""
	@echo "MLOps:"
	@echo "  make train         - Run training pipeline locally"
	@echo "  make evaluate      - Run evaluation pipeline"
	@echo "  make serve         - Start model serving locally"
	@echo "  make monitor       - Start monitoring stack"

# Setup commands
init: clean
	$(PYTHON) -m venv venv
	. venv/bin/activate && $(PIP) install --upgrade pip setuptools wheel
	. venv/bin/activate && $(PIP) install -e ".[dev]"
	. venv/bin/activate && pre-commit install
	@echo "Environment setup complete. Run 'source venv/bin/activate' to activate."

install:
	$(PIP) install -r requirements.txt

install-dev:
	$(PIP) install -r requirements-dev.txt
	pre-commit install

# Testing commands
test:
	pytest tests/ -v --cov --cov-report=term-missing

test-unit:
	pytest tests/unit -v -m unit

test-integration:
	pytest tests/integration -v -m integration

test-e2e:
	pytest tests/e2e -v -m e2e

test-coverage:
	pytest tests/ --cov --cov-report=html --cov-report=xml
	@echo "Coverage report generated in htmlcov/index.html"

# Code quality commands
lint:
	ruff check .
	black --check .
	mypy mlops/ pipelines/ serving/

format:
	black .
	ruff check --fix .

type-check:
	mypy mlops/ pipelines/ serving/ --ignore-missing-imports

security-check:
	bandit -r mlops/ pipelines/ serving/ -ll
	safety check --json

pre-commit:
	pre-commit run --all-files

# Documentation
docs:
	cd docs && $(MAKE) html

serve-docs:
	cd docs/_build/html && python -m http.server 8000

# Cleaning
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -rf build/ dist/ htmlcov/ .coverage coverage.xml

# Docker commands
docker-build:
	docker build -t $(DOCKER_REGISTRY)/$(PROJECT_NAME)-training:$(VERSION) -f serving/containers/Dockerfile.training .
	docker build -t $(DOCKER_REGISTRY)/$(PROJECT_NAME)-serving:$(VERSION) -f serving/containers/Dockerfile.serving .
	docker build -t $(DOCKER_REGISTRY)/$(PROJECT_NAME)-monitoring:$(VERSION) -f observability/monitoring/Dockerfile .

docker-push:
	docker push $(DOCKER_REGISTRY)/$(PROJECT_NAME)-training:$(VERSION)
	docker push $(DOCKER_REGISTRY)/$(PROJECT_NAME)-serving:$(VERSION)
	docker push $(DOCKER_REGISTRY)/$(PROJECT_NAME)-monitoring:$(VERSION)

docker-run:
	docker-compose up -d

docker-stop:
	docker-compose down

# Kubernetes/Deployment commands
deploy-pipelines:
ifndef ENV
	$(error ENV is not set. Use: make deploy-pipelines ENV=dev)
endif
	kubectl apply -k pipelines/manifests/overlays/$(ENV)
	@echo "Pipelines deployed to $(ENV) environment"

deploy-serving:
ifndef ENV
	$(error ENV is not set. Use: make deploy-serving ENV=dev)
endif
	kubectl apply -k serving/manifests/overlays/$(ENV)
	@echo "Serving deployed to $(ENV) environment"

deploy-monitoring:
ifndef ENV
	$(error ENV is not set. Use: make deploy-monitoring ENV=dev)
endif
	kubectl apply -k observability/monitoring/manifests/overlays/$(ENV)
	@echo "Monitoring deployed to $(ENV) environment"

deploy-all: deploy-pipelines deploy-serving deploy-monitoring

# MLOps workflow commands
train:
	python -m pipelines.train.main --config config/pipelines/train.yaml

evaluate:
	python -m pipelines.eval.main --config config/pipelines/eval.yaml

promote:
	python -m pipelines.promote.main --config config/pipelines/promote.yaml

serve:
	uvicorn serving.api.main:app --reload --host 0.0.0.0 --port 8000

monitor:
	docker-compose -f observability/docker-compose.monitoring.yml up -d
	@echo "Monitoring stack started. Grafana: http://localhost:3000"

# Feature store commands
feature-apply:
	cd feature_store && feast apply

feature-materialize:
	cd feature_store && feast materialize-incremental $(shell date -u +"%Y-%m-%dT%H:%M:%S")

feature-ui:
	cd feature_store && feast ui

# Data validation
validate-data:
	python -m data_quality.validate --dataset $(DATASET)

# Infrastructure commands
infra-plan:
ifndef ENV
	$(error ENV is not set. Use: make infra-plan ENV=dev)
endif
	cd infrastructure/terraform && terraform plan -var-file=environments/$(ENV).tfvars

infra-apply:
ifndef ENV
	$(error ENV is not set. Use: make infra-apply ENV=dev)
endif
	cd infrastructure/terraform && terraform apply -var-file=environments/$(ENV).tfvars

# Utility commands
check-env:
	@echo "Python version: $(shell $(PYTHON) --version)"
	@echo "Pip version: $(shell $(PIP) --version)"
	@echo "Project version: $(VERSION)"
	@echo "Docker version: $(shell docker --version 2>/dev/null || echo 'Not installed')"
	@echo "Kubectl version: $(shell kubectl version --client --short 2>/dev/null || echo 'Not installed')"
	@echo "Terraform version: $(shell terraform version -json 2>/dev/null | jq -r '.terraform_version' || echo 'Not installed')"

# Development database
db-start:
	docker run -d --name mlops-postgres \
		-e POSTGRES_USER=mlops \
		-e POSTGRES_PASSWORD=mlops \
		-e POSTGRES_DB=mlops \
		-p 5432:5432 \
		postgres:14

db-stop:
	docker stop mlops-postgres && docker rm mlops-postgres

# MLflow server
mlflow-server:
	mlflow server \
		--backend-store-uri sqlite:///mlflow.db \
		--default-artifact-root ./mlruns \
		--host 0.0.0.0 \
		--port 5000

# Airflow
airflow-init:
	cd pipelines && airflow db init
	cd pipelines && airflow users create \
		--username admin \
		--password admin \
		--firstname Admin \
		--lastname User \
		--role Admin \
		--email admin@example.com

airflow-start:
	cd pipelines && airflow webserver -D
	cd pipelines && airflow scheduler -D

airflow-stop:
	pkill -f "airflow webserver" || true
	pkill -f "airflow scheduler" || true