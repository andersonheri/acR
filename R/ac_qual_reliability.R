#' Calcular confiabilidade entre codificação LLM e humana
#'
#' @description
#' `ac_qual_reliability()` calcula métricas de concordância entre a
#' classificação feita pela LLM e uma classificação humana de referência,
#' com intervalos de confiança via bootstrap.
#'
#' @param llm Tibble com classificação LLM, saída de [ac_qual_code()].
#' @param human Tibble com classificação humana, saída de
#'   [ac_qual_import_human()].
#' @param cat_col Nome da coluna de categoria. Padrão: `"categoria"`.
#' @param metrics Vetor de métricas a calcular. Padrão:
#'   `c("krippendorff", "gwet_ac1", "f1_macro", "percent_agreement")`.
#' @param bootstrap Número de amostras bootstrap para IC. Padrão: `1000`.
#' @param ci_level Nível de confiança do IC. Padrão: `0.95`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas: `metric`, `estimate`, `ci_lower`, `ci_upper`,
#'   `interpretation`.
#'
#' @references
#' Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
#' Methodology* (4th ed.). SAGE.
#'
#' Gwet, K. L. (2014). *Handbook of Inter-Rater Reliability* (4th ed.).
#' Advanced Analytics.
#'
#' Landis, J. R.; Koch, G. G. (1977). The Measurement of Observer Agreement
#' for Categorical Data. *Biometrics*, 33(1), 159-174.
#'
#' @examples
#' \dontrun{
#' rel <- ac_qual_reliability(llm = coded, human = humano_df)
#' print(rel)
#' }
#'
#' @concept qualitative
#' @export
ac_qual_reliability <- function(llm,
                                 human,
                                 cat_col   = "categoria",
                                 metrics   = c("krippendorff", "gwet_ac1",
                                               "f1_macro", "percent_agreement"),
                                 bootstrap = 1000L,
                                 ci_level  = 0.95,
                                 ...) {

  if (!is.data.frame(llm) || !cat_col %in% names(llm)) {
    cli::cli_abort(c(
      "{.arg llm} deve ser um tibble com coluna {.val {cat_col}}.",
      "i" = "Use a sa\u00edda de {.fn ac_qual_code}."
    ))
  }
  if (!is.data.frame(human) || !cat_col %in% names(human)) {
    cli::cli_abort(c(
      "{.arg human} deve ser um tibble com coluna {.val {cat_col}}.",
      "i" = "Use a sa\u00edda de {.fn ac_qual_import_human}."
    ))
  }

  # Alinhar por doc_id
  joined <- dplyr::inner_join(
    llm   |> dplyr::select("doc_id", llm_cat   = dplyr::all_of(cat_col)),
    human |> dplyr::select("doc_id", human_cat = dplyr::all_of(cat_col)),
    by = "doc_id"
  )

  if (nrow(joined) == 0L) {
    cli::cli_abort("Nenhum documento em comum entre {.arg llm} e {.arg human}.")
  }

  n_common <- nrow(joined)
  cli::cli_inform("Calculando confiabilidade em {n_common} documentos comuns...")

  llm_vec   <- joined$llm_cat
  human_vec <- joined$human_cat

  results_list <- list()

  # Percent agreement
  if ("percent_agreement" %in% metrics) {
    pa    <- mean(llm_vec == human_vec, na.rm = TRUE)
    pa_ci <- .ac_bootstrap_metric(
      llm_vec, human_vec, bootstrap, ci_level,
      function(l, h) mean(l == h, na.rm = TRUE)
    )
    results_list[["percent_agreement"]] <- tibble::tibble(
      metric         = "percent_agreement",
      estimate       = pa,
      ci_lower       = pa_ci[1],
      ci_upper       = pa_ci[2],
      interpretation = .ac_interpret_agreement(pa, "percent")
    )
  }

  # Krippendorff alpha
  if ("krippendorff" %in% metrics) {
    if (!requireNamespace("irr", quietly = TRUE)) {
      cli::cli_warn("{.pkg irr} n\u00e3o instalado. Pulando Krippendorff \u03b1.")
    } else {
      mat   <- rbind(llm_vec, human_vec)
      alpha <- tryCatch(
        irr::kripp.alpha(mat, method = "nominal")$value,
        error = function(e) NA_real_
      )
      alpha_ci <- if (!is.na(alpha)) {
        .ac_bootstrap_metric(llm_vec, human_vec, bootstrap, ci_level,
          function(l, h) {
            tryCatch(
              irr::kripp.alpha(rbind(l, h), method = "nominal")$value,
              error = function(e) NA_real_
            )
          }
        )
      } else c(NA_real_, NA_real_)

      results_list[["krippendorff"]] <- tibble::tibble(
        metric         = "krippendorff_alpha",
        estimate       = alpha,
        ci_lower       = alpha_ci[1],
        ci_upper       = alpha_ci[2],
        interpretation = .ac_interpret_agreement(alpha, "kappa")
      )
    }
  }

  # Gwet AC1

  # Gwet AC1 — implementacao propria (Gwet, 2014)
  if ("gwet_ac1" %in% metrics) {
    gwet <- .ac_gwet_ac1(llm_vec, human_vec)
    gwet_ci <- if (!is.na(gwet)) {
      .ac_bootstrap_metric(llm_vec, human_vec, bootstrap, ci_level,
        function(l, h) .ac_gwet_ac1(l, h)
      )
    } else c(NA_real_, NA_real_)

    results_list[["gwet_ac1"]] <- tibble::tibble(
      metric         = "gwet_ac1",
      estimate       = gwet,
      ci_lower       = gwet_ci[1],
      ci_upper       = gwet_ci[2],
      interpretation = .ac_interpret_agreement(gwet, "kappa")
    )
  }

  # F1 macro
  if ("f1_macro" %in% metrics) {
    f1 <- .ac_compute_f1_macro(llm_vec, human_vec)
    f1_ci <- .ac_bootstrap_metric(llm_vec, human_vec, bootstrap, ci_level,
      function(l, h) .ac_compute_f1_macro(l, h)
    )
    results_list[["f1_macro"]] <- tibble::tibble(
      metric         = "f1_macro",
      estimate       = f1,
      ci_lower       = f1_ci[1],
      ci_upper       = f1_ci[2],
      interpretation = .ac_interpret_agreement(f1, "f1")
    )
  }

  result <- dplyr::bind_rows(results_list)

  cli::cli_inform(c(
    "i" = "Interpreta\u00e7\u00e3o baseada em Landis & Koch (1977) e Gwet (2014).",
    "i" = "IC {ci_level*100}% via bootstrap (n = {bootstrap})."
  ))

  result
}


