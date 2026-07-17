# Calcular confiabilidade entre codificação LLM e humana

`ac_qual_reliability()` calcula métricas de concordância entre a
classificação feita pela LLM e uma classificação humana de referência,
com intervalos de confiança via bootstrap.

É a **última porta antes de publicar** um estudo de análise de conteúdo
assistida por LLM. Nenhuma referência metodológica atual (Krippendorff,
2018; Gwet, 2014; Gilardi et al., 2023) aceita rotulagem automática sem
um subconjunto codificado por humano e concordância documentada.

Quatro métricas são computadas por padrão, cada uma respondendo a uma
pergunta diferente:

- **Percent agreement** (`percent_agreement`): fração de documentos em
  que LLM e humano concordam. Fácil de reportar, mas ignora concordância
  por acaso — infla para categorias binárias com distribuição desigual.

- **Alpha de Krippendorff** (`krippendorff`): padrão-ouro em análise de
  conteúdo. Corrige por acaso, aceita missings, funciona com qualquer
  número de categorias. Valores \> 0,80 = quase perfeita; \> 0,67 =
  aceitável para publicação; \< 0,60 = codebook precisa ser refinado.

- **AC1 de Gwet** (`gwet_ac1`): alternativa a Krippendorff mais estável
  quando as categorias são muito desbalanceadas (o "paradoxo do kappa" —
  kappa despenca com alta concordância se uma categoria domina).

- **F1 macro** (`f1_macro`): média não ponderada dos F1 por categoria.
  Útil quando você quer garantir que a LLM está indo bem também nas
  categorias raras, não só nas frequentes.

Intervalos de confiança de 95% vêm de *bootstrap* não paramétrico
(padrão: 1000 réplicas). Reporte pelo menos Krippendorff e F1 macro no
artigo, com os ICs; discuta divergências humano × LLM em amostra de
casos representativos.

## Usage

``` r
ac_qual_reliability(
  llm,
  human,
  cat_col = "categoria",
  metrics = c("krippendorff", "gwet_ac1", "f1_macro", "percent_agreement"),
  bootstrap = 1000L,
  ci_level = 0.95,
  ...
)
```

## Arguments

- llm:

  Tibble com classificação LLM, saída de
  [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md).

- human:

  Tibble com classificação humana, saída de
  [`ac_qual_import_human()`](https://andersonheri.github.io/acR/reference/ac_qual_import_human.md).

- cat_col:

  Nome da coluna de categoria. Padrão: `"categoria"`.

- metrics:

  Vetor de métricas a calcular. Padrão:
  `c("krippendorff", "gwet_ac1", "f1_macro", "percent_agreement")`.

- bootstrap:

  Número de amostras bootstrap para IC. Padrão: `1000`.

- ci_level:

  Nível de confiança do IC. Padrão: `0.95`.

- ...:

  Ignorado.

## Value

Tibble com colunas: `metric`, `estimate`, `ci_lower`, `ci_upper`,
`interpretation`.

## References

Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
Methodology* (4th ed.). SAGE.

Gwet, K. L. (2014). *Handbook of Inter-Rater Reliability* (4th ed.).
Advanced Analytics.

Landis, J. R.; Koch, G. G. (1977). The Measurement of Observer Agreement
for Categorical Data. *Biometrics*, 33(1), 159-174.

## Examples

``` r
# Simular saidas: LLM (coded) e revisao humana (humano_df)
# ambos com as colunas doc_id + categoria
coded <- tibble::tibble(
  doc_id    = paste0("d", 1:5),
  categoria = c("favor", "contra", "favor", "contra", "favor")
)
humano_df <- tibble::tibble(
  doc_id    = paste0("d", 1:5),
  categoria = c("favor", "contra", "contra", "contra", "favor")
)

# Calcular metricas de confiabilidade (bootstrap curto so para demonstrar;
# em uso real, deixe o padrao de 1000 replicas)
rel <- ac_qual_reliability(
  llm       = coded,
  human     = humano_df,
  bootstrap = 50
)
#> Calculando confiabilidade em 5 documentos comuns...
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> Warning: NAs introduced by coercion
#> ℹ Interpretação baseada em Landis & Koch (1977) e Gwet (2014).
#> ℹ IC 95% via bootstrap (n = 50).
print(rel)
#> # A tibble: 4 × 5
#>   metric             estimate ci_lower ci_upper interpretation                  
#>   <chr>                 <dbl>    <dbl>    <dbl> <chr>                           
#> 1 percent_agreement      0.8    0.6           1 boa (>= 80%)                    
#> 2 krippendorff_alpha     0.64   0.0563        1 substancial (Landis & Koch, 197…
#> 3 gwet_ac1               0.6   -0.163         1 moderada (Landis & Koch, 1977)  
#> 4 f1_macro               0.8    0.306         1 quase perfeita (Landis & Koch, …
```
