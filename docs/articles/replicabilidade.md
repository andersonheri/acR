# Replicabilidade ponta-a-ponta — do codebook ao relatório de método

Esta vignette demonstra o pipeline **completo** de análise de conteúdo
qualitativa assistida por LLM, com foco na **replicabilidade**: cada
decisão metodológica é documentada de forma que outro pesquisador possa
reproduzir a análise apenas com o codebook em YAML e o relatório gerado
por
[`ac_qual_report()`](https://andersonheri.github.io/acR/reference/ac_qual_report.md).

A demonstração usa dados sintéticos
([`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)
requer chave de LLM paga); a estrutura, formatos e sequência são
idênticos a uma rodada real.

## O pipeline em 6 etapas

1.  **Coleta** — corpus real ou fabricado
2.  **Codebook** — instrumento analítico (`ac_qual_codebook`)
3.  **Classificação** — LLM com `live view` (`ac_qual_code(live = ...)`)
4.  **Amostragem para revisão** —
    [`ac_qual_sample()`](https://andersonheri.github.io/acR/reference/ac_qual_sample.md)
5.  **Confiabilidade inter-codificador** —
    [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
6.  **Relatório de método** —
    [`ac_qual_report()`](https://andersonheri.github.io/acR/reference/ac_qual_report.md)

## 1. Corpus

Corpus fabricado de 12 pronunciamentos com posição declarada
(favor/contra/neutro) — em uso real, este data.frame viria de
[`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md),
[`ac_fetch_senado()`](https://andersonheri.github.io/acR/reference/ac_fetch_senado.md)
ou de importação de PDFs.

``` r

df <- data.frame(
  doc_id = paste0("d", sprintf("%02d", 1:12)),
  text = c(
    "Apoio integralmente esta reforma que simplifica o sistema tributario.",
    "Sou favoravel a proposta: reduz distorcoes historicas do setor.",
    "Voto sim com plena adesao: precisamos modernizar a estrutura fiscal.",
    "Aprovo a reforma tributaria, e uma conquista para o desenvolvimento.",
    "Rejeito esta proposta, e um retrocesso para os trabalhadores.",
    "Voto contra: a reforma prejudica os mais pobres e as pequenas empresas.",
    "Sou contrario a essa proposta, ela beneficia apenas grandes corporacoes.",
    "Nao apoio o texto atual, precisa de revisao profunda antes da votacao.",
    "O texto substitutivo altera o artigo 145 da Constituicao Federal.",
    "O relatorio incorporou 47 emendas apresentadas em plenario.",
    "A comissao aprovou o parecer com 15 votos a favor e 8 contra.",
    "O projeto seguira para votacao na proxima sessao ordinaria."
  ),
  partido = c("PT","PSD","PL","MDB","PSOL","PT","PDT","PSOL",
              "MDB","PSDB","PL","MDB"),
  stringsAsFactors = FALSE
)

corpus <- ac_corpus(df)
#> New names:
#> • `doc_id` -> `doc_id...1`
#> • `doc_id` -> `doc_id...3`
corpus
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 12
#> • Metadados: 2 colunas
#> • Idioma: "pt"
#> # A tibble: 12 × 4
#>   doc_id...1 text                                             doc_id...3 partido
#>   <chr>      <chr>                                            <chr>      <chr>  
#> 1 doc_1      Apoio integralmente esta reforma que simplifica… d01        PT     
#> 2 doc_2      Sou favoravel a proposta: reduz distorcoes hist… d02        PSD    
#> 3 doc_3      Voto sim com plena adesao: precisamos moderniza… d03        PL     
#> 4 doc_4      Aprovo a reforma tributaria, e uma conquista pa… d04        MDB    
#> 5 doc_5      Rejeito esta proposta, e um retrocesso para os … d05        PSOL   
#> 6 doc_6      Voto contra: a reforma prejudica os mais pobres… d06        PT     
#> # ℹ 6 more rows
```

## 2. Codebook

O codebook é o instrumento central. Aqui usamos três categorias (favor,
contra, neutro/técnico) com definições operacionais e exemplos positivos
e negativos para desambiguar categorias vizinhas.

``` r

cb <- ac_qual_codebook(
  name         = "posicao_reforma_tributaria",
  instructions = paste(
    "Classifique a posicao do parlamentar sobre a reforma tributaria",
    "com base no discurso apresentado."
  ),
  categories = list(
    favor = list(
      definition   = "Apoio explicito a aprovacao da reforma tributaria.",
      examples_pos = c("Sou a favor desta reforma que simplifica o sistema."),
      examples_neg = c("O texto altera o artigo 145 da Constituicao Federal."),
      weight       = 1
    ),
    contra = list(
      definition   = "Oposicao explicita a reforma, com argumentos de rejeicao.",
      examples_pos = c("Voto contra: prejudica os trabalhadores."),
      examples_neg = c("Precisa de ajustes antes da votacao."),
      weight       = 1.2  # categoria com mais dificuldade retorica
    ),
    neutro = list(
      definition   = "Discurso tecnico ou processual, sem posicionamento claro.",
      examples_pos = c("O relatorio incorporou emendas apresentadas."),
      examples_neg = c("Sou totalmente contra esta proposta.")
    )
  ),
  lang = "pt"
)

cb
#> 
#> ── Codebook acR: "posicao_reforma_tributaria" ──────────────────────────────────
#> • Modo: "manual"
#> • Categorias (3): "favor", "contra", and "neutro"
#> • Multilabel: FALSE
#> • Idioma: "pt"
#> • Criado em: 17/07/2026 18:15
#> 
#> Instrução geral:
#> Classifique a posicao do parlamentar sobre a reforma tributaria com base no
#> discurso apresentado.
#> 
#> Categorias:
#> • "favor": Apoio explicito a aprovacao da reforma tributaria.
#> Ex+: Sou a favor desta reforma que simplifica o sistema.
#> • "contra" [peso: 1.2]: Oposicao explicita a reforma, com argumentos de
#> rejeicao.
#> Ex+: Voto contra: prejudica os trabalhadores.
#> • "neutro": Discurso tecnico ou processual, sem posicionamento claro.
#> Ex+: O relatorio incorporou emendas apresentadas.
```

Salvar o codebook em YAML permite versionamento em Git e retomada da
análise em outra sessão:

``` r

arquivo_cb <- tempfile(fileext = ".yaml")
ac_qual_save_codebook(cb, path = arquivo_cb)
#> ✅ Codebook salvo em
#> /var/folders/wr/lsgxp5bj5vd2jgq9ybg24ng00000gn/T//RtmpnISDo4/file1b03715fce23.yaml
cat("Codebook salvo em:", arquivo_cb, "\n")
#> Codebook salvo em: /var/folders/wr/lsgxp5bj5vd2jgq9ybg24ng00000gn/T//RtmpnISDo4/file1b03715fce23.yaml
```

## 3. Classificação com live view

Em uma rodada real, o comando seria:

``` r

library(ellmer)
chat <- chat_anthropic(model = "claude-sonnet-4-5")

resultado <- ac_qual_code(
  corpus        = corpus,
  codebook      = cb,
  chat          = chat,
  k_consistency = 3,           # 3 rodadas de self-consistency
  reasoning     = TRUE,        # pede raciocinio estruturado
  live          = "terminal"   # ver o LLM classificando ao vivo
)
```

Com `live = "terminal"`, cada documento aparece na hora:

    1/12 | =>                    8% | ETA 45s | d01 -> favor  (conf 1.00) "Apoio integralmente..."
    2/12 | ==>                  17% | ETA 40s | d02 -> favor  (conf 1.00) "Sou favoravel a..."
    3/12 | ====>                25% | ETA 35s | d03 -> favor  (conf 0.67) "Voto sim com conviccao..."
    ...

Para esta vignette, simulamos o resultado que o LLM retornaria (formato
idêntico ao real):

``` r

set.seed(42)
resultado <- tibble::tibble(
  doc_id = df$doc_id,
  categoria = c(rep("favor", 4), rep("contra", 4), rep("neutro", 4)),
  confidence_score = c(1.00, 1.00, 0.67, 1.00,
                       1.00, 1.00, 1.00, 0.67,
                       1.00, 1.00, 0.67, 1.00),
  reasoning = c(
    "Apoio explicito com 'apoio integralmente'.",
    "Uso do adjetivo 'favoravel' e 'reduz distorcoes'.",
    "Voto declarado, mas ambivalente entre favor e neutro.",
    "'Aprovo' e 'conquista' marcam adesao.",
    "'Rejeito' e 'retrocesso' marcam oposicao.",
    "'Voto contra' e argumento distributivo.",
    "'Sou contrario' com justificativa.",
    "'Nao apoio' + pede revisao (borderline neutro/contra).",
    "Descreve alteracao normativa sem posicionar.",
    "Descreve processo legislativo.",
    "Numeros do resultado, sem opiniao. Borderline.",
    "Encaminhamento processual."
  )
)
resultado
#> # A tibble: 12 × 4
#>    doc_id categoria confidence_score reasoning                                  
#>    <chr>  <chr>                <dbl> <chr>                                      
#>  1 d01    favor                 1    Apoio explicito com 'apoio integralmente'. 
#>  2 d02    favor                 1    Uso do adjetivo 'favoravel' e 'reduz disto…
#>  3 d03    favor                 0.67 Voto declarado, mas ambivalente entre favo…
#>  4 d04    favor                 1    'Aprovo' e 'conquista' marcam adesao.      
#>  5 d05    contra                1    'Rejeito' e 'retrocesso' marcam oposicao.  
#>  6 d06    contra                1    'Voto contra' e argumento distributivo.    
#>  7 d07    contra                1    'Sou contrario' com justificativa.         
#>  8 d08    contra                0.67 'Nao apoio' + pede revisao (borderline neu…
#>  9 d09    neutro                1    Descreve alteracao normativa sem posiciona…
#> 10 d10    neutro                1    Descreve processo legislativo.             
#> 11 d11    neutro                0.67 Numeros do resultado, sem opiniao. Borderl…
#> 12 d12    neutro                1    Encaminhamento processual.
```

Distribuição dos resultados:

``` r

resultado |>
  dplyr::count(categoria) |>
  dplyr::mutate(pct = round(100 * n / sum(n), 1))
#> # A tibble: 3 × 3
#>   categoria     n   pct
#>   <chr>     <int> <dbl>
#> 1 contra        4  33.3
#> 2 favor         4  33.3
#> 3 neutro        4  33.3
```

Casos com baixa confiança (candidatos prioritários para revisão humana):

``` r

resultado |>
  dplyr::filter(confidence_score < 1.0) |>
  dplyr::select(doc_id, categoria, confidence_score, reasoning)
#> # A tibble: 3 × 4
#>   doc_id categoria confidence_score reasoning                                   
#>   <chr>  <chr>                <dbl> <chr>                                       
#> 1 d03    favor                 0.67 Voto declarado, mas ambivalente entre favor…
#> 2 d08    contra                0.67 'Nao apoio' + pede revisao (borderline neut…
#> 3 d11    neutro                0.67 Numeros do resultado, sem opiniao. Borderli…
```

## 4. Amostra para revisão humana

`ac_qual_sample(strategy = "uncertainty")` prioriza documentos com menor
`confidence_score` — foca o esforço humano onde o LLM mais errou.

``` r

amostra <- ac_qual_sample(
  resultado,
  n        = 4,
  strategy = "uncertainty"
)
#> ℹ Amostra de 4 documentos selecionada (estratégia: "uncertainty").
#> ℹ Use `ac_qual_export_for_review()` para exportar para Excel.
amostra |> dplyr::select(doc_id, categoria, confidence_score, sample_reason)
#> # A tibble: 4 × 4
#>   doc_id categoria confidence_score sample_reason                
#>   <chr>  <chr>                <dbl> <chr>                        
#> 1 d03    favor                 0.67 uncertainty (confidence=0.67)
#> 2 d08    contra                0.67 uncertainty (confidence=0.67)
#> 3 d11    neutro                0.67 uncertainty (confidence=0.67)
#> 4 d01    favor                 1    uncertainty (confidence=1)
```

Em uma rodada real, você exportaria essa amostra para Excel, um
codificador humano preencheria a coluna `categoria_humano`, e o
resultado seria reimportado:

``` r

ac_qual_export_for_review(amostra, path = "revisao.xlsx", corpus = corpus)
# ... revisor humano preenche a coluna categoria_humano no Excel ...
revisado <- ac_qual_import_human("revisao.xlsx")
```

## 5. Confiabilidade inter-codificador

Simulamos a revisão humana (com 1 discordância em 12) e calculamos as
métricas de concordância — no artigo, essas métricas aparecem na seção
de método:

``` r

humano <- tibble::tibble(
  doc_id    = resultado$doc_id,
  categoria = c(rep("favor", 4), rep("contra", 4),
                "neutro","neutro","favor","neutro")  # 1 discordancia
)

irr <- ac_qual_reliability(
  llm       = resultado,
  human     = humano,
  bootstrap = 100L
)
#> Calculando confiabilidade em 12 documentos comuns...
#> Warning in irr::kripp.alpha(mat, method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> Warning in irr::kripp.alpha(rbind(l, h), method = "nominal"): NAs introduced by
#> coercion
#> ℹ Interpretação baseada em Landis & Koch (1977) e Gwet (2014).
#> ℹ IC 95% via bootstrap (n = 100).
irr
#> # A tibble: 4 × 5
#>   metric             estimate ci_lower ci_upper interpretation                  
#>   <chr>                 <dbl>    <dbl>    <dbl> <chr>                           
#> 1 percent_agreement     0.917    0.75         1 excelente (>= 90%)              
#> 2 krippendorff_alpha    0.880    0.584        1 quase perfeita (Landis & Koch, …
#> 3 gwet_ac1              0.875    0.629        1 quase perfeita (Landis & Koch, …
#> 4 f1_macro              0.915    0.625        1 quase perfeita (Landis & Koch, …
```

## 6. Relatório de método — replicabilidade automática

Aqui está o **coração desta vignette**:
[`ac_qual_report()`](https://andersonheri.github.io/acR/reference/ac_qual_report.md)
empacota tudo — codebook, config LLM, distribuição de resultados,
métricas de IRR — em um documento único, pronto para anexar como
material suplementar de um artigo.

``` r

arquivo_md <- tempfile(pattern = "relatorio-", fileext = ".md")

ac_qual_report(
  coded       = resultado,
  codebook    = cb,
  reliability = irr,
  chat        = "anthropic/claude-sonnet-4-5",  # ou objeto Chat
  title       = "Classificacao de posicionamento na reforma tributaria",
  author      = "Silva, A.; Souza, B.",
  method      = "Corpus de 12 pronunciamentos parlamentares (2023-2024).",
  format      = "md",
  path        = arquivo_md,
  lang        = "pt"
)
#> Warning: Unknown or uninitialised column: `metrics`.
#> ✔ Relatorio salvo em
#>   /var/folders/wr/lsgxp5bj5vd2jgq9ybg24ng00000gn/T//RtmpnISDo4/relatorio-1b03129b55ef.md
```

Primeiras 40 linhas do relatório gerado:

``` r

cat(head(readLines(arquivo_md), 40), sep = "\n")
#> # Classificacao de posicionamento na reforma tributaria
#> 
#> - **Gerado em:** 2026-07-17 18:15:40 -03
#> - **Versao do acR:** 0.3.1
#> - **Autor(es):** Silva, A.; Souza, B.
#> - **Metodo:** Corpus de 12 pronunciamentos parlamentares (2023-2024).
#> 
#> ## 1. Visao geral
#> 
#> Este relatorio documenta as decisoes metodologicas da rodada de codificacao qualitativa assistida por LLM, seguindo as recomendacoes de Krippendorff (2018) sobre replicabilidade em analise de conteudo e as boas praticas de Gilardi et al. (2023) para uso de LLMs em anotacao de textos.
#> 
#> ## 2. Codebook
#> 
#> | Nome | posicao_reforma_tributaria |
#> |---|---|
#> | Idioma        | `pt` |
#> | Modo        | `manual` |
#> | Multilabel  | `FALSE` |
#> | Criado em     | 2026-07-17 18:15:38 |
#> 
#> **Instrucoes ao codificador:**
#> 
#> > Classifique a posicao do parlamentar sobre a reforma tributaria com base no discurso apresentado.
#> 
#> ### Categorias
#> 
#> #### `favor`
#> 
#> **Definicao:** Apoio explicito a aprovacao da reforma tributaria.
#> 
#> **Exemplos positivos:**
#> - Sou a favor desta reforma que simplifica o sistema.
#> 
#> **Exemplos negativos:**
#> - O texto altera o artigo 145 da Constituicao Federal.
#> 
#> #### `contra`
#> 
#> **Definicao:** Oposicao explicita a reforma, com argumentos de rejeicao.
```

O relatório completo cobre 8 seções: metadados, codebook completo,
histórico de modificações, configuração da LLM, distribuição de
resultados, confiabilidade (com IC 95%), referências metodológicas e
sugestão de citação.

Para gerar em HTML autocontido (com CSS embutido, pronto para publicação
web):

``` r

ac_qual_report(
  coded       = resultado,
  codebook    = cb,
  reliability = irr,
  format      = "html",
  path        = "apendice_metodo.html",
  lang        = "pt"      # ou "en" para submissao internacional
)
```

## Fluxo completo em 6 linhas

Recapitulando toda a vignette em código executável:

``` r

library(acR); library(ellmer)
corpus    <- ac_corpus(meu_data_frame)
cb        <- ac_qual_codebook(name = "...", instructions = "...", categories = list(...))
resultado <- ac_qual_code(corpus, cb, chat = chat_anthropic("..."), live = "terminal")
amostra   <- ac_qual_sample(resultado, n = 30, strategy = "uncertainty")
# ... revisao humana ...
irr       <- ac_qual_reliability(llm = resultado, human = revisado)
ac_qual_report(resultado, cb, reliability = irr, path = "metodo.md")
```

Seis funções principais, um pipeline reproduzível, um relatório
automático — do texto bruto ao apêndice metodológico do artigo.

## Referências

- Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT outperforms crowd
  workers for text-annotation tasks. *PNAS*, 120(30).
- Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
  Methodology* (4th ed.). SAGE.
- Wang, X. et al. (2022). Self-consistency improves chain-of-thought
  reasoning in language models. *arXiv:2203.11171*.
