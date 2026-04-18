# Amostrar documentos para validação humana

`ac_qual_sample()` seleciona uma amostra de documentos classificados
pela LLM para validação por um codificador humano, usando diferentes
estratégias para maximizar a eficiência da validação.

## Usage

``` r
ac_qual_sample(
  coded,
  n = 50L,
  strategy = c("uncertainty", "stratified", "random", "disagreement"),
  seed = 42L,
  ...
)
```

## Arguments

- coded:

  Tibble com classificação LLM, saída de
  [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md).

- n:

  Número de documentos a amostrar. Padrão: `50`.

- strategy:

  Estratégia de amostragem:

  - `"uncertainty"`: prioriza documentos com menor `confidence_score`
    (maior incerteza da LLM);

  - `"stratified"`: garante representação proporcional de todas as
    categorias;

  - `"random"`: amostra aleatória simples;

  - `"disagreement"`: prioriza documentos onde rodadas de
    self-consistency divergiram (requer `confidence_score < 1`).

- seed:

  Semente para reprodutibilidade. Padrão: `42`.

- ...:

  Ignorado.

## Value

Tibble com os documentos selecionados, incluindo uma coluna
`sample_reason` indicando por que cada documento foi selecionado.
