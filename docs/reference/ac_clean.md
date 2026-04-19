# Limpar e normalizar texto de um corpus

`ac_clean()` aplica um conjunto configurável de transformações ao texto
de um objeto `ac_corpus`, retornando um novo corpus com o texto
modificado. As transformações são aplicadas em ordem lógica e
registradas como atributo para auditoria.

## Usage

``` r
ac_clean(
  corpus,
  lower = TRUE,
  remove_punct = TRUE,
  remove_numbers = FALSE,
  remove_url = TRUE,
  remove_email = TRUE,
  remove_symbols = FALSE,
  remove_hashtags = FALSE,
  remove_mentions = FALSE,
  remove_stopwords = NULL,
  remove_accents = FALSE,
  normalize_pt = FALSE,
  protect = NULL,
  extra_stopwords = NULL,
  min_char = NULL,
  custom_replacements = NULL,
  handle_na = c("preserve", "empty", "remove"),
  strip_whitespace = TRUE,
  verbose = FALSE,
  ...
)
```

## Arguments

- corpus:

  Objeto de classe `ac_corpus`, criado por
  [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md).

- lower:

  Se `TRUE` (padrão), converte texto para minúsculas.

- remove_punct:

  Se `TRUE` (padrão), remove pontuação.

- remove_numbers:

  Se `TRUE`, remove dígitos. Padrão: `FALSE`.

- remove_url:

  Se `TRUE` (padrão), remove URLs (http, https, www).

- remove_email:

  Se `TRUE` (padrão), remove endereços de e-mail.

- remove_symbols:

  Se `TRUE`, remove símbolos e emojis (@, \#, \\, etc.). Padrão:
  `FALSE`. Cuidado: hashtags e menções podem ser informativas.

- remove_hashtags:

  Se `TRUE`, remove hashtags (#termo). Padrão: `FALSE`.

- remove_mentions:

  Se `TRUE`, remove menções (\\usuario). Padrão: `FALSE`.

- remove_stopwords:

  Pode ser:

  - `NULL` (padrão): não remove stopwords;

  - uma string com nome de preset (`"pt"`, `"pt-br-extended"`,
    `"pt-legislativo"`, `"en"`);

  - um vetor `character` com stopwords customizadas.

- remove_accents:

  Se `TRUE`, remove acentos (ex: "ação" vira "acao"). Padrão: `FALSE`.

- normalize_pt:

  Se `TRUE`, aplica normalizações ortográficas do português brasileiro
  coloquial: `"pra"` → `"para"`, `"tá"` → `"está"`, etc. Padrão:
  `FALSE`.

- protect:

  Vetor `character` com termos a preservar exatamente como estão. Útil
  para siglas (`c("PT", "PSDB", "CCJ")`). Padrão: `NULL`.

- extra_stopwords:

  Vetor `character` com stopwords adicionais a remover antes de qualquer
  análise, combinado ao preset de `remove_stopwords`. Use
  [`ac_clean_stopwords()`](https://andersonheri.github.io/acR/reference/ac_clean_stopwords.md)
  para inspecionar e editar o objeto padrão. Padrão: `NULL`.

- min_char:

  Inteiro. Descarta tokens com menos de `min_char` caracteres após a
  limpeza. Padrão: `NULL` (sem filtro).

- custom_replacements:

  Lista nomeada de substituições livres aplicadas antes das demais
  transformações. Ex:
  `list("pres\\." = "presidente", "dep\\." = "deputado")`. Padrão:
  `NULL`.

- handle_na:

  Como tratar valores `NA` no texto:

  - `"preserve"` (padrão): mantém `NA` como `NA`;

  - `"empty"`: converte `NA` para `""`;

  - `"remove"`: remove documentos com `NA` do corpus.

- strip_whitespace:

  Se `TRUE` (padrão), colapsa espaços consecutivos.

- verbose:

  Se `TRUE`, exibe resumo das operações e estatísticas de remoção por
  etapa. Padrão: `FALSE`.

- ...:

  Ignorado com aviso se houver argumentos não reconhecidos.

## Value

Um novo objeto `ac_corpus` com a coluna `text` transformada e o atributo
`cleaning_steps` registrando as operações aplicadas em ordem. Quando
`verbose = TRUE`, também imprime um resumo com tokens removidos por
etapa e documentos que ficaram vazios após limpeza.

## Details

**Ordem de aplicação** das transformações:

1.  `handle_na`: tratamento de NAs

2.  `custom_replacements`: substituições livres

3.  `protect`: proteção de termos com placeholders

4.  `remove_url` e `remove_email`

5.  `remove_hashtags` e `remove_mentions`

6.  `remove_symbols`

7.  `lower`

8.  `remove_accents`

9.  `normalize_pt`

10. `remove_numbers`

11. `remove_punct`

12. `remove_stopwords` + `extra_stopwords`

13. `min_char`: remoção de tokens curtos

14. Restauração dos termos protegidos

15. `strip_whitespace` (sempre)

## See also

[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md),
[`ac_clean_stopwords()`](https://andersonheri.github.io/acR/reference/ac_clean_stopwords.md)

## Examples

``` r
df <- data.frame(
  id = c("a", "b", "c"),
  texto = c(
    "O deputado do PT disse: 'Defendo a CCJ!' Veja em https://exemplo.org",
    "Sra. presidente, o Sr. senador apresentou o requerimento n\u00ba 123.",
    "T\u00e1 na hora de votar, pra acabar com isso."
  )
)
corpus <- ac_corpus(df, text = texto, docid = id)

# Limpeza básica
ac_clean(corpus)
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 3
#> • Metadados: 0 colunas
#> • Idioma: "pt"
#> 
#> # A tibble: 3 × 2
#>   doc_id text                                                        
#>   <chr>  <chr>                                                       
#> 1 a      o deputado do pt disse defendo a ccj veja em                
#> 2 b      sra presidente o sr senador apresentou o requerimento nº 123
#> 3 c      tá na hora de votar pra acabar com isso                     

# Limpeza completa com todas as opções
ac_clean(
  corpus,
  remove_stopwords  = "pt-legislativo",
  extra_stopwords   = c("isso", "aquilo", "coisa"),
  protect           = c("PT", "CCJ"),
  normalize_pt      = TRUE,
  custom_replacements = list("pres\\." = "presidente"),
  min_char          = 3L,
  verbose           = TRUE
)
#> ✔ Limpeza concluída.
#> ℹ Tokens antes: 30 | após: 10 (20 removidos).
#> ℹ Documentos vazios após limpeza: 0.
#> ℹ Etapas aplicadas: "custom_replacements(1)", "protect(2 termos)",
#>   "remove_url", "remove_email", "lower", "normalize_pt", "remove_punct",
#>   "remove_stopwords(preset=pt-legislativo)", "extra_stopwords(3)",
#>   "min_char(3)", and "strip_whitespace".
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 3
#> • Metadados: 0 colunas
#> • Idioma: "pt"
#> 
#> # A tibble: 3 × 2
#>   doc_id text                     
#>   <chr>  <chr>                    
#> 1 a      PT disse defendo CCJ veja
#> 2 b      apresentou 123           
#> 3 c      hora votar acabar        
```
