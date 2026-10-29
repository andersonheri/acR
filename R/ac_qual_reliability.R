#' Calcular confiabilidade entre codificação LLM e humana
#'
#' @description
#' `ac_qual_reliability()` calcula métricas de concordância entre a
#' classificação feita pela LLM e uma classificação humana de referência,
#' com intervalos de confiança via bootstrap.
#'
#' É a **última porta antes de publicar** um estudo de análise de conteúdo
#' assistida por LLM. Nenhuma referência metodológica atual (Krippendorff,
#' 2018; Gwet, 2014; Gilardi et al., 2023) aceita rotulagem automática sem
#' um subconjunto codificado por humano e concordância documentada.
#'
#' Quatro métricas são computadas por padrão, cada uma respondendo a uma
#' pergunta diferente:
#'
#' * **Percent agreement** (`percent_agreement`): fração de documentos em
#'   que LLM e humano concordam. Fácil de reportar, mas ignora concordância
#'   por acaso: infla para categorias binárias com distribuição desigual.
#' * **Alpha de Krippendorff** (`krippendorff`): padrão-ouro em análise de
#'   conteúdo. Corrige por acaso, aceita missings, funciona com qualquer
#'   número de categorias. Krippendorff (2018, sec. 12.4) recomenda
#'   alfa >= 0,800 para conclusões sem ressalvas e 0,667 <= alfa < 0,800
#'   apenas para conclusões provisórias; abaixo de 0,667 os dados não
#'   devem sustentar conclusões.
#' * **AC1 de Gwet** (`gwet_ac1`): alternativa mais estável quando as
#'   categorias são muito desbalanceadas (o "paradoxo do kappa" de
#'   Feinstein & Cicchetti, 1990: kappa despenca mesmo com alta
#'   concordância observada se uma categoria domina). Gwet (2014) propõe
#'   o AC1 justamente para esse caso.
#' * **F1 macro** (`f1_macro`): média não ponderada dos F1 por categoria
#'   (Sokolova & Lapalme, 2009). Útil quando você quer garantir que a LLM
#'   está indo bem também nas categorias raras, não só nas frequentes.
#'   **Não** é corrigido por acaso, então não deve ser lido com as faixas
#'   de Landis & Koch (1977), que foram propostas para o kappa.
#'
#' ## Como a coluna `interpretation` é preenchida
#'
#' Cada métrica usa a referência própria dela, para não misturar escalas:
#'
#' * **Alpha de Krippendorff**: `>= 0,800` confiável; `0,667-0,800` só
#'   conclusões provisórias; `< 0,667` insuficiente (Krippendorff, 2018).
#' * **AC1 de Gwet**: faixas de Landis & Koch (1977): `< 0` pobre;
#'   `0-0,20` leve; `0,21-0,40` razoável; `0,41-0,60` moderada;
#'   `0,61-0,80` substancial; `0,81-1` quase perfeita. Gwet (2014, cap. 6)
#'   usa essas faixas como referência de *benchmarking*.
#' * **Percent agreement**: `>= 0,90` alta; `0,80-0,90` aceitável na
#'   maioria dos casos; `0,70-0,80` só em estudos exploratórios; `< 0,70`
#'   insuficiente (Neuendorf, 2017; Lombard, Snyder-Duch & Bracken, 2002).
#' * **F1 macro**: não há faixa canônica na literatura; o valor é
#'   reportado sem rótulo qualitativo.
#'
#' Essas faixas são convenções, não testes estatísticos: o próprio Landis
#' & Koch (1977, p. 165) as chamam de arbitrárias. Por isso o IC
#' *bootstrap* importa: um alfa de 0,82 com IC de 0,61 a 0,95 **não**
#' permite afirmar que a confiabilidade passa de 0,800 (Krippendorff,
#' 2018, sec. 12.5, decide justamente pela probabilidade de o alfa ficar
#' abaixo do mínimo exigido).
#'
#' Intervalos de confiança de 95% vêm de *bootstrap* não paramétrico
#' (padrão: 1000 réplicas). Reporte pelo menos Krippendorff e F1 macro
#' no artigo, com os ICs; discuta divergências humano × LLM em amostra
#' de casos representativos.
#'
#' @param llm Tibble com classificação LLM, saída de [ac_qual_code()].
#' @param human Tibble com classificação humana, saída de
#'   [ac_qual_import_human()].
#' @param cat_col Nome da coluna de categoria. Padrão: `"categoria"`.
#' @param metrics Vetor de métricas a calcular. Padrão:
#'   `c("krippendorff", "gwet_ac1", "f1_macro", "percent_agreement")`.
#' @param bootstrap Número de amostras bootstrap para IC. Padrão: `1000`.
#' @param ci_level Nível de confiança do IC. Padrão: `0.95`.
#' @param by_variable Lógico. Se `TRUE`, calcula também métricas binárias
#'   (concordância, precisão, recall, F1, Gwet AC1, alfa de Krippendorff)
#'   para cada categoria do codebook individualmente, tratando a presença
#'   de cada categoria como um problema sim/não: essencial quando
#'   `multilabel = TRUE`, onde um único `categoria` (`"a|b"`) mistura
#'   várias decisões binárias independentes que as métricas agregadas
#'   (acima) não conseguem diagnosticar separadamente. Denominadores
#'   zero (ex.: uma categoria nunca escolhida por nenhum dos dois lados)
#'   geram `NA`, nunca `0` ou `1` artificiais. Padrão `FALSE`.
#' @param exclude_status Vetor de valores da coluna `status` (ver
#'   [ac_qual_code()]) a excluir da comparação antes de calcular as
#'   métricas por variável: documentos que falharam na classificação
#'   não têm uma categoria confiável para comparar. Ignorado se `llm`
#'   não tiver coluna `status`. Padrão:
#'   `c("estouro_contexto", "limite_taxa", "timeout", "erro_servidor",
#'   "parcial")`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas: `metric`, `estimate`, `ci_lower`, `ci_upper`,
#'   `interpretation`. Quando `by_variable = TRUE`, o resultado carrega
#'   também um atributo `by_variable`: um tibble com uma linha por
#'   categoria do codebook e colunas `categoria`, `n`, `vp`, `fp`, `fn`,
#'   `vn`, `concordância`, `precisao`, `recall`, `f1`, `gwet_ac1`,
#'   `krippendorff_alfa`.
#'
#' @references
#' Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
#' Methodology* (4th ed.). SAGE.
#'
#' Gwet, K. L. (2014). *Handbook of Inter-Rater Reliability* (4th ed.).
#' Advanced Analytics.
#'
#' Landis, J. R.; Koch, G. G. (1977). The Measurement of Observer Agreement
#' for Categorical Data. *Biometrics*, 33(1), 159-174.
#'
#' Feinstein, A. R.; Cicchetti, D. V. (1990). High agreement but low
#' kappa: I. The problems of two paradoxes. *Journal of Clinical
#' Epidemiology*, 43(6), 543-549.
#'
#' Lombard, M.; Snyder-Duch, J.; Bracken, C. C. (2002). Content analysis
#' in mass communication: Assessment and reporting of intercoder
#' reliability. *Human Communication Research*, 28(4), 587-604.
#'
#' Neuendorf, K. A. (2017). *The Content Analysis Guidebook* (2nd ed.).
#' SAGE.
#'
#' Sokolova, M.; Lapalme, G. (2009). A systematic analysis of performance
#' measures for classification tasks. *Information Processing &
#' Management*, 45(4), 427-437.
#'
#' @examples
#' # Simular saidas: LLM (coded) e revisao humana (humano_df)
#' # ambos com as colunas doc_id + categoria
#' coded <- tibble::tibble(
#'   doc_id    = paste0("d", 1:5),
#'   categoria = c("favor", "contra", "favor", "contra", "favor")
#' )
#' humano_df <- tibble::tibble(
#'   doc_id    = paste0("d", 1:5),
#'   categoria = c("favor", "contra", "contra", "contra", "favor")
#' )
#'
#' # Calcular métricas de confiabilidade (bootstrap curto so para demonstrar;
#' # em uso real, deixe o padrao de 1000 replicas)
#' rel <- ac_qual_reliability(
#'   llm       = coded,
#'   human     = humano_df,
#'   bootstrap = 50
#' )
#' print(rel)
#'
#' @concept qualitative
#' @export
ac_qual_reliability <- function(llm,
                                 human,
                                 cat_col   = "categoria",
                                 metrics   = c("krippendorff", "gwet_ac1",
                                               "f1_macro", "percent_agreement"),
                                 bootstrap = 1000L,
                                 ci_level  = 0.95,
                                 by_variable    = FALSE,
                                 exclude_status = c("estouro_contexto", "limite_taxa", "timeout",
                                                    "erro_servidor", "parcial"),
                                 ...) {

  if (!is.data.frame(llm) || !cat_col %in% names(llm)) {
    cli::cli_abort(c(
      "{.arg llm} deve ser um tibble com coluna {.val {cat_col}}.",
      "i" = "Use a sa\u00edda de {.fn ac_qual_code}."
    ))
  }
  if (!is.data.frame(human) || !cat_col %in% names(human)) {
    cli::cli_abort(c(
      "{.arg human} deve ser um tibble com coluna {.val {cat_col}}.",
      "i" = "Use a sa\u00edda de {.fn ac_qual_import_human}."
    ))
  }

  # Alinhar por doc_id
  joined <- dplyr::inner_join(
    llm   |> dplyr::select("doc_id", llm_cat   = dplyr::all_of(cat_col)),
    human |> dplyr::select("doc_id", human_cat = dplyr::all_of(cat_col)),
    by = "doc_id"
  )

  if (nrow(joined) == 0L) {
    cli::cli_abort("Nenhum documento em comum entre {.arg llm} e {.arg human}.")
  }

  n_common <- nrow(joined)
  cli::cli_inform("Calculando confiabilidade em {n_common} documentos comuns...")

  llm_vec   <- joined$llm_cat
  human_vec <- joined$human_cat

  results_list <- list()

  # Percent agreement
  if ("percent_agreement" %in% metrics) {
    pa    <- mean(llm_vec == human_vec, na.rm = TRUE)
    pa_ci <- .ac_bootstrap_metric(
      llm_vec, human_vec, bootstrap, ci_level,
      function(l, h) mean(l == h, na.rm = TRUE)
    )
    results_list[["percent_agreement"]] <- tibble::tibble(
      metric         = "percent_agreement",
      estimate       = pa,
      ci_lower       = pa_ci[1],
      ci_upper       = pa_ci[2],
      interpretation = .ac_interpret_agreement(pa, "percent")
    )
  }

  # Krippendorff alpha
  if ("krippendorff" %in% metrics) {
    if (!requireNamespace("irr", quietly = TRUE)) {
      cli::cli_warn("{.pkg irr} n\u00e3o instalado. Pulando Krippendorff \u03b1.")
    } else {
      alpha <- .ac_kripp_nominal(llm_vec, human_vec)
      alpha_ci <- if (!is.na(alpha)) {
        .ac_bootstrap_metric(llm_vec, human_vec, bootstrap, ci_level,
                             .ac_kripp_nominal)
      } else c(NA_real_, NA_real_)

      results_list[["krippendorff"]] <- tibble::tibble(
        metric         = "krippendorff_alpha",
        estimate       = alpha,
        ci_lower       = alpha_ci[1],
        ci_upper       = alpha_ci[2],
        interpretation = .ac_interpret_agreement(alpha, "alpha")
      )
    }
  }

  # Gwet AC1

  # Gwet AC1: implementacao propria (Gwet, 2014)
  if ("gwet_ac1" %in% metrics) {
    gwet <- .ac_gwet_ac1(llm_vec, human_vec)
    gwet_ci <- if (!is.na(gwet)) {
      .ac_bootstrap_metric(llm_vec, human_vec, bootstrap, ci_level,
        function(l, h) .ac_gwet_ac1(l, h)
      )
    } else c(NA_real_, NA_real_)

    results_list[["gwet_ac1"]] <- tibble::tibble(
      metric         = "gwet_ac1",
      estimate       = gwet,
      ci_lower       = gwet_ci[1],
      ci_upper       = gwet_ci[2],
      interpretation = .ac_interpret_agreement(gwet, "kappa")
    )
  }

  # F1 macro
  if ("f1_macro" %in% metrics) {
    f1 <- .ac_compute_f1_macro(llm_vec, human_vec)
    f1_ci <- .ac_bootstrap_metric(llm_vec, human_vec, bootstrap, ci_level,
      function(l, h) .ac_compute_f1_macro(l, h)
    )
    results_list[["f1_macro"]] <- tibble::tibble(
      metric         = "f1_macro",
      estimate       = f1,
      ci_lower       = f1_ci[1],
      ci_upper       = f1_ci[2],
      interpretation = .ac_interpret_agreement(f1, "f1")
    )
  }

  result <- dplyr::bind_rows(results_list)

  cli::cli_inform(c(
    "i" = "Interpreta\u00e7\u00e3o: alfa por Krippendorff (2018); AC1 por Landis & Koch (1977) e Gwet (2014); percentual por Neuendorf (2017); F1 sem r\u00f3tulo.",
    "i" = "IC {ci_level*100}% via bootstrap (n = {bootstrap})."
  ))

  if (by_variable) {
    attr(result, "by_variable") <- .ac_reliability_by_variable(
      llm, human, cat_col, exclude_status
    )
  }

  result
}


