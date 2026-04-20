# Changelog

## acR 0.2.1

### Novas funções

- [`ac_qual_codebook_hybrid()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_hybrid.md)
  — enriquece definições de categorias com referências bibliográficas
  buscadas via LLM, combinando fundamento manual com ancora teórica
  induzida da literatura.

- [`ac_qual_codebook_merge()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_merge.md)
  — funde dois objetos `ac_codebook` em um único, com controle de
  conflitos de nomes (`error`, `keep_first`, `keep_second`,
  `rename_second`).

- [`ac_qual_codebook_translate()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_translate.md)
  — traduz instruções, definições e exemplos de um codebook para outro
  idioma via LLM (`"pt"` ↔︎ `"en"`).

- [`ac_qual_codebook_history()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_history.md)
  — retorna o histórico de modificações de um `ac_codebook` (adições,
  remoções, merges, traduções, enriquecimentos).

- [`as_prompt()`](https://andersonheri.github.io/acR/reference/as_prompt.md)
  /
  [`as_prompt.ac_codebook()`](https://andersonheri.github.io/acR/reference/as_prompt.md)
  — converte um `ac_codebook` em system prompt formatado para uso direto
  com objetos `Chat` do `ellmer`, com suporte a raciocínio estruturado
  (`reasoning_length`).

- [`as_prompt.default()`](https://andersonheri.github.io/acR/reference/as_prompt.md)
  — método default com mensagem de erro informativa para objetos que não
  são `ac_codebook`.

### Correções

- Corrigido warning `non-ASCII characters` em `R/ac_qual_codebook.R`:
  escapes `\uXXXX` agora usados no código R; UTF-8 real mantido nos
  blocos roxygen.

- Corrigido warning `missing documentation entries`: todas as 5 novas
  funções do Bloco B agora têm blocos roxygen completos com título,
  `@param` e `@return`.

- Corrigido mismatch de documentação: `check_overlap` adicionado ao
  `.Rd` de
  [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md).

- Corrigido `vignettes/sentimento.Rmd`: `eval=FALSE` adicionado a todos
  os chunks que faziam download externo, prevenindo falha no CI sem
  internet.

### Testes

- 63 testes passando em `tests/testthat/test-ac_qual_codebook.R`,
  cobrindo todas as funções do Bloco B. Testes com LLM real usam
  `skip_if_offline()` e `skip_on_cran()`.

### Documentação

- `README.md` atualizado com tabela de funções de gestão de codebook,
  referências completas (12 entradas) e bloco de citação com ORCID e
  afiliação CEM-Cepid/USP.

- `vignettes/qualitativo-llm.Rmd` reescrita com pipeline completo do
  Bloco B: criação, enriquecimento, fusão, tradução, histórico e geração
  de system prompt.

- `vignettes/analise-proposicoes.Rmd` atualizada com seção 3b
  demonstrando refinamento iterativo do codebook com as novas funções.

- `_pkgdown.yml` atualizado: seção “Codificacao qualitativa via LLM”
  agora lista todas as 12 funções do módulo qualitativo.

## acR 0.2.0

- Versão inicial com módulos qualitativo e quantitativo completos.
