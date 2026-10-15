# Modelagem de tópicos com LDA

## O que é LDA e para que serve

**Latent Dirichlet Allocation** (Blei, Ng & Jordan, 2003) é um modelo
probabilístico não-supervisionado que descobre *tópicos* em um corpus.
Um “tópico” é uma **distribuição de palavras**: por exemplo, um tópico
sobre saúde tende a ter alta probabilidade para “hospital”, “médico”,
“SUS”, “paciente”. Um documento é modelado como **mistura de tópicos**
com pesos diferentes.

Duas matrizes de saída são o coração do modelo:

- **beta (β)**: probabilidade de cada termo em cada tópico. Responde:
  *“que palavras definem este tópico?”*.
- **gamma (γ)**: probabilidade de cada tópico em cada documento.
  Responde: *“que temas dominam este documento?”*.

> **Quando usar LDA?** Quando você tem um corpus grande demais para ler
> tudo, quer identificar temas emergentes sem definir categorias a
> priori, e as unidades são documentos longos o suficiente para ter
> mistura temática (não frases isoladas). É comum em análise de discurso
> parlamentar, notícias, revisões de literatura, feedback de clientes.

### LDA vs. clustering vs. LLM

Três técnicas resolvem problemas parecidos e são confundidas. A
distinção importa mais que a sintaxe:

