# ${{ values.name }}

${{ values.description }}

## Infraestrutura

| Recurso | Valor |
|---|---|
| Cluster ECS | `${{ values.name }}` |
| Região | `${{ values.region }}` |
| Imagem | `${{ values.containerImage }}` |
| CPU | ${{ values.cpu }} units |
| Memória | ${{ values.memory }} MB |
| Tasks | ${{ values.desiredCount }} |
| Spot | ${{ values.spotPercentage }}% |
| On-Demand | base 1 + restante |

## Estratégia de Capacity Provider

- **FARGATE_SPOT**: peso ${{ values.spotPercentage }}, base 1 (garante pelo menos 1 task em Spot)
- **FARGATE**: peso restante (on-demand como fallback)

## Aplicação manual

```bash
terraform init
terraform plan
terraform apply
```
