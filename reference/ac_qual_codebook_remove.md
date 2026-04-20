# Remover categoria de um codebook existente

`ac_qual_codebook_remove()` remove uma ou mais categorias de um
`ac_codebook` existente.

## Usage

``` r
ac_qual_codebook_remove(codebook, categories)
```

## Arguments

- codebook:

  Objeto `ac_codebook`.

- categories:

  Vetor `character` com os nomes das categorias a remover.

## Value

Objeto `ac_codebook` atualizado.

## See also

[`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md),
[`ac_qual_codebook_add()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_add.md)

## Examples

``` r
cb <- ac_qual_codebook(
  name         = "tom",
  instructions = "Classifique o tom.",
  categories   = list(
    positivo = list(definition = "Tom propositivo."),
    negativo = list(definition = "Tom critico."),
    neutro   = list(definition = "Tom neutro.")
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
#> ! Categoria "neutro": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "neutro": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
cb <- ac_qual_codebook_remove(cb, "neutro")
#> ✔ 1 categoria removida: "neutro".
#> ℹ Codebook agora tem 2 categorias.
names(cb$categories)
#> [1] "positivo" "negativo"
```