#' Amostrar documentos para validação humana
#'
#' @description
#' `ac_qual_sample()` seleciona uma amostra de documentos classificados pela
#' LLM para validação por um codificador humano.
#'
#' **Duas finalidades diferentes, duas estratégias diferentes.**
#'
#' 1. *Estimar a confiabilidade* que vai para o artigo
#'    ([ac_qual_reliability()]): a amostra precisa ser **representativa**
#'    do corpus. Krippendorff (2018, cap. 12) exige que os dados de
#'    confiabilidade sejam amostrados da mesma população que os dados
#'    analisados; uma amostra enviesada para casos difíceis subestima a
#'    concordância real, e uma enviesada para casos fáceis a superestima.
#'    Use `"random"` (padrão) ou `"proportional"`.
#' 2. *Diagnosticar erros* e refinar o codebook: aí vale concentrar o
#'    esforço humano onde a LLM mais erra, como em amostragem por incerteza
#'    de *active learning* (Settles, 2012). Use `"uncertainty"` ou
#'    `"disagreement"`, mas **não** reporte a concordância calculada nessa
#'    amostra como confiabilidade do corpus.
#'
#' Sobre o tamanho: Neuendorf (2017) sugere uma subamostra de
#' confiabilidade de 10% a 20% do corpus, raramente menos de 50 unidades;
#' Krippendorff (2018, sec. 12.3) oferece um cálculo formal a partir do
#' alfa mínimo aceitável e da frequência da categoria mais rara.
#'
#' @param coded Tibble com classificação LLM, saída de [ac_qual_code()].
#' @param n Número de documentos a amostrar. Padrão: `50`.
#' @param strategy Estratégia de amostragem:
#'   * `"random"` (padrão): amostra aleatória simples. Representativa:
#'     use para estimar a confiabilidade que vai para o artigo;
#'   * `"uncertainty"`: prioriza documentos com menor `confidence_score`
#'     (maior incerteza da LLM). Serve para diagnóstico de erros, **não**
#'     para estimar confiabilidade (amostra enviesada para casos difíceis);
#'   * `"stratified"`: divide `n` igualmente entre as categorias atribuídas
#'     pela LLM (sobre-representa categorias raras; não é representativa);
#'   * `"disagreement"`: prioriza documentos onde rodadas de self-consistency
#'     divergiram (requer `confidence_score < 1`);
#'   * `"proportional"`: amostragem estratificada com alocação
#'     proporcional ao tamanho de cada estrato (método do maior resto),
#'     respeitando um mínimo por estrato. Diferente de `"stratified"`
#'     (que divide `n` igualmente entre categorias), preserva a
#'     distribuição original de `strata` na amostra: a escolha correta
#'     quando a amostra alimenta uma estimativa populacional (ex.:
#'     `ac_qual_reliability()` ponderada), não só uma checagem
#'     qualitativa de cada categoria.
#' @param strata Nome da coluna usada para estratificar quando
#'   `strategy = "proportional"`. Obrigatório nesse caso.
#' @param min_per_stratum Mínimo de documentos por estrato na amostra
#'   proporcional, mesmo que a alocação exata dê menos. Padrão `1`.
#' @param min_stratum_size Estratos da população com menos documentos
#'   que isso são agrupados em `"Outras"` antes de alocar: evita
#'   alocar uma fração ínfima da amostra a uma categoria com 2
#'   documentos na população inteira. Padrão `10`.
#' @param exclude_ids Vetor de `doc_id` a excluir do universo amostrado
#'   (ex.: documentos já validados em uma rodada anterior). Padrão
#'   `NULL`.
#' @param seed Semente para reprodutibilidade. Padrão: `42`.
#' @param ... Ignorado.
#'
#' @references
#' Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
#' Methodology* (4th ed.). SAGE.
#'
#' Neuendorf, K. A. (2017). *The Content Analysis Guidebook* (2nd ed.).
#' SAGE.
#'
#' Settles, B. (2012). *Active Learning*. Morgan & Claypool.
#'
#' @return Tibble com os documentos selecionados, incluindo uma coluna
#'   `sample_reason` indicando por que cada documento foi selecionado.
#'   Com `strategy = "proportional"`, ganha também `peso_amostral`
#'   (`n_populacao_estrato / n_amostra_estrato`) para uso em estimativas
#'   ponderadas.
#'
#' @examples
#' # Simular saida de ac_qual_code() com 20 documentos já classificados
#' set.seed(1)
#' coded <- tibble::tibble(
#'   doc_id           = paste0("doc_", 1:20),
#'   categoria        = sample(c("favor", "contra"), 20, replace = TRUE),
#'   confidence_score = runif(20, 0.5, 1.0)
#' )
#'
#' # Amostra representativa (padrao): para estimar a confiabilidade
#' ac_qual_sample(coded, n = 5)
#'
#' # Priorizar casos mais incertos: diagnostico de erros, nao confiabilidade
#' ac_qual_sample(coded, n = 5, strategy = "uncertainty")
#'
#' # Garantir cobertura proporcional das duas categorias
#' ac_qual_sample(coded, n = 6, strategy = "stratified")
#'
#' @concept qualitative
#' @export
ac_qual_sample <- function(coded,
                            n        = 50L,
                            strategy = c("random", "uncertainty",
                                         "stratified", "disagreement",
                                         "proportional"),
                            strata           = NULL,
                            min_per_stratum  = 1L,
                            min_stratum_size = 10L,
                            exclude_ids      = NULL,
                            seed     = 42L,
                            ...) {

  if (!is.data.frame(coded)) {
    cli::cli_abort("{.arg coded} deve ser um tibble, sa\u00edda de {.fn ac_qual_code}.")
  }

  strategy <- match.arg(strategy)

  if (!is.null(exclude_ids) && "doc_id" %in% names(coded)) {
    coded <- coded[!coded$doc_id %in% exclude_ids, , drop = FALSE]
  }

  if (strategy == "proportional") {
    if (is.null(strata) || !strata %in% names(coded)) {
      cli::cli_abort(c(
        "{.arg strata} deve ser o nome de uma coluna existente em {.arg coded} quando {.code strategy = \"proportional\"}.",
        "i" = "Colunas dispon\u00edveis: {.val {names(coded)}}."
      ))
    }
  }

  n <- min(as.integer(n), nrow(coded))

  # withr::with_seed escopa o RNG apenas na amostragem; nao altera o
  # .Random.seed do usuario apos o retorno.
  do_sample <- function() {

  if (strategy == "uncertainty") {
    if (!"confidence_score" %in% names(coded)) {
      cli::cli_warn(c(
        "Coluna {.val confidence_score} n\u00e3o encontrada.",
        "i" = "Usando amostragem aleat\u00f3ria."
      ))
      strategy <- "random"
    } else {
      result <- coded |>
        dplyr::arrange(confidence_score) |>
        dplyr::slice_head(n = n) |>
        dplyr::mutate(sample_reason = paste0(
          "uncertainty (confidence=",
          round(confidence_score, 2), ")"
        ))
    }
  }

  if (strategy == "stratified") {
    if (!"categoria" %in% names(coded)) {
      cli::cli_warn("Coluna {.val categoria} n\u00e3o encontrada. Usando aleat\u00f3rio.")
      strategy <- "random"
    } else {
      result <- coded |>
        dplyr::group_by(categoria) |>
        dplyr::slice_sample(
          n = ceiling(n / dplyr::n_groups(dplyr::group_by(coded, categoria)))
        ) |>
        dplyr::ungroup() |>
        dplyr::slice_sample(n = n) |>
        dplyr::mutate(sample_reason = paste0("stratified (cat=", categoria, ")"))
    }
  }

  if (strategy == "disagreement") {
    if (!"confidence_score" %in% names(coded)) {
      cli::cli_warn("Usando amostragem aleat\u00f3ria.")
      strategy <- "random"
    } else {
      result <- coded |>
        dplyr::filter(confidence_score < 1.0) |>
        dplyr::arrange(confidence_score) |>
        dplyr::slice_head(n = n) |>
        dplyr::mutate(sample_reason = "disagreement (self-consistency < 1.0)")
    }
  }

  if (strategy == "random") {
    result <- coded |>
      dplyr::slice_sample(n = n) |>
      dplyr::mutate(sample_reason = "random")
  }

  if (strategy == "proportional") {
    result <- .ac_sample_proportional(coded, n, strata, min_per_stratum, min_stratum_size)
  }

  result
  }  # fim do closure do_sample

  result <- if (is.null(seed)) do_sample() else withr::with_seed(seed, do_sample())

  cli::cli_inform(c(
    "i" = "Amostra de {nrow(result)} documentos selecionada (estrat\u00e9gia: {.val {strategy}}).",
    "i" = "Use {.fn ac_qual_export_for_review} para exportar para Excel."
  ))

  result
}


