# Limpar e normalizar texto de um corpus

`ac_clean()` aplica um conjunto configurável de transformações ao texto
de um objeto `ac_corpus`, retornando um novo corpus com o texto
modificado. As transformações são aplicadas em ordem lógica (URLs e
emails antes de pontuação, etc.) e registradas como atributo para
auditoria.

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
  remove_stopwords = NULL,
  remove_accents = FALSE,
  normalize_pt = FALSE,
  protect = NULL,
  strip_whitespace = TRUE,
  ...
)
```

## Arguments

- corpus:

  Objeto de classe `ac_corpus`, tipicamente criado por
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

- remove_stopwords:

  Pode ser:

  - `NULL` (padrão): não remove stopwords;

  - uma string com nome de preset (`"pt"`, `"pt-br-extended"`,
    `"pt-legislativo"`);

  - um vetor `character` com stopwords customizadas.

- remove_accents:

  Se `TRUE`, remove acentos (ex: "ação" vira "acao"). Padrão: `FALSE`.
  Útil para certas análises quantitativas, mas descaracteriza o texto
  para análise qualitativa.

- normalize_pt:

  Se `TRUE`, aplica normalizações ortográficas do português brasileiro
  coloquial: `"pra"` → `"para"`, `"pro"` → `"para o"`, `"tá"` →
  `"está"`, etc. Padrão: `FALSE`.

- protect:

  Vetor `character` com termos a preservar exatamente como estão (ignora
  `lower`, `remove_punct`, `remove_stopwords` para esses termos). Útil
  para siglas políticas (`c("PT", "PSDB", "CCJ")`). Padrão: `NULL`.

- strip_whitespace:

  Se `TRUE` (padrão e sempre aplicado ao final), colapsa espaços
  consecutivos e remove espaços no início/fim.

- ...:

  Ignorado com aviso se houver argumentos não reconhecidos.

## Value

Um novo objeto `ac_corpus` com a coluna `text` transformada e o atributo
`cleaning_steps` registrando as operações aplicadas em ordem.

## Details

**Ordem de aplicação** das transformações:

1.  Proteção de termos (`protect`): substitui termos por placeholders

2.  Remoção de URLs e emails

3.  Remoção de símbolos (se ativado)

4.  `lower` (minúsculas)

5.  `remove_accents`

6.  `normalize_pt`

7.  `remove_numbers`

8.  `remove_punct`

9.  `remove_stopwords`

10. Restauração dos termos protegidos

11. `strip_whitespace` (sempre)

**Sobre stopwords**: a remoção é feita por *palavras inteiras*
(delimitadas por fronteiras), não por substring. Isso evita que remover
`"em"` corte `"embora"`.

**Sobre termos protegidos**: durante a limpeza, termos em `protect` são
substituídos por placeholders internos inacessíveis às demais
transformações e restaurados ao final com case original.

## See also

[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)
para construir o corpus de entrada.

## Examples

``` r
df <- data.frame(
  id = c("a", "b", "c"),
  texto = c(
    "O deputado do PT disse: 'Defendo a CCJ!' Veja em https://exemplo.org",
    "Sra. presidente, o Sr. senador apresentou o requerimento n\u00ba 123.",
    "Tá na hora de votar, pra acabar com isso."
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

# Limpeza agressiva com stopwords legislativas e proteção de siglas
ac_clean(
  corpus,
  remove_stopwords = "pt-legislativo",
  protect = c("PT", "CCJ"),
  normalize_pt = TRUE
)
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
#> 2 b      apresentou nº 123        
#> 3 c      hora votar acabar        
```
