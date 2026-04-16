test_that("ac_keyness valida estrutura de entrada", {
  df <- data.frame(token = "A", n = 1)
  expect_error(ac_keyness(df, group = "lado", target = "G1"), class = "rlang_error")
  
  df2 <- data.frame(token = "A", n = 1, lado = "G1")
  # apenas um grupo -> erro
  expect_error(ac_keyness(df2, group = "lado", target = "G1"), class = "rlang_error")
})

test_that("ac_keyness calcula keyness com chi2", {
  corp <- make_corpus_count(
    texts = c("A A A B", "A B", "A B B B", "B B C"),
    ids   = c("d1", "d2", "d3", "d4")
  )
  
  corp$lado <- c("Governo", "Governo", "Oposicao", "Oposicao")
  
  freq <- ac_count(corp, by = "lado")
  
  key <- ac_keyness(freq, group = "lado", target = "Governo", measure = "chi2")
  
  expect_true(all(c("token", "n_target", "n_reference", "keyness", "direction") %in% names(key)))
  
  # Termo A deve ser mais caracteristico do Governo (direction == "Governo")
  dir_A <- key$direction[key$token == "A"]
  expect_equal(dir_A, "Governo")
  
  # Termo B deve ser mais caracteristico da Oposicao
  dir_B <- key$direction[key$token == "B"]
  expect_equal(dir_B, "Oposicao")
})

test_that("ac_keyness calcula keyness com log-likelihood", {
  corp <- make_corpus_count(
    texts = c("A A A B", "A B", "A B B B", "B B C"),
    ids   = c("d1", "d2", "d3", "d4")
  )
  
  corp$lado <- c("Governo", "Governo", "Oposicao", "Oposicao")
  
  freq <- ac_count(corp, by = "lado")
  
  key_ll <- ac_keyness(freq, group = "lado", target = "Governo", measure = "ll")
  
  expect_true(all(c("token", "keyness", "direction") %in% names(key_ll)))
  expect_true(any(key_ll$keyness != 0))
})
