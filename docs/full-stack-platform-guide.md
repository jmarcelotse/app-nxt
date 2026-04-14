# Plataforma IDP — Stack Completa com Backstage + Terraform Modules

## Visão Geral

Este documento descreve a arquitetura e o plano de implementação de uma plataforma IDP (Internal Developer Platform) usando Backstage como portal de self-service e módulos Terraform reutilizáveis para provisionamento de infraestrutura AWS.

O objetivo é permitir que desenvolvedores criem aplicações completas — do email da conta AWS até o serviço rodando em produção — através de um formulário no Backstage, sem depender de tickets para o time de plataforma.

---

## Arquitetura Geral

```
┌─────────────────────────────────────────────────────────┐
│                    Backstage (IDP)                       │
│                                                         │
│  ┌──────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │   Software   │  │   Scaffolder   │  │   Search    │ │
│  │   Catalog    │  │   Templates    │  │   Engine    │ │
│  └──────────────┘  └───────┬────────┘  └─────────────┘ │
└────────────────────────────┼────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ GitHub Actions │
                    │    (CI/CD)     │
                    └───────┬────────┘
                            │
                  ┌─────────┼─────────┐
                  ▼         ▼         ▼
            ┌──────────┐ ┌─────┐ ┌──────────┐
            │ Terraform│ │OIDC │ │   ECR    │
            │  Modules │ │(AWS)│ │ (Images) │
            └────┬─────┘ └─────┘ └──────────┘
                 │
    ┌────────────┼────────────────────────┐
    ▼            ▼            ▼           ▼
┌───────┐  ┌─────────┐  ┌────────┐  ┌─────────┐
│  VPC  │  │   ECS   │  │  RDS   │  │Cloudflare│
│Subnets│  │ Fargate │  │ Cache  │  │   DNS   │
│  NAT  │  │   ALB   │  │  S3    │  │  Proxy  │
│  SG   │  │   ECR   │  │  ELK   │  │         │
└───────┘  └─────────┘  └────────┘  └─────────┘
```

---

## Repositórios

### 1. `terraform-modules` — Módulos reutilizáveis

Repositório central com todos os módulos Terraform. Versionado com tags (v1.0.0, v1.1.0, etc.).

```
terraform-modules/
├── modules/
│   ├── networking/          ← VPC, Subnets, NAT, Internet Gateway
│   ├── security-groups/     ← Security Groups por camada
│   ├── iam/                 ← Roles, Policies, Instance Profiles
│   ├── secrets-manager/     ← Secrets Manager
│   ├── acm/                 ← Certificate Manager
│   ├── alb/                 ← ALB + Listeners + Target Groups + WAF
│   ├── ecs-cluster/         ← ECS Cluster Fargate
│   ├── ecs-service/         ← ECS Service + Task Definition + Auto Scaling
│   ├── ecr/                 ← ECR Repository
│   ├── rds/                 ← RDS (PostgreSQL/MySQL) + Subnet Group
│   ├── cache/               ← ElastiCache (Redis/Memcached)
│   ├── s3/                  ← S3 Bucket
│   ├── elk/                 ← OpenSearch (ELK)
│   └── cloudflare-dns/      ← Cloudflare DNS + Proxy
└── README.md
```

### 2. `app-nxt` — Backstage (IDP)

O portal do desenvolvedor com templates que consomem os módulos.

### 3. Repos gerados pelo Backstage

Cada aplicação criada pelo template gera um repo com a infraestrutura e CI/CD.

---

## Módulos Terraform — Detalhamento

### networking

| Recurso | Descrição |
|---|---|
| VPC | VPC dedicada por aplicação ou compartilhada por env |
| Subnets | Public (ALB) + Private (ECS, RDS) em 2-3 AZs |
| NAT Gateway | Para acesso à internet das subnets privadas |
| Internet Gateway | Para subnets públicas |
| Route Tables | Rotas public e private |

### security-groups

| SG | Regras |
|---|---|
| ALB | Inbound 80/443 de 0.0.0.0/0 |
| ECS | Inbound da porta do app vindo do ALB SG |
| RDS | Inbound 5432/3306 vindo do ECS SG |
| Cache | Inbound 6379 vindo do ECS SG |
| ELK | Inbound 443/9200 vindo do ECS SG |

