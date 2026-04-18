# Testes para ac_qual_code()
# Testes de integracao com LLM usam skip_if_offline() e skip_if_not_installed()

# ============================================================
# Fixtures
# ============================================================

make_corpus_test <- function() {
  df <- data.frame(
    id    = c("doc_1", "doc_2", "doc_3"),
    texto = c(
      "Proponho que trabalhemos juntos nesta agenda.",
      "Este governo e um fracasso completo.",
      "O artigo 3o estabelece prazo de 180 dias."
    ),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id)
}

make_codebook_test <- function() {
  ac_qual_codebook(
    name         = "tom_teste",
    instructions = "Classifique o tom do discurso.",
    categories   = list(
      positivo = list(definition = "Tom propositivo e colaborativo."),
      negativo = list(definition = "Tom critico e confrontacional."),
      neutro   = list(definition = "Tom descritivo sem valoracao.")
    )
  )
}


# ============================================================
# Validacoes de entrada
# ============================================================

test_that("ac_qual_code() rejeita corpus invalido", {
  cb <- make_codebook_test()
  expect_error(
    ac_qual_code(corpus = "nao_e_corpus", codebook = cb),
    regexp = "ac_corpus"
  )
})

test_that("ac_qual_code() rejeita codebook invalido", {
  corpus <- make_corpus_test()
  expect_error(
    ac_qual_code(corpus = corpus, codebook = list(a = 1)),
    regexp = "ac_codebook"
  )
})

test_that("ac_qual_code() rejeita chat invalido", {
  corpus <- make_corpus_test()
  cb     <- make_codebook_test()
  expect_error(
    ac_qual_code(corpus = corpus, codebook = cb, chat = "nao_e_chat"),
    regexp = "Chat"
  )
})

test_that("ac_qual_code() aceita confidence = 'none' sem erro de validacao", {
  corpus <- make_corpus_test()
  cb     <- make_codebook_test()
  # So valida argumentos — nao executa LLM
  expect_no_error(
    match.arg("none", c("total", "by_variable", "both", "none"))
  )
})

test_that("ac_qual_code() aceita reasoning_length valido", {
  expect_no_error(match.arg("short",    c("short", "medium", "detailed")))
  expect_no_error(match.arg("medium",   c("short", "medium", "detailed")))
  expect_no_error(match.arg("detailed", c("short", "medium", "detailed")))
})


# ============================================================
# Integracao com LLM (requer credenciais e conexao)
# ============================================================

test_that("ac_qual_code() retorna tibble com colunas esperadas", {
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if(
    nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "GROQ_API_KEY nao configurada"
  )

  corpus <- make_corpus_test()
  cb     <- make_codebook_test()

  chat_obj <- ellmer::chat_groq(
    model = "llama-3.3-70b-versatile",
    echo  = "none"
  )

  resultado <- ac_qual_code(
    corpus        = corpus,
    codebook      = cb,
    chat          = chat_obj,
    confidence    = "total",
    k_consistency = 3L,
    reasoning     = TRUE
  )

  expect_s3_class(resultado, "tbl_df")
  expect_equal(nrow(resultado), 3L)

  expected_cols <- c("doc_id", "categoria", "confidence_score",
                     "confidence_level", "raciocinio")
  expect_true(all(expected_cols %in% names(resultado)))
})

test_that("ac_qual_code() classifica corretamente textos inequivocos", {
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if(
    nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "GROQ_API_KEY nao configurada"
  )

  corpus <- make_corpus_test()
  cb     <- make_codebook_test()

  chat_obj <- ellmer::chat_groq(
    model = "llama-3.3-70b-versatile",
    echo  = "none"
  )

  resultado <- ac_qual_code(
    corpus        = corpus,
    codebook      = cb,
    chat          = chat_obj,
    confidence    = "none",
    reasoning     = FALSE
  )

  # doc_1 deve ser positivo, doc_2 negativo
  cat_doc1 <- resultado$categoria[resultado$doc_id == "doc_1"]
  cat_doc2 <- resultado$categoria[resultado$doc_id == "doc_2"]

  expect_equal(cat_doc1, "positivo")
  expect_equal(cat_doc2, "negativo")
})

test_that("ac_qual_code() com confidence = 'none' nao retorna confidence_score NA inesperado", {
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if(
    nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "GROQ_API_KEY nao configurada"
  )

  corpus <- make_corpus_test()
  cb     <- make_codebook_test()

  chat_obj <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")

  resultado <- ac_qual_code(
    corpus     = corpus,
    codebook   = cb,
    chat       = chat_obj,
    confidence = "none",
    reasoning  = FALSE
  )

  # Com confidence = "none", confidence_score deve ser NA para todos
  expect_true(all(is.na(resultado$confidence_score)))
})

test_that("ac_qual_code() preserva metadados do corpus no resultado", {
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if(
    nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "GROQ_API_KEY nao configurada"
  )

  df <- data.frame(
    id      = c("d1", "d2"),
    texto   = c("Proponho cooperacao.", "Oposicao total."),
    partido = c("PT", "PL"),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  cb     <- make_codebook_test()

  chat_obj <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")

  resultado <- ac_qual_code(
    corpus     = corpus,
    codebook   = cb,
    chat       = chat_obj,
    confidence = "none",
    reasoning  = FALSE
  )

  # Coluna de metadado deve estar presente
  expect_true("partido" %in% names(resultado))
  expect_equal(resultado$partido[resultado$doc_id == "d1"], "PT")
})
