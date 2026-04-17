#' Busca discursos de senadores federais via senatebR
#' @importFrom senatebR extrair_discursos
#'
#' @description
#' Coleta discursos parlamentares do Senado Federal usando o pacote
#' \pkg{senatebR} como backend, retornando um \code{data.frame} no mesmo
#' formato padronizado de \code{\link{ac_fetch_camara}()}. Isso permite
#' combinar corpora das duas casas legislativas sem atrito.
#'
#' O periodo pode ser especificado por legislatura (atalho conveniente) ou
#' por datas exatas (controle fino). Se ambos forem fornecidos, as datas
#' prevalecem.
#'
#' @param data_inicio \code{character} ou \code{NULL}. Data de inicio no
#'   formato \code{"YYYY-MM-DD"}. Se \code{NULL}, usa o inicio da
#'   \code{legislatura_inicio}.
#' @param data_fim \code{character} ou \code{NULL}. Data de fim no formato
#'   \code{"YYYY-MM-DD"}. Se \code{NULL}, usa o fim da
#'   \code{legislatura_fim}.
#' @param legislatura_inicio \code{integer} ou \code{NULL}. Numero da
#'   legislatura de inicio (ex.: \code{56} para 2019-2023,
#'   \code{57} para 2023-2027). Ignorado se \code{data_inicio} for
#'   fornecido.
#' @param legislatura_fim \code{integer} ou \code{NULL}. Numero da
#'   legislatura de fim. Se \code{NULL}, usa o mesmo valor de
#'   \code{legislatura_inicio}.
#' @param partido \code{character} ou \code{NULL}. Sigla(s) do partido para
#'   filtrar senadores (ex.: \code{"PT"}, \code{c("PT", "PL")}). Filtragem
#'   pos-coleta. Se \code{NULL}, inclui todos os partidos.
#' @param uf \code{character} ou \code{NULL}. Sigla(s) da UF para filtrar
#'   senadores (ex.: \code{"SP"}, \code{c("SP", "MG")}). Filtragem
#'   pos-coleta. Se \code{NULL}, inclui todas as UFs.
#' @param nome_senador \code{character} ou \code{NULL}. Padrao de texto para
#'   filtrar pelo nome do senador (busca parcial, case-insensitive). Ex.:
#'   \code{"Lula"}, \code{"Pacheco"}. Se \code{NULL}, inclui todos.
#' @param n_max \code{integer}. Numero maximo de discursos a retornar.
#'   Padrao: \code{100}. Use \code{Inf} para coletar todos.
#' @param verbose \code{logical}. Se \code{TRUE} (padrao), exibe mensagens
#'   de progresso.
#' @param sleep \code{numeric}. Pausa em segundos entre requisicoes.
#'   Padrao: \code{0.3}.
#'
#' @return Um \code{data.frame} com as mesmas colunas de
#'   \code{\link{ac_fetch_camara}()}:
#'   \describe{
#'     \item{\code{id_discurso}}{\code{character}. Identificador unico.}
#'     \item{\code{id_deputado}}{\code{character}. Codigo do senador na API.}
#'     \item{\code{nome_deputado}}{\code{character}. Nome do senador.}
#'     \item{\code{partido}}{\code{character}. Sigla do partido.}
#'     \item{\code{uf}}{\code{character}. UF da representacao.}
#'     \item{\code{data}}{\code{Date}. Data do discurso.}
#'     \item{\code{hora_inicio}}{\code{character}. Hora de inicio (HH:MM).}
#'     \item{\code{tipo_discurso}}{\code{character}. Tipo/fase do discurso.}
#'     \item{\code{sumario}}{\code{character}. Resumo do discurso.}
#'     \item{\code{texto}}{\code{character}. Texto integral (quando disponivel).}
#'     \item{\code{uri_discurso}}{\code{character}. URL do recurso.}
#'     \item{\code{casa}}{\code{character}. Sempre \code{"senado"}.}
#'   }
#'
#' @details
#' ## Legislaturas do Senado Federal
#' | Legislatura | Periodo     |
#' |-------------|-------------|
#' | 55          | 2015-2019   |
#' | 56          | 2019-2023   |
#' | 57          | 2023-2027   |
#'
#' ## Compatibilidade com ac_fetch_camara()
#' O \code{data.frame} retornado tem as mesmas colunas de
#' \code{\link{ac_fetch_camara}()}, com a adicao da coluna \code{casa}
#' (\code{"senado"}). Isso permite combinar os dois corpora com
#' \code{rbind()} ou \code{dplyr::bind_rows()}.
#'
#' ## Backend
#' Esta funcao usa \pkg{senatebR} (Santos, 2026) como backend para acesso
#' a API do Senado Federal. O \pkg{senatebR} deve estar instalado:
#' \code{install.packages("senatebR")}.
#'
#' @examples
#' \dontrun{
#' # Por legislatura
#' disc_sen <- ac_fetch_senado(
#'   legislatura_inicio = 57,
#'   n_max = 50
#' )
#'
#' # Por datas + filtro de partido
#' disc_pt <- ac_fetch_senado(
#'   data_inicio = "2024-01-01",
#'   data_fim    = "2024-06-30",
#'   partido     = c("PT", "PL"),
#'   n_max       = 100
#' )
#'
#' # Combinar Camara + Senado
#' disc_camara <- ac_fetch_camara(
#'   data_inicio = "2024-03-01",
#'   data_fim    = "2024-03-31",
#'   n_max       = 50
#' )
#' disc_senado <- ac_fetch_senado(
#'   data_inicio = "2024-03-01",
#'   data_fim    = "2024-03-31",
#'   n_max       = 50
#' )
#' corpus_bicameral <- dplyr::bind_rows(disc_camara, disc_senado)
#' }
#'
#' @references
#' SANTOS, V. \strong{senatebR}: Collect Data from the Brazilian Federal
#' Senate Open Data API. CRAN, 2026.
#' Disponivel em: \url{https://github.com/vsntos/senatebR}.
#'
#' @seealso \code{\link{ac_fetch_camara}()}, \code{\link{ac_corpus}()}
#'
#' @export
ac_fetch_senado <- function(
    data_inicio        = NULL,
    data_fim           = NULL,
    legislatura_inicio = NULL,
    legislatura_fim    = NULL,
    partido            = NULL,
    uf                 = NULL,
    nome_senador       = NULL,
    n_max              = 100,
    verbose            = TRUE,
    sleep              = 0.3
) {
  # --- 0. Verificar dependencia -----------------------------------------------
  .check_pkg("senatebR", "ac_fetch_senado")

  # --- 1. Resolver periodo ----------------------------------------------------
  datas <- .senado_resolve_periodo(
    data_inicio, data_fim,
    legislatura_inicio, legislatura_fim
  )
  data_inicio <- datas$inicio
  data_fim    <- datas$fim
  leg_inicio  <- datas$leg_inicio
  leg_fim     <- datas$leg_fim

  if (verbose) {
    cli::cli_alert_info(
      "Periodo: {data_inicio} a {data_fim} (leg. {leg_inicio}-{leg_fim})"
    )
  }

  # --- 2. Listar senadores do periodo -----------------------------------------
  if (verbose) cli::cli_progress_step("Buscando lista de senadores...")

  senadores_raw <- tryCatch(
    senatebR::obter_dados_senadores_legislatura(leg_inicio, leg_fim),
    error = function(e) {
      cli::cli_abort(
        "Falha ao listar senadores via senatebR: {conditionMessage(e)}"
      )
    }
  )

  if (is.null(senadores_raw) || nrow(senadores_raw) == 0) {
    cli::cli_warn("Nenhum senador encontrado para as legislaturas informadas.")
    return(invisible(.empty_discursos_df_senado()))
  }

  # Normalizar nomes de colunas do senatebR (variam entre versoes)
  senadores <- .senado_normalize_senators(senadores_raw)
  senadores <- senadores[!is.na(senadores$codigo) & nchar(trimws(as.character(senadores$codigo))) > 0, ]

  # --- 3. Aplicar filtros de partido, UF e nome -------------------------------
  if (!is.null(partido)) {
    senadores <- senadores[
      !is.na(senadores$partido) & toupper(senadores$partido) %in% toupper(partido), ,
      drop = FALSE
    ]
  }
  if (!is.null(uf)) {
    senadores <- senadores[
      toupper(senadores$uf) %in% toupper(uf), ,
      drop = FALSE
    ]
  }
  if (!is.null(nome_senador)) {
    senadores <- senadores[
      grepl(nome_senador, senadores$nome, ignore.case = TRUE), ,
      drop = FALSE
    ]
  }

  if (nrow(senadores) == 0) {
    cli::cli_warn(
      "Nenhum senador encontrado apos aplicar os filtros informados."
    )
    return(invisible(.empty_discursos_df_senado()))
  }

  n_sen <- nrow(senadores)
  if (verbose) cli::cli_alert_success("{n_sen} senador{?es} encontrado{?s}.")

  # --- 4. Coletar discursos por senador ---------------------------------------
  resultados  <- vector("list", n_sen)
  total_colet <- 0L
  limite_ating <- FALSE

  if (verbose) {
    cli::cli_progress_bar(
      "Coletando discursos do Senado",
      total  = n_sen,
      format = "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} sen. | {total_colet} disc."
    )
  }

  for (i in seq_len(n_sen)) {
    if (limite_ating) break

    sen    <- senadores[i, ]
    cod    <- as.character(sen$codigo)

    if (is.na(cod) || trimws(cod) == "" || trimws(cod) == "NA") {
      if (verbose) cli::cli_warn("Codigo invalido para {sen$nome}, pulando.")
      next
    }

    disc_raw <- withCallingHandlers(
      tryCatch(
        {
          on.exit(tryCatch({
      cons <- showConnections(all = TRUE)
      http_cons <- as.integer(rownames(cons[grepl("http|legis[.]senado", cons[,"description"]), , drop = FALSE]))
      for (i in http_cons) try(close(getConnection(i)), silent = TRUE)
    }, error = function(e) NULL), add = TRUE)
          senatebR::extrair_discursos(
            codigo_senador = cod,
            data_inicio    = data_inicio,
            data_fim       = data_fim
          )
        },
        error = function(e) {
          tryCatch({
      cons <- showConnections(all = TRUE)
      http_cons <- as.integer(rownames(cons[grepl("http|legis[.]senado", cons[,"description"]), , drop = FALSE]))
      for (i in http_cons) try(close(getConnection(i)), silent = TRUE)
    }, error = function(e) NULL)
          if (verbose) {
            cli::cli_warn(
              "Falha ao buscar discursos de {sen$nome} (cod={cod}): {conditionMessage(e)}"
            )
          }
          NULL
        }
      ),
      warning = function(w) {
        if (grepl("codigo do senador NA|senadorNA|senador/NA", conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )

    if (!is.null(disc_raw) && nrow(disc_raw) > 0) {
      disc_raw$codigo_senador <- cod
      disc_raw$nome_senador   <- sen$nome
      disc_raw$partido_sen    <- sen$partido
      disc_raw$uf_sen         <- sen$uf

      resultados[[i]] <- disc_raw
      total_colet     <- total_colet + nrow(disc_raw)
    }

    if (is.finite(n_max) && total_colet >= n_max) {
      limite_ating <- TRUE
    }

    tryCatch({
      cons <- showConnections(all = TRUE)
      http_cons <- as.integer(rownames(cons[grepl("http|legis[.]senado", cons[,"description"]), , drop = FALSE]))
      for (i in http_cons) try(close(getConnection(i)), silent = TRUE)
    }, error = function(e) NULL)
    if (verbose) cli::cli_progress_update()
    Sys.sleep(sleep)
  }

  if (verbose) cli::cli_progress_done()

  # --- 5. Consolidar ----------------------------------------------------------
  df_raw <- do.call(rbind, resultados[!sapply(resultados, is.null)])

  if (is.null(df_raw) || nrow(df_raw) == 0) {
    tryCatch({
      cons <- showConnections(all = TRUE)
      http_cons <- as.integer(rownames(cons[grepl("http|legis[.]senado", cons[,"description"]), , drop = FALSE]))
      for (i in http_cons) try(close(getConnection(i)), silent = TRUE)
    }, error = function(e) NULL)
    tryCatch({
      cons <- showConnections(all = TRUE)
      http_cons <- as.integer(rownames(cons[grepl("http|legis[.]senado", cons[,"description"]), , drop = FALSE]))
      for (i in http_cons) try(close(getConnection(i)), silent = TRUE)
    }, error = function(e) NULL)
    cli::cli_warn(
      "Nenhum discurso encontrado para o periodo {data_inicio} - {data_fim}."
    )
    return(invisible(.empty_discursos_df_senado()))
  }

  df <- .senado_normalize_discursos(df_raw)

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
# Helpers internos
# =============================================================================

#' Resolver periodo a partir de legislatura ou datas
#' @noRd
.senado_resolve_periodo <- function(data_inicio, data_fim,
                                    leg_inicio, leg_fim) {
  # Tabela de legislaturas → datas aproximadas
  leg_datas <- list(
    "54" = c("2011-02-01", "2015-01-31"),
    "55" = c("2015-02-01", "2019-01-31"),
    "56" = c("2019-02-01", "2023-01-31"),
    "57" = c("2023-02-01", "2027-01-31")
  )

  # Se datas explicitas foram fornecidas, usam-se diretamente
  if (!is.null(data_inicio) && !is.null(data_fim)) {
    .validate_date(data_inicio, "data_inicio")
    .validate_date(data_fim,    "data_fim")
    # Inferir legislatura das datas para listar senadores
    li <- .senado_leg_from_date(data_inicio, leg_datas)
    lf <- .senado_leg_from_date(data_fim,    leg_datas)
    return(list(inicio = data_inicio, fim = data_fim,
                leg_inicio = li, leg_fim = lf))
  }

  # Se so legislatura foi fornecida
  if (!is.null(leg_inicio)) {
    lf  <- if (!is.null(leg_fim)) leg_fim else leg_inicio
    key_i <- as.character(leg_inicio)
    key_f <- as.character(lf)

    if (!key_i %in% names(leg_datas)) {
      cli::cli_abort(
        "Legislatura {leg_inicio} nao reconhecida. \\
         Use entre 54 e 57, ou forneca {.arg data_inicio}/{.arg data_fim}."
      )
    }
    di <- leg_datas[[key_i]][1]
    df <- leg_datas[[if (key_f %in% names(leg_datas)) key_f else key_i]][2]
    return(list(inicio = di, fim = df,
                leg_inicio = leg_inicio, leg_fim = lf))
  }

  cli::cli_abort(
    "Forneca {.arg data_inicio}/{.arg data_fim} ou {.arg legislatura_inicio}."
  )
}

#' Inferir legislatura a partir de uma data
#' @noRd
.senado_leg_from_date <- function(data, leg_datas) {
  d <- as.Date(data)
  for (leg in rev(names(leg_datas))) {
    if (d >= as.Date(leg_datas[[leg]][1])) return(as.integer(leg))
  }
  as.integer(names(leg_datas)[1])
}

#' Normalizar colunas do data.frame de senadores do senatebR
#' @noRd
.senado_normalize_senators <- function(df) {
  # senatebR pode retornar colunas com nomes variados
  col_map <- c(
    "IdentificacaoParlamentar.CodigoParlamentar"       = "codigo",
    "IdentificacaoParlamentar.NomeParlamentar"         = "nome",
    "IdentificacaoParlamentar.NomeCompletoParlamentar" = "nome_completo",
    "IdentificacaoParlamentar.SiglaPartidoParlamentar" = "partido",
    "IdentificacaoParlamentar.UfParlamentar"           = "uf",
    "IdentificacaoParlamentar.SexoParlamentar"         = "sexo"
  )

  for (api_col in names(col_map)) {
    padrao <- col_map[[api_col]]
    if (api_col %in% names(df) && !padrao %in% names(df)) {
      names(df)[names(df) == api_col] <- padrao
    }
  }

  # Garantir colunas minimas
  for (col in c("codigo", "nome", "partido", "uf")) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }

  df[, c("codigo", "nome", "partido", "uf",
         setdiff(names(df), c("codigo", "nome", "partido", "uf")))]
}

#' Normalizar colunas do data.frame de discursos do senatebR
#' para o schema padrao do acR
#' @noRd
.senado_normalize_discursos <- function(df) {
  # Mapeamento senatebR → acR
  col_map <- c(
    "CodigoPronunciamento"       = "id_discurso_raw",
    "DataPronunciamento"         = "data_hora_inicio",
    "TipoUsoPalavra"             = "tipo_discurso",
    "TextoResumo"                = "sumario",
    "Indexacao"                  = "indexacao",
    "UrlTexto"                   = "uri_discurso",
    "SiglaPartidoParlamentarNaData" = "partido_na_data",
    "UfParlamentarNaData"        = "uf_na_data"
  )

  for (api_col in names(col_map)) {
    padrao <- col_map[[api_col]]
    if (api_col %in% names(df) && !padrao %in% names(df)) {
      names(df)[names(df) == api_col] <- padrao
    }
  }

  # id_discurso
  if ("id_discurso_raw" %in% names(df)) {
    df$id_discurso <- paste0("sen_", df$id_discurso_raw)
  } else {
    df$id_discurso <- paste0("sen_", df$codigo_senador, "_", seq_len(nrow(df)))
  }

  # data e hora_inicio
  if ("data_hora_inicio" %in% names(df)) {
    df$data        <- as.Date(substr(df$data_hora_inicio, 1, 10))
    df$hora_inicio <- substr(df$data_hora_inicio, 12, 16)
    df$hora_inicio[nchar(df$hora_inicio) < 5] <- NA_character_
  } else {
    df$data        <- as.Date(NA)
    df$hora_inicio <- NA_character_
  }

  # Partido e UF: preferir valor na data do discurso, fallback nos metadados
  if (!"partido" %in% names(df)) {
    df$partido <- if ("partido_na_data" %in% names(df)) {
      df$partido_na_data
    } else if ("partido_sen" %in% names(df)) {
      df$partido_sen
    } else {
      NA_character_
    }
  }

  if (!"uf" %in% names(df)) {
    df$uf <- if ("uf_na_data" %in% names(df)) {
      df$uf_na_data
    } else if ("uf_sen" %in% names(df)) {
      df$uf_sen
    } else {
      NA_character_
    }
  }

  # nome_deputado (nome padrao acR para parlamentar)
  if (!"nome_deputado" %in% names(df)) {
    df$nome_deputado <- if ("nome_senador" %in% names(df)) {
      df$nome_senador
    } else {
      NA_character_
    }
  }

  # id_deputado (codigo do parlamentar — nome padrao acR)
  if (!"id_deputado" %in% names(df)) {
    df$id_deputado <- if ("codigo_senador" %in% names(df)) {
      df$codigo_senador
    } else {
      NA_character_
    }
  }

  # texto integral
  if (!"texto" %in% names(df)) df$texto <- NA_character_

  # sumario
  if (!"sumario" %in% names(df)) df$sumario <- NA_character_

  # tipo_discurso
  if (!"tipo_discurso" %in% names(df)) df$tipo_discurso <- NA_character_

  # uri_discurso
  if (!"uri_discurso" %in% names(df)) df$uri_discurso <- NA_character_

  # coluna casa — diferencia do corpus da Camara
  df$casa <- "senado"

  # Colunas obrigatorias na ordem padrao acR + casa
  cols_obrig <- c(
    "id_discurso", "id_deputado", "nome_deputado", "partido", "uf",
    "data", "hora_inicio", "tipo_discurso", "sumario", "texto",
    "uri_discurso", "casa"
  )

  for (col in cols_obrig) {
    if (!col %in% names(df)) df[[col]] <- NA_character_
  }

  df[, c(cols_obrig, setdiff(names(df), cols_obrig))]
}

#' Data.frame vazio com estrutura correta para o Senado
#' @noRd
.empty_discursos_df_senado <- function() {
  df <- .empty_discursos_df()
  df$casa <- character(0)
  df
}
