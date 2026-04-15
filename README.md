
<!-- README.md is generated from README.Rmd. Please edit that file -->

# acR <a href="https://andersonheri.github.io/acR/"><img src="man/figures/logo.png" align="right" height="120" alt="acR website" /></a>

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/andersonheri/acR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/andersonheri/acR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/andersonheri/acR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/andersonheri/acR?branch=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

> **Análise de Conteúdo em R**: pipeline integrado qualitativo (LLMs) e quantitativo, com visualizações modernas e foco em corpora brasileiros.

## Visão geral

O `acR` oferece um pipeline integrado para análise de conteúdo, combinando:

- **Análise qualitativa assistida por LLMs**: codificação automatizada com codebooks versionados, métricas de confiabilidade entre codificador humano e LLM (Krippendorff α, Gwet AC1), calibração de incerteza e auditoria reproducível.
- **Análise quantitativa clássica**: estatísticas descritivas, *keyness*, co-ocorrência, nuvens de palavras (incluindo comparativa e *X-ray*), análise de sentimento (OpLexicon), e *Latent Dirichlet Allocation* (LDA).
- **Visualizações modernas**: tema próprio em `ggplot2`, paletas acessíveis, gráficos publicáveis.
- **Foco em PT-BR**: stopwords expandidas, codebooks validados para o contexto político-institucional brasileiro, integração com `geobr`.

## Instalação

A versão em desenvolvimento pode ser instalada diretamente do GitHub:

``` r
# install.packages("pak")
pak::pak("andersonheri/acR")
```

## Exemplo mínimo

> O pacote está em fase inicial de desenvolvimento. Funções abaixo são ilustrativas da API planejada.

``` r
library(acR)

# Construir corpus a partir de um data.frame
corpus <- ac_corpus(
  data = discursos_camara,
  text = texto,
  docid = id_discurso
)

# Pipeline quantitativo
corpus |>
  ac_clean(remove_stopwords = "pt-br-extended") |>
  ac_quant_keyness(target = partido == "PT", reference = partido == "PL") |>
  ac_plot_keyness(n = 20)

# Pipeline qualitativo (LLM)
cb <- ac_qual_codebook("iliberalismo_br")
coded <- ac_qual_code(corpus, codebook = cb, model = "anthropic/claude-sonnet-4-5")
```

## Documentação

- Site do pacote: [andersonheri.github.io/acR](https://andersonheri.github.io/acR/)
- Vignettes (em desenvolvimento)
- Decisões arquiteturais: [`inst/docs/adr/`](inst/docs/adr/)

## Citação

Se você usa o `acR` em pesquisa, por favor cite:

``` r
citation("acR")
```

## Inspiração e diálogo

O `acR` reconhece dívida intelectual com:

- [`quallmer`](https://quallmer.github.io/quallmer/) (Maerz & Benoit, 2025) — pelo design do workflow de codificação assistida por LLMs.
- [`quanteda`](https://quanteda.io/) (Benoit et al.) — pela infraestrutura de análise textual quantitativa.
- [`ellmer`](https://ellmer.tidyverse.org/) (Wickham et al., Posit) — pelo backend unificado de LLMs.
- OpLexicon (Souza & Vieira, 2012; PUCRS) — léxico de sentimento para PT-BR.

## Como contribuir

Contribuições são bem-vindas. Veja [CONTRIBUTING.md](CONTRIBUTING.md) e o [Código de Conduta](CODE_OF_CONDUCT.md).

## Licença

MIT © 2026 Anderson Henrique
