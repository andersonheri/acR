# Fundir dois codebooks em um

`ac_qual_codebook_merge()` combina as categorias de dois objetos
`ac_codebook` em um único codebook, com controle de conflitos de nomes.

## Usage

``` r
ac_qual_codebook_merge(
  cb1,
  cb2,
  name = NULL,
  on_conflict = c("error", "keep_first", "keep_second", "rename_second"),
  instructions = NULL
)
```

## Arguments

- cb1:

  Objeto `ac_codebook` (base).

- cb2:

  Objeto `ac_codebook` (a fundir).

- name:

  Nome do codebook resultante. Padrão: `"cb1_cb2"`.

- on_conflict:

  Estratégia em caso de categorias com o mesmo nome: `"error"` (padrão),
  `"keep_first"`, `"keep_second"` ou `"rename_second"`.

- instructions:

  Instrução geral do novo codebook. Se `NULL`, usa a de `cb1`.

## Value

Objeto `ac_codebook` fundido.

## Examples

``` r
# Dois codebooks pequenos que cobrem dimensoes distintas
cb_tom <- ac_qual_codebook(
  name         = "tom",
  instructions = "Classifique o tom.",
  categories   = list(
    positivo = list(definition = "Tom positivo."),
    negativo = list(definition = "Tom negativo.")
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
cb_estilo <- ac_qual_codebook(
  name         = "estilo",
  instructions = "Classifique o estilo retorico.",
  categories   = list(
    pathos = list(definition = "Apelo emocional."),
    logos  = list(definition = "Apelo racional.")
  )
)
#> ! Categoria "pathos": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "pathos": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
#> ! Categoria "logos": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "logos": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.

# Fundir em um unico codebook com 4 categorias
cb <- ac_qual_codebook_merge(cb_tom, cb_estilo, name = "tom_estilo")
#> ✔ Fundidos: 4 categorias.
names(cb$categories)  # "positivo" "negativo" "pathos" "logos"
#> [1] "positivo" "negativo" "pathos"   "logos"   
```
