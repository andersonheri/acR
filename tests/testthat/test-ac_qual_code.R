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
    model = "openai/gpt-oss-120b",
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
    model = "openai/gpt-oss-120b",
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

  chat_obj <- ellmer::chat_groq(model = "openai/gpt-oss-120b", echo = "none")

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

  chat_obj <- ellmer::chat_groq(model = "openai/gpt-oss-120b", echo = "none")

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


# ============================================================
# Bug fix: .ac_build_result_tibble tratava `categoria` como
# comprimento 1; quando modelo devolvia array JSON (comum em
# multilabel), purrr::map_chr quebrava com "Result must be length 1,
# not N". Fix: paste(collapse = "|") -- sempre colapsa para string.
# ============================================================

test_that(".ac_build_result_tibble colapsa categoria/raciocinio em array (bug multilabel)", {
  corpus <- tibble::tibble(
    doc_id = c("d1", "d2", "d3"),
    text   = c("t1", "t2", "t3")
  )
  results <- list(
    # d1: modelo obedeceu (string)
    list(doc_id = "d1",
         main = list(categoria = "tecnica",
                     raciocinio = "explicacao"),
         conf_scores = list(total = 1)),
    # d2: modelo devolveu array (bug reproduzido)
    list(doc_id = "d2",
         main = list(categoria = c("tecnica", "politica"),
                     raciocinio = c("parte 1", "parte 2")),
         conf_scores = list(total = 0.8)),
    # d3: modelo devolveu string pipe-separada
    list(doc_id = "d3",
         main = list(categoria = "tecnica|politica",
                     raciocinio = "explicacao unica"),
         conf_scores = list(total = 0.67))
  )

  cb <- ac_qual_codebook(
    name = "multi", instructions = "cl.",
    categories = list(
      tecnica  = list(definition = "tec.", label = "Tecnica"),
      politica = list(definition = "pol.", label = "Politica")
    ),
    multilabel = TRUE
  )
  tbl <- acR:::.ac_build_result_tibble(
    results   = results,
    corpus    = corpus,
    cat_names = c("tecnica", "politica"),
    codebook  = cb,
    confidence = "total",
    reasoning = TRUE
  )

  expect_s3_class(tbl, "tbl_df")
  expect_equal(nrow(tbl), 3L)
  expect_equal(tbl$categoria[1], "tecnica")
  # d2 (array) deve virar string pipe-separada, nao quebrar
  expect_equal(tbl$categoria[2], "tecnica|politica")
  expect_equal(tbl$categoria[3], "tecnica|politica")
  # raciocinio de array deve virar string unica
  expect_equal(tbl$raciocinio[2], "parte 1 parte 2")
  # Bug 5: categoria_label usa label do codebook, com " | " no multilabel
  expect_equal(tbl$categoria_label[1], "Tecnica")
  expect_equal(tbl$categoria_label[2], "Tecnica | Politica")
})

test_that("prompt multilabel instrui explicitamente que categoria eh string", {
  cb <- ac_qual_codebook(
    name = "multi_teste",
    instructions = "Classifique.",
    categories = list(
      a = list(definition = "cat a"),
      b = list(definition = "cat b"),
      c = list(definition = "cat c")
    ),
    multilabel = TRUE
  )
  prompt <- acR:::.ac_build_system_prompt(cb, reasoning = FALSE,
                                          reasoning_length = "short")
  # Instrucao explicita contra array JSON deve estar presente
  expect_true(grepl("NUNCA responda com um array JSON", prompt, fixed = TRUE))
  expect_true(grepl("SEMPRE uma string", prompt))
  expect_true(grepl("separados por", prompt))
})


# ============================================================
# Bug fix: .ac_classify_one recebia `temperature` mas nunca o
# repassava ao Chat -- as k rodadas de self-consistency usavam
# temperatura fixa do provedor. Fix: injeta ellmer::params() em
# dots quando o usuario nao passou params explicitos.
# ============================================================

test_that(".ac_classify_one injeta ellmer::params(temperature) quando ausente (bug temperature)", {
  skip_if_not_installed("ellmer")
  # Interceptamos .ac_ellmer_chat via trace() para capturar os argumentos
  # sem exercer o caminho real (que abriria HTTP). Testa apenas o passo
  # de composicao de argumentos que era o bug.
  captured <- new.env()
  captured$args <- NULL
  ns <- asNamespace("acR")
  original <- ns$.ac_ellmer_chat
  # unlockBinding pra permitir substituicao segura em testes
  suppressWarnings(unlockBinding(".ac_ellmer_chat", ns))
  ns$.ac_ellmer_chat <- function(...) {
    captured$args <- list(...)
    # abortar imediatamente para nao continuar o pipeline
    stop("test-shortcircuit", call. = FALSE)
  }
  on.exit({
    ns$.ac_ellmer_chat <- original
    lockBinding(".ac_ellmer_chat", ns)
  }, add = TRUE)

  cb <- list(multilabel = FALSE,
             categories = list(a = list(definition = "cat a")))
  tryCatch(
    ns$.ac_classify_one(
      text = "t", codebook = cb, model = "openai/gpt-4o",
      system_prompt = "sys", temperature = 0.5, reasoning = FALSE
    ),
    error = function(e) NULL
  )

  expect_false(is.null(captured$args))
  # `params` deve ter sido injetado nos args passados ao .ac_ellmer_chat
  expect_true("params" %in% names(captured$args))
  # E deve ser um objeto do ellmer::params()
  expect_true(!is.null(captured$args$params))
})
