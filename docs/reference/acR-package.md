# acR: Análise de Conteúdo em R

Pipeline integrado de análise de conteúdo em R, combinando codificação
qualitativa assistida por modelos de linguagem (LLMs) com análise
quantitativa clássica de textos. Foco em corpora brasileiros, com
codebooks validados, métricas de confiabilidade entre codificadores, e
visualizações modernas baseadas em ggplot2.

## Details

O pacote organiza-se em três camadas:

1.  **Pré-processamento**: construção de corpus, limpeza, tokenização,
    lematização (via udpipe), stopwords PT-BR expandidas.

2.  **Análise**:

    - *Quantitativa*: descritivos, keyness, co-ocorrência, sentimento
      (OpLexicon), LDA com seleção e validação de tópicos.

    - *Qualitativa*: codificação automatizada via LLMs (`ellmer`),
      codebooks versionados, confiabilidade entre humano e LLM
      (Krippendorff alpha, Gwet AC1), calibração de incerteza.

3.  **Visualização**: tema próprio, paletas acessíveis, gráficos
    publicáveis (nuvens, X-ray, redes de co-ocorrência, mapas via
    geobr).

Para começar, veja `vignette("acR")`.

## Inspiração

O `acR` reconhece dívida intelectual com `quallmer` (Maerz & Benoit,
2025), `quanteda` (Benoit et al.), e `ellmer` (Wickham et al., Posit).
Ver decisões arquiteturais em
<https://github.com/andersonheri/acR/tree/main/inst/docs/adr>.

## See also

Useful links:

- <https://github.com/andersonheri/acR>

- <https://andersonheri.github.io/acR/>

- Report bugs at <https://github.com/andersonheri/acR/issues>

## Author

**Maintainer**: Anderson Henrique <anderson.henrique@usp.br>
([ORCID](https://orcid.org/0000-0002-1842-2725)) (Centro de Estudos da
Metropole (CEM-Cepid) - Universidade de Sao Paulo)
