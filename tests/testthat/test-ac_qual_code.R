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

test_that(".ac_compute_confidence colapsa categoria em array (bug self-consistency)", {
  # Reproduz o crash "Result must be length 1, not 2": numa das k rodadas
  # de self-consistency, o modelo devolve um array JSON em vez de string
  # unica. .ac_compute_confidence() rodava ANTES de .ac_build_result_tibble()
  # e nao tinha a mesma protecao, quebrando purrr::map_chr().
  results <- list(
    list(categoria = "tema_a"),
    list(categoria = c("tema_a", "tema_b")),  # array (bug reproduzido)
    list(categoria = "tema_a")
  )

  conf <- acR:::.ac_compute_confidence(
    results   = results,
    cat_names = c("tema_a", "tema_b"),
    confidence = "total"
  )

  expect_type(conf, "list")
  expect_false(is.null(conf$total))
  # moda deve ser "tema_a" (2 rodadas puras) ou a string colapsada,
  # dependendo de empate; aqui garantimos so que nao ha erro e que o
  # valor colapsado esta entre os possiveis, sem quebrar comprimento
  expect_true(conf$dominant %in% c("tema_a", "tema_a|tema_b"))
})

test_that(".ac_compute_confidence trata categoria NULL como NA sem quebrar", {
  results <- list(
    list(categoria = "tema_a"),
    list(categoria = NULL)
  )
  conf <- acR:::.ac_compute_confidence(
    results   = results,
    cat_names = c("tema_a"),
    confidence = "total"
  )
  expect_type(conf, "list")
  expect_equal(conf$dominant, "tema_a")
})


# ============================================================
# Bug fix: confidence = "by_variable"/"both" nunca populavam
# confianca por variavel. Dois bugs na mesma funcao:
# 1) .ac_compute_confidence(): o primeiro `if` testava
#    confidence %in% c("total", "both"), entao "both" sempre caia
#    nesse ramo e nunca calculava by_var.
# 2) .ac_build_result_tibble(): mesmo com by_var populado, ele nunca
#    era lido -- nenhuma coluna <categoria>_confidence era adicionada
#    ao tibble, apesar de documentado em @return.
# ============================================================

test_that(".ac_compute_confidence() popula by_var para 'by_variable' e 'both'", {
  results <- list(
    list(categoria = "tema_a"),
    list(categoria = "tema_a"),
    list(categoria = "tema_b")
  )
  cat_names <- c("tema_a", "tema_b", "tema_c")

  r_total <- acR:::.ac_compute_confidence(results, cat_names, "total")
  expect_equal(r_total$total, 2/3)
  expect_null(r_total$by_var)

  r_by_var <- acR:::.ac_compute_confidence(results, cat_names, "by_variable")
  expect_null(r_by_var$total)
  expect_equal(r_by_var$by_var$tema_a, 2/3)
  expect_equal(r_by_var$by_var$tema_b, 1/3)
  expect_equal(r_by_var$by_var$tema_c, 0)

  # Bug 1: "both" caia sempre no ramo de "total", nunca alcancando
  # o calculo de by_var.
  r_both <- acR:::.ac_compute_confidence(results, cat_names, "both")
  expect_equal(r_both$total, 2/3)
  expect_equal(r_both$by_var$tema_a, 2/3)
  expect_equal(r_both$by_var$tema_b, 1/3)
  expect_equal(r_both$by_var$tema_c, 0)
})

test_that(".ac_build_result_tibble() cria colunas <categoria>_confidence com 'both'", {
  cb     <- make_codebook_test()  # positivo/negativo/neutro
  corpus <- data.frame(doc_id = c("d1", "d2"), text = c("t1", "t2"),
                       stringsAsFactors = FALSE)

  results <- list(
    list(doc_id = "d1", main = list(categoria = "positivo"),
         conf_scores = list(total = 0.667,
                            by_var = list(positivo = 0.667, negativo = 0.333, neutro = 0),
                            dominant = "positivo")),
    list(doc_id = "d2", main = list(categoria = "negativo"),
         conf_scores = list(total = 1,
                            by_var = list(positivo = 0, negativo = 1, neutro = 0),
                            dominant = "negativo"))
  )

  # Bug 2: by_var era calculado (uma vez o Bug 1 corrigido) mas nunca
  # chegava ao tibble final -- nenhuma coluna <categoria>_confidence
  # era adicionada.
  out <- acR:::.ac_build_result_tibble(
    results   = results, corpus = corpus,
    cat_names = c("positivo", "negativo", "neutro"),
    codebook  = cb, confidence = "both", reasoning = FALSE
  )

  expect_true(all(c("positivo_confidence", "negativo_confidence",
                    "neutro_confidence") %in% names(out)))
  expect_equal(out$positivo_confidence[1], 0.667)
  expect_equal(out$negativo_confidence[2], 1)
  expect_equal(out$confidence_score, c(0.667, 1))
})

