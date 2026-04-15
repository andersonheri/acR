# ADR 0001 — Decisões iniciais do pacote `acR`

**Projeto**: `acR` — Análise de Conteúdo em R (qualitativa via LLMs + quantitativa clássica)
**Data**: 15 de abril de 2026
**Autor responsável pelas decisões**: Anderson Henrique (mantenedor)
**Coautores futuros previstos**: Dalson Britto Figueiredo Filho (UFPE); Rafael Cardoso Sampaio (UFPR)
**Status geral**: Aceito

---

## Sumário executivo

Este documento registra as cinco decisões estruturantes tomadas antes do início da implementação do pacote `acR`. As decisões cobrem: (i) nome e identidade, (ii) governança e mantenedor, (iii) posicionamento técnico frente ao pacote `quallmer`, (iv) escolha e estratégia de empacotamento do léxico de sentimento OpLexicon, e (v) estratégia de publicação acadêmica. Cada decisão segue o formato Architecture Decision Record (Nygard, 2011), com seções de contexto, decisão, alternativas consideradas e consequências.

A motivação geral do pacote é ocupar uma lacuna específica do ecossistema R: oferecer um pipeline integrado bilíngue (PT-BR/EN), tidy-friendly, que combine análise de conteúdo qualitativa assistida por LLMs com análise de conteúdo quantitativa clássica (descritivos, keyness, co-ocorrência, nuvens, X-ray, sentimento, LDA), com codebooks validados para o contexto brasileiro.

---

## ADR-001 — Nome do pacote: `acR`

### Contexto

A escolha do nome afeta repositório, namespace, identidade visual, citação acadêmica e busca. Pacotes R consolidados no domínio adjacente seguem padrões variados: `quanteda` (Benoit), `tidytext` (Silge), `quallmer` (Maerz/Benoit), `lexiconPT` (Gonzaga), `geobr` (Pereira). O contexto brasileiro tem precedente forte de sufixo `R` em pacotes orientados a dados nacionais.

### Decisão

Adotar o nome `acR` (acrônimo de "Análise de Conteúdo em R").

### Alternativas consideradas

| Alternativa | Razão da rejeição |
|---|---|
| `conteudoR` | Longo demais para uso cotidiano; acentuação pode gerar problema em encoding |
| `contentR` | Genérico; risco de colisão futura |
| `bardin` | Homenagem a Laurence Bardin (1977), mas pode soar pretensiosa; risco reputacional |
| `mayring` | Mesmo risco da anterior; Mayring está vivo e não foi consultado |
| `analiseConteudo` | Descritivo mas longo demais |
| `quallquant` | Marca o duplo paradigma, mas difícil de pronunciar |

### Consequências

- Convenção R consolidada (sufixo `R`) facilita reconhecimento
- Nome curto facilita citação acadêmica e digitação
- Permite evolução semântica sem amarração a autor específico
- Necessário verificar disponibilidade do nome no CRAN antes da submissão

---

## ADR-002 — Governança: mantenedor único na fase inicial

### Contexto

Pacotes R em fase de prototipagem com múltiplos coautores ativos desde o dia 1 frequentemente sofrem com travas de design por comitê. Precedentes bem-sucedidos (`geobr`, `microdatasus`, `quanteda`) iniciaram com mantenedor único e expandiram a equipe após MVP funcional.

### Decisão

Anderson Henrique assume papel único de `aut` + `cre` até a versão v0.5 (MVP defensável). Coautores Dalson Britto Figueiredo Filho (UFPE) e Rafael Cardoso Sampaio (UFPR) serão convidados formalmente após o MVP, com divisão de módulos negociada com base em contribuição efetiva.

Repositório público no GitHub desde o dia 1, com DOI Zenodo desde a v0.1, garantindo prioridade temporal e rastreabilidade de autoria via histórico de commits.

### Alternativas consideradas

| Alternativa | Razão da rejeição |
|---|---|
| Convidar coautores antes de iniciar | Risco de travamento por debate de design; histórico de commits ainda não comprova contribuição |
| Desenvolver fechado até v1.0 | Perde marca temporal; impede colaboração externa eventual |
| Coautoria distribuída desde o início (3 mantenedores) | CRAN exige `Maintainer` único; complexidade operacional alta |

### Consequências

- Decisões técnicas do dia-a-dia ficam ágeis
- Histórico de commits comprova autoria de forma incontestável
- Convite posterior aos coautores se dá com material concreto, definindo divisão de trabalho de forma natural
- Cronograma da equipe expandida definido em rodada futura

