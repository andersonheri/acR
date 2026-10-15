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

A entrada são dois data.frames (anotador 1 e anotador 2), cada um com
uma coluna de identificador e uma de categoria, alinhados pelo
identificador.

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
  verbose = TRUE,
  bootstrap = 1000L
)
```

## Arguments

- gold:

  `data.frame`. Anotacoes de referência (anotador humano ou gold
  standard). Deve conter colunas `id_discurso` (ou `id`) e `categoria`.

- predicted:

  `data.frame`. Anotacoes a comparar (ex.: saida do LLM via
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)).
  Mesmas colunas exigidas.

- method:

  `character`. Métrica(s) a calcular. Opcoes: `"all"` (padrao),
  `"cohen_kappa"`, `"fleiss_kappa"`, `"krippendorff"`,
  `"percent_agreement"`. Aceita vetor de múltiplas opcoes.

- id_col:

  `character`. Nome da coluna de identificador nos data.frames. Padrao:
  `"id_discurso"`.

- cat_col:

  `character`. Nome da coluna de categoria nos data.frames. Padrao:
  `"categoria"`.

- weight:

  `character`. Tipo de ponderação para Cohen's Kappa: `"unweighted"`
  (padrão), `"linear"` ou `"squared"` (Cohen, 1968). Os pesos só fazem
  sentido para categorias **ordinais**: a ordem usada é a dos níveis do
  fator em `gold[[cat_col]]` (se for fator) ou a ordem alfabética (caso
  contrário). Para categorias nominais, use `"unweighted"`.

- conf_level:

  `numeric`. Nivel de confianca para intervalos (0-1). Padrao: `0.95`.

- verbose:

  `logical`. Se `TRUE` (padrao), imprime resumo formatado.

- bootstrap:

  `integer`. Número de réplicas *bootstrap* (reamostragem de documentos)
  para os intervalos de confiança de Kappa, Fleiss e Alpha. Padrão:
  `1000`. Use `0` para não calcular IC.

## Value

Um objeto de classe `ac_irr` (lista) com os elementos:

- `metrics`:

  `data.frame` com colunas `metric`, `estimate`, `ci_lower`, `ci_upper`,
  `interpretation`.

- `confusion`:

  `table`. Matriz de confusao entre os anotadores.

- `n_docs`:

  `integer`. Número de documentos comparados.

- `n_annotators`:

  `integer`. Número de anotadores.

- `categories`:

  `character`. Categorias encontradas.

- `method`:

  `character`. Métrica(s) calculadas.

## Details

### Interpretação do Kappa (Landis & Koch, 1977)

|             |                |
|-------------|----------------|
| Kappa       | Concordância   |
| \< 0.00     | Pobre          |
| 0.00 - 0.20 | Leve           |
| 0.21 - 0.40 | Razoável       |
| 0.41 - 0.60 | Moderada       |
| 0.61 - 0.80 | Substancial    |
| 0.81 - 1.00 | Quase perfeita |

Os próprios autores chamam essas faixas de arbitrárias (Landis & Koch,
1977, p. 165): são rótulos de referência, não testes.

### Fleiss' Kappa

Generalização do kappa para vários anotadores (Fleiss, 1971). Com dois
anotadores, como aqui, ela supõe uma distribuição marginal comum aos
dois e por isso equivale ao *pi* de Scott, não ao kappa de Cohen; os
valores ficam próximos, mas não idênticos.

### Krippendorff's Alpha

Métrica mais geral: funciona com qualquer número de anotadores e lida
com dados faltantes (Krippendorff, 2018). Esta função calcula a versão
**nominal**. A interpretação segue Krippendorff (2018, sec. 12.4), não
Landis & Koch: alfa `>= 0,800` confiável; `0,667-0,800` só para
conclusões provisórias; `< 0,667` insuficiente.

### Percentual de concordância

Não corrige por acaso. Rótulos segundo Neuendorf (2017): `>= 0,90` alta;
`>= 0,80` aceitável na maioria dos casos; `>= 0,70` só em estudos
exploratórios; abaixo disso, insuficiente.

### Intervalos de confiança

Calculados por *bootstrap* percentil, reamostrando documentos com
reposição (Efron & Tibshirani, 1993). Uma versão anterior usava
`kappa / z` como erro-padrão, mas o `z` do `irr` é calculado **sob a
hipótese nula** (kappa = 0); esse erro-padrão não serve para IC em torno
do kappa estimado (Fleiss, Cohen & Everitt, 1969) e gerava limites fora
de \[-1, 1\].

## References

KRIPPENDORFF, K. **Content Analysis: An Introduction to Its
Methodology**. 4. ed. Thousand Oaks: SAGE, 2018.

LANDIS, J. R.; KOCH, G. G. The measurement of observer agreement for
categorical data. **Biometrics**, v. 33, n. 1, p. 159-174, 1977.

COHEN, J. Weighted kappa: nominal scale agreement with provision for
scaled disagreement or partial credit. **Psychological Bulletin**, v.
70, n. 4, p. 213-220, 1968.

EFRON, B.; TIBSHIRANI, R. J. **An Introduction to the Bootstrap**. New
York: Chapman & Hall, 1993.

FLEISS, J. L. Measuring nominal scale agreement among many raters.
**Psychological Bulletin**, v. 76, n. 5, p. 378-382, 1971.

FLEISS, J. L.; COHEN, J.; EVERITT, B. S. Large sample standard errors of
kappa and weighted kappa. **Psychological Bulletin**, v. 72, n. 5, p.
323-327, 1969.

NEUENDORF, K. A. **The Content Analysis Guidebook**. 2. ed. Thousand
Oaks: SAGE, 2017.

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
#> Metrica                            Estimativa  IC                Interpretacao
#> ------------------------------------------------------------------------------------- 
#> Percent Agreement                  0.800       --                aceitável na maioria dos casos (>= 80%; Neuendorf, 2017)
#> Cohen's Kappa (unweighted)         0.667       [0.000, 1.000]    substancial (Landis & Koch, 1977)
#> Fleiss' Kappa                      0.655       [-0.250, 1.000]   substancial (Landis & Koch, 1977)
#> Krippendorff's Alpha (nominal)     0.690       [-0.125, 1.000]   só conclusões provisórias (>= 0,667; Krippendorff, 2018)
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
#> Metrica                            Estimativa  IC                Interpretacao
#> ------------------------------------------------------------------------------------- 
#> Percent Agreement                  0.800       --                aceitável na maioria dos casos (>= 80%; Neuendorf, 2017)
#> Cohen's Kappa (unweighted)         0.667       [0.000, 1.000]    substancial (Landis & Koch, 1977)
#> Fleiss' Kappa                      0.655       [-0.250, 1.000]   substancial (Landis & Koch, 1977)
#> Krippendorff's Alpha (nominal)     0.690       [-0.125, 1.000]   só conclusões provisórias (>= 0,667; Krippendorff, 2018)
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
#> Metrica                            Estimativa  IC                Interpretacao
#> ------------------------------------------------------------------------------------- 
#> Cohen's Kappa (unweighted)         0.667       [0.000, 1.000]    substancial (Landis & Koch, 1977)
#> 
#> Matriz de confusao:
#>               Predicted
#> Gold           conservador progressista
#>   conservador            2            0
#>   progressista           0            2
#>   tecnocratico           0            1
# }
```
