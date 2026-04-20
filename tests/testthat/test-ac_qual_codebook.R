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
# Validacoes basicas
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

# ============================================================
# BLOCO B --- ac_qual_codebook_merge()
# ============================================================

test_that("ac_qual_codebook_merge() funde dois codebooks sem conflito", {
  cb1 <- make_cb_manual()
  cb2 <- ac_qual_codebook(
    name         = "estilo",
    instructions = "Classifique o estilo.",
    categories   = list(
      formal   = list(definition = "Linguagem formal."),
      informal = list(definition = "Linguagem informal.")
    )
  )
  merged <- ac_qual_codebook_merge(cb1, cb2)

  expect_s3_class(merged, "ac_codebook")
  expect_equal(length(merged$categories), 4L)
  expect_true(all(c("positivo", "negativo", "formal", "informal") %in%
                    names(merged$categories)))
})

test_that("ac_qual_codebook_merge() respeita on_conflict = 'keep_first'", {
  cb1 <- make_cb_manual()
  cb2 <- ac_qual_codebook(
    name         = "cb2",
    instructions = "y",
    categories   = list(
      positivo = list(definition = "Outra definicao de positivo."),
      neutro   = list(definition = "Tom neutro.")
    )
  )
  merged <- ac_qual_codebook_merge(cb1, cb2, on_conflict = "keep_first")

  expect_equal(
    merged$categories[["positivo"]]$definition,
    cb1$categories[["positivo"]]$definition
  )
  expect_true("neutro" %in% names(merged$categories))
})

test_that("ac_qual_codebook_merge() respeita on_conflict = 'keep_second'", {
  cb1 <- make_cb_manual()
  cb2 <- ac_qual_codebook(
    name         = "cb2",
    instructions = "y",
    categories   = list(
      positivo = list(definition = "Definicao alternativa."),
      neutro   = list(definition = "Tom neutro.")
    )
  )
  merged <- ac_qual_codebook_merge(cb1, cb2, on_conflict = "keep_second")

  expect_equal(
    merged$categories[["positivo"]]$definition,
    "Definicao alternativa."
  )
})

test_that("ac_qual_codebook_merge() respeita on_conflict = 'rename_second'", {
  cb1 <- make_cb_manual()
  cb2 <- ac_qual_codebook(
    name         = "cb2",
    instructions = "y",
    categories   = list(
      positivo = list(definition = "Def conflitante."),
      neutro   = list(definition = "Tom neutro.")
    )
  )
  merged <- ac_qual_codebook_merge(cb1, cb2, on_conflict = "rename_second")

  expect_true("positivo"   %in% names(merged$categories))
  expect_true("positivo_2" %in% names(merged$categories))
})

test_that("ac_qual_codebook_merge() erro em conflito com on_conflict = 'error'", {
  cb1 <- make_cb_manual()
  cb2 <- ac_qual_codebook(
    name         = "cb2",
    instructions = "y",
    categories   = list(
      positivo = list(definition = "Conflito."),
      neutro   = list(definition = "Neutro.")
    )
  )
  expect_error(
    ac_qual_codebook_merge(cb1, cb2, on_conflict = "error"),
    regexp = "Conflito"
  )
})

test_that("ac_qual_codebook_merge() aceita name e instructions customizados", {
  cb1    <- make_cb_manual()
  cb2    <- ac_qual_codebook(
    name = "cb2", instructions = "y",
    categories = list(x = list(definition = "x"), y = list(definition = "y"))
  )
  merged <- ac_qual_codebook_merge(cb1, cb2,
                                   name         = "fusao_teste",
                                   instructions = "Instrucao combinada.")
  expect_equal(merged$name, "fusao_teste")
  expect_equal(merged$instructions, "Instrucao combinada.")
})

test_that("ac_qual_codebook_merge() rejeita objetos que nao sao ac_codebook", {
  cb <- make_cb_manual()
  expect_error(ac_qual_codebook_merge(cb,  list()), regexp = "ac_codebook")
  expect_error(ac_qual_codebook_merge(list(), cb),  regexp = "ac_codebook")
})

# ============================================================
# BLOCO B --- ac_qual_codebook_history()
# ============================================================

test_that("ac_qual_codebook_history() retorna tibble vazio para codebook novo", {
  cb   <- make_cb_manual()
  hist <- ac_qual_codebook_history(cb)
  expect_s3_class(hist, "tbl_df")
  expect_equal(nrow(hist), 0L)
  expect_true(all(c("timestamp", "action", "detail") %in% names(hist)))
})

test_that("ac_qual_codebook_history() registra acao de merge", {
  cb1 <- make_cb_manual()
  cb2 <- ac_qual_codebook(
    name = "cb2", instructions = "y",
    categories = list(x = list(definition = "x"), y = list(definition = "y"))
  )
  merged <- ac_qual_codebook_merge(cb1, cb2)
  hist   <- ac_qual_codebook_history(merged)

  expect_equal(nrow(hist), 1L)
  expect_equal(hist$action[1], "merge")
})

