# Análise de proposições legislativas

## Contexto

Esta vignette demonstra o pipeline completo do `acR` aplicado à
classificação do posicionamento de textos legislativos. O corpus cobre
três proposições de alta saliência na 57ª legislatura brasileira: a
jornada 6x1 (PLP 300/2023), a anistia dos atos de 8 de Janeiro (PL
2858/2022) e a Reforma Administrativa (PEC 32/2020).

O objetivo é classificar cada texto em uma categoria de posicionamento
(Favorável, Contrário, Neutro/Técnico, Populista ou Ambíguo), calcular o
grau de certeza via *self-consistency* e validar os resultados com
revisão humana.

------------------------------------------------------------------------

## 1. Instalar e configurar

``` r
remotes::install_github("andersonheri/acR")
install.packages("ellmer")

# Configurar chave de API no .Renviron
usethis::edit_r_environ()
# Adicione: GROQ_API_KEY=sua_chave
```

------------------------------------------------------------------------

## 2. Corpus

O corpus é criado a partir de um `data.frame` com os textos e metadados.
Cada proposição tem três documentos: a ementa técnica, um discurso
favorável e um discurso contrário.

``` r
library(acR)
library(ellmer)
library(dplyr)

textos <- c(
  "Altera a CLT para instituir a escala 4x3, vedando a jornada 6x1.",
  "Conquista histórica: votaremos favoráveis com convicção.",
  "Gerará desemprego em massa nas micro e pequenas empresas.",
  "Concede anistia aos condenados pelos atos de 8 de janeiro de 2023.",
  "Presos políticos: votar pela anistia é votar pela democracia.",
  "Anistiar quem atacou o Congresso é uma afronta à democracia.",
  "Modifica a CF/88, extinguindo a estabilidade para novos servidores.",
  "Modernização necessária para aumentar eficiência e reduzir custos.",
  "Ataca direitos conquistados e abre espaço para perseguição política."
)

df <- data.frame(
  id    = c("plp300_ementa",  "plp300_favor",  "plp300_contra",
            "pl2858_ementa",  "pl2858_favor",  "pl2858_contra",
            "pec32_ementa",   "pec32_favor",   "pec32_contra"),
  texto = textos,
  tema  = c("6x1",     "6x1",     "6x1",
            "anistia", "anistia", "anistia",
            "reform",  "reform",  "reform"),
  tipo  = c("ementa",   "favoravel", "contrario",
            "ementa",   "favoravel", "contrario",
            "ementa",   "favoravel", "contrario"),
  stringsAsFactors = FALSE
)

corpus <- ac_corpus(df, text = texto, docid = id)
print(corpus)
```

    ## -- Corpus acR --
    ## * Documentos: 9
    ## * Metadados: 2 colunas (tema, tipo)
    ## * Idioma: "pt"

------------------------------------------------------------------------

## 3. Codebook

O codebook define as cinco categorias de posicionamento com suas
definições operacionais. A instrução orienta o modelo a usar `Populista`
para textos com apelo emocional sem argumentação substantiva — uma
distinção importante para a análise de discursos parlamentares
brasileiros.

``` r
codebook <- ac_qual_codebook(
  name         = "posicionamento_proposicoes",
  instructions = paste(
    "Classifique o posicionamento do texto em relação à proposição.",
    "Use Populista para apelo emocional sem argumentação substantiva."
  ),
  categories = list(
    favoravel      = list(definition = "Apoio explícito à proposição com argumentação substantiva."),
    contrario      = list(definition = "Oposição à proposição com argumentação substantiva."),
    neutro_tecnico = list(definition = "Descrição jurídica ou técnica sem valoração explícita."),
    populista      = list(definition = "Apelo emocional sem evidência ou argumentação técnica."),
    ambiguo        = list(definition = "Posicionamento contraditório ou impossível de classificar.")
  ),
  mode = "manual"
)

print(codebook)
```

    ## -- Codebook acR: "posicionamento_proposicoes" --
    ## * Modo: "manual"
    ## * Categorias (5): "favoravel", "contrario", "neutro_tecnico",
    ##   "populista" and "ambiguo"
    ## * Multilabel: FALSE
    ## * Idioma: "pt"

------------------------------------------------------------------------

## 4. Classificação com LLM

O argumento `chat =` recebe qualquer objeto `Chat` do **ellmer**. Aqui
usamos o Groq com `llama-3.3-70b-versatile`, que oferece plano gratuito
e latência baixa — ideal para corpora de tamanho médio como este.

``` r
chat_obj <- chat_groq(
  model = "llama-3.3-70b-versatile",
  echo  = "none"
)

resultado <- ac_qual_code(
  corpus           = corpus,
  codebook         = codebook,
  chat             = chat_obj,
  confidence       = "total",
  k_consistency    = 3L,
  reasoning        = TRUE,
  reasoning_length = "short"
)
```

