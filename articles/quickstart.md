# Quickstart — acR em 5 minutos

Quer entender o `acR` sem ler nada longo? Este é o menor caminho
ponta-a-ponta usando apenas as funções que rodam **offline e sem chave
de API**. Copie e cole.

``` r

library(acR)
```

## 1 · Um corpus mínimo

``` r

df <- data.frame(
  id       = paste0("d", 1:6),
  texto    = c(
    "Sou favoravel a reforma tributaria que simplifica os impostos.",
    "Voto contra a proposta, ela vai destruir o setor produtivo.",
    "Apoio integralmente a reforma, ha ganhos claros de eficiencia.",
    "Esta reforma e um retrocesso, vamos rejeitar em plenario.",
    "Defendo a proposta que corrige distorcoes historicas do sistema.",
    "Somos contra, o texto beneficia apenas grandes corporacoes."
  ),
  posicao  = c("favor", "contra", "favor", "contra", "favor", "contra"),
  stringsAsFactors = FALSE
)

corpus <- ac_corpus(df, text = texto, docid = id, meta = posicao)
corpus
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 6
#> • Metadados: 1 coluna
#> • Idioma: "pt"
#> 
#> # A tibble: 6 × 3
#>   doc_id text                                                            posicao
#>   <chr>  <chr>                                                           <chr>  
#> 1 d1     Sou favoravel a reforma tributaria que simplifica os impostos.  favor  
#> 2 d2     Voto contra a proposta, ela vai destruir o setor produtivo.     contra 
#> 3 d3     Apoio integralmente a reforma, ha ganhos claros de eficiencia.  favor  
#> 4 d4     Esta reforma e um retrocesso, vamos rejeitar em plenario.       contra 
#> 5 d5     Defendo a proposta que corrige distorcoes historicas do sistem… favor  
#> 6 d6     Somos contra, o texto beneficia apenas grandes corporacoes.     contra
```

## 2 · Termos mais frequentes por grupo

``` r

freq_por_grupo <- ac_count(corpus, by = "posicao")
ac_top_terms(freq_por_grupo, n = 5, by = "posicao")
#> # A tibble: 50 × 3
#>    posicao token            n
#>    <chr>   <chr>        <int>
#>  1 contra  o                2
#>  2 contra  Esta             1
#>  3 contra  Somos            1
#>  4 contra  Voto             1
#>  5 contra  a                1
#>  6 contra  apenas           1
#>  7 contra  beneficia        1
#>  8 contra  contra           1
#>  9 contra  contra,          1
#> 10 contra  corporacoes.     1
#> # ℹ 40 more rows
```

## 3 · Palavras distintivas de cada lado (*keyness*)

``` r

key <- ac_keyness(freq_por_grupo, group = "posicao", target = "favor")
head(key, 5)
#> # A tibble: 5 × 10
#>   token group target reference n_target n_reference total_target total_reference
#>   <chr> <chr> <chr>  <chr>        <dbl>       <dbl>        <dbl>           <dbl>
#> 1 que   posi… favor  contra           2           0           27              27
#> 2 a     posi… favor  contra           3           1           27              27
#> 3 Apoio posi… favor  contra           1           0           27              27
#> 4 Defe… posi… favor  contra           1           0           27              27
#> 5 Sou   posi… favor  contra           1           0           27              27
#> # ℹ 2 more variables: keyness <dbl>, direction <chr>
```

## 4 · Sentimento por documento (OpLexicon PT-BR)

``` r

ac_sentiment(corpus)
#> # A tibble: 6 × 6
#>   doc_id n_pos n_neg n_neu score sentiment
#>   <chr>  <int> <int> <int> <int> <chr>    
#> 1 d1         0     1     8    -1 negativo 
#> 2 d2         1     0     9     1 positivo 
#> 3 d3         1     0     8     1 positivo 
#> 4 d4         0     0     9     0 neutro   
#> 5 d5         0     0     9     0 neutro   
#> 6 d6         0     0     8     0 neutro
```

## 5 · Escolher um modelo LLM para a próxima etapa

Se você **for** usar a etapa qualitativa, o pacote sugere modelos com
base em custo, idioma e tipo de tarefa. Consulta 100% offline (banco
interno).

``` r

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

## O que vem depois?

- **[Comece
  aqui](https://andersonheri.github.io/acR/articles/introducao-acR.md)**
  — visão geral com codificação humana e IRR.
- **[Codificação com
  LLMs](https://andersonheri.github.io/acR/articles/qualitativo-llm.md)**
  — codebook, `ellmer`, *self-consistency*.
- **[LDA](https://andersonheri.github.io/acR/articles/lda.md)** —
  modelagem de tópicos.
- **[Sentimento](https://andersonheri.github.io/acR/articles/sentimento.md)**
  — pipeline completo com OpLexicon.

Cada uma das funções acima tem exemplos executáveis em
`?nome_da_funcao`.
