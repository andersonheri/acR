#' Stopwords em português brasileiro (presets do `acR`)
#'
#' @description
#' Retorna um vetor de stopwords segundo o preset especificado.
#' Função interna usada por [ac_clean()]. Usuários podem acessar
#' via `acR:::.ac_get_stopwords()` para inspeção.
#'
#' @details
#' Presets disponíveis:
#'
#' * `"pt"`: stopwords padrão do português, via `stopwords::stopwords("pt")`
#'   (fonte: Snowball).
#' * `"pt-br-extended"`: `"pt"` + termos formais do português brasileiro
#'   (pronomes de tratamento, fórmulas de discurso, saudações).
#' * `"pt-legislativo"`: `"pt-br-extended"` + vocabulário parlamentar
#'   brasileiro (cargos, procedimentos, instituições).
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

  valid_presets <- c("pt", "pt-br-extended", "pt-legislativo")

  if (!preset %in% valid_presets) {
    cli::cli_abort(c(
      "Preset de stopwords {.val {preset}} desconhecido.",
      "i" = "Presets v\u00e1lidos: {.val {valid_presets}}."
    ))
  }

  # Base: stopwords padrão do português
  base_pt <- stopwords::stopwords("pt", source = "snowball")

  # Extensão BR: formalidades e pronomes de tratamento
  br_extended <- c(
    # Pronomes de tratamento
    "sr", "sra", "srs", "sras", "senhor", "senhora", "senhores", "senhoras",
    "vossa", "vossas", "excelencia", "exa", "exas", "excelencias",
    "excelentissimo", "excelentissima", "digno", "digna",
    "meritissimo", "meritissima",
    # Saudações e fórmulas
    "bom", "boa", "dia", "tarde", "noite", "ola", "obrigado", "obrigada",
    "please", "agradeco", "agradecemos", "caro", "cara", "caros", "caras",
    "prezado", "prezada", "prezados", "prezadas",
    # Conectivos formais
    "portanto", "outrossim", "ademais", "destarte", "conquanto",
    "doravante", "ulterior", "anteriormente",
    # Termos discursivos neutros
    "assim", "aqui", "ali", "la", "entao", "tambem", "apenas", "somente",
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
    "projeto", "projetos", "emenda", "emendas", "substitutivo",
    "parecer", "pareceres", "aparte", "apartes", "oficio", "oficios",
    "votacao", "votacoes", "voto", "votos", "pronunciamento",
    "discurso", "discursos", "sessao", "sessoes", "reuniao", "reunioes",
    "ordem", "dia", "expediente", "pauta",
    # Instituições / locais
    "camara", "senado", "congresso", "plenario", "mesa", "tribuna",
    "comissao", "comissoes", "ccj", "cae", "cct", "cctci",
    "casa", "federal", "nacional", "assembleia",
    # Fórmulas legislativas
    "art", "artigo", "artigos", "paragrafo", "paragrafos", "inciso", "incisos",
    "lei", "leis", "decreto", "decretos", "medida", "provisoria",
    "regimento", "regimental", "constituicao", "constitucional"
  )

  result <- switch(preset,
    "pt"              = base_pt,
    "pt-br-extended"  = unique(c(base_pt, br_extended)),
    "pt-legislativo"  = unique(c(base_pt, br_extended, br_legislativo))
  )

  result
}
