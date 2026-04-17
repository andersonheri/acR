#' Calcula metricas de confiabilidade inter-anotador
#'
#' @description
#' Compara as classificacoes de dois ou mais anotadores (humanos ou LLMs) e
#' retorna metricas padronizadas de concordancia. Suporta Cohen's Kappa
#' (dois anotadores), Fleiss' Kappa (multi-anotador), Krippendorff's Alpha e
#' percentual de concordancia simples.
#'
#' A funcao aceita dois formatos de entrada: (a) dois data.frames com colunas
#' `id` e `categoria`, representando anotador 1 e anotador 2; ou (b) um unico
#' data.frame em formato largo com uma coluna por anotador.
#'
#' @param gold `data.frame`. Anotacoes de referencia (anotador humano ou
#'   gold standard). Deve conter colunas `id_discurso` (ou `id`) e `categoria`.
#' @param predicted `data.frame`. Anotacoes a comparar (ex.: saida do LLM via
#'   [ac_qual_code()]). Mesmas colunas exigidas.
#' @param method `character`. Metrica(s) a calcular. Opcoes: `"all"` (padrao),
#'   `"cohen_kappa"`, `"fleiss_kappa"`, `"krippendorff"`, `"percent_agreement"`.
#'   Aceita vetor de multiplas opcoes.
#' @param id_col `character`. Nome da coluna de identificador nos data.frames.
#'   Padrao: `"id_discurso"`.
#' @param cat_col `character`. Nome da coluna de categoria nos data.frames.
#'   Padrao: `"categoria"`.
#' @param weight `character`. Tipo de ponderacao para Cohen's Kappa:
#'   `"unweighted"` (padrao), `"linear"`, `"squared"`. Ignorado para
#'   categorias nominais sem ordem natural.
#' @param conf_level `numeric`. Nivel de confianca para intervalos (0-1).
#'   Padrao: `0.95`.
#' @param verbose `logical`. Se `TRUE` (padrao), imprime resumo formatado.
#'
#' @return Um objeto de classe `ac_irr` (lista) com os elementos:
#'   \describe{
#'     \item{`metrics`}{`data.frame` com colunas `metric`, `estimate`,
#'       `ci_lower`, `ci_upper`, `interpretation`.}
#'     \item{`confusion`}{`table`. Matriz de confusao entre os anotadores.}
#'     \item{`n_docs`}{`integer`. Numero de documentos comparados.}
#'     \item{`n_annotators`}{`integer`. Numero de anotadores.}
#'     \item{`categories`}{`character`. Categorias encontradas.}
#'     \item{`method`}{`character`. Metrica(s) calculadas.}
#'   }
#'
#' @details
#' ## Interpretacao do Kappa (Landis & Koch, 1977)
#' | Kappa       | Concordancia        |
#' |-------------|---------------------|
#' | < 0.00      | Pobre               |
#' | 0.00 - 0.20 | Leve                |
#' | 0.21 - 0.40 | Razoavel            |
#' | 0.41 - 0.60 | Moderada            |
#' | 0.61 - 0.80 | Substancial         |
#' | 0.81 - 1.00 | Quase perfeita      |
#'
#' ## Fleiss' Kappa
#' Extensao do Kappa de Cohen para mais de dois anotadores. Requer que
#' `predicted` contenha uma coluna por anotador adicional, ou que sejam
#' passados como lista via `...`.
#'
#' ## Krippendorff's Alpha
#' Metrica mais geral: funciona com qualquer numero de anotadores, lida com
#' dados faltantes e suporta escalas nominais, ordinais e de intervalo
#' (KRIPPENDORFF, 2018).
#'
#' @examples
#' \dontrun{
#' # Comparar LLM vs. anotador humano
#' humano <- data.frame(
#'   id_discurso = c("d1", "d2", "d3", "d4", "d5"),
#'   categoria   = c("progressista", "conservador", "tecnocratico",
#'                   "progressista", "conservador")
#' )
#'
#' llm <- data.frame(
#'   id_discurso = c("d1", "d2", "d3", "d4", "d5"),
#'   categoria   = c("progressista", "conservador", "progressista",
#'                   "progressista", "conservador")
#' )
#'
#' resultado <- ac_qual_irr(gold = humano, predicted = llm)
#' print(resultado)
#'
#' # So Cohen's Kappa
#' ac_qual_irr(humano, llm, method = "cohen_kappa")
#' }
#'
#' @references
#' KRIPPENDORFF, K. **Content Analysis: An Introduction to Its Methodology**.
#' 4. ed. Thousand Oaks: SAGE, 2018.
#'
#' LANDIS, J. R.; KOCH, G. G. The measurement of observer agreement for
#' categorical data. **Biometrics**, v. 33, n. 1, p. 159-174, 1977.
#'
#' @seealso [ac_qual_code()], [ac_qual_sample()]
#'
#' @importFrom stats qnorm
#' @export
ac_qual_irr <- function(
    gold,
    predicted,
    method     = "all",
    id_col     = "id_discurso",
    cat_col    = "categoria",
    weight     = "unweighted",
    conf_level = 0.95,
    verbose    = TRUE
) {
  # --- 0. Validar dependencias -------------------------------------------------
  .check_pkg("irr", "ac_qual_irr")

  # --- 1. Validar inputs -------------------------------------------------------
  .irr_check_df(gold,      "gold",      id_col, cat_col)
  .irr_check_df(predicted, "predicted", id_col, cat_col)

  method <- if ("all" %in% method) {
    c("percent_agreement", "cohen_kappa", "fleiss_kappa", "krippendorff")
  } else {
    match.arg(
      method,
      choices  = c("all", "cohen_kappa", "fleiss_kappa",
                   "krippendorff", "percent_agreement"),
      several.ok = TRUE
    )
  }

  weight <- match.arg(weight, c("unweighted", "linear", "squared"))

  # --- 2. Alinhar por ID -------------------------------------------------------
  merged <- merge(
    gold[, c(id_col, cat_col)],
    predicted[, c(id_col, cat_col)],
    by      = id_col,
    suffixes = c("_gold", "_pred")
  )

  if (nrow(merged) == 0) {
    cli::cli_abort(
      "Nenhum documento em comum entre {.arg gold} e {.arg predicted}. \\
       Verifique a coluna {.arg id_col} = {.val {id_col}}."
    )
  }

  if (nrow(merged) < nrow(gold)) {
    cli::cli_warn(
      "{nrow(gold) - nrow(merged)} documento(s) de {.arg gold} sem par em \\
       {.arg predicted}  excluidos do calculo."
    )
  }

  ratings_gold <- merged[[paste0(cat_col, "_gold")]]
  ratings_pred <- merged[[paste0(cat_col, "_pred")]]
  categories   <- sort(unique(c(ratings_gold, ratings_pred)))

  # Converter para inteiro (exigido por irr)
  cat_factor  <- factor(c(ratings_gold, ratings_pred), levels = categories)
  gold_int    <- as.integer(factor(ratings_gold, levels = categories))
  pred_int    <- as.integer(factor(ratings_pred, levels = categories))
  ratings_mat <- cbind(gold_int, pred_int)

  # --- 3. Calcular metricas ----------------------------------------------------
  results <- list()

  if ("percent_agreement" %in% method) {
    pa <- irr::agree(ratings_mat)
    results$percent_agreement <- data.frame(
      metric         = "Percent Agreement",
      estimate       = pa$value / 100,
      ci_lower       = NA_real_,
      ci_upper       = NA_real_,
      interpretation = .irr_interpret_pa(pa$value / 100),
      stringsAsFactors = FALSE
    )
  }

  if ("cohen_kappa" %in% method) {
    kw <- if (weight == "unweighted") "unweighted" else weight
    ck <- irr::kappa2(ratings_mat, weight = kw)
    ci <- .irr_kappa_ci(ck$value, ck$statistic, nrow(merged), conf_level)
    results$cohen_kappa <- data.frame(
      metric         = paste0("Cohen's Kappa (", weight, ")"),
      estimate       = ck$value,
      ci_lower       = ci[1],
      ci_upper       = ci[2],
      interpretation = .irr_interpret_kappa(ck$value),
      stringsAsFactors = FALSE
    )
  }

  if ("fleiss_kappa" %in% method) {
    fk <- irr::kappam.fleiss(ratings_mat)
    ci <- .irr_kappa_ci(fk$value, fk$statistic, nrow(merged), conf_level)
    results$fleiss_kappa <- data.frame(
      metric         = "Fleiss' Kappa",
      estimate       = fk$value,
      ci_lower       = ci[1],
      ci_upper       = ci[2],
      interpretation = .irr_interpret_kappa(fk$value),
      stringsAsFactors = FALSE
    )
  }

  if ("krippendorff" %in% method) {
    ka <- irr::kripp.alpha(t(ratings_mat), method = "nominal")
    results$krippendorff <- data.frame(
      metric         = "Krippendorff's Alpha (nominal)",
      estimate       = ka$value,
      ci_lower       = NA_real_,
      ci_upper       = NA_real_,
      interpretation = .irr_interpret_kappa(ka$value),
      stringsAsFactors = FALSE
    )
  }

  metrics_df <- do.call(rbind, results)
  rownames(metrics_df) <- NULL

  # --- 4. Matriz de confusao ---------------------------------------------------
  confusion <- table(
    Gold      = ratings_gold,
    Predicted = ratings_pred
  )

  # --- 5. Montar output --------------------------------------------------------
  out <- structure(
    list(
      metrics      = metrics_df,
      confusion    = confusion,
      n_docs       = nrow(merged),
      n_annotators = 2L,
      categories   = categories,
      method       = method
    ),
    class = "ac_irr"
  )

  if (verbose) print(out)
  invisible(out)
}