### iam

| Recurso | Descrição |
|---|---|
| ECS Task Execution Role | Pull de imagens ECR + logs CloudWatch |
| ECS Task Role | Acesso a S3, Secrets Manager, etc. |
| GitHub Actions Role | OIDC para deploy via CI/CD |

### secrets-manager

| Recurso | Descrição |
|---|---|
| DB Password | Senha do RDS gerada automaticamente |
| App Secrets | Secrets da aplicação (API keys, tokens) |
| Rotation | Rotação automática opcional |

### acm

| Recurso | Descrição |
|---|---|
| Certificado | SSL/TLS para o domínio da aplicação |
| Validação | DNS via Cloudflare (automática) |

### alb

| Recurso | Descrição |
|---|---|
| ALB | Application Load Balancer nas subnets públicas |
| Listener HTTP | Redirect 80 → 443 |
| Listener HTTPS | Forward para target group com certificado ACM |
| Target Group | Health check configurável |
| WAF | Regras básicas de proteção (opcional) |

### ecs-cluster

| Recurso | Descrição |
|---|---|
| Cluster | ECS Cluster com Fargate + Fargate Spot |
| Capacity Providers | Configurável % Spot vs On-Demand |
| CloudWatch | Container Insights habilitado |

### ecs-service

| Recurso | Descrição |
|---|---|
| Task Definition | Container com imagem do ECR, CPU, memória, env vars |
| Service | Desired count, deployment circuit breaker |
| Auto Scaling | Target tracking por CPU/memória |
| Log Group | CloudWatch Logs com retenção configurável |

### ecr

| Recurso | Descrição |
|---|---|
| Repository | Registry para imagens Docker |
| Lifecycle | Limpeza automática de imagens antigas |
| Scan | Scan de vulnerabilidades habilitado |

### rds

| Recurso | Descrição |
|---|---|
| Instance | PostgreSQL 16 ou MySQL 8.0 |
| Subnet Group | Subnets privadas |
| Storage | gp3, tamanho configurável |
| Backup | Retenção configurável (7 dias default) |
| Multi-AZ | Opcional |
| Encryption | Habilitado por padrão |

### cache

| Recurso | Descrição |
|---|---|
| ElastiCache | Redis ou Memcached |
| Subnet Group | Subnets privadas |
| Parameter Group | Configurações otimizadas |

### s3

| Recurso | Descrição |
|---|---|
| Bucket | Nomeado por app + env |
| Versionamento | Habilitado |
| Encryption | SSE-S3 |
| Public Access | Bloqueado |

### elk

| Recurso | Descrição |
|---|---|
| OpenSearch | Cluster para logs e busca |
| Domain | Configurável por tamanho |
| Access Policy | Restrito ao ECS SG |

### cloudflare-dns

| Recurso | Descrição |
|---|---|
| CNAME | Aponta subdomínio para o ALB |
| Proxy | Cloudflare proxy habilitado (CDN + DDoS) |
| SSL | Full (strict) |

---

## Recursos Opcionais no Template

O template do Backstage usa campos boolean para recursos opcionais. O Terraform usa `count` para criar ou não:

```hcl
# No template.yaml do Backstage
properties:
  enableRds:
    title: Banco de dados (RDS)
    type: boolean
    default: true
  enableCache:
    title: Cache (Redis)
    type: boolean
    default: false
  enableElk:
    title: ELK (OpenSearch)
    type: boolean
    default: false
  enableS3:
    title: S3 Bucket
    type: boolean
    default: false
```

```hcl
# No Terraform gerado
module "rds" {
  count  = var.enable_rds ? 1 : 0
  source = "git::https://github.com/sua-org/terraform-modules.git//modules/rds?ref=v1.0.0"
  ...
}

module "cache" {
  count  = var.enable_cache ? 1 : 0
  source = "git::https://github.com/sua-org/terraform-modules.git//modules/cache?ref=v1.0.0"
  ...
}

module "elk" {
  count  = var.enable_elk ? 1 : 0
  source = "git::https://github.com/sua-org/terraform-modules.git//modules/elk?ref=v1.0.0"
  ...
}

module "s3" {
  count  = var.enable_s3 ? 1 : 0
  source = "git::https://github.com/sua-org/terraform-modules.git//modules/s3?ref=v1.0.0"
  ...
}
```

