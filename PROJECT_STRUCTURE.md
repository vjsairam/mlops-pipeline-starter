# MLOps Pipeline Starter - Project Structure

## Directory Layout

```
mlops-pipeline-starter/
│
├── pipelines/                    # Training & deployment orchestration
│   ├── train/                   # Training pipeline DAGs
│   ├── eval/                    # Evaluation pipeline DAGs
│   ├── promote/                 # Model promotion DAGs
│   └── feature_engineering/     # Feature pipeline DAGs
│
├── serving/                      # Model serving infrastructure
│   ├── containers/              # Dockerfiles for model serving
│   ├── manifests/               # K8s deployment manifests
│   └── rollouts/                # Argo Rollouts configurations
│
├── observability/               # Monitoring & alerting
│   ├── monitoring/              # Prometheus rules, collectors
│   ├── alerting/                # Alert configurations
│   └── dashboards/              # Grafana dashboards
│
├── mlops/                       # ML-specific utilities
│   ├── registry/                # Model registry integration
│   ├── utils/                   # Training/eval utilities
│   └── experiments/             # Experiment tracking configs
│
├── security/                    # Security & compliance
│   ├── signing/                 # Cosign artifact signing
│   ├── policies/                # Promotion & security policies
│   └── audit/                   # Audit trail configurations
│
├── data/                        # Data storage (gitignored)
│   ├── raw/                     # Raw datasets
│   ├── processed/               # Processed datasets
│   └── features/                # Feature store exports
│
├── models/                      # Model storage (gitignored)
│   ├── artifacts/               # Trained model artifacts
│   ├── checkpoints/             # Training checkpoints
│   └── exports/                 # Exported models for serving
│
├── config/                      # Configuration files
│   ├── environments/            # Environment-specific configs
│   ├── pipelines/               # Pipeline configurations
│   └── serving/                 # Serving configurations
│
├── tests/                       # Test suites
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   └── e2e/                     # End-to-end tests
│
├── docs/                        # Documentation
│   ├── playbooks/               # Operational playbooks
│   ├── architecture/            # Architecture diagrams
│   └── guides/                  # User guides
│
└── .github/                     # GitHub Actions
    └── workflows/               # CI/CD workflows
```

## Component Overview

### 1. Pipelines (`/pipelines`)
- **Train**: Airflow/Kubeflow DAGs for model training
- **Eval**: Evaluation pipelines with acceptance gates
- **Promote**: Model promotion workflows with policy checks
- **Feature Engineering**: Data validation & feature creation

### 2. Serving (`/serving`)
- **Containers**: Docker images for vLLM/TorchServe/BentoML
- **Manifests**: Kubernetes deployments & services
- **Rollouts**: Canary & blue-green deployment configs

### 3. Observability (`/observability`)
- **Monitoring**: Prometheus metrics, OTel collectors
- **Alerting**: Alert rules for drift, SLO breaches
- **Dashboards**: Grafana dashboards for model metrics

### 4. MLOps (`/mlops`)
- **Registry**: MLflow/Vertex AI registry integration
- **Utils**: Training helpers, data loaders, metrics
- **Experiments**: Experiment tracking configurations

### 5. Security (`/security`)
- **Signing**: Cosign configurations for artifact signing
- **Policies**: OPA/Gatekeeper policies for promotion
- **Audit**: SLSA provenance & audit trail setup

### 6. Data & Models
- Gitignored directories for datasets and model artifacts
- Integration with DVC/Delta Lake for versioning

### 7. Configuration (`/config`)
- Environment-specific settings (dev/staging/prod)
- Pipeline parameters & hyperparameters
- Serving configurations (resources, scaling)

### 8. Testing (`/tests`)
- Unit tests for utilities & components
- Integration tests for pipelines
- E2E tests for full CT/CD flow

### 9. Documentation (`/docs`)
- Operational playbooks (promote, rollback, debug)
- Architecture diagrams & decision records
- User guides for engineers & data scientists

## Key Files to Create

### Root Level
- `Makefile` - Common commands for setup & deployment
- `requirements.txt` / `pyproject.toml` - Python dependencies
- `.env.example` - Environment variable template
- `docker-compose.yml` - Local development environment

### Pipeline Files
- `pipelines/train/train_dag.py` - Training orchestration
- `pipelines/eval/eval_dag.py` - Evaluation pipeline
- `pipelines/promote/promote_dag.py` - Promotion workflow

### Serving Files
- `serving/containers/Dockerfile` - Model serving image
- `serving/manifests/deployment.yaml` - K8s deployment
- `serving/rollouts/canary.yaml` - Canary rollout config

### MLOps Files
- `mlops/registry/client.py` - Registry client wrapper
- `mlops/utils/metrics.py` - Custom metrics & evaluators
- `mlops/experiments/config.yaml` - MLflow configuration

### Observability Files
- `observability/monitoring/metrics.yaml` - Prometheus rules
- `observability/dashboards/model_performance.json` - Grafana dashboard
- `observability/alerting/drift_alerts.yaml` - Drift detection alerts

## Getting Started

1. **Initialize the project**:
   ```bash
   make init
   ```

2. **Set up environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configurations
   ```

3. **Run local development**:
   ```bash
   docker-compose up -d
   ```

4. **Deploy pipelines**:
   ```bash
   make deploy-pipelines ENV=dev
   ```

5. **Deploy serving**:
   ```bash
   make deploy-serving ENV=staging
   ```

## Development Workflow

1. **Feature Development**: Create feature branches from `main`
2. **Pipeline Testing**: Run pipelines locally with test data
3. **Model Training**: Execute training DAG via Airflow UI
4. **Evaluation**: Automatic evaluation triggers post-training
5. **Promotion**: Manual/automatic promotion based on gates
6. **Deployment**: GitOps triggers canary rollout
7. **Monitoring**: Observe metrics in Grafana dashboards
8. **Rollback**: Automatic or manual based on SLO breach

## Compliance & Security

- All models signed with Cosign before promotion
- SLSA provenance generated for supply chain integrity
- Model cards required with metrics & constraints
- Audit trail maintained for all promotions
- Policy gates enforce quality & fairness thresholds