#' Amostrar documentos para validação humana
#'
#' @description
#' `ac_qual_sample()` seleciona uma amostra de documentos classificados pela
#' LLM para validação por um codificador humano, usando diferentes estratégias
#' para maximizar a eficiência da validação.
#'
#' @param coded Tibble com classificação LLM, saída de [ac_qual_code()].
#' @param n Número de documentos a amostrar. Padrão: `50`.
#' @param strategy Estratégia de amostragem:
#'   * `"uncertainty"`: prioriza documentos com menor `confidence_score`
#'     (maior incerteza da LLM);
#'   * `"stratified"`: garante representação proporcional de todas as
#'     categorias;
#'   * `"random"`: amostra aleatória simples;
#'   * `"disagreement"`: prioriza documentos onde rodadas de self-consistency
#'     divergiram (requer `confidence_score < 1`).
#' @param seed Semente para reprodutibilidade. Padrão: `42`.
#' @param ... Ignorado.
#'
#' @return Tibble com os documentos selecionados, incluindo uma coluna
#'   `sample_reason` indicando por que cada documento foi selecionado.
#'
#' @concept qualitative
#' @export
ac_qual_sample <- function(coded,
                            n        = 50L,
                            strategy = c("uncertainty", "stratified",
                                         "random", "disagreement"),
                            seed     = 42L,
                            ...) {

  if (!is.data.frame(coded)) {
    cli::cli_abort("{.arg coded} deve ser um tibble, sa\u00edda de {.fn ac_qual_code}.")
  }

  strategy <- match.arg(strategy)
  set.seed(seed)
  n <- min(as.integer(n), nrow(coded))

  if (strategy == "uncertainty") {
    if (!"confidence_score" %in% names(coded)) {
      cli::cli_warn(c(
        "Coluna {.val confidence_score} n\u00e3o encontrada.",
        "i" = "Usando amostragem aleat\u00f3ria."
      ))
      strategy <- "random"
    } else {
      result <- coded |>
        dplyr::arrange(confidence_score) |>
        dplyr::slice_head(n = n) |>
        dplyr::mutate(sample_reason = paste0(
          "uncertainty (confidence=",
          round(confidence_score, 2), ")"
        ))
    }
  }

  if (strategy == "stratified") {
    if (!"categoria" %in% names(coded)) {
      cli::cli_warn("Coluna {.val categoria} n\u00e3o encontrada. Usando aleat\u00f3rio.")
      strategy <- "random"
    } else {
      result <- coded |>
        dplyr::group_by(categoria) |>
        dplyr::slice_sample(
          n = ceiling(n / dplyr::n_groups(dplyr::group_by(coded, categoria)))
        ) |>
        dplyr::ungroup() |>
        dplyr::slice_sample(n = n) |>
        dplyr::mutate(sample_reason = paste0("stratified (cat=", categoria, ")"))
    }
  }

  if (strategy == "disagreement") {
    if (!"confidence_score" %in% names(coded)) {
      cli::cli_warn("Usando amostragem aleat\u00f3ria.")
      strategy <- "random"
    } else {
      result <- coded |>
        dplyr::filter(confidence_score < 1.0) |>
        dplyr::arrange(confidence_score) |>
        dplyr::slice_head(n = n) |>
        dplyr::mutate(sample_reason = "disagreement (self-consistency < 1.0)")
    }
  }

  if (strategy == "random") {
    result <- coded |>
      dplyr::slice_sample(n = n) |>
      dplyr::mutate(sample_reason = "random")
  }

  cli::cli_inform(c(
    "i" = "Amostra de {nrow(result)} documentos selecionada (estrat\u00e9gia: {.val {strategy}}).",
    "i" = "Use {.fn ac_qual_export_for_review} para exportar para Excel."
  ))

  result
}


