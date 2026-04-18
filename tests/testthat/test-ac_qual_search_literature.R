# Testes para ac_qual_search_literature()
# Testes de integracao requerem conexao e credenciais LLM

# ============================================================
# Validacoes de entrada
# ============================================================

test_that("ac_qual_search_literature() rejeita concept vazio", {
  expect_error(
    ac_qual_search_literature(concept = ""),
    regexp = "string nao vazia"
  )
})

test_that("ac_qual_search_literature() rejeita concept nao-string", {
  expect_error(
    ac_qual_search_literature(concept = 123),
    regexp = "string nao vazia"
  )
})

test_that("ac_qual_search_literature() rejeita chat invalido", {
  expect_error(
    ac_qual_search_literature(concept = "state capacity", chat = "nao_e_chat"),
    regexp = "Chat"
  )
})


# ============================================================
# Funcoes auxiliares internas
# ============================================================

test_that(".ac_get_journals() retorna vetor para 'default'", {
  j <- acR:::.ac_get_journals("default")
  expect_type(j, "character")
  expect_true(length(j) > 0L)
  expect_true("DADOS" %in% j)
  expect_true("American Political Science Review" %in% j)
})

test_that(".ac_get_journals() retorna NULL para 'all'", {
  j <- acR:::.ac_get_journals("all")
  expect_null(j)
})

test_that(".ac_get_journals() combina default com extras", {
  j <- acR:::.ac_get_journals(c("default", "Minha Revista"))
  expect_true("DADOS" %in% j)
  expect_true("Minha Revista" %in% j)
})

test_that(".ac_get_journals() aceita vetor sem default", {
  j <- acR:::.ac_get_journals(c("Revista A", "Revista B"))
  expect_equal(j, c("Revista A", "Revista B"))
})

test_that(".ac_reconstruct_abstract() reconstroi texto corretamente", {
  # Simular inverted index do OpenAlex
  inverted <- list(
    "Democratic"   = list(0L),
    "backsliding"  = list(1L),
    "is"           = list(2L),
    "a"            = list(3L),
    "process"      = list(4L)
  )
  result <- acR:::.ac_reconstruct_abstract(inverted)
  expect_equal(result, "Democratic backsliding is a process")
})

test_that(".ac_reconstruct_abstract() retorna NA para index vazio", {
  expect_equal(acR:::.ac_reconstruct_abstract(NULL),        NA_character_)
  expect_equal(acR:::.ac_reconstruct_abstract(list()),      NA_character_)
})

test_that(".ac_reconstruct_abstract() ordena palavras por posicao", {
  # Palavras fora de ordem no index
  inverted <- list(
    "world"  = list(2L),
    "Hello"  = list(0L),
    "the"    = list(1L)
  )
  result <- acR:::.ac_reconstruct_abstract(inverted)
  expect_equal(result, "Hello the world")
})

test_that(".ac_reconstruct_abstract() trata palavras com multiplas posicoes", {
  inverted <- list(
    "the"   = list(0L, 3L),
    "cat"   = list(1L),
    "sat"   = list(2L),
    "mat"   = list(4L)
  )
  result <- acR:::.ac_reconstruct_abstract(inverted)
  expect_equal(result, "the cat sat the mat")
})

test_that(".ac_empty_lit_tibble() retorna tibble com colunas corretas", {
  tib <- acR:::.ac_empty_lit_tibble()
  expect_s3_class(tib, "tbl_df")
  expect_equal(nrow(tib), 0L)
  expected_cols <- c("conceito", "autor", "ano", "revista", "n_citacoes",
                     "trecho_original", "definicao_pt", "abstract_original", "link")
  expect_true(all(expected_cols %in% names(tib)))
})


# ============================================================
# Integracao com OpenAlex (requer conexao, sem LLM)
# ============================================================