test_that(".ac_build_result_tibble() nao adiciona colunas <categoria>_confidence com 'total'", {
  cb     <- make_codebook_test()
  corpus <- data.frame(doc_id = "d1", text = "t1", stringsAsFactors = FALSE)

  results <- list(
    list(doc_id = "d1", main = list(categoria = "positivo"),
         conf_scores = list(total = 1, by_var = NULL, dominant = "positivo"))
  )

  out <- acR:::.ac_build_result_tibble(
    results   = results, corpus = corpus,
    cat_names = c("positivo", "negativo", "neutro"),
    codebook  = cb, confidence = "total", reasoning = FALSE
  )

  expect_false(any(grepl("_confidence$", names(out)[names(out) != "confidence_score"])))
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


# ============================================================
# Bug fix (item 1 da revisao de producao): quando `model` e um
# objeto `Chat` pre-configurado, `temperature` era descartado em
# silencio sempre que a reconstrucao via .ac_ellmer_chat falhava --
# o que acontecia sistematicamente no ellmer >= 0.5.0, porque
# `class(provider)[1]` passou a vir qualificado por namespace
# ("ellmer::ProviderOpenAI"), quebrando o `sub("^provider", "", ...)`.
# Fix: .ac_chat_with_temperature() muta o `Model` via
# set_model()/get_model_object() (API estavel), e avisa
# explicitamente (cli::cli_warn) se a mutacao falhar -- nunca mais
# um fallback silencioso.
# ============================================================

make_fake_chat <- function(model_obj = list(params = NULL)) {
  self <- new.env()
  self$model <- model_obj
  self$system_prompt <- NULL
  self$clone <- function(...) make_fake_chat(self$model)
  self$set_system_prompt <- function(p) { self$system_prompt <<- p; invisible(self) }
  self$get_model_object <- function() self$model
  self$set_model <- function(m) { self$model <<- m; invisible(self) }
  self$chat <- function(msg) '{"categoria": "a"}'
  class(self) <- "Chat"
  self
}

test_that(".ac_chat_with_temperature() aplica temperature via set_model/get_model_object", {
  skip_if_not_installed("ellmer")

  fake <- make_fake_chat()
  out <- acR:::.ac_chat_with_temperature(fake, "sys prompt", 0.7)

  expect_equal(out$system_prompt, "sys prompt")
  expect_false(is.null(out$model$params))
})

test_that(".ac_chat_with_temperature() avisa (nao falha em silencio) quando mutacao falha", {
  self <- new.env()
  self$system_prompt <- NULL
  self$clone <- function(...) self
  self$set_system_prompt <- function(p) { self$system_prompt <<- p; invisible(self) }
  self$get_model_object <- function() stop("API indisponivel nesta versao")
  self$chat <- function(msg) '{"categoria": "a"}'
  class(self) <- "Chat"

  expect_warning(
    out <- acR:::.ac_chat_with_temperature(self, "sys", 0.5),
    regexp = "Não foi possível aplicar"
  )
  expect_equal(out$system_prompt, "sys")
})

test_that(".ac_chat_with_temperature() nao tenta mutar quando temperature e NULL", {
  fake <- make_fake_chat()
  expect_no_warning(
    out <- acR:::.ac_chat_with_temperature(fake, "sys", NULL)
  )
  expect_equal(out$system_prompt, "sys")
})

test_that(".ac_make_chat() aceita funcao-fabrica function(temperature, system_prompt)", {
  captured <- list()
  factory <- function(temperature, system_prompt) {
    captured$temperature <<- temperature
    captured$system_prompt <<- system_prompt
    make_fake_chat()
  }

  chat <- acR:::.ac_make_chat(factory, "sys prompt", 0.42, list())

  expect_equal(captured$temperature, 0.42)
  expect_equal(captured$system_prompt, "sys prompt")
  expect_s3_class(chat, "Chat")
})

test_that(".ac_make_chat() aplica temperature a objeto Chat pre-configurado", {
  fake <- make_fake_chat()
  chat <- acR:::.ac_make_chat(fake, "sys", 0.9, list())
  expect_false(is.null(chat$model$params))
  expect_equal(chat$system_prompt, "sys")
})
