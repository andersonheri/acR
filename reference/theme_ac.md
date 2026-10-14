# Tema visual consistente do acR

`theme_ac()` retorna um tema `ggplot2` minimalista e consistente, usado
por todos os `ac_plot_*()` do pacote. Deriva de
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
com ajustes editoriais: tipografia mais compacta, gridlines suaves,
títulos em negrito com espaçamento negativo (visual editorial).

Também expõe
[`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md)
para uma paleta categórica coerente com o tema (compatível com
acessibilidade AA).

## Usage

``` r
theme_ac(base_size = 12, base_family = "")
```

## Arguments

- base_size:

  Tamanho base da fonte. Padrão: `12`.

- base_family:

  Família tipográfica. Padrão: `""` (usa sistema).

## Value

Um objeto
[`ggplot2::theme`](https://ggplot2.tidyverse.org/reference/theme.html).

## See also

[`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md)

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
    ggplot2::geom_point(color = ac_palette()[1]) +
    ggplot2::labs(title = "MPG vs. peso", subtitle = "Tema editorial acR") +
    theme_ac()
}

```
