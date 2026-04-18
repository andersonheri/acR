# Testes para ac_qual_codebook(), ac_qual_save/load_codebook()
# Modo literatura requer LLM: usa skip_if_offline()

make_cb_manual <- function() {
  ac_qual_codebook(
    name         = "tom_teste",
    instructions = "Classifique o tom do discurso.",
    categories   = list(
      positivo = list(
        definition   = "Tom propositivo e colaborativo.",
        examples_pos = c("Proponho que trabalhemos juntos."),
        examples_neg = c("Este governo e um fracasso.")
      ),
      negativo = list(
        definition   = "Tom critico e confrontacional.",
        examples_pos = c("Esta proposta vai arruinar o pais."),
        examples_neg = c("Apresento esta emenda.")
      )
    )
  )
}

# ============================================================
# Validações básicas
# ============================================================

test_that("ac_qual_codebook() cria objeto ac_codebook no modo manual", {
  cb <- make_cb_manual()
  expect_s3_class(cb, "ac_codebook")
  expect_equal(cb$name, "tom_teste")
  expect_equal(cb$mode, "manual")
  expect_equal(length(cb$categories), 2L)
  expect_equal(names(cb$categories), c("positivo", "negativo"))
})

test_that("ac_qual_codebook() rejeita nome vazio", {
  expect_error(
    ac_qual_codebook(name = "", instructions = "x", categories = list(a = list(), b = list())),
    regexp = "n\u00e3o vazia"
  )
})

test_that("ac_qual_codebook() rejeita categories sem nomes", {
  expect_error(
    ac_qual_codebook(
      name = "x", instructions = "y",
      categories = list(list(definition = "a"), list(definition = "b"))
    ),
    regexp = "nomeada"
  )
})

test_that("ac_qual_codebook() rejeita menos de 2 categorias", {
  expect_error(
    ac_qual_codebook(
      name = "x", instructions = "y",
      categories = list(a = list(definition = "so uma"))
    ),
    regexp = "2 categorias"
  )
})

test_that("categorias tem estrutura correta", {
  cb <- make_cb_manual()
  cat <- cb$categories[["positivo"]]
  expect_s3_class(cat, "ac_category")
  expect_equal(cat$name, "positivo")
  expect_true(nchar(cat$definition) > 0)
  expect_equal(length(cat$examples_pos), 1L)
  expect_equal(length(cat$examples_neg), 1L)
})

test_that("multilabel e lang sao preservados", {
  cb <- ac_qual_codebook(
    name         = "x",
    instructions = "y",
    categories   = list(
      a = list(definition = "def a"),
      b = list(definition = "def b")
    ),
    multilabel = TRUE,
    lang       = "en"
  )
  expect_true(cb$multilabel)
  expect_equal(cb$lang, "en")
})

test_that("print.ac_codebook nao gera erro", {
  cb <- make_cb_manual()
  expect_invisible(print(cb))
})

test_that("summary.ac_codebook retorna tibble", {
  cb <- make_cb_manual()
  s <- summary(cb)
  expect_s3_class(s, "ac_codebook")
})

# ============================================================
# Salvar e carregar YAML
# ============================================================

test_that("ac_qual_save_codebook() salva arquivo YAML", {
  skip_if_not_installed("yaml")
  cb   <- make_cb_manual()
  path <- tempfile(fileext = ".yaml")
  ac_qual_save_codebook(cb, path)
  expect_true(file.exists(path))
  unlink(path)
})

test_that("ac_qual_load_codebook() carrega e preserva estrutura", {
  skip_if_not_installed("yaml")
  cb   <- make_cb_manual()
  path <- tempfile(fileext = ".yaml")
  ac_qual_save_codebook(cb, path)
  cb2 <- ac_qual_load_codebook(path)

  expect_s3_class(cb2, "ac_codebook")
  expect_equal(cb2$name, cb$name)
  expect_equal(cb2$mode, cb$mode)
  expect_equal(names(cb2$categories), names(cb$categories))
  expect_equal(
    cb2$categories[["positivo"]]$definition,
    cb$categories[["positivo"]]$definition
  )
  unlink(path)
})

test_that("ac_qual_load_codebook() falha para arquivo inexistente", {
  skip_if_not_installed("yaml")
  expect_error(
    ac_qual_load_codebook("arquivo_que_nao_existe.yaml"),
    regexp = "n\u00e3o encontrado"
  )
})

# ============================================================
# ac_qual_search_literature() (requer LLM online)
# ============================================================

test_that("ac_qual_search_literature() retorna tibble com colunas esperadas", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if_not_installed("jsonlite")
  skip_if(
    nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "GROQ_API_KEY nao configurada"
  )

  # Verificar se OpenAlex retorna algo antes de rodar o teste completo
  api_ok <- tryCatch({
    r    <- httr2::request("https://api.openalex.org/works") |>
      httr2::req_url_query(search = "democratic backsliding", `per-page` = 1L,
                           filter = "type:article") |>
      httr2::req_timeout(10L) |>
      httr2::req_perform()
    body <- httr2::resp_body_json(r, simplifyVector = FALSE)
    length(body$results) > 0L
  }, error = function(e) FALSE)
  skip_if(!api_ok, "OpenAlex nao retornou resultados para o conceito de teste")

  chat_obj <- ellmer::chat_groq(
    model = "llama-3.3-70b-versatile",
    echo  = "none"
  )

  lit <- ac_qual_search_literature(
    concept       = "democratic backsliding",
    n_refs        = 2,
    journals      = "all",
    min_citations = 50L,
    chat          = chat_obj
  )

  expect_s3_class(lit, "tbl_df")
  expected_cols <- c("conceito", "autor", "ano", "trecho_original",
                     "definicao_pt", "revista", "link")
  expect_true(all(expected_cols %in% names(lit)))
  expect_true(nrow(lit) > 0)
})

test_that(".ac_get_journals() retorna listas corretas", {
  j_default <- acR:::.ac_get_journals("default")
  j_all     <- acR:::.ac_get_journals("all")
  j_custom  <- acR:::.ac_get_journals(c("default", "RBCS"))

  expect_true(length(j_default) > 0)
  expect_null(j_all)
  expect_true("RBCS" %in% j_custom)
  expect_true("DADOS" %in% j_custom)
})
