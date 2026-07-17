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

## Examples

``` r
# Criar codebook e aplicar duas modificacoes
cb <- ac_qual_codebook(
  name         = "sentimento",
  instructions = "Classifique o sentimento.",
  categories   = list(
    positivo = list(definition = "Sentimento positivo."),
    negativo = list(definition = "Sentimento negativo.")
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
  neutro = list(definition = "Sem valencia clara.")
)
#> ! Categoria "neutro": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "neutro": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
#> ✔ 1 categoria adicionada: "neutro".
#> ℹ Codebook agora tem 3 categorias.
cb <- ac_qual_codebook_remove(cb, "neutro")
#> ✔ 1 categoria removida: "neutro".
#> ℹ Codebook agora tem 2 categorias.

# Ver historico completo de acoes registradas
ac_qual_codebook_history(cb)
#> 
#> ── Histórico: "sentimento" ─────────────────────────────────────────────────────
#> # A tibble: 2 × 3
#>   timestamp           action detail
#>   <chr>               <chr>  <chr> 
#> 1 2026-07-17 22:30:43 add    neutro
#> 2 2026-07-17 22:30:43 remove neutro
```
