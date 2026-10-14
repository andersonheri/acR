# Busca discursos de deputados federais via API da Camara dos Deputados

Coleta discursos parlamentares diretamente da API publica da Camara dos
Deputados (v2), retornando um `data.frame` padronizado e pronto para uso
nas funcoes do `acR`. A coleta e feita em duas etapas: (1) lista
deputados conforme os filtros informados; (2) para cada deputado, busca
os discursos no periodo solicitado, com paginacao automatica.

## Usage

``` r
ac_fetch_camara(
  data_inicio,
  data_fim,
  legislatura = NULL,
  partido = NULL,
  uf = NULL,
  n_max = 100,
  tipo_discurso = "plenario",
  verbose = TRUE,
  sleep = 0.5
)
```

## Arguments

- data_inicio:

  `character`. Data de inicio no formato `"YYYY-MM-DD"`.

- data_fim:

  `character`. Data de fim no formato `"YYYY-MM-DD"`.

- legislatura:

  `integer` ou `NULL`. Numero da legislatura (ex.: `57` para 2023-2027).
  Se `NULL`, usa o periodo definido por `data_inicio` e `data_fim` sem
  filtrar por legislatura.

- partido:

  `character` ou `NULL`. Sigla do partido para filtrar deputados (ex.:
  `"PT"`, `"PL"`, `"MDB"`). Aceita vetor de siglas. Se `NULL`, inclui
  todos os partidos.

- uf:

  `character` ou `NULL`. Sigla da UF para filtrar deputados (ex.:
  `"SP"`, `"MG"`). Aceita vetor de UFs. Se `NULL`, inclui todas.

- n_max:

  `integer`. Numero maximo de discursos a retornar. Padrao: `100`. Use
  `Inf` para coletar todos (atencao: pode ser lento).

- tipo_discurso:

  `character`. Tipo de evento parlamentar. Opcoes principais:
  `"plenario"` (padrao), `"comissao"`, `"todos"`.

- verbose:

  `logical`. Se `TRUE` (padrao), exibe mensagens de progresso.

- sleep:

  `numeric`. Tempo de espera (em segundos) entre chamadas a API para
  respeitar o rate limit. Padrao: `0.5`.

## Value

Um `data.frame` com as colunas:

- `id_discurso`:

  `character`. Identificador unico do discurso.

- `id_deputado`:

  `integer`. ID do deputado na API da Camara.

- `nome_deputado`:

  `character`. Nome civil do parlamentar.

- `partido`:

  `character`. Sigla do partido na data do discurso.

- `uf`:

  `character`. UF da bancada do parlamentar.

- `data`:

  `Date`. Data do discurso.

- `hora_inicio`:

  `character`. Hora de inicio (HH:MM).

- `tipo_discurso`:

  `character`. Tipo de fase do evento.

- `sumario`:

  `character`. Sumario do discurso (quando disponivel).

- `texto`:

  `character`. Texto integral do discurso (quando disponivel).

- `uri_discurso`:

  `character`. URI do recurso na API.

## Details

A API Dados Abertos da Camara (v2) nao dispoe de endpoint unico para
discursos por periodo. O fluxo de coleta e:

1.  `GET /api/v2/deputados` - lista deputados com filtros de partido/UF.

2.  `GET /api/v2/deputados/{id}/discursos` - discursos de cada deputado,
    com paginacao (max. 100 itens por pagina).

O filtro `tipo_discurso` atua sobre o campo `tipoDiscurso` retornado
pela API. Valores observados: `"DISCURSO"`, `"DISCURSO ENCAMINHADO"`,
`"BREVE COMUNICACAO"`, `"PELA ORDEM"`, `"COMUNICACAO PARLAMENTAR"`.

## References

CAMARA DOS DEPUTADOS. Dados Abertos da Camara dos Deputados - API v2.
Brasilia, 2024. Disponivel em:
<https://dadosabertos.camara.leg.br/swagger/api.html>. Acesso em: abr.
2026.

## See also

[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)
para transformar o resultado em corpus.

## Examples

``` r
if (FALSE) { # \dontrun{
# Discursos do plenario, marco de 2024
disc <- ac_fetch_camara(
  data_inicio = "2024-03-11",
  data_fim    = "2024-03-15",
  n_max       = 50
)

# Apenas PT e PL
disc_partidos <- ac_fetch_camara(
  data_inicio = "2024-01-01",
  data_fim    = "2024-03-31",
  partido     = c("PT", "PL"),
  n_max       = 100
)

# Todos os tipos de discurso
disc_todos <- ac_fetch_camara(
  data_inicio   = "2024-03-01",
  data_fim      = "2024-03-31",
  uf            = "SP",
  tipo_discurso = "todos",
  n_max         = 100
)
} # }
```
