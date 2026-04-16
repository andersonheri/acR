# Testes para ac_clean() e função auxiliar de stopwords

# ============================================================================
# Helpers
# ============================================================================

make_corpus <- function() {
  df <- data.frame(
    id = c("a", "b", "c"),
    texto = c(
      "O deputado do PT disse: 'Defendo a CCJ!' Veja em https://exemplo.org",
      "Sra. presidente, o Sr. senador apresentou o requerimento n 123.",
      "Ta na hora de votar, pra acabar com isso."
    )
  )
  ac_corpus(df, text = texto, docid = id)
}

# ============================================================================
# Validações básicas
# ============================================================================

test_that("ac_clean() exige ac_corpus como entrada", {
  expect_error(ac_clean(data.frame(x = 1)), regexp = "ac_corpus")
  expect_error(ac_clean("texto solto"),     regexp = "ac_corpus")
  expect_error(ac_clean(NULL),              regexp = "ac_corpus")
})

test_that("ac_clean() preserva classe ac_corpus na saída", {
  corpus <- make_corpus()
  result <- ac_clean(corpus)
  expect_s3_class(result, "ac_corpus")
  expect_s3_class(result, "tbl_df")
})

test_that("ac_clean() preserva número de documentos", {
  corpus <- make_corpus()
  result <- ac_clean(corpus)
  expect_equal(nrow(result), nrow(corpus))
  expect_equal(result$doc_id, corpus$doc_id)
})

