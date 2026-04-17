#' Busca discursos de deputados federais via API da C^amara dos Deputados
#'
#' @description
#' Coleta discursos parlamentares diretamente da API p'ublica da C^amara dos
#' Deputados (v2), retornando um `data.frame` padronizado e pronto para uso
#' nas func~oes do `acR`. A coleta e feita em duas etapas: (1) lista deputados
#' conforme os filtros informados; (2) para cada deputado, busca os discursos
#' no periodo solicitado, com paginacao autom'atica.
#'
#' @param data_inicio `character`. Data de in'icio no formato `"YYYY-MM-DD"`.
#' @param data_fim `character`. Data de fim no formato `"YYYY-MM-DD"`.
#' @param legislatura `integer` ou `NULL`. N'umero da legislatura (ex.: `57`
#'   para 2023-2027). Se `NULL`, usa o periodo definido por `data_inicio` e
#'   `data_fim` sem filtrar por legislatura.
#' @param partido `character` ou `NULL`. Sigla do partido para filtrar
#'   deputados (ex.: `"PT"`, `"PL"`, `"MDB"`). Aceita vetor de sigllas.
#'   Se `NULL`, inclui todos os partidos.
#' @param uf `character` ou `NULL`. Sigla da UF para filtrar deputados
#'   (ex.: `"SP"`, `"MG"`). Aceita vetor de UFs. Se `NULL`, inclui todas.
#' @param n_max `integer`. N'umero m'aximo de discursos a retornar.
#'   Padr~ao: `100`. Use `Inf` para coletar todos (atenc~ao: pode ser lento).
#' @param tipo_discurso `character`. Tipo de evento parlamentar. Opc~oes
#'   principais: `"plenario"` (padrao), `"comissao"`, `"todos"`.
#' @param verbose `logical`. Se `TRUE` (padrao), exibe mensagens de progresso.
#' @param sleep `numeric`. Tempo de espera (em segundos) entre chamadas `a API
#'   para respeitar o rate limit. Padr~ao: `0.5`.
#'
#' @return Um `data.frame` com as colunas:
#'   \describe{
#'     \item{`id_discurso`}{`character`. Identificador unico do discurso.}
#'     \item{`id_deputado`}{`integer`. ID do deputado na API da C^amara.}
#'     \item{`nome_deputado`}{`character`. Nome civil do parlamentar.}
#'     \item{`partido`}{`character`. Sigla do partido na data do discurso.}
#'     \item{`uf`}{`character`. UF da bancada do parlamentar.}
#'     \item{`data`}{`Date`. Data do discurso.}
#'     \item{`hora_inicio`}{`character`. Hora de in'icio (HH:MM).}
#'     \item{`tipo_discurso`}{`character`. Tipo de fase do evento.}
#'     \item{`sumario`}{`character`. Sum'ario do discurso (quando dispon'ivel).}
#'     \item{`texto`}{`character`. Texto integral do discurso (quando dispon'ivel).}
#'     \item{`uri_discurso`}{`character`. URI do recurso na API.}
#'   }
#'
#' @details
#' ## Estrutura da API
#' A API Dados Abertos da C^amara (v2) n~ao disp~oe de endpoint unico para
#' discursos por periodo. O fluxo de coleta e:
#'
#' 1. `GET /api/v2/deputados` - lista deputados com filtros de partido/UF.
#' 2. `GET /api/v2/deputados/{id}/discursos` - discursos de cada deputado,
#'    com paginacao (m'ax. 100 itens por p'agina).
#'
#' ## Rate limiting
#' A API n~ao publica limites formais, mas respostas com HTTP 429 s~ao tratadas
#' com *backoff* exponencial (ate 3 tentativas). O par^ametro `sleep` define
#' a pausa m'inima entre requisicoes.
#'
#' ## Texto integral
#' Nem todos os discursos t^em texto integral dispon'ivel. Quando ausente,
#' a coluna `texto` recebe `NA`. Nesses casos, apenas o `sumario` e retornado.
#'
#' @examples
#' \dontrun{
#' # Discursos do plen'ario, primeiro semestre de 2024
#' disc <- ac_fetch_camara(
#'   data_inicio = "2024-01-01",
#'   data_fim    = "2024-06-30",
#'   n_max       = 50
#' )
#'
#' # Apenas PT e PL, legislatura 57
#' disc_partidos <- ac_fetch_camara(
#'   data_inicio  = "2024-01-01",
#'   data_fim     = "2024-12-31",
#'   legislatura  = 57,
#'   partido      = c("PT", "PL"),
#'   n_max        = 200
#' )
#'
#' # Deputados de SP, todos os tipos de discurso
#' disc_sp <- ac_fetch_camara(
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
#' C^AMARA DOS DEPUTADOS. **Dados Abertos da C^amara dos Deputados - API v2**.
#' Bras'ilia, 2024. Dispon'ivel em:
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
  # --- 0. Verificar dependencias -----------------------------------------------
  .check_pkg("httr2",   "ac_fetch_camara")
  .check_pkg("jsonlite", "ac_fetch_camara")

  # --- 1. Validar parametros ---------------------------------------------------
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

  # --- 2. Listar deputados com os filtros solicitados -------------------------
  if (verbose) cli::cli_progress_step("Buscando lista de deputados...")

  dep_params <- list(
    ordem      = "ASC",
    ordenarPor = "nome",
    itens      = 100
  )
  if (!is.null(legislatura)) dep_params$idLegislatura <- legislatura
  if (!is.null(uf))          dep_params$siglaUf       <- uf

  # Se partido e vetor, precisa multiplas requisicoes (API aceita 1 por vez)
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
  if (verbose) {
    cli::cli_alert_success(
      "{n_dep} deputado{?s} encontrado{?s}."
    )
  }

  # --- 3. Para cada deputado, buscar discursos --------------------------------
  disc_params_base <- list(
    dataInicio = data_inicio,
    dataFim    = data_fim,
    ordenarPor = "dataHoraInicio",
    ordem      = "ASC",
    itens      = 100
  )

  # Mapear tipo_discurso -> codTipoDiscurso da API
  # (API usa fase do evento, n~ao existe filtro direto por "plenario" no endpoint
  # de discursos; filtramos por faseEvento no p'os-processamento)
  cod_fase <- switch(
    tipo_discurso,
    "plenario"  = "GF",   # Grande Expediente / Ordem do Dia
    "comissao"  = "CO",
    "todos"     = NULL
  )

  resultados   <- vector("list", n_dep)
  total_colet  <- 0L
  limite_ating <- FALSE

  if (verbose) {
    cli::cli_progress_bar(
      "Coletando discursos",
      total = n_dep,
      format = "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} dep. | {total_colet} disc."
    )
  }

  for (i in seq_len(n_dep)) {
    if (limite_ating) break

    dep        <- deputados[i, ]
    id_dep     <- dep$id
    disc_params <- disc_params_base

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
      # Enriquecer com metadados do deputado
      disc_raw$id_deputado   <- id_dep
      disc_raw$nome_deputado <- dep$nome
      disc_raw$partido       <- dep$siglaPartido %||% NA_character_
      disc_raw$uf            <- dep$siglaUf      %||% NA_character_

      # Filtrar por tipo de fase, se aplic'avel
      if (!is.null(cod_fase) && "faseEvento" %in% names(disc_raw)) {
        disc_raw <- disc_raw[
          grepl(cod_fase, disc_raw$faseEvento, ignore.case = TRUE), ,
          drop = FALSE
        ]
      }

      resultados[[i]] <- disc_raw
      total_colet     <- total_colet + nrow(disc_raw)
    }

    if (is.finite(n_max) && total_colet >= n_max) {
      limite_ating <- TRUE
    }

    if (verbose) cli::cli_progress_update()
    Sys.sleep(sleep)
  }

  if (verbose) cli::cli_progress_done()

  # --- 4. Consolidar e padronizar ---------------------------------------------
  df_raw <- do.call(rbind, resultados[!sapply(resultados, is.null)])

  if (is.null(df_raw) || nrow(df_raw) == 0) {
    cli::cli_warn(
      "Nenhum discurso encontrado para o periodo {data_inicio} - {data_fim} com os filtros informados."
    )
    return(invisible(.empty_discursos_df()))
  }

  # Normalizar nomes de colunas que variam entre vers~oes da API
  df <- .normalize_discursos(df_raw)

  # Aplicar n_max ap'os consolidac~ao (pode ter coletado ligeiramente acima)
  if (is.finite(n_max) && nrow(df) > n_max) {
    df <- df[seq_len(n_max), ]
  }

  if (verbose) {
    cli::cli_alert_success(
      "{nrow(df)} discurso{?s} coletado{?s} de {data_inicio} a {data_fim}."
    )
  }

  df
}


