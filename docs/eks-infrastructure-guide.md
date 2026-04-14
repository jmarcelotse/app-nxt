# Guia de Infraestrutura — Backstage no EKS

## Visão Geral

Este documento descreve as configurações recomendadas para rodar o Backstage em um cluster EKS na AWS, cobrindo cenários de teste/staging e produção.

---

## Banco de Dados — PostgreSQL

O Backstage precisa de um banco PostgreSQL. Existem 3 opções:

| Opção | Quando usar | Custo estimado |
|---|---|---|
| PostgreSQL no K8s (StatefulSet) | Teste/staging — simples, sem custo extra | ~$0 (roda no node) |
| RDS PostgreSQL | Produção — backup, Multi-AZ, patching automático | ~$15-70/mês |
| Aurora Serverless v2 | Produção com uso variável — escala automaticamente | ~$50+/mês |

### PostgreSQL no K8s (teste/staging)

- Já incluso no Helm chart do Backstage
- Sem backup automático
- Dados perdidos se o PVC for deletado
- Suficiente para testes e demonstrações

### RDS (produção)

- Backup automático com retenção configurável
- Failover Multi-AZ para alta disponibilidade
- Patching sem downtime
- Dados seguros independente do cluster K8s
- Recomendado: `db.t3.micro` (staging) ou `db.t3.medium` (produção)

---

## Configuração de EKS — Teste/Staging

| Recurso | Configuração |
|---|---|
| EKS | 1 cluster, versão 1.30+ |
| Node Group | 2x `t3.medium` (2 vCPU, 4GB) |
| Backstage | 1 réplica, 512Mi~1Gi RAM, 250m~500m CPU |
| PostgreSQL | StatefulSet no cluster (Helm chart) |
| Ingress | Nginx Ingress Controller ou AWS ALB Controller |
| DNS | Route53 ou Cloudflare |
| TLS | cert-manager + Let's Encrypt |
| Auth | Guest provider (dangerouslyAllowOutsideDevelopment) |

### Custo estimado mensal (staging)

| Recurso | Estimativa |
|---|---|
| EKS control plane | ~$73 |
| 2x t3.medium (spot) | ~$30 |
| ALB | ~$20 |
| **Total** | **~$123/mês** |

### Alternativa com Fargate (staging)

| Recurso | Estimativa |
|---|---|
| EKS control plane | ~$73 |
| Fargate (Backstage + PostgreSQL) | ~$25 |
| **Total** | **~$98/mês** |

> Fargate elimina a necessidade de gerenciar nodes EC2. Paga apenas pelo consumo dos pods.

---

## Configuração de EKS — Produção

| Recurso | Configuração |
|---|---|
| EKS | 1 cluster, versão 1.30+, private endpoint |
| Node Group | 3x `t3.large` (2 vCPU, 8GB) — mixed on-demand + spot |
| Backstage | 2 réplicas, 1Gi~2Gi RAM, 500m~1000m CPU |
| PostgreSQL | RDS `db.t3.medium` Multi-AZ, 50GB gp3, backup 7 dias |
| Cache | ElastiCache Redis (opcional, para search) |
| Ingress | AWS ALB Controller + WAF |
| DNS | Route53 ou Cloudflare |
| TLS | ACM (se ALB) ou cert-manager |
| Auth | OIDC (Google, Okta, Azure AD) |
| Secrets | External Secrets Operator + AWS Secrets Manager |
| Monitoring | Prometheus + Grafana ou CloudWatch |
| Logs | Fluent Bit → CloudWatch |

### Custo estimado mensal (produção)

| Recurso | Estimativa |
|---|---|
| EKS control plane | ~$73 |
| 3x t3.large (mixed on-demand + spot) | ~$120 |
| RDS db.t3.medium Multi-AZ | ~$70 |
| ALB + WAF | ~$40 |
| Secrets Manager + extras | ~$10 |
| **Total** | **~$310/mês** |