#' Exportar amostra para revisão humana em Excel
#'
#' @description
#' `ac_qual_export_for_review()` exporta uma amostra de documentos classificados
#' para um arquivo Excel, com colunas para o codificador humano preencher.
#'
#' @param sample Tibble, saída de [ac_qual_sample()].
#' @param path Caminho do arquivo `.xlsx`. Padrão: `"validacao_humana.xlsx"`.
#' @param corpus Objeto `ac_corpus` original (opcional). Se fornecido, inclui
#'   o texto completo de cada documento na planilha.
#' @param ... Ignorado.
#'
#' @return Invisível: caminho do arquivo gerado.
#' @concept qualitative
#' @export
ac_qual_export_for_review <- function(sample,
                                       path   = "validacao_humana.xlsx",
                                       corpus = NULL,
                                       ...) {

  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg openxlsx} \u00e9 necess\u00e1rio.",
      "i" = "Instale com {.code install.packages(\"openxlsx\")}."
    ))
  }

  export_df <- sample

  # Adicionar texto completo se corpus fornecido
  if (!is.null(corpus) && is_ac_corpus(corpus)) {
    export_df <- export_df |>
      dplyr::left_join(
        corpus |> tibble::as_tibble() |> dplyr::select("doc_id", "text"),
        by = "doc_id"
      ) |>
      dplyr::relocate(text, .after = doc_id)
  }

  # Adicionar coluna em branco para o humano preencher
  export_df$categoria_humano <- ""
  export_df$notas_humano     <- ""

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "validacao")
  openxlsx::writeData(wb, "validacao", export_df)

  # Formatar cabeçalho
  header_style <- openxlsx::createStyle(
    fontColour = "#FFFFFF",
    fgFill     = "#0072B2",
    halign     = "CENTER",
    textDecoration = "Bold"
  )
  openxlsx::addStyle(wb, "validacao", header_style,
                     rows = 1, cols = 1:ncol(export_df))

  # Destacar colunas para preenchimento humano
  fill_cols <- which(names(export_df) %in% c("categoria_humano", "notas_humano"))
  fill_style <- openxlsx::createStyle(fgFill = "#FFF9C4")
  openxlsx::addStyle(wb, "validacao", fill_style,
                     rows = 2:(nrow(export_df) + 1),
                     cols = fill_cols,
                     gridExpand = TRUE)

  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)

  cli::cli_inform(c(
    "\u2705 Planilha exportada: {.path {path}}",
    "i" = "Preencha a coluna {.val categoria_humano} com a classifica\u00e7\u00e3o.",
    "i" = "Use {.fn ac_qual_import_human} para importar ap\u00f3s preenchimento."
  ))

  invisible(path)
}


