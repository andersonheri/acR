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
frequência relativa delas no próprio documento virgem: só palavras que
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

  Tipo de reescalonamento aplicado aos escores brutos, para corrigir a
  compressão em torno da média que o método produz (palavras comuns a
  todos os textos puxam todo escore para o centro da escala):

  - `"none"` (padrão): sem reescalonamento, escore bruto.

  - `"lbg"`: transformação de Laver, Benoit & Garry (2003, p. 316),
    \\S^\*\_v = (S_v - \bar{S}\_v)(DP_r / DP_v) + \bar{S}\_v\\, em que
    \\\bar{S}\_v\\ e \\DP_v\\ são a média e o desvio-padrão dos escores
    brutos dos **documentos virgens** e \\DP_r\\ o desvio-padrão dos
    escores **conhecidos** das referências. Dá aos virgens a mesma
    dispersão das referências, mantendo a média deles. Exige pelo menos
    2 virgens e depende de quais virgens entram: com poucos, fica
    instável (com exatamente 2, eles caem sempre a cerca de 0,71
    desvio-padrão da média, seja qual for o texto).

  - `"mv"`: transformação de Martin & Vanberg (2008), \\S^\*\_v = (S_v -
    P_1)/(P_2 - P_1) \cdot (A_2 - A_1) + A_1\\, em que \\A_1\\ e \\A_2\\
    são os escores conhecidos das referências extremas (menor e maior) e
    \\P_1\\, \\P_2\\ os escores brutos que o método atribui a essas
    mesmas referências. Não depende do conjunto de virgens: é a opção
    mais robusta quando há poucos documentos a estimar.

  A mesma transformação é aplicada também às referências (como se fossem
  virgens), o que serve de checagem: uma referência bem recuperada fica
  perto do seu escore conhecido.

- drop_punct:

  Lógico, encaminhado para
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

Martin, L. W.; Vanberg, G. (2008). A Robust Transformation Procedure for
Interpreting Political Text. *Political Analysis*, 16(1), 93-100.

## See also

[`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md),
[`ac_ca()`](https://ahenriquecp.com/acR/reference/ac_ca.md)

## Examples

``` r
# Avaliações de produto com nota conhecida (referência) e sem nota
# (a estimar), usadas como escala continua de satisfacao
df <- data.frame(
  id = paste0("r", 1:6),
  texto = c(
    "produto excelente, superou expectativas, recomendo muito",
    "muito bom, chegou rápido e funciona perfeitamente",
    "produto regular, cumpre o básico",
    "não funcionou bem, qualidade ruim, não recomendo",
    "péssimo, quebrado e com defeito, decepcao total",
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
