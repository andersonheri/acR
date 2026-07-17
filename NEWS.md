# acR 0.3.2

## Novidades

* **`ac_cluster_documents()`** (novo) — clustering nao supervisionado de
  documentos com hierarquico (Ward.D2), k-means ou PAM. Features
  configuraveis (TF-IDF ou contagens), distancias `cosine`/`euclidean`,
  escolha automatica de `k` por silhueta (usa `cluster` de `Suggests`).
  Retorna S3 `ac_cluster` com metodo `print`.
* **`ac_plot_cluster()`** (novo) — tres tipos de visualizacao para
  objetos `ac_cluster`: `dendrogram` (default para hclust), `scatter`
  (projecao PCA 2D com labels) e `heatmap` (matriz de dissimilaridade
  ordenada pelo dendrograma).
* **Nova vignette** — `vignette("cluster")`: "Agrupamento nao
  supervisionado de documentos". Explica as tres familias (hard/soft
  clustering e LDA) com tabela de quando usar cada uma, apresenta seis
  visualizacoes complementares (dendrograma, PCA, heatmap, top termos
  por cluster, curva de silhueta e comparacao lado-a-lado hard vs.
  LDA/gamma), valida a particao contra um `tema_real` mantido fora do
  modelo e integra o clustering ao pipeline qualitativo.
* **Documentacao** — README, `_pkgdown.yml` (menu de vignettes e secao
  "Pipeline quantitativo") apontam para a nova vignette; acentos
  corrigidos nas entradas visiveis do menu.
* **`ac_plot_wordcloud_comparative()`** agora aceita **N grupos** (>= 2)
  em vez de somente 2. Cada grupo vira uma faceta; nas duas
  implementacoes (`backend = "ggwordcloud"` e `backend = "ggplot"`) o
  layout usa `facet_wrap()`. Cores padrao passam a vir de
  `ac_palette(N)`. A validacao antiga (`length(grupos) != 2L`) foi
  substituida por `length(grupos) < 2L`.
* **Polimento de documentacao** — reescrita de `qualitativo-llm.Rmd`
  (nova secao "Quando usar LLM (e quando NAO usar)" com tabela
  decisoria, tabela de custo por modelo e "Diagnosticando problemas
  comuns" com 4 modos de falha); `quantitativo.Rmd` (nova secao "Qual
  metrica responde qual pergunta"); `lda.Rmd` (comparativo LDA vs.
  clustering vs. LLM e heatmap gamma com referencia cruzada ao cluster).
  Roxygen de `ac_qual_codebook()`, `ac_qual_code()`,
  `ac_qual_reliability()`, `ac_import()`, `ac_qual_report()`,
  `ac_qual_irr()`, `ac_tokenize()` e `ac_count()` expandidos com
  framing teorico e faixas interpretativas. `@examples` mais realistas
  em `ac_keyness()`, `ac_tf_idf()`, `ac_cooccurrence()` e
  `ac_sentiment()`.
* **Generalizacao do keyness** — README, vignette `quantitativo` e
  roxygen de `ac_keyness()` descrevem grupos genericamente (qualquer
  variavel categorica: partido, periodo, tema, regiao, condicao
  experimental) em vez do exemplo "governo x oposicao" que havia
  ossificado como canonico.
* **Cobertura de testes** subiu de ~55% (0.3.1) para ~66%. Testes novos
  em `ac_cluster.R` (67% -> 91%), `ac_qual_codebook.R` (43% -> 48%) e
  `ac_qual_reliability.R`.

# acR 0.3.1

## Ajustes

* **`ac_plot_wordcloud_comparative()`** — layout reproduzivel via novo
  argumento `seed` (padrao `42L`), com salvaguarda do RNG global; cores
  padrao agora vem de `ac_palette(2L)` em vez de codigos fixos. Novo
  argumento `backend` (`"auto"`/`"ggwordcloud"`/`"ggplot"`): quando
  `ggwordcloud` esta instalado, usa `geom_text_wordcloud` com facets
  lado a lado; caso contrario, mantem o layout jitter original.
