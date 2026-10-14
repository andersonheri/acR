# Estimar numero de tokens de um texto

`ac_estimate_tokens()` estima o numero de tokens de entrada que um texto
vai consumir, usando uma heuristica de caracteres por token. Util para
prever o custo de uma rodada de
[`ac_qual_code()`](https://ahenriquecp.com/acR/dev/reference/ac_qual_code.md)
ou para detectar, antes de enviar ao LLM, documentos que provavelmente
excederao a janela de contexto do modelo.

E uma estimativa deliberadamente barata: nao faz nenhuma chamada de rede
nem depende do tokenizador exato de um modelo especifico (que varia por
provedor e as vezes nem e publico). Para calibrar a heuristica contra um
modelo real, use
[`ac_calibrate_tokens()`](https://ahenriquecp.com/acR/dev/reference/ac_calibrate_tokens.md)
com uma amostra pequena de textos.

## Usage

``` r
ac_estimate_tokens(text, chat = NULL, chars_per_token = 3.2)
```

## Arguments

- text:

  Vetor de caracteres com os textos.

- chat:

  Ignorado nesta versao (reservado para uma futura estimativa especifica
  de provedor via `chat$token_count()`). Receber o argumento ja na
  assinatura evita quebrar codigo que o passar.

- chars_per_token:

  Caracteres por token, usado para a estimativa. Padrao `3.2` (razoavel
  para portugues via BPE; varia por tokenizador e idioma). Calibre com
  [`ac_calibrate_tokens()`](https://ahenriquecp.com/acR/dev/reference/ac_calibrate_tokens.md)
  se precisar de precisao maior para um modelo especifico.

## Value

Vetor inteiro com a estimativa de tokens por texto.

## Examples

``` r
ac_estimate_tokens("Este e um texto de exemplo para estimar tokens.")
#> [1] 15
ac_estimate_tokens(c("texto curto", "um texto um pouco mais longo que o anterior"))
#> [1]  4 14
```
