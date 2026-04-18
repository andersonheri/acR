# Testes para ac_import()
# ac_import() depende de readtext (Suggests) para formatos de texto
# e tesseract (Suggests) para OCR.
# Testes de formato real usam skip_if_not_installed("readtext").
# Testes de validacao de entrada e id_from sao puros R.

# ============================================================
# Validacoes de entrada — sem dependencias externas
# ============================================================

test_that("ac_import() falha com arquivo inexistente e sem glob", {
  # Sem readtext instalado, o erro vem antes (nenhum arquivo compativel)
  # Com readtext, o erro vem do readtext::readtext()
  # Em ambos os casos, deve gerar um erro
  expect_error(
    ac_import("arquivo_que_nao_existe_xyz.txt"),
    class = "error"
  )
})

test_that("ac_import() falha com formato nao suportado", {
  tmp <- tempfile(fileext = ".xyz123")
  writeLines("conteudo", tmp)
  on.exit(unlink(tmp))

  expect_error(
    ac_import(tmp),
    regexp = "compativel"
  )
})


# ============================================================
# Arquivos TXT — sem dependencia de readtext
# (readtext suporta TXT nativamente, mas vamos testar via
#  mock do readtext para evitar dependencia obrigatoria)
# ============================================================

test_that("ac_import() com TXT retorna ac_corpus via readtext", {
  skip_if_not_installed("readtext")

  tmp <- tempfile(fileext = ".txt")
  writeLines("Este e um texto de teste para importacao.", tmp)
  on.exit(unlink(tmp))

  corp <- ac_import(tmp)
  expect_true(is_ac_corpus(corp))
  expect_equal(nrow(corp), 1L)
})

test_that("ac_import() com dois TXTs retorna corpus com 2 documentos", {
  skip_if_not_installed("readtext")

  tmp1 <- tempfile(fileext = ".txt")
  tmp2 <- tempfile(fileext = ".txt")
  writeLines("Texto do documento um.", tmp1)
  writeLines("Texto do documento dois.", tmp2)
  on.exit({ unlink(tmp1); unlink(tmp2) })

  corp <- ac_import(c(tmp1, tmp2))
  expect_true(is_ac_corpus(corp))
  expect_equal(nrow(corp), 2L)
})

test_that("ac_import() id_from = 'rownum' gera IDs sequenciais", {
  skip_if_not_installed("readtext")

  tmp1 <- tempfile(fileext = ".txt")
  tmp2 <- tempfile(fileext = ".txt")
  writeLines("Texto A.", tmp1)
  writeLines("Texto B.", tmp2)
  on.exit({ unlink(tmp1); unlink(tmp2) })

  corp <- ac_import(c(tmp1, tmp2), id_from = "rownum")
  expect_true(is_ac_corpus(corp))
  expect_true(all(grepl("^doc_", corp$doc_id)))
})

test_that("ac_import() id_from como vetor usa IDs fornecidos", {
  skip_if_not_installed("readtext")

  tmp1 <- tempfile(fileext = ".txt")
  tmp2 <- tempfile(fileext = ".txt")
  writeLines("Texto A.", tmp1)
  writeLines("Texto B.", tmp2)
  on.exit({ unlink(tmp1); unlink(tmp2) })

  corp <- ac_import(c(tmp1, tmp2), id_from = c("meu_doc_1", "meu_doc_2"))
  expect_true(is_ac_corpus(corp))
  expect_equal(sort(corp$doc_id), c("meu_doc_1", "meu_doc_2"))
})

test_that("ac_import() id_from vetor com tamanho errado gera erro", {
  skip_if_not_installed("readtext")

  tmp1 <- tempfile(fileext = ".txt")
  tmp2 <- tempfile(fileext = ".txt")
  writeLines("Texto A.", tmp1)
  writeLines("Texto B.", tmp2)
  on.exit({ unlink(tmp1); unlink(tmp2) })

  expect_error(
    ac_import(c(tmp1, tmp2), id_from = c("id1", "id2", "id3")),
    regexp = "comprimento"
  )
})

test_that("ac_import() id_from = 'filename' usa nome do arquivo sem extensao", {
  skip_if_not_installed("readtext")

  tmp <- tempfile(pattern = "meu_arquivo_", fileext = ".txt")
  writeLines("Texto de teste.", tmp)
  on.exit(unlink(tmp))

  corp <- ac_import(tmp, id_from = "filename")
  expect_true(is_ac_corpus(corp))
  # ID deve ser o basename sem extensao — tempfile() gera hash no nome
  expected_id <- tools::file_path_sans_ext(basename(tmp))
  expect_equal(corp$doc_id[1], expected_id)
  expect_false(grepl("\\.txt$", corp$doc_id[1]))
})


# ============================================================
# CSV com text_field
# ============================================================

test_that("ac_import() com CSV e text_field retorna corpus correto", {
  skip_if_not_installed("readtext")

  tmp <- tempfile(fileext = ".csv")
  write.csv(
    data.frame(id = "d1", texto = "Texto alpha."),
    tmp, row.names = FALSE
  )
  corp <- ac_import(tmp, text_field = "texto")
  expect_true(is_ac_corpus(corp))
  expect_equal(nrow(corp), 1L)
})


# ============================================================
# Glob
# ============================================================

test_that("ac_import() com glob importa multiplos arquivos do diretorio", {
  skip_if_not_installed("readtext")

  dir_tmp <- tempdir()
  f1 <- file.path(dir_tmp, "acR_test_glob_a.txt")
  f2 <- file.path(dir_tmp, "acR_test_glob_b.txt")
  writeLines("Documento glob A.", f1)
  writeLines("Documento glob B.", f2)
  on.exit({ unlink(f1); unlink(f2) })

  glob <- file.path(dir_tmp, "acR_test_glob_*.txt")
  corp <- ac_import(glob)
  expect_true(is_ac_corpus(corp))
  expect_equal(nrow(corp), 2L)
})