> Para valores exatos e atualizados, use a [AWS Pricing Calculator](https://calculator.aws/).

---

## Componentes de Infraestrutura

### Ingress

| Opção | Prós | Contras |
|---|---|---|
| Nginx Ingress Controller | Simples, amplamente usado, gratuito | Precisa de NLB/CLB na frente |
| AWS ALB Controller | Nativo AWS, integração com WAF e ACM | Mais complexo de configurar |

### TLS/Certificados

| Opção | Quando usar |
|---|---|
| ACM (AWS Certificate Manager) | Com ALB Controller — certificado gratuito gerenciado pela AWS |
| cert-manager + Let's Encrypt | Com Nginx Ingress — certificado gratuito auto-renovável |

### Autenticação

| Ambiente | Provider |
|---|---|
| Teste | Guest (com `dangerouslyAllowOutsideDevelopment: true`) |
| Produção | GitHub, Google, Okta, Azure AD, OIDC genérico |

### Secrets

| Ambiente | Abordagem |
|---|---|
| Teste | Kubernetes Secrets (plain) |
| Produção | External Secrets Operator + AWS Secrets Manager ou HashiCorp Vault |

### Monitoramento

| Componente | Ferramenta |
|---|---|
| Métricas | Prometheus + Grafana ou CloudWatch Container Insights |
| Logs | Fluent Bit → CloudWatch Logs ou Loki |
| Alertas | Grafana Alerting ou CloudWatch Alarms |

---

## Arquitetura — Staging

```
Internet
    │
    ▼
┌────────┐
│  ALB   │
└───┬────┘
    │
┌───▼──────────────────────────┐
│         EKS Cluster          │
│                              │
│  ┌───────────┐ ┌──────────┐ │
│  │ Backstage │ │PostgreSQL│ │
│  │  (1 pod)  │ │(1 pod)   │ │
│  └───────────┘ └──────────┘ │
│                              │
│  Node Group: 2x t3.medium   │
└──────────────────────────────┘
```

## Arquitetura — Produção

```
Internet
    │
    ▼
┌─────────────┐
│ Cloudflare  │
│  / Route53  │
└──────┬──────┘
       │
┌──────▼──────┐
│  ALB + WAF  │
└──────┬──────┘
       │
┌──────▼──────────────────────────────┐
│            EKS Cluster              │
│          (private endpoint)         │
│                                     │
│  ┌───────────┐  ┌───────────┐      │
│  │ Backstage │  │ Backstage │      │
│  │ (pod 1)   │  │ (pod 2)   │      │
│  └───────────┘  └───────────┘      │
│                                     │
│  ┌──────────────┐ ┌─────────────┐  │
│  │ Ext. Secrets │ │ Fluent Bit  │  │
│  └──────────────┘ └─────────────┘  │
│                                     │
│  Node Group: 3x t3.large (mixed)   │
└──────────────┬──────────────────────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌───────┐ ┌────────┐ ┌──────────┐
│  RDS  │ │Secrets │ │CloudWatch│
│Multi-AZ│ │Manager│ │  Logs    │
└───────┘ └────────┘ └──────────┘
```

---

## Checklist de Deploy

### Staging

- [ ] Criar cluster EKS
- [ ] Configurar node group (t3.medium spot)
- [ ] Instalar Ingress Controller
- [ ] Configurar DNS
- [ ] Deploy Backstage via Helm
- [ ] Configurar GitHub Token
- [ ] Testar templates

### Produção

- [ ] Criar cluster EKS (private endpoint)
- [ ] Configurar node group (mixed on-demand + spot)
- [ ] Criar RDS PostgreSQL Multi-AZ
- [ ] Instalar ALB Controller + WAF
- [ ] Configurar cert-manager ou ACM
- [ ] Configurar DNS (Route53/Cloudflare)
- [ ] Instalar External Secrets Operator
- [ ] Configurar auth provider (OIDC)
- [ ] Configurar permission framework
- [ ] Deploy Backstage via Helm (2 réplicas)
- [ ] Configurar monitoramento (Prometheus/CloudWatch)
- [ ] Configurar logs (Fluent Bit)
- [ ] Configurar backups do RDS
- [ ] Testar failover e resiliência