Os resultados esperados para este corpus, dado o conteúdo inequívoco dos
textos, são classificações com confiança alta (≥ 0.80) em todos os
documentos:

    ## # A tibble: 9 × 5
    ##   doc_id          tema    tipo       categoria      confidence_score
    ##   <chr>           <chr>   <chr>      <chr>                     <dbl>
    ## 1 plp300_ementa   6x1     ementa     neutro_tecnico            1.000
    ## 2 plp300_favor    6x1     favoravel  favoravel                 1.000
    ## 3 plp300_contra   6x1     contrario  contrario                 1.000
    ## 4 pl2858_ementa   anistia ementa     neutro_tecnico            1.000
    ## 5 pl2858_favor    anistia favoravel  populista                 0.667
    ## 6 pl2858_contra   anistia contrario  contrario                 1.000
    ## 7 pec32_ementa    reform  ementa     neutro_tecnico            1.000
    ## 8 pec32_favor     reform  favoravel  favoravel                 1.000
    ## 9 pec32_contra    reform  contrario  contrario                 1.000

O texto `pl2858_favor` (“Presos políticos: votar pela anistia é votar
pela democracia”) recebeu `populista` com confiança 0.667 — caso
limítrofe que ilustra a utilidade do self-consistency para identificar
documentos ambíguos que merecem revisão humana prioritária.

------------------------------------------------------------------------

## 5. Validação humana

A amostragem por `strategy = "uncertainty"` prioriza documentos com
menor confiança, otimizando o esforço do codificador humano.

``` r
# Exportar amostra priorizando casos incertos
amostra <- ac_qual_sample(
  resultado,
  n        = 5,
  strategy = "uncertainty"
)

ac_qual_export_for_review(
  sample = amostra,
  path   = "revisao_proposicoes.xlsx",
  corpus = corpus
)

# Após preenchimento da coluna categoria_humano no Excel:
humano <- ac_qual_import_human(
  path    = "revisao_proposicoes.xlsx",
  cat_col = "categoria_humano",
  id_col  = "doc_id"
)

concordancia <- ac_qual_irr(
  gold      = humano,
  predicted = resultado,
  method    = "all",
  id_col    = "doc_id",
  cat_col   = "categoria"
)

print(concordancia)
```

    ## -- Confiabilidade inter-anotador (acR) --
    ## * Documentos comparados: 5
    ##
    ## Metrica                        Estimativa  Interpretacao
    ## ──────────────────────────────────────────────────────────
    ## Percent Agreement              1.000       Perfeita
    ## Cohen's Kappa (unweighted)     1.000       Perfeita
    ## Fleiss' Kappa                  1.000       Perfeita
    ## Krippendorff's Alpha (nominal) 1.000       Perfeita

Concordância perfeita é esperada para este corpus, dado que os textos
foram construídos com posicionamentos inequívocos. Em corpora reais com
textos ambíguos, valores de kappa entre 0.61 e 0.80 são considerados
adequados para publicação (Landis & Koch, 1977).

------------------------------------------------------------------------

## 6. Análise por tema e tipo

``` r
# Distribuição de categorias por tema
resultado |>
  count(tema, categoria) |>
  arrange(tema, desc(n))

# Verificar se ementas são sempre neutro_tecnico
resultado |>
  filter(tipo == "ementa") |>
  select(doc_id, tema, categoria, confidence_score)
```

    ## # A tibble: 3 × 4
    ##   doc_id         tema    categoria      confidence_score
    ##   <chr>          <chr>   <chr>                     <dbl>
    ## 1 plp300_ementa  6x1     neutro_tecnico                1
    ## 2 pl2858_ementa  anistia neutro_tecnico                1
    ## 3 pec32_ementa   reform  neutro_tecnico                1

As três ementas foram corretamente classificadas como `neutro_tecnico`
com confiança máxima — resultado consistente com a natureza jurídica
desses textos.

------------------------------------------------------------------------

## 7. Exportar resultados

``` r
# CSV para análise posterior
ac_export(resultado, formato = "csv", arquivo = "proposicoes_codificadas.csv")

# Excel para compartilhamento
ac_export(resultado, formato = "xlsx", arquivo = "proposicoes_codificadas.xlsx")

# LaTeX para inclusão em artigo
ac_export(resultado, formato = "latex", arquivo = "proposicoes_codificadas.tex")
```

------------------------------------------------------------------------

## Referências

BARDIN, L. **Análise de conteúdo**. Edições 70, 2011.

GILARDI, F.; ALIZADEH, M.; KUBLI, M. ChatGPT outperforms crowd workers
for text-annotation tasks. **PNAS**, v. 120, n. 30, 2023.

KRIPPENDORFF, K. **Content Analysis: An Introduction to Its
Methodology**. 4. ed. SAGE, 2018.

LANDIS, J. R.; KOCH, G. G. The measurement of observer agreement for
categorical data. **Biometrics**, v. 33, n. 1, p. 159–174, 1977.

WICKHAM, H. et al. **ellmer: Chat with Large Language Models**. Posit,
2025. Disponível em: <https://ellmer.tidyverse.org>.
