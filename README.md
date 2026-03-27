# Parte 1: Prova da Não-Normalidade dos Retornos Financeiros

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Author](https://img.shields.io/badge/Author-Ivan%20Santos-blue)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

## 👤 Autor

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

## 🎯 Objetivo

Demonstrar estatisticamente que os retornos de ativos financeiros **NÃO seguem uma distribuição normal**, contrariando uma das premissas básicas da teoria financeira clássica (Random Walk Hypothesis).

## 📚 Fundamentação Teórica

A hipótese de normalidade dos retornos é fundamental para:
- Modelo de Precificação de Ativos (CAPM)
- Teoria Moderna de Portfólio (Markowitz)
- Cálculo de Value at Risk (VaR) paramétrico
- Testes de hipótese em regressões financeiras

**Evidências empíricas** (Mandelbrot, 1963; Fama, 1965) mostram que:
- Retornos financeiros apresentam caudas pesadas (leptocurtose)
- Distribuição não é normal, mas sim estável ou com caudas de potência
- Eventos extremos ocorrem com maior frequência que o previsto pela normal

## 🧪 Hipóteses Testadas

```
H₀: Os retornos seguem distribuição normal
H₁: Os retornos NÃO seguem distribuição normal
```

## 📊 Ativos Analisados

| Ticker | Nome | Classe | Fonte |
|--------|------|--------|-------|
| WEGE3 | WEG S.A. | Ação Brasileira | Yahoo Finance (yfR) |
| HGLG11 | CSHG Logística FII | Fundo Imobiliário | Yahoo Finance (yfR) |
| BTC-USD | Bitcoin | Criptomoeda | Yahoo Finance (yfR) |

## 📈 Período de Análise

- **Data inicial:** 2024-01-01
- **Data final:** 2026-03-20
- **Total de dias úteis:** ~550 por ativo

---

## 🔬 Metodologia

### 1. Coleta de Dados
Utilização do pacote `yfR` para coleta de dados do Yahoo Finance, com sistema de cache para eficiência.

### 2. Cálculo dos Retornos
```r
retorno_log = log(P_t / P_{t-1})
```

### 3. Análise de Momentos
- **Assimetria (Skewness):** Mede a inclinação da distribuição
- **Curtose (Kurtosis):** Mede o peso das caudas
- **Excesso de Curtose:** Curtose - 3 (excesso em relação à normal)

### 4. Testes de Normalidade

| Teste | Descrição |
|-------|-----------|
| **Shapiro-Wilk** | Teste de normalidade mais poderoso |
| **Jarque-Bera** | Baseado em assimetria e curtose |
| **Anderson-Darling** | Sensível às caudas da distribuição |

---

## 📊 Resultados

### Momentos Estatísticos

| Ativo | Assimetria | Curtose | Excesso | Dias Positivos |
|-------|------------|---------|---------|----------------|
| **WEGE3** | -0.78 | 8.14 | 5.14 | 50.8% |
| **HGLG11** | +0.73 | 7.03 | 4.03 | 50.3% |
| **BTC-USD** | +0.09 | 3.44 | 0.44 | 50.4% |

### Testes de Normalidade

| Ativo | Shapiro-Wilk | Jarque-Bera | Anderson-Darling | Conclusão |
|-------|--------------|-------------|------------------|-----------|
| **WEGE3** | p = 1.24e-17 ❌ | p = 5.21e-145 ❌ | p = 9.70e-18 ❌ | Rejeita H₀ |
| **HGLG11** | p = 6.27e-16 ❌ | p = 1.19e-92 ❌ | p = 1.36e-21 ❌ | Rejeita H₀ |
| **BTC-USD** | p = 2.11e-14 ❌ | p = 2.29e-02 ❌ | p = 6.14e-19 ❌ | Rejeita H₀ |

### Interpretação dos Resultados

**WEGE3 (Ação Brasileira)**
- Assimetria negativa (-0.78) → maior probabilidade de quedas bruscas
- Curtose elevada (8.14) → caudas muito pesadas
- Risco de eventos extremos significativo

**HGLG11 (Fundo Imobiliário)**
- Assimetria positiva (0.73) → chance de ganhos excepcionais
- Curtose elevada (7.03) → caudas pesadas para um FII
- Menor volatilidade entre os ativos

**BTC-USD (Bitcoin)**
- Assimetria próxima de zero (0.09) → distribuição mais simétrica
- Curtose moderada (3.44) → mais próxima da normal
- Maior volatilidade entre os ativos

---

## 📊 Visualizações Geradas

| Arquivo | Descrição |
|---------|-----------|
| `01_qqplot_*.png` | Q-Q Plot com envelope de confiança 95% |
| `02_histograma_*.png` | Histograma com curva normal sobreposta |
| `03_boxplots_comparativos.png` | Boxplots comparativos dos 3 ativos |
| `04_pvalores_testes.png` | Gráfico de barras dos p-valores |

---

## 🎯 Conclusão

**❌ TODOS os ativos rejeitam a hipótese de normalidade (p < 0.05)**

- Retornos financeiros **NÃO seguem distribuição normal**
- Modelos baseados na normalidade (CAPM, VaR paramétrico) devem ser usados com cautela
- Recomendado usar modelos que consideram caudas pesadas (t-Student, GARCH)

---

## 📁 Estrutura de Arquivos

```
Parte_01_Prova_Nao_Normalidade/
├── codigo_parte1.R          # Código completo da análise
├── README.md                # Esta documentação
├── graficos/                # Gráficos gerados
│   ├── 01_qqplot_WEGE3.png
│   ├── 01_qqplot_HGLG11.png
│   ├── 01_qqplot_BTC_USD.png
│   ├── 02_histograma_WEGE3.png
│   ├── 02_histograma_HGLG11.png
│   ├── 02_histograma_BTC_USD.png
│   ├── 03_boxplots_comparativos.png
│   └── 04_pvalores_testes.png
└── resultados/              # Resultados exportados
    ├── retornos_calculados.csv
    ├── momentos_estatisticos.csv
    ├── testes_normalidade.csv
    └── resultados_parte1.rds
```

---

## 🚀 Como Executar

### Pré-requisitos
```r
install.packages(c("yfR", "dplyr", "moments", "nortest", "car", "ggplot2"))
```

### Execução
```r
# Fonte o código completo
source("Parte_01_Prova_Nao_Normalidade/codigo_parte1.R")
```

---

## 📚 Referências

- **Mandelbrot, B. (1963).** The Variation of Certain Speculative Prices. *The Journal of Business*, 36(4), 394-419.
- **Fama, E. (1965).** The Behavior of Stock-Market Prices. *The Journal of Business*, 38(1), 34-105.
- **Cont, R. (2001).** Empirical properties of asset returns: stylized facts and statistical issues. *Quantitative Finance*, 1(2), 223-236.
- **Jarque, C. & Bera, A. (1980).** Efficient tests for normality, homoscedasticity and serial independence of regression residuals. *Economics Letters*, 6(3), 255-259.

---

## 🎯 Próximas Partes

- **Parte 2:** Simulação de Monte Carlo e Análise de Risco
- **Parte 3:** Inferência Estatística e Testes de Hipóteses
- **Parte 4:** ANOVA e Análise de Associação (Qui-Quadrado)
- **Parte 5:** Regressão Linear - Modelo CAPM
- **Parte 6:** GLM e Séries Temporais (ARIMA)

---

## 📫 Contato

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

⬅️ [Voltar ao README Principal](../README.md) | ➡️ [Ir para Parte 2](../Parte_02_Simulacao_Monte_Carlo/)
