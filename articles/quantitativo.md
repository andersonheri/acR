# Análise quantitativa de texto

Esta vignette percorre o **módulo quantitativo** do `acR` em cima de um
corpus de discursos parlamentares fabricado para o exemplo. Cada etapa é
apresentada com uma pergunta metodológica (*por que faço isso?*) antes
do código e do gráfico.

O caminho é o clássico da análise de conteúdo estatística: **corpus →
limpeza → tokenização → frequências → distintividade → visualização**.

## Qual métrica responde qual pergunta?

O módulo quantitativo tem dezoito técnicas, agrupadas em cinco famílias.
Aprender qual usar em cada situação vale mais que decorar sintaxe: a
pergunta de pesquisa escolhe a técnica, não o contrário.

**Frequência, distintividade e coocorrência**

| Pergunta | Técnica | Função |
|----|----|----|
| Que palavras dominam o corpus como um todo? | Frequência bruta | [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md) → [`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md) |
| Que palavras são **distintivas** de cada documento vs. o resto? | TF-IDF | [`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md) → [`ac_plot_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_plot_tf_idf.md) |
| Que palavras separam **um grupo** do outro estatisticamente? | *Keyness* | [`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md) → [`ac_plot_keyness()`](https://andersonheri.github.io/acR/reference/ac_plot_keyness.md) |
| Que palavras **andam juntas** (associação sintagmática)? | Coocorrência | [`ac_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_cooccurrence.md) → [`ac_plot_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_plot_cooccurrence.md) |
| Que bigramas/trigramas aparecem juntos mais do que o esperado pelo acaso? | Colocações | [`ac_collocations()`](https://andersonheri.github.io/acR/reference/ac_collocations.md) |
| **Onde no texto** um termo aparece com mais frequência? | X-ray plot | [`ac_plot_xray()`](https://andersonheri.github.io/acR/reference/ac_plot_xray.md) |
| Em que contexto exato um termo aparece a cada ocorrência? | Concordância/KWIC | [`ac_kwic()`](https://andersonheri.github.io/acR/reference/ac_kwic.md) |
| Panorama visual rápido para relatório ou apresentação | Nuvem de palavras | [`ac_wordcloud()`](https://andersonheri.github.io/acR/reference/ac_wordcloud.md) (`ggwordcloud`) |

**Diagnóstico do corpus**

| Pergunta | Técnica | Função |
|----|----|----|
| O texto é fácil ou difícil de ler? | Legibilidade | [`ac_readability()`](https://andersonheri.github.io/acR/reference/ac_readability.md) |
| O vocabulário é rico ou repetitivo? | Diversidade lexical | [`ac_lexical_diversity()`](https://andersonheri.github.io/acR/reference/ac_lexical_diversity.md) |
| O corpus se comporta como linguagem natural (não dominado por ruído)? | Lei de Zipf | [`ac_plot_zipf()`](https://andersonheri.github.io/acR/reference/ac_plot_zipf.md) |

**Série temporal**

| Pergunta | Técnica | Função |
|----|----|----|
| Um termo, sentimento ou qualquer métrica muda ao longo do tempo? | Série temporal | [`ac_temporal()`](https://andersonheri.github.io/acR/reference/ac_temporal.md) → [`ac_plot_temporal()`](https://andersonheri.github.io/acR/reference/ac_plot_temporal.md) |

**Escalas e mapas**

| Pergunta | Técnica | Função |
|----|----|----|
| Onde cada documento se posiciona num espectro contínuo (favorável↔︎desfavorável)? | Wordscores | [`ac_wordscores()`](https://andersonheri.github.io/acR/reference/ac_wordscores.md) |
| Como grupos e termos se relacionam num mapa 2D, sem assumir tópicos latentes? | Análise de correspondência | [`ac_ca()`](https://andersonheri.github.io/acR/reference/ac_ca.md) |

**Dicionários e léxicos**

| Pergunta | Técnica | Função |
|----|----|----|
| Quanto do texto pertence a cada categoria temática que eu defino? | Dicionário multi-categoria | [`ac_dictionary()`](https://andersonheri.github.io/acR/reference/ac_dictionary.md) |
| Que emoções (não só positivo/negativo) o texto expressa? | Léxico de emoção | [`ac_emotion()`](https://andersonheri.github.io/acR/reference/ac_emotion.md) |
| Meu dicionário classifica bem, comparado a uma codificação humana? | Validação de dicionário | [`ac_dictionary_validate()`](https://andersonheri.github.io/acR/reference/ac_dictionary_validate.md) |

**Não é redundância.** As três métricas de frequência respondem
perguntas diferentes:

- **Frequência bruta** conta ocorrências. É a primeira olhada, mas os
  termos no topo tendem a ser genéricos (mesmo depois de tirar
  *stopwords*).
- **TF-IDF** penaliza termos que aparecem em muitos documentos: destaca
  o vocabulário **próprio** de cada texto. Sem grupo definido a priori.
- **Keyness** compara **grupos** com um teste estatístico (χ² ou
  log-likelihood). Precisa de uma variável categórica no corpus.

Para descobrir tipologias emergentes sem categoria a priori, veja
[`vignette("cluster")`](https://andersonheri.github.io/acR/articles/cluster.md)
e
[`vignette("lda")`](https://andersonheri.github.io/acR/articles/lda.md)
(não supervisionado). Para rotular com categorias teóricas, veja
[`vignette("qualitativo-llm")`](https://andersonheri.github.io/acR/articles/qualitativo-llm.md)
(assistido).

## Sequência sugerida para reportar resultados

Um erro comum em análise de conteúdo computacional é aplicar uma técnica
isoladamente, sem o diagnóstico que justifica o resultado. A ordem
abaixo segue a lógica de qualquer método reportável: primeiro você
mostra que o corpus é adequado para a análise, depois descreve seu
conteúdo, e só então compara grupos ou constrói escalas. Pular etapas é
o motivo mais comum de revisores pedirem reanálise.

| Ordem | Etapa | Por que vem nessa posição |
|:--:|----|----|
| 1 | Limpeza e tokenização (§2-3) | Sem isso, qualquer contagem é dominada por artigos e preposições, mascarando o sinal. |
| 2 | Diagnóstico do corpus (§10-11) | Legibilidade e diversidade lexical descrevem *o material em si*: um corpus muito homogêneo ou pouco diverso limita o que qualquer análise posterior pode revelar. A Lei de Zipf confirma que o corpus se comporta como linguagem natural, não como ruído ou dados malformados. |
| 3 | Frequência e distintividade (§5, §7) | Primeiro você descreve o vocabulário geral (frequência), depois o que é próprio de cada documento (TF-IDF). Isso ancora a leitura qualitativa dos resultados seguintes. |
| 4 | Comparação entre grupos (§8, §13) | *Keyness* e série temporal respondem à pergunta comparativa central da maioria dos estudos: o que muda entre grupos ou ao longo do tempo. Só faz sentido depois que o vocabulário geral já foi descrito. |
| 5 | Associação e contexto (§9, §12) | Coocorrência, colocações e KWIC aprofundam *por que* um termo é relevante, qualificando os achados das etapas 3-4 com evidência de uso em contexto. |
| 6 | Escalas e classificação (§14-16) | Wordscores, análise de correspondência e dicionários produzem medidas derivadas (posição num espectro, categoria temática). Por dependerem do vocabulário já mapeado nas etapas anteriores, vêm depois, não antes. |
| 7 | Validação | Toda classificação por dicionário (§15) precisa de [`ac_dictionary_validate()`](https://andersonheri.github.io/acR/reference/ac_dictionary_validate.md) contra uma amostra humana antes de ir para o relatório final: é o que transforma uma heurística em achado defensável (Grimmer & Stewart, 2013). |

Essa ordem é um ponto de partida, não uma regra rígida: um estudo focado
só em descrever o corpus pode parar na etapa 2; um estudo que já tem uma
variável de grupo definida a priori pode ir direto da etapa 1 à 4. O que
não muda é a lógica: descreva antes de comparar, e valide antes de
publicar.

``` r

library(acR)
```

## 1. Construir o corpus

O
[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)
padroniza qualquer `data.frame` em um objeto com colunas fixas `doc_id`
e `text`, mantendo os metadados que você quiser preservar para
comparações posteriores.

``` r

textos <- c(
  "O governo anunciou nova politica fiscal para reduzir o deficit público.",
  "A oposicao critica o aumento dos gastos e da divida pública no orcamento.",
  "Parlamentares debatem a reforma tributária e o imposto de renda das familias.",
  "O presidente vetou o projeto que ampliava beneficios sociais para os pobres.",
  "O Senado aprovou o marco legal para investimentos em infraestrutura logistica.",
  "Deputados votam pela reducao da carga tributária para pequenas empresas.",
  "A politica monetária do Banco Central eleva a taxa de juros para conter inflacao.",
  "A inflacao acima da meta preocupa economistas e o mercado financeiro.",
  "O relator defendeu emendas ao texto do orcamento com foco em saude e educacao.",
  "A comissao aprovou o projeto que amplia beneficios sociais no interior.",
  "O ministro afirmou que a reforma tributária simplifica o sistema para empresas.",
  "Lideres da oposicao pediram vistas ao projeto na comissao de constituicao."
)

meta <- data.frame(
  text = textos,
  tema = c("fiscal","fiscal","tributário","social","infraestrutura",
           "tributário","monetário","monetário","fiscal","social",
           "tributário","fiscal"),
  stringsAsFactors = FALSE
)

corpus <- ac_corpus(meta)
corpus
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 12
#> • Metadados: 1 coluna
#> • Idioma: "pt"
#> 
#> # A tibble: 12 × 3
#>   doc_id text                                                              tema 
#>   <chr>  <chr>                                                             <chr>
#> 1 doc_1  O governo anunciou nova politica fiscal para reduzir o deficit p… fisc…
#> 2 doc_2  A oposicao critica o aumento dos gastos e da divida pública no o… fisc…
#> 3 doc_3  Parlamentares debatem a reforma tributária e o imposto de renda … trib…
#> 4 doc_4  O presidente vetou o projeto que ampliava beneficios sociais par… soci…
#> 5 doc_5  O Senado aprovou o marco legal para investimentos em infraestrut… infr…
#> 6 doc_6  Deputados votam pela reducao da carga tributária para pequenas e… trib…
#> # ℹ 6 more rows
```

## 2. Limpeza: por que remover *stopwords*?

Sem remoção de *stopwords*, os termos mais frequentes de qualquer corpus
em português são artigos, preposições e conjunções (`o`, `a`, `de`,
`que`, `para`…). Eles carregam pouquíssima informação temática e sufocam
qualquer padrão real de vocabulário. A regra prática em análise de
conteúdo (Sampaio & Lycarião, 2021) é sempre remover *stopwords* antes
de contar frequências ou calcular distintividade.

O
[`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md)
aceita o parâmetro `remove_stopwords = "pt"` para aplicar uma lista de
*stopwords* portuguesas curada. Você pode adicionar seu próprio
glossário via `extra_stopwords`.

``` r

corpus_limpo <- ac_clean(
  corpus,
  remove_stopwords = "pt",
  extra_stopwords  = c("pra", "pro")  # opcional: coloquiais
)
corpus_limpo
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 12
#> • Metadados: 1 coluna
#> • Idioma: "pt"
#> 
#> # A tibble: 12 × 3
#>   doc_id text                                                              tema 
#>   <chr>  <chr>                                                             <chr>
#> 1 doc_1  governo anunciou nova politica fiscal reduzir deficit público     fisc…
#> 2 doc_2  oposicao critica aumento gastos divida pública orcamento          fisc…
#> 3 doc_3  parlamentares debatem reforma tributária imposto renda familias   trib…
#> 4 doc_4  presidente vetou projeto ampliava beneficios sociais pobres       soci…
#> 5 doc_5  senado aprovou marco legal investimentos infraestrutura logistica infr…
#> 6 doc_6  deputados votam reducao carga tributária pequenas empresas        trib…
#> # ℹ 6 more rows
```

## 3. Tokenização

[`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)
quebra cada documento em unidades de análise. Com `n = 1L` são unigramas
(palavras); com `n = 2L`, bigramas (“reforma tributária”). Bigramas são
úteis quando você quer capturar **expressões compostas** que perdem
sentido tokenizadas separadamente.

``` r

tokens <- ac_tokenize(corpus_limpo, n = 1L)
head(tokens, 12)
#> # A tibble: 12 × 3
#>    doc_id token_id token   
#>    <chr>     <int> <chr>   
#>  1 doc_1         1 governo 
#>  2 doc_1         2 anunciou
#>  3 doc_1         3 nova    
#>  4 doc_1         4 politica
#>  5 doc_1         5 fiscal  
#>  6 doc_1         6 reduzir 
#>  7 doc_1         7 deficit 
#>  8 doc_1         8 público 
#>  9 doc_2         1 oposicao
#> 10 doc_2         2 critica 
#> 11 doc_2         3 aumento 
#> 12 doc_2         4 gastos
```

## 4. Frequência

Contagem de ocorrências por documento e depois agregação.
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)
já retorna no formato *tidy* pronto para pipeline com `dplyr` e
`ggplot2`.

``` r

contagem <- ac_count(corpus_limpo)
contagem
#> # A tibble: 88 × 3
#>    doc_id token        n
#>    <chr>  <chr>    <int>
#>  1 doc_1  anunciou     1
#>  2 doc_1  deficit      1
#>  3 doc_1  fiscal       1
#>  4 doc_1  governo      1
#>  5 doc_1  nova         1
#>  6 doc_1  politica     1
#>  7 doc_1  público      1
#>  8 doc_1  reduzir      1
#>  9 doc_10 amplia       1
#> 10 doc_10 aprovou      1
#> # ℹ 78 more rows
```

## 5. Top termos: o vocabulário do corpus

O gráfico abaixo mostra as **15 palavras mais frequentes**. Agora, com
*stopwords* removidas, é possível ler os *temas* dominantes: reforma,
projeto, tributária, orçamento, etc.

``` r

top <- ac_top_terms(contagem, n = 15)
ac_plot_top_terms(top) +
  ggplot2::labs(
    title    = "Termos mais frequentes no corpus",
    subtitle = "Discursos legislativos - 12 documentos fabricados",
    caption  = "acR - vignette Análise Quantitativa"
  )
```

![](quantitativo_files/figure-html/top-termos-1.png)

> **Como interpretar:** o comprimento da barra é contagem bruta de
> ocorrências, não relevância temática. Frequência alta identifica
> candidatos a tema dominante, mas não confirma: um termo pode ser
> frequente só porque é comum na língua em geral (mesmo após remover
> *stopwords*). Compare sempre com o TF-IDF (§7) antes de afirmar que um
> termo frequente é também *distintivo* do corpus.

## 6. Nuvem de palavras

Uma nuvem funciona como **panorama visual** rápido, útil para relatórios
e apresentações. Não substitui análise numérica: o tamanho da palavra é
proporcional à frequência, mas a posição no plot é aleatória.

Desde a versão 0.3.1 o
[`ac_wordcloud()`](https://andersonheri.github.io/acR/reference/ac_wordcloud.md)
prefere automaticamente o motor `ggwordcloud` (retorna um `ggplot`, com
tipografia mais legível e layout consistente com o tema do pacote); se
ele não estiver instalado, cai para o `wordcloud` clássico. Você pode
forçar via `backend = "ggwordcloud"` ou `backend = "wordcloud"`.

``` r

ac_wordcloud(contagem, max_words = 40, title = "Panorama do corpus")
#> Warning in wordcloud_boxes(data_points = points_valid_first, boxes = boxes, :
#> Some words could not fit on page. They have been removed.
```

![](quantitativo_files/figure-html/wordcloud-1.png)

### 6.1 Nuvem comparativa entre grupos

Quando o corpus tem uma variável de agrupamento (partido, período, tema,
etc.), a nuvem comparativa mostra lado a lado os termos mais
**distintivos** de cada grupo, pontuados por TF-IDF calculado tratando
cada grupo como um “documento”. Aceita 2, 3 ou mais grupos.

``` r

# Nosso corpus tem 5 temas distintos: todos entram na comparativa.
ac_plot_wordcloud_comparative(
  corpus,
  group     = tema,
  max_words = 25,
  title     = "Termos distintivos por tema"
)
#> Warning in wordcloud_boxes(data_points = points_valid_first, boxes = boxes, :
#> Some words could not fit on page. They have been removed.
#> Warning in wordcloud_boxes(data_points = points_valid_first, boxes = boxes, :
#> Some words could not fit on page. They have been removed.
#> Warning in wordcloud_boxes(data_points = points_valid_first, boxes = boxes, :
#> Some words could not fit on page. They have been removed.
#> Warning in wordcloud_boxes(data_points = points_valid_first, boxes = boxes, :
#> Some words could not fit on page. They have been removed.
#> Warning in wordcloud_boxes(data_points = points_valid_first, boxes = boxes, :
#> Some words could not fit on page. They have been removed.
```

![](quantitativo_files/figure-html/wordcloud-comp-1.png)

O layout usa `ggwordcloud` com facets quando disponível
(`backend = "auto"`), e cai em `geom_text` com jitter reproduzível
quando não. A semente do posicionamento é controlada por `seed = 42L`.
Cores vêm de
[`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md)
por padrão: uma por grupo.

## 7. TF-IDF: o que é *distintivo* em cada documento?

Frequência bruta favorece palavras que aparecem em quase todos os
documentos (mesmo depois de *stopwords*). O **TF-IDF** (*term frequency
× inverse document frequency*) penaliza termos comuns e destaca
vocabulário próprio de cada grupo, útil quando o corpus é composto por
textos com propostas ou temas distintos.

Com **12 discursos curtos** e cada palavra aparecendo em 1–2 documentos,
o TF-IDF *por documento* resulta em barras quase todas iguais (todo
termo único vale o mesmo). O padrão fica mais legível **agregando por
tema**: tratamos cada tema como um “documento” e o TF-IDF revela o
vocabulário característico de cada eixo temático do corpus.

``` r

freq_tema  <- ac_count(corpus_limpo, by = "tema")
tfidf_tema <- ac_tf_idf(freq_tema, by = "tema")

ac_plot_tf_idf(tfidf_tema, by = "tema", n = 6) +
  ggplot2::labs(
    title    = "Termos mais distintivos por tema (TF-IDF)",
    subtitle = "Cada eixo temático como um documento; alta pontuação = termo característico do tema"
  )
```

![](quantitativo_files/figure-html/tfidf-1.png)

## 8. *Keyness*: o que é distintivo entre **grupos**?

Enquanto TF-IDF compara documento vs. corpus, ***keyness*** compara
**grupos**: o critério que define o grupo é seu, não do pacote. Pode ser
partido, período histórico, tema, região, autor, condição experimental,
faixa etária, qualquer variável categórica no seu corpus. É a métrica
clássica para a pergunta comparativa: *“o que um grupo diz que o outro
não diz?”*.

Aqui comparamos os temas **fiscal** e **tributário**: quais palavras
marcam cada lado?

``` r

freq_tema     <- ac_count(corpus_limpo, by = "tema")
freq_2grupos  <- freq_tema[freq_tema$tema %in% c("fiscal", "tributário"), ]

kn <- ac_keyness(freq_2grupos, group = "tema", target = "fiscal")

ac_plot_keyness(kn, n = 10) +
  ggplot2::labs(
    title    = "Palavras distintivas: 'fiscal' vs. 'tributário'",
    subtitle = "Barras positivas = distintivas do tema 'fiscal'"
  )
```

![](quantitativo_files/figure-html/keyness-1.png)

Interpretação: chi-quadrado alto indica **sobre-representação
estatística**. Termos como *deficit* e *orçamento* marcam o eixo fiscal;
*carga* e *renda* o tributário, resultado consistente com o corpus de
exemplo.

## 9. Rede de co-ocorrência

Palavras que aparecem próximas com frequência formam **agrupamentos
semânticos**. A rede de coocorrência mostra essas vizinhanças com base
numa **janela** de tokens (aqui, 5 palavras à esquerda e à direita).

Útil para: identificar frames, mapear associações conceituais e
encontrar combinações de palavras que definem sub-temas dentro do
corpus.

``` r

cooc <- ac_cooccurrence(corpus_limpo, window = 5L, min_count = 2L)

if (requireNamespace("ggraph", quietly = TRUE)) {
  ac_plot_cooccurrence(cooc, top_n = 25) +
    ggplot2::labs(
      title    = "Rede de coocorrência (janela = 5, freq mínima = 2)",
      subtitle = "Arestas conectam termos que co-ocorrem no mesmo contexto"
    )
}
```

![](quantitativo_files/figure-html/coocorr%C3%AAncia-1.png)

> **Como interpretar:** o tamanho do nó reflete seu grau (quantas
> conexões ele tem): nós maiores são mais centrais na rede,
> conectando-se a mais termos diferentes. A espessura da aresta reflete
> a força da coocorrência entre aquele par específico. Agrupamentos
> visuais (*clusters* de nós bem conectados entre si, mas pouco
> conectados ao resto) costumam corresponder a sub-temas do corpus.

### 9.1 Trocando o peso: PMI em vez de contagem

A rede padrão pondera arestas pela **contagem** de coocorrências: termos
frequentes tendem a dominar. O **PMI** (*pointwise mutual information*)
mede o quanto duas palavras aparecem juntas *acima do esperado por
acaso*; revela pares surpreendentes, mesmo que raros.

``` r

if (requireNamespace("ggraph", quietly = TRUE)) {
  ac_plot_cooccurrence(cooc, top_n = 25, weight = "pmi") +
    ggplot2::labs(
      title    = "Rede de coocorrência ponderada por PMI",
      subtitle = "Destaca pares associados além do esperado por acaso"
    )
}
```

![](quantitativo_files/figure-html/coocorr%C3%AAncia-pmi-1.png)

### 9.2 Trocando o layout

O layout controla como os nós são posicionados no plano. O padrão `"fr"`
(Fruchterman-Reingold) minimiza cruzamentos; `"kk"` (Kamada-Kawai)
respeita distâncias de grafo; `"circle"` alinha tudo num anel: útil para
corpora pequenos onde a topologia importa menos que a legibilidade.

``` r

if (requireNamespace("ggraph", quietly = TRUE)) {
  ac_plot_cooccurrence(cooc, top_n = 25, layout = "circle") +
    ggplot2::labs(
      title    = "Rede de coocorrência: layout circular",
      subtitle = "Todas as palavras num anel; arestas mostram o grafo cru"
    )
}
```

![](quantitativo_files/figure-html/coocorr%C3%AAncia-circle-1.png)

### 9.3 Coocorrência como matriz (heatmap)

Quando a rede fica saturada de arestas, um **heatmap** das top-N
palavras pode ser mais legível: linhas e colunas são termos, e a
intensidade da célula é a coocorrência. Não requer `ggraph`.

``` r

top_tokens <- ac_top_terms(ac_count(corpus_limpo), n = 12)$token
cooc_mat   <- cooc[cooc$word1 %in% top_tokens & cooc$word2 %in% top_tokens, ]

ggplot2::ggplot(cooc_mat,
                ggplot2::aes(word1, word2, fill = cooc)) +
  ggplot2::geom_tile(color = "white") +
  ggplot2::scale_fill_gradient(low = "#F1F5F9", high = ac_palette(1)) +
  ggplot2::labs(
    title    = "Matriz de coocorrência (top 12 termos)",
    subtitle = "Alternativa ao grafo quando a rede fica densa",
    x = NULL, y = NULL, fill = "cooc."
  ) +
  theme_ac() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  )
```

![](quantitativo_files/figure-html/coocorr%C3%AAncia-heatmap-1.png)

## Novidades: diagnóstico de corpus, escalas e dicionários

As seções anteriores giram em torno de discursos parlamentares: um
domínio comum na ciência política, mas o módulo quantitativo não é
específico a ele. As técnicas a seguir são novas no pacote e são
apresentadas com exemplos de **outros domínios** (avaliações de produto,
atendimento ao cliente, notícias) para deixar claro que servem a
qualquer corpus de texto.

### 10. Legibilidade e diversidade lexical

Duas perguntas distintas sobre a *forma* do texto, independente do
conteúdo:

- **Legibilidade**
  ([`ac_readability()`](https://andersonheri.github.io/acR/reference/ac_readability.md)):
  o texto é fácil de ler? Adapta o índice de Flesch para português
  (Martins et al., 1996), combinando palavras por frase e sílabas por
  palavra. Útil para comparar, por exemplo, a complexidade de um manual
  técnico com a de um texto de divulgação para o público geral.
- **Diversidade lexical**
  ([`ac_lexical_diversity()`](https://andersonheri.github.io/acR/reference/ac_lexical_diversity.md)):
  o vocabulário é rico ou repetitivo? TTR é sensível ao tamanho do
  texto; Herdan’s C (Herdan,
  1960. e o MTLD (McCarthy & Jarvis, 2010) corrigem isso: o MTLD é a
        métrica recomendada para comparar textos de tamanhos diferentes.

``` r

avaliacoes <- data.frame(
  id = paste0("rev", 1:4),
  texto = c(
    "Este produto é incrível. Funciona perfeitamente bem e chegou rápido.",
    "O manual técnico especifica que a calibração requer ajuste periódico do sensor piezoelétrico conforme a norma vigente, o que demanda qualificação especializada do operador responsável pela manutenção preventiva do equipamento.",
    "Bom. Chegou. Funciona. Recomendo.",
    "A experiência de uso revelou inconsistências na usabilidade da interface, comprometendo a jornada do consumidor e gerando fricção considerável ao longo do processo de integração do dispositivo ao ecossistema existente."
  ),
  stringsAsFactors = FALSE
)
corpus_aval <- ac_corpus(avaliacoes, text = texto, docid = id)
```

``` r

ac_readability(corpus_aval)
#> # A tibble: 4 × 6
#>   doc_id n_palavras n_frases n_silabas flesch nivel        
#>   <chr>       <int>    <int>     <dbl>  <dbl> <chr>        
#> 1 rev1           10        2        24   40.7 dificil      
#> 2 rev2           30        1        84  -18.5 muito dificil
#> 3 rev3            4        4        10   36.3 dificil      
#> 4 rev4           30        1        81  -10.0 muito dificil
```

> **Como interpretar:** o índice de Flesch (1948), adaptado ao português
> por Martins et al. (1996), não é limitado a 0-100 na prática: é uma
> combinação linear de duas razões (palavras/frase e sílabas/palavra)
> sem teto nem piso, e pode produzir valores negativos em textos muito
> densos, como o manual técnico do exemplo (-18.5). A coluna `nivel`
> categoriza o escore em quatro faixas (adaptadas da literatura
> educacional brasileira que usa o índice): `>= 75` muito fácil,
> `50-74,9` fácil, `25-49,9` difícil, `< 25` muito difícil. Note que
> mesmo a avaliação curta e coloquial (“Bom. Chegou. Funciona.”) cai em
> *difícil* (36.3), não em *fácil*: o peso do termo sílabas/palavra na
> fórmula (84,6×) é alto o bastante para que poucas palavras longas já
> derrubem o escore, mesmo com frases curtas. Ainda assim, pontua bem
> mais alto que o manual técnico (-18.5): a métrica mede *forma*, não
> qualidade do conteúdo, e seu valor está em comparações relativas entre
> textos, não em ler o número isolado contra uma escala fixa de
> “bom”/“ruim”.

``` r

ac_lexical_diversity(corpus_aval)
#> # A tibble: 4 × 6
#>   doc_id n_tokens n_types   ttr herdan_c  mtld
#>   <chr>     <int>   <int> <dbl>    <dbl> <dbl>
#> 1 rev1         10      10 1        1      10  
#> 2 rev2         30      25 0.833    0.946  50.4
#> 3 rev3          4       4 1        1       4  
#> 4 rev4         30      25 0.833    0.946  50.4
```

> **Como interpretar:** o MTLD (McCarthy & Jarvis, 2010) não tem um
> limite teórico fixo, mas na prática valores abaixo de 40-50 costumam
> indicar vocabulário repetitivo (poucas palavras diferentes sustentando
> o texto); valores acima de 80-100 indicam vocabulário variado.
> **Atenção a textos muito curtos:** o algoritmo mede quantas vezes o
> TTR acumulado cai abaixo de um limiar (0,72) conforme o texto avança;
> se o documento termina antes de atingir esse limiar mesmo uma vez
> (como `rev1` e `rev3` aqui, com vocabulário 100% único), a métrica
> devolve o próprio número de tokens, não uma medida de diversidade de
> fato. Por isso `rev1` (10 tokens) e `rev3` (4 tokens) têm MTLD igual à
> sua contagem de palavras: a literatura de diversidade lexical
> recomenda amostras mais longas (dezenas a centenas de tokens) para o
> MTLD estabilizar como medida comparável. Compare sempre o MTLD entre
> textos de tamanho semelhante, nunca em isolado.

``` r

ac_plot_lexical_diversity(ac_lexical_diversity(corpus_aval), group_col = "doc_id",
                           metric = "mtld", type = "bar")
```

![](quantitativo_files/figure-html/lexical-diversity-plot-1.png)

Uma visão alternativa, útil quando há muitos documentos: um *scatter
plot* de legibilidade por diversidade lexical, cruzando as duas métricas
da seção num só gráfico, para ver se textos difíceis de ler também
tendem a ser lexicalmente mais ricos (ou se as duas dimensões são
independentes).

``` r

leg  <- ac_readability(corpus_aval)
div  <- ac_lexical_diversity(corpus_aval)
cruz <- merge(leg, div, by = "doc_id")

ggplot2::ggplot(cruz, ggplot2::aes(x = flesch, y = mtld, label = doc_id)) +
  ggplot2::geom_point(color = ac_palette(1), size = 3) +
  ggplot2::geom_text(vjust = -1, size = 3.2) +
  ggplot2::labs(
    title = "Legibilidade vs. diversidade lexical",
    subtitle = "Cada ponto é um documento; eixos sem relação necessária entre si",
    x = "Flesch (legibilidade)", y = "MTLD (diversidade lexical)"
  ) +
  theme_ac()
```

![](quantitativo_files/figure-html/readability-scatter-1.png)

### 11. Lei de Zipf: o corpus se comporta como linguagem natural?

A Lei de Zipf (Zipf, 1949) prevê que a frequência de uma palavra é
inversamente proporcional ao seu ranking: a palavra mais comum aparece
aproximadamente duas vezes mais que a segunda mais comum, três vezes
mais que a terceira, e assim por diante. É um diagnóstico clássico para
saber se um corpus é “normal” (não dominado por um único termo repetido
artificialmente, como aconteceria em dados malformados ou com erro de
coleta).

``` r

freq_aval <- ac_count(corpus_aval, drop_punct = TRUE)
ac_plot_zipf(freq_aval)
```

![](quantitativo_files/figure-html/zipf-1.png)

> **Como interpretar:** o gráfico é log-log (ambos os eixos em escala
> logarítmica). Se os pontos seguem de perto a linha pontilhada de
> referência (inclinação igual a -1), o corpus se comporta como texto
> natural. Pontos muito acima da linha no início (um ou dois termos
> dominando desproporcionalmente) costumam indicar *stopwords* não
> removidas ou um termo repetido por erro de coleta; corpora muito
> pequenos (como este exemplo de 4 documentos) naturalmente se desviam
> mais da linha teórica do que corpora de milhares de documentos.

Quando o corpus tem grupos, `ac_plot_zipf(freq_tbl, by = "grupo")`
faceta um painel por grupo, útil para comparar se todos os subcorpora
têm comportamento igualmente “natural” ou se algum se destoa (por
exemplo, por ter sido coletado de uma fonte com vocabulário mais técnico
ou repetitivo). Um exemplo com duas fontes bem diferentes: textos
jornalísticos variados vs. um manual técnico que repete o mesmo
vocabulário especializado.

``` r

grupos_zipf <- data.frame(
  id = paste0("doc", 1:12),
  texto = c(
    "O presidente anunciou um pacote de medidas economicas para estimular o crescimento.",
    "A prefeitura inaugurou um novo parque publico no bairro central da cidade.",
    "Cientistas descobriram uma nova especie de inseto na floresta amazonica.",
    "O time local venceu a partida decisiva do campeonato estadual de futebol.",
    "A exposicao de arte contemporanea atraiu milhares de visitantes no fim de semana.",
    "Pesquisadores desenvolveram uma vacina experimental contra uma doenca rara.",
    "O sistema deve ser configurado conforme o manual tecnico do equipamento.",
    "Configure o equipamento tecnico seguindo o manual de configuracao tecnica.",
    "O manual tecnico especifica a configuracao tecnica do sistema tecnico.",
    "Consulte o manual tecnico para configurar corretamente o sistema tecnico.",
    "A configuracao tecnica do equipamento segue o manual tecnico padrao.",
    "O equipamento tecnico requer configuracao conforme manual tecnico oficial."
  ),
  fonte = rep(c("noticias", "manual_tecnico"), each = 6),
  stringsAsFactors = FALSE
)
corpus_zipf_grupo <- ac_corpus(grupos_zipf, text = texto, docid = id, meta = fonte)
freq_zipf_grupo   <- ac_count(corpus_zipf_grupo, by = "fonte", drop_punct = TRUE)
ac_plot_zipf(freq_zipf_grupo, by = "fonte")
```

![](quantitativo_files/figure-html/zipf-grupo-1.png)

> **Como interpretar:** compare o ponto de posto 1 (a palavra mais
> frequente) de cada painel em relação à linha tracejada: em
> `manual_tecnico`, “tecnico” aparece bem mais acima da linha teórica do
> que a palavra mais frequente de `noticias`, sinal de um vocabulário
> mais concentrado em poucos termos repetidos, esperado num texto
> técnico/formulaico. Com corpora deste tamanho (6 documentos curtos por
> grupo) a curva de ambos os painéis ainda se desvia visivelmente da
> linha teórica (como já discutido acima): o que vale comparar aqui é a
> posição *relativa* dos pontos iniciais entre os grupos, não o ajuste
> absoluto de nenhum dos dois à reta.

### 12. Concordância (KWIC) e colocações

Frequência bruta não mostra *como* uma palavra é usada. Duas ferramentas
complementares respondem a essa lacuna: **KWIC** mostra o contexto de
cada ocorrência individual; **colocações** medem, de forma agregada,
quais pares de palavras andam juntos mais do que o acaso explicaria. São
técnicas distintas que respondem perguntas diferentes, então cada uma
tem sua própria subseção abaixo.

Corpus de exemplo para as duas: três registros fictícios de atendimento
ao cliente.

``` r

atendimento <- data.frame(
  id = paste0("call", 1:3),
  texto = c(
    "o cliente reclamou que o produto chegou com defeito de fabrica",
    "outro cliente relatou defeito no produto depois de uma semana de uso",
    "o produto sem defeito foi elogiado pelo cliente no final da ligacao"
  ),
  stringsAsFactors = FALSE
)
corpus_atend <- ac_corpus(atendimento, text = texto, docid = id)
```

#### 12.1 KWIC: ver cada ocorrência em contexto

**KWIC** (*keyword-in-context*, Sinclair, 1991) lista cada ocorrência de
um termo com o texto imediatamente antes e depois dele. É o primeiro
passo de qualquer análise de discurso baseada em corpus (*corpus-based
discourse analysis*): antes de interpretar por que um termo é frequente,
leia como ele é usado em cada caso individual.

``` r

ac_kwic(corpus_atend, pattern = "defeito", window = 4)
#> # A tibble: 3 × 5
#>   doc_id position before                keyword after                    
#>   <chr>     <int> <chr>                 <chr>   <chr>                    
#> 1 call1         9 o produto chegou com  defeito de fabrica               
#> 2 call2         4 outro cliente relatou defeito no produto depois de     
#> 3 call3         4 o produto sem         defeito foi elogiado pelo cliente
```

> **Como interpretar:** leia a coluna `before`, depois `keyword`, depois
> `after`, como uma frase só. No exemplo, “defeito” aparece tanto
> associado a reclamação (“chegou com defeito”) quanto a elogio negado
> (“sem defeito foi elogiado”): uma contagem de frequência trataria as
> três ocorrências como idênticas, mas o contexto mostra que a terceira
> é, na verdade, uma menção à *ausência* do problema.

#### 12.2 Colocações: associação estatística entre palavras

Enquanto o KWIC mostra ocorrências individuais, **colocações**
([`ac_collocations()`](https://andersonheri.github.io/acR/reference/ac_collocations.md))
respondem a uma pergunta agregada: quais bigramas/trigramas aparecem
juntos mais do que o esperado pelo acaso, medido por PMI (Church &
Hanks, 1990), log-likelihood (Dunning, 1993) ou qui-quadrado. Vai além
da frequência bruta de n-gramas: um bigrama pode ser raro e ainda assim
estatisticamente muito associado.

``` r

ac_collocations(corpus_atend, n = 2, measure = "pmi", min_count = 1)
#> # A tibble: 31 × 3
#>    collocation      count association
#>    <chr>            <int>       <dbl>
#>  1 chegou com           1        5.13
#>  2 da ligacao           1        5.13
#>  3 elogiado pelo        1        5.13
#>  4 final da             1        5.13
#>  5 foi elogiado         1        5.13
#>  6 reclamou que         1        5.13
#>  7 uma semana           1        5.13
#>  8 no final             1        4.13
#>  9 cliente reclamou     1        3.54
#> 10 cliente relatou      1        3.54
#> # ℹ 21 more rows
```

> **Como interpretar:** PMI mede o quanto duas palavras aparecem juntas
> *além* do esperado pelo acaso, dadas suas frequências individuais.
> Valores mais altos indicam associação mais forte; PMI próximo de zero
> indica que as palavras aparecem juntas tanto quanto o esperado só pela
> frequência de cada uma. Com corpora pequenos (poucos documentos), PMI
> tende a inflar colocações raras: sempre acompanhe `measure = "pmi"` da
> coluna `count`, e desconsidere pares com contagem muito baixa.

Para visualizar as colocações mais fortes em vez de ler a tabela, um
gráfico de barras ordenado funciona bem com poucos pares:

``` r

colocacoes <- ac_collocations(corpus_atend, n = 2, measure = "pmi", min_count = 1)
colocacoes_top <- utils::head(colocacoes, 8)

ggplot2::ggplot(colocacoes_top,
                ggplot2::aes(x = association, y = reorder(collocation, association))) +
  ggplot2::geom_col(fill = ac_palette(1)) +
  ggplot2::labs(
    title = "Colocações mais associadas (PMI)",
    x = "PMI", y = NULL
  ) +
  theme_ac()
```

![](quantitativo_files/figure-html/collocations-plot-1.png)

### 13. Análise temporal/diacrônica

Quando o corpus tem datas, perguntas que antes eram estáticas (quanto um
termo aparece?) passam a ter uma dimensão temporal (quando ele aparece
mais?). É essencial para cobertura jornalística, séries de atendimento
ao cliente, ou qualquer corpus com carimbo de data (Welbers, Van
Atteveldt & Benoit, 2017).

[`ac_temporal()`](https://andersonheri.github.io/acR/reference/ac_temporal.md)
é deliberadamente genérica: a coluna numérica agregada (`value_col`)
pode ser a saída de qualquer outra função do pacote (score de
[`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md),
índice de
[`ac_readability()`](https://andersonheri.github.io/acR/reference/ac_readability.md),
contagem de um termo de
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)…),
desde que exista uma coluna de data no mesmo `data.frame`. Dois
parâmetros controlam a agregação:

- `unit`: o tamanho da janela de tempo: `"day"`, `"week"`, `"month"`
  (padrão) ou `"year"`.
- `stat`: como agregar os valores dentro de cada janela: `"mean"`
  (padrão), `"sum"` ou `"n"` (conta documentos, ignorando `value_col`).

No exemplo abaixo, `sentimento` já é o score de
[`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md)
pré-calculado para 8 notícias fictícias, cada uma com sua data de
publicação:

``` r

noticias <- data.frame(
  data       = as.Date("2024-01-01") + c(0, 10, 20, 35, 50, 65, 80, 95),
  sentimento = c(0.2, 0.1, -0.1, -0.4, -0.3, 0.0, 0.3, 0.5)
)
serie <- ac_temporal(noticias, date_col = "data", value_col = "sentimento",
                      unit = "month", stat = "mean")
serie
#> # A tibble: 4 × 3
#>   period       value n_docs
#>   <date>       <dbl>  <int>
#> 1 2024-01-01  0.0667      3
#> 2 2024-02-01 -0.35        2
#> 3 2024-03-01  0.15        2
#> 4 2024-04-01  0.5         1
```

> **Como interpretar a tabela:**
> [`ac_temporal()`](https://andersonheri.github.io/acR/reference/ac_temporal.md)
> devolve uma linha por período, com `period` (data de início da
> janela), `value` (a estatística agregada, aqui a média do sentimento)
> e `n_docs` (quantos documentos caíram naquele período). **Sempre olhe
> `n_docs` antes do `value`**: um `value` calculado sobre 1 documento
> (como o período de abril aqui) não é uma “média” de fato, é só aquele
> documento isolado, e deve ser tratado com a mesma cautela que uma
> amostra de n=1.

``` r

ac_plot_temporal(serie, ylab = "Sentimento médio")
#> Warning in simpleLoess(y, x, w, span, degree = degree, parametric = parametric,
#> : span too small.  fewer data values than degrees of freedom.
#> Warning in simpleLoess(y, x, w, span, degree = degree, parametric = parametric,
#> : pseudoinverse used at 19723
#> Warning in simpleLoess(y, x, w, span, degree = degree, parametric = parametric,
#> : neighborhood radius 60.455
#> Warning in simpleLoess(y, x, w, span, degree = degree, parametric = parametric,
#> : reciprocal condition number 0
#> Warning in simpleLoess(y, x, w, span, degree = degree, parametric = parametric,
#> : There are other near singularities as well. 3654.8
```

![](quantitativo_files/figure-html/plot-temporal-1.png)

> **Como interpretar o gráfico:** a linha de tendência (LOESS;
> Cleveland, 1979) suaviza flutuações de curto prazo para destacar a
> direção geral: aqui, queda até o meio do período seguida de
> recuperação. A suavização local precisa de pontos suficientes na
> vizinhança de cada ajuste para estimar a curva com estabilidade; com
> poucos pontos (4 meses, com `n_docs` variando de 1 a 3 por mês neste
> exemplo), o próprio [`loess()`](https://rdrr.io/r/stats/loess.html) já
> avisa sobre instabilidade numérica (“span too small”, “pseudoinverse
> used”) — um sinal de que a linha de tendência está extrapolando mais
> do que suavizando. Nesses casos, prefira olhar os pontos brutos da
> tabela (ou o gráfico de barras logo abaixo) em vez de confiar na
> curva; com séries mais longas e `n_docs` mais estável por período, a
> suavização se torna mais confiável.

Uma visão alternativa, mais direta para comparar poucos períodos entre
si, é o gráfico de barras:

``` r

ggplot2::ggplot(serie, ggplot2::aes(x = period, y = value)) +
  ggplot2::geom_col(fill = ac_palette(1)) +
  ggplot2::geom_hline(yintercept = 0, color = "grey40", linetype = "dashed") +
  ggplot2::labs(
    title = "Sentimento médio por mês",
    subtitle = "Barras tornam mais fácil comparar período a período",
    x = NULL, y = "Sentimento médio"
  ) +
  theme_ac()
```

![](quantitativo_files/figure-html/temporal-bar-1.png)

### 14. Escalonamento Wordscores: posicionar documentos numa escala

Às vezes queremos posicionar documentos num espectro contínuo
(favorável↔︎ desfavorável, satisfeito↔︎insatisfeito) sem codificar
manualmente todos eles. O método Wordscores (Laver, Benoit & Garry,
2003) faz isso em duas etapas, de forma parecida com uma régua calibrada
por exemplos conhecidos:

1.  **Aprender a régua.** Você fornece um pequeno conjunto de documentos
    com posição *já conhecida* (aqui, a nota de 1 a 5 que o cliente deu
    à avaliação). O método observa quais palavras aparecem mais em notas
    altas e quais aparecem mais em notas baixas, construindo um “escore”
    implícito para cada palavra do vocabulário.
2.  **Aplicar a régua.** Para cada documento **sem** nota conhecida (os
    “virgens”), o método olha o vocabulário usado e calcula uma média
    ponderada dos escores de palavra aprendidos na etapa 1 — produzindo
    uma posição estimada no mesmo espectro, sem nunca ter visto uma nota
    para aquele texto.

O exemplo abaixo usa sete avaliações de produto com nota conhecida (de 1
a 5, incluindo duas em cada extremo para dar ao método mais vocabulário
de referência) e duas avaliações **sem nota**, uma claramente
entusiasmada e outra deliberadamente mediana, para ver se o método
recupera essa diferença só pelo texto.

``` r

resenhas <- data.frame(
  id = paste0("r", 1:9),
  texto = c(
    # Referencia: nota 5
    "produto excelente, superou todas as expectativas, qualidade impecavel, recomendo muito a todos",
    "amei esse produto, chegou rapido, funciona perfeitamente, melhor compra que fiz esse ano",
    # Referencia: nota 4
    "muito bom, chegou no prazo e funciona bem, pequenos detalhes a melhorar mas vale a pena",
    # Referencia: nota 3
    "produto regular, cumpre o basico, nada de especial mas tambem nao decepciona",
    # Referencia: nota 2
    "nao funcionou muito bem, qualidade deixou a desejar, esperava mais pelo preco pago",
    # Referencia: nota 1
    "pessimo, quebrado na caixa, com defeito serio, decepcao total com essa compra",
    "produto horrivel, nao recomendo a ninguem, dinheiro jogado fora, qualidade pessima",
    # "Virgens": sem nota, a estimar so pelo vocabulario
    "simplesmente perfeito, superou expectativas, qualidade impecavel, recomendo de olhos fechados",
    "produto ok, atende o basico, nem bom nem ruim, mediano"
  ),
  stringsAsFactors = FALSE
)
corpus_resenhas <- ac_corpus(resenhas, text = texto, docid = id)

# r1, r2, r3, r4, r5, r6, r7 tem nota conhecida; r8 e r9 sao "virgens"
notas <- c(r1 = 5, r2 = 5, r3 = 4, r4 = 3, r5 = 2, r6 = 1, r7 = 1)
wordscores <- ac_wordscores(corpus_resenhas, notas, rescale = "lbg")
wordscores
#> # A tibble: 9 × 4
#>   doc_id score score_raw is_reference
#>   <chr>  <dbl>     <dbl> <lgl>       
#> 1 r1     4.55       4.19 TRUE        
#> 2 r2     5.31       4.77 TRUE        
#> 3 r3     4.08       3.83 TRUE        
#> 4 r4     2.93       2.94 TRUE        
#> 5 r5     2.12       2.33 TRUE        
#> 6 r6     0.599      1.16 TRUE        
#> 7 r7     1.40       1.78 TRUE        
#> 8 r8     4.21       3.92 FALSE       
#> 9 r9     2.97       2.98 FALSE
```

``` r

ac_plot_wordscores(wordscores)
```

![](quantitativo_files/figure-html/wordscores-plot-1.png)

> **Como interpretar:** cada ponto é um documento, ordenado pelo `score`
> estimado; a cor diferencia referência (nota conhecida) de estimado
> (virgem). A escala é relativa, não absoluta: um escore de 4.2 só tem
> sentido comparado aos escores de referência (aqui, de 1 a 5), não como
> nota objetiva. O teste de sanidade do método está nos dois pontos
> cinzas: `r8` (texto claramente entusiasmado: “simplesmente perfeito”)
> foi estimado perto de `r1`/`r3`, na faixa alta da escala; `r9` (texto
> deliberadamente mediano: “nem bom nem ruim”) foi estimado bem perto de
> `r4`, a referência de nota 3. O método nunca viu uma nota para `r8` ou
> `r9`: a posição vem inteiramente do vocabulário aprendido com as
> referências. Quando um documento estimado fica muito perto de uma
> única referência, ele compartilha bastante vocabulário com ela; no
> meio da escala, o resultado costuma ser ambiguidade real do texto, não
> erro do método.

Uma visão complementar, útil para apresentar a escala completa num
relatório, é ordenar os documentos num eixo horizontal:

``` r

wordscores$doc_id <- factor(wordscores$doc_id, levels = wordscores$doc_id[order(wordscores$score)])

ggplot2::ggplot(wordscores, ggplot2::aes(x = score, y = doc_id, fill = is_reference)) +
  ggplot2::geom_col() +
  ggplot2::scale_fill_manual(
    values = c(`TRUE` = "#1b7837", `FALSE` = "#737373"),
    labels = c(`TRUE` = "Referência", `FALSE` = "Estimado"),
    name = NULL
  ) +
  ggplot2::labs(title = "Escores Wordscores (barras)", x = "Escore", y = NULL) +
  theme_ac()
```

![](quantitativo_files/figure-html/wordscores-bar-1.png)

> **Como interpretar:** o conteúdo é o mesmo do gráfico de pontos acima
> — a diferença é só de leitura. Barras horizontais facilitam comparar
> **o tamanho relativo** entre documentos vizinhos na escala (a barra de
> `r8` é visivelmente maior que a de `r3`, por exemplo), o que fica mais
> difícil de perceber a olho nu num gráfico de pontos. Use a versão de
> pontos para explorar os dados durante a análise, e esta versão de
> barras quando for apresentar o ranking completo num relatório ou
> slide, onde o comprimento da barra comunica a posição mais diretamente
> que a posição de um ponto isolado.

### 15. Dicionários multi-categoria, emoções e validação

Nem toda análise baseada em dicionário é positivo/negativo.
[`ac_dictionary()`](https://andersonheri.github.io/acR/reference/ac_dictionary.md)
generaliza a lógica de
[`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md)
para **qualquer** conjunto de categorias (temas, enquadramentos,
emoções), no espírito do General Inquirer (Stone et al., 1966) e de
“Text as Data” (Grimmer & Stewart, 2013): você define as categorias e as
palavras de cada uma, e o pacote conta. Esta seção tem três partes: o
dicionário em si (15.1), uma camada especializada para emoções (15.2), e
a validação contra codificação humana que toda análise de dicionário
publicável precisa ter (15.3).

Corpus de exemplo: seis registros de atendimento cobrindo problemas de
**entrega** e de **produto**, às vezes os dois no mesmo registro.

``` r

atendimento2 <- data.frame(
  id = paste0("call", 1:6),
  texto = c(
    "a entrega atrasou muito e o rastreio nao atualizava ha dias",
    "o produto chegou com defeito e veio quebrado da fabrica",
    "entrega rapida produto excelente superou expectativas",
    "o rastreio mostrava entrega prevista mas o pacote nunca chegou",
    "produto perfeito funciona bem sem nenhum problema",
    "entrega no prazo mas o produto veio com defeito de fabricacao"
  ),
  stringsAsFactors = FALSE
)
corpus_atend2 <- ac_corpus(atendimento2, text = texto, docid = id)
```

#### 15.1 Dicionário multi-categoria

``` r

dict <- ac_build_dictionary(
  entrega = c("entrega", "atrasou", "atrasada", "rapida", "rastreio", "prazo"),
  produto = c("defeito", "quebrado", "perfeito", "excelente")
)
resultado_dict <- ac_dictionary(corpus_atend2, dict)
resultado_dict
#> # A tibble: 6 × 6
#>   doc_id total_tokens entrega_n produto_n entrega_prop produto_prop
#>   <chr>         <int>     <int>     <int>        <dbl>        <dbl>
#> 1 call1            11         3         0        0.273       0     
#> 2 call2            10         0         2        0           0.2   
#> 3 call3             6         2         1        0.333       0.167 
#> 4 call4            10         2         0        0.2         0     
#> 5 call5             7         0         1        0           0.143 
#> 6 call6            11         2         1        0.182       0.0909
```

> **Como interpretar:** a coluna `<categoria>_prop` é a proporção de
> tokens do documento pertencentes àquela categoria, não a proporção de
> sentenças ou de “sentimento”. Um `produto_prop` alto não significa que
> o documento fala *bem* ou *mal* do produto, só que usa vocabulário da
> categoria “produto” com frequência: dicionários contam palavras, não
> interpretam contexto, negação ou ironia (por isso a validação em 15.3
> é indispensável). Documentos podem pontuar em mais de uma categoria ao
> mesmo tempo (`call3` e `call6` têm tokens de `entrega` **e**
> `produto`): as categorias não são mutuamente exclusivas por padrão.

Para visualizar a composição temática de vários documentos de uma vez,
um gráfico de barras empilhadas às proporções funciona melhor que a
tabela:

``` r

long_dict <- data.frame(
  doc_id   = rep(resultado_dict$doc_id, 2),
  categoria = rep(c("entrega", "produto"), each = nrow(resultado_dict)),
  prop      = c(resultado_dict$entrega_prop, resultado_dict$produto_prop)
)

ggplot2::ggplot(long_dict, ggplot2::aes(x = doc_id, y = prop, fill = categoria)) +
  ggplot2::geom_col(position = "stack") +
  ggplot2::scale_fill_manual(values = ac_palette(2)) +
  ggplot2::labs(
    title = "Composição temática por documento",
    x = NULL, y = "Proporção de tokens", fill = "Categoria"
  ) +
  theme_ac()
```

![](quantitativo_files/figure-html/dictionary-plot-1.png)

> **Como interpretar:** a altura total da barra é a proporção de tokens
> do documento capturada por **qualquer** categoria do dicionário; o
> restante (até completar 100%) é vocabulário fora do dicionário —
> normal e esperado, já que a maior parte de qualquer texto é gramática
> e palavras funcionais, não vocabulário temático. Barras com as duas
> cores empilhadas (`call3`, `call6`) são documentos que mencionam
> entrega e produto na mesma frase; barras de uma cor só, documentos
> focados num único problema.

#### 15.2 Léxico de emoções

[`ac_emotion()`](https://andersonheri.github.io/acR/reference/ac_emotion.md)
é uma camada especializada do mesmo mecanismo para léxicos de emoção
(inspirada no NRC Emotion Lexicon; Mohammad & Turney, 2013), indo além
de só positivo/negativo:

``` r

lexico_emocao <- data.frame(
  termo  = c("excelente", "perfeito", "defeito", "quebrado", "atrasou"),
  emocao = c("alegria",   "alegria",  "tristeza", "raiva",   "raiva"),
  stringsAsFactors = FALSE
)
ac_emotion(corpus_atend2, lexicon = lexico_emocao)
#> # A tibble: 6 × 8
#>   doc_id total_tokens alegria_n raiva_n tristeza_n alegria_prop raiva_prop
#>   <chr>         <int>     <int>   <int>      <int>        <dbl>      <dbl>
#> 1 call1            11         0       1          0        0         0.0909
#> 2 call2            10         0       1          1        0         0.1   
#> 3 call3             6         1       0          0        0.167     0     
#> 4 call4            10         0       0          0        0         0     
#> 5 call5             7         1       0          0        0.143     0     
#> 6 call6            11         0       0          1        0         0     
#> # ℹ 1 more variable: tristeza_prop <dbl>
```

> **Como interpretar:** mecanicamente é a mesma lógica da seção 15.1
> (conta palavras por categoria), só que as categorias são emoções em
> vez de temas — por isso o mesmo cuidado se aplica: a função conta
> vocabulário associado à emoção, não detecta a emoção real do autor.
> Note que `call1` (“atrasou”) pontua em `raiva`, não em `tristeza`,
> porque foi essa a emoção atribuída a “atrasou” no léxico de exemplo: a
> qualidade do resultado depende inteiramente de que léxico você usa. O
> pacote não distribui um léxico de emoções pronto (por isso o exemplo
> define um na mão); para português, procure léxicos adaptados do NRC ou
> construa o seu com
> [`ac_build_dictionary()`](https://andersonheri.github.io/acR/reference/ac_build_dictionary.md)
> a partir de categorias validadas na literatura da sua área.

#### 15.3 Validação contra codificação humana

Nenhum dicionário deveria ser usado numa análise publicável sem comparar
sua classificação a uma amostra codificada por humano: é a mesma lógica
de
[`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
(para codificação por LLM), aplicada aqui ao método de dicionário. Para
ilustrar os dois tipos de erro que a validação revela, o `humano` abaixo
discorda do dicionário em um ponto: em `call1` (“a entrega atrasou
muito…”), o revisor humano leu o registro como uma reclamação sobre o
*produto* em geral, não especificamente sobre a entrega — uma
divergência plausível entre dicionário e leitor humano, que ao mesmo
tempo produz um falso positivo para “entrega” (o dicionário marcou, o
humano não) e um falso negativo para “produto” (o humano marcou, o
dicionário não).

``` r

humano <- tibble::tibble(
  doc_id    = resultado_dict$doc_id,
  categoria = c("produto", "produto", "entrega|produto", "entrega", "produto", "entrega|produto")
)
ac_dictionary_validate(resultado_dict, humano)
#> # A tibble: 2 × 12
#>   categoria     n    vp    fp    fn    vn concordancia precisao recall    f1
#>   <chr>     <int> <int> <int> <int> <int>        <dbl>    <dbl>  <dbl> <dbl>
#> 1 entrega       6     3     1     0     2        0.833     0.75    1   0.857
#> 2 produto       6     4     0     1     1        0.833     1       0.8 0.889
#> # ℹ 2 more variables: gwet_ac1 <dbl>, krippendorff_alfa <dbl>
```

> **Como interpretar:** leia `precisao` e `recall` por categoria, não só
> uma `concordancia` geral. No exemplo, `entrega` tem **precisão** menor
> (0.75): o dicionário marcou `call1` como “entrega”, mas o humano
> discordou — um falso positivo. `produto` tem **recall** menor (0.8): o
> humano marcou um caso como “produto” que o dicionário não capturou —
> um falso negativo. Essa é a diferença prática entre os dois erros:
> precisão baixa é o dicionário marcando demais (alarme falso); recall
> baixo é o dicionário deixando passar (caso perdido), e qual dos dois
> importa mais depende do uso: numa triagem para revisão humana, recall
> alto é mais importante (não quer perder casos); num relatório
> automático sem revisão, precisão alta é mais importante (não quer
> alarmes falsos). Krippendorff (2018) considera `krippendorff_alfa`
> acima de 0.80 adequado para publicação sem reservas, e entre 0.67 e
> 0.80 aceitável com discussão dos casos divergentes no texto.

### 16. Análise de correspondência (CA): um mapa de grupos e termos

Quando queremos visualizar em 2D como o vocabulário difere entre grupos,
sem assumir um número de tópicos latentes (como em
[`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md)), a
Análise de Correspondência (Greenacre, 2007) posiciona grupos e termos
no mesmo espaço geométrico. A lógica geométrica é simples: pontos
próximos tendem a co-ocorrer mais do que o esperado pelo acaso, e a
distância até a origem indica quão distintivo (vs. genérico) é um termo
ou grupo.

``` r

categorias <- data.frame(
  id = paste0("d", 1:6),
  texto = c(
    "entrega atrasada rastreio sumiu",
    "pedido atrasou rastreio sumiu",
    "produto defeito quebrado chegou",
    "veio quebrado produto péssimo",
    "atendimento excelente resolveram rápido",
    "suporte educado resolveu rápido"
  ),
  categoria = c("entrega", "entrega", "produto", "produto",
                "atendimento", "atendimento"),
  stringsAsFactors = FALSE
)
corpus_cat <- ac_corpus(categorias, text = texto, docid = id, meta = categoria)
ca <- ac_ca(corpus_cat, by = "categoria", min_count = 1)
ac_plot_ca(ca)
```

![](quantitativo_files/figure-html/ca-1.png)

> **Como interpretar:** os pontos verdes são grupos (aqui, categorias de
> atendimento); os triângulos roxos são termos. Um termo próximo de um
> grupo é característico dele; um termo perto da origem (o cruzamento
> dos eixos) é genérico, usado de forma parecida por todos os grupos. As
> porcentagens nos títulos dos eixos (`Dim 1`, `Dim 2`) indicam quanto
> da variação total cada dimensão explica: se a Dim 1 já explica a maior
> parte, o mapa 2D captura bem a estrutura; se as duas dimensões
> dividirem a variação de forma mais equilibrada, interpretar só a Dim 1
> perde informação relevante.

Quando o mapa fica poluído de termos, uma alternativa é olhar só as
coordenadas dos grupos, sem os termos: útil quando a pergunta é apenas
“quão diferentes os grupos são entre si”:

``` r

ggplot2::ggplot(ca$row_coords, ggplot2::aes(x = dim1, y = dim2, label = unit)) +
  ggplot2::geom_hline(yintercept = 0, color = "grey80") +
  ggplot2::geom_vline(xintercept = 0, color = "grey80") +
  ggplot2::geom_point(color = ac_palette(1), size = 4) +
  ggplot2::geom_text(vjust = -1, fontface = "bold") +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = 0.25)) +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = 0.25)) +
  ggplot2::labs(
    title = "Análise de correspondência: só grupos",
    subtitle = "Distância entre pontos reflete dissimilaridade de vocabulário"
  ) +
  theme_ac()
```

![](quantitativo_files/figure-html/ca-groups-only-1.png)

## Referências

- Church, K. W.; Hanks, P. (1990). Word Association Norms, Mutual
  Information, and Lexicography. *Computational Linguistics*, 16(1),
  22-29.
- Cleveland, W. S. (1979). Robust Locally Weighted Regression and
  Smoothing Scatterplots. *Journal of the American Statistical
  Association*, 74(368), 829-836.
- Dunning, T. (1993). Accurate Methods for the Statistics of Surprise
  and Coincidence. *Computational Linguistics*, 19(1), 61-74.
- Flesch, R. (1948). A New Readability Yardstick. *Journal of Applied
  Psychology*, 32(3), 221-233.
- Greenacre, M. (2007). *Correspondence Analysis in Practice* (2nd ed.).
  Chapman and Hall/CRC.
- Grimmer, J.; Stewart, B. M. (2013). Text as Data: The Promise and
  Pitfalls of Automatic Content Analysis Methods for Political Texts.
  *Political Analysis*, 21(3), 267-297.
- Herdan, G. (1960). *Type-Token Mathematics*. Mouton.
- Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
  Methodology*. 4. ed. SAGE.
- Laver, M.; Benoit, K.; Garry, J. (2003). Extracting Policy Positions
  from Political Texts Using Words as Data. *American Political Science
  Review*, 97(2), 311-331.
- Martin, L. W.; Vanberg, G. (2007). A Robust Transformation Procedure
  for Interpreting Political Text. *Political Analysis*, 16(1), 93-100.
- Martins, T. B. F. et al. (1996). Readability formulas applied to
  textbooks in Brazilian Portuguese. *Memorandum*, 28.
- McCarthy, P. M.; Jarvis, S. (2010). MTLD, vocd-D, and HD-D: A
  validation study of sophisticated approaches to lexical diversity
  assessment. *Behavior Research Methods*, 42(2), 381-392.
- Mohammad, S. M.; Turney, P. D. (2013). Crowdsourcing a Word-Emotion
  Association Lexicon. *Computational Intelligence*, 29(3), 436-465.
- Sampaio, R. C.; Lycarião, D. (2021). *Análise de conteúdo categorial:
  manual de aplicação*. ENAP.
- Silge, J.; Robinson, D. (2017). *Text Mining with R*. O’Reilly.
- Sinclair, J. (1991). *Corpus, Concordance, Collocation*. Oxford
  University Press.
- Stone, P. J. et al. (1966). *The General Inquirer: A Computer Approach
  to Content Analysis*. MIT Press.
- Welbers, K.; Van Atteveldt, W.; Benoit, K. (2017). Text Analysis in R.
  *Communication Methods and Measures*, 11(4), 245-265.
- Zipf, G. K. (1949). *Human Behavior and the Principle of Least
  Effort*. Addison-Wesley.