# =============================================================================
# Func~oes auxiliares internas (n~ao exportadas)
# =============================================================================

#' Paginar endpoint da API da C^amara
#' @noRd
.paginate_api <- function(base_url, endpoint, params, max_items, sleep, verbose) {
  results    <- list()
  pagina     <- 1L
  total_pags <- Inf
  total_colet <- 0L

  while (pagina <= total_pags && total_colet < max_items) {
    params$pagina <- pagina

    resp <- .camara_get(base_url, endpoint, params)
    if (is.null(resp)) break

    dados <- resp$dados
    if (is.null(dados) || length(dados) == 0) break

    # Converter lista de listas em data.frame
    if (is.list(dados) && !is.data.frame(dados)) {
      dados <- tryCatch(
        jsonlite::fromJSON(jsonlite::toJSON(dados, auto_unbox = TRUE),
                           flatten = TRUE),
        error = function(e) NULL
      )
    }
    if (is.null(dados)) break

    results[[pagina]] <- dados
    total_colet        <- total_colet + nrow(dados)

    # Ler numero total de paginas do link de paginacao
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

    # Se retornou menos do que o m'aximo por p'agina, n~ao ha pr'oxima p'agina
    if (nrow(dados) < (params$itens %||% 100)) break

    pagina <- pagina + 1L
    Sys.sleep(sleep)
  }

  if (length(results) == 0) return(NULL)
  do.call(rbind, results)
}