---

## Separação por Ambiente

### Estratégia: Diretórios por ambiente

Cada repo gerado pelo Backstage tem diretórios separados por env, com tfvars diferentes e state isolado:

```
repo-da-aplicacao/
├── envs/
│   ├── staging/
│   │   ├── main.tf              ← Chama os módulos
│   │   ├── variables.tf
│   │   ├── terraform.tfvars     ← Valores de staging
│   │   └── backend.tf           ← State: s3://state-bucket/app/staging/
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars     ← Valores de produção
│       └── backend.tf           ← State: s3://state-bucket/app/production/
├── .github/workflows/
│   ├── staging.yaml             ← Auto deploy no push
│   ├── production.yaml          ← Deploy com approval manual
│   └── destroy.yaml             ← Destroy manual por env
├── Dockerfile
├── catalog-info.yaml
└── README.md
```

### Diferenças entre ambientes

| Configuração | Staging | Production |
|---|---|---|
| Instance type (ECS) | 256 CPU / 512 MB | 512+ CPU / 1024+ MB |
| Desired count | 1-2 | 2-4 |
| Spot | 100% Spot | 70% Spot / 30% On-Demand |
| RDS | db.t3.micro, Single-AZ | db.t3.medium+, Multi-AZ |
| Cache | Não ou t3.micro | t3.small+ |
| Auto Scaling | Desabilitado ou conservador | Agressivo |
| WAF | Desabilitado | Habilitado |
| Backup RDS | 1 dia | 7-30 dias |
| Logs retention | 7 dias | 30-90 dias |

### Accounts AWS por ambiente

| Ambiente | Account | OIDC Role |
|---|---|---|
| Staging | Account staging | `arn:aws:iam::<staging-id>:role/backstage-github-actions` |
| Production | Account production | `arn:aws:iam::<prod-id>:role/backstage-github-actions` |

Cada account precisa do OIDC Provider do GitHub configurado e uma role com as permissões necessárias.

---

## CI/CD — GitHub Actions

### staging.yaml (deploy automático)

```yaml
name: Deploy Staging
on:
  push:
    branches: [main]
    paths:
      - 'envs/staging/**'
      - 'Dockerfile'
      - 'src/**'

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS (staging)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<staging-id>:role/backstage-github-actions
          aws-region: us-east-1

      - name: Build & Push Docker image
        run: |
          aws ecr get-login-password | docker login --username AWS --password-stdin <staging-id>.dkr.ecr.us-east-1.amazonaws.com
          docker build -t <app-name> .
          docker tag <app-name>:latest <staging-id>.dkr.ecr.us-east-1.amazonaws.com/<app-name>:${{ github.sha }}
          docker push <staging-id>.dkr.ecr.us-east-1.amazonaws.com/<app-name>:${{ github.sha }}

      - name: Terraform Apply
        working-directory: envs/staging
        run: |
          terraform init
          terraform apply -auto-approve -var="image_tag=${{ github.sha }}"
```

### production.yaml (deploy com approval)

```yaml
name: Deploy Production
on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Requer approval no GitHub
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS (production)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<prod-id>:role/backstage-github-actions
          aws-region: us-east-1

      - name: Terraform Apply
        working-directory: envs/production
        run: |
          terraform init
          terraform apply -auto-approve
```

### destroy.yaml (cleanup)

```yaml
name: Destroy Environment
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Ambiente (staging ou production)'
        required: true
        type: choice
        options:
          - staging
          - production
      confirm:
        description: 'Digite "destroy" para confirmar'
        required: true

jobs:
  destroy:
    runs-on: ubuntu-latest
    if: github.event.inputs.confirm == 'destroy'
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<account-id>:role/backstage-github-actions
          aws-region: us-east-1

      - name: Terraform Destroy
        working-directory: envs/${{ github.event.inputs.environment }}
        run: |
          terraform init
          terraform destroy -auto-approve
```