#' Exportar amostra para revisão humana em Excel
#'
#' @description
#' `ac_qual_export_for_review()` exporta uma amostra de documentos classificados
#' para um arquivo Excel, com colunas para o codificador humano preencher.
#'
#' @param sample Tibble, saída de [ac_qual_sample()].
#' @param path Caminho do arquivo `.xlsx`. Padrão: `"validacao_humana.xlsx"`.
#' @param corpus Objeto `ac_corpus` original (opcional). Se fornecido, inclui
#'   o texto completo de cada documento na planilha.
#' @param ... Ignorado.
#'
#' @return Invisível: caminho do arquivo gerado.
#'
#' @examples
#' if (requireNamespace("openxlsx", quietly = TRUE)) {
#'   # Amostra de documentos já classificados pela LLM
#'   coded <- tibble::tibble(
#'     doc_id           = paste0("doc_", 1:5),
#'     categoria        = c("favor", "contra", "favor", "contra", "favor"),
#'     confidence_score = c(0.6, 0.9, 0.8, 0.7, 0.55)
#'   )
#'   amostra <- ac_qual_sample(coded, n = 3, strategy = "uncertainty")
#'
#'   # Exportar para revisao humana em arquivo temporário
#'   arquivo <- tempfile(fileext = ".xlsx")
#'   ac_qual_export_for_review(amostra, path = arquivo)
#'   file.exists(arquivo)
#' }
#'
#' @concept qualitative
#' @export
ac_qual_export_for_review <- function(sample,
                                       path   = "validacao_humana.xlsx",
                                       corpus = NULL,
                                       ...) {

  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg openxlsx} \u00e9 necess\u00e1rio.",
      "i" = "Instale com {.code install.packages(\"openxlsx\")}."
    ))
  }

  export_df <- sample

  # Adicionar texto completo se corpus fornecido
  if (!is.null(corpus) && is_ac_corpus(corpus)) {
    export_df <- export_df |>
      dplyr::left_join(
        corpus |> tibble::as_tibble() |> dplyr::select("doc_id", "text"),
        by = "doc_id"
      ) |>
      dplyr::relocate(text, .after = doc_id)
  }

  # Adicionar coluna em branco para o humano preencher
  export_df$categoria_humano <- ""
  export_df$notas_humano     <- ""

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "validacao")
  openxlsx::writeData(wb, "validacao", export_df)

  # Formatar cabeçalho
  header_style <- openxlsx::createStyle(
    fontColour = "#FFFFFF",
    fgFill     = "#0072B2",
    halign     = "CENTER",
    textDecoration = "Bold"
  )
  openxlsx::addStyle(wb, "validacao", header_style,
                     rows = 1, cols = 1:ncol(export_df))

  # Destacar colunas para preenchimento humano
  fill_cols <- which(names(export_df) %in% c("categoria_humano", "notas_humano"))
  fill_style <- openxlsx::createStyle(fgFill = "#FFF9C4")
  openxlsx::addStyle(wb, "validacao", fill_style,
                     rows = 2:(nrow(export_df) + 1),
                     cols = fill_cols,
                     gridExpand = TRUE)

  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)

  cli::cli_inform(c(
    "\u2705 Planilha exportada: {.path {path}}",
    "i" = "Preencha a coluna {.val categoria_humano} com a classifica\u00e7\u00e3o.",
    "i" = "Use {.fn ac_qual_import_human} para importar ap\u00f3s preenchimento."
  ))

  invisible(path)
}


