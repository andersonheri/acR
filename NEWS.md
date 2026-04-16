# acR 0.0.0.9001

* Versão inicial em desenvolvimento.
* Estrutura do pacote criada.
* Decisões arquiteturais documentadas em `inst/docs/adr/0001-decisoes-iniciais-acR.md`.



# acR 0.0.0.9001

- Adiciona função `ac_clean()` para limpeza de textos em português:
  - pipeline com ordem fixa (lower, remoção de URL/e-mail, `normalize_pt`, stopwords, pontuação, números, símbolos, acentos, espaços);
  - presets de stopwords (`"pt"`, `"pt-br-extended"`, `"pt-legislativo"`);
  - mecanismo de proteção de termos (`protect`) para siglas como partidos e cortes;
  - registro de etapas aplicadas no atributo `cleaning_steps`.
- Inclui conjunto de testes unitários abrangentes para `ac_clean()`.
- Estrutura interna de stopwords (`.ac_get_stopwords()`) e normalização coloquial (`.ac_normalize_pt()`).



# acR 0.0.0.9001

- Adiciona `ac_clean()` para limpeza de textos em português, com pipeline configurável,
  presets de stopwords e registro de etapas aplicadas.
- Adiciona `ac_tokenize()` para tokenizar objetos `ac_corpus` em palavras, retornando
  tibble tidy com colunas `doc_id`, `token_id` e `token`.