#' Print method for ac_irr objects
#'
#' @description
#' Prints a formatted summary of inter-rater reliability metrics,
#' including a metrics table and confusion matrix.
#'
#' @param x An object of class \code{ac_irr}.
#' @param ... Additional arguments (ignored).
#'
#' @return Invisibly returns \code{x}.
#'
#' @export
print.ac_irr <- function(x, ...) {
  cli::cli_h2("Confiabilidade inter-anotador (acR)")
  cli::cli_bullets(c(
    "*" = "Documentos comparados: {x$n_docs}",
    "*" = "Categorias: {paste(x$categories, collapse = ', ')}"
  ))
  cat("\n")

  # Formatar tabela de metricas
  df <- x$metrics
  df$estimate <- sprintf("%.3f", df$estimate)
  df$ci_lower <- ifelse(is.na(df$ci_lower), "", sprintf("%.3f", as.numeric(df$ci_lower)))
  df$ci_upper <- ifelse(is.na(df$ci_upper), "", sprintf("%.3f", as.numeric(df$ci_upper)))
  df$ic_95    <- paste0("[", df$ci_lower, ", ", df$ci_upper, "]")

  cat(format("Metrica",        width = 35),
      format("Estimativa", width = 12),
      format("IC 95%",     width = 18),
      "Interpretacao\n", sep = "")
  cat(strrep("-", 85), "\n")

  for (i in seq_len(nrow(df))) {
    cat(format(df$metric[i],         width = 35),
        format(df$estimate[i],       width = 12),
        format(df$ic_95[i],          width = 18),
        df$interpretation[i], "\n", sep = "")
  }

  cat("\nMatriz de confusao:\n")
  print(x$confusion)
  invisible(x)
}


