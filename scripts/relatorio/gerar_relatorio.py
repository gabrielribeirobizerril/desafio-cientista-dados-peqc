r"""
Gera docs/relatorio-resultados.html a partir dos seis marts exportados em CSV.

Uso (depois do dbt build):
  .\scripts\relatorio\exportar_marts.ps1 -Project <seu-projeto>
  python scripts/relatorio/gerar_relatorio.py

Lê os CSVs de scripts/relatorio/dados/ (um por mart) e monta uma seção
recolhível por mart, só com números, tabelas e gráficos. O único texto fica
no cabeçalho.
Dependências: pandas.
"""
import argparse
import html
import os
from datetime import date

import pandas as pd

MARTS = [
    "absenteismo_escola",
    "absenteismo_bairro",
    "absenteismo_disciplina",
    "desempenho_escola",
    "desempenho_bairro",
    "desempenho_faixa_etaria",
]
NOME = {"portugues": "Português", "matematica": "Matemática", "ciencias": "Ciências", "ingles": "Inglês"}

# Tamanho mínimo para listas e percentis (mesmos cortes do notebook ii_analytics).
MINIMO_ALUNOS = 30
MINIMO_NOTAS = 30
MINIMO_VINCULOS_BAIRRO = 300


# ---------------------------------------------------------------- formatação
def n(x, d=0):
    s = f"{x:,.{d}f}"
    return s.replace(",", "X").replace(".", ",").replace("X", ".")


def pct(x, d=1):
    return n(100 * x, d) + "%"


def hashc(h):
    """Identificador anonimizado truncado (só para distinguir linhas)."""
    return html.escape(str(h)[:10]) + "…"


def tabela(cabecalho, linhas):
    t = '<div class="tw"><table><thead><tr>' + "".join(f"<th>{c}</th>" for c in cabecalho) + "</tr></thead><tbody>"
    for linha in linhas:
        t += "<tr>" + "".join(f"<td>{c}</td>" for c in linha) + "</tr>"
    return t + "</tbody></table></div>"


def kpis(itens):
    return '<div class="kpis">' + "".join(
        f'<div class="kpi"><b>{v}</b><span>{r}</span></div>' for v, r in itens
    ) + "</div>"


def secao(mart, titulo, corpo):
    return (
        f'<details open><summary><span class="t">{titulo}</span>'
        f'<code>mart_educacao__{mart}</code></summary><div class="corpo">{corpo}</div></details>'
    )


# ---------------------------------------------------------------- gráficos
def barras_horizontais(linhas, vmax, fmt, w=640, rh=30, lw=130):
    h = rh * len(linhas) + 8
    pw = w - lw - 80
    out = [f'<svg viewBox="0 0 {w} {h}" role="img" class="chart">']
    for i, (rotulo, v) in enumerate(linhas):
        y = i * rh + 4
        bw = max(2, pw * v / vmax)
        out.append(f'<text x="{lw - 8}" y="{y + rh / 2 + 1}" class="lab" text-anchor="end">{html.escape(rotulo)}</text>')
        out.append(f'<rect x="{lw}" y="{y + 5}" width="{bw:.1f}" height="{rh - 12}" rx="4" class="s1"><title>{html.escape(rotulo)}: {fmt(v)}</title></rect>')
        out.append(f'<text x="{lw + bw + 6:.1f}" y="{y + rh / 2 + 1}" class="val">{fmt(v)}</text>')
    out.append(f'<line x1="{lw}" x2="{lw}" y1="0" y2="{h}" class="axis"/></svg>')
    return "".join(out)


