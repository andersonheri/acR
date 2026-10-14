# Escalonamento ideológico de documentos pelo método Wordscores

`ac_wordscores()` posiciona documentos num espectro contínuo (ex.:
esquerda-direita, pró/contra uma reforma) a partir só do vocabulário que
usam, pelo algoritmo Wordscores de Laver, Benoit & Garry (2003). É um
método supervisionado: parte de um pequeno conjunto de documentos de
referência com posição conhecida (ex.: manifestos de partidos com
posição já estimada por especialistas, ou avaliações de produto com nota
conhecida) e estima a posição de todos os outros documentos ("documentos
virgens") comparando seu vocabulário ao vocabulário dos documentos de
referência.

A lógica: cada palavra recebe um "escore de palavra", a média ponderada
das posições dos documentos de referência em que ela aparece (ponderada
pela frequência relativa da palavra em cada referência). Um documento
virgem recebe a média dos escores de suas palavras, ponderada pela
frequência relativa delas no próprio documento virgem — só palavras que
também aparecem nos documentos de referência contam.

Fora da ciência política (onde o método nasceu, aplicado a manifestos
partidários), a mesma lógica serve para qualquer escala contínua
latente: por exemplo, estimar o quão favorável um conjunto de avaliações
de produto é a partir de um pequeno conjunto de avaliações com nota de
estrelas conhecida, ou posicionar transcrições de atendimento num
espectro de satisfação do cliente.

## Usage

``` r
ac_wordscores(
  corpus,
  scores,
  rescale = c("none", "lbg", "mv"),
  drop_punct = TRUE
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- scores:

  Vetor numérico nomeado (nomes = `doc_id`) ou tibble com colunas
  `doc_id` e `score`, com a posição conhecida dos documentos de
  referência. Documentos de `corpus` ausentes de `scores` (ou com
  `score = NA`) são tratados como documentos virgens, a serem estimados.

- rescale:

  Tipo de reescalonamento aplicado aos escores brutos dos documentos
  virgens, para corrigir a compressão em torno da média que o método
  tende a produzir (Laver, Benoit & Garry, 2003; Martin & Vanberg,
  2007):

  - `"none"` (padrão): sem reescalonamento, escore bruto.

  - `"lbg"`: reescalona pela razão de desvios-padrão entre os escores de
    referência conhecidos e os escores brutos estimados para os próprios
    documentos de referência.

  - `"mv"`: reescalona linearmente para o intervalo `[min, max]` dos
    escores de referência conhecidos (Martin & Vanberg, 2007).

- drop_punct:

  Logico, encaminhado para
  [`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md).
  Padrão: `TRUE`.

## Value

Tibble com colunas `doc_id`, `score` (escore estimado, já reescalonado
conforme `rescale`), `score_raw` (escore bruto, antes do
reescalonamento) e `is_reference` (`TRUE` para os documentos usados como
referência).

## References

Laver, M.; Benoit, K.; Garry, J. (2003). Extracting Policy Positions
from Political Texts Using Words as Data. *American Political Science
Review*, 97(2), 311-331.

Martin, L. W.; Vanberg, G. (2007). A Robust Transformation Procedure for
Interpreting Political Text. *Political Analysis*, 16(1), 93-100.

## See also

[`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md),
[`ac_ca()`](https://ahenriquecp.com/acR/reference/ac_ca.md)

## Examples

``` r
# Avaliacoes de produto com nota conhecida (referencia) e sem nota
# (a estimar), usadas como escala continua de satisfacao
df <- data.frame(
  id = paste0("r", 1:6),
  texto = c(
    "produto excelente, superou expectativas, recomendo muito",
    "muito bom, chegou rapido e funciona perfeitamente",
    "produto regular, cumpre o basico",
    "nao funcionou bem, qualidade ruim, nao recomendo",
    "pessimo, quebrado e com defeito, decepcao total",
    "produto ok, nada de especial mas atende"
  ),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)

# r1, r2, r4, r5 com nota conhecida (1-5); r3 e r6 sao "virgens"
notas <- c(r1 = 5, r2 = 4, r4 = 2, r5 = 1)

ac_wordscores(corpus, notas)
#> # A tibble: 6 × 4
#>   doc_id score score_raw is_reference
#>   <chr>  <dbl>     <dbl> <lgl>       
#> 1 r1      4.69      4.69 TRUE        
#> 2 r2      3.86      3.86 TRUE        
#> 3 r3      5         5    FALSE       
#> 4 r4      2.23      2.23 TRUE        
#> 5 r5      1.21      1.21 TRUE        
#> 6 r6      5         5    FALSE       
```