* **`ac_plot_xray()`** — corrigido caso de divisao por zero em
  documentos com apenas 1 token (posicao passa a ser `0.5`); warning
  agora identifica quais termos ficaram sem ocorrencia, nao apenas o
  caso extremo de nenhum encontrado.
* **`ac_import()`** — a ordem dos documentos no corpus resultante
  agora preserva a ordem de entrada em `path`, mesmo misturando arquivos
  OCR e texto; `doc_id` duplicados sao desambiguados automaticamente
  com sufixos (`_2`, `_3`, ...) e um aviso; erros migrados para
  `cli::cli_abort` (padrao do pacote). Loop de OCR ganhou barra de
  progresso via `cli::cli_progress_bar()`.

## Testes

* Nova cobertura para `ac_export()`, `ac_qual_irr()`, `theme_ac()`,
  `ac_palette()` e `is_ac_corpus()`.

# acR 0.3.0

## Novas funcionalidades — Visualização e Tema

* **`theme_ac()`** — tema `ggplot2` minimalista e consistente, usado
  por todos os `ac_plot_*()`. Deriva de `theme_minimal()` com ajustes
  editoriais: títulos em negrito, gridlines suaves, tipografia compacta.

* **`ac_palette()`** — paleta categórica de 8 cores (adaptada de
  Okabe-Ito para compatibilidade WCAG AA e daltonismo).

* **`ac_wordcloud(backend = ...)`** — reescrita para preferir
  `ggwordcloud` (retorna `ggplot`, layout mais agradável, tipografia
  editorial), com fallback para `wordcloud` clássico. Novos argumentos
  `backend` e `title`.

* **`ac_plot_xray()`** — refinada com `theme_ac()` + `ac_palette()`,
  facet_grid com label do documento à esquerda, barras verticais mais
  espessas e arredondadas.

## Menu e navegação

* Vignettes do site pkgdown reorganizadas em 3 blocos ("Comece por
  aqui", "Pipeline qualitativo (LLMs)", "Pipeline quantitativo").
  "Análise de proposições" agora aparece como sub-item de "Codificação
  com LLMs", esclarecendo a relação entre guia e estudo de caso.

* Diagrama SVG do pipeline redesenhado: Etapas 5 e 6 em layout de duas
  linhas (título + funções empilhados) resolvendo vazamento de texto.

## Testes e cobertura

* +87 assertions em 4 arquivos novos (`test-ac_ellmer_chat`,
  `test-ac_qual_report`, `test-ac_qual_live`, `test-ac_qual_code-live`).
* Cobertura global: **55% → ~64%**.
* Total agora: 741+ testes pass, 5 skips justificados.

## Documentação

* Nova vignette **`replicabilidade.Rmd`** — pipeline completo em 6
  etapas (corpus → codebook → code + live → sample → reliability →
  report), com exemplo executável de `ac_qual_report()`.

* Todas as vignettes usam `ac_clean(remove_stopwords = "pt")` — antes
  top-terms e keyness apareciam poluídos por artigos e preposições.

* Vignettes `lda.Rmd` e `sentimento.Rmd` reescritas com corpus real e
  chunks 100% executáveis (antes usavam `eval=FALSE` + outputs falsos).

## Bug fixes

* `ac_plot_sentiment(type = "line")`: conflito de escala de cor
  resolvido (linha em cinza neutro, pontos coloridos por sentimento).

* `.ac_ellmer_chat()`: sempre usa dispatch direto ao invés de delegar a
  `ellmer::chat()`, garantindo resolução consistente de aliases
  (`gemini → chat_google_gemini`, `claude → chat_anthropic`,
  `azure → chat_azure_openai`, `bedrock → chat_aws_bedrock`).

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
