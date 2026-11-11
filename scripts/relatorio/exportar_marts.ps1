# Exporta os seis marts para CSV, usados por gerar_relatorio.py.
# Uso (depois do dbt build): .\scripts\relatorio\exportar_marts.ps1 -Project <seu-projeto>

param(
    [Parameter(Mandatory = $true)][string]$Project,
    [string]$Dataset = "dbt_dev_marts"
)

$pasta = Join-Path $PSScriptRoot "dados"
New-Item -ItemType Directory -Force $pasta | Out-Null

$marts = "desempenho_escola", "desempenho_bairro", "desempenho_faixa_etaria",
         "absenteismo_escola", "absenteismo_bairro", "absenteismo_disciplina"

foreach ($m in $marts) {
    Write-Host "Exportando mart_educacao__$m..."
    $csv = bq query --project_id=$Project --use_legacy_sql=false --format=csv --max_rows=100000 `
        "SELECT * FROM ${Dataset}.mart_educacao__$m"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao exportar mart_educacao__$m" }
    $csv | Out-File -Encoding utf8 (Join-Path $pasta "$m.csv")
}
Write-Host "CSVs gravados em $pasta"
