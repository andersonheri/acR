# Calcular legibilidade textual (Índice de Flesch adaptado ao português)

`ac_readability()` estima a legibilidade (facilidade de leitura) dos
documentos de um `ac_corpus`, usando o Índice de Legibilidade de Flesch
adaptado ao português por Martins et al. (1996) a partir da fórmula
original de Flesch (1948).

É uma ferramenta de diagnóstico, não de julgamento de qualidade: um
texto "difícil" pelo índice pode ser exatamente o esperado — uma decisão
judicial, um artigo técnico, uma bula de remédio. O uso típico é
**comparativo**: saber se o manual de instruções do produto A é mais
acessível que o do produto B, se a imprensa simplificou a linguagem de
comunicados oficiais ao longo do tempo, ou se avaliações de um produto
em um site de e-commerce variam em complexidade por categoria.

A fórmula depende da contagem de sílabas por palavra, que a função
estima contando grupos de vogais (heurística comum em legibilidade
automática, já que não há dicionário de sílabas open-source completo
para português). Isso introduz algum erro em palavras com hiatos,
ditongos ou dígrafos vocálicos, mas a estimativa costuma ficar próxima
da contagem manual para fins comparativos.

## Usage

``` r
ac_readability(corpus, by = NULL)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- by:

  Coluna(s) de agrupamento para agregar a legibilidade além do documento
  (ex.: `"categoria"`, `"fonte"`, `"ano"`). Padrão: `NULL` (uma linha
  por documento).

## Value

Tibble com colunas:

- `doc_id` (ou as colunas de `by`, se informado);

- `n_palavras`, `n_frases`, `n_silabas`: contagens usadas na fórmula;

- `flesch`: Índice de Legibilidade de Flesch adaptado ao português
  (0-100; valores mais altos = texto mais fácil de ler);

- `nivel`: interpretação categórica do índice (ver `@details`).

## Details

A fórmula (Martins et al., 1996) é: \$\$ILF = 248{,}835 - 1{,}015 \times
\frac{palavras}{frases} - 84{,}6 \times \frac{sílabas}{palavras}\$\$

Faixas de interpretação (adaptadas da literatura educacional brasileira
que usa o ILF):

- `>= 75`: muito fácil (ensino fundamental inicial);

- `50-74,9`: fácil a médio (ensino fundamental/médio);

- `25-49,9`: difícil (ensino superior);

- `< 25`: muito difícil (especializado/técnico).

## References

Flesch, R. (1948). A New Readability Yardstick. *Journal of Applied
Psychology*, 32(3), 221-233.

Martins, T. B. F., Ghiraldelo, C. M., Nunes, M. G. V., Oliveira Jr., O.
N. (1996). Readability formulas applied to textbooks in Brazilian
Portuguese. *ICMSC Technical Report*, 28.

## See also

[`ac_lexical_diversity()`](https://andersonheri.github.io/acR/dev/reference/ac_lexical_diversity.md)

## Examples

``` r
# Avaliacoes de produtos em um e-commerce, com nivel de complexidade variado
df <- data.frame(
  id = paste0("r", 1:4),
  texto = c(
    "Bom. Gostei. Chegou rapido.",
    paste(
      "A ergonomia do dispositivo privilegia uma distribuicao",
      "assimetrica de peso, o que compromete substancialmente a",
      "usabilidade prolongada em cenarios de utilizacao intensiva."
    ),
    "Facil de usar e bonito.",
    "O manual e confuso e a instalacao exige conhecimento tecnico avancado."
  ),
  categoria = c("eletronico", "eletronico", "casa", "eletronico"),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)

ac_readability(corpus)
#> # A tibble: 4 × 6
#>   doc_id n_palavras n_frases n_silabas flesch nivel        
#>   <chr>       <int>    <int>     <dbl>  <dbl> <chr>        
#> 1 r1              4        3         8   78.3 muito facil  
#> 2 r2             22        1        65  -23.4 muito dificil
#> 3 r3              5        1         9   91.5 muito facil  
#> 4 r4             11        1        28   22.3 muito dificil

# Comparando legibilidade media por categoria de produto
ac_readability(corpus, by = "categoria")
#> # A tibble: 2 × 6
#>   categoria  n_palavras n_frases n_silabas flesch nivel        
#>   <chr>           <int>    <int>     <dbl>  <dbl> <chr>        
#> 1 casa                5        1         9   91.5 muito facil  
#> 2 eletronico         37        5       101   10.4 muito dificil
```
