#' Busca discursos de deputados federais via API da Camara dos Deputados
#'
#' @description
#' Coleta discursos parlamentares diretamente da API publica da Camara dos
#' Deputados (v2), retornando um `data.frame` padronizado e pronto para uso
#' nas funcoes do `acR`. A coleta e feita em duas etapas: (1) lista deputados
#' conforme os filtros informados; (2) para cada deputado, busca os discursos
#' no periodo solicitado, com paginacao automatica.
#'
#' @param data_inicio `character`. Data de inicio no formato `"YYYY-MM-DD"`.
#' @param data_fim `character`. Data de fim no formato `"YYYY-MM-DD"`.
#' @param legislatura `integer` ou `NULL`. Numero da legislatura (ex.: `57`
#'   para 2023-2027). Se `NULL`, usa o periodo definido por `data_inicio` e
#'   `data_fim` sem filtrar por legislatura.
#' @param partido `character` ou `NULL`. Sigla do partido para filtrar
#'   deputados (ex.: `"PT"`, `"PL"`, `"MDB"`). Aceita vetor de siglas.
#'   Se `NULL`, inclui todos os partidos.
#' @param uf `character` ou `NULL`. Sigla da UF para filtrar deputados
#'   (ex.: `"SP"`, `"MG"`). Aceita vetor de UFs. Se `NULL`, inclui todas.
#' @param n_max `integer`. Numero maximo de discursos a retornar.
#'   Padrao: `100`. Use `Inf` para coletar todos (atencao: pode ser lento).
#' @param tipo_discurso `character`. Tipo de evento parlamentar. Opcoes
#'   principais: `"plenario"` (padrao), `"comissao"`, `"todos"`.
#' @param verbose `logical`. Se `TRUE` (padrao), exibe mensagens de progresso.
#' @param sleep `numeric`. Tempo de espera (em segundos) entre chamadas a API
#'   para respeitar o rate limit. Padrao: `0.5`.
#'
#' @return Um `data.frame` com as colunas:
#'   \describe{
#'     \item{`id_discurso`}{`character`. Identificador unico do discurso.}
#'     \item{`id_deputado`}{`integer`. ID do deputado na API da Camara.}
#'     \item{`nome_deputado`}{`character`. Nome civil do parlamentar.}
#'     \item{`partido`}{`character`. Sigla do partido na data do discurso.}
#'     \item{`uf`}{`character`. UF da bancada do parlamentar.}
#'     \item{`data`}{`Date`. Data do discurso.}
#'     \item{`hora_inicio`}{`character`. Hora de inicio (HH:MM).}
#'     \item{`tipo_discurso`}{`character`. Tipo de fase do evento.}
#'     \item{`sumario`}{`character`. Sumario do discurso (quando disponivel).}
#'     \item{`texto`}{`character`. Texto integral do discurso (quando disponivel).}
#'     \item{`uri_discurso`}{`character`. URI do recurso na API.}
#'   }
#'
#' @details
#' A API Dados Abertos da Camara (v2) nao dispoe de endpoint unico para
#' discursos por periodo. O fluxo de coleta e:
#'
#' 1. `GET /api/v2/deputados` - lista deputados com filtros de partido/UF.
#' 2. `GET /api/v2/deputados/{id}/discursos` - discursos de cada deputado,
#'    com paginacao (max. 100 itens por pagina).
#'
#' O filtro `tipo_discurso` atua sobre o campo `tipoDiscurso` retornado pela
#' API. Valores observados: `"DISCURSO"`, `"DISCURSO ENCAMINHADO"`,
#' `"BREVE COMUNICACAO"`, `"PELA ORDEM"`, `"COMUNICACAO PARLAMENTAR"`.
#'
#' @examples
#' \dontrun{
#' # Discursos do plenario, marco de 2024
#' disc <- ac_fetch_camara(
#'   data_inicio = "2024-03-11",
#'   data_fim    = "2024-03-15",
#'   n_max       = 50
#' )
#'
#' # Apenas PT e PL
#' disc_partidos <- ac_fetch_camara(
#'   data_inicio = "2024-01-01",
#'   data_fim    = "2024-03-31",
#'   partido     = c("PT", "PL"),
#'   n_max       = 100
#' )
#'
#' # Todos os tipos de discurso
#' disc_todos <- ac_fetch_camara(
#'   data_inicio   = "2024-03-01",
#'   data_fim      = "2024-03-31",
#'   uf            = "SP",
#'   tipo_discurso = "todos",
#'   n_max         = 100
#' )
#' }
#'
#' @seealso [ac_corpus()] para transformar o resultado em corpus.
#'
#' @references
#' CAMARA DOS DEPUTADOS. Dados Abertos da Camara dos Deputados - API v2.
#' Brasilia, 2024. Disponivel em:
#' <https://dadosabertos.camara.leg.br/swagger/api.html>. Acesso em: abr. 2026.
#'
#' @export
ac_fetch_camara <- function(
    data_inicio,
    data_fim,
    legislatura   = NULL,
    partido       = NULL,
    uf            = NULL,
    n_max         = 100,
    tipo_discurso = "plenario",
    verbose       = TRUE,
    sleep         = 0.5
) {
  # --- 0. Verificar dependencias ----------------------------------------------
  .check_pkg("httr2",    "ac_fetch_camara")
  .check_pkg("jsonlite", "ac_fetch_camara")

  # --- 1. Validar parametros --------------------------------------------------
  .validate_date(data_inicio, "data_inicio")
  .validate_date(data_fim,    "data_fim")

  if (as.Date(data_fim) < as.Date(data_inicio)) {
    cli::cli_abort(
      "{.arg data_fim} ({data_fim}) deve ser posterior a {.arg data_inicio} ({data_inicio})."
    )
  }

  tipo_discurso <- match.arg(
    tipo_discurso,
    choices = c("plenario", "comissao", "todos")
  )

  base_url <- "https://dadosabertos.camara.leg.br/api/v2"

  # --- 2. Listar deputados ----------------------------------------------------
  if (verbose) cli::cli_progress_step("Buscando lista de deputados...")

  dep_params <- list(
    ordem      = "ASC",
    ordenarPor = "nome",
    itens      = 100
  )
  if (!is.null(legislatura)) dep_params$idLegislatura <- legislatura
  if (!is.null(uf))          dep_params$siglaUf       <- uf

  if (!is.null(partido)) {
    deputados <- do.call(rbind, lapply(partido, function(p) {
      dep_params$siglaPartido <- p
      .paginate_api(
        base_url  = base_url,
        endpoint  = "/deputados",
        params    = dep_params,
        max_items = Inf,
        sleep     = sleep,
        verbose   = FALSE
      )
    }))
    deputados <- unique(deputados)
  } else {
    deputados <- .paginate_api(
      base_url  = base_url,
      endpoint  = "/deputados",
      params    = dep_params,
      max_items = Inf,
      sleep     = sleep,
      verbose   = FALSE
    )
  }

  if (is.null(deputados) || nrow(deputados) == 0) {
    cli::cli_warn("Nenhum deputado encontrado com os filtros informados.")
    return(invisible(.empty_discursos_df()))
  }

  n_dep <- nrow(deputados)
  if (verbose) cli::cli_alert_success("{n_dep} deputado{?s} encontrado{?s}.")

  # --- 3. Para cada deputado, buscar discursos --------------------------------
  disc_params_base <- list(
    dataInicio = data_inicio,
    dataFim    = data_fim,
    ordenarPor = "dataHoraInicio",
    ordem      = "ASC",
    itens      = 100
  )

  # Filtro por tipoDiscurso (campo string plano da API)
  # Valores observados via inspecao da API em marco/2024
  cod_tipo <- switch(
    tipo_discurso,
    "plenario" = c("DISCURSO", "DISCURSO ENCAMINHADO",
                   "BREVE COMUNICACAO", "PELA ORDEM",
                   "COMUNICACAO PARLAMENTAR"),
    "comissao" = c("COMISSAO"),
    "todos"    = NULL
  )

  resultados   <- vector("list", n_dep)
  total_colet  <- 0L
  limite_ating <- FALSE

  if (verbose) {
    cli::cli_progress_bar(
      "Coletando discursos",
      total  = n_dep,
      format = "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} dep. | {total_colet} disc."
    )
  }

  for (i in seq_len(n_dep)) {
    if (limite_ating) break

    dep           <- deputados[i, ]
    id_dep        <- dep$id
    disc_params   <- disc_params_base
    endpoint_disc <- paste0("/deputados/", id_dep, "/discursos")

    disc_raw <- tryCatch(
      .paginate_api(
        base_url  = base_url,
        endpoint  = endpoint_disc,
        params    = disc_params,
        max_items = if (is.finite(n_max)) n_max - total_colet else Inf,
        sleep     = sleep,
        verbose   = FALSE
      ),
      error = function(e) {
        if (verbose) {
          cli::cli_warn(
            "Falha ao buscar discursos do deputado {dep$nome} (id={id_dep}): {conditionMessage(e)}"
          )
        }
        NULL
      }
    )

    if (!is.null(disc_raw) && nrow(disc_raw) > 0) {

      # Remover faseEvento: e lista aninhada e quebra o do.call(rbind)
      if ("faseEvento" %in% names(disc_raw)) disc_raw$faseEvento <- NULL

      # Enriquecer com metadados do deputado
      disc_raw$id_deputado   <- id_dep
      disc_raw$nome_deputado <- dep$nome
      disc_raw$partido       <- dep$siglaPartido %||% NA_character_
      disc_raw$uf            <- dep$siglaUf      %||% NA_character_

      # Filtrar por tipoDiscurso (campo string plano)
      if (!is.null(cod_tipo) && "tipoDiscurso" %in% names(disc_raw)) {
        disc_raw <- disc_raw[
          disc_raw$tipoDiscurso %in% cod_tipo, ,
          drop = FALSE
        ]
      }

      if (nrow(disc_raw) > 0) {
        resultados[[i]] <- disc_raw
        total_colet     <- total_colet + nrow(disc_raw)
      }
    }

    if (is.finite(n_max) && total_colet >= n_max) limite_ating <- TRUE

    if (verbose) cli::cli_progress_update()
    Sys.sleep(sleep)
  }

  if (verbose) cli::cli_progress_done()

  # --- 4. Consolidar e padronizar ---------------------------------------------
  resultados_validos <- resultados[!sapply(resultados, is.null)]

  if (length(resultados_validos) == 0) {
    cli::cli_warn(
      "Nenhum discurso encontrado para o periodo {data_inicio} - {data_fim} com os filtros informados."
    )
    return(invisible(.empty_discursos_df()))
  }

  # Usar dplyr::bind_rows para evitar bug de row.names duplicados do rbind
  df_raw <- dplyr::bind_rows(resultados_validos)

  if (nrow(df_raw) == 0) {
    cli::cli_warn(
      "Nenhum discurso encontrado para o periodo {data_inicio} - {data_fim} com os filtros informados."
    )
    return(invisible(.empty_discursos_df()))
  }

  df <- .normalize_discursos(df_raw)

  if (is.finite(n_max) && nrow(df) > n_max) df <- df[seq_len(n_max), ]

  if (verbose) {
    cli::cli_alert_success(
      "{nrow(df)} discurso{?s} coletado{?s} de {data_inicio} a {data_fim}."
    )
  }

  df
}