---

## Template do Backstage — Formulário

O template terá os seguintes passos no formulário:

### Passo 1: Informações do Projeto

| Campo | Tipo | Obrigatório |
|---|---|---|
| Nome da aplicação | text | Sim |
| Descrição | text | Sim |
| Owner (time) | OwnerPicker | Sim |
| Ambiente | select (staging/production) | Sim |
| Região AWS | select | Sim |

### Passo 2: Aplicação

| Campo | Tipo | Obrigatório |
|---|---|---|
| Versão Ruby | select (3.2, 3.3, 3.4) | Sim |
| Versão Rails | select (7.1, 7.2, 8.0) | Sim |
| Porta do container | number (default: 3000) | Sim |

### Passo 3: Compute (ECS)

| Campo | Tipo | Obrigatório |
|---|---|---|
| CPU | select (256, 512, 1024, 2048) | Sim |
| Memória | select (512, 1024, 2048, 4096) | Sim |
| Desired count | number (default: 2) | Sim |
| % Spot | number (default: 70) | Sim |
| Auto Scaling min | number | Sim |
| Auto Scaling max | number | Sim |

### Passo 4: Dados (opcionais)

| Campo | Tipo | Default |
|---|---|---|
| Habilitar RDS | boolean | true |
| Engine RDS | select (postgres/mysql) | postgres |
| Classe RDS | select | db.t3.micro |
| Multi-AZ | boolean | false |
| Habilitar Cache | boolean | false |
| Engine Cache | select (redis/memcached) | redis |
| Habilitar S3 | boolean | false |
| Habilitar ELK | boolean | false |

### Passo 5: DNS

| Campo | Tipo | Obrigatório |
|---|---|---|
| Domínio | text | Sim |
| Subdomínio | text | Sim |
| Cloudflare Zone ID | text | Sim |

### Passo 6: Repositório

| Campo | Tipo | Obrigatório |
|---|---|---|
| Repo URL | RepoUrlPicker | Sim |

---

## Uso de Módulos de Repos Gerenciados

Os templates do Backstage referenciam módulos Terraform de um repositório central versionado:

```hcl
module "networking" {
  source = "git::https://github.com/sua-org/terraform-modules.git//modules/networking?ref=v1.0.0"

  name        = var.name
  environment = var.environment
  region      = var.region
}

module "ecs_cluster" {
  source = "git::https://github.com/sua-org/terraform-modules.git//modules/ecs-cluster?ref=v1.0.0"

  name             = var.name
  spot_percentage  = var.spot_percentage
}

module "ecs_service" {
  source = "git::https://github.com/sua-org/terraform-modules.git//modules/ecs-service?ref=v1.0.0"

  cluster_id      = module.ecs_cluster.cluster_id
  name            = var.name
  image           = "${module.ecr.repository_url}:${var.image_tag}"
  cpu             = var.cpu
  memory          = var.memory
  desired_count   = var.desired_count
  container_port  = var.container_port
  target_group_arn = module.alb.target_group_arn
  subnets         = module.networking.private_subnet_ids
  security_groups = [module.security_groups.ecs_sg_id]
  scaling_min     = var.scaling_min
  scaling_max     = var.scaling_max
}
```

### Vantagens dos módulos centralizados

- **Padronização** — Todos os times usam a mesma base
- **Governança** — Mudanças nos módulos passam por code review
- **Versionamento** — Cada app pode usar uma versão diferente do módulo
- **Atualização** — Bump de versão no módulo atualiza todas as apps
- **Segurança** — Boas práticas embutidas (encryption, SG restritivos, etc.)

---

## Fluxo Completo