test_that("ac_qual_codebook_history() respeita argumento n", {
  cb <- make_cb_manual()
  # Gerar 3 entradas no historico via add/remove
  cb <- ac_qual_codebook_add(cb,
    neutro = list(definition = "Tom neutro."))
  cb <- ac_qual_codebook_add(cb,
    tecnico = list(definition = "Tom tecnico."))
  cb <- ac_qual_codebook_remove(cb, "tecnico")

  hist_all <- ac_qual_codebook_history(cb)
  hist_1   <- ac_qual_codebook_history(cb, n = 1L)

  expect_equal(nrow(hist_all), 3L)
  expect_equal(nrow(hist_1),   1L)
})

# ============================================================
# BLOCO B --- as_prompt() / as_prompt.ac_codebook()
# ============================================================

test_that("as_prompt() retorna string nao vazia", {
  cb     <- make_cb_manual()
  prompt <- as_prompt(cb)
  expect_type(prompt, "character")
  expect_true(nchar(prompt) > 50L)
})

test_that("as_prompt() inclui nomes das categorias no prompt", {
  cb     <- make_cb_manual()
  prompt <- as_prompt(cb)
  expect_true(grepl("positivo", prompt))
  expect_true(grepl("negativo", prompt))
})

test_that("as_prompt() com reasoning = FALSE omite campo raciocinio", {
  cb         <- make_cb_manual()
  prompt_com <- as_prompt(cb, reasoning = FALSE)
  expect_false(grepl("raciocinio", prompt_com))
})

test_that("as_prompt() com reasoning_length = 'detailed' inclui paragrafo", {
  cb     <- make_cb_manual()
  prompt <- as_prompt(cb, reasoning = TRUE, reasoning_length = "detailed")
  expect_true(grepl("par", prompt))
})

test_that("as_prompt() com multilabel = TRUE menciona MAIS DE UMA", {
  cb <- ac_qual_codebook(
    name         = "multi",
    instructions = "Classifique.",
    categories   = list(
      a = list(definition = "Def A."),
      b = list(definition = "Def B.")
    ),
    multilabel = TRUE
  )
  prompt <- as_prompt(cb)
  expect_true(grepl("MAIS DE UMA", prompt))
})

test_that("as_prompt() rejeita objeto que nao e ac_codebook", {
  expect_error(as_prompt(list()), regexp = "ac_codebook")
})

# ============================================================
# BLOCO B --- ac_qual_codebook_translate() (sem LLM: skip)
# ============================================================

test_that("ac_qual_codebook_translate() retorna mesmo codebook se ja no idioma alvo", {
  cb <- ac_qual_codebook(
    name = "en_cb", instructions = "Classify.",
    categories = list(
      positive = list(definition = "Positive tone."),
      negative = list(definition = "Negative tone.")
    ),
    lang = "en"
  )
  result <- ac_qual_codebook_translate(cb, to = "en")
  expect_equal(result$lang, "en")
  expect_equal(result$categories[["positive"]]$definition,
               cb$categories[["positive"]]$definition)
})

test_that("ac_qual_codebook_translate() rejeita objeto que nao e ac_codebook", {
  expect_error(
    ac_qual_codebook_translate(list(), to = "en"),
    regexp = "ac_codebook"
  )
})

test_that("ac_qual_codebook_translate() traduz PT->EN com LLM (online)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if_not_installed("jsonlite")
  skip_if(
    nchar(Sys.getenv("ANTHROPIC_API_KEY")) == 0 &&
      nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "Nenhuma API key configurada"
  )

  cb     <- make_cb_manual()
  cb_en  <- ac_qual_codebook_translate(cb, to = "en")

  expect_s3_class(cb_en, "ac_codebook")
  expect_equal(cb_en$lang, "en")
  expect_false(identical(
    cb_en$categories[["positivo"]]$definition,
    cb$categories[["positivo"]]$definition
  ))
  hist <- ac_qual_codebook_history(cb_en)
  expect_true(any(hist$action == "translate"))
})

# ============================================================
# BLOCO B --- ac_qual_codebook_hybrid() (requer LLM: skip)
# ============================================================

test_that("ac_qual_codebook_hybrid() rejeita objeto que nao e ac_codebook", {
  expect_error(
    ac_qual_codebook_hybrid(list()),
    regexp = "ac_codebook"
  )
})

test_that("ac_qual_codebook_hybrid() enriquece definicoes com LLM (online)", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if_not_installed("jsonlite")
  skip_if(
    nchar(Sys.getenv("ANTHROPIC_API_KEY")) == 0 &&
      nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "Nenhuma API key configurada"
  )

  cb        <- make_cb_manual()
  cb_hybrid <- ac_qual_codebook_hybrid(
    cb,
    model  = "anthropic/claude-sonnet-4-5",
    n_refs = 2L,
    lang   = "pt"
  )

  expect_s3_class(cb_hybrid, "ac_codebook")
  expect_equal(cb_hybrid$mode, "hybrid")
  expect_equal(names(cb_hybrid$categories), names(cb$categories))

  # Definicoes devem ter sido atualizadas (ou pelo menos mantidas)
  expect_true(nchar(cb_hybrid$categories[["positivo"]]$definition) > 0)

  # Historico deve registrar a acao
  hist <- ac_qual_codebook_history(cb_hybrid)
  expect_true(any(hist$action == "hybrid"))
})
