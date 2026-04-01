# Parte 5: Regressão Linear - Modelo de Precificação de Ativos (CAPM)

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Author](https://img.shields.io/badge/Author-Ivan%20Santos-blue)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

## 👤 Autor

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

## 🎯 Objetivo

Estimar o **Beta (β)** de um ativo em relação ao mercado (Ibovespa) utilizando regressão linear, fundamentando a análise no Capital Asset Pricing Model (CAPM).

## 📚 Fundamentação Teórica

### Capital Asset Pricing Model (CAPM)

O CAPM estabelece que o retorno esperado de um ativo é função do retorno livre de risco mais um prêmio de risco ajustado pelo beta do ativo:

```
E(Ri) = Rf + βi × [E(Rm) - Rf]
```

### Modelo de Regressão

```
Ri - Rf = α + β × (Rm - Rf) + ε
```

Onde:
- **Ri**: Retorno do ativo i
- **Rf**: Taxa livre de risco (Selic/CDI)
- **Rm**: Retorno do mercado (Ibovespa)
- **β**: Beta - risco sistemático do ativo
- **α**: Alfa - retorno anormal do ativo
- **ε**: Erro aleatório

### Interpretação do Beta

| β | Classificação | Significado |
|---|---------------|-------------|
| β > 1 | Agressivo | Mais volátil que o mercado |
| β = 1 | Neutro | Mesma volatilidade do mercado |
| 0 < β < 1 | Defensivo | Menos volátil que o mercado |
| β < 0 | Hedge | Move-se na direção oposta |

---

## 📊 Ativos Analisados

| Ticker | Nome | Classe |
|--------|------|--------|
| WEGE3 | WEG S.A. | Ação Brasileira |
| ^BVSP | Ibovespa | Índice de Mercado |

---

## 🔬 Metodologia

### 1. Coleta de Dados
- **Ativo:** WEGE3 (retornos da Parte 1)
- **Mercado:** Ibovespa (^BVSP) via yfR
- **Período:** 2024-01-01 a 2026-03-20

### 2. Taxa Livre de Risco
- Selic anual: 10.5%
- Taxa diária: (1 + 0.105)^(1/252) - 1 = 0.0396%

### 3. Modelo de Regressão
```
modelo_capm <- lm(excesso_ativo ~ excesso_mercado, data = dados_regressao)
```

### 4. Diagnóstico do Modelo
- **Durbin-Watson:** Teste de autocorrelação dos resíduos
- **Breusch-Pagan:** Teste de heterocedasticidade
- **RESET:** Teste de especificação do modelo
- **Shapiro-Wilk:** Teste de normalidade dos resíduos

### 5. Erros Robustos (White)
Correção para possíveis heterocedasticidades nos resíduos.

### 6. Bootstrap do Beta
Reamostragem para intervalos de confiança robustos.

---

## 📈 Resultados

### Estatísticas Descritivas

| Métrica | WEGE3 | Ibovespa |
|---------|-------|----------|
| Retorno médio diário | 0.0566% | 0.0554% |
| Volatilidade diária | 1.79% | 1.17% |
| Correlação | 0.3062 | - |

### Modelo CAPM

| Coeficiente | Estimativa | Erro Padrão | t-valor | p-valor |
|-------------|------------|-------------|---------|---------|
| **Alfa (α)** | 0.000078 | 0.000727 | 0.107 | 0.915 |
| **Beta (β)** | **0.5867** | 0.0777 | 7.55 | < 0.001 |

### Métricas de Qualidade

| Métrica | Valor | Interpretação |
|---------|-------|---------------|
| **R²** | 9.38% | 9.38% da variância explicada |
| **R² Ajustado** | 9.21% | - |
| **F-statistic** | 57.0 | p < 0.001 |
| **AIC** | -2782.5 | - |
| **BIC** | -2773.9 | - |

### Intervalo de Confiança (95%)

| Coeficiente | IC Inferior | IC Superior |
|-------------|-------------|-------------|
| **Beta** | 0.4341 | 0.7394 |

### Erros Robustos (White)

| Coeficiente | Estimativa | Erro Robusto | t-valor | p-valor |
|-------------|------------|--------------|---------|---------|
| Alfa | 0.000078 | 0.000726 | 0.107 | 0.915 |
| Beta | 0.5867 | 0.0939 | 6.248 | < 0.001 |

### Bootstrap do Beta (10.000 reamostragens)

| Métrica | Valor |
|---------|-------|
| Beta estimado | 0.5867 |
| Beta bootstrap | 0.5885 |
| Erro padrão bootstrap | 0.0938 |
| IC 95% bootstrap | [0.4009, 0.7697] |

### Diagnóstico do Modelo

| Teste | Estatística | p-valor | Conclusão |
|-------|-------------|---------|-----------|
| **Durbin-Watson** | d = 2.0618 | 0.7671 | ✅ Sem autocorrelação |
| **Breusch-Pagan** | BP = 0.4909 | 0.4835 | ✅ Homocedasticidade |
| **RESET** | F = 2.9329 | 0.0541 | ✅ Bem especificado |
| **Shapiro-Wilk** | W = 0.8855 | < 0.001 | ⚠ Não normais |

---

## 📊 Visualizações Geradas

| Arquivo | Descrição |
|---------|-----------|
| `01_dispersao.png` | Gráfico de dispersão com reta de regressão |
| `02_serie_temporal.png` | Série temporal dos retornos |
| `03_diagnostico_padrao.png` | 4 gráficos de diagnóstico (R base) |
| `04_residuos_ajustados.png` | Resíduos vs valores ajustados |
| `05_qqplot_residuos.png` | Q-Q Plot dos resíduos |
| `06_histograma_residuos.png` | Histograma dos resíduos |
| `07_bootstrap_beta.png` | Distribuição bootstrap do Beta |

---

## 🎯 Conclusões

### Principais Descobertas

1. **Beta = 0.5867**: A WEGE3 é um ativo **DEFENSIVO**, 41.3% menos volátil que o mercado
2. **Alfa positivo**: Pequeno retorno anormal acima do esperado pelo CAPM
3. **R² baixo (9.38%)**: Apenas 9% da variância é explicada pelo mercado
4. **Modelo estatisticamente significativo**: p-valor do Beta < 0.001
5. **Bootstrap robusto**: IC 95%: [0.40, 0.77] confirma a estimativa

### Implicações Práticas

- **Para o Investidor**: WEGE3 oferece proteção em momentos de queda do mercado
- **Para Carteira**: Atua como diversificador, reduzindo o risco total
- **Para Precificação**: Beta inferior a 1 indica menor custo de capital

---

## 📁 Estrutura de Arquivos

```
Parte_05_Regressao_Linear_CAPM/
├── codigo_parte5.R          # Código completo da análise
├── README.md                # Esta documentação
├── graficos/                # Gráficos gerados
│   ├── 01_dispersao.png
│   ├── 02_serie_temporal.png
│   ├── 03_diagnostico_padrao.png
│   ├── 04_residuos_ajustados.png
│   ├── 05_qqplot_residuos.png
│   ├── 06_histograma_residuos.png
│   └── 07_bootstrap_beta.png
└── resultados/              # Resultados exportados
    ├── coeficientes_capm.csv
    ├── metricas_modelo.csv
    ├── diagnostico_modelo.csv
    ├── bootstrap_beta.csv
    └── resultados_parte5.rds
```

---

## 🚀 Como Executar

### Pré-requisitos
```
# Certifique-se de ter a Parte 1 concluída
# Os retornos históricos são carregados automaticamente
```

### Execução
```
# Fonte o código completo
source("Parte_05_Regressao_Linear_CAPM/codigo_parte5.R")
```

---

## 📚 Referências

- **Sharpe, W. F. (1964).** Capital asset prices: A theory of market equilibrium under conditions of risk. *The Journal of Finance*.
- **Lintner, J. (1965).** The valuation of risk assets and the selection of risky investments in stock portfolios and capital budgets. *The Review of Economics and Statistics*.
- **Black, F. (1972).** Capital market equilibrium with restricted borrowing. *The Journal of Business*.
- **White, H. (1980).** A heteroskedasticity-consistent covariance matrix estimator and a direct test for heteroskedasticity. *Econometrica*.

---

## 🎯 Próximas Partes

- **Parte 6:** GLM e Séries Temporais (ARIMA)

---

## 📫 Contato

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

⬅️ [Voltar para Parte 4](../Parte_04_ANOVA_QuiQuadrado/) | [Voltar ao README Principal](../README.md) | ➡️ [Ir para Parte 6](../Parte_06_GLM_Series_Temporais/)
