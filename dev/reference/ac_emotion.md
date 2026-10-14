# Classificar emoções com um léxico de palavra-emoção

`ac_emotion()` conta, por documento, quantas palavras caem em cada
categoria de emoção de um léxico fornecido pelo usuário — indo além da
polaridade binária de
[`ac_sentiment()`](https://ahenriquecp.com/acR/dev/reference/ac_sentiment.md)
para distinguir, por exemplo, se um texto negativo expressa raiva, medo
ou tristeza (Mohammad & Turney, 2013, propuseram essa distinção no NRC
Emotion Lexicon, hoje o léxico de emoções mais usado em inglês).

O pacote **não distribui** um léxico de emoções em português: o NRC
Emotion Lexicon original é em inglês e sua tradução/adaptação para
português está sujeita aos termos de licença do léxico de origem, que o
usuário deve obter e licenciar por conta própria (o NRC é gratuito para
pesquisa, mas não redistribuível livremente dentro de outro pacote).
`ac_emotion()` é agnóstica ao léxico: funciona com qualquer tabela
palavra→emoção que você tenha — o NRC traduzido, um léxico doméstico, ou
uma lista construída à mão para um domínio específico (ex.: emoções em
avaliações de atendimento ao cliente).

Internamente, é uma camada sobre
[`ac_dictionary()`](https://ahenriquecp.com/acR/dev/reference/ac_dictionary.md):
converte o léxico em formato longo (uma linha por palavra-emoção) para o
formato de dicionário multi-categoria e aplica a mesma contagem.

## Usage

``` r
ac_emotion(
  corpus,
  lexicon,
  term_col = "termo",
  emotion_col = "emocao",
  by = NULL
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- lexicon:

  Tibble/data.frame em formato longo com colunas de palavra e emoção
  (ver `term_col`/`emotion_col`). Uma palavra pode aparecer em mais de
  uma linha (associada a mais de uma emoção).

- term_col:

  Nome da coluna de palavra em `lexicon`. Padrão: `"termo"`.

- emotion_col:

  Nome da coluna de emoção em `lexicon`. Padrão: `"emocao"`.

- by:

  Coluna(s) de agrupamento adicional. Padrão: `NULL`.

## Value

Tibble no mesmo formato de
[`ac_dictionary()`](https://ahenriquecp.com/acR/dev/reference/ac_dictionary.md):
`total_tokens` e, para cada emoção presente em `lexicon`, colunas
`<emocao>_n` e `<emocao>_prop`.

## References

Mohammad, S. M.; Turney, P. D. (2013). Crowdsourcing a Word-Emotion
Association Lexicon. *Computational Intelligence*, 29(3), 436-465.

## See also

[`ac_dictionary()`](https://ahenriquecp.com/acR/dev/reference/ac_dictionary.md),
[`ac_sentiment()`](https://ahenriquecp.com/acR/dev/reference/ac_sentiment.md)

## Examples

``` r
# Lexico de emocao minimo, construido a mao para este exemplo
# (em uso real, substitua por um lexico de emocoes licenciado em PT)
lexico <- data.frame(
  termo  = c("alegria", "feliz", "medo", "assustado", "raiva", "furioso"),
  emocao = c("alegria", "alegria", "medo", "medo", "raiva", "raiva"),
  stringsAsFactors = FALSE
)

df <- data.frame(
  id = paste0("d", 1:3),
  texto = c(
    "fiquei muito feliz com a alegria do momento",
    "fiquei assustado, senti muito medo da situacao",
    "fiquei furioso, aquela raiva nao passava"
  ),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)

ac_emotion(corpus, lexicon = lexico)
#> # A tibble: 3 × 8
#>   doc_id total_tokens alegria_n medo_n raiva_n alegria_prop medo_prop raiva_prop
#>   <chr>         <int>     <int>  <int>   <int>        <dbl>     <dbl>      <dbl>
#> 1 d1                8         2      0       0         0.25     0          0    
#> 2 d2                7         0      1       0         0        0.143      0    
#> 3 d3                6         0      0       1         0        0          0.167
```