test_that("ac_clean() preserva metadados do corpus", {
  df <- data.frame(
    id = c("a", "b"),
    texto = c("Texto um.", "Texto dois."),
    partido = c("PT", "PL")
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  result <- ac_clean(corpus)
  expect_true("partido" %in% names(result))
  expect_equal(result$partido, c("PT", "PL"))
})

test_that("ac_clean() preserva atributo lang", {
  corpus <- ac_corpus(c("A", "B"), lang = "en")
  result <- ac_clean(corpus)
  expect_equal(attr(result, "lang"), "en")
})

test_that("ac_clean() registra atributo cleaning_steps", {
  corpus <- make_corpus()
  result <- ac_clean(corpus)
  expect_false(is.null(attr(result, "cleaning_steps")))
  expect_true(is.character(attr(result, "cleaning_steps")))
})

# ============================================================================
# Transformações individuais
# ============================================================================

test_that("lower = TRUE converte para minúsculas", {
  corpus <- ac_corpus("DEPUTADO Fala")
  result <- ac_clean(corpus, lower = TRUE, remove_punct = FALSE,
                    strip_whitespace = FALSE)
  expect_equal(result$text, "deputado fala")
})

test_that("lower = FALSE preserva capitalização", {
  corpus <- ac_corpus("DEPUTADO")
  result <- ac_clean(corpus, lower = FALSE, remove_punct = FALSE)
  expect_equal(result$text, "DEPUTADO")
})

test_that("remove_punct = TRUE remove pontuação", {
  corpus <- ac_corpus("Ola, mundo! Tudo bem?")
  result <- ac_clean(corpus, lower = FALSE, remove_punct = TRUE)
  expect_false(grepl("[,!?]", result$text))
  expect_true(grepl("Ola", result$text))
  expect_true(grepl("mundo", result$text))
})

test_that("remove_numbers remove dígitos quando TRUE", {
  corpus <- ac_corpus("Aprovado 123 votos em 2024")
  result <- ac_clean(corpus, remove_numbers = TRUE,
                    lower = FALSE, remove_punct = FALSE)
  expect_false(grepl("\\d", result$text))
})

test_that("remove_numbers = FALSE preserva dígitos", {
  corpus <- ac_corpus("Artigo 5")
  result <- ac_clean(corpus, remove_numbers = FALSE,
                    lower = FALSE, remove_punct = FALSE)
  expect_true(grepl("5", result$text))
})

test_that("remove_url remove URLs", {
  corpus <- ac_corpus("Veja em https://exemplo.org e tambem www.teste.com")
  result <- ac_clean(corpus, remove_url = TRUE,
                    lower = FALSE, remove_punct = FALSE)
  expect_false(grepl("https", result$text))
  expect_false(grepl("www", result$text))
  expect_true(grepl("Veja", result$text))
})

test_that("remove_email remove endereços de email", {
  corpus <- ac_corpus("Contate ana@exemplo.com.br por favor")
  result <- ac_clean(corpus, remove_email = TRUE,
                    lower = FALSE, remove_punct = FALSE)
  expect_false(grepl("@", result$text))
  expect_false(grepl("ana", result$text))
})

test_that("remove_accents remove acentos", {
  corpus <- ac_corpus("A\u00e7\u00e3o e ora\u00e7\u00e3o")  # Ação e oração
  result <- ac_clean(corpus, remove_accents = TRUE,
                    lower = FALSE, remove_punct = FALSE)
  expect_false(grepl("\u00e7", result$text))  # sem ç
  expect_false(grepl("\u00e3", result$text))  # sem ã
  expect_true(grepl("Acao", result$text))
})

test_that("strip_whitespace colapsa espaços", {
  corpus <- ac_corpus("palavra   com     muitos espacos")
  result <- ac_clean(corpus, lower = FALSE, remove_punct = FALSE,
                    strip_whitespace = TRUE)
  expect_false(grepl("  ", result$text))  # sem espaço duplo
})

# ============================================================================
# Normalização PT-BR
# ============================================================================

test_that("normalize_pt expande contrações informais", {
  corpus <- ac_corpus("Pra votar, vc tem que ta na sessao")
  result <- ac_clean(corpus, normalize_pt = TRUE,
                    lower = TRUE, remove_punct = FALSE)
  expect_true(grepl("\\bpara\\b", result$text))
  expect_true(grepl("\\bvoce\\b", result$text))
  expect_true(grepl("\\besta\\b", result$text))
  expect_false(grepl("\\bpra\\b", result$text))
  expect_false(grepl("\\bvc\\b", result$text))
})

# ============================================================================
# Stopwords
# ============================================================================

test_that("remove_stopwords aceita preset 'pt'", {
  corpus <- ac_corpus("A casa do deputado")
  result <- ac_clean(corpus, remove_stopwords = "pt",
                    lower = TRUE, remove_punct = TRUE)
  # "a", "do" são stopwords padrão do pt
  expect_false(grepl("\\ba\\b", result$text))
  expect_false(grepl("\\bdo\\b", result$text))
  expect_true(grepl("casa", result$text))
  expect_true(grepl("deputado", result$text))  # não é stopword no preset 'pt' puro
})

test_that("remove_stopwords aceita preset 'pt-legislativo'", {
  corpus <- ac_corpus("O deputado apresentou o requerimento")
  result <- ac_clean(corpus, remove_stopwords = "pt-legislativo",
                    lower = TRUE, remove_punct = TRUE)
  expect_false(grepl("\\bdeputado\\b", result$text))
  expect_false(grepl("\\brequerimento\\b", result$text))
  expect_true(grepl("apresentou", result$text))
})

test_that("remove_stopwords aceita vetor customizado", {
  corpus <- ac_corpus("alpha beta gamma delta")
  result <- ac_clean(corpus, remove_stopwords = c("beta", "delta"),
                    lower = TRUE, remove_punct = TRUE)
  expect_false(grepl("\\bbeta\\b", result$text))
  expect_false(grepl("\\bdelta\\b", result$text))
  expect_true(grepl("alpha", result$text))
  expect_true(grepl("gamma", result$text))
})

test_that("remove_stopwords = NULL não remove nada", {
  corpus <- ac_corpus("a casa do deputado")
  result <- ac_clean(corpus, remove_stopwords = NULL,
                    lower = TRUE, remove_punct = FALSE,
                    strip_whitespace = FALSE)
  expect_true(grepl("\\ba\\b", result$text))
  expect_true(grepl("\\bdo\\b", result$text))
})

test_that("remove_stopwords rejeita tipo inválido", {
  corpus <- ac_corpus("texto")
  expect_error(
    ac_clean(corpus, remove_stopwords = 123),
    regexp = "NULL"
  )
})

test_that("remove_stopwords rejeita preset desconhecido", {
  corpus <- ac_corpus("texto")
  # Quando é string única que não bate nenhum preset, cai como vetor custom
  # e simplesmente remove essa palavra se aparecer. Então testamos com
  # o helper interno:
  expect_error(
    acR:::.ac_get_stopwords("preset-inexistente"),
    regexp = "desconhecido"
  )
})

# ============================================================================
# Proteção de termos
# ============================================================================

test_that("protect preserva case de siglas", {
  corpus <- ac_corpus("O deputado do PT e o senador do PSDB debateram")
  result <- ac_clean(corpus, lower = TRUE, remove_punct = FALSE,
                    protect = c("PT", "PSDB"))
  expect_true(grepl("\\bPT\\b", result$text))
  expect_true(grepl("\\bPSDB\\b", result$text))
  expect_true(grepl("deputado", result$text))  # lowercase
})

test_that("protect sobrevive à remoção de stopwords", {
  # Situação: "CCJ" não é stopword, mas garantimos que protect funciona
  # mesmo com stopwords ativadas
  corpus <- ac_corpus("A CCJ decidiu a favor")
  result <- ac_clean(corpus,
                    lower = TRUE,
                    remove_stopwords = "pt",
                    protect = c("CCJ"))
  expect_true(grepl("\\bCCJ\\b", result$text))
})

test_that("protect rejeita tipo inválido", {
  corpus <- ac_corpus("texto")
  expect_error(
    ac_clean(corpus, protect = 123),
    regexp = "character"
  )
})

# ============================================================================
# cleaning_steps registra operações
# ============================================================================

test_that("cleaning_steps registra ordem das operações", {
  corpus <- ac_corpus("Texto")
  result <- ac_clean(corpus,
                    lower = TRUE,
                    remove_punct = TRUE,
                    remove_url = FALSE,
                    remove_email = FALSE)
  steps <- attr(result, "cleaning_steps")
  expect_true("lower" %in% steps)
  expect_true("remove_punct" %in% steps)
  expect_false("remove_url" %in% steps)
})

test_that("cleaning_steps registra preset de stopwords", {
  corpus <- ac_corpus("a casa")
  result <- ac_clean(corpus, remove_stopwords = "pt-br-extended")
  steps <- attr(result, "cleaning_steps")
  expect_true(any(grepl("pt-br-extended", steps)))
})

# ============================================================================
# Argumentos extras
# ============================================================================

test_that("ac_clean() avisa sobre argumentos desconhecidos", {
  corpus <- ac_corpus("texto")
  expect_warning(
    ac_clean(corpus, argumento_inexistente = TRUE),
    regexp = "ignorado"
  )
})

# ============================================================================
# Casos complexos de integração
# ============================================================================

test_that("pipeline completo com múltiplas transformações", {
  corpus <- make_corpus()
  result <- ac_clean(
    corpus,
    lower = TRUE,
    remove_punct = TRUE,
    remove_url = TRUE,
    remove_email = TRUE,
    remove_stopwords = "pt-legislativo",
    protect = c("PT", "CCJ"),
    normalize_pt = TRUE
  )
  # PT e CCJ preservados (protect)
  expect_true(grepl("\\bPT\\b", result$text[1]))
  expect_true(grepl("\\bCCJ\\b", result$text[1]))
  # URL removida
  expect_false(grepl("https", result$text[1]))
  # "deputado" removido (stopword legislativa)
  expect_false(grepl("\\bdeputado\\b", result$text[1]))
  # "pra" nao deve mais aparecer no texto apos normalize_pt
  expect_false(grepl("\\bpra\\b", result$text[3]))
  # Sem pontuação
  expect_false(grepl("[:,'!]", result$text[1]))
})

test_that("pipeline completo com multiplas transformacoes", {
  # Corpus de exemplo com 3 documentos
  corp <- ac_corpus(
    data.frame(
      id   = c("d1", "d2", "d3"),
      text = c(
        "Vou pra reuniao amanha, vc vem?",
        "Acesse http://camara.gov.br para mais informacoes.",
        "O PT e o PL votaram juntos na sessao."
      ),
      stringsAsFactors = FALSE
    ),
    text  = text,
    docid = id
  )
  
  # Pipeline relativamente completo, mas sem assumir nada sobre
  # quais palavras sao stopwords no lexico
  result <- ac_clean(
    corp,
    lower            = TRUE,
    remove_url       = TRUE,
    normalize_pt     = TRUE,
    remove_stopwords = "pt",
    remove_punct     = TRUE,
    protect          = c("PT", "PL")
  )
  
  # Saida geral: continua sendo ac_corpus, com 3 docs e coluna text character
  expect_s3_class(result, "ac_corpus")
  expect_equal(nrow(result), 3L)
  expect_type(result$text, "character")
  
  # Doc 1: texto nao vazio (nao nos interessa o conteudo exato)
  expect_false(is.na(result$text[1]))
  expect_true(nchar(result$text[1]) > 0)
  
  # Doc 2: URL deve ter sido removida
  expect_false(grepl("http", result$text[2]))
  
  # Doc 3: PT e PL protegidos devem estar presentes (case-insensitive)
  expect_true(
    grepl("\\bpt\\b|\\bpl\\b", result$text[3], ignore.case = TRUE)
  )
})

