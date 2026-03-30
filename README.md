# 📊 Estatística Aplicada em R - Análise Completa de Ativos Financeiros

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Author](https://img.shields.io/badge/Author-Ivan%20Santos-blue)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

## 👤 Autor

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

## 🎯 Sobre o Projeto

Este projeto é uma jornada completa pela **Estatística Aplicada em R**, utilizando dados reais de ativos financeiros (ações, fundos imobiliários e criptomoedas) para demonstrar conceitos fundamentais de análise estatística, modelagem e previsão.

O objetivo é demonstrar, na prática, como a estatística pode ser aplicada para:
- 📈 Analisar o comportamento de ativos financeiros
- 🔬 Testar hipóteses e validar pressupostos
- 🎲 Simular cenários futuros via Monte Carlo
- 📊 Modelar riscos e retornos
- 🔮 Prever comportamentos futuros

---

## 🗂️ Estrutura do Projeto

```
Estatistica-Aplicada-R/
├── Parte_01_Prova_Nao_Normalidade/     # Prova empírica da não-normalidade
├── Parte_02_Simulacao_Monte_Carlo/     # Análise de risco e simulações
├── Parte_03_Inferencia_Estatistica/    # Testes de hipóteses e bootstrap
├── Parte_04_ANOVA_QuiQuadrado/         # Análise de variância e associação
├── Parte_05_Regressao_Linear_CAPM/     # Modelagem CAPM e diagnóstico
├── Parte_06_GLM_Series_Temporais/      # GLM e previsão ARIMA
├── data/                               # Dados brutos (opcional)
├── resultados/                         # Resultados exportados
└── graficos/                           # Visualizações geradas
```

---

## 📚 Conteúdo por Parte

### [Parte 1: Prova da Não-Normalidade dos Retornos](Parte_01_Prova_Nao_Normalidade/)
**Conceitos:** Distribuições, assimetria, curtose, testes de normalidade

Demonstra estatisticamente que retornos financeiros não seguem distribuição normal:
- ✅ Coleta de dados de múltiplas fontes (B3 e Yahoo Finance)
- ✅ Cálculo de retornos logarítmicos
- ✅ Análise de assimetria e curtose
- ✅ Aplicação de testes: Shapiro-Wilk, Jarque-Bera, Anderson-Darling
- ✅ Visualizações: QQ-Plots, histogramas, análise de caudas

**Resultados:** Todos os ativos rejeitam a hipótese de normalidade (p < 0.05)

---

### [Parte 2: Simulação de Monte Carlo](Parte_02_Simulacao_Monte_Carlo/)
**Conceitos:** Bootstrap, Value at Risk (VaR), Expected Shortfall (CVaR)

Estima a distribuição de probabilidade do patrimônio futuro:
- ✅ Reamostragem com bootstrap de retornos históricos
- ✅ Simulação de 10.000+ cenários futuros
- ✅ Cálculo de VaR e CVaR em múltiplos níveis de confiança
- ✅ Análise de drawdown máximo
- ✅ Probabilidade de atingir metas específicas

**Resultados:** 69.4% chance de lucro, VaR 95%: R$ 7.150, drawdown médio: 23.8%

---

### [Parte 3: Inferência Estatística](Parte_03_Inferencia_Estatistica/)
**Conceitos:** Testes paramétricos e não-paramétricos, bootstrap, intervalos de confiança

Compara distribuições e estima parâmetros populacionais:
- ✅ Teste t de Student (paramétrico)
- ✅ Teste de Wilcoxon-Mann-Whitney (não-paramétrico)
- ✅ Teste de Kolmogorov-Smirnov
- ✅ Bootstrap para intervalos de confiança
- ✅ Tamanho de efeito (Cohen's d, Cliff's Delta)

**Resultados:** Não há diferença significativa entre os ativos (p > 0.05), tamanho do efeito desprezível

---

### [Parte 4: ANOVA e Qui-Quadrado](Parte_04_ANOVA_QuiQuadrado/)
**Conceitos:** Análise de variância, tabelas de contingência, medidas de associação

Analisa diferenças entre grupos e associação entre variáveis:
- ✅ ANOVA clássica e robusta (Welch)
- ✅ Teste post-hoc de Tukey HSD
- ✅ Teste de Kruskal-Wallis (não-paramétrico)
- ✅ Teste Qui-Quadrado de independência
- ✅ V de Cramér e medidas de associação

---

### [Parte 5: Regressão Linear - CAPM](Parte_05_Regressao_Linear_CAPM/)
**Conceitos:** Modelo de precificação, diagnóstico de regressão, erros robustos

Estima o Beta de um ativo em relação ao mercado:
- ✅ Modelo CAPM (Capital Asset Pricing Model)
- ✅ Cálculo de Beta e Alfa
- ✅ Diagnóstico completo de resíduos
- ✅ Testes de autocorrelação (Durbin-Watson)
- ✅ Testes de heterocedasticidade (Breusch-Pagan)

---

### [Parte 6: GLM e Séries Temporais](Parte_06_GLM_Series_Temporais/)
**Conceitos:** Regressão logística, ARIMA, previsão de séries

Modela eventos extremos e prevê retornos futuros:
- ✅ Regressão Logística para previsão de crises
- ✅ Interpretação via Odds Ratio
- ✅ Curva ROC e AUC
- ✅ Modelos ARIMA (Auto-Regressive Integrated Moving Average)
- ✅ Previsões com intervalos de confiança

---

## 🛠️ Tecnologias Utilizadas

| Categoria | Pacotes R |
|-----------|-----------|
| **Coleta de Dados** | `rb3` (B3 oficial), `yfR` (Yahoo Finance) |
| **Manipulação** | `tidyverse`, `dplyr`, `tidyr`, `lubridate` |
| **Estatística** | `moments`, `nortest`, `car`, `lmtest` |
| **Simulação** | `boot`, `forecast` |
| **Visualização** | `ggplot2`, `ggcorrplot`, `corrplot` |
| **Modelagem** | `broom`, `performance`, `sandwich` |

---

## 🚀 Como Executar

### Pré-requisitos
```
# Instalar R (versão 4.0 ou superior)
# https://cran.r-project.org/

# Instalar RStudio (recomendado)
# https://posit.co/download/rstudio-desktop/
```

### Execução
```
# Execute cada parte sequencialmente
source("Parte_01_Prova_Nao_Normalidade/codigo_parte1.R")
source("Parte_02_Simulacao_Monte_Carlo/codigo_parte2.R")
source("Parte_03_Inferencia_Estatistica/codigo_parte3.R")
# ... e assim por diante
```

---

## 📈 Resultados Principais

### Parte 1: Prova da Não-Normalidade
- **Conclusão**: Todos os ativos rejeitam a hipótese de normalidade (p < 0.05)
- **Curtose**: WEGE3 (8.14), HGLG11 (7.03), BTC-USD (3.44)
- **Assimetria**: WEGE3 (-0.78), HGLG11 (0.73), BTC-USD (0.09)

### Parte 2: Simulação de Monte Carlo (WEGE3)
- **Probabilidade de lucro**: 69.4%
- **Retorno esperado**: 19.9% ao ano
- **VaR 95%**: R$ 7.150 (perda máxima esperada)
- **Drawdown médio**: 23.8%

### Parte 3: Inferência Estatística
- **Conclusão**: Não há diferença significativa entre os ativos (p > 0.05)
- **Tamanho do efeito**: Desprezível (Cohen's d < 0.2)

---

## 📚 Referências

- **Mandelbrot, B. (1963).** The Variation of Certain Speculative Prices.
- **Fama, E. (1965).** The Behavior of Stock-Market Prices.
- **Hull, J. (2018).** Risk Management and Financial Institutions.
- **Jorion, P. (2006).** Value at Risk: The New Benchmark.

---

## 📫 Contato

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!