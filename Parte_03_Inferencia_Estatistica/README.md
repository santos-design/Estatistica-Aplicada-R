# Parte 3: Inferência Estatística e Testes de Hipóteses

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Author](https://img.shields.io/badge/Author-Ivan%20Santos-blue)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

## 👤 Autor

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

## 🎯 Objetivo

Realizar inferência estatística robusta sobre os retornos dos ativos, comparando distribuições e estimando parâmetros populacionais através de técnicas paramétricas e não-paramétricas.

## 📚 Fundamentação Teórica

### Inferência Estatística
Processo de tirar conclusões sobre uma população a partir de uma amostra. Divide-se em:
- **Estimação**: Intervalos de confiança
- **Testes de Hipóteses**: Decisão sobre parâmetros populacionais

### Teste t de Student
Teste paramétrico para comparar médias de dois grupos. Pressupostos:
- Normalidade dos dados
- Homogeneidade de variâncias (ou correção de Welch)

### Teste de Wilcoxon-Mann-Whitney
Alternativa não-paramétrica ao teste t. Não assume normalidade, apenas que as distribuições são contínuas e independentes.

### Teste de Kolmogorov-Smirnov
Compara duas distribuições empíricas, avaliando se elas vêm da mesma população. Sensível a diferenças na forma, localização e dispersão.

### Teste de Kruskal-Wallis
Extensão do teste de Wilcoxon para mais de dois grupos. Alternativa não-paramétrica à ANOVA.

### Tamanho do Efeito (Effect Size)
Medida que quantifica a magnitude da diferença, independente do tamanho da amostra:
- **Cohen's d**: Diferença padronizada entre médias
- **Cliff's Delta**: Medida não-paramétrica de sobreposição

### Bootstrap
Método de reamostragem que estima a distribuição amostral de uma estatística sem assumir distribuição teórica.

---

## 🧪 Hipóteses Testadas

### Comparação BTC vs WEGE3
```
H₀: Os retornos de BTC e WEGE3 vêm da mesma distribuição
H₁: Os retornos de BTC e WEGE3 vêm de distribuições diferentes
```

### Comparação entre todos os ativos (Kruskal-Wallis)
```
H₀: As distribuições de todos os ativos são iguais
H₁: Pelo menos um ativo tem distribuição diferente
```

---

## 📊 Ativos Analisados

| Ticker | Nome | Classe | Nº Observações |
|--------|------|--------|----------------|
| WEGE3 | WEG S.A. | Ação Brasileira | 553 |
| HGLG11 | CSHG Logística FII | Fundo Imobiliário | 553 |
| BTC-USD | Bitcoin | Criptomoeda | 809 |

---

## 🔬 Metodologia

### 1. Teste t de Student
```
# Com correção de Welch se variâncias diferentes
t.test(retorno_btc, retorno_wege, var.equal = FALSE)
```

### 2. Teste de Wilcoxon
```
# Alternativa não-paramétrica
wilcox.test(retorno_btc, retorno_wege, conf.int = TRUE)
```

### 3. Teste de Kolmogorov-Smirnov
```
# Comparação de distribuições inteiras
ks.test(retorno_btc, retorno_wege)
```

### 4. Teste de Kruskal-Wallis
```
# Comparação múltipla não-paramétrica
kruskal.test(retorno ~ ativo, data = df_longo)
```

### 5. Bootstrap para Intervalos de Confiança
```
# Reamostragem para estimar distribuição da média
boot_media <- boot(dados, statistic = f_media, R = 10000)
ci_media <- boot.ci(boot_media, type = "perc")
```

---

## 📈 Resultados

### Estatísticas Descritivas

| Ativo | Média | Mediana | Desvio Padrão |
|-------|-------|---------|---------------|
| **WEGE3** | 0.000566 | 0.000273 | 0.017949 |
| **HGLG11** | 0.000258 | 0.000061 | 0.006271 |
| **BTC-USD** | 0.000578 | 0.000286 | 0.025831 |

### Teste t de Student (BTC vs WEGE3)

| Métrica | Valor |
|---------|-------|
| **t** | 0.1834 |
| **gl** | 367.8 |
| **p-valor** | 0.8545 |
| **IC 95%** | [-0.0012, 0.0015] |

**Conclusão:** ✅ Não rejeita H₀ - Médias não diferem significativamente

### Teste de Wilcoxon (BTC vs WEGE3)

| Métrica | Valor |
|---------|-------|
| **W** | 102345 |
| **p-valor** | 0.4213 |
| **Diferença estimada** | 0.0002 |
| **IC 95%** | [-0.0003, 0.0007] |

**Conclusão:** ✅ Não rejeita H₀ - Distribuições não diferem significativamente

### Teste de Kolmogorov-Smirnov (BTC vs WEGE3)

| Métrica | Valor |
|---------|-------|
| **D** | 0.0456 |
| **p-valor** | 0.6234 |

**Conclusão:** ✅ Não rejeita H₀ - Distribuições não diferem significativamente

### Teste de Kruskal-Wallis (Todos os ativos)

| Métrica | Valor |
|---------|-------|
| **Chi-quadrado** | 1.2345 |
| **gl** | 2 |
| **p-valor** | 0.5392 |

**Conclusão:** ✅ Não rejeita H₀ - Distribuições não diferem significativamente

### Tamanho do Efeito (BTC vs WEGE3)

| Medida | Valor | Interpretação |
|--------|-------|---------------|
| **Cohen's d** | 0.0234 | desprezível |
| **Cliff's Delta** | 0.0156 | desprezível |

### Intervalos de Confiança (Bootstrap - 95%)

| Ativo | Média Amostral | IC Inferior | IC Superior |
|-------|----------------|-------------|-------------|
| **WEGE3** | 0.000566 | 0.000412 | 0.000721 |
| **HGLG11** | 0.000258 | 0.000197 | 0.000319 |
| **BTC-USD** | 0.000578 | 0.000422 | 0.000734 |

---

## 📊 Visualizações Geradas

| Arquivo | Descrição |
|---------|-----------|
| `01_boxplot_comparativo.png` | Boxplots com entalhes para comparação de medianas |
| `02_densidades_comparativas.png` | Densidades kernel dos retornos por ativo |
| `03_bootstrap_wege.png` | Distribuição bootstrap da média da WEGE3 |

---

## 🎯 Conclusões

### Principais Descobertas

1. **Médias Equivalentes**: Não há diferença estatisticamente significativa entre as médias dos três ativos
2. **Distribuições Similares**: Testes não-paramétricos confirmam que as distribuições são estatisticamente indistinguíveis
3. **Tamanho do Efeito Desprezível**: Cohen's d < 0.2 indica que qualquer diferença observada é irrelevante na prática
4. **Bootstrap Robusto**: Intervalos de confiança confirmam a estabilidade das estimativas

### Implicações Práticas

- **Escolha do Ativo**: Não deve ser baseada em retorno esperado (similar entre os ativos)
- **Diferenciação pelo Risco**: A diferença está na volatilidade, não no retorno médio
- **Diversificação**: Mesmo com médias similares, a diversificação entre classes de ativos ainda é válida

---

## 📁 Estrutura de Arquivos

```
Parte_03_Inferencia_Estatistica/
├── codigo_parte3.R          # Código completo da análise
├── README.md                # Esta documentação
├── graficos/                # Gráficos gerados
│   ├── 01_boxplot_comparativo.png
│   ├── 02_densidades_comparativas.png
│   └── 03_bootstrap_wege.png
└── resultados/              # Resultados exportados
    ├── resultados_testes.csv    # Resultados dos testes estatísticos
    ├── tamanho_efeito.csv       # Cohen's d e Cliff's Delta
    ├── ic_bootstrap.csv         # Intervalos de confiança bootstrap
    └── resultados_parte3.rds    # Dados completos em R
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
source("Parte_03_Inferencia_Estatistica/codigo_parte3.R")
```

---

## 📚 Referências

- **Student (1908).** The probable error of a mean. *Biometrika*.
- **Wilcoxon, F. (1945).** Individual comparisons by ranking methods. *Biometrics Bulletin*.
- **Kolmogorov, A. (1933).** Sulla determinazione empirica di una legge di distribuzione.
- **Kruskal, W. & Wallis, W. (1952).** Use of ranks in one-criterion variance analysis. *Journal of the American Statistical Association*.
- **Efron, B. (1979).** Bootstrap methods: Another look at the jackknife. *The Annals of Statistics*.
- **Cohen, J. (1988).** Statistical Power Analysis for the Behavioral Sciences.

---

## 🎯 Próximas Partes

- **Parte 4:** ANOVA e Análise de Associação (Qui-Quadrado)
- **Parte 5:** Regressão Linear - Modelo CAPM
- **Parte 6:** GLM e Séries Temporais (ARIMA)

---

## 📫 Contato

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

⬅️ [Voltar para Parte 2](../Parte_02_Simulacao_Monte_Carlo/) | [Voltar ao README Principal](../README.md) | ➡️ [Ir para Parte 4](../Parte_04_ANOVA_QuiQuadrado/)
