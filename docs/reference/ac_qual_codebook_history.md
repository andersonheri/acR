# Exibir histórico de modificações de um codebook

`ac_qual_codebook_history()` retorna e imprime o histórico de ações
registradas em um `ac_codebook` (adições, remoções, merges, traduções
etc.).

## Usage

``` r
ac_qual_codebook_history(codebook, n = Inf)
```

## Arguments

- codebook:

  Objeto `ac_codebook`.

- n:

  Número máximo de entradas a exibir. Padrão: `Inf` (todas).

## Value

Tibble com colunas `timestamp`, `action` e `detail` (invisível).
