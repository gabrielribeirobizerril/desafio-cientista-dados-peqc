# Gera o dbt docs e copia para docs/, pasta publicada no GitHub Pages.
# O site é gerado localmente porque o `dbt docs generate` precisa de conexão
# com o BigQuery (lê o catálogo: tipos das colunas e tamanho das tabelas), e o
# CI do projeto não guarda credenciais.
# Uso (depois do dbt build): .\scripts\publicar_docs.ps1
# Resultado: docs/index.html (dbt docs em arquivo único) e docs/assets/.

# 1. Gera o site em um único HTML, com manifest e catálogo embutidos (--static)
dbt docs generate --static
if ($LASTEXITCODE -ne 0) { throw "Falha no dbt docs generate" }

# 2. Copia para docs/ o HTML e as imagens que ele referencia (assets/)
Copy-Item target\static_index.html docs\index.html -Force
New-Item -ItemType Directory -Force docs\assets | Out-Null
Copy-Item target\assets\* docs\assets\ -Force

# 3. Desliga o Jekyll do GitHub Pages: os arquivos são servidos como estão
New-Item -ItemType File -Force docs\.nojekyll | Out-Null

Write-Host "dbt docs copiado para docs/. Faça o commit de docs/ e o push."