#' Requisic~ao GET com retry e backoff exponencial
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

    # Se e erro de conex~ao
    if (inherits(resp, "error")) {
      if (tentativa < 3) {
        Sys.sleep(2^tentativa)
        next
      } else {
        cli::cli_warn("Falha de conexao apos 3 tentativas: {conditionMessage(resp)}")
        return(NULL)
      }
    }

    status <- httr2::resp_status(resp)

    # Rate limit: esperar e tentar novamente
    if (status == 429L) {
      wait <- 2^tentativa * 5
      cli::cli_warn("HTTP 429 (rate limit). Aguardando {wait}s antes de tentar novamente...")
      Sys.sleep(wait)
      next
    }

    # Outros erros HTTP
    if (status >= 400L) {
      cli::cli_warn("HTTP {status} em {url}. Pulando.")
      return(NULL)
    }

    # Sucesso
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
  # Mapeamento de nomes da API -> nomes padronizados do acR
  col_map <- c(
    "dataHoraInicio" = "data_hora_inicio",
    "dataHoraFim"    = "data_hora_fim",
    "tipoDiscurso"   = "tipo_discurso",
    "urlTexto"       = "url_texto",
    "urlAudio"       = "url_audio",
    "urlVideo"       = "url_video",
    "faseEvento"     = "fase_evento",
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

  # Criar id_discurso unico e reproduz'ivel
  if (!"id_discurso" %in% names(df)) {
    df$id_discurso <- paste0(
      "cam_",
      df$id_deputado,
      "_",
      seq_len(nrow(df))
    )
  }

  # Parsear datas
  if ("data_hora_inicio" %in% names(df)) {
    df$data <- as.Date(
      substr(df$data_hora_inicio, 1, 10)
    )
    df$hora_inicio <- substr(df$data_hora_inicio, 12, 16)
  }

  # Garantir coluna texto (pode estar em transcricao ou ausente)
  if (!"texto" %in% names(df)) {
    df$texto <- NA_character_
  }

  # Colunas obrigatorias na ordem certa
  cols_obrig <- c(
    "id_discurso", "id_deputado", "nome_deputado", "partido", "uf",
    "data", "hora_inicio", "tipo_discurso", "sumario", "texto", "uri_discurso"
  )

  for (col in cols_obrig) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }

  df[, c(cols_obrig, setdiff(names(df), cols_obrig))]
}


#' Data.frame vazio com estrutura correta (retorno em caso de falha)
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


#' Verificar se pacote esta dispon'ivel
#' @noRd
.check_pkg <- function(pkg, fn) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cli::cli_abort(
      "O pacote {.pkg {pkg}} e necessario para {.fn {fn}}. \\
       Instale com: {.code install.packages(\"{pkg}\")}"
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
    cli::cli_abort(
      "{.arg {arg}} nao e uma data valida: {.val {x}}"
    )
  }
}


#' Operador null-coalesce
#' @noRd
`%||%` <- function(x, y) if (!is.null(x) && length(x) > 0 && !is.na(x[1])) x else y
