## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local R installation (Ubuntu 24.04, R 4.4.x)
* GitHub Actions (Ubuntu, macOS, Windows × R 4.3 / R-release / R-devel)
* win-builder (devel)

## Notes para submissão inicial (v0.1.0)

Este é o primeiro envio do pacote ao CRAN.

* O pacote inclui o léxico OpLexicon (Souza & Vieira, 2012; Souza et al., 2011) na versão revisada distribuída pelo autor original em https://github.com/marlovss/OpLexicon, com citação completa em `inst/CITATION` e arquivo `LICENSE.note` específico.
* Dependência opcional `geobr` em `Suggests` é para integração com mapas brasileiros; não é exigida para uso geral.
* Vignettes incluem exemplos com chamadas a APIs de LLMs (Anthropic, OpenAI, Ollama) — todas marcadas com `eval = FALSE` para evitar falhas em ambiente de check.
