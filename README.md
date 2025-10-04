# MLOps Pipeline Starter

Production-ready template for continuous training and continuous delivery (CT/CD) of ML models with data validation, feature pipelines, experiment tracking, model registry, CI/CD to real-time inference with canary rollouts and drift monitoring.

## Features

### Core MLOps Capabilities
- **Continuous Training**: Automated model retraining on data/performance triggers
- **Continuous Delivery**: GitOps-based deployment with canary rollouts
- **Data Validation**: Great Expectations integration for data quality checks
- **Feature Store**: Feast-based feature management with online/offline stores
- **Experiment Tracking**: MLflow/Weights & Biases integration
- **Model Registry**: Centralized model versioning and promotion
- **Model Governance**: Model cards, explainability (SHAP/LIME), fairness checks
- **Monitoring**: Prometheus/Grafana with drift detection (Evidently)
- **Security**: Artifact signing (Cosign), SLSA provenance, secrets management

### Infrastructure & Deployment
- **Infrastructure as Code**: Terraform for AWS/GCP/Azure
- **Container Orchestration**: Kubernetes with Helm charts
- **GitOps**: ArgoCD for declarative deployments
- **Canary Deployments**: Argo Rollouts with automatic rollback
- **Load Balancing**: Service mesh integration
- **Auto-scaling**: HPA/VPA based on metrics

## Quick Start

### Prerequisites
- Python 3.8+
- Docker & Docker Compose
- Kubernetes cluster (for production)
- Cloud provider account (AWS/GCP/Azure)

### Local Development Setup

1. **Clone the repository**
```bash
git clone https://github.com/yourorg/mlops-pipeline-starter.git
cd mlops-pipeline-starter
```

2. **Initialize the environment**
```bash
make init
```

3. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. **Start local services**
```bash
docker-compose up -d
```

5. **Access services**
- MLflow UI: http://localhost:5000
- Airflow UI: http://localhost:8080 (admin/admin)
- Grafana: http://localhost:3000 (admin/admin)
- Jupyter: http://localhost:8888 (token: mlops)

## Project Structure

```
mlops-pipeline-starter/
├── pipelines/              # Training & deployment orchestration
├── serving/                # Model serving infrastructure
├── observability/          # Monitoring & alerting
├── mlops/                  # ML-specific utilities
├── security/               # Security & compliance
├── data_quality/           # Data validation with Great Expectations
├── feature_store/          # Feature definitions and management
├── model_governance/       # Model cards and governance
├── infrastructure/         # IaC templates (Terraform/Helm)
├── tests/                  # Unit, integration, and E2E tests
├── config/                 # Configuration files
└── docs/                   # Documentation
```

## Workflow

### 1. Data Pipeline
```bash
# Validate incoming data
make validate-data DATASET=path/to/data.csv

# Run feature engineering
python -m pipelines.feature_engineering.main --config config/features.yaml

# Apply feature definitions
make feature-apply
```

### 2. Training Pipeline
```bash
# Run training pipeline
make train

# Or trigger via Airflow
airflow dags trigger training_pipeline
```

### 3. Model Evaluation & Promotion
```bash
# Evaluate model
make evaluate

# Promote to production (requires approval)
make promote ENV=prod
```

### 4. Deployment
```bash
# Deploy to staging (automatic on main branch)
make deploy-all ENV=staging

# Deploy to production (manual trigger)
make deploy-all ENV=prod
```

### 5. Monitoring
```bash
# Start monitoring stack
make monitor

# Check drift detection
python -m observability.monitoring.drift_detector --model-version v1.0.0
```

## CI/CD Pipeline

### Continuous Integration
- **Linting**: Black, Ruff, MyPy
- **Testing**: Unit, Integration, E2E tests
- **Security**: Bandit, Safety, Trivy scans
- **Data Validation**: Great Expectations checks
- **Docker Build**: Multi-stage builds with caching

### Continuous Deployment
- **Model Validation**: Performance thresholds
- **Infrastructure**: Terraform apply
- **Deployment**: Helm charts with Argo Rollouts
- **Smoke Tests**: API endpoint validation
- **Canary Promotion**: Gradual traffic shifting
- **Automatic Rollback**: On SLO breach

## Configuration

### Model Training
Edit `config/pipelines/train.yaml`:
```yaml
training:
  max_epochs: 100
  batch_size: 64
  learning_rate: 0.001
  early_stopping_patience: 10
```

### Feature Store
Configure features in `feature_store/definitions/`:
```python
customer_stats_fv = FeatureView(
    name="customer_stats",
    entities=["customer_id"],
    ttl=timedelta(days=7),
    features=[...],
    online=True,
    source=customer_stats_source,
)
```

### Monitoring Alerts
Configure in `observability/alerting/alerts.yaml`:
```yaml
alerts:
  - name: ModelDriftDetected
    condition: drift_score > 0.3
    action: create_jira_ticket
```

## Testing

### Run All Tests
```bash
make test
```

### Specific Test Suites
```bash
# Unit tests
make test-unit

# Integration tests
make test-integration

# End-to-end tests
make test-e2e

# Load tests
make test-load
```

## Security

### Secrets Management
- HashiCorp Vault integration
- Kubernetes sealed secrets
- Environment-specific encryption

### Compliance
- GDPR/CCPA data privacy
- Model governance with audit trails
- Artifact signing with Cosign
- SLSA provenance generation

## Performance

### SLA Targets
- Model inference: p95 < 250ms
- Data freshness: < 1 hour
- Feature serving: p99 < 50ms
- Training pipeline: < 4 hours

### Optimization
- Model quantization
- Feature caching
- Batch prediction
- GPU acceleration

## Troubleshooting

### Common Issues

1. **Docker services not starting**
```bash
docker-compose logs <service-name>
docker-compose restart <service-name>
```

2. **Training pipeline failures**
```bash
# Check Airflow logs
airflow dags show training_pipeline
airflow tasks test training_pipeline task_id execution_date
```

3. **Model serving errors**
```bash
# Check pod logs
kubectl logs -n mlops deployment/mlops-model
kubectl describe pod -n mlops <pod-name>
```

4. **Data validation failures**
```bash
# View validation report
python -m data_quality.generate_report --output reports/validation.html
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.

## Support

- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/yourorg/mlops-pipeline/issues)
- Slack: #mlops-pipeline

## Roadmap

- [ ] Multi-model serving
- [ ] A/B testing framework
- [ ] Federated learning support
- [ ] AutoML integration
- [ ] Model explainability dashboard
- [ ] Cost optimization automation
- [ ] Edge deployment support
- [ ] Real-time feature computation

## Acknowledgments

Built with best practices from:
- [MLOps Community](https://mlops.community/)
- [Google MLOps Maturity Model](https://cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning)
- [Microsoft Team Data Science Process](https://docs.microsoft.com/en-us/azure/machine-learning/team-data-science-process/)
- [AWS Well-Architected ML Lens](https://docs.aws.amazon.com/wellarchitected/latest/machine-learning-lens/)