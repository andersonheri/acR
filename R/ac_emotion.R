#' Classificar emoções com um léxico de palavra-emoção
#'
#' @description
#' `ac_emotion()` conta, por documento, quantas palavras caem em cada
#' categoria de emoção de um léxico fornecido pelo usuário — indo além
#' da polaridade binária de [ac_sentiment()] para distinguir, por
#' exemplo, se um texto negativo expressa raiva, medo ou tristeza
#' (Mohammad & Turney, 2013, propuseram essa distinção no NRC Emotion
#' Lexicon, hoje o léxico de emoções mais usado em inglês).
#'
#' O pacote **não distribui** um léxico de emoções em português: o NRC
#' Emotion Lexicon original é em inglês e sua tradução/adaptação para
#' português está sujeita aos termos de licença do léxico de origem, que
#' o usuário deve obter e licenciar por conta própria (o NRC é gratuito
#' para pesquisa, mas não redistribuível livremente dentro de outro
#' pacote). `ac_emotion()` é agnóstica ao léxico: funciona com qualquer
#' tabela palavra→emoção que você tenha — o NRC traduzido, um léxico
#' doméstico, ou uma lista construída à mão para um domínio específico
#' (ex.: emoções em avaliações de atendimento ao cliente).
#'
#' Internamente, é uma camada sobre [ac_dictionary()]: converte o léxico
#' em formato longo (uma linha por palavra-emoção) para o formato de
#' dicionário multi-categoria e aplica a mesma contagem.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param lexicon Tibble/data.frame em formato longo com colunas de
#'   palavra e emoção (ver `term_col`/`emotion_col`). Uma palavra pode
#'   aparecer em mais de uma linha (associada a mais de uma emoção).
#' @param term_col Nome da coluna de palavra em `lexicon`. Padrão:
#'   `"termo"`.
#' @param emotion_col Nome da coluna de emoção em `lexicon`. Padrão:
#'   `"emocao"`.
#' @param by Coluna(s) de agrupamento adicional. Padrão: `NULL`.
#'
#' @return Tibble no mesmo formato de [ac_dictionary()]: `total_tokens`
#'   e, para cada emoção presente em `lexicon`, colunas `<emocao>_n` e
#'   `<emocao>_prop`.
#'
#' @references
#' Mohammad, S. M.; Turney, P. D. (2013). Crowdsourcing a Word-Emotion
#' Association Lexicon. *Computational Intelligence*, 29(3), 436-465.
#'
#' @examples
#' # Lexico de emocao minimo, construido a mao para este exemplo
#' # (em uso real, substitua por um lexico de emocoes licenciado em PT)
#' lexico <- data.frame(
#'   termo  = c("alegria", "feliz", "medo", "assustado", "raiva", "furioso"),
#'   emocao = c("alegria", "alegria", "medo", "medo", "raiva", "raiva"),
#'   stringsAsFactors = FALSE
#' )
#'
#' df <- data.frame(
#'   id = paste0("d", 1:3),
#'   texto = c(
#'     "fiquei muito feliz com a alegria do momento",
#'     "fiquei assustado, senti muito medo da situacao",
#'     "fiquei furioso, aquela raiva nao passava"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' ac_emotion(corpus, lexicon = lexico)
#'
#' @seealso [ac_dictionary()], [ac_sentiment()]
#' @concept quantitative
#' @export
ac_emotion <- function(corpus,
                        lexicon,
                        term_col    = "termo",
                        emotion_col = "emocao",
                        by = NULL) {
  if (!is.data.frame(lexicon)) {
    cli::cli_abort("{.arg lexicon} deve ser um data.frame/tibble.")
  }
  if (!all(c(term_col, emotion_col) %in% names(lexicon))) {
    cli::cli_abort(c(
      "{.arg lexicon} deve conter as colunas {.val {term_col}} e {.val {emotion_col}}.",
      "i" = "Colunas dispon\u00edveis: {.val {names(lexicon)}}."
    ))
  }

  dictionary <- ac_dictionary_import(
    lexicon,
    term_col     = term_col,
    category_col = emotion_col
  )

  ac_dictionary(corpus, dictionary, by = by)
}