#' Importar classificação humana de Excel
#'
#' @description
#' `ac_qual_import_human()` importa um arquivo Excel preenchido por um
#' codificador humano, retornando um tibble compatível com
#' [ac_qual_reliability()].
#'
#' @param path Caminho do arquivo `.xlsx`.
#' @param cat_col Nome da coluna com a classificação humana.
#'   Padrão: `"categoria_humano"`.
#' @param id_col Nome da coluna de identificador. Padrão: `"doc_id"`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas `doc_id` e `categoria`.
#'
#' @examples
#' if (requireNamespace("openxlsx", quietly = TRUE)) {
#'   # Simular uma planilha já preenchida pelo codificador humano
#'   arquivo <- tempfile(fileext = ".xlsx")
#'   openxlsx::write.xlsx(
#'     data.frame(
#'       doc_id           = paste0("doc_", 1:3),
#'       categoria_humano = c("favor", "contra", "favor")
#'     ),
#'     arquivo
#'   )
#'
#'   # Importar de volta para o R para uso com ac_qual_reliability()
#'   humano <- ac_qual_import_human(arquivo)
#'   humano
#' }
#'
#' @concept qualitative
#' @export
ac_qual_import_human <- function(path,
                                  cat_col = "categoria_humano",
                                  id_col  = "doc_id",
                                  ...) {

  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg openxlsx} \u00e9 necess\u00e1rio.")
  }
  if (!file.exists(path)) {
    cli::cli_abort("Arquivo {.path {path}} n\u00e3o encontrado.")
  }

  df <- openxlsx::read.xlsx(path)

  if (!id_col %in% names(df)) {
    cli::cli_abort(c(
      "Coluna {.val {id_col}} n\u00e3o encontrada.",
      "i" = "Colunas dispon\u00edveis: {.val {names(df)}}."
    ))
  }
  if (!cat_col %in% names(df)) {
    cli::cli_abort(c(
      "Coluna {.val {cat_col}} n\u00e3o encontrada.",
      "i" = "Colunas dispon\u00edveis: {.val {names(df)}}."
    ))
  }

  result <- tibble::tibble(
    doc_id    = as.character(df[[id_col]]),
    categoria = as.character(df[[cat_col]])
  ) |>
    dplyr::filter(!is.na(categoria), nchar(categoria) > 0L)

  n_vazio <- nrow(df) - nrow(result)
  if (n_vazio > 0L) {
    cli::cli_warn("{n_vazio} linha(s) sem classifica\u00e7\u00e3o humana foram removidas.")
  }

  cli::cli_inform("\u2705 {nrow(result)} classifica\u00e7\u00f5es humanas importadas de {.path {path}}")
  result
}


