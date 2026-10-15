# Carregar codebook de arquivo YAML

Le um arquivo YAML gerado por
[`ac_qual_save_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_save_codebook.md)
e reconstroi o objeto `ac_codebook` na sessão atual. Uso típico: retomar
uma análise iniciada em outra sessão ou por outro pesquisador.

## Usage

``` r
ac_qual_load_codebook(path, ...)
```

## Arguments

- path:

  Caminho do arquivo `.yaml`.

- ...:

  Ignorado.

## Value

Objeto `ac_codebook`.

## Examples

``` r
# Preparar um codebook e salvar em arquivo temporário
cb <- ac_qual_codebook(
  name         = "polaridade",
  instructions = "Classifique a polaridade do texto.",
  categories   = list(
    favor   = list(definition = "Apoia a proposta."),
    contra  = list(definition = "Opoe-se a proposta.")
  )
)
#> ! Categoria "favor": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "favor": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
#> ! Categoria "contra": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "contra": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
arquivo <- tempfile(fileext = ".yaml")
ac_qual_save_codebook(cb, path = arquivo)
#> ✅ Codebook salvo em /tmp/RtmpqRXVQC/file1b3960a6c728.yaml

# Recarregar em outra sessão
cb_novo <- ac_qual_load_codebook(arquivo)
names(cb_novo$categories)  # "favor" "contra"
#> [1] "favor"  "contra"
```
