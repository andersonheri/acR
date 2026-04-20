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
