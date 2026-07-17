# Salvar codebook em arquivo YAML

Serializa um objeto `ac_codebook` em disco no formato YAML, preservando
instrucoes, categorias, exemplos, referencias e historico de
modificacoes. YAML foi escolhido por ser legivel por humanos e
versionavel em Git.

## Usage

``` r
ac_qual_save_codebook(codebook, path = NULL, ...)
```

## Arguments

- codebook:

  Objeto `ac_codebook`.

- path:

  Caminho do arquivo `.yaml`. Se `NULL`, deriva do nome do codebook.

- ...:

  Ignorado.

## Value

Invisivel: caminho do arquivo gerado.

## Examples

``` r
# Criar um codebook simples
cb <- ac_qual_codebook(
  name         = "tom_discurso",
  instructions = "Classifique o tom do discurso.",
  categories   = list(
    positivo = list(definition = "Tom propositivo e colaborativo."),
    negativo = list(definition = "Tom critico e confrontacional.")
  )
)
#> ! Categoria "positivo": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "positivo": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
#> ! Categoria "negativo": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "negativo": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.

# Salvar em arquivo temporario (usar caminho real fora de exemplos)
arquivo <- tempfile(fileext = ".yaml")
ac_qual_save_codebook(cb, path = arquivo)
#> ✅ Codebook salvo em /tmp/Rtmp2FtUFO/file1b6641800aa6.yaml

# Reabrir para conferir
cb_recarregado <- ac_qual_load_codebook(arquivo)
identical(cb$categories, cb_recarregado$categories)
#> [1] FALSE
```
