# Testes para ac_corpus() e métodos relacionados
# Cobertura: construção a partir de data.frame, character, quanteda::corpus;
# validações; métodos S3 (print, summary, format, as_tibble); função auxiliar
# is_ac_corpus().

# ============================================================================
# Construção a partir de data.frame
# ============================================================================

test_that("ac_corpus() funciona com data.frame mínimo", {
  df <- data.frame(
    texto = c("Primeiro texto.", "Segundo texto.", "Terceiro.")
  )
  corpus <- ac_corpus(df, text = texto)

  expect_s3_class(corpus, "ac_corpus")
  expect_s3_class(corpus, "tbl_df")
  expect_equal(nrow(corpus), 3)
  expect_equal(names(corpus)[1:2], c("doc_id", "text"))
  expect_equal(corpus$text, c("Primeiro texto.", "Segundo texto.", "Terceiro."))
  expect_equal(corpus$doc_id, c("doc_1", "doc_2", "doc_3"))
})

test_that("ac_corpus() preserva docid personalizado", {
  df <- data.frame(
    id = c("a", "b", "c"),
    texto = c("Um", "Dois", "Três")
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  expect_equal(corpus$doc_id, c("a", "b", "c"))
})

test_that("ac_corpus() preserva metadados especificados", {
  df <- data.frame(
    id = c("a", "b"),
    texto = c("X", "Y"),
    partido = c("PT", "PL"),
    data = as.Date(c("2023-01-01", "2023-02-01")),
    ignorar = c(1, 2)
  )
  corpus <- ac_corpus(df, text = texto, docid = id, meta = c(partido, data))

  expect_equal(ncol(corpus), 4)  # doc_id, text, partido, data
  expect_true(all(c("partido", "data") %in% names(corpus)))
  expect_false("ignorar" %in% names(corpus))
})

test_that("ac_corpus() preserva todos os metadados quando meta=NULL", {
  df <- data.frame(
    id = c("a", "b"),
    texto = c("X", "Y"),
    var1 = c(1, 2),
    var2 = c("p", "q")
  )
  corpus <- ac_corpus(df, text = texto, docid = id)

  expect_equal(ncol(corpus), 4)  # doc_id, text, var1, var2
  expect_true(all(c("var1", "var2") %in% names(corpus)))
})

# ============================================================================
# Construção a partir de vetor character
# ============================================================================

test_that("ac_corpus() funciona com vetor character", {
  corpus <- ac_corpus(c("Texto um.", "Texto dois."))

  expect_s3_class(corpus, "ac_corpus")
  expect_equal(nrow(corpus), 2)
  expect_equal(corpus$doc_id, c("doc_1", "doc_2"))
  expect_equal(corpus$text, c("Texto um.", "Texto dois."))
})

test_that("ac_corpus() falha com vetor character vazio", {
  expect_error(
    ac_corpus(character(0)),
    regexp = "vazio"
  )
})

# ============================================================================
# Detecção automática de coluna de texto
# ============================================================================

test_that("ac_corpus() detecta automaticamente coluna 'text'", {
  df <- data.frame(text = c("A", "B"), autor = c("X", "Y"))
  corpus <- ac_corpus(df)
  expect_equal(corpus$text, c("A", "B"))
})

test_that("ac_corpus() detecta automaticamente coluna 'texto'", {
  df <- data.frame(texto = c("A", "B"))
  corpus <- ac_corpus(df)
  expect_equal(corpus$text, c("A", "B"))
})

test_that("ac_corpus() detecta automaticamente coluna 'content'", {
  df <- data.frame(content = c("A", "B"))
  corpus <- ac_corpus(df)
  expect_equal(corpus$text, c("A", "B"))
})

test_that("ac_corpus() falha quando não detecta coluna de texto", {
  df <- data.frame(col1 = c("A", "B"), col2 = c("X", "Y"))
  expect_error(
    ac_corpus(df),
    regexp = "detectar a coluna de texto"
  )
})

# ============================================================================
# Validações obrigatórias
# ============================================================================

test_that("ac_corpus() rejeita tipo de entrada não suportado", {
  expect_error(
    ac_corpus(list(a = 1)),
    regexp = "data.frame"
  )
  expect_error(
    ac_corpus(42),
    regexp = "data.frame"
  )
})

test_that("ac_corpus() rejeita coluna de texto inexistente", {
  df <- data.frame(x = 1:3)
  expect_error(
    ac_corpus(df, text = inexistente),
    regexp = "n\u00e3o existe"
  )
})

test_that("ac_corpus() rejeita texto inteiramente vazio ou NA", {
  df1 <- data.frame(texto = c("", "", ""))
  expect_error(ac_corpus(df1, text = texto), regexp = "vazia")

  df2 <- data.frame(texto = as.character(c(NA, NA, NA)))
  expect_error(ac_corpus(df2, text = texto), regexp = "vazia")
})

test_that("ac_corpus() avisa sobre textos vazios parciais", {
  df <- data.frame(texto = c("A", "", "C"))
  expect_warning(
    corpus <- ac_corpus(df, text = texto),
    regexp = "vazio"
  )
  expect_equal(nrow(corpus), 3)
})

test_that("ac_corpus() rejeita doc_id duplicado", {
  df <- data.frame(
    id = c("a", "a", "b"),
    texto = c("X", "Y", "Z")
  )
  expect_error(
    ac_corpus(df, text = texto, docid = id),
    regexp = "duplicados"
  )
})

test_that("ac_corpus() rejeita doc_id com NA", {
  df <- data.frame(
    id = c("a", NA, "c"),
    texto = c("X", "Y", "Z")
  )
  expect_error(
    ac_corpus(df, text = texto, docid = id),
    regexp = "NA"
  )
})

test_that("ac_corpus() rejeita docid em coluna inexistente", {
  df <- data.frame(texto = c("A", "B"))
  expect_error(
    ac_corpus(df, text = texto, docid = inexistente),
    regexp = "n\u00e3o existe"
  )
})

# ============================================================================
# Atributos
# ============================================================================

test_that("ac_corpus() atribui atributo lang", {
  corpus <- ac_corpus(c("A", "B"), lang = "en")
  expect_equal(attr(corpus, "lang"), "en")
})

test_that("ac_corpus() usa lang='pt' por padrão", {
  corpus <- ac_corpus(c("A", "B"))
  expect_equal(attr(corpus, "lang"), "pt")
})

# ============================================================================
# Avisos sobre argumentos extras
# ============================================================================

test_that("ac_corpus() avisa sobre argumentos extras desconhecidos", {
  expect_warning(
    ac_corpus(c("A", "B"), argumento_inexistente = TRUE),
    regexp = NA  # vetor character não passa por ... — esse teste precisa de data.frame
  )

  df <- data.frame(texto = c("A", "B"))
  expect_warning(
    ac_corpus(df, text = texto, xyz = 1),
    regexp = "ignorado"
  )
})

# ============================================================================
# Métodos S3
# ============================================================================

test_that("print.ac_corpus() funciona sem erro", {
  corpus <- ac_corpus(c("A", "B"))
  # Captura o output combinado (stdout + stderr) do cli
  out <- capture.output(print(corpus), type = "message")
  out <- c(out, capture.output(print(corpus), type = "output"))
  combined <- paste(out, collapse = "\n")
  expect_true(nchar(combined) > 0)
  # Teste mais tolerante: verifica que print retorna o próprio objeto (invisível)
  expect_invisible(print(corpus))
})

test_that("summary.ac_corpus() retorna estatísticas corretas", {
  corpus <- ac_corpus(c("A", "BB", "CCC"))
  s <- summary(corpus)

  expect_s3_class(s, "summary.ac_corpus")
  expect_equal(s$n_documents, 3)
  expect_equal(s$lang, "pt")
  expect_equal(s$chars[["min"]], 1)
  expect_equal(s$chars[["max"]], 3)
})

test_that("format.ac_corpus() retorna string esperada", {
  corpus <- ac_corpus(c("A", "B"), lang = "en")
  expect_equal(format(corpus), "<ac_corpus: 2 docs, lang=en>")
})

test_that("as_tibble.ac_corpus() remove classe ac_corpus", {
  corpus <- ac_corpus(c("A", "B"))
  tbl <- tibble::as_tibble(corpus)

  expect_s3_class(tbl, "tbl_df")
  expect_false(inherits(tbl, "ac_corpus"))
  expect_null(attr(tbl, "lang"))
})

# ============================================================================
# Função auxiliar is_ac_corpus()
# ============================================================================

test_that("is_ac_corpus() identifica corretamente", {
  corpus <- ac_corpus(c("A", "B"))
  expect_true(is_ac_corpus(corpus))

  expect_false(is_ac_corpus(data.frame()))
  expect_false(is_ac_corpus("texto"))
  expect_false(is_ac_corpus(NULL))
  expect_false(is_ac_corpus(list()))
  expect_false(is_ac_corpus(tibble::tibble(doc_id = "a", text = "b")))
})

# ============================================================================
# Integração com quanteda (opcional, pula se não instalado)
# ============================================================================

test_that("ac_corpus() converte quanteda::corpus corretamente", {
  skip_if_not_installed("quanteda")

  qc <- quanteda::corpus(
    c("Texto um.", "Texto dois."),
    docnames = c("d1", "d2"),
    docvars = data.frame(partido = c("PT", "PL"))
  )
  corpus <- ac_corpus(qc)

  expect_s3_class(corpus, "ac_corpus")
  expect_equal(nrow(corpus), 2)
  expect_equal(corpus$doc_id, c("d1", "d2"))
  expect_true("partido" %in% names(corpus))
})