def histograma(valores, unidade="escolas", passo=0.025, w=640, h=220):
    """Unidades por faixa de taxa: uma barra para 0 e intervalos de `passo`."""
    limite = max(valores.max(), passo)
    nfaixas = int(limite // passo) + 1
    contagens = [int((valores == 0).sum())]
    rotulos = ["0"]
    for i in range(nfaixas):
        a, b = i * passo, (i + 1) * passo
        contagens.append(int(((valores > a if i == 0 else valores >= a) & (valores < b)).sum()))
        rotulos.append(f"{n(100 * a, 1).replace(',0', '')}–{n(100 * b, 1).replace(',0', '')}")
    mx = max(contagens)
    pl, pb, pt = 40, 40, 14
    pw = w - pl - 10
    bw = pw / len(contagens)
    out = [f'<svg viewBox="0 0 {w} {h}" role="img" class="chart">']
    for t in range(0, mx + 1, 5 if mx <= 40 else max(10, int(round(mx / 4, -1)))):
        y = h - pb - (h - pb - pt) * t / mx
        out.append(f'<line x1="{pl}" x2="{w - 10}" y1="{y:.1f}" y2="{y:.1f}" class="grid"/><text x="{pl - 6}" y="{y + 4:.1f}" class="tick" text-anchor="end">{t}</text>')
    for i, c in enumerate(contagens):
        bh = (h - pb - pt) * c / mx
        x = pl + i * bw + 1
        out.append(f'<rect x="{x:.1f}" y="{h - pb - bh:.1f}" width="{bw - 2:.1f}" height="{bh:.1f}" rx="3" class="s1"><title>{rotulos[i]}%: {c} {unidade}</title></rect>')
        out.append(f'<text x="{x + bw / 2 - 1:.1f}" y="{h - pb + 15}" class="tick" text-anchor="middle">{rotulos[i]}</text>')
    out.append(f'<text x="{pl + pw / 2}" y="{h - 6}" class="tick" text-anchor="middle">taxa de absenteísmo crônico (%) · {unidade}</text></svg>')
    return "".join(out)


def barras_agrupadas(df, grupos, series, w=640, h=240):
    pl, pb, pt = 34, 40, 12
    pw = w - pl - 10
    gw = pw / len(grupos)
    bw = (gw - 30) / len(series)
    out = [f'<svg viewBox="0 0 {w} {h}" role="img" class="chart">']
    for t in range(0, 11, 2):
        y = h - pb - (h - pb - pt) * t / 10
        out.append(f'<line x1="{pl}" x2="{w - 10}" y1="{y:.1f}" y2="{y:.1f}" class="grid"/><text x="{pl - 6}" y="{y + 4:.1f}" class="tick" text-anchor="end">{t}</text>')
    for i, g in enumerate(grupos):
        for j, s in enumerate(series):
            linha = df[(df["faixa_etaria"] == g) & (df["disciplina"] == s)]
            if linha.empty:
                continue
            v = linha["media_nota"].iloc[0]
            bh = (h - pb - pt) * v / 10
            x = pl + i * gw + 15 + j * bw
            out.append(f'<rect x="{x + 1:.1f}" y="{h - pb - bh:.1f}" width="{bw - 2:.1f}" height="{bh:.1f}" rx="4" class="s{j + 1}"><title>{g} · {NOME[s]}: {n(v, 2)}</title></rect>')
        out.append(f'<text x="{pl + i * gw + gw / 2:.1f}" y="{h - pb + 18}" class="lab" text-anchor="middle">{g} anos</text>')
    out.append("</svg>")
    legenda = '<div class="legend">' + "".join(
        f'<span><i class="c{j + 1}"></i>{NOME[s]}</span>' for j, s in enumerate(series)
    ) + "</div>"
    return "".join(out) + legenda


def boxplot(df, series, w=640, h=260):
    """Um box por disciplina: caixa P25–P75, linha na mediana, bigodes P10–P90,
    pontos para bairros fora dos bigodes. Usa só bairros com MINIMO_NOTAS+ notas."""
    dados = {s: df[(df["disciplina"] == s) & (df["qtd_notas"] >= MINIMO_NOTAS)]["media_nota"] for s in series}
    todos = pd.concat(dados.values())
    lo, hi = int(todos.min()), int(todos.max()) + 1
    pl, pb, pt = 34, 34, 12
    gw = (w - pl - 10) / len(series)
    y = lambda v: h - pb - (h - pb - pt) * (v - lo) / (hi - lo)
    out = [f'<svg viewBox="0 0 {w} {h}" role="img" class="chart">']
    for t in range(lo, hi + 1):
        out.append(f'<line x1="{pl}" x2="{w - 10}" y1="{y(t):.1f}" y2="{y(t):.1f}" class="grid"/><text x="{pl - 6}" y="{y(t) + 4:.1f}" class="tick" text-anchor="end">{t}</text>')
    for j, s in enumerate(series):
        v = dados[s]
        q = v.quantile([0.1, 0.25, 0.5, 0.75, 0.9])
        cx, bw = pl + j * gw + gw / 2, min(90, gw * 0.4)
        dica = f"{NOME[s]} · {n(len(v))} bairros · P10 {n(q[0.1], 2)} · P25 {n(q[0.25], 2)} · mediana {n(q[0.5], 2)} · P75 {n(q[0.75], 2)} · P90 {n(q[0.9], 2)}"
        out.append(f'<line x1="{cx}" x2="{cx}" y1="{y(q[0.9]):.1f}" y2="{y(q[0.1]):.1f}" class="axis"/>')
        for k in (0.1, 0.9):
            out.append(f'<line x1="{cx - bw / 4:.1f}" x2="{cx + bw / 4:.1f}" y1="{y(q[k]):.1f}" y2="{y(q[k]):.1f}" class="axis"/>')
        out.append(f'<rect x="{cx - bw / 2:.1f}" y="{y(q[0.75]):.1f}" width="{bw:.1f}" height="{y(q[0.25]) - y(q[0.75]):.1f}" rx="4" class="s{j + 1}" fill-opacity=".85"><title>{dica}</title></rect>')
        out.append(f'<line x1="{cx - bw / 2:.1f}" x2="{cx + bw / 2:.1f}" y1="{y(q[0.5]):.1f}" y2="{y(q[0.5]):.1f}" class="med"/>')
        for x in v[(v < q[0.1]) | (v > q[0.9])]:
            out.append(f'<circle cx="{cx}" cy="{y(x):.1f}" r="2.5" class="s{j + 1}" fill-opacity=".5"/>')
        out.append(f'<text x="{cx}" y="{h - pb + 18}" class="lab" text-anchor="middle">{NOME[s]} ({n(len(v))})</text>')
    out.append("</svg>")
    return "".join(out) + '<div class="legend"><span>média dos bairros com 30+ notas · caixa P25–P75 · traço na mediana · bigodes P10–P90</span></div>'


# ---------------------------------------------------------------- seções
def absenteismo_escola(ae):
    vinculos = ae["qtd_alunos"].sum()
    casos = ae["qtd_alunos_absenteismo_cronico"].sum()
    comparaveis = ae[ae["qtd_alunos"] >= MINIMO_ALUNOS]
    q = comparaveis["taxa_absenteismo_cronico"].quantile([0.1, 0.5, 0.9])
    ordenadas = comparaveis.sort_values("qtd_alunos_absenteismo_cronico", ascending=False)
    acumulado = ordenadas["qtd_alunos_absenteismo_cronico"].cumsum() / ordenadas["qtd_alunos_absenteismo_cronico"].sum()
    k = int((acumulado < 0.5).sum()) + 1
    top = comparaveis.sort_values("taxa_absenteismo_cronico", ascending=False).head(10)
    corpo = kpis([
        (pct(casos / vinculos), f"taxa da rede ({n(casos)} de {n(vinculos)} vínculos)"),
        (n(len(ae)), "escolas"),
        (n((ae["qtd_alunos_absenteismo_cronico"] == 0).sum()), "escolas sem nenhum caso"),
        (n(k), f"escolas com metade dos casos (entre {n(len(comparaveis))} com {MINIMO_ALUNOS}+ alunos)"),
    ])
    corpo += tabela(
        ["Escolas com 30+ alunos", "P10", "Mediana", "P90", "Máximo"],
        [[n(len(comparaveis)), pct(q[0.1]), pct(q[0.5]), pct(q[0.9]), pct(comparaveis["taxa_absenteismo_cronico"].max())]],
    )
    corpo += f'<figure>{histograma(comparaveis["taxa_absenteismo_cronico"])}</figure>'
    corpo += "<h3>10 maiores taxas (escolas com 30+ alunos)</h3>" + tabela(
        ["Escola", "Bairro", "Vínculos", "Casos", "Taxa", "Frequência média"],
        [[hashc(r.id_escola), hashc(r.bairro_escola), n(r.qtd_alunos), n(r.qtd_alunos_absenteismo_cronico),
          pct(r.taxa_absenteismo_cronico), n(r.media_percentual_frequencia, 1) + "%"] for r in top.itertuples()],
    )
    return secao("absenteismo_escola", "Absenteísmo crônico por escola", corpo)


def absenteismo_bairro(ab):
    comparaveis = ab[ab["qtd_vinculos_aluno_escola"] >= MINIMO_VINCULOS_BAIRRO]
    q = comparaveis["taxa_absenteismo_cronico"].quantile([0.1, 0.5, 0.9])
    top = comparaveis.sort_values("taxa_absenteismo_cronico", ascending=False).head(10)
    corpo = kpis([
        (n(len(ab)), "bairros"),
        (n((ab["qtd_escolas"] == 1).sum()), "bairros com uma escola só"),
        (n(len(comparaveis)), f"bairros com {MINIMO_VINCULOS_BAIRRO}+ vínculos"),
    ])
    corpo += tabela(
        ["Bairros com 300+ vínculos", "P10", "Mediana", "P90", "Máximo"],
        [[n(len(comparaveis)), pct(q[0.1]), pct(q[0.5]), pct(q[0.9]), pct(comparaveis["taxa_absenteismo_cronico"].max())]],
    )
    corpo += f'<figure>{histograma(comparaveis["taxa_absenteismo_cronico"], "bairros", 0.01)}</figure>'
    corpo += "<h3>10 maiores taxas (bairros com 300+ vínculos)</h3>" + tabela(
        ["Bairro", "Escolas", "Vínculos", "Casos", "Taxa"],
        [[hashc(r.bairro_escola), n(r.qtd_escolas), n(r.qtd_vinculos_aluno_escola),
          n(r.qtd_vinculos_absenteismo_cronico), pct(r.taxa_absenteismo_cronico)] for r in top.itertuples()],
    )
    return secao("absenteismo_bairro", "Absenteísmo crônico por bairro", corpo)


def absenteismo_disciplina(ad):
    ad = ad.sort_values("taxa_absenteismo_cronico", ascending=False)
    grafico = barras_horizontais(
        [(NOME[r.disciplina], r.taxa_absenteismo_cronico) for r in ad.itertuples()],
        ad["taxa_absenteismo_cronico"].max() * 1.1, pct,
    )
    corpo = f"<figure>{grafico}</figure>" + tabela(
        ["Disciplina", "Vínculos", "Casos", "Taxa", "Frequência média"],
        [[NOME[r.disciplina], n(r.qtd_vinculos_aluno_escola), n(r.qtd_vinculos_absenteismo_cronico),
          pct(r.taxa_absenteismo_cronico), n(r.media_percentual_frequencia, 1) + "%"] for r in ad.itertuples()],
    )
    return secao("absenteismo_disciplina", "Absenteísmo crônico por disciplina", corpo)


def resumo_desempenho(df, unidade, minimo_rotulo):
    linhas = []
    for disciplina in ["portugues", "ciencias", "matematica"]:
        d = df[df["disciplina"] == disciplina]
        comparaveis = d[d["qtd_notas"] >= MINIMO_NOTAS]
        q = comparaveis["media_nota"].quantile([0.1, 0.5, 0.9])
        linhas.append([
            NOME[disciplina], n(d["qtd_notas"].sum()), n(d["soma_notas"].sum() / d["qtd_notas"].sum(), 2),
            n(len(comparaveis)), n(q[0.1], 2), n(q[0.5], 2), n(q[0.9], 2),
        ])
    return tabela(["Disciplina", "Notas", "Média", f"{unidade} ({minimo_rotulo})", "P10", "Mediana", "P90"], linhas)


def desempenho_escola(de):
    corpo = kpis([(n(de["id_escola"].nunique()), "escolas com notas"), (n(de["qtd_notas"].sum()), "notas com escola conhecida")])
    corpo += resumo_desempenho(de, "Escolas", "30+ notas")
    return secao("desempenho_escola", "Desempenho por escola", corpo)


def desempenho_bairro(db):
    corpo = kpis([(n(db["bairro_escola"].nunique()), "bairros com notas")])
    corpo += f"<figure>{boxplot(db, ['portugues', 'ciencias', 'matematica'])}</figure>"
    corpo += resumo_desempenho(db, "Bairros", "30+ notas")
    return secao("desempenho_bairro", "Desempenho por bairro", corpo)


def desempenho_faixa_etaria(df):
    df = df.sort_values(["ordem_faixa_etaria", "disciplina"])
    faixas = list(df["faixa_etaria"].unique())
    series = ["portugues", "ciencias", "matematica"]
    corpo = f"<figure>{barras_agrupadas(df, faixas, series)}</figure>"
    corpo += tabela(
        ["Faixa etária", "Disciplina", "Alunos", "Notas", "Média", "Desvio padrão"],
        [[r.faixa_etaria, NOME[r.disciplina], n(r.qtd_alunos), n(r.qtd_notas), n(r.media_nota, 2), n(r.desvio_padrao_nota, 2)]
         for r in df.itertuples()],
    )
    return secao("desempenho_faixa_etaria", "Desempenho por faixa etária", corpo)


# ---------------------------------------------------------------- página
CSS = """
:root{color-scheme:light;--surface:#fcfcfb;--surface-2:#f2f1ee;--border:#e1dfda;--text:#0b0b0b;--text-2:#52514e;
--grid:#e7e5e0;--axis:#bdbab3;--s1:#2a78d6;--s2:#eb6834;--s3:#1baf7a}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){color-scheme:dark;--surface:#1a1a19;--surface-2:#242422;
--border:#34332f;--text:#f0efec;--text-2:#c3c2b7;--grid:#2e2d2a;--axis:#55534d;--s1:#3987e5;--s2:#d95926;--s3:#199e70}}
*{box-sizing:border-box}
body{margin:0;background:var(--surface);color:var(--text);font:15px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
main{max-width:880px;margin:0 auto;padding:36px 16px 56px}
h1{font-size:1.6rem;margin:0 0 8px}
.cab{color:var(--text-2);margin:0 0 24px}
details{border:1px solid var(--border);border-radius:10px;margin:14px 0;background:var(--surface)}
summary{cursor:pointer;padding:12px 16px;display:flex;justify-content:space-between;align-items:center;gap:12px;
background:var(--surface-2);border-radius:10px;list-style:none}
summary::-webkit-details-marker{display:none}
summary::before{content:"▸";margin-right:8px;color:var(--text-2)}
details[open] summary::before{content:"▾"}
details[open] summary{border-radius:10px 10px 0 0}
summary .t{font-weight:600;font-size:1.05rem;flex:1}
summary code{font:.78rem ui-monospace,Menlo,monospace;color:var(--text-2)}
.corpo{padding:4px 16px 14px}
h3{font-size:.95rem;margin:20px 0 4px}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:10px;margin:14px 0}
.kpi{background:var(--surface-2);border:1px solid var(--border);border-radius:8px;padding:10px 12px}
.kpi b{display:block;font-size:1.35rem;font-variant-numeric:tabular-nums}
.kpi span{color:var(--text-2);font-size:.82rem}
.tw{overflow-x:auto;margin:10px 0}
table{border-collapse:collapse;width:100%;font-size:.88rem;font-variant-numeric:tabular-nums}
th,td{padding:6px 9px;border-bottom:1px solid var(--border);text-align:right;white-space:nowrap}
th:first-child,td:first-child{text-align:left}
th{color:var(--text-2);font-weight:600;background:var(--surface-2)}
figure{margin:12px 0}
.chart{width:100%;height:auto;display:block}
.chart .lab{fill:var(--text);font-size:13px}.chart .val,.chart .tick{fill:var(--text-2);font-size:12px}
.chart .grid{stroke:var(--grid)}.chart .med{stroke:var(--surface);stroke-width:2.5}.chart .axis{stroke:var(--axis)}
.chart .s1{fill:var(--s1)}.chart .s2{fill:var(--s2)}.chart .s3{fill:var(--s3)}
.legend{display:flex;gap:16px;font-size:.85rem;color:var(--text-2)}
.legend i{display:inline-block;width:11px;height:11px;border-radius:3px;margin-right:6px}
.legend .c1{background:var(--s1)}.legend .c2{background:var(--s2)}.legend .c3{background:var(--s3)}
"""


def gerar(ler, saida, origem):
    dados = {m: ler(f"mart_educacao__{m}") for m in MARTS}
    cabecalho = (
        f"Indicadores dos seis marts do projeto dbt, exportados de <code>{html.escape(origem)}</code>; relatório gerado em "
        f"{date.today().strftime('%d/%m/%Y')}. Os dados do RMI foram anonimizados e aleatorizados: os números "
        "ilustram o método e não descrevem a rede real. O absenteísmo crônico é a frequência estimada abaixo "
        "de 75%, por vínculo aluno–escola; o bairro é o da escola. Percentis e listas consideram só escolas com "
        "30 alunos ou mais (absenteísmo) ou 30 notas ou mais (desempenho) e bairros com 300 vínculos ou mais."
    )
    corpo = "".join([
        absenteismo_escola(dados["absenteismo_escola"]),
        absenteismo_bairro(dados["absenteismo_bairro"]),
        absenteismo_disciplina(dados["absenteismo_disciplina"]),
        desempenho_escola(dados["desempenho_escola"]),
        desempenho_bairro(dados["desempenho_bairro"]),
        desempenho_faixa_etaria(dados["desempenho_faixa_etaria"]),
    ])
    pagina = (
        '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        f"<title>Resultados dos indicadores educacionais</title><style>{CSS}</style></head><body><main>"
        f'<h1>Desempenho e absenteísmo na rede municipal</h1><p class="cab">{cabecalho}</p>'
        f"{corpo}</main></body></html>"
    )
    with open(saida, "w", encoding="utf-8") as arquivo:
        arquivo.write(pagina)
    return saida


if __name__ == "__main__":
    raiz = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser()
    parser.add_argument("--dados", default=os.path.join(raiz, "dados"))
    parser.add_argument("--saida", default=os.path.join(raiz, "..", "..", "docs", "relatorio-resultados.html"))
    args = parser.parse_args()

    def ler(tabela):
        arquivo = os.path.join(args.dados, tabela.replace("mart_educacao__", "") + ".csv")
        return pd.read_csv(arquivo, encoding="utf-8-sig", dtype={"id_escola": str, "bairro_escola": str})

    print("Relatório gerado em", gerar(ler, os.path.abspath(args.saida), "dbt_dev_marts (exportação em CSV)"))
