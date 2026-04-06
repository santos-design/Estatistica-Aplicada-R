# Parte 6: Modelos Lineares Generalizados (GLM) e Séries Temporais (ARIMA)

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Author](https://img.shields.io/badge/Author-Ivan%20Santos-blue)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

## 👤 Autor

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

## 🎯 Objetivo

Aplicar modelos avançados de previsão e classificação:
1. **Regressão Logística** para prever eventos extremos (crises) na WEGE3
2. **Modelos ARIMA** para previsão de séries temporais de retornos do Bitcoin

## 📚 Fundamentação Teórica

### Regressão Logística
Modelo da família GLM para variáveis resposta binárias. Modela a probabilidade de ocorrência de um evento usando a função logit.

```
logit(p) = ln(p/(1-p)) = β0 + β1X1 + ... + βkXk
```

### Odds Ratio
Medida de associação entre preditor e resposta. OR > 1 indica aumento na chance; OR < 1 indica diminuição.

### Curva ROC e AUC
- **ROC (Receiver Operating Characteristic)**: Gráfico da sensibilidade vs 1-especificidade
- **AUC (Area Under the Curve)**: Medida de poder discriminatório do modelo
  - AUC > 0.9: Excelente
  - AUC > 0.8: Bom
  - AUC > 0.7: Razoável
  - AUC > 0.6: Fraco

### Modelos ARIMA
Modelos para previsão de séries temporais que combinam:
- **AR(p)**: Componente autoregressiva (dependência com valores passados)
- **I(d)**: Integração (diferenciação para tornar série estacionária)
- **MA(q)**: Média móvel (dependência com erros passados)

### Teste de Estacionariedade (ADF)
Verifica se a série tem média e variância constantes no tempo. H₀: Série não é estacionária.

---

## 🧪 Hipóteses Testadas

### Regressão Logística
```
H₀: O retorno do mercado não afeta a probabilidade de crise na WEGE3
H₁: O retorno do mercado afeta a probabilidade de crise na WEGE3
```

### Modelo ARIMA
```
H₀: A série não é estacionária (tem raiz unitária)
H₁: A série é estacionária
```

---

## 📊 Ativos Analisados

| Modelo | Ativo | Tipo | Nº Observações |
|--------|-------|------|----------------|
| Regressão Logística | WEGE3 | Ação Brasileira | 553 |
| ARIMA | BTC-USD | Criptomoeda | 809 |

---

## 📈 Resultados

### Regressão Logística

#### Distribuição do Evento de Crise
| Evento | Frequência | Percentual |
|--------|------------|------------|
| Dias com crise (retorno < -2%) | 43 | 7.78% |
| Dias sem crise | 510 | 92.22% |

#### Coeficientes do Modelo
| Variável | Coeficiente | Erro Padrão | z-value | p-valor |
|----------|-------------|-------------|---------|---------|
| Intercepto | -2.570 | 0.172 | -14.93 | < 0.001 |
| retorno_mercado_pct | -0.593 | 0.163 | -3.64 | < 0.001 |

#### Odds Ratio
| Variável | Odds Ratio | Interpretação |
|----------|------------|---------------|
| retorno_mercado_pct | 0.5524 | Queda de 1% no Ibovespa reduz a chance de crise em 44.8% |

#### Matriz de Confusão (Threshold = 0.5)
| | Predito 0 (Não Crise) | Predito 1 (Crise) |
|---|----------------------|-------------------|
| **Real 0 (Não Crise)** | 509 | 1 |
| **Real 1 (Crise)** | 43 | 0 |

#### Métricas de Classificação
| Métrica | Valor | Interpretação |
|---------|-------|---------------|
| **Acurácia** | 92.04% | Modelo acerta 92% das previsões |
| **AUC** | 0.6584 | Poder discriminatório razoável |

---

### Modelo ARIMA (Bitcoin)

#### Teste de Estacionariedade (ADF)
| Estatística | p-valor | Conclusão |
|-------------|---------|-----------|
| DF = -9.84 | 0.01 | ✓ Série estacionária |

#### Modelo Selecionado
| Parâmetro | Valor |
|-----------|-------|
| **Ordem** | ARIMA(3, 0, 2) |
| **AIC** | -3621.24 |
| **AICc** | -3621.14 |
| **BIC** | -3593.07 |

#### Coeficientes do Modelo
| Coeficiente | Valor | Erro Padrão |
|-------------|-------|-------------|
| ar1 | -1.056 | 0.065 |
| ar2 | -0.975 | 0.077 |
| ar3 | -0.098 | 0.037 |
| ma1 | 0.986 | 0.056 |
| ma2 | 0.919 | 0.057 |

#### Previsões para os Próximos 10 Dias
| Dia | Previsão | IC 80% | IC 95% |
|-----|----------|--------|--------|
| 1 | -0.137% | [-3.43%, 3.16%] | [-5.17%, 4.90%] |
| 2 | 0.003% | [-3.30%, 3.30%] | [-5.05%, 5.05%] |
| 3 | 0.045% | [-3.26%, 3.35%] | [-5.00%, 5.09%] |
| 4 | -0.037% | [-3.34%, 3.27%] | [-5.09%, 5.02%] |
| 5 | -0.005% | [-3.31%, 3.30%] | [-5.06%, 5.05%] |
| 6 | 0.037% | [-3.27%, 3.35%] | [-5.02%, 5.10%] |
| 7 | -0.031% | [-3.34%, 3.28%] | [-5.09%, 5.03%] |
| 8 | -0.004% | [-3.32%, 3.31%] | [-5.07%, 5.06%] |
| 9 | 0.030% | [-3.28%, 3.34%] | [-5.04%, 5.10%] |
| 10 | -0.025% | [-3.34%, 3.29%] | [-5.09%, 5.04%] |

**Retorno acumulado esperado em 10 dias: -0.1233%**

---

## 📊 Visualizações Geradas

| Arquivo | Descrição |
|---------|-----------|
| `01_curva_roc.png` | Curva ROC com AUC = 0.6584 |
| `02_previsoes_arima.png` | Previsões ARIMA com intervalos de confiança |
| `03_serie_temporal.png` | Série temporal dos retornos do Bitcoin |

---

## 🎯 Conclusões

### Principais Descobertas

1. **Regressão Logística**: 
   - Odds Ratio de 0.5524 indica que a WEGE3 tem comportamento defensivo
   - Quando o mercado cai, a chance de crise na WEGE3 DIMINUI
   - Confirma o Beta defensivo (0.5867) encontrado na Parte 5

2. **Modelo ARIMA**:
   - ARIMA(3,0,2) é o melhor modelo para os retornos do Bitcoin
   - Série é estacionária (não precisa diferenciar)
   - Previsão ligeiramente negativa para os próximos 10 dias

3. **Incerteza nas Previsões**:
   - Intervalos de confiança amplos indicam alta incerteza
   - Retornos financeiros são difíceis de prever com precisão

### Implicações Práticas

- **WEGE3**: Atua como proteção em momentos de queda do mercado
- **Bitcoin**: Previsões de curto prazo têm alta incerteza
- **Gestão de Risco**: Modelos logísticos podem auxiliar na identificação de crises

---

## 📁 Estrutura de Arquivos

```
Parte_06_GLM_Series_Temporais/
├── codigo_parte6.R          # Código completo da análise
├── README.md                # Esta documentação
├── graficos/                # Gráficos gerados
│   ├── 01_curva_roc.png
│   ├── 02_previsoes_arima.png
│   └── 03_serie_temporal.png
└── resultados/              # Resultados exportados
    ├── coeficientes_logistico.csv
    ├── metricas_classificacao.csv
    ├── coeficientes_arima.csv
    ├── previsoes_arima.csv
    └── resultados_parte6.rds
```

---

## 🚀 Como Executar

### Pré-requisitos
```
# Certifique-se de ter as Partes 1 e 5 concluídas
# Os dados são carregados automaticamente
```

### Execução
```
# Fonte o código completo
source("Parte_06_GLM_Series_Temporais/codigo_parte6.R")
```

---

## 📚 Referências

- **Hosmer, D. & Lemeshow, S. (2000).** Applied Logistic Regression. Wiley.
- **Box, G. & Jenkins, G. (1976).** Time Series Analysis: Forecasting and Control. Holden-Day.
- **Hyndman, R. & Athanasopoulos, G. (2018).** Forecasting: Principles and Practice. OTexts.
- **Fawcett, T. (2006).** An introduction to ROC analysis. *Pattern Recognition Letters*.

---

## 🎯 Projeto Completo

| Parte | Título |
|-------|--------|
| **Parte 1** | Prova da Não-Normalidade dos Retornos |
| **Parte 2** | Simulação de Monte Carlo e Análise de Risco |
| **Parte 3** | Inferência Estatística e Testes de Hipóteses |
| **Parte 4** | ANOVA e Análise de Associação (Qui-Quadrado) |
| **Parte 5** | Regressão Linear - Modelo CAPM |
| **Parte 6** | GLM e Séries Temporais (ARIMA) |

---

## 📫 Contato

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

⬅️ [Voltar para Parte 5](../Parte_05_Regressao_Linear_CAPM/) | [Voltar ao README Principal](../README.md)