# ============================================================================
# Auxiliares de confiabilidade
# ============================================================================

# Aloca n_total itens entre estratos de tamanho n_pop com o metodo do
# maior resto (largest remainder): cada estrato recebe pelo menos
# minimo, o resto e distribuido um a um aos estratos com a maior parte
# fracionaria perdida, ate fechar a soma em n_total (para mais ou para
# menos, dependendo se o piso ja ultrapassa n_total).
#' @keywords internal
#' @noRd
.ac_allocate <- function(n_pop, n_total, minimo = 1L) {
  exato <- n_total * n_pop / sum(n_pop)
  alocado <- pmax(minimo, floor(exato))

  while (sum(alocado) < n_total) {
    resto <- exato - alocado
    alocado[which.max(resto)] <- alocado[which.max(resto)] + 1L
  }
  while (sum(alocado) > n_total) {
    candidatos <- which(alocado > minimo)
    if (length(candidatos) == 0L) break
    i <- candidatos[which.min((exato - alocado)[candidatos])]
    alocado[i] <- alocado[i] - 1L
  }

  alocado
}


# Amostragem estratificada com alocacao proporcional (metodo do maior
# resto). Estratos pequenos (< min_stratum_size na POPULACAO, nao na
# amostra) sao agrupados em "Outras" antes de alocar, para nao dar a
# uma categoria residual uma fracao da amostra menor que 1 documento de
# forma instavel. peso_amostral e o inverso da fracao amostrada dentro
# do estrato -- use para ponderar estimativas populacionais.
#' @keywords internal
#' @noRd
.ac_sample_proportional <- function(coded, n, strata, min_per_stratum, min_stratum_size) {
  estrato_original <- as.character(coded[[strata]])
  contagem <- table(estrato_original)

  pequenos <- names(contagem)[contagem < min_stratum_size]
  estrato  <- ifelse(estrato_original %in% pequenos, "Outras", estrato_original)

  tab   <- table(estrato)
  nomes <- names(tab)
  n_use <- min(n, nrow(coded))

  alocacao <- .ac_allocate(as.integer(tab), n_use, as.integer(min_per_stratum))
  names(alocacao) <- nomes

  coded_estrato <- coded
  coded_estrato$.ac_estrato <- estrato

  partes <- purrr::map(nomes, function(nm) {
    sub_df <- coded_estrato[coded_estrato$.ac_estrato == nm, , drop = FALSE]
    k      <- min(alocacao[[nm]], nrow(sub_df))
    sub_df[sample(nrow(sub_df), k), , drop = FALSE]
  })

  result <- dplyr::bind_rows(partes)
  result$peso_amostral <- as.numeric(tab[result$.ac_estrato]) / as.numeric(alocacao[result$.ac_estrato])
  result$sample_reason <- paste0("proportional (estrato=", result$.ac_estrato, ")")
  result$.ac_estrato <- NULL

  result
}


