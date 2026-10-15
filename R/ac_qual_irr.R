#' Calcular métricas de confiabilidade inter-anotador
#'
#' @description
#' Compara as classificações de dois ou mais anotadores (humanos ou LLMs) e
#' retorna métricas padronizadas de concordância. Suporta Cohen's Kappa
#' (dois anotadores), Fleiss' Kappa (multi-anotador), Krippendorff's Alpha e
#' percentual de concordância simples.
#'
#' Complementa [ac_qual_reliability()]: aquela compara **um par** LLM ×
#' humano com bootstrap; esta é o motor genérico para **qualquer par ou
#' painel** de anotadores. Use-a diretamente quando você tem duas rodadas
#' humanas para calibrar entre codificadores antes de acender a LLM, ou
#' quando quer comparar LLMs entre si sobre a mesma amostra.
#'
#' A entrada são dois data.frames (anotador 1 e anotador 2), cada um com
#' uma coluna de identificador e uma de categoria, alinhados pelo
#' identificador.
#'
#' @param gold `data.frame`. Anotacoes de referência (anotador humano ou
#'   gold standard). Deve conter colunas `id_discurso` (ou `id`) e `categoria`.
#' @param predicted `data.frame`. Anotacoes a comparar (ex.: saida do LLM via
#'   [ac_qual_code()]). Mesmas colunas exigidas.
#' @param method `character`. Métrica(s) a calcular. Opcoes: `"all"` (padrao),
#'   `"cohen_kappa"`, `"fleiss_kappa"`, `"krippendorff"`, `"percent_agreement"`.
#'   Aceita vetor de múltiplas opcoes.
#' @param id_col `character`. Nome da coluna de identificador nos data.frames.
#'   Padrao: `"id_discurso"`.
#' @param cat_col `character`. Nome da coluna de categoria nos data.frames.
#'   Padrao: `"categoria"`.
#' @param weight `character`. Tipo de ponderação para Cohen's Kappa:
#'   `"unweighted"` (padrão), `"linear"` ou `"squared"` (Cohen, 1968).
#'   Os pesos só fazem sentido para categorias **ordinais**: a ordem usada
#'   é a dos níveis do fator em `gold[[cat_col]]` (se for fator) ou a
#'   ordem alfabética (caso contrário). Para categorias nominais, use
#'   `"unweighted"`.
#' @param conf_level `numeric`. Nivel de confianca para intervalos (0-1).
#'   Padrao: `0.95`.
#' @param bootstrap `integer`. Número de réplicas *bootstrap* (reamostragem
#'   de documentos) para os intervalos de confiança de Kappa, Fleiss e
#'   Alpha. Padrão: `1000`. Use `0` para não calcular IC.
#' @param verbose `logical`. Se `TRUE` (padrao), imprime resumo formatado.
#'
#' @return Um objeto de classe `ac_irr` (lista) com os elementos:
#'   \describe{
#'     \item{`metrics`}{`data.frame` com colunas `metric`, `estimate`,
#'       `ci_lower`, `ci_upper`, `interpretation`.}
#'     \item{`confusion`}{`table`. Matriz de confusao entre os anotadores.}
#'     \item{`n_docs`}{`integer`. Número de documentos comparados.}
#'     \item{`n_annotators`}{`integer`. Número de anotadores.}
#'     \item{`categories`}{`character`. Categorias encontradas.}
#'     \item{`method`}{`character`. Métrica(s) calculadas.}
#'   }
#'
#' @details
#' ## Interpretação do Kappa (Landis & Koch, 1977)
#' | Kappa       | Concordância        |
#' |-------------|---------------------|
#' | < 0.00      | Pobre               |
#' | 0.00 - 0.20 | Leve                |
#' | 0.21 - 0.40 | Razoável            |
#' | 0.41 - 0.60 | Moderada            |
#' | 0.61 - 0.80 | Substancial         |
#' | 0.81 - 1.00 | Quase perfeita      |
#'
#' Os próprios autores chamam essas faixas de arbitrárias (Landis & Koch,
#' 1977, p. 165): são rótulos de referência, não testes.
#'
#' ## Fleiss' Kappa
#' Generalização do kappa para vários anotadores (Fleiss, 1971). Com dois
#' anotadores, como aqui, ela supõe uma distribuição marginal comum aos
#' dois e por isso equivale ao *pi* de Scott, não ao kappa de Cohen; os
#' valores ficam próximos, mas não idênticos.
#'
#' ## Krippendorff's Alpha
#' Métrica mais geral: funciona com qualquer número de anotadores e lida
#' com dados faltantes (Krippendorff, 2018). Esta função calcula a versão
#' **nominal**. A interpretação segue Krippendorff (2018, sec. 12.4), não
#' Landis & Koch: alfa `>= 0,800` confiável; `0,667-0,800` só para
#' conclusões provisórias; `< 0,667` insuficiente.
#'
#' ## Percentual de concordância
#' Não corrige por acaso. Rótulos segundo Neuendorf (2017): `>= 0,90`
#' alta; `>= 0,80` aceitável na maioria dos casos; `>= 0,70` só em
#' estudos exploratórios; abaixo disso, insuficiente.
#'
#' ## Intervalos de confiança
#' Calculados por *bootstrap* percentil, reamostrando documentos com
#' reposição (Efron & Tibshirani, 1993). Uma versão anterior usava
#' `kappa / z` como erro-padrão, mas o `z` do `irr` é calculado **sob a
#' hipótese nula** (kappa = 0); esse erro-padrão não serve para IC em
#' torno do kappa estimado (Fleiss, Cohen & Everitt, 1969) e gerava
#' limites fora de \[-1, 1\].
#'
#' @examples
#' \donttest{
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
#' COHEN, J. Weighted kappa: nominal scale agreement with provision for
#' scaled disagreement or partial credit. **Psychological Bulletin**,
#' v. 70, n. 4, p. 213-220, 1968.
#'
#' EFRON, B.; TIBSHIRANI, R. J. **An Introduction to the Bootstrap**.
#' New York: Chapman & Hall, 1993.
#'
#' FLEISS, J. L. Measuring nominal scale agreement among many raters.
#' **Psychological Bulletin**, v. 76, n. 5, p. 378-382, 1971.
#'
#' FLEISS, J. L.; COHEN, J.; EVERITT, B. S. Large sample standard errors
#' of kappa and weighted kappa. **Psychological Bulletin**, v. 72, n. 5,
#' p. 323-327, 1969.
#'
#' NEUENDORF, K. A. **The Content Analysis Guidebook**. 2. ed. Thousand
#' Oaks: SAGE, 2017.
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
    verbose    = TRUE,
    bootstrap  = 1000L
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

  for (arg in c("gold", "predicted")) {
    ids <- get(arg)[[id_col]]
    if (anyDuplicated(ids)) {
      cli::cli_abort(
        "{.arg {arg}} tem {.arg id_col} duplicado ({.val {unique(ids[duplicated(ids)])}}): \\
         cada documento deve aparecer uma vez por anotador."
      )
    }
  }

  n_sem_par <- nrow(gold) + nrow(predicted) - 2L * nrow(merged)
  if (n_sem_par > 0L) {
    cli::cli_warn(
      "{n_sem_par} documento(s) sem par entre {.arg gold} e \\
       {.arg predicted} foram exclu\u00eddos do c\u00e1lculo."
    )
  }

  ratings_gold <- as.character(merged[[paste0(cat_col, "_gold")]])
  ratings_pred <- as.character(merged[[paste0(cat_col, "_pred")]])
  # Ordem das categorias: a dos niveis do fator, se houver (necessaria
  # para kappa ponderado em escala ordinal); senao, alfabetica.
  categories <- if (is.factor(gold[[cat_col]])) {
    union(levels(gold[[cat_col]]), sort(unique(stats::na.omit(c(ratings_gold, ratings_pred)))))
  } else {
    sort(unique(stats::na.omit(c(ratings_gold, ratings_pred))))
  }
  if (weight != "unweighted" && !is.factor(gold[[cat_col]])) {
    cli::cli_warn(c(
      "Kappa ponderado ({.val {weight}}) usando a ordem alfab\u00e9tica das categorias: {.val {categories}}.",
      "i" = "Se a escala \u00e9 ordinal, passe {.code gold[[cat_col]]} como fator com os n\u00edveis na ordem certa."
    ))
  }

  # Converter para inteiro (exigido por irr)
  gold_int    <- as.integer(factor(ratings_gold, levels = categories))
  pred_int    <- as.integer(factor(ratings_pred, levels = categories))
  ratings_mat <- cbind(gold_int, pred_int)

  # IC bootstrap percentil: reamostra documentos (linhas) com reposicao.
  boot_ci <- function(stat_fn) {
    if (is.null(bootstrap) || bootstrap < 1L) return(c(NA_real_, NA_real_))
    .ac_bootstrap_metric(gold_int, pred_int, as.integer(bootstrap), conf_level,
                         function(a, b) {
                           # Reamostras degeneradas (ex.: uma so categoria)
                           # fazem o irr calcular o z interno com 0/0 e
                           # avisar "NaNs produced"; o z nao e usado aqui.
                           tryCatch(suppressWarnings(stat_fn(cbind(a, b))),
                                    error = function(e) NA_real_)
                         })
  }

  # --- 3. Calcular metricas ----------------------------------------------------
  results <- list()

  if ("percent_agreement" %in% method) {
    pa <- irr::agree(ratings_mat)
    results$percent_agreement <- data.frame(
      metric         = "Percent Agreement",
      estimate       = pa$value / 100,
      ci_lower       = NA_real_,
      ci_upper       = NA_real_,
      interpretation = .ac_interpret_agreement(pa$value / 100, "percent"),
      stringsAsFactors = FALSE
    )
  }

  if ("cohen_kappa" %in% method) {
    # irr::kappa2 chama os pesos lineares de "equal"
    kw <- switch(weight, unweighted = "unweighted", linear = "equal", squared = "squared")
    ck <- irr::kappa2(ratings_mat, weight = kw)
    ci <- boot_ci(function(m) irr::kappa2(m, weight = kw)$value)
    results$cohen_kappa <- data.frame(
      metric         = paste0("Cohen's Kappa (", weight, ")"),
      estimate       = ck$value,
      ci_lower       = ci[1],
      ci_upper       = ci[2],
      interpretation = .ac_landis_koch(ck$value, citar = TRUE),
      stringsAsFactors = FALSE
    )
  }

  if ("fleiss_kappa" %in% method) {
    fk <- irr::kappam.fleiss(ratings_mat)
    ci <- boot_ci(function(m) irr::kappam.fleiss(m)$value)
    results$fleiss_kappa <- data.frame(
      metric         = "Fleiss' Kappa",
      estimate       = fk$value,
      ci_lower       = ci[1],
      ci_upper       = ci[2],
      interpretation = .ac_landis_koch(fk$value, citar = TRUE),
      stringsAsFactors = FALSE
    )
  }

  if ("krippendorff" %in% method) {
    ka <- irr::kripp.alpha(t(ratings_mat), method = "nominal")
    ci <- boot_ci(function(m) irr::kripp.alpha(t(m), method = "nominal")$value)
    results$krippendorff <- data.frame(
      metric         = "Krippendorff's Alpha (nominal)",
      estimate       = ka$value,
      ci_lower       = ci[1],
      ci_upper       = ci[2],
      interpretation = .ac_interpret_agreement(ka$value, "alpha"),
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
#' @keywords internal
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
      format("IC",         width = 18),
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
