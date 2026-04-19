#' Stopwords em português brasileiro e inglês (presets do `acR`)
#'
#' @description
#' Retorna um vetor de stopwords segundo o preset especificado.
#' Função interna usada por [ac_clean()]. Usuários podem acessar
#' via `acR:::.ac_get_stopwords()` para inspeção ou usar
#' [ac_clean_stopwords()] para construir vetores customizados.
#'
#' @details
#' Presets disponíveis:
#'
#' * `"pt"`: stopwords padrão do português via `stopwords::stopwords("pt")`
#'   (fonte: Snowball), com remoção das preposições substantivas mais
#'   relevantes para análise de conteúdo político (`"sobre"`, `"entre"`,
#'   `"contra"`, `"desde"`, `"durante"`, `"mediante"`).
#' * `"pt-br-extended"`: `"pt"` + pronomes de tratamento, fórmulas de
#'   discurso, saudações e conectivos formais do português brasileiro.
#' * `"pt-legislativo"`: `"pt-br-extended"` + vocabulário parlamentar
#'   brasileiro (cargos, procedimentos, instituições).
#' * `"en"`: stopwords padrão do inglês via `stopwords::stopwords("en")`
#'   (fonte: Snowball). Útil para corpora bilíngues ou literatura.
#'
#' @param preset String com nome do preset.
#' @return Vetor `character` com as stopwords.
#' @keywords internal
#' @noRd
.ac_get_stopwords <- function(preset) {
  if (!requireNamespace("stopwords", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg stopwords} \u00e9 necess\u00e1rio para usar presets.",
      "i" = "Instale com {.code install.packages(\"stopwords\")}."
    ))
  }

  valid_presets <- c("pt", "pt-br-extended", "pt-legislativo", "en")
  if (!preset %in% valid_presets) {
    cli::cli_abort(c(
      "Preset de stopwords {.val {preset}} desconhecido.",
      "i" = "Presets v\u00e1lidos: {.val {valid_presets}}."
    ))
  }

  # Preset inglês — retorna direto
  if (preset == "en") {
    return(stopwords::stopwords("en", source = "snowball"))
  }

  # Base: stopwords padrão do português
  base_pt_raw <- stopwords::stopwords("pt", source = "snowball")

  # Preposições analiticamente relevantes para CP/CS/AP — removidas do preset
  # "pt" para não suprimir dimensões substantivas do texto.
  # Pesquisador pode adicioná-las manualmente via extra_stopwords se desejar.
  preposicoes_substantivas <- c(
    "sobre",     # indica tema/objeto ("discussão SOBRE reforma")
    "entre",     # indica relação ("acordo ENTRE partidos")
    "contra",    # indica oposição ("voto CONTRA a proposta")
    "desde",     # indica temporalidade ("DESDE a promulgação")
    "durante",   # indica período ("DURANTE o governo")
    "mediante",  # indica instrumento ("MEDIANTE decreto")
    "perante",   # indica referência institucional ("PERANTE o plenário")
    "conforme",  # indica conformidade normativa ("CONFORME a lei")
    "segundo",   # indica autoria/fonte ("SEGUNDO o relator")
    "apos",      # indica sequência ("APÓS a votação")
    "ap\u00f3s"  # com acento
  )

  base_pt <- base_pt_raw[!base_pt_raw %in% preposicoes_substantivas]

  # Extensão BR: formalidades e pronomes de tratamento
  br_extended <- c(
    # Pronomes de tratamento
    "sr", "sra", "srs", "sras", "senhor", "senhora", "senhores", "senhoras",
    "vossa", "vossas", "excelencia", "exa", "exas", "excelencias",
    "excelentissimo", "excelentissima", "digno", "digna",
    "meritissimo", "meritissima",
    # Saudações e fórmulas
    "bom", "boa", "dia", "tarde", "noite", "ola", "obrigado", "obrigada",
    "agradeco", "agradecemos", "caro", "cara", "caros", "caras",
    "prezado", "prezada", "prezados", "prezadas",
    # Conectivos formais (sem valor analítico em CP/CS)
    "portanto", "outrossim", "ademais", "destarte", "conquanto",
    "doravante", "anteriormente",
    # Termos discursivos neutros
    "aqui", "ali", "la", "entao", "tambem", "apenas", "somente",
    "pois", "contudo", "entretanto", "todavia",
    # Números por extenso comuns
    "primeiro", "segundo", "terceiro", "um", "dois", "tres", "mil", "cem"
  )

  # Extensão legislativa: vocabulário parlamentar brasileiro
  br_legislativo <- c(
    # Cargos
    "deputado", "deputada", "deputados", "deputadas",
    "senador", "senadora", "senadores", "senadoras",
    "presidente", "vice", "lider", "relator", "relatora",
    "ministro", "ministra", "ministros", "ministras",
    # Procedimentos
    "requerimento", "requerimentos", "proposicao", "proposicoes",
    "emenda", "emendas", "substitutivo",
    "parecer", "pareceres", "aparte", "apartes", "oficio", "oficios",
    "votacao", "votacoes", "voto", "votos", "pronunciamento",
    "discurso", "discursos", "sessao", "sessoes", "reuniao", "reunioes",
    "ordem", "dia", "expediente", "pauta",
    # Instituições / locais
    "camara", "senado", "congresso", "plenario", "mesa", "tribuna",
    "comissao", "comissoes", "casa", "federal", "nacional", "assembleia",
    # Fórmulas legislativas
    "art", "artigo", "artigos", "paragrafo", "paragrafos",
    "inciso", "incisos", "decreto", "decretos",
    "medida", "provisoria", "regimento", "regimental",
    "constitucional"
    # Nota: "lei", "leis", "projeto", "projetos" e "constituicao" foram
    # removidos deste preset pois são frequentemente objetos de análise
    # em estudos legislativos. Adicione via extra_stopwords se necessário.
  )

  result <- switch(preset,
    "pt"             = base_pt,
    "pt-br-extended" = unique(c(base_pt, br_extended)),
    "pt-legislativo" = unique(c(base_pt, br_extended, br_legislativo))
  )

  result
}
