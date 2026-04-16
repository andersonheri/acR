#' Verificar se um objeto é um corpus do `acR`
#'
#' @description
#' Função auxiliar para testar se um objeto pertence à classe `ac_corpus`.
#' Útil para validação de argumentos em funções do pipeline.
#'
#' @param x Objeto qualquer a ser testado.
#'
#' @return `TRUE` se `x` é um objeto de classe `ac_corpus`, `FALSE` caso
#'   contrário.
#'
#' @examples
#' corpus <- ac_corpus(c("Texto um.", "Texto dois."))
#' is_ac_corpus(corpus)         # TRUE
#' is_ac_corpus(data.frame())   # FALSE
#' is_ac_corpus("texto solto")  # FALSE
#'
#' @concept corpus
#' @export
is_ac_corpus <- function(x) {
  inherits(x, "ac_corpus")
}
