test_that("ac_fetch_camara() valida formato de data", {
  expect_error(
    ac_fetch_camara("01/01/2024", "2024-06-30"),
    "YYYY-MM-DD"
  )
  expect_error(
    ac_fetch_camara("2024-01-01", "30-06-2024"),
    "YYYY-MM-DD"
  )
  expect_error(
    ac_fetch_camara("2024-13-01", "2024-06-30"),
    "data valida"
  )
})

test_that("ac_fetch_camara() rejeita data_fim anterior a data_inicio", {
  expect_error(
    ac_fetch_camara("2024-06-30", "2024-01-01"),
    "posterior"
  )
})

test_that("ac_fetch_camara() valida tipo_discurso", {
  expect_error(
    ac_fetch_camara("2024-01-01", "2024-06-30", tipo_discurso = "invalido"),
    "arg"
  )
})

test_that(".validate_date() aceita datas válidas", {
  # Não deve lançar erro
  expect_no_error(.validate_date("2024-01-01", "x"))
  expect_no_error(.validate_date("2023-12-31", "x"))
})

test_that(".empty_discursos_df() retorna data.frame com colunas corretas", {
  df <- .empty_discursos_df()
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0)
  expect_true(all(c(
    "id_discurso", "id_deputado", "nome_deputado",
    "partido", "uf", "data", "texto"
  ) %in% names(df)))
})

test_that(".normalize_discursos() padroniza nomes de colunas da API", {
  # Simular resposta bruta da API
  df_api <- data.frame(
    dataHoraInicio = "2024-03-15T10:30:00",
    dataHoraFim    = "2024-03-15T10:45:00",
    tipoDiscurso   = "Discurso",
    transcricao    = "Texto do discurso aqui.",
    sumario        = "Resumo do discurso.",
    uri            = "https://dadosabertos.camara.leg.br/api/v2/...",
    id_deputado    = 123L,
    nome_deputado  = "Deputado Teste",
    partido        = "PT",
    uf             = "SP",
    stringsAsFactors = FALSE
  )

  resultado <- .normalize_discursos(df_api)

  expect_true("texto"        %in% names(resultado))
  expect_true("data"         %in% names(resultado))
  expect_true("hora_inicio"  %in% names(resultado))
  expect_true("uri_discurso" %in% names(resultado))
  expect_true("id_discurso"  %in% names(resultado))

  expect_s3_class(resultado$data, "Date")
  expect_equal(resultado$data, as.Date("2024-03-15"))
  expect_equal(resultado$hora_inicio, "10:30")
  expect_equal(resultado$texto, "Texto do discurso aqui.")
})

test_that(".normalize_discursos() cria id_discurso reproduzível", {
  df <- data.frame(
    dataHoraInicio = c("2024-01-01T09:00:00", "2024-01-02T10:00:00"),
    id_deputado    = c(1L, 2L),
    nome_deputado  = c("A", "B"),
    partido        = c("PT", "PL"),
    uf             = c("SP", "RJ"),
    stringsAsFactors = FALSE
  )

  resultado <- .normalize_discursos(df)
  expect_equal(nrow(resultado), 2)
  expect_true(all(grepl("^cam_", resultado$id_discurso)))
  # IDs devem ser únicos
  expect_equal(length(unique(resultado$id_discurso)), 2)
})

test_that(".check_pkg() lança erro informativo para pacote ausente", {
  # 'pacote_que_nao_existe' nunca estará instalado
  expect_error(
    .check_pkg("pacote_que_nao_existe_acr_test", "minha_funcao"),
    "pacote_que_nao_existe_acr_test"
  )
})

test_that("`%||%` retorna lado esquerdo quando não-NULL e não-NA", {
  expect_equal("valor" %||% "default", "valor")
  expect_equal(NULL    %||% "default", "default")
  expect_equal(NA      %||% "default", "default")
  expect_equal(0L      %||% "default", 0L)
})

# --- Testes de integração (skipped em CI sem internet) -----------------------

test_that("ac_fetch_camara() retorna data.frame com estrutura correta (integração)", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  # Coleta pequena: 5 discursos, 1 semana, partido único
  result <- ac_fetch_camara(
    data_inicio = "2024-03-11",
    data_fim    = "2024-03-15",
    partido     = "PT",
    n_max       = 5,
    verbose     = FALSE
  )

  expect_s3_class(result, "data.frame")
  expect_lte(nrow(result), 5)

  if (nrow(result) > 0) {
    expect_true(all(c(
      "id_discurso", "nome_deputado", "partido", "uf",
      "data", "texto"
    ) %in% names(result)))
    expect_s3_class(result$data, "Date")
    expect_equal(unique(result$partido), "PT")
  }
})

test_that("ac_fetch_camara() respeita n_max (integração)", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  n <- 3L
  result <- ac_fetch_camara(
    data_inicio = "2024-02-01",
    data_fim    = "2024-02-28",
    n_max       = n,
    verbose     = FALSE
  )

  expect_lte(nrow(result), n)
})

test_that("ac_fetch_camara() retorna df vazio com filtros sem resultado (integração)", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  # Partido inexistente — deve retornar aviso e df vazio
  expect_warning(
    result <- ac_fetch_camara(
      data_inicio = "2024-01-01",
      data_fim    = "2024-01-07",
      partido     = "PARTIDO_INEXISTENTE_XYZ",
      n_max       = 10,
      verbose     = FALSE
    )
  )

  expect_equal(nrow(result), 0)
})
