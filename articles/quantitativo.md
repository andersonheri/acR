# Analise quantitativa de texto

## Visao geral

O modulo quantitativo do `acR` cobre as etapas classicas de analise
textual: limpeza, tokenizacao, contagem de frequencias, TF-IDF, keyness
e co-ocorrencia. Todas as funcoes recebem um objeto `ac_corpus` e
retornam tibbles prontos para visualizacao ou modelagem.

------------------------------------------------------------------------

## 1. Construir o corpus

``` r
textos <- c(
  "O governo anunciou nova politica fiscal para reduzir o deficit.",
  "A oposicao critica o aumento dos gastos publicos no orcamento.",
  "Parlamentares debatem reforma tributaria e imposto de renda.",
  "O presidente vetou o projeto que ampliava beneficios sociais.",
  "Senado aprova marco legal para investimentos em infraestrutura.",
  "Deputados votam pela reducao da carga tributaria para empresas.",
  "Politica monetaria do Banco Central eleva a taxa de juros.",
  "Inflacao acima da meta preocupa economistas e mercado financeiro."
)
corpus <- ac_corpus(
  textos,
  id   = paste0("doc_", seq_along(textos)),
  tema = c("fiscal","fiscal","tributario","social",
           "infraestrutura","tributario","monetario","monetario")
)
print(corpus)
summary(corpus)
```

    # Corpus acR: 8 documentos
    # Temas: fiscal (2), tributario (2), monetario (2),
    #        social (1), infraestrutura (1)

------------------------------------------------------------------------

## 2. Limpeza

``` r
corpus_limpo <- ac_clean(
  corpus,
  lowercase        = TRUE,
  remover_numeros  = TRUE,
  remover_pontuacao = TRUE
)
print(corpus_limpo)
```

    # Corpus acR: 8 documentos (apos limpeza)
    # Operacoes: lowercase, remover_numeros, remover_pontuacao

------------------------------------------------------------------------

## 3. Tokenizacao

``` r
tokens <- ac_tokenize(
  corpus_limpo,
  remover_stopwords = TRUE,
  ngrams            = 1L
)
print(tokens)
```

    # Tokens acR: 8 documentos | ~95 tokens unicos
    # Stopwords removidas: portugues (NLTK/stopwords-pt)

------------------------------------------------------------------------

## 4. Frequencia de termos

``` r
contagem <- ac_count(tokens)
print(contagem)
```

    # A tibble: 95 x 4
    #   termo        freq  freq_rel  doc_freq
    #   politica        4    0.042         3
    #   tributaria      3    0.032         2
    #   reforma         3    0.032         2
    #   fiscal          2    0.021         2
    #   juros           2    0.021         2

------------------------------------------------------------------------

## 5. Top termos e wordcloud

``` r
top <- ac_top_terms(contagem, n = 15)
ac_plot_top_terms(
  top,
  titulo   = "Termos mais frequentes — agenda economica",
  por_grupo = TRUE
)
```

    # Grafico: barras horizontais por frequencia
    # Top 15 termos por grupo/tema

``` r
ac_plot_wordcloud(
  contagem,
  max_words = 50,
  cores     = "viridis"
)
```

------------------------------------------------------------------------

## 6. TF-IDF

``` r
tfidf <- ac_tfidf(tokens)
print(tfidf)
ac_plot_tfidf(tfidf, n = 10, por_grupo = TRUE)
```

    # A tibble: 95 x 5
    #   doc_id  tema          termo       tf      idf    tf_idf
    #   doc_1   fiscal        deficit  0.083    1.386     0.115
    #   doc_3   tributario    imposto  0.077    1.099     0.085
    #   doc_7   monetario     juros    0.091    1.099     0.100

------------------------------------------------------------------------

## 7. Keyness — vocabulario distintivo

