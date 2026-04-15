# Como contribuir com o `acR`

Obrigado pelo interesse em contribuir! Este documento explica como reportar problemas, propor melhorias e enviar pull requests.

## Reportando bugs

Antes de abrir um *issue*:

1. Verifique se o problema já foi reportado em [issues abertos e fechados](https://github.com/andersonheri/acR/issues?q=is%3Aissue).
2. Verifique se está usando a versão mais recente do pacote (instale via `pak::pak("andersonheri/acR")`).
3. Prepare um exemplo reprodutível mínimo (*reprex*). Recomendamos o pacote [`reprex`](https://reprex.tidyverse.org/).

Use o template de bug report disponível ao abrir um novo *issue*.

## Propondo novas funcionalidades

Para sugerir novas funcionalidades:

1. Abra um *issue* com o template de *feature request*, descrevendo:
   - O problema que a funcionalidade resolve.
   - Casos de uso típicos.
   - Referências bibliográficas relevantes (importante para funções metodológicas).
2. Aguarde discussão antes de iniciar implementação. Funcionalidades fora do escopo podem ser melhor implementadas em pacotes separados.

## Submetendo Pull Requests

### Fluxo geral

1. *Fork* do repositório.
2. Crie um branch específico: `git checkout -b feature/nome-da-feature` ou `fix/descricao-do-bug`.
3. Faça commits pequenos e bem descritos, em português ou inglês.
4. Inclua testes (`tests/testthat/`) para qualquer código novo.
5. Atualize a documentação (`roxygen2`) e rode `devtools::document()`.
6. Atualize o `NEWS.md` na seção "development version".
7. Rode `devtools::check()` localmente — não envie PRs com NOTES, WARNINGS ou ERRORS.
8. Abra o PR contra o branch `main` usando o template fornecido.

### Padrões de código

- Estilo: [tidyverse style guide](https://style.tidyverse.org/).
- Use `|>` (pipe nativo do R), não `%>%`.
- Use `cli::cli_*` para mensagens de erro/warning/info.
- Use `rlang::abort()`, `rlang::warn()`, `rlang::inform()` para condições.
- Documentação em **português** (mensagens de usuário) e **inglês** (comentários técnicos quando útil para colaboradores internacionais).

### Padrões de teste

- Use `testthat` 3a edição.
- Cada arquivo `R/foo.R` deve ter `tests/testthat/test-foo.R` correspondente.
- Mock chamadas de API LLM (use `mockery` ou snapshots).
- Cobertura mínima esperada: 70%.

## Código de Conduta

Este projeto adota o [Contributor Covenant](CODE_OF_CONDUCT.md). Ao participar, você concorda em respeitar seus termos.

## Dúvidas

Em caso de dúvida, abra uma *discussion* no repositório ou contate o mantenedor (Anderson Henrique, anderson.henrique@usp.br).