| Técnica | Saída | Você fornece |
|----|----|----|
| **LDA** (esta vignette) | Mistura probabilística de tópicos | Só o corpus + `k` |
| **Hard clustering** ([`vignette("cluster")`](https://ahenriquecp.com/acR/articles/cluster.md)) | Uma etiqueta por documento | Só o corpus + `k` |
| **LLM** ([`vignette("qualitativo-llm")`](https://ahenriquecp.com/acR/articles/qualitativo-llm.md)) | Categoria pré-definida | Codebook com categorias |

Regra prática: use **LDA** quando temas se **misturam** dentro do mesmo
texto (discurso parlamentar, notícia, artigo científico); **clustering**
quando você quer uma partição limpa para amostrar; **LLM** quando as
categorias vêm da teoria e não da distribuição empírica de palavras.

O `acR` empacota o pipeline em três chamadas:
[`ac_lda_tune()`](https://ahenriquecp.com/acR/reference/ac_lda_tune.md)
para escolher **K** (número de tópicos),
[`ac_lda()`](https://ahenriquecp.com/acR/reference/ac_lda.md) para
ajustar o modelo,
[`ac_plot_lda_topics()`](https://ahenriquecp.com/acR/reference/ac_plot_lda_topics.md)
para visualizar. Todo o restante é `dplyr` puro.

## 1. Corpus: agenda legislativa

LDA precisa de **corpus suficiente**. Aqui usamos 32 documentos cobrindo
quatro temas: reforma tributária, IA e proteção de dados, habitação, e
educação. Cada tema tem 8 documentos com vocabulário parcialmente
sobreposto (para o modelo ter algo interessante para desemaranhar).

Cada documento é um parágrafo de três frases (cerca de 20 palavras
depois da limpeza), não uma frase solta. Isso importa: o LDA aprende os
tópicos a partir de palavras que **co-ocorrem no mesmo documento**, e
textos muito curtos dão poucas co-ocorrências. Hong & Davison (2010) e
Yan et al. (2013) documentam que o LDA padrão perde qualidade em textos
curtos como tweets; numa versão anterior desta vignette, com frases de
~7 palavras, os tópicos recuperavam os temas pouco melhor que o acaso.
Se seu corpus é de textos curtos, agregue-os (por autor, por sessão, por
dia) ou use modelos próprios para isso.

``` r

textos <- c(
  # Tema 1: reforma tributária (8 documentos)
  "A reforma tributária simplifica o sistema de impostos e reduz a carga fiscal para empresas. O governo federal estima ganho de arrecadacao com menos sonegacao. Tributaristas pedem cautela na transicao entre os dois sistemas de impostos.",
  "O IVA dual substitui PIS, COFINS e ICMS no novo modelo de arrecadacao federal. Estados e municipios temem perder receita com o fim do ICMS. A transicao do imposto sobre consumo levara anos de ajuste fiscal.",
  "Deputados debatem aliquotas e excecoes tributárias para setores economicos. Cada setor pede tratamento diferenciado no novo imposto. O relator da reforma tributária resiste a ampliar as excecoes fiscais.",
  "A reforma tributária unifica impostos indiretos e simplifica obrigacoes das empresas. Contadores esperam menos custo para apurar tributos. A cobranca do imposto no destino muda a disputa fiscal entre estados.",
  "Empresários criticam a alta carga tributária brasileira sobre o consumo popular. O peso dos impostos indiretos recai sobre os mais pobres. A proposta de cashback devolve parte do tributo as familias de baixa renda.",
  "O relator propoe aliquotas diferenciadas para produtos essenciais no novo IVA. A cesta básica tera aliquota zero de imposto. Economistas calculam o efeito das excecoes sobre a aliquota padrao do tributo.",
  "A reforma tributária promete reduzir litigios fiscais e aumentar a arrecadacao. O contencioso tributário bilionario trava empresas e governo. Regras simples de imposto diminuem disputas judiciais sobre tributos.",
  "Congresso avalia impacto da reforma tributária sobre pequenas empresas e servicos. O Simples Nacional sera mantido com ajustes de aliquota. O setor de servicos teme aumento da carga de impostos sobre a folha.",
  # Tema 2: IA e proteção de dados (8 documentos)
  "O marco legal da inteligência artificial regulamenta o uso de algoritmos e dados. O projeto classifica sistemas de IA por nivel de risco. Algoritmos de alto risco exigirao avaliação de impacto antes do uso.",
  "Privacidade e seguranca de dados pessoais sao prioridades da nova lei de IA. Vazamentos de dados expõem milhoes de usuarios. A lei preve multas para empresas que tratarem dados pessoais sem consentimento.",
  "Algoritmos de inteligência artificial precisam de transparência e auditoria pública. Decisoes automatizadas devem ser explicaveis ao cidadao. Auditores independentes poderao inspecionar o codigo e os dados de treinamento.",
  "A LGPD estabelece regras para tratamento de dados pessoais por empresas e governo. O titular pode pedir acesso e exclusao dos seus dados. Empresas precisam nomear um encarregado de protecao de dados pessoais.",
  "Modelos de IA generativa levantam questoes eticas sobre direitos autorais e dados. Artistas reclamam do uso de obras no treinamento de algoritmos. O projeto de lei de IA preve remuneracao por dados protegidos.",
  "A ANPD fiscaliza o cumprimento das regras de protecao de dados no Brasil. A autoridade aplicou as primeiras sancoes por vazamento de dados pessoais. Plataformas digitais devem relatar incidentes de seguranca em prazo curto.",
  "Especialistas defendem regulamentacao de algoritmos preditivos usados por bancos. Sistemas de credito com inteligência artificial podem discriminar clientes. A transparência dos algoritmos permite contestar decisoes automatizadas.",
  "Inteligência artificial na saude requer protocolos de seguranca e privacidade. Algoritmos de diagnostico usam dados pessoais sensiveis de pacientes. Hospitais precisam de consentimento para treinar modelos de IA com esses dados.",
  # Tema 3: habitação e cidade (8 documentos)
  "O programa habitacional amplia recursos federais para moradia popular urbana. O governo pretende contratar milhares de novas unidades habitacionais. Prefeituras disputam terrenos urbanos bem localizados para as obras.",
  "O deficit habitacional afeta milhoes de familias de baixa renda nas cidades. O aluguel caro consome boa parte da renda das familias. Coabitacao e moradia precária concentram o deficit nas periferias urbanas.",
  "Urbanizacao de favelas e regularizacao fundiária avancam em municipios brasileiros. Moradores recebem titulos de propriedade e obras de saneamento. A urbanizacao das favelas leva infraestrutura e transporte aos bairros.",
  "Moradia digna e direito social garantido pela Constituicao federal de 1988. Movimentos de moradia ocupam imoveis vazios no centro das cidades. A funcao social da propriedade urbana orienta a politica habitacional.",
  "Assentamentos precários crescem nas periferias metropolitanas do pais. Familias constroem moradias em areas de risco sem infraestrutura urbana. Deslizamentos e enchentes atingem bairros sem planejamento habitacional.",
  "O programa Minha Casa Minha Vida entrega novas unidades habitacionais populares. Conjuntos habitacionais distantes do centro dificultam o acesso ao emprego. O programa retoma a faixa de moradia para familias de baixa renda.",
  "Especialistas em urbanismo debatem alugueis abusivos nas grandes cidades. O aluguel social atende familias despejadas de suas moradias. Imoveis ociosos no centro urbano poderiam virar habitacao popular.",
  "Politicas de habitacao popular incluem regularizacao fundiária e infraestrutura urbana. Saneamento, transporte e moradia precisam de planejamento conjunto nas cidades. Municipios recebem recursos para urbanizacao de bairros periféricos.",
  # Tema 4: educação (8 documentos)
  "A educacao básica recebe novos recursos do Fundeb ampliado pelo Congresso. Redes municipais de ensino ampliam vagas em creches e escolas. A complementacao federal prioriza municipios com menor investimento por aluno.",
  "Alfabetizacao na idade certa e meta central do novo Plano Nacional de Educacao. Avaliacoes mostram atraso na leitura dos alunos apos a pandemia. Escolas recebem material didático e formacao de professores alfabetizadores.",
  "Professores debatem remuneracao e condicoes de trabalho nas escolas públicas. Salas lotadas e falta de estrutura prejudicam o ensino. Sindicatos de professores cobram plano de carreira nas redes de educacao.",
  "O ensino médio integrado ao técnico expande vagas em institutos federais. Alunos combinam formacao geral e curso profissionalizante na escola. A reforma do ensino médio redefine o curriculo e a carga horaria.",
  "A avaliação Prova Brasil mede aprendizagem em português e matemática. Os resultados do Saeb orientam metas das escolas e redes de ensino. Professores usam os indicadores de aprendizagem para planejar as aulas.",
  "Politicas de permanência estudantil ampliam bolsas para universitários pobres. Alunos de baixa renda abandonam o ensino superior por falta de apoio. Universidades públicas ampliam moradia estudantil e restaurantes para estudantes.",
  "O piso salarial nacional dos professores e reajustado pelo governo federal. Municipios alegam falta de recursos para pagar o piso do magisterio. A valorizacao dos professores e meta do Plano Nacional de Educacao.",
  "A formacao continuada de professores e desafio permanente da educacao básica. Cursos de capacitacao ajudam docentes a usar tecnologia em sala de aula. Escolas com professores bem formados apresentam melhor aprendizagem dos alunos."
)

corpus <- ac_corpus(
  data.frame(
    text = textos,
    tema = rep(c("tributário","tecnologia","habitacao","educacao"), each = 8L),
    stringsAsFactors = FALSE
  )
)
corpus
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 32
#> • Metadados: 1 coluna
#> • Idioma: "pt"
#> 
#> # A tibble: 32 × 3
#>   doc_id text                                                              tema 
#>   <chr>  <chr>                                                             <chr>
#> 1 doc_1  A reforma tributária simplifica o sistema de impostos e reduz a … trib…
#> 2 doc_2  O IVA dual substitui PIS, COFINS e ICMS no novo modelo de arreca… trib…
#> 3 doc_3  Deputados debatem aliquotas e excecoes tributárias para setores … trib…
#> 4 doc_4  A reforma tributária unifica impostos indiretos e simplifica obr… trib…
#> 5 doc_5  Empresários criticam a alta carga tributária brasileira sobre o … trib…
#> 6 doc_6  O relator propoe aliquotas diferenciadas para produtos essenciai… trib…
#> # ℹ 26 more rows
```

## 2. Preparar: limpeza e remoção de *stopwords*

**Sem remover *stopwords*, LDA vai identificar tópicos dominados por
“o”, “a”, “de”, “que”, “para”.** Isso mascara os padrões reais.
Removemos as *stopwords* padrão do português e adicionamos algumas
específicas do domínio legislativo (`brasil`, `pais`) que aparecem em
todos os temas.

``` r

corpus_limpo <- ac_clean(
  corpus,
  remove_stopwords = "pt",
  extra_stopwords  = c("brasil", "pais", "sobre", "novo", "nova")
)
corpus_limpo
#> 
#> ── Corpus acR ──────────────────────────────────────────────────────────────────
#> • Documentos: 32
#> • Metadados: 1 coluna
#> • Idioma: "pt"
#> 
#> # A tibble: 32 × 3
#>   doc_id text                                                              tema 
#>   <chr>  <chr>                                                             <chr>
#> 1 doc_1  reforma tributária simplifica sistema impostos reduz carga fisca… trib…
#> 2 doc_2  iva dual substitui pis cofins icms modelo arrecadacao federal es… trib…
#> 3 doc_3  deputados debatem aliquotas excecoes tributárias setores economi… trib…
#> 4 doc_4  reforma tributária unifica impostos indiretos simplifica obrigac… trib…
#> 5 doc_5  empresários criticam alta carga tributária brasileira consumo po… trib…
#> 6 doc_6  relator propoe aliquotas diferenciadas produtos essenciais iva c… trib…
#> # ℹ 26 more rows
```

## 3. Escolher K: quantos tópicos?

LDA exige que você especifique **K** (número de tópicos) *a priori*. A
escolha ideal é um balanço:

- **K muito baixo** → tópicos misturam temas distintos (subajuste).
- **K muito alto** → tópicos fragmentam um mesmo tema (sobreajuste,
  ruído).

A métrica clássica é a **perplexidade**: o quão “surpreso” o modelo fica
com os documentos (menor = prevê melhor as palavras). O detalhe que
decide tudo é **em quais documentos** ela é medida. Calculada nos mesmos
documentos usados no ajuste, ela cai quase sempre que K aumenta, porque
mais tópicos = mais parâmetros para memorizar o corpus. Por isso Blei,
Ng & Jordan (2003) e Wallach et al. (2009) a medem em documentos **não
vistos**, e Zhao et al. (2015) usam validação cruzada em 5 partes, que é
o que
[`ac_lda_tune()`](https://ahenriquecp.com/acR/reference/ac_lda_tune.md)
faz: ajusta em 4/5 dos documentos, mede no 1/5 restante, e repete 5
vezes. A coluna `perplexity_train` mostra a versão de treino, só para
comparação.

### Antes de rodar: o *prior* α importa em textos curtos

O LDA tem um hiperparâmetro α que controla **quantos tópicos cada
documento costuma misturar**: α alto empurra todo documento para uma
mistura de vários tópicos; α baixo permite que cada documento se
concentre em poucos. O padrão do Gibbs no `topicmodels` é α = 50/K
(Griffiths & Steyvers, 2004), pensado para documentos longos; com K = 4
isso dá α = 12,5, uma mistura forçada que não combina com parágrafos de
três frases sobre um único tema. Wallach, Mimno & McCallum (2009)
mostram que a escolha do *prior* muda substancialmente a qualidade dos
tópicos. Usamos aqui Gibbs com α = 0,1, passado via `control`:

``` r

controle <- list(alpha = 0.1, iter = 2000, burnin = 500)
```

``` r

tune <- ac_lda_tune(
  corpus_limpo,
  k_range = 2:8,
  seed    = 42L,
  method  = "Gibbs",
  control = controle
)
#> Testando k = 2 a 8...
#> ℹ Perplexidade fora da amostra: validação cruzada em 5 partes.
tune
#> # A tibble: 7 × 4
#>       k perplexity perplexity_sd perplexity_train
#>   <int>      <dbl>         <dbl>            <dbl>
#> 1     2       207.          22.3             198.
#> 2     3       182.          16.2             153.
#> 3     4       131.          15.3             127.
#> 4     5       136.          10.1             128.
#> 5     6       140.          14.1             119.
#> 6     7       139.          16.1             112.
#> 7     8       143.          21.3             109.
```

``` r

ac_plot_lda_tune(tune) +
  ggplot2::labs(
    title    = "Perplexidade fora da amostra por número de tópicos (K)",
    subtitle = "Validação cruzada em 5 partes; menor = melhor previsão de documentos novos",
    caption  = "acR - ac_lda_tune()"
  )
```

![](lda_files/figure-html/plot-tune-1.png)

> **Como ler a tabela e o gráfico**
>
> 1.  **Onde olhar.** Na tabela, cada linha é um K testado. Compare duas
>     colunas: `perplexity_train` (medida nos mesmos documentos do
>     ajuste) e `perplexity` (medida em documentos que o modelo não viu;
>     é a do gráfico). Menor = o modelo prevê melhor as palavras. No
>     gráfico, procure onde a curva **para de cair**. `perplexity_sd`
>     diz o quanto o valor variou entre as 5 partes da validação.
>
> 2.  **O que este exemplo mostra.** A de treino cai sem parar, de ≈ 198
>     (K = 2) até ≈ 109 (K = 8). A de fora da amostra cai até K = 4 (≈
>
>     131. e depois fica parada entre ≈ 136 e ≈ 143. O `perplexity_sd`
>          fica entre 10 e 22.
>
> 3.  **Em palavras simples.** Na versão de treino, mais tópicos sempre
>     parecem melhores, porque o modelo decora o corpus; escolher K por
>     ela levaria sempre ao maior K testado. Em documentos novos,
>     tópicos além do 4º já não ajudam a prever nada: o ganho acaba em K
>     = 4, que é o número de temas com que o corpus foi construído.
>
> 4.  **Cuidado.** A curva delimita uma faixa, não um valor exato: K =
>     5, 6 e 7 ficam dentro da margem de variação (`perplexity_sd`) de K
>     =
>
>     4.  Perplexidade e interpretabilidade humana nem sempre concordam
>         (Chang et al., 2009); a decisão final combina a curva, a
>         leitura dos tópicos de alguns K candidatos e o conhecimento do
>         corpus (DiMaggio, Nag & Blei, 2013). Faça o teste: com o
>         método padrão (`"VEM"`), a curva fora da amostra **sobe** com
>         K neste corpus, sinal de que o ajuste precisa de atenção, não
>         só o K.

## 4. Treinar o modelo LDA

Com K definido, ajustamos o modelo com os mesmos `method` e `control`
usados na escolha de K. `seed` é obrigatório para reprodutibilidade: LDA
é estocástico (Variational EM ou Gibbs sampling), e rodadas com sementes
diferentes retornam **tópicos com IDs diferentes** e pequenas variações
nas distribuições.

``` r

modelo <- ac_lda(
  corpus_limpo,
  k       = 4L,
  seed    = 42L,
  method  = "Gibbs",
  control = controle
)
#> Ajustando LDA com k = 4 tópicos...
modelo
#> 
#> ── Modelo LDA acR ──────────────────────────────────────────────────────────────
#> • Tópicos (k): 4
#> • Método: "Gibbs"
#> • Semente: 42
#> • Termos únicos: 425
#> • Documentos: 32
```

## 5. Termos por tópico (matriz β)

Cada linha é uma combinação (tópico, termo), com `beta` = probabilidade
do termo dado o tópico. Filtramos os top termos para inspecionar o que
cada tópico “significa”.

``` r

beta <- modelo$terms
head(beta, 10)
#> # A tibble: 10 × 3
#>    topic term           beta
#>    <int> <chr>         <dbl>
#>  1     1 dados      0.000466
#>  2     1 impostos   0.000466
#>  3     1 lei        0.000466
#>  4     1 pessoais   0.000466
#>  5     1 empresas   0.000466
#>  6     1 ia         0.000466
#>  7     1 algoritmos 0.000466
#>  8     1 deficit    0.00979 
#>  9     1 familias   0.0284  
#> 10     1 renda      0.0238
```

Visualização: os 10 termos com maior β por tópico:

``` r

ac_plot_lda_topics(modelo, top_n = 10L) +
  ggplot2::labs(
    title    = "Top 10 termos por tópico (LDA, K=4)",
    subtitle = "Beta = probabilidade do termo dado o tópico"
  )
```

![](lda_files/figure-html/plot-topics-1.png)

> **Como ler este gráfico**
>
> 1.  **Onde olhar.** Um painel por tópico. Em cada painel, a barra mais
>     longa (no topo) é a palavra mais provável daquele tópico (β). Leia
>     as 3 ou 4 primeiras palavras de cada painel e pergunte: “sobre o
>     que fala um texto que usa essas palavras?”.
>
> 2.  **O que este exemplo mostra.** Tópico 1: *moradia*, *familias*,
>     *renda*, *urbana* (habitação). Tópico 2: *professores*, *ensino*,
>     *escolas*, *educacao* (educação). Tópico 3: *dados*, com a barra
>     mais longa do gráfico, seguido de *algoritmos*, *pessoais*, *ia*
>     (IA e proteção de dados). Tópico 4: *tributária*, *reforma*,
>     *impostos*, *imposto* (reforma tributária).
>
> 3.  **Em palavras simples.** Cada tópico corresponde a uma das quatro
>     agendas do corpus. O modelo não sabe os nomes dos temas: quem dá o
>     nome é você, olhando as palavras.
>
> 4.  **Cuidado.** Palavras genéricas aparecem no fim de alguns painéis
>     (*precisam*, *ampliam*, *empresas*). Se elas aparecerem nas
>     **primeiras** posições de todos os tópicos, faltou removê-las como
>     *stopwords* do domínio na etapa 2. E não confunda os números:
>     “Tópico 1” não é o primeiro tema do corpus; a numeração é
>     arbitrária e muda com a semente.

O gráfico permite **rotular** os tópicos. Nomeamos com base nos termos
dominantes: se um tópico é dominado por *reforma*, *tributária*, *iva*,
*aliquotas*, chamamos de “Reforma Tributária”.

Visualização alternativa: uma *word cloud* ponderada por β dentro de
cada tópico, útil em apresentações onde o eixo numérico do gráfico de
barras pesa menos que o impacto visual imediato das palavras maiores:

``` r

topico_escolhido <- 1L

beta |>
  dplyr::filter(topic == topico_escolhido) |>
  dplyr::slice_max(beta, n = 25L, with_ties = FALSE) |>
  ggplot2::ggplot(ggplot2::aes(label = term, size = beta, color = beta)) +
  ggwordcloud::geom_text_wordcloud() +
  ggplot2::scale_size_area(max_size = 14) +
  ggplot2::scale_color_gradient(low = ac_palette(1), high = ac_palette(2)) +
  ggplot2::labs(
    title = paste("Nuvem de termos do tópico", topico_escolhido)
  ) +
  theme_ac()
```

![](lda_files/figure-html/plot-topics-alt-1.png)

## 6. Distribuição de tópicos por documento (matriz γ)

Para cada documento, quais tópicos dominam? Um documento pode ser 90%
tópico 1 (tema puro) ou distribuído entre vários tópicos (tema misto).

``` r

gamma <- modelo$documents
head(gamma, 12)
#> # A tibble: 12 × 3
#>    doc_id topic   gamma
#>    <chr>  <int>   <dbl>
#>  1 doc_10     1 0.00467
#>  2 doc_10     2 0.00467
#>  3 doc_10     3 0.939  
#>  4 doc_10     4 0.0514 
#>  5 doc_12     1 0.00467
#>  6 doc_12     2 0.00467
#>  7 doc_12     3 0.799  
#>  8 doc_12     4 0.192  
#>  9 doc_1      1 0.00410
#> 10 doc_1      2 0.00410
#> 11 doc_1      3 0.00410
#> 12 doc_1      4 0.988
```

Sumário: qual o tópico dominante de cada documento?

``` r

dominante <- gamma |>
  dplyr::group_by(doc_id) |>
  dplyr::slice_max(gamma, n = 1L, with_ties = FALSE) |>
  dplyr::ungroup() |>
  dplyr::rename(topico_dominante = topic, prob = gamma)

head(dominante, 12)
#> # A tibble: 12 × 3
#>    doc_id topico_dominante  prob
#>    <chr>             <int> <dbl>
#>  1 doc_1                 4 0.988
#>  2 doc_10                3 0.939
#>  3 doc_11                3 0.838
#>  4 doc_12                3 0.799
#>  5 doc_13                3 0.987
#>  6 doc_14                3 0.939
#>  7 doc_15                3 0.985
#>  8 doc_16                3 0.986
#>  9 doc_17                1 0.540
#> 10 doc_18                1 0.987
#> 11 doc_19                1 0.985
#> 12 doc_2                 4 0.987
```

Comparando com o **tema real** de cada documento (o `meta$tema` que
guardamos no corpus), conseguimos avaliar **quão bem o LDA recuperou a
estrutura conhecida**:

``` r

# Recuperar o metadado 'tema' e cruzar com o tópico dominante
tema_real <- corpus[, c("doc_id", "tema")]
comparacao <- merge(dominante, tema_real, by = "doc_id")

# Tabela de contingência: tópico dominante x tema real
table(comparacao$topico_dominante, comparacao$tema)
#>    
#>     educacao habitacao tecnologia tributário
#>   1        0         8          0          1
#>   2        8         0          0          0
#>   3        0         0          8          0
#>   4        0         0          0          7
```

> **Como ler esta tabela**
>
> 1.  **Onde olhar.** Linhas = tópico dominante de cada documento (o de
>     maior γ); colunas = tema real, que o modelo não viu. Cada número é
>     quantos documentos caem naquela combinação. O ideal é **uma célula
>     grande por linha** (cada tópico ligado a um tema só). Como a
>     numeração dos tópicos é arbitrária, a “diagonal” pode aparecer
>     embaralhada.
>
> 2.  **O que este exemplo mostra.** O Tópico 1 tem os 8 documentos de
>     `habitacao`, o Tópico 2 os 8 de `educacao`, o Tópico 3 os 8 de
>     `tecnologia` e o Tópico 4 7 dos 8 de `tributário`. O único fora do
>     lugar é um documento tributário no Tópico 1 (habitação).
>
> 3.  **Em palavras simples.** O modelo recuperou os quatro temas sem
>     ver nenhum rótulo, com 31 acertos em 32 documentos.
>
> 4.  **Cuidado.** O “erro” é instrutivo: é `doc_5`, um texto tributário
>     sobre *cashback* para “famílias de baixa renda”. Ele divide o peso
>     quase ao meio entre os tópicos tributário e de habitação (γ ≈ 0,47
>     e ≈ 0,52) porque compartilha vocabulário com os textos de moradia.
>     É um documento genuinamente ambíguo, e a seção 8 mostra como
>     reconhecê-lo. Em corpora reais, sem tema conhecido, essa validação
>     vem da leitura humana dos tópicos e de alguns documentos de cada
>     um.

Se a diagonal for dominante (cada tópico se alinha bem com um tema
real), o modelo capturou a estrutura. Em corpora reais sem “rótulo
verdadeiro”, essa validação vem da **interpretação humana** dos tópicos
e da concordância entre codificadores.

## 7. Interpretação e nomeação dos tópicos

A prática consolidada em análise de conteúdo com LDA (DiMaggio et al.,
2013): apresente os top-N termos por tópico, proponha um **rótulo
substantivo** e valide com pelo menos um segundo pesquisador. O `acR`
facilita gerar essa tabela para incluir no artigo:

``` r

top_terms_por_topico <- beta |>
  dplyr::group_by(topic) |>
  dplyr::slice_max(beta, n = 7L, with_ties = FALSE) |>
  dplyr::summarise(
    top_termos = paste(term, collapse = ", "),
    .groups    = "drop"
  )

top_terms_por_topico
#> # A tibble: 4 × 2
#>   topic top_termos                                                           
#>   <int> <chr>                                                                
#> 1     1 moradia, familias, renda, habitacional, popular, urbana, baixa       
#> 2     2 professores, ensino, educacao, escolas, alunos, aprendizagem, ampliam
#> 3     3 dados, algoritmos, pessoais, ia, artificial, inteligência, precisam  
#> 4     4 tributária, impostos, reforma, imposto, empresas, carga, excecoes
```

## 8. Visualizando as misturas: γ como heatmap

Uma das forças didáticas do LDA é que γ **não é** uma etiqueta: é uma
proporção. Documentos que “quase pertencem a um tema” aparecem como um
gradiente, não como uma célula preenchida. Este heatmap mostra os
documentos como linhas, os tópicos como colunas, e a cor como `gamma` (0
= nada; 1 = totalidade da massa).

``` r

gamma_ord <- gamma |>
  # ordem numérica (doc_1 no topo), para os 4 temas aparecerem em blocos
  dplyr::mutate(doc_id = factor(doc_id, levels = paste0("doc_", 32:1)))

ggplot2::ggplot(
  gamma_ord,
  ggplot2::aes(x = factor(topic), y = doc_id, fill = gamma)
) +
  ggplot2::geom_tile(color = "white") +
  ggplot2::scale_fill_gradient(
    low  = "#F1F5F9",
    high = ac_palette(1),
    name = "gamma"
  ) +
  ggplot2::labs(
    title    = "Composicao tematica de cada documento (matriz gamma)",
    subtitle = "Cores mais fortes = maior peso do tópico no documento",
    x        = "Tópico",
    y        = "Documento",
    caption  = "acR - LDA soft assignment"
  ) +
  theme_ac() +
  ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = 7)
  )
```

![](lda_files/figure-html/gamma-heatmap-1.png)

> **Como ler este gráfico**
>
> 1.  **Onde olhar.** Uma linha por documento (`doc_1` no topo), uma
>     coluna por tópico. Cor escura = o tópico ocupa quase todo o
>     documento; cinza médio = o documento está dividido. Como cada
>     linha soma 1, procure linhas com **duas células cinzas** em vez de
>     uma escura: são os documentos mistos.
>
> 2.  **O que este exemplo mostra.** Os 32 documentos formam 4 blocos
>     escuros, um por tema: `doc_1` a `doc_8` no Tópico 4, `doc_9` a
>     `doc_16` no 3, `doc_17` a `doc_24` no 1 e `doc_25` a `doc_32`
>     no 2. Destoam poucas linhas: `doc_5` (dividido entre os Tópicos 1
>     e 4), `doc_17` (entre 1 e 2) e, em menor grau, `doc_6`, `doc_23` e
>     `doc_30`.
>
> 3.  **Em palavras simples.** Quase todo documento fala de um assunto
>     só. Os poucos divididos são textos que usam palavras de dois temas
>     (`doc_17`, sobre programa habitacional, fala de “recursos
>     federais”, vocabulário que também aparece nos textos de educação).
>
> 4.  **Cuidado.** Não há um limiar universal para dizer que um
>     documento “pertence” a um tópico. A prática usual é reportar o
>     tópico de maior γ e marcar como ambíguos os documentos em que o
>     segundo tópico chega perto do primeiro. A proporção de documentos
>     puros também depende do α escolhido na seção 3: α baixo favorece
>     documentos concentrados (Wallach, Mimno & McCallum, 2009).

Neste corpus, a maioria dos documentos é quase “pura”: a γ do tópico
principal tem mediana ≈ 0,98. Só 5 dos 32 documentos dão mais de 0,20 a
um segundo tópico, e em dois deles (`doc_5` e `doc_17`) os dois tópicos
principais estão quase empatados (≈ 0,52 × 0,47 e ≈ 0,54 × 0,45): são
esses que mereceriam a etiqueta de “ambíguos”. Isso é coerente com o α
baixo escolhido na seção 3, que favorece documentos concentrados em
poucos tópicos, e com textos escritos, cada um, sobre um único tema. Em
discursos longos reais, espere mais linhas com massa espalhada.

Compare com o heatmap “hard clustering” da
[`vignette("cluster")`](https://ahenriquecp.com/acR/articles/cluster.md)
§4.6: lá, cada linha tem **uma** célula acesa (pertence ao grupo A
**ou** ao B), mesmo para documentos como `doc_5`, cuja ambiguidade a γ
revela e a etiqueta única esconde. Tomar o tópico de maior γ de cada
documento é justamente transformar a descrição contínua numa partição.

## 9. Exportar

Salvamos as duas matrizes principais para reuso: em outros scripts, no
Excel, ou para colar em tabelas de artigo:

``` r

ac_export(beta,  arquivo = "lda_beta.csv",  formato = "csv")
ac_export(gamma, arquivo = "lda_gamma.csv", formato = "csv")

# Tabela pronta para LaTeX
ac_export(top_terms_por_topico, arquivo = "lda_topicos.tex", formato = "latex")

# Objeto R serializado (recarregavel via readRDS)
saveRDS(modelo, "lda_modelo.rds")
```

## Referências

- Blei, D. M.; Ng, A. Y.; Jordan, M. I. (2003). Latent Dirichlet
  Allocation. *Journal of Machine Learning Research*, 3, 993-1022.
- DiMaggio, P.; Nag, M.; Blei, D. (2013). Exploiting affinities between
  topic modeling and the sociological perspective on culture:
  Application to newspaper coverage of U.S. government arts funding.
  *Poetics*, 41(6), 570-606.
- Hong, L.; Davison, B. D. (2010). Empirical study of topic modeling in
  Twitter. *Proceedings of the First Workshop on Social Media
  Analytics*, 80-88.
- Yan, X.; Guo, J.; Lan, Y.; Cheng, X. (2013). A biterm topic model for
  short texts. *Proceedings of the 22nd International Conference on
  World Wide Web*, 1445-1456.
- Griffiths, T. L.; Steyvers, M. (2004). Finding scientific topics.
  *Proceedings of the National Academy of Sciences*, 101(suppl. 1),
  5228-5235.
- Wallach, H. M.; Mimno, D.; McCallum, A. (2009). Rethinking LDA: Why
  priors matter. *Advances in Neural Information Processing Systems*,
  22, 1973-1981.
- Chang, J.; Gerrish, S.; Wang, C.; Boyd-Graber, J.; Blei, D. M. (2009).
  Reading tea leaves: How humans interpret topic models. *Advances in
  Neural Information Processing Systems*, 22, 288-296.
- Wallach, H. M.; Murray, I.; Salakhutdinov, R.; Mimno, D. (2009).
  Evaluation methods for topic models. *Proceedings of the 26th
  International Conference on Machine Learning*, 1105-1112.
- Zhao, W. et al. (2015). A heuristic approach to determine an
  appropriate number of topics in topic modeling. *BMC Bioinformatics*,
  16(S13).
- Silge, J.; Robinson, D. (2017). *Text Mining with R*. O’Reilly.
