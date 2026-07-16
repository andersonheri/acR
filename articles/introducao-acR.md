# Introdução ao acR: pipeline integrado de análise de conteúdo

``` r

library(acR)
```

## Objetivo

O `acR` integra, em um único fluxo reprodutível, a análise quantitativa
clássica de texto (frequências, *keyness*, coocorrência, LDA,
sentimento) e a codificação qualitativa assistida por modelos de
linguagem (LLMs) via `ellmer`. Esta vignette apresenta o caminho mínimo
do dado bruto ao resultado, usando apenas funções que rodam sem chave de
API. O módulo de LLM é demonstrado ao final, com execução desativada.

O objeto central é o `ac_corpus`, um `tibble` com colunas padronizadas
`doc_id` e `text`, sobre o qual todas as demais funções operam.

## 1. Construir um corpus

``` r

df <- data.frame(
  id      = c("d1", "d2", "d3", "d4"),
  texto   = c(
    "O deputado do PT defendeu a reforma na CCJ.",
    "O deputado do PL criticou a reforma novamente.",
    "A senadora do PT relatou o projeto na comissão.",
    "O senador do PL obstruiu a votação do projeto."
  ),
  partido = c("PT", "PL", "PT", "PL"),
  stringsAsFactors = FALSE
)

corp <- ac_corpus(df, text = texto, docid = id, meta = partido)
corp
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 4
#> • Metadados: 1 coluna
#> • Idioma: "pt"
#> 
#> # A tibble: 4 × 3
#>   doc_id text                                            partido
#>   <chr>  <chr>                                           <chr>  
#> 1 d1     O deputado do PT defendeu a reforma na CCJ.     PT     
#> 2 d2     O deputado do PL criticou a reforma novamente.  PL     
#> 3 d3     A senadora do PT relatou o projeto na comissão. PT     
#> 4 d4     O senador do PL obstruiu a votação do projeto.  PL
```

## 2. Frequências e termos mais salientes

``` r

# Frequência de unigramas no corpus inteiro
freq <- ac_count(corp)
ac_top_terms(freq, n = 8)
#> # A tibble: 34 × 3
#>    doc_id token     n
#>    <chr>  <chr> <int>
#>  1 d4     do        2
#>  2 d3     A         1
#>  3 d1     CCJ.      1
#>  4 d1     O         1
#>  5 d2     O         1
#>  6 d4     O         1
#>  7 d2     PL        1
#>  8 d4     PL        1
#>  9 d1     PT        1
#> 10 d3     PT        1
#> # ℹ 24 more rows

# Frequência por partido
freq_partido <- ac_count(corp, by = "partido")
ac_top_terms(freq_partido, n = 5, by = "partido")
#> # A tibble: 27 × 3
#>    partido token          n
#>    <chr>   <chr>      <int>
#>  1 PL      do             3
#>  2 PL      O              2
#>  3 PL      PL             2
#>  4 PL      a              2
#>  5 PL      criticou       1
#>  6 PL      deputado       1
#>  7 PL      novamente.     1
#>  8 PL      obstruiu       1
#>  9 PL      projeto.       1
#> 10 PL      reforma        1
#> # ℹ 17 more rows
```

## 3. Escolher um modelo LLM para a etapa qualitativa

Antes de codificar qualitativamente, o `acR` ajuda a selecionar um
modelo adequado ao orçamento e ao idioma do corpus. A consulta usa um
banco interno curado e funciona offline.

``` r

# Modelos recomendados para classificação em português, orçamento médio
ac_qual_recommend_model(task = "coding", budget = "medium", lang = "pt", n = 3)
#> 
#> ── Recomendacoes de modelo acR ─────────────────────────────────────────────────
#> ℹ Tarefa: "coding" | Budget: "medium" | Idioma: "pt"
#> ℹ Baseado em Gilardi et al. (2023, PNAS) e Tornberg (2023, PLOS ONE).
#> # A tibble: 3 × 12
#>    rank provider model_id           name  tier  context_k cost_input cost_output
#>   <int> <chr>    <chr>              <chr> <chr>     <dbl>      <dbl>       <dbl>
#> 1     1 google   google/gemini-2.0… Gemi… fast       1000       0.1          0.4
#> 2     2 google   google/gemini-2.5… Gemi… fron…      1000       1.25        10  
#> 3     3 openai   openai/o4-mini     o4-m… bala…       200       1.1          4.4
#> # ℹ 4 more variables: pt_support <chr>, score <dbl>, justificativa <chr>,
#> #   acr_string <chr>
```

A recomendação é baseada em benchmarks de anotação de texto em Ciências
Sociais (Gilardi, Alizadeh e Kubli, 2023; Törnberg, 2023) combinados com
custo, janela de contexto e suporte estimado ao português.

## 4. Codificação qualitativa assistida por LLM

Esta etapa requer uma chave de API configurada e, por isso, não é
executada na construção da vignette. O padrão de uso é o seguinte.

``` r

# Requer chave de API (ex.: ANTHROPIC_API_KEY) configurada no ambiente
codebook <- ac_qual_codebook(
  name         = "posicionamento",
  instructions = "Classifique o posicionamento do parlamentar sobre a reforma.",
  categories   = list(
    apoio   = "manifestação favorável à reforma",
    critica = "manifestação contrária à reforma",
    neutro  = "sem posicionamento claro"
  ),
  mode = "manual"
)

codificado <- ac_qual_code(
  corpus   = corp,
  codebook = codebook,
  model    = "anthropic/claude-sonnet-4-5"
)

codificado
```

## 5. Validar com codificação humana

O `acR` fecha o ciclo com validação humana e métricas de confiabilidade
entre codificadores. O fluxo abaixo é offline após a codificação.

``` r

# Amostra estratificada para revisão humana
amostra <- ac_qual_sample(codificado, n = 50, strategy = "stratified")

# Exporta planilha para o codificador humano preencher
ac_qual_export_for_review(amostra, path = "validacao_humana.xlsx", corpus = corp)

# Após o preenchimento, reimporta e calcula confiabilidade
humano <- ac_qual_import_human("validacao_humana.xlsx")
ac_qual_reliability(llm = codificado, human = humano)
```

As métricas incluem *percent agreement*, *alpha* de Krippendorff, AC1 de
Gwet e F1 macro, com intervalos de confiança por *bootstrap* e
interpretação segundo Landis e Koch (1977) e Gwet (2014).

## Próximos passos

Consulte as vignettes específicas para aprofundamento: análise de
proposições, LDA, sentimento e o fluxo qualitativo completo com LLMs.

## Referências

GILARDI, F.; ALIZADEH, M.; KUBLI, M. ChatGPT outperforms crowd workers
for text-annotation tasks. *PNAS*, v. 120, n. 30, 2023.

GWET, K. L. *Handbook of inter-rater reliability*. 4. ed. Gaithersburg:
Advanced Analytics, 2014.

KRIPPENDORFF, K. *Content analysis: an introduction to its methodology*.
4. ed. Thousand Oaks: SAGE, 2018.

LANDIS, J. R.; KOCH, G. G. The measurement of observer agreement for
categorical data. *Biometrics*, v. 33, n. 1, p. 159-174, 1977.

TÖRNBERG, P. ChatGPT-4 outperforms experts and crowd workers in
annotating political Twitter messages with zero-shot learning. *PLOS
ONE*, v. 18, n. 4, 2023.
