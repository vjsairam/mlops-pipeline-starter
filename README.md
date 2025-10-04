# Data Pipeline

Production-ready data pipeline framework for building reliable, scalable data processing systems with built-in data quality validation, monitoring, and orchestration.

## Features

### Core Capabilities
- **Data Validation**: Great Expectations integration for data quality checks
- **Orchestration**: Apache Airflow for workflow management
- **Monitoring**: Prometheus/Grafana for metrics and observability
- **Data Processing**: Scalable batch and streaming data pipelines
- **Quality Assurance**: Automated data quality checks and reporting
- **Security**: Environment-based secrets management and access control

### Infrastructure & Deployment
- **Infrastructure as Code**: Terraform for cloud resource provisioning
- **Container Orchestration**: Docker Compose for local development
- **CI/CD**: GitHub Actions for automated testing and deployment
- **Observability**: Structured logging and distributed tracing
- **Scalability**: Resource limits and auto-scaling capabilities

## Quick Start

### Prerequisites
- Python 3.9+
- Docker & Docker Compose
- Git

### Local Development Setup

1. **Clone the repository**
```bash
git clone https://github.com/yourorg/data-pipeline.git
cd data-pipeline
```

2. **Set up environment**
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# IMPORTANT: Generate secure secrets for all CHANGE_ME_* values
```

3. **Install dependencies**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements-dev.txt
pip install -e .
```

4. **Start services**
```bash
docker compose up -d
```

5. **Access services**
- Airflow: http://localhost:8080
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

## Project Structure

```
data-pipeline/
├── data_quality/           # Data validation and quality checks
│   ├── validators/         # Custom validators
│   └── great_expectations.yml
├── pipelines/              # Airflow DAGs and workflow definitions
├── infrastructure/         # Infrastructure as Code
│   └── terraform/          # Terraform configurations
├── observability/          # Monitoring and dashboards
│   ├── monitoring/         # Prometheus configs
│   └── dashboards/         # Grafana dashboards
├── tests/                  # Test suite
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docker-compose.yml      # Local development environment
├── .env.example            # Environment variables template
└── pyproject.toml          # Project configuration
```

## Development

### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=data_quality --cov-report=html

# Run specific test types
pytest tests/unit
pytest tests/integration
```

### Code Quality
```bash
# Format code
black .

# Lint code
ruff check .

# Type checking
mypy data_quality/

# Run all pre-commit hooks
pre-commit run --all-files
```

### Adding a New Pipeline
1. Create DAG file in `pipelines/`
2. Add data quality checks in `data_quality/validators/`
3. Add tests in `tests/`
4. Update documentation

## Configuration

All configuration is managed through environment variables. See `.env.example` for all available options.

### Key Configuration Areas
- **Database**: PostgreSQL connection settings
- **Cache**: Redis configuration
- **Monitoring**: Prometheus/Grafana settings
- **Security**: JWT, API keys, secrets management
- **Cloud**: AWS/GCP/Azure credentials (optional)

## Deployment

### Development
```bash
docker compose up -d
```

### Production
Production deployment uses GitHub Actions CI/CD pipeline:
1. Push to `main` branch triggers CI
2. Tests run automatically
3. Security scans execute
4. Docker images build on success

See `.github/workflows/ci.yml` for pipeline details.

## Monitoring

### Metrics
- Pipeline execution times
- Data quality scores
- System resource usage
- Error rates and types

### Dashboards
Access Grafana at http://localhost:3000 to view:
- Pipeline performance
- Data quality metrics
- System health

### Alerting
Configure alerts in:
- Slack (via webhook)
- Email (SMTP)
- PagerDuty (for critical issues)

## Security

### Secrets Management
- Never commit `.env` file
- Use strong passwords (generated via `openssl rand -hex 32`)
- Rotate credentials regularly
- Use separate credentials per environment

### Security Features
- Pre-commit hooks for secret detection
- Automated security scanning in CI
- Container security hardening
- Network isolation

## Troubleshooting

### Common Issues

**Services won't start**
```bash
# Check logs
docker compose logs

# Verify .env file exists
ls -la .env

# Check port conflicts
docker compose ps
```

**Database connection errors**
```bash
# Verify PostgreSQL is running
docker compose ps postgres

# Check credentials in .env
cat .env | grep POSTGRES
```

**Airflow tasks failing**
```bash
# Check Airflow logs
docker compose logs airflow-scheduler
docker compose logs airflow-webserver

# Access Airflow UI for detailed logs
open http://localhost:8080
```

## Contributing

### Development Workflow
1. Create feature branch
2. Make changes
3. Run tests locally
4. Submit pull request
5. CI runs automatically
6. Merge after approval

### Commit Message Format
Follow conventional commits:
```
feat: add new data validator
fix: resolve database connection issue
docs: update README with examples
test: add integration tests for pipeline
```

## License

Apache 2.0

## Support

- Issues: [GitHub Issues](https://github.com/yourorg/data-pipeline/issues)
- Documentation: [Full Docs](https://data-pipeline.readthedocs.io)

## Roadmap

- [ ] Add streaming data support
- [ ] Implement data lineage tracking
- [ ] Add data catalog integration
- [ ] Support for multiple orchestrators
- [ ] Enhanced observability features
