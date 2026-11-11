# Carrega os Parquets do desafio (GCS) no dataset raw do BigQuery.
# Execução idempotente em 3 passos, que devem ser seguidos em ordem:
#   1. cria o dataset;
#   2. carrega as cinco tabelas, substituindo o conteúdo anterior;
#   3. confere as contagens de linhas com a linha de base do snapshot do
#      desafio e falha se alguma divergir.
# Uso: .\scripts\load_raw.ps1 -Project <seu-projeto-gcp>
# Para carregar outro snapshot sem conferir as contagens: -SemConferencia

param(
    [Parameter(Mandatory = $true)][string]$Project,
    [string]$Dataset  = "raw_rmi",
    [string]$Location = "US",
    [string]$Bucket   = "gs://case_vagas/rmi",
    [switch]$SemConferencia
)

$tabelas = "aluno", "escola", "turma", "frequencia", "avaliacao"

# Linha de base do snapshot entregue no desafio (perfilamento).
$esperado = @{
    aluno      = 97044
    escola     = 1558
    turma      = 97044
    frequencia = 2727684
    avaliacao  = 221687
}

# 1. Cria o dataset (--force: não falha se ele já existir)
bq mk --force --location=$Location --dataset "${Project}:${Dataset}"
if ($LASTEXITCODE -ne 0) { throw "Falha ao criar o dataset $Dataset" }

# 2. Carrega cada tabela (--replace: substitui em vez de acrescentar)
foreach ($t in $tabelas) {
    Write-Host "Carregando $t..."
    bq load --project_id=$Project --replace --source_format=PARQUET "${Dataset}.${t}" "$Bucket/$t"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao carregar $t" }
}

# 3. Lê as contagens e confere com a linha de base
$csv = bq query --project_id=$Project --use_legacy_sql=false --format=csv `
    "SELECT table_id, row_count FROM ${Dataset}.__TABLES__ ORDER BY table_id"
if ($LASTEXITCODE -ne 0) { throw "Falha ao consultar as contagens de linhas" }

$contagens = $csv | ConvertFrom-Csv
$contagens | Format-Table -AutoSize

if ($SemConferencia) {
    Write-Host "Conferência das contagens desativada (-SemConferencia)."
    return
}

$divergencias = @()
foreach ($t in $tabelas) {
    $linha = $contagens | Where-Object { $_.table_id -eq $t }
    if ($null -eq $linha) {
        $divergencias += "${t}: tabela ausente"
    }
    elseif ([int64]$linha.row_count -ne $esperado[$t]) {
        $divergencias += "${t}: $($linha.row_count) linhas (esperado: $($esperado[$t]))"
    }
}

if ($divergencias.Count -gt 0) {
    throw "Contagens diferentes da linha de base do desafio:`n$($divergencias -join "`n")"
}
Write-Host "Carga conferida: as cinco tabelas batem com a linha de base do desafio."
