# ${{ values.name }}

${{ values.description }}

## Arquitetura

```
Cloudflare DNS (${{ values.subdomain }}.${{ values.domain }})
        │
        ▼
   ALB (Application Load Balancer)
        │
        ▼
   EC2 Auto Scaling Group (${{ values.instanceCount }}x ${{ values.instanceType }}{% if values.useSpot %} Spot{% endif %})
        │
   ┌────┴────┐
   ▼         ▼
  RDS       S3
  (${{ values.dbEngine }})   (assets)
```

## Recursos

| Recurso | Configuração |
|---|---|
| EC2 | ${{ values.instanceCount }}x ${{ values.instanceType }}{% if values.useSpot %} (Spot){% endif %} |
| ALB | Application Load Balancer |
| RDS | ${{ values.dbEngine }} - ${{ values.dbInstanceClass }} - ${{ values.dbStorage }}GB{% if values.dbMultiAz %} Multi-AZ{% endif %} |
| S3 | ${{ values.name }}-${{ values.environment }}-assets |
| DNS | ${{ values.subdomain }}.${{ values.domain }} (Cloudflare proxied) |
| Região | ${{ values.region }} |
| Ambiente | ${{ values.environment }} |

## Secrets necessários no GitHub

Antes do Terraform Apply funcionar, configure estes secrets no repositório (Settings → Secrets → Actions):

| Secret | Descrição |
|---|---|
| `DB_PASSWORD` | Senha do banco de dados RDS |
| `CLOUDFLARE_API_TOKEN` | Token da API do Cloudflare com permissão de DNS edit |

## Aplicação manual

```bash
export TF_VAR_db_password="sua-senha"
export TF_VAR_cloudflare_api_token="seu-token"
terraform init
terraform plan
terraform apply
```
