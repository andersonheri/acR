# Calibrar a razão caracteres/token contra um modelo real

`ac_calibrate_tokens()` mede, contra um `Chat` real, quantos tokens de
entrada um conjunto de textos de amostra realmente consome, e devolve a
razão caracteres/token observada — para usar como `chars_per_token` em
[`ac_estimate_tokens()`](https://ahenriquecp.com/acR/reference/ac_estimate_tokens.md)
(ou como `chars_per_token` em `ac_qual_code()` / futuras funções que
dependam da estimativa).

## Usage

``` r
ac_calibrate_tokens(chat_factory, textos)
```

## Arguments

- chat_factory:

  Função `function(temperature, system_prompt) Chat` que constrói o chat
  a usar (o mesmo padrão aceito por `model` em
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)).
  Permite calibrar contra o provedor/modelo exato que será usado na
  rodada real.

- textos:

  Vetor de caracteres com textos de amostra (poucos bastam; ideal variar
  o tamanho).

## Value

Número: a mediana de caracteres por token observada na amostra.

## Details

Faz uma chamada real ao modelo por texto de amostra (com uma mensagem
mínima, para medir só o consumo de tokens de entrada), então usa poucos
textos — o suficiente para calibrar, não uma amostra representativa de
todo o corpus.

## Examples

``` r
if (FALSE) { # \dontrun{
chat_factory <- function(temperature, system_prompt) {
  ellmer::chat_openai(model = "gpt-4.1-mini", temperature = temperature,
                      system_prompt = system_prompt, echo = "none")
}
razao <- ac_calibrate_tokens(chat_factory, c("texto curto de teste.",
                                             "um texto um pouco mais longo de teste."))
coded <- ac_qual_code(corpus, cb, model = chat_factory)
} # }
```