#' @keywords internal
#' @noRd
.ac_bootstrap_metric <- function(v1, v2, B, ci_level, fn) {
  n       <- length(v1)
  samples <- replicate(B, {
    idx <- sample(n, n, replace = TRUE)
    fn(v1[idx], v2[idx])
  })
  alpha <- 1 - ci_level
  stats::quantile(samples, c(alpha / 2, 1 - alpha / 2), na.rm = TRUE)
}

#' @keywords internal
#' @noRd
.ac_compute_f1_macro <- function(pred, true) {
  cats <- unique(c(pred, true))
  f1s  <- purrr::map_dbl(cats, function(cat) {
    tp <- sum(pred == cat & true == cat, na.rm = TRUE)
    fp <- sum(pred == cat & true != cat, na.rm = TRUE)
    fn <- sum(pred != cat & true == cat, na.rm = TRUE)
    if ((2 * tp + fp + fn) == 0L) return(NA_real_)
    (2 * tp) / (2 * tp + fp + fn)
  })
  mean(f1s, na.rm = TRUE)
}

#' @keywords internal
#' @noRd
# Rotulo qualitativo de uma metrica de concordancia. Cada tipo usa a
# referencia propria dele -- ler alfa ou F1 com as faixas de Landis &
# Koch (propostas para o kappa) mistura escalas diferentes.
#   * "alpha":   Krippendorff (2018, sec. 12.4): >= .800 / >= .667
#   * "kappa":   Landis & Koch (1977, p. 165); usado tambem para o AC1
#                (Gwet, 2014, cap. 6)
#   * "percent": Neuendorf (2017); Lombard et al. (2002)
#   * "f1":      sem faixa canonica na literatura -> sem rotulo
.ac_interpret_agreement <- function(value, type = c("kappa", "alpha", "percent", "f1")) {
  type <- match.arg(type)
  if (is.na(value)) return("n\u00e3o calculado")
  switch(type,
    percent = dplyr::case_when(
      value >= 0.90 ~ "alta (>= 90%; Neuendorf, 2017)",
      value >= 0.80 ~ "aceit\u00e1vel na maioria dos casos (>= 80%; Neuendorf, 2017)",
      value >= 0.70 ~ "s\u00f3 para estudos explorat\u00f3rios (>= 70%; Neuendorf, 2017)",
      TRUE          ~ "insuficiente (< 70%; Neuendorf, 2017)"
    ),
    alpha = dplyr::case_when(
      value >= 0.800 ~ "confi\u00e1vel (>= 0,800; Krippendorff, 2018)",
      value >= 0.667 ~ "s\u00f3 conclus\u00f5es provis\u00f3rias (>= 0,667; Krippendorff, 2018)",
      TRUE           ~ "insuficiente (< 0,667; Krippendorff, 2018)"
    ),
    kappa = .ac_landis_koch(value, citar = TRUE),
    f1    = "sem faixa can\u00f4nica (n\u00e3o corrigido por acaso)"
  )
}