#' Importar classificação humana de Excel
#'
#' @description
#' `ac_qual_import_human()` importa um arquivo Excel preenchido por um
#' codificador humano, retornando um tibble compatível com
#' [ac_qual_reliability()].
#'
#' @param path Caminho do arquivo `.xlsx`.
#' @param cat_col Nome da coluna com a classificação humana.
#'   Padrão: `"categoria_humano"`.
#' @param id_col Nome da coluna de identificador. Padrão: `"doc_id"`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas `doc_id` e `categoria`.
#' @concept qualitative
#' @export
ac_qual_import_human <- function(path,
                                  cat_col = "categoria_humano",
                                  id_col  = "doc_id",
                                  ...) {

  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg openxlsx} \u00e9 necess\u00e1rio.")
  }
  if (!file.exists(path)) {
    cli::cli_abort("Arquivo {.path {path}} n\u00e3o encontrado.")
  }

  df <- openxlsx::read.xlsx(path)

  if (!id_col %in% names(df)) {
    cli::cli_abort(c(
      "Coluna {.val {id_col}} n\u00e3o encontrada.",
      "i" = "Colunas dispon\u00edveis: {.val {names(df)}}."
    ))
  }
  if (!cat_col %in% names(df)) {
    cli::cli_abort(c(
      "Coluna {.val {cat_col}} n\u00e3o encontrada.",
      "i" = "Colunas dispon\u00edveis: {.val {names(df)}}."
    ))
  }

  result <- tibble::tibble(
    doc_id    = as.character(df[[id_col]]),
    categoria = as.character(df[[cat_col]])
  ) |>
    dplyr::filter(!is.na(categoria), nchar(categoria) > 0L)

  n_vazio <- nrow(df) - nrow(result)
  if (n_vazio > 0L) {
    cli::cli_warn("{n_vazio} linha(s) sem classifica\u00e7\u00e3o humana foram removidas.")
  }

  cli::cli_inform("\u2705 {nrow(result)} classifica\u00e7\u00f5es humanas importadas de {.path {path}}")
  result
}


# ============================================================================
# Auxiliares de confiabilidade
# ============================================================================

#' @keywords internal
#' @noRd
.ac_bootstrap_metric <- function(v1, v2, B, ci_level, fn) {
  n       <- length(v1)
  samples <- replicate(B, {
    idx <- sample(n, n, replace = TRUE)
    fn(v1[idx], v2[idx])
  })
  alpha <- 1 - ci_level
  stats::quantile(samples, c(alpha / 2, 1 - alpha / 2), na.rm = TRUE)
}

#' @keywords internal
#' @noRd
.ac_compute_f1_macro <- function(pred, true) {
  cats <- unique(c(pred, true))
  f1s  <- purrr::map_dbl(cats, function(cat) {
    tp <- sum(pred == cat & true == cat, na.rm = TRUE)
    fp <- sum(pred == cat & true != cat, na.rm = TRUE)
    fn <- sum(pred != cat & true == cat, na.rm = TRUE)
    if ((2 * tp + fp + fn) == 0L) return(NA_real_)
    (2 * tp) / (2 * tp + fp + fn)
  })
  mean(f1s, na.rm = TRUE)
}

#' @keywords internal
#' @noRd
.ac_interpret_agreement <- function(value, type = "kappa") {
  if (is.na(value)) return("n\u00e3o calculado")
  if (type == "percent") {
    dplyr::case_when(
      value >= 0.90 ~ "excelente (>= 90%)",
      value >= 0.80 ~ "boa (>= 80%)",
      value >= 0.70 ~ "aceit\u00e1vel (>= 70%)",
      TRUE          ~ "insuficiente (< 70%)"
    )
  } else {
    # Landis & Koch (1977) + Gwet (2014)
    dplyr::case_when(
      value >= 0.80 ~ "quase perfeita (Landis & Koch, 1977)",
      value >= 0.61 ~ "substancial (Landis & Koch, 1977)",
      value >= 0.41 ~ "moderada (Landis & Koch, 1977)",
      value >= 0.21 ~ "razo\u00e1vel (Landis & Koch, 1977)",
      TRUE          ~ "fraca (Landis & Koch, 1977)"
    )
  }
}

#' @keywords internal
#' @noRd
# Gwet AC1 — formula de Gwet (2014, cap. 3)
# Corrige o paradoxo do kappa quando categorias sao altamente prevalentes.
.ac_gwet_ac1 <- function(r1, r2) {
  # Remover NAs pareados
  ok  <- !is.na(r1) & !is.na(r2)
  r1  <- r1[ok]; r2 <- r2[ok]
  n   <- length(r1)
  if (n < 2L) return(NA_real_)
  cats <- unique(c(r1, r2))
  q   <- length(cats)
  if (q < 2L) return(NA_real_)
  # Proporcao observada de concordancia
  pa  <- mean(r1 == r2)
  # Proporcao esperada pelo acaso (Gwet AC1)
  pi_k <- sapply(cats, function(k) {
    (mean(r1 == k) + mean(r2 == k)) / 2
  })
  pe  <- (1 / (q - 1)) * sum(pi_k * (1 - pi_k))
  if (abs(1 - pe) < 1e-10) return(NA_real_)
  (pa - pe) / (1 - pe)
}
