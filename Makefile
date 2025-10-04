.PHONY: help init install install-dev clean test lint format type-check security-check docker-build docker-up docker-down

PYTHON := python3
PIP := $(PYTHON) -m pip
PROJECT_NAME := data-pipeline
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "0.1.0")

# Default target
help:
	@echo "Data Pipeline - Development Commands"
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
	@echo "Docker:"
	@echo "  make docker-build  - Build Docker images"
	@echo "  make docker-up     - Start all services"
	@echo "  make docker-down   - Stop all services"
	@echo "  make docker-logs   - View service logs"
	@echo ""
	@echo "Pipeline:"
	@echo "  make pipeline-validate - Validate pipeline configurations"
	@echo "  make data-quality  - Run data quality checks"

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
	$(PIP) install -e .

# Testing commands
test: test-unit test-integration

test-unit:
	pytest tests/unit -v --cov=data_quality --cov-report=term-missing

test-integration:
	pytest tests/integration -v

test-e2e:
	pytest tests/e2e -v

test-coverage:
	pytest --cov=data_quality --cov-report=html --cov-report=term-missing

# Code quality commands
lint:
	black --check .
	ruff check .
	pylint data_quality/

format:
	black .
	ruff check --fix .
	isort .

type-check:
	mypy data_quality/ --ignore-missing-imports

security-check:
	bandit -r data_quality/ -ll
	safety check
	pip-audit

# Docker commands
docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

docker-restart:
	docker compose restart

docker-clean:
	docker compose down -v
	docker system prune -f

# Pipeline commands
pipeline-validate:
	@echo "Validating pipeline configurations..."
	python -m data_quality.validators.base_validator

data-quality:
	@echo "Running data quality checks..."
	pytest tests/unit/test_validators.py -v

# Cleanup commands
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "*.pyo" -delete 2>/dev/null || true
	find . -type f -name ".coverage" -delete 2>/dev/null || true
	rm -rf build/ dist/ htmlcov/ .coverage coverage.xml

# Development utilities
.env:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
		echo "IMPORTANT: Edit .env and replace all CHANGE_ME_* values with actual secrets!"; \
	else \
		echo ".env file already exists"; \
	fi

setup-dev: init .env
	@echo "Development environment ready!"
	@echo "Next steps:"
	@echo "  1. Edit .env with your configuration"
	@echo "  2. Run: make docker-up"
	@echo "  3. Access services at:"
	@echo "     - Airflow: http://localhost:8080"
	@echo "     - Grafana: http://localhost:3000"
	@echo "     - Prometheus: http://localhost:9090"

# Pre-commit
pre-commit:
	pre-commit run --all-files

pre-commit-update:
	pre-commit autoupdate