```
1. Dev abre Backstage → Create → "Nova Aplicação Ruby/Rails"
2. Preenche formulário (nome, env, recursos, DNS)
3. Backstage cria repo no GitHub com:
   ├── Dockerfile (Ruby + Rails)
   ├── envs/staging/main.tf (chama módulos)
   ├── envs/production/main.tf
   ├── .github/workflows/ (CI/CD)
   └── catalog-info.yaml
4. Push no main dispara GitHub Actions
5. GitHub Actions assume role via OIDC
6. Terraform aplica os módulos:
   ├── VPC + Subnets + NAT
   ├── ALB + ACM
   ├── ECS Cluster + Service (Fargate Spot)
   ├── ECR + Build da imagem
   ├── RDS (se habilitado)
   ├── Cache (se habilitado)
   ├── S3 (se habilitado)
   ├── ELK (se habilitado)
   ├── Secrets Manager
   └── Cloudflare DNS
7. Aplicação rodando e acessível via subdomínio
8. Componente registrado no catálogo do Backstage
```

---

## Plano de Implementação

### Fase 1 — Fundação (1-2 semanas)

- [ ] Criar repo `terraform-modules`
- [ ] Implementar módulo `networking` (VPC, subnets, NAT)
- [ ] Implementar módulo `security-groups`
- [ ] Implementar módulo `iam`
- [ ] Implementar módulo `ecr`
- [ ] Configurar OIDC nas accounts AWS (staging + prod)
- [ ] Testar módulos isoladamente

### Fase 2 — Compute (1-2 semanas)

- [ ] Implementar módulo `ecs-cluster`
- [ ] Implementar módulo `ecs-service` (com auto scaling)
- [ ] Implementar módulo `alb`
- [ ] Implementar módulo `acm`
- [ ] Criar Dockerfile base Ruby/Rails
- [ ] Testar deploy de app Rails no ECS

### Fase 3 — Dados e Segurança (1 semana)

- [ ] Implementar módulo `rds`
- [ ] Implementar módulo `cache`
- [ ] Implementar módulo `s3`
- [ ] Implementar módulo `secrets-manager`
- [ ] Implementar módulo `elk` (opcional)
- [ ] Testar conectividade ECS → RDS/Cache

### Fase 4 — DNS e Template (1 semana)

- [ ] Implementar módulo `cloudflare-dns`
- [ ] Criar template completo no Backstage
- [ ] Configurar CI/CD (staging auto, prod manual)
- [ ] Configurar workflow de destroy
- [ ] Testar fluxo end-to-end

### Fase 5 — Refinamento (contínuo)

- [ ] Adicionar mais services ao ECS (múltiplos services por app)
- [ ] Configurar monitoramento (CloudWatch/Prometheus)
- [ ] Configurar alertas
- [ ] Documentar runbooks
- [ ] Onboarding dos times

---

## Estimativa de Custo por Aplicação

### Staging (mínimo)

| Recurso | Estimativa/mês |
|---|---|
| ECS Fargate Spot (2 tasks, 256 CPU, 512 MB) | ~$15 |
| ALB | ~$20 |
| RDS db.t3.micro | ~$15 |
| NAT Gateway | ~$35 |
| ECR | ~$1 |
| Cloudflare | Gratuito (plano free) |
| **Total** | **~$86/mês** |

### Production (típico)

| Recurso | Estimativa/mês |
|---|---|
| ECS Fargate mixed (4 tasks, 512 CPU, 1024 MB) | ~$80 |
| ALB | ~$25 |
| RDS db.t3.medium Multi-AZ | ~$70 |
| ElastiCache t3.small | ~$25 |
| NAT Gateway | ~$35 |
| S3 | ~$5 |
| ECR | ~$2 |
| Secrets Manager | ~$2 |
| Cloudflare | Gratuito |
| **Total** | **~$244/mês** |

> Para valores exatos e atualizados, use a [AWS Pricing Calculator](https://calculator.aws/).

---

## FinOps — Boas Práticas

- **Destroy staging no fim do dia** — Workflow de destroy agendado ou manual
- **Spot Instances** — 70-100% Spot em staging, 50-70% em produção
- **Right-sizing** — Começar pequeno, escalar conforme necessidade
- **Lifecycle policies** — Limpeza automática de imagens ECR antigas
- **Logs retention** — 7 dias staging, 30 dias produção
- **Reserved Instances** — Para RDS em produção (economia de 30-60%)
- **NAT Gateway compartilhado** — Uma VPC por env, não por app