# Faixas de Landis & Koch (1977, p. 165) com os limites exatos do
# artigo: < 0 pobre; 0-0,20 leve; 0,21-0,40 razoavel; 0,41-0,60
# moderada; 0,61-0,80 substancial; 0,81-1 quase perfeita. Fonte unica
# usada por ac_qual_reliability() e ac_qual_irr().
.ac_landis_koch <- function(k, citar = FALSE) {
  if (is.na(k)) return(NA_character_)
  rotulo <- if (k < 0) {
    "pobre"
  } else if (k <= 0.20) {
    "leve"
  } else if (k <= 0.40) {
    "razo\u00e1vel"
  } else if (k <= 0.60) {
    "moderada"
  } else if (k <= 0.80) {
    "substancial"
  } else {
    "quase perfeita"
  }
  if (citar) paste0(rotulo, " (Landis & Koch, 1977)") else rotulo
}

# Alfa de Krippendorff nominal para dois codificadores. irr::kripp.alpha()
# espera matriz numerica: converter as categorias (texto) para codigos
# inteiros com niveis comuns aos dois vetores, em vez de deixar o irr
# coagir texto para numero (gera "NAs introduzidos por coercao" a cada
# replica bootstrap).
.ac_kripp_nominal <- function(r1, r2) {
  if (!requireNamespace("irr", quietly = TRUE)) return(NA_real_)
  niveis <- sort(unique(stats::na.omit(c(as.character(r1), as.character(r2)))))
  if (length(niveis) < 2L) return(NA_real_)
  mat <- rbind(
    as.integer(factor(as.character(r1), levels = niveis)),
    as.integer(factor(as.character(r2), levels = niveis))
  )
  tryCatch(
    irr::kripp.alpha(mat, method = "nominal")$value,
    error = function(e) NA_real_
  )
}

