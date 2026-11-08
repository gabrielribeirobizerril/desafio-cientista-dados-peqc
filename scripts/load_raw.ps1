# Carrega os Parquets do desafio (GCS) no dataset raw do BigQuery.
# Execução idempotente dividida em 3 passos que devem ser seguidos em ordem.
# Uso: .\scripts\load_raw.ps1 -Project <seu-projeto-gcp>

param(
    [Parameter(Mandatory = $true)][string]$Project,
    [string]$Dataset  = "raw_rmi",
    [string]$Location = "US",
    [string]$Bucket   = "gs://case_vagas/rmi"
)

$tabelas = "aluno", "escola", "turma", "frequencia", "avaliacao"

# 1. Cria o dataset (--force: não falha se ele já existir)
bq mk --force --location=$Location --dataset "${Project}:${Dataset}"
if ($LASTEXITCODE -ne 0) { throw "Falha ao criar o dataset $Dataset" }

# 2. Carrega cada tabela (--replace: substitui em vez de acrescentar)
foreach ($t in $tabelas) {
    Write-Host "Carregando $t..."
    bq load --project_id=$Project --replace --source_format=PARQUET "${Dataset}.${t}" "$Bucket/$t"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao carregar $t" }
}

# 3. Confere as contagens com a linha de base
bq query --project_id=$Project --use_legacy_sql=false "SELECT table_id, row_count FROM ${Dataset}.__TABLES__ ORDER BY table_id"