# =============================================================================
# Funcoes auxiliares internas (nao exportadas)
# =============================================================================

#' Paginar endpoint da API da Camara
#' @noRd
.paginate_api <- function(base_url, endpoint, params, max_items, sleep, verbose) {
  results     <- list()
  pagina      <- 1L
  total_pags  <- Inf
  total_colet <- 0L

  while (pagina <= total_pags && total_colet < max_items) {
    params$pagina <- pagina

    resp  <- .camara_get(base_url, endpoint, params)
    if (is.null(resp)) break

    dados <- resp$dados
    if (is.null(dados) || length(dados) == 0) break

    if (is.list(dados) && !is.data.frame(dados)) {
      dados <- tryCatch(
        jsonlite::fromJSON(
          jsonlite::toJSON(dados, auto_unbox = TRUE),
          flatten = TRUE
        ),
        error = function(e) NULL
      )
    }
    if (is.null(dados)) break

    results[[pagina]] <- dados
    total_colet       <- total_colet + nrow(dados)

    links <- resp$links
    if (!is.null(links) && is.data.frame(links)) {
      ultima <- links$href[links$rel == "last"]
      if (length(ultima) > 0 && !is.na(ultima)) {
        m <- regmatches(ultima, regexpr("pagina=(\\d+)", ultima))
        if (length(m) > 0) {
          total_pags <- as.integer(sub("pagina=", "", m))
        }
      }
    }

    if (nrow(dados) < (params$itens %||% 100)) break

    pagina <- pagina + 1L
    Sys.sleep(sleep)
  }

  if (length(results) == 0) return(NULL)
  dplyr::bind_rows(results)
}


