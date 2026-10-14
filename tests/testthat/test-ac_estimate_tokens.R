# Testes para ac_estimate_tokens() / ac_calibrate_tokens() (item 7 da
# revisao de producao: estimativa de tokens para evitar estouro de
# contexto antes de enviar ao LLM).

test_that("ac_estimate_tokens() usa chars_per_token para estimar", {
  texto <- paste(rep("a", 32), collapse = "")  # 32 caracteres
  expect_equal(ac_estimate_tokens(texto, chars_per_token = 3.2), 10L)
})

test_that("ac_estimate_tokens() arredonda para cima (ceiling)", {
  texto <- paste(rep("a", 10), collapse = "")  # 10 caracteres
  expect_equal(ac_estimate_tokens(texto, chars_per_token = 3.2), ceiling(10 / 3.2))
})

test_that("ac_estimate_tokens() e vetorizada", {
  textos <- c("curto", "um texto um pouco mais longo")
  res <- ac_estimate_tokens(textos)
  expect_length(res, 2L)
  expect_true(res[2] > res[1])
})

test_that("ac_estimate_tokens() ignora o argumento chat sem erro", {
  expect_no_error(ac_estimate_tokens("texto", chat = "qualquer coisa"))
})

test_that("ac_calibrate_tokens() exige chat_factory como funcao", {
  expect_error(
    ac_calibrate_tokens("nao e funcao", textos = "x"),
    regexp = "função"
  )
})

test_that("ac_calibrate_tokens() calcula a mediana de caracteres por token observada", {
  make_fake_factory <- function(tokens_por_texto) {
    i <- 0L
    function(temperature, system_prompt) {
      self <- new.env()
      self$chat <- function(msg) "ok"
      self$get_tokens <- function() {
        i <<- i + 1L
        data.frame(input = tokens_por_texto[i])
      }
      self
    }
  }

  textos <- c(
    paste(rep("a", 100), collapse = ""),  # 100 chars
    paste(rep("b", 200), collapse = "")   # 200 chars
  )
  # 100 chars / 25 tokens = 4; 200 chars / 50 tokens = 4 -> mediana 4
  factory <- make_fake_factory(c(25, 50))

  razao <- ac_calibrate_tokens(factory, textos)
  expect_equal(razao, 4)
})