# Metricas de concordancia para um UNICO par de vetores binarios 0/1
# (presenca/ausencia de uma categoria especifica em cada rodada).
# Denominadores zero (precisao/recall sem nenhum positivo, por exemplo)
# sempre geram NA -- nunca 0 ou 1 artificiais, que mascarariam uma
# categoria rara que nenhum dos dois lados escolheu.
#' @keywords internal
#' @noRd
.ac_metricas_binarias <- function(h, m) {
  n  <- length(h)
  vp <- sum(h == 1L & m == 1L)
  fp <- sum(h == 0L & m == 1L)
  fn <- sum(h == 1L & m == 0L)
  vn <- sum(h == 0L & m == 0L)

  conc <- (vp + vn) / n
  prec <- if (vp + fp > 0L) vp / (vp + fp) else NA_real_
  rec  <- if (vp + fn > 0L) vp / (vp + fn) else NA_real_
  f1   <- if (!is.na(prec) && !is.na(rec) && (prec + rec) > 0) {
    2 * prec * rec / (prec + rec)
  } else NA_real_

  pi_pos <- (mean(h == 1L) + mean(m == 1L)) / 2
  pe     <- 2 * pi_pos * (1 - pi_pos)
  ac1    <- if (!is.na(pe) && abs(1 - pe) > 1e-10) (conc - pe) / (1 - pe) else NA_real_

  p1  <- mean(c(h, m) == 1L)
  de  <- if (n > 1L) 2 * p1 * (1 - p1) * (2 * n) / (2 * n - 1) else 0
  alfa <- if (de > 0) 1 - (1 - conc) / de else NA_real_

  tibble::tibble(
    n = n, vp = vp, fp = fp, fn = fn, vn = vn,
    concordancia = conc, precisao = prec, recall = rec, f1 = f1,
    gwet_ac1 = ac1, krippendorff_alfa = alfa
  )
}


# Constroi, para cada categoria presente em llm/human, um par de
# vetores binarios de presenca (apos separar categoria por "|" --
# suporta multilabel) e aplica .ac_metricas_binarias(). Documentos cujo
# status (ver ac_qual_code()) esta em exclude_status sao removidos
# antes: uma categoria vinda de uma rodada que falhou (estouro de
# contexto, timeout, etc.) nao e um dado confiavel sobre concordancia.
#' @keywords internal
#' @noRd
.ac_reliability_by_variable <- function(llm, human, cat_col, exclude_status) {
  if ("status" %in% names(llm) && length(exclude_status) > 0L) {
    llm <- llm[is.na(llm$status) | !llm$status %in% exclude_status, , drop = FALSE]
  }

  joined <- dplyr::inner_join(
    llm   |> dplyr::select("doc_id", llm_cat   = dplyr::all_of(cat_col)),
    human |> dplyr::select("doc_id", human_cat = dplyr::all_of(cat_col)),
    by = "doc_id"
  )
  joined <- joined[!is.na(joined$llm_cat) & !is.na(joined$human_cat), , drop = FALSE]

  if (nrow(joined) == 0L) {
    cli::cli_warn("Nenhum documento comum valido para calcular confiabilidade por variavel.")
    return(tibble::tibble())
  }

  llm_sets   <- strsplit(joined$llm_cat, "|", fixed = TRUE)
  human_sets <- strsplit(joined$human_cat, "|", fixed = TRUE)
  todas_cats <- sort(unique(c(unlist(llm_sets), unlist(human_sets))))

  linhas <- purrr::map(todas_cats, function(cat) {
    m <- as.integer(vapply(llm_sets,   function(s) cat %in% s, logical(1)))
    h <- as.integer(vapply(human_sets, function(s) cat %in% s, logical(1)))
    dplyr::bind_cols(tibble::tibble(categoria = cat), .ac_metricas_binarias(h, m))
  })

  dplyr::bind_rows(linhas)
}


#' @keywords internal
#' @noRd
# Gwet AC1: formula de Gwet (2014, cap. 3)
# Corrige o paradoxo do kappa quando categorias sao altamente prevalentes.
.ac_gwet_ac1 <- function(r1, r2) {
  # Remover NAs pareados
  ok  <- !is.na(r1) & !is.na(r2)
  r1  <- r1[ok]; r2 <- r2[ok]
  n   <- length(r1)
  if (n < 2L) return(NA_real_)
  cats <- unique(c(r1, r2))
  q   <- length(cats)
  if (q < 2L) return(NA_real_)
  # Proporcao observada de concordancia
  pa  <- mean(r1 == r2)
  # Proporcao esperada pelo acaso (Gwet AC1)
  pi_k <- sapply(cats, function(k) {
    (mean(r1 == k) + mean(r2 == k)) / 2
  })
  pe  <- (1 / (q - 1)) * sum(pi_k * (1 - pi_k))
  if (abs(1 - pe) < 1e-10) return(NA_real_)
  (pa - pe) / (1 - pe)
}