#' Requisicao GET com retry e backoff exponencial
#' @noRd
.camara_get <- function(base_url, endpoint, params) {
  url <- paste0(base_url, endpoint)

  for (tentativa in 1:3) {
    resp <- tryCatch(
      httr2::request(url) |>
        httr2::req_url_query(!!!params) |>
        httr2::req_headers(Accept = "application/json") |>
        httr2::req_timeout(30) |>
        httr2::req_perform(),
      error = function(e) e
    )

    if (inherits(resp, "error")) {
      if (tentativa < 3) { Sys.sleep(2^tentativa); next }
      cli::cli_warn("Falha de conexao apos 3 tentativas: {conditionMessage(resp)}")
      return(NULL)
    }

    status <- httr2::resp_status(resp)

    if (status == 429L) {
      wait <- 2^tentativa * 5
      cli::cli_warn("HTTP 429 (rate limit). Aguardando {wait}s...")
      Sys.sleep(wait)
      next
    }

    if (status >= 400L) {
      cli::cli_warn("HTTP {status} em {url}. Pulando.")
      return(NULL)
    }

    return(
      tryCatch(
        httr2::resp_body_json(resp, simplifyVector = TRUE),
        error = function(e) NULL
      )
    )
  }
  NULL
}


#' Normalizar colunas do data.frame de discursos
#' @noRd
.normalize_discursos <- function(df) {
  col_map <- c(
    "dataHoraInicio" = "data_hora_inicio",
    "dataHoraFim"    = "data_hora_fim",
    "tipoDiscurso"   = "tipo_discurso",
    "urlTexto"       = "url_texto",
    "urlAudio"       = "url_audio",
    "urlVideo"       = "url_video",
    "sumario"        = "sumario",
    "transcricao"    = "texto",
    "uri"            = "uri_discurso"
  )

  for (api_col in names(col_map)) {
    padrao_col <- col_map[[api_col]]
    if (api_col %in% names(df) && !padrao_col %in% names(df)) {
      names(df)[names(df) == api_col] <- padrao_col
    }
  }

  if (!"id_discurso" %in% names(df)) {
    df$id_discurso <- paste0("cam_", df$id_deputado, "_", seq_len(nrow(df)))
  }

  if ("data_hora_inicio" %in% names(df)) {
    df$data        <- as.Date(substr(df$data_hora_inicio, 1, 10))
    df$hora_inicio <- substr(df$data_hora_inicio, 12, 16)
  }

  if (!"texto" %in% names(df)) df$texto <- NA_character_

  cols_obrig <- c(
    "id_discurso", "id_deputado", "nome_deputado", "partido", "uf",
    "data", "hora_inicio", "tipo_discurso", "sumario", "texto", "uri_discurso"
  )

  for (col in cols_obrig) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }

  df[, c(cols_obrig, setdiff(names(df), cols_obrig))]
}


