# ${{ values.name }}

${{ values.description }}

## Recursos criados

- S3 Bucket: `${{ values.name }}`
- Região: `${{ values.region }}`
- Versionamento: ${{ values.versioning }}
- Criptografia SSE-S3: ${{ values.encryption }}
- Acesso público: bloqueado

## Como aplicar

```bash
# Inicializar
terraform init

# Planejar
terraform plan

# Aplicar
terraform apply
```

> O provider está configurado com `profile = "staging"`. Certifique-se de ter o profile configurado em `~/.aws/credentials`.
