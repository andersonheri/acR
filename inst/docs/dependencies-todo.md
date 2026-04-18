# Dependências adiadas

Pacotes removidos temporariamente do `DESCRIPTION` por causarem falha no CI
(GitHub Actions / pak). Adicionar de volta quando o código que os utiliza for
implementado:

| Pacote | Categoria | Função planejada | Quando reintroduzir |
|--------|-----------|------------------|---------------------|
| `irrCAC` | Suggests | `ac_qual_reliability()` (Krippendorff α, Gwet AC1) | Fase 7 do roadmap |
| `ldatuning` | Suggests | `ac_quant_lda_tune()` (seleção de k em LDA) | Fase 5 do roadmap |

Referências:

- irrCAC: Gwet, K. L. (2014). *Handbook of Inter-Rater Reliability*, 4th ed.
- ldatuning: Murzintcev, N. (2020). *Select number of topics for LDA model*. 
  https://cran.r-project.org/package=ldatuning

Quando reintroduzir, considerar:

1. Adicionar via `desc::desc()$set_dep()` em vez de editar manualmente
2. Testar localmente com `devtools::check()` antes do push
3. Verificar se o `pak` consegue resolver a dependência no CI