### Composição prevista de longo prazo

| Coautor | Filiação | Contribuição prevista |
|---|---|---|
| Anderson Henrique | CEM-USP | Arquitetura geral, módulo LLM, codebooks BR, visualização |
| Dalson Britto Figueiredo Filho | UFPE | Métricas estatísticas, confiabilidade, rigor metodológico |
| Rafael Cardoso Sampaio | UFPR | Aplicação a corpora digitais, sentimento, LDA |

---

## ADR-003 — Posicionamento técnico: arquitetura híbrida frente ao `quallmer`

### Contexto

O pacote `quallmer` (Maerz & Benoit, v0.3.0) já oferece infraestrutura para codificação qualitativa via LLMs em R, com API enxuta (`qlm_codebook`, `qlm_code`, `qlm_compare`, `qlm_replicate`, `qlm_trail`) e suporte multimodal. Três posicionamentos são possíveis para o `acR`: (i) reimplementar tudo do zero ignorando `quallmer`; (ii) depender de `quallmer` como camada base; (iii) reimplementar apenas o núcleo LLM (3-4 funções equivalentes), sem dependência, mas com diálogo acadêmico.

A opção (ii) implica risco de quebra a cada mudança de API do `quallmer` (que está em v0.3, sem garantia de estabilidade) e impossibilita correção autônoma de bugs estruturais identificados (ex: filtro restritivo de argumentos em `qlm_code()` que impede uso de provedores OpenAI-compatible self-hosted).

### Decisão

Adotar arquitetura **híbrida**: o `acR` reimplementa o núcleo de funcionalidade LLM por meio de wrapper direto sobre `ellmer` (Posit/Wickham, estável, com semver respeitado), sem depender de `quallmer` em tempo de execução. O `quallmer` é citado como referência metodológica ("inspired by Maerz & Benoit, 2025") na documentação, vignettes e paper metodológico.

Como contraprestação à comunidade upstream, será submetido um Pull Request ao repositório oficial do `quallmer` corrigindo o bug do filtro de argumentos, antes do lançamento público da v0.1 do `acR`.

### Alternativas consideradas

| Alternativa | Razão da rejeição |
|---|---|
| Independente puro (ignorar `quallmer`) | Posicionamento desonesto; perde diálogo acadêmico legítimo |
| Extensão (depender de `quallmer`) | Risco de quebra a cada release upstream; impede correção autônoma de bugs; amarra identidade do `acR` |

### Consequências

- O `acR` controla seu núcleo técnico integralmente
- Custo de reimplementação é baixo (~150-200 linhas R para equivalência funcional)
- Dependências centrais ficam: `ellmer`, `quanteda`, `irrCAC`, `topicmodels`, `ggplot2`, `dplyr`, `tibble`, `rlang`, `cli`
- Dependências opcionais (`Suggests`): `udpipe`, `sf`, `geobr`, `ggraph`, `ldatuning`
- Bugfix upstream cumpre dever de comunidade open source e gera goodwill com Maerz/Benoit
- Resposta padronizada a eventual pergunta sobre não-contribuição ao `quallmer`: "fizemos um pacote com escopo diferente (qual+quant integrado, PT-BR), e tomamos `quallmer` como referência metodológica"

### Bug identificado a corrigir upstream

Em `qlm_code()`, o filtro `chat_args <- dots[dot_names %in% chat_arg_names]` descarta argumentos específicos de provedores (ex: `base_url`, `api_args`) que não estão em `formals(ellmer::chat)`. Isso impede uso com APIs OpenAI-compatible self-hospedadas (vLLM, LiteLLM, Azure OpenAI, OpenRouter).

A correção proposta usa whitelist por provedor (via inspeção de `formals(chat_<provider>)` no namespace `ellmer`) com warning informativo para argumentos não reconhecidos, em vez de simplesmente remover o filtro.

---

## ADR-004 — Léxico de sentimento: OpLexicon empacotado direto

### Contexto

O módulo de análise de sentimento em PT-BR exige um léxico validado. Três léxicos foram considerados: OpLexicon (Souza & Vieira, 2012; PUCRS), SentiLex-PT (Silva et al., 2012; Univ. Lisboa), e LIWC-Br (Balage Filho et al., 2013). OpLexicon foi escolhido como léxico inicial por (i) ser o mais usado em literatura brasileira; (ii) já ter precedente de empacotamento em CRAN via `lexiconPT`; (iii) cobertura ampla (~32k termos); (iv) prática prévia do mantenedor com a fonte.

