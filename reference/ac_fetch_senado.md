# Busca discursos de senadores federais via senatebR

Coleta discursos parlamentares do Senado Federal usando o pacote
senatebR como backend, retornando um `data.frame` no mesmo formato
padronizado de
[`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md).
Isso permite combinar corpora das duas casas legislativas sem atrito.

O periodo pode ser especificado por legislatura (atalho conveniente) ou
por datas exatas (controle fino). Se ambos forem fornecidos, as datas
prevalecem.

## Usage

``` r
ac_fetch_senado(
  data_inicio = NULL,
  data_fim = NULL,
  legislatura_inicio = NULL,
  legislatura_fim = NULL,
  partido = NULL,
  uf = NULL,
  nome_senador = NULL,
  n_max = 100,
  verbose = TRUE,
  sleep = 0.3
)
```

## Arguments

- data_inicio:

  `character` ou `NULL`. Data de inicio no formato `"YYYY-MM-DD"`. Se
  `NULL`, usa o inicio da `legislatura_inicio`.

- data_fim:

  `character` ou `NULL`. Data de fim no formato `"YYYY-MM-DD"`. Se
  `NULL`, usa o fim da `legislatura_fim`.

- legislatura_inicio:

  `integer` ou `NULL`. Numero da legislatura de inicio (ex.: `56` para
  2019-2023, `57` para 2023-2027). Ignorado se `data_inicio` for
  fornecido.

- legislatura_fim:

  `integer` ou `NULL`. Numero da legislatura de fim. Se `NULL`, usa o
  mesmo valor de `legislatura_inicio`.

- partido:

  `character` ou `NULL`. Sigla(s) do partido para filtrar senadores
  (ex.: `"PT"`, `c("PT", "PL")`). Filtragem pos-coleta. Se `NULL`,
  inclui todos os partidos.

- uf:

  `character` ou `NULL`. Sigla(s) da UF para filtrar senadores (ex.:
  `"SP"`, `c("SP", "MG")`). Filtragem pos-coleta. Se `NULL`, inclui
  todas as UFs.

- nome_senador:

  `character` ou `NULL`. Padrao de texto para filtrar pelo nome do
  senador (busca parcial, case-insensitive). Ex.: `"Lula"`, `"Pacheco"`.
  Se `NULL`, inclui todos.

- n_max:

  `integer`. Numero maximo de discursos a retornar. Padrao: `100`. Use
  `Inf` para coletar todos.

- verbose:

  `logical`. Se `TRUE` (padrao), exibe mensagens de progresso.

- sleep:

  `numeric`. Pausa em segundos entre requisicoes. Padrao: `0.3`.

## Value

Um `data.frame` com as mesmas colunas de
[`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md):

- `id_discurso`:

  `character`. Identificador unico.

- `id_deputado`:

  `character`. Codigo do senador na API.

- `nome_deputado`:

  `character`. Nome do senador.

- `partido`:

  `character`. Sigla do partido.

- `uf`:

  `character`. UF da representacao.

- `data`:

  `Date`. Data do discurso.

- `hora_inicio`:

  `character`. Hora de inicio (HH:MM).

- `tipo_discurso`:

  `character`. Tipo/fase do discurso.

- `sumario`:

  `character`. Resumo do discurso.

- `texto`:

  `character`. Texto integral (quando disponivel).

- `uri_discurso`:

  `character`. URL do recurso.

- `casa`:

  `character`. Sempre `"senado"`.

## Details

### Legislaturas do Senado Federal

|             |           |
|-------------|-----------|
| Legislatura | Periodo   |
| 55          | 2015-2019 |
| 56          | 2019-2023 |
| 57          | 2023-2027 |

### Compatibilidade com ac_fetch_camara()

O `data.frame` retornado tem as mesmas colunas de
[`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md),
com a adicao da coluna `casa` (`"senado"`). Isso permite combinar os
dois corpora com [`rbind()`](https://rdrr.io/r/base/cbind.html) ou
[`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html).

### Backend

Esta funcao usa senatebR (Santos, 2026) como backend para acesso a API
do Senado Federal. O senatebR deve estar instalado:
`install.packages("senatebR")`.

## References

SANTOS, V. **senatebR**: Collect Data from the Brazilian Federal Senate
Open Data API. CRAN, 2026. Disponivel em:
<https://github.com/vsntos/senatebR>.

## See also

[`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md),
[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Por legislatura
disc_sen <- ac_fetch_senado(
  legislatura_inicio = 57,
  n_max = 50
)

# Por datas + filtro de partido
disc_pt <- ac_fetch_senado(
  data_inicio = "2024-01-01",
  data_fim    = "2024-06-30",
  partido     = c("PT", "PL"),
  n_max       = 100
)

# Combinar Camara + Senado
disc_camara <- ac_fetch_camara(
  data_inicio = "2024-03-01",
  data_fim    = "2024-03-31",
  n_max       = 50
)
disc_senado <- ac_fetch_senado(
  data_inicio = "2024-03-01",
  data_fim    = "2024-03-31",
  n_max       = 50
)
corpus_bicameral <- dplyr::bind_rows(disc_camara, disc_senado)
} # }
```
