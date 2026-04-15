# Teste placeholder para garantir que a infraestrutura de testes funciona.
# Será expandido conforme os módulos forem implementados.

test_that("o pacote carrega sem erros", {
  expect_true(requireNamespace("acR", quietly = TRUE))
})
