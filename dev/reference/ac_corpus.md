# Construir um corpus para análise de conteúdo

`ac_corpus()` é a porta de entrada do pipeline do pacote `acR`. Constrói
um objeto estruturado de corpus a partir de um `data.frame`, um vetor de
caracteres, ou um corpus do `quanteda`, validando a entrada e
preservando metadados associados aos documentos.

## Usage

``` r
ac_corpus(data, text = NULL, docid = NULL, meta = NULL, lang = "pt", ...)
```

## Arguments

- data:

  Entrada do corpus. Pode ser:

  - um `data.frame` ou `tibble` com pelo menos uma coluna de texto;

  - um vetor `character` com textos (um documento por elemento);

  - um objeto `corpus` do pacote `quanteda`.

- text:

  Nome da coluna de texto, sem aspas (usa *tidyselect* / *non-standard
  evaluation*). Apenas relevante quando `data` é um `data.frame`. Se
  `NULL` (padrão), a função tenta detectar automaticamente uma coluna
  chamada `text`, `texto`, `doc`, `content` ou `conteudo`.

- docid:

  Nome da coluna de identificador único, sem aspas. Se `NULL` (padrão),
  gera IDs sequenciais no formato `doc_1`, `doc_2`, ...

- meta:

  Colunas de metadados a preservar, via *tidyselect* (ex:
  `c(partido, data, regiao)` ou `tidyselect::starts_with("var_")`). Se
  `NULL`, preserva todas as demais colunas do `data.frame`.

- lang:

  Código ISO do idioma do corpus (padrão: `"pt"`). Utilizado em etapas
  posteriores (lematização, stopwords, léxicos).

- ...:

  Argumentos reservados para extensão futura. No momento, são ignorados
  com aviso se nomeados de forma desconhecida.

## Value

Um objeto de classe `ac_corpus` (que herda de `tbl_df`, `tbl`,
`data.frame`) com as colunas:

- `doc_id` (character): identificador único do documento.

- `text` (character): texto do documento.

- Demais colunas de metadados, preservadas de `data`. O objeto traz
  também o atributo `lang` indicando o idioma.

## Details

A função realiza cinco validações obrigatórias e falha cedo em caso de
problema:

1.  `data` deve ser de um dos tipos suportados;

2.  a coluna de texto deve existir (ou ser detectável automaticamente);

3.  a coluna de texto não pode ser inteiramente `NA` ou vazia;

4.  `doc_id` não pode ter valores duplicados;

5.  `doc_id` não pode conter `NA`.

Documentos com texto vazio ou `NA` geram aviso (`warning`) mas são
mantidos no corpus com texto `""` — o usuário decide se filtra depois.

## Examples

``` r
# A partir de um data.frame
df <- data.frame(
  id = c("a", "b", "c"),
  texto = c("Primeiro texto.", "Segundo texto.", "Terceiro."),
  partido = c("PT", "PL", "MDB")
)
corpus <- ac_corpus(df, text = texto, docid = id, meta = partido)
corpus
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 3
#> • Metadados: 1 coluna
#> • Idioma: "pt"
#> 
#> # A tibble: 3 × 3
#>   doc_id text            partido
#>   <chr>  <chr>           <chr>  
#> 1 a      Primeiro texto. PT     
#> 2 b      Segundo texto.  PL     
#> 3 c      Terceiro.       MDB    

# A partir de um vetor character (doc_id gerado automaticamente)
ac_corpus(c("Texto um.", "Texto dois."))
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 2
#> • Metadados: 0 colunas
#> • Idioma: "pt"
#> 
#> # A tibble: 2 × 2
#>   doc_id text       
#>   <chr>  <chr>      
#> 1 doc_1  Texto um.  
#> 2 doc_2  Texto dois.

# Detecção automática da coluna de texto
df2 <- data.frame(text = c("A", "B"), autor = c("X", "Y"))
ac_corpus(df2)
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 2
#> • Metadados: 1 coluna
#> • Idioma: "pt"
#> 
#> # A tibble: 2 × 3
#>   doc_id text  autor
#>   <chr>  <chr> <chr>
#> 1 doc_1  A     X    
#> 2 doc_2  B     Y    
```
