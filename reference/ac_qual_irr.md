# Calcular métricas de confiabilidade inter-anotador

Compara as classificações de dois ou mais anotadores (humanos ou LLMs) e
retorna métricas padronizadas de concordância. Suporta Cohen's Kappa
(dois anotadores), Fleiss' Kappa (multi-anotador), Krippendorff's Alpha
e percentual de concordância simples.

Complementa
[`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md):
aquela compara **um par** LLM × humano com bootstrap; esta é o motor
genérico para **qualquer par ou painel** de anotadores. Use-a
diretamente quando você tem duas rodadas humanas para calibrar entre
codificadores antes de acender a LLM, ou quando quer comparar LLMs entre
si sobre a mesma amostra.

A função aceita dois formatos de entrada: (a) dois data.frames com
colunas `id` e `categoria`, representando anotador 1 e anotador 2; ou
(b) um único data.frame em formato largo com uma coluna por anotador.

## Usage

``` r
ac_qual_irr(
  gold,
  predicted,
  method = "all",
  id_col = "id_discurso",
  cat_col = "categoria",
  weight = "unweighted",
  conf_level = 0.95,
  verbose = TRUE
)
```

## Arguments

- gold:

  `data.frame`. Anotacoes de referencia (anotador humano ou gold
  standard). Deve conter colunas `id_discurso` (ou `id`) e `categoria`.

- predicted:

  `data.frame`. Anotacoes a comparar (ex.: saida do LLM via
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)).
  Mesmas colunas exigidas.

- method:

  `character`. Metrica(s) a calcular. Opcoes: `"all"` (padrao),
  `"cohen_kappa"`, `"fleiss_kappa"`, `"krippendorff"`,
  `"percent_agreement"`. Aceita vetor de multiplas opcoes.

- id_col:

  `character`. Nome da coluna de identificador nos data.frames. Padrao:
  `"id_discurso"`.

- cat_col:

  `character`. Nome da coluna de categoria nos data.frames. Padrao:
  `"categoria"`.

- weight:

  `character`. Tipo de ponderacao para Cohen's Kappa: `"unweighted"`
  (padrao), `"linear"`, `"squared"`. Ignorado para categorias nominais
  sem ordem natural.

- conf_level:

  `numeric`. Nivel de confianca para intervalos (0-1). Padrao: `0.95`.

- verbose:

  `logical`. Se `TRUE` (padrao), imprime resumo formatado.

## Value

Um objeto de classe `ac_irr` (lista) com os elementos:

- `metrics`:

  `data.frame` com colunas `metric`, `estimate`, `ci_lower`, `ci_upper`,
  `interpretation`.

- `confusion`:

  `table`. Matriz de confusao entre os anotadores.

- `n_docs`:

  `integer`. Numero de documentos comparados.

- `n_annotators`:

  `integer`. Numero de anotadores.

- `categories`:

  `character`. Categorias encontradas.

- `method`:

  `character`. Metrica(s) calculadas.

## Details

### Interpretacao do Kappa (Landis & Koch, 1977)

|             |                |
|-------------|----------------|
| Kappa       | Concordancia   |
| \< 0.00     | Pobre          |
| 0.00 - 0.20 | Leve           |
| 0.21 - 0.40 | Razoavel       |
| 0.41 - 0.60 | Moderada       |
| 0.61 - 0.80 | Substancial    |
| 0.81 - 1.00 | Quase perfeita |

### Fleiss' Kappa

Extensao do Kappa de Cohen para mais de dois anotadores. Requer que
`predicted` contenha uma coluna por anotador adicional, ou que sejam
passados como lista via `...`.

### Krippendorff's Alpha

Metrica mais geral: funciona com qualquer numero de anotadores, lida com
dados faltantes e suporta escalas nominais, ordinais e de intervalo
(KRIPPENDORFF, 2018).

## References

KRIPPENDORFF, K. **Content Analysis: An Introduction to Its
Methodology**. 4. ed. Thousand Oaks: SAGE, 2018.

LANDIS, J. R.; KOCH, G. G. The measurement of observer agreement for
categorical data. **Biometrics**, v. 33, n. 1, p. 159-174, 1977.

## See also

[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md),
[`ac_qual_sample()`](https://ahenriquecp.com/acR/reference/ac_qual_sample.md)

## Examples

``` r
# \donttest{
# Comparar LLM vs. anotador humano
humano <- data.frame(
  id_discurso = c("d1", "d2", "d3", "d4", "d5"),
  categoria   = c("progressista", "conservador", "tecnocratico",
                  "progressista", "conservador")
)

llm <- data.frame(
  id_discurso = c("d1", "d2", "d3", "d4", "d5"),
  categoria   = c("progressista", "conservador", "progressista",
                  "progressista", "conservador")
)

resultado <- ac_qual_irr(gold = humano, predicted = llm)
#> 
#> ── Confiabilidade inter-anotador (acR) ──
#> 
#> • Documentos comparados: 5
#> • Categorias: conservador, progressista, tecnocratico
#> 
#> Metrica                            Estimativa  IC 95%            Interpretacao
#> ------------------------------------------------------------------------------------- 
#> Percent Agreement                  0.800       [, ]              Muito bom
#> Cohen's Kappa (unweighted)         0.667       [0.027, 1.307]    Substancial
#> Fleiss' Kappa                      0.655       [-0.048, 1.358]   Substancial
#> Krippendorff's Alpha (nominal)     0.690       [, ]              Substancial
#> 
#> Matriz de confusao:
#>               Predicted
#> Gold           conservador progressista
#>   conservador            2            0
#>   progressista           0            2
#>   tecnocratico           0            1
print(resultado)
#> 
#> ── Confiabilidade inter-anotador (acR) ──
#> 
#> • Documentos comparados: 5
#> • Categorias: conservador, progressista, tecnocratico
#> 
#> Metrica                            Estimativa  IC 95%            Interpretacao
#> ------------------------------------------------------------------------------------- 
#> Percent Agreement                  0.800       [, ]              Muito bom
#> Cohen's Kappa (unweighted)         0.667       [0.027, 1.307]    Substancial
#> Fleiss' Kappa                      0.655       [-0.048, 1.358]   Substancial
#> Krippendorff's Alpha (nominal)     0.690       [, ]              Substancial
#> 
#> Matriz de confusao:
#>               Predicted
#> Gold           conservador progressista
#>   conservador            2            0
#>   progressista           0            2
#>   tecnocratico           0            1

# So Cohen's Kappa
ac_qual_irr(humano, llm, method = "cohen_kappa")
#> 
#> ── Confiabilidade inter-anotador (acR) ──
#> 
#> • Documentos comparados: 5
#> • Categorias: conservador, progressista, tecnocratico
#> 
#> Metrica                            Estimativa  IC 95%            Interpretacao
#> ------------------------------------------------------------------------------------- 
#> Cohen's Kappa (unweighted)         0.667       [0.027, 1.307]    Substancial
#> 
#> Matriz de confusao:
#>               Predicted
#> Gold           conservador progressista
#>   conservador            2            0
#>   progressista           0            2
#>   tecnocratico           0            1
# }
```
