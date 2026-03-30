# Parte 2: Simulação de Monte Carlo e Análise de Risco

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Author](https://img.shields.io/badge/Author-Ivan%20Santos-blue)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

## 👤 Autor

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

## 🎯 Objetivo

Estimar a distribuição de probabilidade do patrimônio futuro através de **Simulação de Monte Carlo**, utilizando bootstrap dos retornos históricos para responder perguntas como:
- Qual a probabilidade de lucro em 1 ano?
- Qual o valor em risco (VaR) para diferentes níveis de confiança?
- Qual o drawdown máximo esperado?

## 📚 Fundamentação Teórica

### Simulação de Monte Carlo
Técnica que utiliza amostragem aleatória para estimar distribuições de resultados quando a análise analítica é complexa ou inviável. Neste contexto, utilizamos bootstrap dos retornos históricos reais.

### Bootstrap
Método de reamostragem com reposição que permite estimar a distribuição amostral de uma estatística sem assumir distribuição teórica. Vantagens:
- Não assume normalidade dos retornos
- Preserva as características empíricas dos dados
- Permite calcular intervalos de confiança robustos

### Value at Risk (VaR)
Medida que quantifica a perda máxima esperada dentro de um nível de confiança. Interpretação: "Há 95% de chance de que a perda não exceda o VaR".

```
VaR(α) = inf{x | P(L ≤ x) ≥ 1-α}
```

### Conditional VaR (CVaR / Expected Shortfall)
Média das perdas que excedem o VaR. Medida mais conservadora que captura a severidade dos eventos extremos.

```
CVaR(α) = E[L | L ≥ VaR(α)]
```

### Drawdown
Queda máxima do patrimônio em relação ao pico anterior. Medida importante para avaliar o risco de período de estresse.

```
Drawdown(t) = (Pico - Valor_atual) / Pico
```

---

## 📊 Ativo Analisado

| Ticker | Nome | Classe | Retorno Anualizado | Volatilidade Anualizada |
|--------|------|--------|-------------------|------------------------|
| WEGE3 | WEG S.A. | Ação Brasileira | 14.27% | 28.49% |

---

## 🎲 Metodologia

### 1. Coleta de Dados
Utilização dos retornos logarítmicos calculados na Parte 1 para o período de 2024-01-01 a 2026-03-20.

### 2. Bootstrap dos Retornos
```
# Amostragem com reposição dos retornos históricos
retornos_sim <- sample(retornos_historicos, size = 252, replace = TRUE)
```

### 3. Simulação do Caminho
```
# P(t) = P(0) × exp(Σ retornos)
caminho <- investimento_inicial * exp(cumsum(retornos_sim))
```

### 4. Cálculo do VaR
```
# VaR 95%: pior cenário em 95% dos casos
var_95 <- quantile(valores_finais, 0.05)

# CVaR 95%: média dos piores 5% cenários
cvar_95 <- mean(valores_finais[valores_finais <= var_95])
```

### 5. Análise de Drawdown
```
# Drawdown máximo para cada simulação
drawdown <- (pico - valor) / pico
```

---

## 📊 Parâmetros da Simulação

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| Investimento Inicial | R$ 10.000 | Valor inicial do patrimônio |
| Horizonte | 252 dias | 1 ano de dias úteis |
| Nº Simulações | 10.000 | Para precisão estatística |
| Nível de Confiança | 95% | Para VaR e intervalos |

---

## 📈 Resultados

### Estatísticas dos Valores Finais

| Métrica | Valor (R$) | Interpretação |
|---------|------------|---------------|
| **Média** | R$ 11.992 | Retorno médio de 19.9% |
| **Mediana** | R$ 11.528 | Metade dos cenários acima deste valor |
| **Desvio Padrão** | R$ 3.453 | Alta dispersão dos resultados |
| **Mínimo** | R$ 3.251 | Pior cenário: perda de 67.5% |
| **Máximo** | R$ 31.167 | Melhor cenário: ganho de 211.7% |

### Probabilidades

| Evento | Probabilidade |
|--------|---------------|
| **Lucro** | **69.4%** |
| **Prejuízo** | 30.6% |
| **Retorno esperado** | **19.9%** |

### Value at Risk (VaR)

| Medida | Valor (R$) | Significado |
|--------|------------|-------------|
| **VaR 90%** | R$ 8.010 | 90% dos cenários > R$ 8.010 |
| **VaR 95%** | R$ 7.150 | 95% dos cenários > R$ 7.150 |
| **VaR 99%** | R$ 5.745 | 99% dos cenários > R$ 5.745 |
| **CVaR 95%** | R$ 6.327 | Média dos 5% piores cenários |

**Interpretação do VaR 95%:**
- Há 5% de chance de perder mais de R$ 2.850 (28.5% do capital)
- Em 95% dos cenários, a perda é menor ou há lucro

### Análise de Drawdown

| Métrica | Valor | Significado |
|---------|-------|-------------|
| **Drawdown médio** | 23.8% | Queda média máxima em algum momento |
| **Drawdown mediano** | 22.2% | Metade dos cenários com drawdown ≤ 22.2% |
| **Drawdown p95** | 41.1% | 95% dos cenários com drawdown ≤ 41.1% |
| **Drawdown máximo** | 70.5% | Pior cenário: queda de 70.5% |

---

## 📊 Visualizações Geradas

| Arquivo | Descrição |
|---------|-----------|
| `01_caminhos_simulacao.png` | Evolução de 500 cenários simulados |
| `02_distribuicao_valores_finais.png` | Histograma e densidade dos valores finais |
| `03_boxplot_temporal.png` | Evolução da distribuição ao longo do tempo |
| `04_analise_drawdown.png` | Distribuição do drawdown máximo |
| `05_cdf_valores_finais.png` | Função de distribuição acumulada |

---

## 🎯 Conclusões

### Principais Descobertas

1. **Probabilidade de Lucro**: 69.4% de chance de terminar o ano com lucro
2. **Retorno Esperado**: 19.9% ao ano, consistente com o histórico
3. **Risco Significativo**: 
   - VaR 95% indica perda potencial de 28.5% do capital
   - Drawdown médio de 23.8% mostra períodos de estresse
4. **Caudas Pesadas**: Mínimo de R$ 3.251 confirma eventos extremos possíveis

### Implicações para o Investidor

- **Perfil Agressivo**: Adequado para quem busca alto retorno e aceita risco elevado
- **Horizonte Longo**: A volatilidade alta exige paciência para realizar o retorno esperado
- **Diversificação**: Recomendado combinar com ativos de menor correlação

---

## 📁 Estrutura de Arquivos

```
Parte_02_Simulacao_Monte_Carlo/
├── codigo_parte2.R          # Código completo da análise
├── README.md                # Esta documentação
├── graficos/                # Gráficos gerados
│   ├── 01_caminhos_simulacao.png
│   ├── 02_distribuicao_valores_finais.png
│   ├── 03_boxplot_temporal.png
│   ├── 04_analise_drawdown.png
│   └── 05_cdf_valores_finais.png
└── resultados/              # Resultados exportados
    ├── simulacoes.csv       # 10.000 cenários simulados
    ├── estatisticas.csv     # Métricas resumidas
    └── resultados_parte2.rds # Dados completos em R
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
source("Parte_02_Simulacao_Monte_Carlo/codigo_parte2.R")
```

---

## 📚 Referências

- **Hull, J. (2018).** Risk Management and Financial Institutions. Wiley.
- **Glasserman, P. (2003).** Monte Carlo Methods in Financial Engineering. Springer.
- **Jorion, P. (2006).** Value at Risk: The New Benchmark for Managing Financial Risk. McGraw-Hill.
- **Efron, B. (1979).** Bootstrap methods: Another look at the jackknife. *The Annals of Statistics*.

---

## 🎯 Próximas Partes

- **Parte 3:** Inferência Estatística e Testes de Hipóteses
- **Parte 4:** ANOVA e Análise de Associação (Qui-Quadrado)
- **Parte 5:** Regressão Linear - Modelo CAPM
- **Parte 6:** GLM e Séries Temporais (ARIMA)

---

## 📫 Contato

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

⬅️ [Voltar para Parte 1](../Parte_01_Prova_Nao_Normalidade/) | [Voltar ao README Principal](../README.md) | ➡️ [Ir para Parte 3](../Parte_03_Inferencia_Estatistica/)
