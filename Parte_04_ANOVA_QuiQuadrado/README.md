# Parte 4: ANOVA e Análise de Associação (Qui-Quadrado)

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Author](https://img.shields.io/badge/Author-Ivan%20Santos-blue)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

## 👤 Autor

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

## 🎯 Objetivo

Analisar a variância dos retornos entre diferentes ativos (ANOVA) e a associação entre a direção dos movimentos (alta/baixa) e os ativos através do teste Qui-Quadrado.

## 📚 Fundamentação Teórica

### Análise de Variância (ANOVA)
Técnica estatística que testa se as médias de múltiplos grupos são iguais. Decompõe a variância total em:
- **Variância entre grupos**: Diferenças causadas pelo fator estudado
- **Variância intra-grupos**: Variação natural dentro de cada grupo

### Pressupostos da ANOVA
1. **Normalidade**: Resíduos seguem distribuição normal
2. **Homocedasticidade**: Variâncias iguais entre grupos
3. **Independência**: Observações independentes

### Teste de Levene
Verifica a homogeneidade de variâncias entre os grupos. H₀: As variâncias são iguais.

### Teste de Tukey HSD
Teste post-hoc para comparações múltiplas, ajustando o nível de significância para evitar erro Tipo I.

### Teste de Kruskal-Wallis
Alternativa não-paramétrica à ANOVA. Não assume normalidade, apenas que as distribuições são contínuas.

### Teste Qui-Quadrado de Independência
Avalia se duas variáveis categóricas são independentes. Compara frequências observadas com esperadas.

```
χ² = Σ (O - E)² / E
```

### V de Cramér
Medida de associação para tabelas de contingência, variando de 0 (independência) a 1 (associação perfeita).

---

## 🧪 Hipóteses Testadas

### ANOVA / Kruskal-Wallis
```
H₀: As médias/distribuições de todos os ativos são iguais
H₁: Pelo menos um ativo tem média/distribuição diferente
```

### Qui-Quadrado
```
H₀: Direção do movimento e ativo são independentes
H₁: Existe associação entre direção e ativo
```

---

## 📊 Ativos Analisados

| Ticker | Nome | Classe | Nº Observações |
|--------|------|--------|----------------|
| WEGE3 | WEG S.A. | Ação Brasileira | 553 |
| HGLG11 | CSHG Logística FII | Fundo Imobiliário | 553 |
| BTC-USD | Bitcoin | Criptomoeda | 809 |

---

## 📈 Resultados

### Estatísticas Descritivas

| Ativo | Média | Mediana | Desvio Padrão | Mínimo | Máximo |
|-------|-------|---------|---------------|--------|--------|
| **WEGE3** | 0.000566 | 0.000273 | 0.01795 | -0.123 | 0.0995 |
| **HGLG11** | 0.000258 | 0.000061 | 0.00627 | -0.0224 | 0.0468 |
| **BTC-USD** | 0.000578 | 0.000286 | 0.02583 | -0.152 | 0.118 |

### Teste de Levene (Homogeneidade de Variâncias)

| Estatística | p-valor | Conclusão |
|-------------|---------|-----------|
| F = 165.0 | < 0.001 | ⚠ Variâncias heterogêneas |

### ANOVA Clássica

| Fonte | SQ | GL | QM | F | p-valor |
|-------|----|----|----|---|---------|
| Entre Grupos | 0.00002 | 2 | 0.00001 | 0.0507 | 0.9506 |
| Intra Grupos | 0.739 | 1912 | 0.000386 | - | - |

**R² = 0.01%** (proporção da variância explicada é desprezível)

**Conclusão:** ✅ Não rejeita H₀ - Não há evidência de diferenças entre os ativos

### ANOVA Robusta (Welch)

| Estatística | p-valor | Conclusão |
|-------------|---------|-----------|
| F = 0.1188 | 0.888 | ✅ Confirma ausência de diferenças |

### Teste de Tukey HSD (Comparações par a par)

| Comparação | Diferença | IC 95% | p-ajustado |
|------------|-----------|--------|------------|
| HGLG11 - BTC-USD | -0.00032 | [-0.00286, 0.00222] | 0.953 |
| WEGE3 - BTC-USD | -0.00001 | [-0.00256, 0.00253] | 0.999 |
| WEGE3 - HGLG11 | 0.00031 | [-0.00246, 0.00308] | 0.963 |

**Nenhuma comparação apresentou diferença significativa**

### Teste de Kruskal-Wallis

| Estatística | gl | p-valor | Conclusão |
|-------------|----|---------|-----------|
| χ² = 0.3561 | 2 | 0.8369 | ✅ Distribuições não diferem |

### Teste Qui-Quadrado de Independência

**Tabela de Contingência:**

| Ativo | Alta | Baixa | Total |
|-------|------|-------|-------|
| BTC-USD | 408 | 401 | 809 |
| HGLG11 | 278 | 275 | 553 |
| WEGE3 | 281 | 272 | 553 |
| **Total** | 967 | 948 | 1915 |

| Estatística | gl | p-valor | Conclusão |
|-------------|----|---------|-----------|
| χ² = 0.0348 | 2 | 0.9827 | ✅ Não há associação |

### V de Cramér

| Valor | Interpretação |
|-------|---------------|
| 0.0043 | associação desprezível |

### Análise de Resíduos

| Teste | Estatística | p-valor | Conclusão |
|-------|-------------|---------|-----------|
| Shapiro-Wilk | W = 0.8952 | < 0.001 | ⚠ Resíduos não normais |

**Recomendação:** Usar Kruskal-Wallis (já aplicado)

---

## 📊 Visualizações Geradas

| Arquivo | Descrição |
|---------|-----------|
| `01_boxplots_por_grupo.png` | Boxplots comparativos dos retornos por ativo |
| `02_intervalos_tukey.png` | Intervalos de confiança das comparações Tukey |
| `03_diagnostico_residuos.png` | 4 gráficos de diagnóstico dos resíduos |
| `04_barras_empilhadas.png` | Proporção de dias de alta/baixa por ativo |
| `05_heatmap_contingencia.png` | Heatmap da tabela de contingência |

---

## 🎯 Conclusões

### Principais Descobertas

1. **Médias Equivalentes**: ANOVA e Kruskal-Wallis confirmam que não há diferença significativa entre os retornos médios dos três ativos (p > 0.05)

2. **Variâncias Diferentes**: Teste de Levene mostra variâncias heterogêneas (p < 0.001), justificando o uso da ANOVA robusta

3. **Associação Desprezível**: Qui-Quadrado não rejeita independência entre ativo e direção (p = 0.98)

4. **Tamanho do Efeito Nulo**: η² = 0.0001 e V de Cramér = 0.0043 indicam efeitos desprezíveis

### Implicações Práticas

- **Escolha do Ativo**: Não deve ser baseada em retorno esperado (similar)
- **Diferenciação pelo Risco**: A diferença está na volatilidade, não no retorno médio
- **Direção dos Movimentos**: Todos os ativos têm mesma probabilidade de alta/baixa
- **Modelagem**: Modelos não precisam incluir efeitos de grupo

---

## 📁 Estrutura de Arquivos

```
Parte_04_ANOVA_QuiQuadrado/
├── codigo_parte4.R          # Código completo da análise
├── README.md                # Esta documentação
├── graficos/                # Gráficos gerados
│   ├── 01_boxplots_por_grupo.png
│   ├── 02_intervalos_tukey.png
│   ├── 03_diagnostico_residuos.png
│   ├── 04_barras_empilhadas.png
│   └── 05_heatmap_contingencia.png
└── resultados/              # Resultados exportados
    ├── estatisticas_descritivas.csv
    ├── resultados_anova.csv
    ├── resultados_tukey.csv
    ├── resultados_quiquadrado.csv
    ├── tabela_contingencia.csv
    ├── resultados_kruskal.csv
    └── resultados_parte4.rds
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
source("Parte_04_ANOVA_QuiQuadrado/codigo_parte4.R")
```

---

## 📚 Referências

- **Fisher, R. A. (1925).** Statistical Methods for Research Workers.
- **Tukey, J. W. (1949).** Comparing individual means in the analysis of variance.
- **Kruskal, W. & Wallis, W. (1952).** Use of ranks in one-criterion variance analysis.
- **Pearson, K. (1900).** On the criterion that a given system of deviations from the probable in the case of a correlated system of variables is such that it can be reasonably supposed to have arisen from random sampling.
- **Cramér, H. (1946).** Mathematical Methods of Statistics.

---

## 🎯 Próximas Partes

- **Parte 5:** Regressão Linear - Modelo CAPM
- **Parte 6:** GLM e Séries Temporais (ARIMA)

---

## 📫 Contato

**Ivan Santos**  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ivan-santos-8046a8355/)

---

⬅️ [Voltar para Parte 3](../Parte_03_Inferencia_Estatistica/) | [Voltar ao README Principal](../README.md) | ➡️ [Ir para Parte 5](../Parte_05_Regressao_Linear_CAPM/)