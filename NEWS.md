# acR 0.2.2

## Novas funcionalidades — Replicabilidade e transparência

* **`ac_qual_report()`** — gera relatório de replicabilidade em Markdown ou
  HTML autocontido (bilíngue PT/EN), documentando codebook completo, histórico
  de modificações, configuração da LLM, distribuição de resultados, métricas
  de confiabilidade (opcional) e referências metodológicas. Pronto para colar
  em artigo/relatório.

* **`ac_qual_code(live = ...)`** — novo argumento com três modos:
  * `"off"` (padrão): sem live view;
  * `"terminal"`: barra de progresso com doc atual, categoria, confiança e
    início do raciocínio a cada iteração (via `cli::cli_progress_bar`);
  * `"shiny"`: janela Shiny em background com tabela atualizando em tempo
    real (requer `shiny` e `callr` em `Suggests`).

## Compatibilidade

* Migrado o acesso ao `ellmer` para a nova API baseada em `chat_<provider>()`
  (`chat_anthropic()`, `chat_groq()`, `chat_openai()`, etc.). A função
  `ellmer::chat()` foi removida em versões recentes do `ellmer`; o novo
  helper interno `.ac_ellmer_chat()` roteia strings no formato
  `"provider/model"` para o dispatcher correto, mantendo fallback para
  `ellmer::chat()` quando disponível (retrocompatível).

* `ellmer` movido de `Imports` para `Suggests`: o pacote agora carrega o
  `ellmer` apenas quando o usuário chama uma função qualitativa, reduzindo
  a superfície de dependência para quem usa apenas os módulos quantitativos.

## Preparação para CRAN

* `Language: en-US` adicionado ao `DESCRIPTION`.
* `inst/WORDLIST` semeado com termos técnicos e nomes próprios; teste de
  ortografia não-bloqueante em `tests/spelling.R`.
* Vinhetas voltam a ser empacotadas no tarball (`^vignettes$` removido do
  `.Rbuildignore`); as 6 vinhetas compilam sem rede/LLM (chunks LLM com
  `eval=FALSE`).
* `vignettes/introducao-acR.Rmd` reescrita como tutorial offline completo.
* Removida a linha inválida `Additional_repositories` (apontava para URL
  `github.com`, não aceita pela CRAN).

## Testes

* +16 testes cobrindo I/O Excel (`ac_qual_export_for_review`,
  `ac_qual_import_human`, roundtrip com `tempfile()`) e helpers internos
  de modelos (`.ac_models_db`, `.ac_score_models`,
  `.ac_model_justification`, `.ac_list_models_live`).
* Testes online de `ac_qual_codebook_translate()` e
  `ac_qual_codebook_hybrid()` ganham `skip_if()` defensivo para versões do
  `ellmer` sem `chat()`.
* Total: 688 pass, 4 skips justificados.

* `R CMD check`: 0 errors, 0 warnings, 1 note inofensiva (clock).

# acR 0.2.1

## Novas funções

* `ac_qual_codebook_hybrid()` — enriquece definições de categorias com referências
  bibliográficas buscadas via LLM, combinando fundamento manual com ancora teórica
  induzida da literatura.

* `ac_qual_codebook_merge()` — funde dois objetos `ac_codebook` em um único,
  com controle de conflitos de nomes (`error`, `keep_first`, `keep_second`,
  `rename_second`).

* `ac_qual_codebook_translate()` — traduz instruções, definições e exemplos de um
  codebook para outro idioma via LLM (`"pt"` ↔ `"en"`).

* `ac_qual_codebook_history()` — retorna o histórico de modificações de um
  `ac_codebook` (adições, remoções, merges, traduções, enriquecimentos).

* `as_prompt()` / `as_prompt.ac_codebook()` — converte um `ac_codebook` em
  system prompt formatado para uso direto com objetos `Chat` do `ellmer`,
  com suporte a raciocínio estruturado (`reasoning_length`).

* `as_prompt.default()` — método default com mensagem de erro informativa para
  objetos que não são `ac_codebook`.

## Correções

* Corrigido warning `non-ASCII characters` em `R/ac_qual_codebook.R`: escapes
  `\uXXXX` agora usados no código R; UTF-8 real mantido nos blocos roxygen.

* Corrigido warning `missing documentation entries`: todas as 5 novas funções
  do Bloco B agora têm blocos roxygen completos com título, `@param` e `@return`.

* Corrigido mismatch de documentação: `check_overlap` adicionado ao `.Rd` de
  `ac_qual_codebook()`.

* Corrigido `vignettes/sentimento.Rmd`: `eval=FALSE` adicionado a todos os
  chunks que faziam download externo, prevenindo falha no CI sem internet.

## Testes

* 63 testes passando em `tests/testthat/test-ac_qual_codebook.R`, cobrindo
  todas as funções do Bloco B. Testes com LLM real usam `skip_if_offline()`
  e `skip_on_cran()`.

## Documentação

* `README.md` atualizado com tabela de funções de gestão de codebook,
  referências completas (12 entradas) e bloco de citação com ORCID e afiliação
  CEM-Cepid/USP.

* `vignettes/qualitativo-llm.Rmd` reescrita com pipeline completo do Bloco B:
  criação, enriquecimento, fusão, tradução, histórico e geração de system prompt.

* `vignettes/analise-proposicoes.Rmd` atualizada com seção 3b demonstrando
  refinamento iterativo do codebook com as novas funções.

* `_pkgdown.yml` atualizado: seção "Codificacao qualitativa via LLM" agora
  lista todas as 12 funções do módulo qualitativo.

# acR 0.2.0

* Versão inicial com módulos qualitativo e quantitativo completos.
