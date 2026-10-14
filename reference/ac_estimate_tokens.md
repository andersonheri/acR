# Estimar número de tokens de um texto

`ac_estimate_tokens()` estima o número de tokens de entrada que um texto
vai consumir, usando uma heurística de caracteres por token. Útil para
prever o custo de uma rodada de
[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
ou para detectar, antes de enviar ao LLM, documentos que provavelmente
excederão a janela de contexto do modelo.

## Usage

``` r
ac_estimate_tokens(text, chat = NULL, chars_per_token = 3.2)
```

## Arguments

- text:

  Vetor de caracteres com os textos.

- chat:

  Ignorado nesta versão (reservado para uma futura estimativa específica
  de provedor via `chat$token_count()`). Receber o argumento já na
  assinatura evita quebrar código que o passar.

- chars_per_token:

  Caracteres por token, usado para a estimativa. Padrão `3.2` (razoável
  para português via BPE; varia por tokenizador e idioma). Calibre com
  [`ac_calibrate_tokens()`](https://ahenriquecp.com/acR/reference/ac_calibrate_tokens.md)
  se precisar de precisão maior para um modelo específico.

## Value

Vetor inteiro com a estimativa de tokens por texto.

## Details

É uma estimativa deliberadamente barata: não faz nenhuma chamada de rede
nem depende do tokenizador exato de um modelo específico (que varia por
provedor e às vezes nem é público). Para calibrar a heurística contra um
modelo real, use
[`ac_calibrate_tokens()`](https://ahenriquecp.com/acR/reference/ac_calibrate_tokens.md)
com uma amostra pequena de textos.

## Examples

``` r
ac_estimate_tokens("Este e um texto de exemplo para estimar tokens.")
#> [1] 15
ac_estimate_tokens(c("texto curto", "um texto um pouco mais longo que o anterior"))
#> [1]  4 14
```
