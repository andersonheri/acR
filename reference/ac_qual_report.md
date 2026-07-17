# Gerar relatorio de replicabilidade da analise qualitativa

`ac_qual_report()` gera um documento estruturado, pronto para artigo ou
relatorio, com todas as decisoes metodologicas da rodada de codificacao
qualitativa: codebook completo, historico de modificacoes, configuracao
da LLM, distribuicao de resultados, metricas de confiabilidade e
referencias bibliograficas.

Suporta saida em Markdown (`.md`) ou HTML autocontido (`.html`), em
portugues ou ingles.

## Usage

``` r
ac_qual_report(
  coded,
  codebook,
  reliability = NULL,
  chat = NULL,
  title = NULL,
  author = NULL,
  method = NULL,
  format = c("md", "html"),
  path = NULL,
  lang = c("pt", "en")
)
```

## Arguments

- coded:

  Tibble com resultado de
  [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md).

- codebook:

  Objeto `ac_codebook` usado na classificacao.

- reliability:

  Opcional. Saida de
  [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md);
  se fornecido, adiciona secao de confiabilidade inter-codificador.

- chat:

  Opcional. Objeto `Chat` do `ellmer` (ou string de modelo); se
  fornecido, extrai provedor/modelo/parametros para o relatorio.

- title:

  Titulo do relatorio. Padrao: gerado a partir do nome do codebook.

- author:

  Autor(es) do estudo (opcional).

- method:

  Descricao livre do metodo de coleta do corpus (opcional).

- format:

  Formato de saida: `"md"` (padrao) ou `"html"`.

- path:

  Caminho do arquivo destino. Se `NULL`, usa
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html).

- lang:

  Idioma: `"pt"` (padrao) ou `"en"`.

## Value

Invisivel: caminho do arquivo gerado.

## Examples

``` r
# Simular resultado de ac_qual_code para o exemplo
cb <- ac_qual_codebook(
  name         = "polaridade",
  instructions = "Classifique a polaridade do texto.",
  categories   = list(
    favor  = list(definition = "Apoio a proposta."),
    contra = list(definition = "Oposicao a proposta.")
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

coded <- tibble::tibble(
  doc_id           = paste0("d", 1:5),
  categoria        = c("favor", "contra", "favor", "contra", "favor"),
  confidence_score = c(1.00, 0.67, 1.00, 1.00, 0.67),
  reasoning        = rep("...", 5)
)

# Gerar relatorio em markdown temporario
arquivo <- tempfile(fileext = ".md")
ac_qual_report(coded, cb, path = arquivo, author = "Fulano de Tal")
#> ✔ Relatorio salvo em /tmp/RtmpHMr2ol/file1b81c9a8731.md
# readLines(arquivo, n = 20)
```
