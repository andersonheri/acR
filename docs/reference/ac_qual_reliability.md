# Calcular confiabilidade entre codificação LLM e humana

`ac_qual_reliability()` calcula métricas de concordância entre a
classificação feita pela LLM e uma classificação humana de referência,
com intervalos de confiança via bootstrap.

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
if (FALSE) { # \dontrun{
rel <- ac_qual_reliability(llm = coded, human = humano_df)
print(rel)
} # }
```