A fonte `https://raw.githubusercontent.com/marlovss/OpLexicon/main/OpLexicon.csv`, identificada durante o levantamento, é mantida por **Marlo Souza** — um dos coautores originais do léxico. A versão hospedada nesse repositório incorpora revisão linguística posterior, feita por Aline A. Vanin e Denise Hogetop, sendo portanto mais atual que a versão distribuída pelo `lexiconPT` (estática desde 2017, sem manutenção desde 2019).

### Decisão

Empacotar o OpLexicon na versão `marlovss/OpLexicon` diretamente em `data/oplexicon.rda` do `acR`, sem dependência do pacote `lexiconPT`. A procedência (versão direto do autor original) elimina ambiguidade legal e oferece versão mais atualizada que a alternativa via CRAN.

### Implementação prevista

```r
# data-raw/oplexicon.R (script de preparação, fora do pacote final)
oplexicon <- readr::read_csv(
  "https://raw.githubusercontent.com/marlovss/OpLexicon/main/OpLexicon.csv",
  col_names = c("termo", "pos", "polaridade"),
  col_types = "ccc"
)
usethis::use_data(oplexicon, overwrite = TRUE)
```

### Obrigações associadas

1. **Citação obrigatória** em toda documentação, vignettes e papers que usem o módulo de sentimento:
   - Souza, M.; Vieira, R. (2012). Sentiment Analysis on Twitter Data for Portuguese Language. *PROPOR*.
   - Souza, M.; Vieira, R.; Busetti, D.; Chishman, R.; Alves, I. M. (2011). Construction of a Portuguese Opinion Lexicon from multiple resources. *STIL/SBC*.
   - Reconhecimento da revisão linguística por Vanin & Hogetop.
2. **Arquivo `LICENSE.note`** específico para o léxico no diretório do pacote.
3. **`inst/CITATION`** com referência completa.
4. **E-mail de cortesia a Marlo Souza** antes do lançamento da v0.1, comunicando o uso e oferecendo agradecimento formal na documentação. Não se trata de pedido de permissão (uso autorizado pela publicação em GitHub público), mas de cortesia acadêmica.

### Alternativas consideradas

| Alternativa | Razão da rejeição |
|---|---|
| Depender de `lexiconPT::oplexicon_v3.0` | Pacote sem manutenção desde 2019; versão mais antiga; `acR` ficaria refém de manutenção alheia |
| Download sob demanda do site oficial PUCRS | Site retornou 403 durante levantamento; instabilidade do link |
| Empacotar SentiLex-PT em vez de OpLexicon | Menor adoção em literatura brasileira; cobertura menor |
| Empacotar múltiplos léxicos desde a v0.1 | Aumenta complexidade do MVP; OpLexicon basta para demonstrar arquitetura |

### Consequências

- O `acR` fica autônomo no módulo de sentimento
- Possibilidade de sincronização periódica com o repositório do Marlo Souza
- Diferencial acadêmico: usar versão revisada e atualizada é argumento defensável no paper metodológico
- Expansão futura para SentiLex-PT e outros léxicos fica em aberto para v0.2 ou v1.0

---

## ADR-005 — Estratégia de publicação: três entregas escalonadas

### Contexto

