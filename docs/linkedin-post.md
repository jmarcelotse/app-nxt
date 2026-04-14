# Construindo um Internal Developer Platform (IDP) com Backstage — do zero à produção

## Post LinkedIn

🚀 **Construindo um Internal Developer Platform (IDP) com Backstage — do zero à produção**

Nos últimos dias, montei um projeto completo de Internal Developer Platform usando Backstage (CNCF) rodando no Kubernetes, com CI/CD automatizado e provisionamento de infraestrutura AWS via self-service.

**Por que um IDP é importante?**

Em empresas com dezenas (ou centenas) de microserviços, o caos se instala rápido: times não sabem quem é dono de qual serviço, a documentação está espalhada, criar um novo projeto leva dias e provisionar infraestrutura depende de tickets para o time de plataforma.

Um IDP resolve isso centralizando tudo em um único portal:

📋 **Software Catalog** — Visão unificada de todos os serviços, APIs, bancos de dados, times e suas dependências. Quem é dono? Qual o status? Do que depende?

⚡ **Self-Service Templates** — Desenvolvedores criam novos serviços e provisionam infraestrutura em minutos, sem tickets, sem espera. Tudo padronizado e com boas práticas embutidas.

🔄 **Automação end-to-end** — Do clique no portal até o recurso rodando na AWS, tudo automatizado via GitHub Actions + Terraform + OIDC.

**O que construí neste projeto:**

- Backstage rodando no Kubernetes com imagem customizada
- Catálogo com 2 domínios, 10 componentes, 5 APIs, 6 recursos e 3 times
- 4 templates de self-service:
  → Node.js Service (cria repo + CI/CD)
  → AWS S3 Bucket (provisiona automaticamente)
  → AWS ECS Fargate Spot (cluster com spot instances)
  → AWS Full Stack (EC2 + ALB + RDS + S3 + Cloudflare DNS)
- CI/CD com GitHub Actions buildando e deployando automaticamente
- Integração AWS via OIDC (sem credenciais estáticas)
- Terraform com state remoto no S3
- Workflow de destroy para limpeza de ambientes

**O resultado:** um desenvolvedor consegue, em menos de 2 minutos, criar um serviço completo com repositório, pipeline, infraestrutura na AWS e registro no catálogo — tudo com um formulário no browser.

O IDP não é sobre tirar autonomia dos times — é sobre dar autonomia com guardrails. É o caminho para escalar engenharia sem escalar complexidade.

Stack: Backstage · Kubernetes · Terraform · GitHub Actions · AWS · Cloudflare

#DevOps #PlatformEngineering #Backstage #IDP #InternalDeveloperPlatform #AWS #Terraform #Kubernetes #SRE #CloudNative

---

## Screenshots para o carrossel

### Slide 1 — Capa
> **Construindo um IDP com Backstage**
> Do zero à produção com Kubernetes, Terraform e AWS

### Slide 2 — Software Catalog
**Print:** Tela inicial do Backstage mostrando a lista de componentes (api-gateway, orders-service, payments-service, storefront, etc.)

**O que demonstra:** Visão centralizada de todos os serviços, owners e status.

### Slide 3 — Detalhe de um componente
**Print:** Página do componente `api-gateway` mostrando owner, system, lifecycle, dependências e APIs.

**O que demonstra:** Toda informação sobre um serviço em um único lugar.

### Slide 4 — Templates de Self-Service
**Print:** Tela "Create" com os 4 cards de templates (Node.js Service, AWS S3 Bucket, ECS Fargate Spot, Full Stack).

**O que demonstra:** O catálogo de self-service disponível para os desenvolvedores.

### Slide 5 — Formulário de criação
**Print:** Formulário do template Full Stack com campos: nome, região, tipo de instância, engine do banco, domínio Cloudflare.

**O que demonstra:** A experiência do desenvolvedor ao provisionar infraestrutura.

### Slide 6 — Execução do Scaffolder
**Print:** Logs de execução mostrando os steps: Gerar código ✅ → Publicar no GitHub ✅ → Registrar no catálogo ✅

**O que demonstra:** A automação end-to-end funcionando.

### Slide 7 — Repositório e CI/CD
**Print:** Repositório gerado no GitHub com a estrutura Terraform + GitHub Actions executando o Terraform Apply com sucesso.

**O que demonstra:** Código gerado automaticamente e infra sendo provisionada.

### Slide 8 — Recurso na AWS
**Print:** Console da AWS mostrando o recurso criado (ex: bucket S3).

**O que demonstra:** Prova que a infra foi realmente criada — fecha o ciclo portal → código → infra real.

### Slide 9 — Encerramento
> **Stack utilizada:**
> Backstage · Kubernetes · Terraform · GitHub Actions · AWS · Cloudflare
>
> O IDP não é sobre tirar autonomia dos times — é sobre dar autonomia com guardrails.

---

## Arquitetura do Projeto

```
┌─────────────────────────────────────────────────┐
│                  Backstage (K8s)                │
│                                                 │
│  ┌──────────┐  ┌───────────┐  ┌─────────────┐  │
│  │ Software │  │ Scaffolder│  │   Search    │  │
│  │ Catalog  │  │ Templates │  │   Engine    │  │
│  └──────────┘  └─────┬─────┘  └─────────────┘  │
│                      │                          │
└──────────────────────┼──────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │ GitHub Actions │
              │   (CI/CD)      │
              └───────┬────────┘
                      │
            ┌─────────┼─────────┐
            ▼         ▼         ▼
      ┌──────────┐ ┌─────┐ ┌──────────┐
      │ Terraform│ │OIDC │ │ Registry │
      │  Apply   │ │(AWS)│ │ (GHCR)   │
      └────┬─────┘ └─────┘ └──────────┘
           │
     ┌─────┼─────┬──────────┐
     ▼     ▼     ▼          ▼
   ┌───┐ ┌───┐ ┌────┐ ┌──────────┐
   │EC2│ │RDS│ │ S3 │ │Cloudflare│
   │ALB│ │   │ │    │ │   DNS    │
   └───┘ └───┘ └────┘ └──────────┘
```

---

## Catálogo de Entidades

| Tipo | Quantidade | Exemplos |
|---|---|---|
| Domains | 2 | engineering, data |
| Systems | 2 | ecommerce, data-platform |
| Groups | 3 | team-platform, team-data, team-frontend |
| Components | 10 | api-gateway, orders-service, storefront, etl-pipeline |
| APIs | 5 | gateway-rest-api, orders-api, payments-api, inventory-api, analytics-api |
| Resources | 6 | orders-db, payments-db, redis-cache, kafka-cluster, data-warehouse |

## Templates Disponíveis

| Template | O que cria | Recursos AWS |
|---|---|---|
| Node.js Service | Repo + CI/CD | — |
| AWS S3 Bucket | Repo + Terraform + Apply automático | S3 |
| AWS ECS Fargate Spot | Repo + Terraform + Apply automático | ECS, Fargate Spot, CloudWatch, IAM |
| AWS Full Stack | Repo + Terraform + Apply automático | EC2 Spot, ALB, RDS, S3, Cloudflare DNS |
