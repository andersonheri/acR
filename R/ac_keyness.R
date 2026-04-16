#' Calcular estatisticas de keyness entre dois grupos
#'
#' @description
#' `ac_keyness()` calcula estatisticas de "keyness" para comparar a
#' distribuicao de termos entre dois grupos (por exemplo, governo vs
#' oposicao, partidos, periodos). A funcao e inspirada em
#' [`quanteda.textstats::textstat_keyness()`] e utiliza tabelas 2x2 por
#' termo.
#'
#' A entrada tipica e uma tabela de frequencias gerada por
#' [`ac_count()`], agregada por uma coluna de grupo:
#' - `ac_count(corp, by = "lado")` seguido de
#' - `ac_keyness(freq, group = "lado", target = "Governo")`.
#'
#' @param x Um `data.frame` ou [`tibble::tibble()`] contendo, no minimo,
#'   as colunas `token`, `n` e uma coluna de grupo.
#' @param group Nome da coluna em `x` que identifica os grupos (string).
#'   Essa coluna deve possuir exatamente dois valores distintos.
#' @param target Valor de `group` que sera considerado o grupo alvo
#'   (por exemplo, `"Governo"`). O outro valor sera tratado como grupo
#'   de referencia.
#' @param measure Estatistica de keyness a ser usada. Pode ser `"chi2"`
#'   (padrao) para qui-quadrado com 1 grau de liberdade, ou `"ll"` para
#'   log-likelihood (G^2).
#' @param sort Logico. Se `TRUE` (padrao), ordena a saida por `keyness`
#'   em ordem decrescente (termos mais caracteristicos do grupo alvo no
#'   topo).
#'
#' @return Um [`tibble::tibble()`] com uma linha por termo, contendo:
#'   - `token`
#'   - `group` (nome da coluna de grupo, repetido para referencia)
#'   - `target`, `reference`
#'   - `n_target`, `n_reference`
#'   - `total_target`, `total_reference`
#'   - `keyness` (estatistica assinada, positiva quando o termo e mais
#'     frequente no grupo alvo, negativa quando e mais frequente no
#'     grupo de referencia)
#'   - `direction` (nome do grupo em que o termo e relativamente mais
#'     frequente)
#'
#' @details
#' Para cada termo, a funcao constroi uma tabela 2x2:
#' - `a = n_target` (frequencia do termo no grupo alvo)
#' - `b = n_reference` (frequencia do termo no grupo de referencia)
#' - `c = total_target - a`
#' - `d = total_reference - b`
#'
#' Em seguida, calcula:
#' - qui-quadrado com 1 g.l. na opcao `measure = "chi2"`;
#' - log-likelihood ratio (G^2) na opcao `measure = "ll"`.
#'
#' Em ambos os casos, a estatistica e multiplicada pelo sinal da
#' diferenca de frequencias relativas `(a / total_target - b / total_reference)`,
#' de forma que valores positivos indiquem termos mais caracteristicos
#' do grupo alvo e valores negativos termos mais caracteristicos do
#' grupo de referencia.
#'
#' @examples
#' df <- data.frame(
#'   id    = c("d1", "d2", "d3", "d4"),
#'   texto = c(
#'     "A A A B",
#'     "A B",
#'     "A B B B",
#'     "B B C"
#'   ),
#'   lado  = c("Governo", "Governo", "Oposicao", "Oposicao"),
#'   stringsAsFactors = FALSE
#' )
#'
#' corp <- ac_corpus(df, text = texto, docid = id, meta = lado)
#' freq <- ac_count(corp, by = "lado")
#'
#' key <- ac_keyness(freq, group = "lado", target = "Governo")
#'
#' @seealso [ac_count()], [ac_top_terms()], [ac_tf_idf()]
#' @concept corpus
#' @export
ac_keyness <- function(
    x,
    group,
    target,
    measure = c("chi2", "ll"),
    sort = TRUE
) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} deve ser um data.frame ou tibble.")
  }
  
  if (!all(c("token", "n") %in% names(x))) {
    cli::cli_abort(
      "{.arg x} deve conter, no minimo, as colunas {.field token} e {.field n}."
    )
  }
  
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg dplyr} e necessario.",
      "i" = "Instale com {.code install.packages(\"dplyr\")}."
    ))
  }
  
  if (!requireNamespace("rlang", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg rlang} e necessario.",
      "i" = "Instale com {.code install.packages(\"rlang\")}."
    ))
  }
  
  measure <- match.arg(measure, c("chi2", "ll"))
  
  if (!is.character(group) || length(group) != 1L) {
    cli::cli_abort("{.arg group} deve ser um unico nome de coluna (string).")
  }
  
  if (!group %in% names(x)) {
    cli::cli_abort(c(
      "{.arg group} contem um nome que nao existe em {.arg x}.",
      "x" = "Nome ausente: {.val {group}}"
    ))
  }
  
  g_vals <- unique(x[[group]])
  if (length(g_vals) != 2L) {
    cli::cli_abort(c(
      "{.arg group} deve identificar exatamente dois grupos distintos.",
      "x" = "Foram encontrados {.val {length(g_vals)}} grupos."
    ))
  }
  
  if (!target %in% g_vals) {
    cli::cli_abort(c(
      "{.arg target} deve ser um dos valores de {.arg group}.",
      "x" = "Valores disponiveis: {.val {g_vals}}"
    ))
  }
  
  reference <- setdiff(g_vals, target)
  reference <- reference[[1L]]
  
  grp_sym <- rlang::sym(group)
  
  # frequencias por token e grupo (garantia)
  freq_token <- x |>
    dplyr::group_by(token, !!grp_sym) |>
    dplyr::summarise(n = sum(n), .groups = "drop")
  
  # totais de tokens por grupo
  totals <- freq_token |>
    dplyr::group_by(!!grp_sym) |>
    dplyr::summarise(total = sum(n), .groups = "drop")
  
  total_target <- totals$total[totals[[group]] == target]
  total_ref    <- totals$total[totals[[group]] == reference]
  
  # frequencias por termo em cada grupo (preenchendo zeros)
  freq_target <- freq_token |>
    dplyr::filter(!!grp_sym == target) |>
    dplyr::select(token, n_target = n)
  
  freq_ref <- freq_token |>
    dplyr::filter(!!grp_sym == reference) |>
    dplyr::select(token, n_reference = n)
  
  freq_all <- dplyr::full_join(freq_target, freq_ref, by = "token") |>
    dplyr::mutate(
      n_target    = dplyr::coalesce(n_target, 0L),
      n_reference = dplyr::coalesce(n_reference, 0L)
    )
  
  a <- as.numeric(freq_all$n_target)
  b <- as.numeric(freq_all$n_reference)
  c <- as.numeric(total_target - a)
  d <- as.numeric(total_ref - b)
  
  # proteger contra denominadores zero
  valid <- (a + b > 0) & (c + d > 0) &
    (a + c > 0) & (b + d > 0)
  
  key <- rep(NA_real_, length(a))
  
  if (measure == "chi2") {
    num <- (a * d - b * c)^2 * (total_target + total_ref)
    den <- (a + b) * (c + d) * (a + c) * (b + d)
    chi2 <- rep(0, length(a))
    chi2[valid] <- num[valid] / den[valid]
    key_raw <- chi2
  } else {
    # log-likelihood (G^2)
    N  <- total_target + total_ref
    E1 <- (a + b) * total_target / N
    E2 <- (a + b) * total_ref    / N
    E3 <- (c + d) * total_target / N
    E4 <- (c + d) * total_ref    / N
    
    term1 <- ifelse(a > 0 & E1 > 0, a * log(a / E1), 0)
    term2 <- ifelse(b > 0 & E2 > 0, b * log(b / E2), 0)
    term3 <- ifelse(c > 0 & E3 > 0, c * log(c / E3), 0)
    term4 <- ifelse(d > 0 & E4 > 0, d * log(d / E4), 0)
    
    ll <- rep(0, length(a))
    ll[valid] <- 2 * (term1[valid] + term2[valid] + term3[valid] + term4[valid])
    key_raw <- ll
  }
  
  # sinal baseado em frequencias relativas
  rel_diff <- (a / total_target) - (b / total_ref)
  sign_dir <- sign(rel_diff)
  key[valid] <- key_raw[valid] * sign_dir[valid]
  
  direction <- ifelse(rel_diff >= 0, target, reference)
  
  out <- tibble::tibble(
    token          = freq_all$token,
    group          = group,
    target         = target,
    reference      = reference,
    n_target       = a,
    n_reference    = b,
    total_target   = as.numeric(total_target),
    total_reference= as.numeric(total_ref),
    keyness        = key,
    direction      = direction
  )
  
  if (sort) {
    out <- dplyr::arrange(out, dplyr::desc(keyness))
  }
  
  out
}