A estratégia de publicação acadêmica define o nível de rigor metodológico exigido durante o desenvolvimento, o cronograma de submissão e a alocação de esforço de redação. Três estratégias foram consideradas: (A) paper único de alto impacto em *Journal of Statistical Software* ou *Political Analysis*; (B) dois papers paralelos em *BPSR* + *DADOS*/*Opinião Pública*; (C) três entregas escalonadas (pré-print + paper metodológico + paper aplicado).

### Decisão

Adotar a **Estratégia C — três entregas escalonadas**:

| Etapa | Quando | Onde | Foco |
|---|---|---|---|
| 1. Pré-print + release público | Mês 4-5, após MVP | SocArXiv + GitHub v0.5 + DOI Zenodo | Marca prioridade temporal |
| 2. Paper metodológico | Mês 9-10, após CRAN | *Brazilian Political Science Review* | Arquitetura do pacote, integração qual+quant, contribuição PT-BR |
| 3. Paper aplicado | Mês 14-18 | *DADOS* ou *Opinião Pública* | Aplicação a corpus substantivo (sugestão: discursos da Câmara sobre federalismo, dialogando com a agenda de capacidade estatal de Anderson Henrique) |

### Alternativas consideradas

| Alternativa | Razão da rejeição |
|---|---|
| Estratégia A (paper único em JSS/Political Analysis) | Fila de revisão de 12-18 meses; rejeição custosa; não dialoga com público brasileiro; exige nível de validação raro em pacotes brasileiros |
| Estratégia B (dois papers paralelos) | Dobro de esforço de redação; risco de auto-plágio; coautoria se complica |

### Consequências e padrões mínimos derivados

A Estratégia C ajusta os padrões mínimos de qualidade do desenvolvimento, tornando-os realistas para postdoc com agenda de pesquisa própria:

- **Cobertura de testes**: meta de 70% (suficiente para *BPSR*, abaixo do exigido por JSS)
- **Vignettes**: 5-7
- **Validação empírica**: 1 corpus de gold standard (não 3-4)
- **Documentação**: bilíngue PT/EN, com prioridade ao PT
- **Benchmarks**: comparação com `quanteda` e `quallmer`, sem exigência de exaustividade

Esses padrões liberam aproximadamente 30-40% do esforço que seria gasto se a meta inicial fosse JSS, sem comprometer a qualidade científica das entregas previstas.

### Vantagens estratégicas adicionais

- Distribui risco entre três venues independentes
- Pré-print marca prioridade temporal sem custo de revisão
- Permite convite escalonado a coautores em momentos específicos (Dalson no metodológico, Rafael no aplicado, conforme contribuição efetiva)
- Alinha com cronograma da renovação FAPESP (processo nº 2025/15250-0) em 2027
- Não impede submissão posterior em JSS ou *Political Analysis* na v1.0 (2027-2028), com versão expandida

---

## Decisões técnicas associadas (registradas para referência)

As decisões abaixo são derivadas das cinco principais e foram aceitas como pacote único:

| Item | Decisão |
|---|---|
| Licença | MIT |
| Sistema de classes | S3 na v0.x; migração para S7 em v1.0 |
| Idioma do código e documentação | Bilíngue PT-BR/EN; mensagens de erro em PT |
| Hospedagem | GitHub público desde dia 1 + DOI Zenodo desde v0.1 |
| Backends LLM suportados | Via `ellmer`: Anthropic, OpenAI, Ollama, Groq, OpenAI-compatible self-hosted |
| Política de PRs externos | Após v0.5 público, todos via PR revisado por pelo menos 1 coautor |
| Convenção de versionamento | Semantic Versioning (semver) |

---

## Pendências e próximas decisões

Itens identificados que não bloqueiam o início da execução, mas precisarão de decisão nas próximas semanas:

1. Tema visual e paleta exata do `theme_acR()`
2. Estrutura final detalhada de pastas
3. Configuração de CI/CD (GitHub Actions, codecov, pkgdown)
4. Formato dos codebooks BR (YAML, JSON, R objects)
5. Política de cache (SQLite via `cachem`?)
6. Documento separado de arquitetura técnica (`docs/architecture.md`)
7. Documento separado de roadmap (`docs/roadmap.md`)

---

## Histórico de revisões

| Versão | Data | Mudança | Responsável |
|---|---|---|---|
| 1.0 | 15/04/2026 | Versão inicial — registro das 5 decisões críticas | Anderson Henrique |

---

## Referências

- Bardin, L. (1977). *L'Analyse de Contenu*. PUF.
- Mayring, P. (2022). *Qualitative Content Analysis: A Step-by-Step Guide*. SAGE.
- Krippendorff, K. (2018). *Content Analysis: An Introduction to Its Methodology* (4th ed.). SAGE.
- Nygard, M. (2011). *Documenting Architecture Decisions*. https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- Souza, M.; Vieira, R. (2012). Sentiment Analysis on Twitter Data for Portuguese Language. *PROPOR*.
- Souza, M.; Vieira, R.; Busetti, D.; Chishman, R.; Alves, I. M. (2011). Construction of a Portuguese Opinion Lexicon from multiple resources. *STIL/SBC*.
- Maerz, S. F.; Benoit, K. (2025). *quallmer: LLM-Assisted Qualitative Coding in R*. https://quallmer.github.io/quallmer/
- Wickham, H. et al. (2024-2026). *ellmer: Chat with Large Language Models*. https://ellmer.tidyverse.org/
- Benoit, K. et al. *quanteda: Quantitative Analysis of Textual Data*. https://quanteda.io/