#' Data.frame vazio com estrutura correta
#' @noRd
.empty_discursos_df <- function() {
  data.frame(
    id_discurso   = character(0),
    id_deputado   = integer(0),
    nome_deputado = character(0),
    partido       = character(0),
    uf            = character(0),
    data          = as.Date(character(0)),
    hora_inicio   = character(0),
    tipo_discurso = character(0),
    sumario       = character(0),
    texto         = character(0),
    uri_discurso  = character(0),
    stringsAsFactors = FALSE
  )
}


#' Verificar se pacote esta disponivel
#' @noRd
.check_pkg <- function(pkg, fn) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cli::cli_abort(
      "O pacote {.pkg {pkg}} e necessario para {.fn {fn}}. Instale com: {.code install.packages(\"{pkg}\")}"
    )
  }
}


#' Validar formato de data
#' @noRd
.validate_date <- function(x, arg) {
  if (!grepl("^\\d{4}-\\d{2}-\\d{2}$", x)) {
    cli::cli_abort(
      "{.arg {arg}} deve estar no formato {.code YYYY-MM-DD}. Recebido: {.val {x}}"
    )
  }
  if (is.na(as.Date(x, format = "%Y-%m-%d"))) {
    cli::cli_abort("{.arg {arg}} nao e uma data valida: {.val {x}}")
  }
}


#' Operador null-coalesce
#' @noRd
`%||%` <- function(x, y) if (!is.null(x) && length(x) > 0 && !is.na(x[1])) x else y