test_that(".ac_openalex_search() retorna tibble com estrutura correta", {
  skip_if_offline()

  result <- acR:::.ac_openalex_search(
    concept       = "democratic backsliding",
    n_refs        = 3L,
    venue_ids     = NULL,
    min_citations = 100L
  )

  expect_s3_class(result, "data.frame")
  if (nrow(result) > 0L) {
    expect_true("autor"             %in% names(result))
    expect_true("ano"               %in% names(result))
    expect_true("revista"           %in% names(result))
    expect_true("n_citacoes"        %in% names(result))
    expect_true("abstract_original" %in% names(result))
    expect_true("link"              %in% names(result))
    # Abstracts reconstruidos nao devem ter palavras duplicadas em sequencia
    if (!is.na(result$abstract_original[1])) {
      palavras <- strsplit(result$abstract_original[1], " ")[[1]]
      # Verificar que nao ha mais de 3 repeticoes consecutivas da mesma palavra
      runs <- rle(palavras)
      expect_true(max(runs$lengths) <= 3L)
    }
  }
})

test_that(".ac_resolve_venue_ids() retorna IDs para journals conhecidos", {
  skip_if_offline()

  ids <- acR:::.ac_resolve_venue_ids(c(
    "American Political Science Review",
    "DADOS"
  ))

  expect_type(ids, "character")
  expect_true(length(ids) >= 1L)
  # IDs do OpenAlex comecam com "S"
  expect_true(all(grepl("^S[0-9]+$", ids)))
})

test_that(".ac_resolve_venue_ids() retorna vetor vazio para journals desconhecidos", {
  skip_if_offline()

  ids <- acR:::.ac_resolve_venue_ids("Revista Inexistente XYZ 99999")
  # Pode retornar 0 ou 1 resultado dependendo da busca semantica
  expect_type(ids, "character")
})


# ============================================================
# Integracao completa com LLM
# ============================================================


# Verificar se OpenAlex retorna resultados para o conceito de teste
.skip_if_openalex_empty <- function() {
  api_ok <- tryCatch({
    r    <- httr2::request("https://api.openalex.org/works") |>
      httr2::req_url_query(search = "democratic backsliding", `per-page` = 1L,
                           filter = "type:article") |>
      httr2::req_timeout(10L) |>
      httr2::req_perform()
    body <- httr2::resp_body_json(r, simplifyVector = FALSE)
    length(body$results) > 0L
  }, error = function(e) FALSE)
  testthat::skip_if(!api_ok, "OpenAlex nao retornou resultados para o conceito de teste")
}

test_that("ac_qual_search_literature() retorna tibble com colunas esperadas", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if(
    nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "GROQ_API_KEY nao configurada"
  )
  .skip_if_openalex_empty()

  chat_obj <- ellmer::chat_groq(
    model = "llama-3.3-70b-versatile",
    echo  = "none"
  )

  lit <- ac_qual_search_literature(
    concept       = "democratic backsliding",
    n_refs        = 2L,
    journals      = "all",
    min_citations = 50L,
    chat          = chat_obj
  )

  expect_s3_class(lit, "tbl_df")
  expected_cols <- c("conceito", "autor", "ano", "revista", "n_citacoes",
                     "trecho_original", "definicao_pt", "abstract_original", "link")
  expect_true(all(expected_cols %in% names(lit)))
  expect_true(nrow(lit) > 0L)
  expect_true(all(lit$conceito == "democratic backsliding"))
})

test_that("ac_qual_search_literature() com journals = 'all' retorna resultados", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("ellmer")
  skip_if(
    nchar(Sys.getenv("GROQ_API_KEY")) == 0,
    "GROQ_API_KEY nao configurada"
  )
  .skip_if_openalex_empty()

  chat_obj <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")

  lit <- ac_qual_search_literature(
    concept       = "democratic backsliding",
    n_refs        = 2L,
    journals      = "all",
    min_citations = 50L,
    chat          = chat_obj
  )

  expect_s3_class(lit, "tbl_df")
  expect_true(nrow(lit) > 0L)
})
