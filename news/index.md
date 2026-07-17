# Changelog

## acR 0.3.0

### Novas funcionalidades — Visualização e Tema

- **[`theme_ac()`](https://andersonheri.github.io/acR/reference/theme_ac.md)**
  — tema `ggplot2` minimalista e consistente, usado por todos os
  `ac_plot_*()`. Deriva de `theme_minimal()` com ajustes editoriais:
  títulos em negrito, gridlines suaves, tipografia compacta.

- **[`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md)**
  — paleta categórica de 8 cores (adaptada de Okabe-Ito para
  compatibilidade WCAG AA e daltonismo).

- **`ac_wordcloud(backend = ...)`** — reescrita para preferir
  `ggwordcloud` (retorna `ggplot`, layout mais agradável, tipografia
  editorial), com fallback para `wordcloud` clássico. Novos argumentos
  `backend` e `title`.

- **[`ac_plot_xray()`](https://andersonheri.github.io/acR/reference/ac_plot_xray.md)**
  — refinada com
  [`theme_ac()`](https://andersonheri.github.io/acR/reference/theme_ac.md) +
  [`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md),
  facet_grid com label do documento à esquerda, barras verticais mais
  espessas e arredondadas.

### Menu e navegação

- Vignettes do site pkgdown reorganizadas em 3 blocos (“Comece por
  aqui”, “Pipeline qualitativo (LLMs)”, “Pipeline quantitativo”).
  “Análise de proposições” agora aparece como sub-item de “Codificação
  com LLMs”, esclarecendo a relação entre guia e estudo de caso.

- Diagrama SVG do pipeline redesenhado: Etapas 5 e 6 em layout de duas
  linhas (título + funções empilhados) resolvendo vazamento de texto.

### Testes e cobertura

- +87 assertions em 4 arquivos novos (`test-ac_ellmer_chat`,
  `test-ac_qual_report`, `test-ac_qual_live`, `test-ac_qual_code-live`).
- Cobertura global: **55% → ~64%**.
- Total agora: 741+ testes pass, 5 skips justificados.

### Documentação

- Nova vignette **`replicabilidade.Rmd`** — pipeline completo em 6
  etapas (corpus → codebook → code + live → sample → reliability →
  report), com exemplo executável de
  [`ac_qual_report()`](https://andersonheri.github.io/acR/reference/ac_qual_report.md).

- Todas as vignettes usam `ac_clean(remove_stopwords = "pt")` — antes
  top-terms e keyness apareciam poluídos por artigos e preposições.

- Vignettes `lda.Rmd` e `sentimento.Rmd` reescritas com corpus real e
  chunks 100% executáveis (antes usavam `eval=FALSE` + outputs falsos).

### Bug fixes

- `ac_plot_sentiment(type = "line")`: conflito de escala de cor
  resolvido (linha em cinza neutro, pontos coloridos por sentimento).

- `.ac_ellmer_chat()`: sempre usa dispatch direto ao invés de delegar a
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html),
  garantindo resolução consistente de aliases
  (`gemini → chat_google_gemini`, `claude → chat_anthropic`,
  `azure → chat_azure_openai`, `bedrock → chat_aws_bedrock`).

## acR 0.2.2

### Novas funcionalidades — Replicabilidade e transparência

- **[`ac_qual_report()`](https://andersonheri.github.io/acR/reference/ac_qual_report.md)**
  — gera relatório de replicabilidade em Markdown ou HTML autocontido
  (bilíngue PT/EN), documentando codebook completo, histórico de
  modificações, configuração da LLM, distribuição de resultados,
  métricas de confiabilidade (opcional) e referências metodológicas.
  Pronto para colar em artigo/relatório.

- **`ac_qual_code(live = ...)`** — novo argumento com três modos:

  - `"off"` (padrão): sem live view;
  - `"terminal"`: barra de progresso com doc atual, categoria, confiança
    e início do raciocínio a cada iteração (via
    [`cli::cli_progress_bar`](https://cli.r-lib.org/reference/cli_progress_bar.html));
  - `"shiny"`: janela Shiny em background com tabela atualizando em
    tempo real (requer `shiny` e `callr` em `Suggests`).

### Compatibilidade

- Migrado o acesso ao `ellmer` para a nova API baseada em
  `chat_<provider>()`
  ([`chat_anthropic()`](https://ellmer.tidyverse.org/reference/chat_anthropic.html),
  [`chat_groq()`](https://ellmer.tidyverse.org/reference/chat_groq.html),
  [`chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html),
  etc.). A função
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html)
  foi removida em versões recentes do `ellmer`; o novo helper interno
  `.ac_ellmer_chat()` roteia strings no formato `"provider/model"` para
  o dispatcher correto, mantendo fallback para
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html)
  quando disponível (retrocompatível).

- `ellmer` movido de `Imports` para `Suggests`: o pacote agora carrega o
  `ellmer` apenas quando o usuário chama uma função qualitativa,
  reduzindo a superfície de dependência para quem usa apenas os módulos
  quantitativos.

### Preparação para CRAN

- `Language: en-US` adicionado ao `DESCRIPTION`.
- `inst/WORDLIST` semeado com termos técnicos e nomes próprios; teste de
  ortografia não-bloqueante em `tests/spelling.R`.
- Vinhetas voltam a ser empacotadas no tarball (`^vignettes$` removido
  do `.Rbuildignore`); as 6 vinhetas compilam sem rede/LLM (chunks LLM
  com `eval=FALSE`).
- `vignettes/introducao-acR.Rmd` reescrita como tutorial offline
  completo.
- Removida a linha inválida `Additional_repositories` (apontava para URL
  `github.com`, não aceita pela CRAN).

### Testes

- +16 testes cobrindo I/O Excel (`ac_qual_export_for_review`,
  `ac_qual_import_human`, roundtrip com
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html)) e helpers
  internos de modelos (`.ac_models_db`, `.ac_score_models`,
  `.ac_model_justification`, `.ac_list_models_live`).

- Testes online de
  [`ac_qual_codebook_translate()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_translate.md)
  e
  [`ac_qual_codebook_hybrid()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_hybrid.md)
  ganham `skip_if()` defensivo para versões do `ellmer` sem
  [`chat()`](https://ellmer.tidyverse.org/reference/chat-any.html).

- Total: 688 pass, 4 skips justificados.

- `R CMD check`: 0 errors, 0 warnings, 1 note inofensiva (clock).

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