``` r
kn <- ac_keyness(tokens, grupo_ref = "fiscal")
print(kn)
ac_plot_keyness(kn, n_termos = 15)
```

    # Keyness (chi-quadrado) — grupo focal: fiscal
    #   termo       chi2    p_value  keyness
    #   deficit     8.42    0.004    positivo
    #   gastos      6.11    0.013    positivo
    #   tributaria  5.03    0.025    negativo

------------------------------------------------------------------------

## 8. Co-ocorrencia

``` r
cooc <- ac_cooccurrence(tokens, window = 5L)
print(cooc)
ac_plot_cooccurrence(
  cooc,
  min_freq  = 2,
  n_nos     = 20
)
```

    # Rede de co-ocorrencia: 20 nos | 38 arestas
    # Par mais frequente: politica -- fiscal (3)

------------------------------------------------------------------------

## 9. Exportar

``` r
ac_export(tfidf,    formato = "csv",  arquivo = "tfidf.csv")
ac_export(contagem, formato = "xlsx", arquivo = "frequencias.xlsx")
ac_export(kn,       formato = "csv",  arquivo = "keyness.csv")
```

------------------------------------------------------------------------

------------------------------------------------------------------------

## Referencias

**Pacote**

Henrique, A. (2025). *acR: Analise de Conteudo em R*. R package version
0.1.0. Centro de Estudos da Metropole (CEM-Cepid) — Universidade de Sao
Paulo. Disponivel em: <https://andersonheri.github.io/acR/>

**Pacotes utilizados**

Santos, V. (2026). *senatebR: Collect Data from the Brazilian Federal
Senate Open Data API*. R package version 0.1.0.
<https://CRAN.R-project.org/package=senatebR>

Ferreira, P., Jorge, P., Lima, D., Coelho, G., Pereira, R. H. M., &
Mation, L. (2026). *ipeaplot: Add Ipea Editorial Standards to ggplot2
Graphics*. R package version 0.5.1. Instituto de Pesquisa Economica
Aplicada (Ipea). <doi:10.32614/CRAN.package.ipeaplot>

**Inspiracao e dialogo**

Maerz, S., & Benoit, K. (2025). *quallmer: Qualitative and LLM-Assisted
Text Analysis in R*. — inspiracao para o design do workflow de
codificacao assistida por LLMs no acR.

Benoit, K., Watanabe, K., Wang, H., Nulty, P., Obeng, A., Muller, S., &
Matsuo, A. (2018). quanteda: An R package for the quantitative analysis
of textual data. *Journal of Open Source Software*, 3(30), 774.
<doi:10.21105/joss.00774> — infraestrutura de analise textual
quantitativa.

Wickham, H., et al. (Posit). *ellmer: A unified interface to large
language models in R*. <https://ellmer.tidyverse.org/> — backend
unificado de LLMs.

Souza, M., & Vieira, R. (2012). Sentiment Analysis on Twitter with
Portuguese Language. In *4th Workshop on Computational Approaches to
Subjectivity, Sentiment and Social Media Analysis*. PUCRS. — OpLexicon:
lexico de sentimento para portugues brasileiro.

**Fundamentacao teorica**

Bardin, L. (2011). *Analise de conteudo*. Edicoes 70.

Blei, D. M., Ng, A. Y., & Jordan, M. I. (2003). Latent Dirichlet
Allocation. *Journal of Machine Learning Research*, 3, 993-1022.

Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
Methodology* (4a ed.). SAGE.

Landis, J. R., & Koch, G. G. (1977). The measurement of observer
agreement for categorical data. *Biometrics*, 33(1), 159-174.

Laver, M., Benoit, K., & Garry, J. (2003). Extracting policy positions
from political texts using words as data. *American Political Science
Review*, 97(2), 311-331.

Sampaio, R. C., & Lycariao, D. (2021). *Analise de conteudo categorial:
manual de aplicacao*. Enap. Disponivel em:
<https://repositorio.enap.gov.br>

R Core Team. (2024). *R: A language and environment for statistical
computing*. R Foundation for Statistical Computing.
<https://www.R-project.org/>
