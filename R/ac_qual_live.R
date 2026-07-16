#' @keywords internal
#' @noRd
.ac_live_start <- function(mode, n_docs) {
  ctx <- list(mode = mode, n = n_docs, results = list())

  if (mode == "terminal") {
    ctx$pb <- cli::cli_progress_bar(
      total  = n_docs,
      format = "{cli::pb_current}/{cli::pb_total} | {cli::pb_bar} {cli::pb_percent} | ETA {cli::pb_eta} | {cli::pb_status}",
      clear  = FALSE
    )
  } else if (mode == "shiny") {
    ctx$shiny_data <- new.env(parent = emptyenv())
    ctx$shiny_data$rows <- list()
    ctx$shiny_data$done <- FALSE
    ctx$shiny_app <- .ac_live_shiny_app(ctx$shiny_data, n_docs)
    ctx$shiny_process <- .ac_live_shiny_launch(ctx$shiny_app)
  }

  ctx
}


#' @keywords internal
#' @noRd
.ac_live_update <- function(ctx, i, n_docs, doc_id, main_result, conf_scores) {
  if (ctx$mode == "off") return(invisible())

  categoria <- main_result$categoria %||% main_result$categoria_all[1] %||% "?"
  raciocinio <- main_result$raciocinio %||% ""
  conf <- if (is.list(conf_scores) && !is.null(conf_scores$total)) {
    conf_scores$total
  } else if (is.numeric(conf_scores)) {
    conf_scores[1]
  } else {
    NA_real_
  }

  short_reasoning <- if (nchar(raciocinio) > 60L) {
    paste0(substr(raciocinio, 1L, 57L), "...")
  } else {
    raciocinio
  }

  status <- sprintf(
    "%s -> %s%s%s",
    format(doc_id, width = 12L),
    format(categoria, width = 12L),
    if (!is.na(conf)) sprintf(" (conf %.2f)", conf) else "",
    if (nzchar(short_reasoning)) paste0(" \"", short_reasoning, "\"") else ""
  )

  if (ctx$mode == "terminal") {
    cli::cli_progress_update(id = ctx$pb, status = status)
  } else if (ctx$mode == "shiny") {
    ctx$shiny_data$rows[[length(ctx$shiny_data$rows) + 1L]] <- list(
      i = i, doc_id = doc_id, categoria = categoria,
      confidence = conf, reasoning = short_reasoning
    )
  }

  invisible()
}


#' @keywords internal
#' @noRd
.ac_live_finish <- function(ctx) {
  if (is.null(ctx)) return(invisible())

  if (identical(ctx$mode, "terminal") && !is.null(ctx$pb)) {
    cli::cli_progress_done(id = ctx$pb)
  } else if (identical(ctx$mode, "shiny")) {
    if (!is.null(ctx$shiny_data)) ctx$shiny_data$done <- TRUE
    # nao encerra o gadget; usuario fecha a janela quando quiser
  }

  invisible()
}


# ============================================================================
# Shiny live view (opcional)
# ============================================================================

#' @keywords internal
#' @noRd
.ac_live_shiny_app <- function(shared_env, n_docs) {
  if (!requireNamespace("shiny", quietly = TRUE))
    return(NULL)

  shiny::shinyApp(
    ui = shiny::fluidPage(
      shiny::tags$head(shiny::tags$style(shiny::HTML("
        body { font-family: Inter, -apple-system, sans-serif; padding: 20px; background: #FBFAF7; }
        h2 { color: #0F3D5C; letter-spacing: -0.01em; margin-top: 0; }
        table { width: 100%; border-collapse: collapse; font-size: 13px; }
        th { background: #0F3D5C; color: white; padding: 8px 12px; text-align: left; }
        td { padding: 6px 12px; border-bottom: 1px solid #E5E7EB; }
        tr:nth-child(even) { background: #F9FAFB; }
        .low-conf { color: #B45309; font-weight: 600; }
        .high-conf { color: #166534; }
        .prog { height: 8px; background: #E5E7EB; border-radius: 4px; overflow: hidden; margin: 10px 0 20px; }
        .prog > div { height: 100%; background: linear-gradient(90deg, #0F766E, #0F3D5C); transition: width 0.3s; }
      "))),
      shiny::h2("acR - Classificacao em tempo real"),
      shiny::div(class = "prog", shiny::div(style = "width: 0%", id = "bar")),
      shiny::textOutput("summary"),
      shiny::tags$br(),
      shiny::tableOutput("live_tbl")
    ),
    server = function(input, output, session) {
      auto_tick <- shiny::reactiveTimer(500, session)

      output$summary <- shiny::renderText({
        auto_tick()
        n <- length(shared_env$rows)
        pct <- round(100 * n / n_docs)
        session$sendCustomMessage("bar", pct)
        sprintf("Documento %d de %d (%d%%)%s",
                n, n_docs, pct,
                if (shared_env$done) " - concluido" else " - em andamento...")
      })

      output$live_tbl <- shiny::renderTable({
        auto_tick()
        rows <- shared_env$rows
        if (length(rows) == 0L) return(NULL)
        do.call(rbind, lapply(rev(rows), function(r) data.frame(
          doc = r$doc_id,
          categoria = r$categoria,
          confidence = round(r$confidence, 2),
          reasoning = r$reasoning,
          stringsAsFactors = FALSE
        )))
      }, striped = TRUE)

      session$sendCustomMessage("progress_js", "true")
      shiny::insertUI("head", where = "beforeEnd", ui = shiny::tags$script(shiny::HTML("
        Shiny.addCustomMessageHandler('bar', function(pct) {
          document.getElementById('bar').style.width = pct + '%';
        });
      ")))
    }
  )
}


#' @keywords internal
#' @noRd
.ac_live_shiny_launch <- function(app) {
  if (is.null(app)) return(NULL)
  # roda em processo separado para nao bloquear a classificacao
  if (requireNamespace("callr", quietly = TRUE)) {
    tryCatch(
      callr::r_bg(function(a) shiny::runGadget(a, viewer = shiny::browserViewer()),
                  args = list(a = app)),
      error = function(e) {
        cli::cli_warn("Nao foi possivel iniciar Shiny em background: {conditionMessage(e)}")
        NULL
      }
    )
  } else {
    cli::cli_warn("Pacote {.pkg callr} necessario para Shiny live em background.")
    NULL
  }
}
