.onAttach <- function(libname, pkgname) {
  # Mensagem so em sessao interativa; nunca poluir batch/CI/CRAN check
  if (!interactive() || isTRUE(getOption("acR.quiet_startup"))) {
    return(invisible())
  }

  v <- utils::packageVersion("acR")
  packageStartupMessage(
    "acR ", v, " -- Analise de Conteudo em R (qualitativo LLM + quantitativo)\n",
    "  Documentacao: https://andersonheri.github.io/acR/\n",
    "  Comece com : vignette(\"quickstart\", package = \"acR\") ou ?acR"
  )
}
