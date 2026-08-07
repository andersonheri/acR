# Gerar relatório consolidado de múltiplas variáveis de conteúdo

`ac_qual_report_full()` gera **um único** documento (Markdown ou HTML)
consolidando resultados de N variáveis de codificação qualitativa — cada
uma com seu próprio codebook, rodada de
[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
e, opcionalmente, métricas de
[`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md)
ou
[`ac_qual_irr()`](https://ahenriquecp.com/acR/reference/ac_qual_irr.md).

É a resposta natural ao caso de uso mais comum de análise de conteúdo
categorial (Krippendorff, 2018): um estudo tem várias variáveis de
conteúdo (tom, posicionamento, tema, framing…). Antes desta função, o
pesquisador precisava chamar
[`ac_qual_report()`](https://ahenriquecp.com/acR/reference/ac_qual_report.md)
N vezes e emendar os relatórios manualmente, ou escrever um consolidador
ad hoc por projeto.

Aceita variáveis `multilabel = TRUE` e `multilabel = FALSE` no mesmo
relatório — cada seção herda a apresentação apropriada para o tipo.

## Usage

``` r
ac_qual_report_full(
  variables,
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

- variables:

  Lista **nomeada** onde cada elemento é uma lista com:

  - `coded`: tibble com resultado de
    [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
    (obrigatório).

  - `codebook`: objeto `ac_codebook` (obrigatório).

  - `reliability`: opcional, saída de
    [`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md)
    ou
    [`ac_qual_irr()`](https://ahenriquecp.com/acR/reference/ac_qual_irr.md).
    Os nomes da lista viram os títulos das seções do relatório.

- chat:

  Opcional. Objeto `Chat` do `ellmer` ou string de modelo
  `"provider/model"`. Aplica-se a todas as variáveis (assumindo que
  todas foram classificadas com o mesmo modelo — se não, deixe `NULL`).

- title:

  Título do relatório consolidado. Padrão:
  `"Relatório consolidado de análise de conteúdo"`.

- author:

  Autor(es) do estudo.

- method:

  Descrição do método de coleta do corpus.

- format:

  `"md"` (padrão) ou `"html"`.

- path:

  Caminho do arquivo destino. Se `NULL`, usa
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html).

- lang:

  `"pt"` (padrão) ou `"en"`.

## Value

Invisível: caminho do arquivo gerado.

## See also

[`ac_qual_report()`](https://ahenriquecp.com/acR/reference/ac_qual_report.md)
para relatório de uma única variável.

## Examples

``` r
# Duas variaveis de conteudo, cada uma com seu codebook
cb_tom <- ac_qual_codebook(
  name = "tom",
  instructions = "Classifique o tom.",
  categories = list(
    pos = list(definition = "Positivo.", label = "Positivo"),
    neg = list(definition = "Negativo.", label = "Negativo")
  )
)
#> ! Categoria "pos": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "pos": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
#> ! Categoria "neg": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "neg": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
cb_pos <- ac_qual_codebook(
  name = "posicao",
  instructions = "Classifique a posicao.",
  categories = list(
    favor  = list(definition = "A favor.",  label = "A favor"),
    contra = list(definition = "Contra.",   label = "Contra")
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

coded_tom <- tibble::tibble(
  doc_id = paste0("d", 1:3),
  categoria = c("pos", "neg", "pos"),
  confidence_score = c(1, 0.67, 1)
)
coded_pos <- tibble::tibble(
  doc_id = paste0("d", 1:3),
  categoria = c("favor", "contra", "favor"),
  confidence_score = c(1, 1, 0.67)
)

arquivo <- tempfile(fileext = ".md")
ac_qual_report_full(
  variables = list(
    "Tom do discurso" = list(coded = coded_tom, codebook = cb_tom),
    "Posicao politica" = list(coded = coded_pos, codebook = cb_pos)
  ),
  path = arquivo,
  author = "Fulano de Tal"
)
#> ✔ Relatorio salvo em
#>   /var/folders/wr/lsgxp5bj5vd2jgq9ybg24ng00000gn/T//RtmpxhhqVY/file1c3164647cdc.md
```
