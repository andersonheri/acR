# Adicionar categoria a um codebook existente

`ac_qual_codebook_add()` adiciona uma ou mais categorias a um
`ac_codebook` já criado, sem precisar recriar o objeto do zero. Útil
para refinamento iterativo do codebook durante a análise.

## Usage

``` r
ac_qual_codebook_add(codebook, ...)
```

## Arguments

- codebook:

  Objeto `ac_codebook`.

- ...:

  Categorias a adicionar, nomeadas. Cada elemento deve ser uma lista com
  `definition` e, opcionalmente, `examples_pos`, `examples_neg`,
  `weight` e `references`.

## Value

Objeto `ac_codebook` atualizado.

## See also

[`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md),
[`ac_qual_codebook_remove()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_remove.md)

## Examples

``` r
cb <- ac_qual_codebook(
  name         = "tom",
  instructions = "Classifique o tom.",
  categories   = list(
    positivo = list(definition = "Tom propositivo."),
    negativo = list(definition = "Tom critico.")
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

cb <- ac_qual_codebook_add(cb,
  neutro = list(
    definition   = "Tom neutro, sem posicionamento claro.",
    examples_pos = c("O projeto foi apresentado na sessao de hoje.")
  )
)
#> ! Categoria "neutro": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
#> ✔ 1 categoria adicionada: "neutro".
#> ℹ Codebook agora tem 3 categorias.
names(cb$categories)
#> [1] "positivo" "negativo" "neutro"  
```
