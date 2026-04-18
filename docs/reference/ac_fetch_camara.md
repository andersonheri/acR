# Busca discursos de deputados federais via API da C^amara dos Deputados

Coleta discursos parlamentares diretamente da API p'ublica da C^amara
dos Deputados (v2), retornando um `data.frame` padronizado e pronto para
uso nas func~oes do `acR`. A coleta e feita em duas etapas: (1) lista
deputados conforme os filtros informados; (2) para cada deputado, busca
os discursos no periodo solicitado, com paginacao autom'atica.

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

  `character`. Data de in'icio no formato `"YYYY-MM-DD"`.

- data_fim:

  `character`. Data de fim no formato `"YYYY-MM-DD"`.

- legislatura:

  `integer` ou `NULL`. N'umero da legislatura (ex.: `57` para
  2023-2027). Se `NULL`, usa o periodo definido por `data_inicio` e
  `data_fim` sem filtrar por legislatura.

- partido:

  `character` ou `NULL`. Sigla do partido para filtrar deputados (ex.:
  `"PT"`, `"PL"`, `"MDB"`). Aceita vetor de sigllas. Se `NULL`, inclui
  todos os partidos.

- uf:

  `character` ou `NULL`. Sigla da UF para filtrar deputados (ex.:
  `"SP"`, `"MG"`). Aceita vetor de UFs. Se `NULL`, inclui todas.

- n_max:

  `integer`. N'umero m'aximo de discursos a retornar. Padr~ao: `100`.
  Use `Inf` para coletar todos (atenc~ao: pode ser lento).

- tipo_discurso:

  `character`. Tipo de evento parlamentar. Opc~oes principais:
  `"plenario"` (padrao), `"comissao"`, `"todos"`.

- verbose:

  `logical`. Se `TRUE` (padrao), exibe mensagens de progresso.

- sleep:

  `numeric`. Tempo de espera (em segundos) entre chamadas
  `a API para respeitar o rate limit. Padr~ao: `0.5\`.

## Value

Um `data.frame` com as colunas:

- `id_discurso`:

  `character`. Identificador unico do discurso.

- `id_deputado`:

  `integer`. ID do deputado na API da C^amara.

- `nome_deputado`:

  `character`. Nome civil do parlamentar.

- `partido`:

  `character`. Sigla do partido na data do discurso.

- `uf`:

  `character`. UF da bancada do parlamentar.

- `data`:

  `Date`. Data do discurso.

- `hora_inicio`:

  `character`. Hora de in'icio (HH:MM).

- `tipo_discurso`:

  `character`. Tipo de fase do evento.

- `sumario`:

  `character`. Sum'ario do discurso (quando dispon'ivel).

- `texto`:

  `character`. Texto integral do discurso (quando dispon'ivel).

- `uri_discurso`:

  `character`. URI do recurso na API.

## Details

### Estrutura da API

A API Dados Abertos da C^amara (v2) n~ao disp~oe de endpoint unico para
discursos por periodo. O fluxo de coleta e:

1.  `GET /api/v2/deputados` - lista deputados com filtros de partido/UF.

2.  `GET /api/v2/deputados/{id}/discursos` - discursos de cada deputado,
    com paginacao (m'ax. 100 itens por p'agina).

### Rate limiting

A API n~ao publica limites formais, mas respostas com HTTP 429 s~ao
tratadas com *backoff* exponencial (ate 3 tentativas). O par^ametro
`sleep` define a pausa m'inima entre requisicoes.

### Texto integral

Nem todos os discursos t^em texto integral dispon'ivel. Quando ausente,
a coluna `texto` recebe `NA`. Nesses casos, apenas o `sumario` e
retornado.

## References

C^AMARA DOS DEPUTADOS. **Dados Abertos da C^amara dos Deputados - API
v2**. Bras'ilia, 2024. Dispon'ivel em:
<https://dadosabertos.camara.leg.br/swagger/api.html>. Acesso em: abr.
2026.

## See also

[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)
para transformar o resultado em corpus.

## Examples

``` r
if (FALSE) { # \dontrun{
# Discursos do plen'ario, primeiro semestre de 2024
disc <- ac_fetch_camara(
  data_inicio = "2024-01-01",
  data_fim    = "2024-06-30",
  n_max       = 50
)

# Apenas PT e PL, legislatura 57
disc_partidos <- ac_fetch_camara(
  data_inicio  = "2024-01-01",
  data_fim     = "2024-12-31",
  legislatura  = 57,
  partido      = c("PT", "PL"),
  n_max        = 200
)

# Deputados de SP, todos os tipos de discurso
disc_sp <- ac_fetch_camara(
  data_inicio   = "2024-03-01",
  data_fim      = "2024-03-31",
  uf            = "SP",
  tipo_discurso = "todos",
  n_max         = 100
)
} # }
```