# =============================================================================
# Helpers internos
# =============================================================================

#' @noRd
.irr_check_df <- function(df, arg, id_col, cat_col) {
  if (!is.data.frame(df)) {
    cli::cli_abort("{.arg {arg}} deve ser um data.frame.")
  }
  for (col in c(id_col, cat_col)) {
    if (!col %in% names(df)) {
      cli::cli_abort(
        "Coluna {.val {col}} nao encontrada em {.arg {arg}}. \\
         Use os argumentos {.arg id_col} e {.arg cat_col} para especificar \\
         os nomes corretos."
      )
    }
  }
}

#' Intervalo de confianca aproximado para Kappa via z-score
#' @noRd
.irr_kappa_ci <- function(kappa, z_stat, n, conf_level) {
  if (is.na(z_stat) || is.na(kappa) || n < 2) return(c(NA_real_, NA_real_))
  se    <- abs(kappa / z_stat)
  alpha <- 1 - conf_level
  z     <- qnorm(1 - alpha / 2)
  c(kappa - z * se, kappa + z * se)
}

#' Interpretacao do Kappa (Landis & Koch, 1977)
#' @noRd
.irr_interpret_kappa <- function(k) {
  if (is.na(k))    return("N/A")
  if (k < 0.00)    return("Pobre")
  if (k < 0.21)    return("Leve")
  if (k < 0.41)    return("Razoavel")
  if (k < 0.61)    return("Moderada")
  if (k < 0.81)    return("Substancial")
  return("Quase perfeita")
}

#' Interpretacao do percentual de concordancia
#' @noRd
.irr_interpret_pa <- function(p) {
  if (is.na(p))  return("N/A")
  if (p < 0.60)  return("Insuficiente")
  if (p < 0.70)  return("Aceitavel")
  if (p < 0.80)  return("Bom")
  if (p < 0.90)  return("Muito bom")
  return("Excelente")
}
