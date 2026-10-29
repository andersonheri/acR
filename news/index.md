# Changelog

## acR (development version)

### Correcoes

- [`ac_import()`](https://ahenriquecp.com/acR/reference/ac_import.md):
  planilhas (`.xlsx`, `.xls`) e CSV com mais de uma linha falhavam com
  “Nenhum documento foi importado com sucesso” (ou com o aviso de
  arquivos descartados). O `readtext` devolve uma linha por registro
  (`doc_id` `arquivo.ext.N`), e o
  [`ac_import()`](https://ahenriquecp.com/acR/reference/ac_import.md)
  comparava os IDs pelo nome do arquivo, descartando tudo. Agora cada
  linha da tabela vira um documento (`doc_id` `<arquivo>.<n>`), as
  demais colunas viram metadados do corpus, e entradas mistas (tabelas
  com pdf, docx, txt) preservam a ordem de `path`. Novos testes cobrem
  CSV, XLSX, entrada mista e `id_from = "rownum"`.

## acR 0.6.0

CRAN release: 2026-10-16

### Correcoes metodologicas (auditoria de codigo e interpretacoes)

Cada item abaixo e uma correcao de resultado, nao so de texto: numeros
produzidos pelas funcoes afetadas mudam em relacao a 0.5.0.

- `ac_tokenize(drop_punct = TRUE)` (e tudo que o usa:
  [`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md),
  [`ac_dictionary()`](https://ahenriquecp.com/acR/reference/ac_dictionary.md),
  [`ac_wordscores()`](https://ahenriquecp.com/acR/reference/ac_wordscores.md),
  [`ac_lexical_diversity()`](https://ahenriquecp.com/acR/reference/ac_lexical_diversity.md),
  [`ac_collocations()`](https://ahenriquecp.com/acR/reference/ac_collocations.md),
  [`ac_ca()`](https://ahenriquecp.com/acR/reference/ac_ca.md)): a
  pontuacao colada a palavra agora e removida das bordas do token
  (`"excelente,"` -\> `"excelente"`). Antes so tokens inteiramente de
  pontuacao eram descartados, e a mesma palavra virava dois tipos
  diferentes. Pontuacao interna (`"e-mail"`, `"3,5"`) e preservada.

- [`ac_cooccurrence()`](https://ahenriquecp.com/acR/reference/ac_cooccurrence.md):
  com `unit = "window"`, cada encontro de dois termos era contado duas
  vezes (uma a partir de cada palavra), dobrando `cooc` e somando 1 bit
  ao PMI; agora conta uma vez. Pares de um termo com ele mesmo sao
  ignorados. Com `unit = "document"`, Dice e PMI passam a usar
  frequencia documental e numero de documentos (antes misturavam
  documentos com tokens, e o Dice era truncado em 1).

- `ac_collocations(n = 3)`: a tabela 2x2 compara a primeira palavra com
  o bigrama restante (antes, w1 x w3, ignorando a palavra do meio).
  Corrigida a afirmacao de que o log-likelihood e a medida do
  `quanteda.textstats::textstat_collocations()` (que usa lambda).

- [`ac_wordscores()`](https://ahenriquecp.com/acR/reference/ac_wordscores.md):
  `rescale = "lbg"` agora segue a formula de Laver, Benoit & Garry
  (2003, p. 316), com media e desvio-padrao dos documentos **virgens**
  (antes usava as referencias reestimadas); exige 2 ou mais virgens e
  avisa quando ha menos de 5. `rescale = "mv"` ancora nas referencias de
  menor e maior escore conhecido (Martin & Vanberg, 2008). Corrigido o
  ano da referencia (2008, nao 2007).

- [`ac_cluster_documents()`](https://ahenriquecp.com/acR/reference/ac_cluster_documents.md):
  a distancia cosseno e calculada como distancia de corda, sqrt(2(1 -
  cos)), que e euclidiana e portanto valida para Ward.D2 (Murtagh &
  Legendre, 2014); com `distance = "cosine"`, o k-means roda sobre
  vetores normalizados. Antes o Ward recebia 1 - cos e o k-means
  ignorava a distancia escolhida.

- [`ac_lda_tune()`](https://ahenriquecp.com/acR/reference/ac_lda_tune.md):
  a perplexidade agora e calculada fora da amostra, por validacao
  cruzada (`folds = 5`), avaliando o teste sobre o vocabulario do
  treino. A perplexidade de treino, que cai quase sempre com k, continua
  na coluna `perplexity_train`. `method = "Gibbs"` deixou de dar erro, e
  `...` agora repassa `control` ao
  [`topicmodels::LDA()`](https://rdrr.io/pkg/topicmodels/man/lda.html).

- [`ac_lda()`](https://ahenriquecp.com/acR/reference/ac_lda.md): aceita
  `control = list(...)` (antes dava erro de argumento duplicado).
  [`ac_plot_lda_topics()`](https://ahenriquecp.com/acR/reference/ac_plot_lda_topics.md)
  mostrava rotulos como `"termo___Topico 1"` no eixo; agora mostra so o
  termo.

- [`ac_sentiment()`](https://ahenriquecp.com/acR/reference/ac_sentiment.md):
  termos repetidos no OpLexicon (28 termos com mais de uma classe
  gramatical, alguns com polaridades opostas) eram contados duas vezes;
  agora cada termo tem uma polaridade (sinal da soma). O argumento `by`
  passa a agregar de fato por grupo, como a documentacao dizia (antes
  devolvia uma linha por documento).

- [`ac_qual_irr()`](https://ahenriquecp.com/acR/reference/ac_qual_irr.md):
  o intervalo de confianca usava `kappa / z` como erro-padrao, mas o `z`
  do `irr` e calculado sob a hipotese nula; o IC saia de \[-1, 1\].
  Agora e *bootstrap* percentil (novo argumento `bootstrap`,
  padrao 1000) para kappa, Fleiss e alfa. `weight = "linear"` estava
  documentado mas dava erro (o `irr` chama de `"equal"`); kappa
  ponderado respeita a ordem dos niveis do fator. IDs duplicados geram
  erro em vez de produto cartesiano silencioso.

- Interpretacao das metricas de concordancia
  ([`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md),
  [`ac_qual_irr()`](https://ahenriquecp.com/acR/reference/ac_qual_irr.md),
  [`ac_qual_report()`](https://ahenriquecp.com/acR/reference/ac_qual_report.md)):
  cada metrica usa a referencia propria. Alfa de Krippendorff pelas
  faixas de Krippendorff (2018: 0,800 / 0,667), e nao pelas de Landis &
  Koch; AC1 de Gwet e kappa por Landis & Koch (1977), com os limites
  exatos do artigo; percentual por Neuendorf (2017); F1 macro sem rotulo
  (nao e corrigido por acaso). `confidence_level` de
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
  deixa de ser atribuido a Landis & Koch: e uma convencao do pacote.

- [`ac_qual_sample()`](https://ahenriquecp.com/acR/reference/ac_qual_sample.md):
  o padrao passa de `"uncertainty"` para `"random"`. A amostra usada
  para estimar confiabilidade precisa ser representativa (Krippendorff,
  2018, cap. 12); amostrar os casos incertos serve para diagnosticar
  erros, nao para estimar concordancia. Vignettes e README atualizados.

- [`ac_top_terms()`](https://ahenriquecp.com/acR/reference/ac_top_terms.md):
  sem `by`, uma tabela por documento (saida padrao de
  [`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md)) era
  ranqueada linha a linha, sem somar o termo entre documentos; com
  empates mantidos, o “top 15” de um corpus pequeno devolvia o
  vocabulario inteiro. Agora soma por termo (ou por grupo) e devolve
  exatamente `n` termos, com desempate alfabetico.

- [`ac_plot_keyness()`](https://ahenriquecp.com/acR/reference/ac_plot_keyness.md)
  e
  [`ac_plot_tf_idf()`](https://ahenriquecp.com/acR/reference/ac_plot_tf_idf.md):
  o mesmo problema de empates (pedir `n = 6` desenhava dezenas de
  barras); agora exatamente `n` por lado ou grupo.
  [`ac_plot_top_terms()`](https://ahenriquecp.com/acR/reference/ac_plot_top_terms.md)
  passa a mostrar o termo mais frequente no topo.

- [`ac_plot_xray()`](https://ahenriquecp.com/acR/reference/ac_plot_xray.md):
  tokenizava sem remover pontuacao, entao um termo seguido de virgula ou
  ponto (“trabalhadores.”) nao era encontrado.

- [`ac_plot_ca()`](https://ahenriquecp.com/acR/reference/ac_plot_ca.md):
  termos com o mesmo perfil caem no mesmo ponto e os rotulos se
  sobrepunham ilegiveis; agora sao agrupados num rotulo so.

### Correcoes de interpretacao nas vignettes

- Os 44 blocos “Como interpretar” foram reescritos como “Como ler este
  grafico/esta tabela”, em quatro passos fixos: onde olhar, o que este
  exemplo mostra (com os numeros da saida), em palavras simples e
  cuidado (com a referencia da literatura).

- [`vignette("quantitativo")`](https://ahenriquecp.com/acR/articles/quantitativo.md):
  exemplo de analise de correspondencia trocado (no anterior, cada
  categoria tinha vocabulario exclusivo e o mapa era degenerado);
  leitura do grafico de Zipf corrigida (a linha ideal parte do primeiro
  ponto, que por isso sempre cai sobre ela).

- [`vignette("sentimento")`](https://ahenriquecp.com/acR/articles/sentimento.md):
  o X-ray buscava termos que nao ocorrem no corpus.
  [`vignette("lda")`](https://ahenriquecp.com/acR/articles/lda.md): o
  mapa de calor de gama ordena os documentos numericamente, deixando os
  temas visiveis em blocos.

- Todas as vignettes foram re-executadas com o codigo corrigido e cada
  bloco “Como interpretar” foi conferido contra a saida real.

- [`vignette("lda")`](https://ahenriquecp.com/acR/articles/lda.md): o
  corpus de exemplo (frases de ~7 palavras) nao permitia ao LDA
  recuperar os temas (pureza perto do acaso); os documentos viraram
  paragrafos de tres frases e o exemplo usa Gibbs com alfa = 0,1, com
  justificativa na literatura (Griffiths & Steyvers, 2004; Wallach,
  Mimno & McCallum, 2009; Hong & Davison, 2010). A escolha de K passou a
  usar perplexidade fora da amostra.

- [`vignette("cluster")`](https://ahenriquecp.com/acR/articles/cluster.md):
  alturas do dendrograma e silhuetas atualizadas; incluida a leitura de
  Kaufman & Rousseeuw (1990) para silhueta media baixa; corrigida a
  comparacao com LDA (o ajuste padrao dava gama = 0,5/0,5 para todos os
  documentos).

- [`vignette("sentimento")`](https://ahenriquecp.com/acR/articles/sentimento.md):
  callouts reescritos a partir da saida real (erros de cobertura e de
  sentido no dominio do OpLexicon, Loughran & McDonald, 2011); alerta de
  que as densidades coloridas pelo sinal do escore separam-se por
  construcao.

- [`vignette("quantitativo")`](https://ahenriquecp.com/acR/articles/quantitativo.md):
  keyness com ressalvas de contagem baixa e comparacoes multiplas;
  Wordscores com `rescale = "mv"`; mapa de AC lido pela direcao
  (Greenacre, 2007); MTLD e C de Herdan sem faixas inventadas; grafico
  de barras do Wordscores com alerta de eixo sem zero significativo
  (Cleveland, 1985).

### Recursos da internet

- [`ac_sentiment()`](https://ahenriquecp.com/acR/reference/ac_sentiment.md)
  baixa o OpLexicon do GitHub na primeira execucao. Os exemplos de
  [`ac_sentiment()`](https://ahenriquecp.com/acR/reference/ac_sentiment.md)
  e
  [`ac_plot_sentiment()`](https://ahenriquecp.com/acR/reference/ac_plot_sentiment.md)
  passam a usar `@examplesIf interactive()`, e as vignettes
  `sentimento`, `introducao-acR` e `quickstart` testam o acesso ao
  lexico antes: sem internet, pulam so os trechos que dependem dele e
  mostram um aviso, em vez de falhar. A documentacao de
  [`ac_sentiment()`](https://ahenriquecp.com/acR/reference/ac_sentiment.md)
  explica o download e o cache em `tools::R_user_dir("acR", "data")`.

### Correcao de comportamento

- [`ac_qual_codebook_translate()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook_translate.md):
  exigia o pacote `ellmer` instalado mesmo quando o codebook ja estava
  no idioma de destino (caso em que nenhuma chamada de LLM e
  necessaria). A checagem de idioma agora acontece antes da checagem de
  dependencia.

### Documentacao

- Revisao ortografica completa (acentuacao) do README, das dez vignettes
  e dos comentarios `roxygen2` em `R/*.R`.
- Tabela “Qual metrica responde qual pergunta?”
  ([`vignette("quantitativo")`](https://ahenriquecp.com/acR/articles/quantitativo.md))
  expandida para cobrir as doze novas tecnicas introduzidas na 0.5.0,
  organizada em cinco familias metodologicas.
- Adicionados blocos “Como interpretar” apos graficos e tabelas de
  resultado em todas as vignettes, explicando como ler cada visualizacao
  e armadilhas comuns de interpretacao.
- Adicionadas visualizacoes alternativas (como exemplos de uso de
  `ggplot2`, sem novas funcoes exportadas) para varias das tecnicas da
  0.5.0 em
  [`vignette("quantitativo")`](https://ahenriquecp.com/acR/articles/quantitativo.md)
  e [`vignette("lda")`](https://ahenriquecp.com/acR/articles/lda.md).
- Novas secoes “Sequencia sugerida para reportar resultados” em
  [`vignette("quantitativo")`](https://ahenriquecp.com/acR/articles/quantitativo.md)
  e
  [`vignette("qualitativo-llm")`](https://ahenriquecp.com/acR/articles/qualitativo-llm.md),
  com tabela de etapas e justificativa metodologica para cada uma.
- Reduzido o uso de travessao (`--`) para zero ocorrencias em todo o
  pacote (README, vignettes e comentarios `roxygen2`), em favor de `:`
  ou reestruturacao de frase.
- `man/*.Rd` regenerado via `devtools::document()` para sincronizar com
  os comentarios `roxygen2` corrigidos.

### Robustez de testes e vignettes

- [`vignette("cluster")`](https://ahenriquecp.com/acR/articles/cluster.md)
  e [`vignette("lda")`](https://ahenriquecp.com/acR/articles/lda.md): os
  trechos que dependem do pacote Suggests `topicmodels` agora sao
  protegidos por
  `eval = requireNamespace("topicmodels", quietly = TRUE)`, evitando
  falha de `R CMD check` em ambientes sem esse pacote instalado.
- Tres testes que exercitavam caminhos de codigo dependentes de `ellmer`
  ganharam `skip_if_not_installed("ellmer")`, espelhando o padrao ja
  usado no restante da suite.

### Manutencao de infraestrutura

- URLs do site do pacote unificadas em `https://ahenriquecp.com/acR/`
  (`_pkgdown.yml`, README, `DESCRIPTION`, `man/acR-package.Rd`): o
  endereco `andersonheri.github.io/acR` redireciona (301) para ele, e o
  CRAN aponta URLs que redirecionam. Corrigido tambem o link do
  repositorio da ENAP no README, cujo endereco antigo nao resolvia.
- Removida do controle de versao a pasta `docs/` que vinha sendo
  comitada por engano em `main` desde uma configuracao antiga de
  publicacao (hoje o site e publicado via GitHub Actions na branch
  `gh-pages`); ja estava em `.Rbuildignore` e agora tambem esta em
  `.gitignore`.

## acR 0.5.0

Doze novas tecnicas quantitativas de diagnostico de corpus, escalas e
dicionarios, todas documentadas na vignette
[`vignette("quantitativo")`](https://ahenriquecp.com/acR/articles/quantitativo.md)
(secao “Novidades”), com exemplos fora do dominio parlamentar
(avaliacoes de produto, atendimento ao cliente, noticias).

### Novidades

- **[`ac_readability()`](https://ahenriquecp.com/acR/reference/ac_readability.md)/[`ac_plot_readability()`](https://ahenriquecp.com/acR/reference/ac_plot_readability.md)**:
  legibilidade/ complexidade textual via indice de Flesch adaptado ao
  portugues (Martins et al., 1996).
- **[`ac_lexical_diversity()`](https://ahenriquecp.com/acR/reference/ac_lexical_diversity.md)/[`ac_plot_lexical_diversity()`](https://ahenriquecp.com/acR/reference/ac_plot_lexical_diversity.md)**:
  diversidade lexical (TTR, C de Herdan, MTLD; Herdan, 1960; McCarthy &
  Jarvis, 2010).
- **[`ac_plot_zipf()`](https://ahenriquecp.com/acR/reference/ac_plot_zipf.md)**:
  grafico log-log de frequencia por ranking (Lei de Zipf, 1949),
  diagnostico classico de corpus.
- **[`ac_kwic()`](https://ahenriquecp.com/acR/reference/ac_kwic.md)**:
  concordancia/*keyword-in-context* (Sinclair, 1991), complementar a
  [`ac_plot_xray()`](https://ahenriquecp.com/acR/reference/ac_plot_xray.md).
- **[`ac_collocations()`](https://ahenriquecp.com/acR/reference/ac_collocations.md)**:
  bigramas/trigramas estatisticamente associados via PMI (Church &
  Hanks, 1990), log-likelihood (Dunning,
  1993. ou qui-quadrado – nao so frequencia bruta.
- **[`ac_temporal()`](https://ahenriquecp.com/acR/reference/ac_temporal.md)/[`ac_plot_temporal()`](https://ahenriquecp.com/acR/reference/ac_plot_temporal.md)**:
  agregacao diacronica de qualquer metrica por dia/semana/mes/ano
  (Welbers, Van Atteveldt & Benoit, 2017).
- **[`ac_wordscores()`](https://ahenriquecp.com/acR/reference/ac_wordscores.md)/[`ac_plot_wordscores()`](https://ahenriquecp.com/acR/reference/ac_plot_wordscores.md)**:
  escalonamento ideologico/continuo de documentos a partir de um pequeno
  conjunto de referencia com posicao conhecida (Laver, Benoit & Garry,
  2003), com reescalonamento `"lbg"` ou `"mv"` (Martin & Vanberg, 2008).
- **[`ac_ca()`](https://ahenriquecp.com/acR/reference/ac_ca.md)/[`ac_plot_ca()`](https://ahenriquecp.com/acR/reference/ac_plot_ca.md)**:
  analise de correspondencia (biplot de documentos/grupos x termos)
  calculada nativamente via
  [`base::svd()`](https://rdrr.io/r/base/svd.html) (Greenacre, 2007),
  alternativa geometrica e deterministica a
  [`ac_lda()`](https://ahenriquecp.com/acR/reference/ac_lda.md).
- **[`ac_dictionary()`](https://ahenriquecp.com/acR/reference/ac_dictionary.md)/[`ac_build_dictionary()`](https://ahenriquecp.com/acR/reference/ac_build_dictionary.md)**:
  dicionario multi-categoria generico (temas, enquadramentos, emocoes),
  nao apenas polaridade positivo/negativo (Stone et al., 1966; Grimmer &
  Stewart, 2013).
- **[`ac_dictionary_save()`](https://ahenriquecp.com/acR/reference/ac_dictionary_save.md)/[`ac_dictionary_load()`](https://ahenriquecp.com/acR/reference/ac_dictionary_save.md)/
  [`ac_dictionary_import()`](https://ahenriquecp.com/acR/reference/ac_dictionary_import.md)**:
  construcao e importacao de dicionario customizado via YAML/CSV,
  unificando o fluxo deterministico com o fluxo de codebook para LLM
  ([`ac_qual_save_codebook()`](https://ahenriquecp.com/acR/reference/ac_qual_save_codebook.md)).
- **[`ac_emotion()`](https://ahenriquecp.com/acR/reference/ac_emotion.md)**:
  classificacao de emocoes a partir de um lexico fornecido pelo usuario,
  inspirada no NRC Emotion Lexicon (Mohammad & Turney, 2013); o pacote
  nao distribui lexico de emocao em portugues por motivos de
  licenciamento.
- **[`ac_dictionary_validate()`](https://ahenriquecp.com/acR/reference/ac_dictionary_validate.md)**:
  validacao de classificacao por dicionario contra uma codificacao
  humana de referencia, categoria por categoria – o equivalente de
  [`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md)
  para o metodo de dicionario (Grimmer & Stewart, 2013).

## acR 0.4.0

CRAN release: 2026-10-14

Pacote de ajustes derivados de uso em producao (872 atos normativos do
SIGEPE, `ellmer` + LM Studio com dois modelos locais, validacao humana,
documentos de ate 1,4M de caracteres).

### Correcoes

- **[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
  com `model`/`chat` como objeto `Chat` do `ellmer`**: `temperature` era
  silenciosamente descartado sempre que a tentativa de reconstruir o
  chat via `.ac_ellmer_chat()` falhava – o que passou a acontecer
  sistematicamente no `ellmer >= 0.5.0`, porque `class(provider)[1]`
  passou a vir qualificado por namespace (`"ellmer::ProviderOpenAI"`),
  quebrando o `sub("^provider", "", ...)` usado para remontar o nome
  `"provedor/modelo"`. O fallback silencioso fazia as `k_consistency`
  rodadas de self-consistency (Wang et al.,
  2023. rodarem todas na mesma temperatura padrao do provedor, inflando
        `confidence_score` sem aviso. Corrigido com uma nova rota que
        muta o objeto `Model` do chat diretamente via `set_model()`/
        `get_model_object()` (API estavel desde o `ellmer` 0.5.0), e que
        avisa explicitamente
        ([`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html))
        quando a mutacao falha – nunca mais em silencio. `model` agora
        tambem aceita uma funcao fabrica
        `function(temperature, system_prompt) Chat` para controle total
        sobre a construcao do chat a cada rodada.
- **`ac_qual_code(confidence = "by_variable" | "both")` com
  `multilabel = TRUE`**: a confianca por variavel subestimava
  sistematicamente categorias presentes junto com outras na mesma
  rodada, porque comparava a string inteira
  (`"tecnica|politica" == "tecnica"` nunca e `TRUE`) em vez de testar se
  a categoria estava entre as escolhidas naquela rodada. Corrigido para
  usar `%in%` apos separar a string por `"|"`; o comportamento para
  rotulagem unica (sem `"|"`) nao muda.

### Novidades

- **`ac_qual_code(max_retries = 2L)`**: novas tentativas automaticas
  (espera exponencial, ate 30s) quando uma rodada falha por erro de
  rede, timeout ou resposta invalida. Nova coluna `status` no tibble de
  saida (`"ok"`, `"resposta_invalida"`, `"estouro_contexto"`,
  `"timeout"`, `"erro_servidor"`) e `n_tentativas`. Erros classificados
  como `"estouro_contexto"` nao sao repetidos (retry nao resolve). Se
  mais da metade dos ultimos 5+ documentos falhar, a execucao e abortada
  com sugestao de `checkpoint_dir`.
- **`ac_qual_code(checkpoint_dir = ...)`**: salva o resultado de cada
  documento assim que classificado (gravacao atomica via arquivo
  temporario + [`file.rename()`](https://rdrr.io/r/base/files.html)),
  permitindo retomar uma rodada interrompida sem reclassificar
  documentos ja concluidos. Checkpoints de uma rodada com
  `codebook`/`model`/`k_consistency`/`temperature` diferentes sao
  invalidados e sobrescritos automaticamente (com aviso).
- **[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
  ganha colunas `tokens_entrada`, `tokens_saida`, `segundos` e
  `tokens_por_segundo`** (via `chat$get_tokens()`), medidos na rodada
  principal de cada documento.
- **[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
  ganha o atributo `run_info`** (`attr(resultado, "run_info")`): versoes
  de `acR`/`ellmer`, modelo, `base_url`, parametros efetivos aplicados
  ao provedor, temperaturas pedidas, `k_consistency`, hash do codebook e
  timestamps de inicio/fim. Avisa quando nao e possivel confirmar que
  `temperature` foi de fato aplicada a um `Chat` pre-configurado.
- **`ac_qual_code(main_temperature = 0, reasoning_extras = FALSE)`**:
  parametros antes fixos no codigo agora expostos. `main_temperature`
  controla a temperatura da rodada que gera o resultado final (antes
  sempre `0`); `reasoning_extras` controla se as rodadas extras de
  self-consistency tambem pedem raciocinio (antes sempre `FALSE`).
- **`ac_qual_reliability(by_variable = TRUE)`**: calcula métricas
  binárias (concordância, precisão, recall, F1, Gwet AC1, alfa de
  Krippendorff) para cada categoria do codebook individualmente —
  essencial em `multilabel = TRUE`, onde a métrica agregada mistura
  várias decisões binárias independentes. Denominadores zero geram `NA`,
  nunca `0`/`1` artificiais. `exclude_status` remove documentos cuja
  rodada falhou (ver `status` em \[ac_qual_code()\]) antes de comparar.
  Resultado fica em `attr(resultado, "by_variable")`.
- **`ac_qual_sample(strategy = "proportional")`**: amostragem
  estratificada com alocação proporcional ao tamanho de cada estrato
  (método do maior resto), preservando a distribuição original —
  diferente de `"stratified"`, que divide `n` igualmente entre
  categorias. Ganha `strata`, `min_per_stratum`, `min_stratum_size`
  (agrupa estratos pequenos em `"Outras"`) e `exclude_ids`. A amostra
  ganha a coluna `peso_amostral` para uso em estimativas ponderadas.
- **[`ac_chat_local()`](https://ahenriquecp.com/acR/reference/ac_chat_local.md)**:
  provedor de primeira classe para servidores LLM locais compatíveis com
  OpenAI (LM Studio, llama.cpp, vLLM, Ollama em modo OpenAI), sem exigir
  uma chave de API real. Adapta-se ao nome do parâmetro de credencial
  (`api_key` vs `credentials`) conforme a versão instalada do `ellmer`.
- **[`ac_estimate_tokens()`](https://ahenriquecp.com/acR/reference/ac_estimate_tokens.md)**:
  estimativa barata (heurística de caracteres por token, sem chamada de
  rede) do consumo de tokens de um texto – útil para prever estouro de
  contexto antes de enviar ao LLM.
  **[`ac_calibrate_tokens()`](https://ahenriquecp.com/acR/reference/ac_calibrate_tokens.md)**:
  calibra a razão caracteres/token contra um modelo real usando uma
  amostra pequena de textos.
- **`ac_qual_code(live = "progress")`**: novo modo de barra de progresso
  enxuta (doc atual + status, sem ecoar categoria/raciocinio) para
  rodadas grandes. Chats construidos internamente pelo `acR` agora usam
  `echo = "none"` por padrao (configuravel via `...`), evitando poluir o
  console a cada uma das `k_consistency` rodadas por documento.

## acR 0.3.4

CRAN release: 2026-09-10

### Correcoes

- **`ac_qual_code(confidence = "by_variable" | "both")`**: a confianca
  por variavel nunca era calculada nem chegava ao tibble de saida como
  colunas `<categoria>_confidence`, apesar de documentado em `@return`.
  Dois bugs na mesma funcao: (1) `.ac_compute_confidence()` testava
  `confidence %in% c("total", "both")` no primeiro `if`, entao `"both"`
  sempre caia nesse ramo e nunca calculava a confianca por variavel;
  2.  mesmo quando calculada (modo `"by_variable"` puro), o valor era so
      a proporcao da categoria vencedora, nao uma proporcao por
      categoria do codebook – e `.ac_build_result_tibble()` nunca lia
      esse valor para adicionar as colunas ao tibble final. Corrigido
      nas duas funcoes: `by_var` agora tem uma entrada por categoria de
      `cat_names` com a proporcao de rodadas de self-consistency que a
      escolheram, calculada sempre que `confidence` inclui
      `"by_variable"`, e o tibble final ganha as colunas
      `<categoria>_confidence` correspondentes.
- **[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)**:
  corrigido crash “Result must be length 1, not N” em
  `.ac_compute_confidence()` (calculo de confianca via self-consistency)
  quando uma das k rodadas devolvia `categoria` como array JSON
  (`["tema_a", "tema_b"]`) em vez de string unica – apesar do prompt
  instruir explicitamente o contrario. A funcao irma
  `.ac_build_result_tibble()` ja colapsava esse caso corretamente
  (`paste(collapse = "|")`), mas o crash ocorria antes, no calculo de
  confianca, que nao tinha a mesma protecao. Mesma logica aplicada agora
  nas duas funcoes.

## acR 0.3.3

CRAN release: 2026-08-20

### Compatibilidade

- Teste `ac_plot_top_terms() gera ggplot valido` (em
  `test-plots-snapshot.R:56`) usava `"labels" %in% names(p)` como
  sanidade. Em ggplot2 4.x a estrutura interna do objeto ggplot mudou
  (nova base S7) e a checagem por nome de slot passou a retornar
  `FALSE`, quebrando o test na CRAN r-release-macos e r-oldrel-macos
  (post-acceptance check, deadline 2026-08-21). Substituido por
  `expect_no_error(ggplot2::ggplot_build(p))` – teste de buildabilidade
  real, independente de versao do ggplot2.

- Referencias ao modelo Groq `llama-3.3-70b-versatile` (e ao par
  `llama-3.1-8b-instant`) foram atualizadas para `openai/gpt-oss-120b`
  (e `openai/gpt-oss-20b`) em exemplos, vignettes, README, testes de
  integracao e na tabela de
  [`ac_qual_recommend_model()`](https://ahenriquecp.com/acR/reference/ac_qual_recommend_model.md).
  A Groq descontinuou os modelos Llama em 2026-06-17; chamadas com o
  nome antigo retornam HTTP 404. Nao afeta usuarios da CRAN diretamente
  (sao apenas defaults sugeridos e testes com `skip_if()` de API key),
  mas evita quebra de exemplos e de CI com `GROQ_API_KEY` configurada.

### Nova funcionalidade

- **[`ac_qual_report_full()`](https://ahenriquecp.com/acR/reference/ac_qual_report_full.md)**
  (novo) – relatorio consolidado multi-variavel. Aceita uma lista
  nomeada de resultados (`coded` + `codebook` + `reliability` opcional)
  e gera **um unico** arquivo (Markdown ou HTML) com uma secao por
  variavel, tabela sumaria no topo (k categorias, n docs, multilabel por
  variavel), mesmo idioma (`pt`/`en`) e formato consistente com
  \[ac_qual_report()\]. Atende ao caso de uso comum de analise de
  conteudo com N variaveis, que antes exigia consolidador ad hoc.

- **Campo `label` opcional em cada categoria do codebook.** Cada entrada
  de `categories` em \[ac_qual_codebook()\] agora aceita `label = "..."`
  como rotulo humano para exibicao (paralelo a `definition`,
  `examples_pos`, etc.). Se ausente, o rotulo defaults para o proprio
  slug (chave da lista). A saida de \[ac_qual_code()\] ganha coluna nova
  **`categoria_label`** com o rotulo traduzido; em multilabel, os labels
  vem unidos por `" | "` (espaco dos dois lados), enquanto a coluna
  `categoria` mantem `"|"` sem espaco como chave estavel de comparacao.
  Preservado tambem em
  [`ac_qual_save_codebook()`](https://ahenriquecp.com/acR/reference/ac_qual_save_codebook.md)
  /
  [`ac_qual_load_codebook()`](https://ahenriquecp.com/acR/reference/ac_qual_load_codebook.md)
  (YAML).

### Bug fixes – modulo qualitativo (pipeline LLM)

Tres bugs encontrados no
[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
e funcoes internas durante uso em producao (Gemini/Groq/OpenAI) foram
corrigidos:

- **`live = "terminal"` travava no primeiro documento com “Cannot find
  progress bar”** (`R/ac_qual_live.R`). A
  [`cli::cli_progress_bar()`](https://cli.r-lib.org/reference/cli_progress_bar.html)
  era criada sem `.envir`, amarrando o ciclo de vida da barra ao frame
  de `.ac_live_start()` – que retorna imediatamente. `cli` destruia a
  barra antes de
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
  conseguir chamar `cli_progress_update()`. Fix: `.ac_live_start()` (e
  `.ac_live_finish()`) agora aceita argumento `.envir` (padrao
  [`parent.frame()`](https://rdrr.io/r/base/sys.parent.html)), amarrando
  a barra ao frame do chamador – tipicamente
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md).

- **`temperature` de
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
  era aceito mas nunca usado** (`R/ac_qual_code.R`,
  `.ac_classify_one()`). O parametro formal era ignorado no corpo, entao
  as `k_consistency` rodadas de self-consistency (Wang et al., 2023)
  usavam sempre a temperatura padrao do provedor – variacao estocastica
  esperada nao acontecia, inflando `confidence_score` espuriamente. Fix:
  `temperature` agora e injetada via `ellmer::params(temperature = ...)`
  no argumento `params` do chat (respeita `params` explicitos passados
  pelo usuario via `...`). Para o caminho
  `chat = <Chat pre-configurado>`, o Chat e reconstruido com o novo
  `params` via `get_provider()` + `get_model()`, com fallback graceful
  para o clone antigo se a reconstrucao falhar.

- **`ac_qual_report(path = <relativo>)` falhava com “The directory ‘X’
  does not exist”** mesmo com a pasta criada, e derrubava loops sem
  `tryCatch`. Causa:
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
  muda o cwd durante o knit, e `normalizePath(path, mustWork = FALSE)`
  nao converte confiavelmente paths relativos inexistentes em absolutos.
  Fix: `.ac_report_absolute_path()` resolve para absoluto contra o cwd
  atual antes de qualquer `render()`, e a pasta destino e criada com
  `dir.create(recursive = TRUE)` se necessario.

- **`multilabel = TRUE` quebrava com “Result must be length 1, not N”
  quando o modelo devolvia array JSON** (`R/ac_qual_code.R`,
  `.ac_build_system_prompt()` + `.ac_build_result_tibble()`). O prompt
  nao instruia explicitamente que `"categoria"` deve ser sempre uma
  string (mesmo em multilabel), e o parser assumia que `main$categoria`
  era escalar. Um documento com array `["a","b"]` quebrava a
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html)
  inteira, derrubando a classificacao de TODOS os documentos daquela
  variavel. Fix: (a) prompt multilabel agora instrui a devolver
  “tecnica\|politica” (string pipe-separada) e proibe explicitamente
  array JSON; (b) parser defensivo faz sempre
  `paste(as.character(main$categoria), collapse = "|")`, absorvendo
  arrays quando o modelo ignora a instrucao.

## acR 0.3.2

CRAN release: 2026-08-07

### Novidades

- **[`ac_cluster_documents()`](https://ahenriquecp.com/acR/reference/ac_cluster_documents.md)**
  (novo) — clustering nao supervisionado de documentos com hierarquico
  (Ward.D2), k-means ou PAM. Features configuraveis (TF-IDF ou
  contagens), distancias `cosine`/`euclidean`, escolha automatica de `k`
  por silhueta (usa `cluster` de `Suggests`). Retorna S3 `ac_cluster`
  com metodo `print`.
- **[`ac_plot_cluster()`](https://ahenriquecp.com/acR/reference/ac_plot_cluster.md)**
  (novo) — tres tipos de visualizacao para objetos `ac_cluster`:
  `dendrogram` (default para hclust), `scatter` (projecao PCA 2D com
  labels) e `heatmap` (matriz de dissimilaridade ordenada pelo
  dendrograma).
- **Nova vignette** —
  [`vignette("cluster")`](https://ahenriquecp.com/acR/articles/cluster.md):
  “Agrupamento nao supervisionado de documentos”. Explica as tres
  familias (hard/soft clustering e LDA) com tabela de quando usar cada
  uma, apresenta seis visualizacoes complementares (dendrograma, PCA,
  heatmap, top termos por cluster, curva de silhueta e comparacao
  lado-a-lado hard vs. LDA/gamma), valida a particao contra um
  `tema_real` mantido fora do modelo e integra o clustering ao pipeline
  qualitativo.
- **Documentacao** — README, `_pkgdown.yml` (menu de vignettes e secao
  “Pipeline quantitativo”) apontam para a nova vignette; acentos
  corrigidos nas entradas visiveis do menu.
- **[`ac_plot_wordcloud_comparative()`](https://ahenriquecp.com/acR/reference/ac_plot_wordcloud_comparative.md)**
  agora aceita **N grupos** (\>= 2) em vez de somente 2. Cada grupo vira
  uma faceta; nas duas implementacoes (`backend = "ggwordcloud"` e
  `backend = "ggplot"`) o layout usa `facet_wrap()`. Cores padrao passam
  a vir de `ac_palette(N)`. A validacao antiga (`length(grupos) != 2L`)
  foi substituida por `length(grupos) < 2L`.
- **Polimento de documentacao** — reescrita de `qualitativo-llm.Rmd`
  (nova secao “Quando usar LLM (e quando NAO usar)” com tabela
  decisoria, tabela de custo por modelo e “Diagnosticando problemas
  comuns” com 4 modos de falha); `quantitativo.Rmd` (nova secao “Qual
  metrica responde qual pergunta”); `lda.Rmd` (comparativo LDA vs.
  clustering vs. LLM e heatmap gamma com referencia cruzada ao cluster).
  Roxygen de
  [`ac_qual_codebook()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook.md),
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md),
  [`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md),
  [`ac_import()`](https://ahenriquecp.com/acR/reference/ac_import.md),
  [`ac_qual_report()`](https://ahenriquecp.com/acR/reference/ac_qual_report.md),
  [`ac_qual_irr()`](https://ahenriquecp.com/acR/reference/ac_qual_irr.md),
  [`ac_tokenize()`](https://ahenriquecp.com/acR/reference/ac_tokenize.md)
  e [`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md)
  expandidos com framing teorico e faixas interpretativas. `@examples`
  mais realistas em
  [`ac_keyness()`](https://ahenriquecp.com/acR/reference/ac_keyness.md),
  [`ac_tf_idf()`](https://ahenriquecp.com/acR/reference/ac_tf_idf.md),
  [`ac_cooccurrence()`](https://ahenriquecp.com/acR/reference/ac_cooccurrence.md)
  e
  [`ac_sentiment()`](https://ahenriquecp.com/acR/reference/ac_sentiment.md).
- **Generalizacao do keyness** — README, vignette `quantitativo` e
  roxygen de
  [`ac_keyness()`](https://ahenriquecp.com/acR/reference/ac_keyness.md)
  descrevem grupos genericamente (qualquer variavel categorica: partido,
  periodo, tema, regiao, condicao experimental) em vez do exemplo
  “governo x oposicao” que havia ossificado como canonico.
- **Cobertura de testes** subiu de ~55% (0.3.1) para ~66%. Testes novos
  em `ac_cluster.R` (67% -\> 91%), `ac_qual_codebook.R` (43% -\> 48%) e
  `ac_qual_reliability.R`.

### Adequacao CRAN (correcoes de resubmissao)

- [`ac_wordcloud()`](https://ahenriquecp.com/acR/reference/ac_wordcloud.md),
  [`ac_plot_wordcloud_comparative()`](https://ahenriquecp.com/acR/reference/ac_plot_wordcloud_comparative.md)
  e
  [`ac_qual_sample()`](https://ahenriquecp.com/acR/reference/ac_qual_sample.md)
  agora expoem argumento `seed` (padrao `42L`; `NULL` usa o RNG
  corrente). A semente e escopada via
  [`withr::with_seed()`](https://withr.r-lib.org/reference/with_seed.html)
  – nao altera o `.Random.seed` do usuario apos o retorno.
- Removido uso de `<<-` em `.ac_report_build_md()` (`ac_qual_report.R`):
  o buffer de linhas agora vive em um
  [`environment()`](https://rdrr.io/r/base/environment.html) local.
- Removidas escritas ao `.GlobalEnv` em
  [`ac_plot_wordcloud_comparative()`](https://ahenriquecp.com/acR/reference/ac_plot_wordcloud_comparative.md);
  RNG passa a ser escopado exclusivamente via
  [`withr::with_seed()`](https://withr.r-lib.org/reference/with_seed.html).
- `withr` movido de `Suggests` para `Imports` (usado em codigo
  principal).

## acR 0.3.1

### Ajustes

- **[`ac_plot_wordcloud_comparative()`](https://ahenriquecp.com/acR/reference/ac_plot_wordcloud_comparative.md)**
  — layout reproduzivel via novo argumento `seed` (padrao `42L`), com
  salvaguarda do RNG global; cores padrao agora vem de `ac_palette(2L)`
  em vez de codigos fixos. Novo argumento `backend`
  (`"auto"`/`"ggwordcloud"`/`"ggplot"`): quando `ggwordcloud` esta
  instalado, usa `geom_text_wordcloud` com facets lado a lado; caso
  contrario, mantem o layout jitter original.
- **[`ac_plot_xray()`](https://ahenriquecp.com/acR/reference/ac_plot_xray.md)**
  — corrigido caso de divisao por zero em documentos com apenas 1 token
  (posicao passa a ser `0.5`); warning agora identifica quais termos
  ficaram sem ocorrencia, nao apenas o caso extremo de nenhum
  encontrado.
- **[`ac_import()`](https://ahenriquecp.com/acR/reference/ac_import.md)**
  — a ordem dos documentos no corpus resultante agora preserva a ordem
  de entrada em `path`, mesmo misturando arquivos OCR e texto; `doc_id`
  duplicados sao desambiguados automaticamente com sufixos (`_2`, `_3`,
  …) e um aviso; erros migrados para
  [`cli::cli_abort`](https://cli.r-lib.org/reference/cli_abort.html)
  (padrao do pacote). Loop de OCR ganhou barra de progresso via
  [`cli::cli_progress_bar()`](https://cli.r-lib.org/reference/cli_progress_bar.html).

### Testes

- Nova cobertura para
  [`ac_export()`](https://ahenriquecp.com/acR/reference/ac_export.md),
  [`ac_qual_irr()`](https://ahenriquecp.com/acR/reference/ac_qual_irr.md),
  [`theme_ac()`](https://ahenriquecp.com/acR/reference/theme_ac.md),
  [`ac_palette()`](https://ahenriquecp.com/acR/reference/ac_palette.md)
  e
  [`is_ac_corpus()`](https://ahenriquecp.com/acR/reference/is_ac_corpus.md).

## acR 0.3.0

### Novas funcionalidades — Visualização e Tema

- **[`theme_ac()`](https://ahenriquecp.com/acR/reference/theme_ac.md)**
  — tema `ggplot2` minimalista e consistente, usado por todos os
  `ac_plot_*()`. Deriva de `theme_minimal()` com ajustes editoriais:
  títulos em negrito, gridlines suaves, tipografia compacta.

- **[`ac_palette()`](https://ahenriquecp.com/acR/reference/ac_palette.md)**
  — paleta categórica de 8 cores (adaptada de Okabe-Ito para
  compatibilidade WCAG AA e daltonismo).

- **`ac_wordcloud(backend = ...)`** — reescrita para preferir
  `ggwordcloud` (retorna `ggplot`, layout mais agradável, tipografia
  editorial), com fallback para `wordcloud` clássico. Novos argumentos
  `backend` e `title`.

- **[`ac_plot_xray()`](https://ahenriquecp.com/acR/reference/ac_plot_xray.md)**
  — refinada com
  [`theme_ac()`](https://ahenriquecp.com/acR/reference/theme_ac.md) +
  [`ac_palette()`](https://ahenriquecp.com/acR/reference/ac_palette.md),
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
  [`ac_qual_report()`](https://ahenriquecp.com/acR/reference/ac_qual_report.md).

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

- **[`ac_qual_report()`](https://ahenriquecp.com/acR/reference/ac_qual_report.md)**
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
  [`ac_qual_codebook_translate()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook_translate.md)
  e
  [`ac_qual_codebook_hybrid()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook_hybrid.md)
  ganham `skip_if()` defensivo para versões do `ellmer` sem
  [`chat()`](https://ellmer.tidyverse.org/reference/chat-any.html).

- Total: 688 pass, 4 skips justificados.

- `R CMD check`: 0 errors, 0 warnings, 1 note inofensiva (clock).

## acR 0.2.1

### Novas funções

- [`ac_qual_codebook_hybrid()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook_hybrid.md)
  — enriquece definições de categorias com referências bibliográficas
  buscadas via LLM, combinando fundamento manual com ancora teórica
  induzida da literatura.

- [`ac_qual_codebook_merge()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook_merge.md)
  — funde dois objetos `ac_codebook` em um único, com controle de
  conflitos de nomes (`error`, `keep_first`, `keep_second`,
  `rename_second`).

- [`ac_qual_codebook_translate()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook_translate.md)
  — traduz instruções, definições e exemplos de um codebook para outro
  idioma via LLM (`"pt"` ↔︎ `"en"`).

- [`ac_qual_codebook_history()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook_history.md)
  — retorna o histórico de modificações de um `ac_codebook` (adições,
  remoções, merges, traduções, enriquecimentos).

- [`as_prompt()`](https://ahenriquecp.com/acR/reference/as_prompt.md) /
  [`as_prompt.ac_codebook()`](https://ahenriquecp.com/acR/reference/as_prompt.md)
  — converte um `ac_codebook` em system prompt formatado para uso direto
  com objetos `Chat` do `ellmer`, com suporte a raciocínio estruturado
  (`reasoning_length`).

- [`as_prompt.default()`](https://ahenriquecp.com/acR/reference/as_prompt.md)
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
  [`ac_qual_codebook()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook.md).

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
