# ============================================================================
# PARTE 4: ANOVA E ANÁLISE DE ASSOCIAÇÃO (QUI-QUADRADO)
# ============================================================================
#
# OBJETIVO:
#   Analisar a variância dos retornos entre diferentes ativos (ANOVA) e a
#   associação entre a direção dos movimentos (alta/baixa) e os ativos.
#
# AUTOR: Ivan Santos
# DATA: 2026-03-30
# ============================================================================

# ----------------------------------------------------------------------------
# 1. CONFIGURAÇÃO INICIAL
# ----------------------------------------------------------------------------

# Limpeza do ambiente
rm(list = ls())
gc()

# Configuração de opções
options(
  stringsAsFactors = FALSE,
  scipen = 999,
  digits = 4,
  warn = 1
)

# Definir o nome da parte
PARTE <- "Parte_04_ANOVA_QuiQuadrado"

# Criar pastas
if(!dir.exists(file.path(PARTE, "graficos"))) {
  dir.create(file.path(PARTE, "graficos"), recursive = TRUE)
}
if(!dir.exists(file.path(PARTE, "resultados"))) {
  dir.create(file.path(PARTE, "resultados"), recursive = TRUE)
}

# Carregar pacotes
library(yfR)
library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(car)
library(vcd)

cat("\n✅ Pacotes carregados com sucesso!\n")

# ----------------------------------------------------------------------------
# 2. CARREGAR DADOS DA PARTE 1
# ----------------------------------------------------------------------------

cat("\n📊 CARREGANDO DADOS DA PARTE 1\n")
cat("─────────────────────────────────────────────────────────────────────\n")

if(file.exists("Parte_01_Prova_Nao_Normalidade/resultados/retornos_calculados.csv")) {
  retornos <- read.csv("Parte_01_Prova_Nao_Normalidade/resultados/retornos_calculados.csv")
  cat("✅ Dados carregados com sucesso!\n")
  cat("   Total de observações:", nrow(retornos), "\n")
  cat("   Ativos:", paste(unique(retornos$symbol), collapse = ", "), "\n")
} else {
  stop("❌ Dados da Parte 1 não encontrados. Execute a Parte 1 primeiro.")
}

# Renomear coluna para padronizar
names(retornos)[names(retornos) == "retorno_log"] <- "retorno"

# ----------------------------------------------------------------------------
# 3. PREPARAÇÃO DOS DADOS
# ----------------------------------------------------------------------------

cat("\n📊 PREPARANDO DADOS PARA ANOVA\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Filtrar dados e remover NAs
dados_anova <- retornos %>%
  filter(!is.na(retorno)) %>%
  select(symbol, retorno) %>%
  mutate(symbol = as.factor(symbol))

# Estatísticas descritivas por grupo
estatisticas_grupo <- dados_anova %>%
  group_by(symbol) %>%
  summarise(
    N = n(),
    Media = mean(retorno),
    Mediana = median(retorno),
    DP = sd(retorno),
    Min = min(retorno),
    Max = max(retorno),
    Q1 = quantile(retorno, 0.25),
    Q3 = quantile(retorno, 0.75),
    .groups = 'drop'
  )

cat("\n📈 ESTATÍSTICAS DESCRITIVAS POR ATIVO\n")
print(estatisticas_grupo)

# ----------------------------------------------------------------------------
# 4. VERIFICAÇÃO DOS PRESSUPOSTOS DA ANOVA
# ----------------------------------------------------------------------------

cat("\n🔍 VERIFICANDO PRESSUPOSTOS DA ANOVA\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Teste de Levene para homogeneidade de variâncias
cat("\n📋 Teste de Levene (Homogeneidade de Variâncias)\n")
levene_test <- leveneTest(retorno ~ symbol, data = dados_anova)
print(levene_test)

if(levene_test$`Pr(>F)`[1] < 0.05) {
  cat("   ⚠ ATENÇÃO: Variâncias heterogêneas (p < 0.05)\n")
  cat("   → Recomendado usar ANOVA robusta (Welch)\n")
} else {
  cat("   ✓ Variâncias homogêneas (p ≥ 0.05) - pressuposto atendido\n")
}

# ----------------------------------------------------------------------------
# 5. ANOVA CLÁSSICA
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║                    ANÁLISE DE VARIÂNCIA (ANOVA)                  ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

cat("\n📊 ANOVA CLÁSSICA\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Hipótese Nula (H0): As médias de todos os ativos são iguais\n")
cat("Hipótese Alternativa (H1): Pelo menos um ativo tem média diferente\n\n")

modelo_anova <- aov(retorno ~ symbol, data = dados_anova)
anova_summary <- summary(modelo_anova)
print(anova_summary)

# Extrair estatísticas
f_stat <- anova_summary[[1]]$`F value`[1]
p_valor <- anova_summary[[1]]$`Pr(>F)`[1]
df_entre <- anova_summary[[1]]$Df[1]
df_intra <- anova_summary[[1]]$Df[2]
ss_entre <- anova_summary[[1]]$`Sum Sq`[1]
ss_intra <- anova_summary[[1]]$`Sum Sq`[2]
ss_total <- ss_entre + ss_intra

# R²
r2 <- ss_entre / ss_total
r2_adj <- 1 - (1 - r2) * (sum(df_entre, df_intra) - 1) / df_intra

cat("\n📈 MÉTRICAS DE QUALIDADE DO MODELO\n")
cat(sprintf("   R² = %.4f (%.2f%% da variância explicada)\n", r2, r2 * 100))
cat(sprintf("   R² Ajustado = %.4f\n", r2_adj))

if(p_valor < 0.05) {
  cat("\n❌ Conclusão: Rejeita H0 - Existem diferenças significativas entre os ativos\n")
} else {
  cat("\n✅ Conclusão: Não rejeita H0 - Não há evidência de diferenças entre os ativos\n")
}

# ----------------------------------------------------------------------------
# 6. ANOVA ROBUSTA (WELCH)
# ----------------------------------------------------------------------------

cat("\n\n📊 ANOVA ROBUSTA (WELCH'S ANOVA)\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Recomendado quando variâncias são heterogêneas\n\n")

welch_anova <- oneway.test(retorno ~ symbol, 
                           data = dados_anova, 
                           var.equal = FALSE)

cat(sprintf("   F = %.4f | df = %.2f | p-valor = %.6f\n", 
            welch_anova$statistic, 
            welch_anova$parameter, 
            welch_anova$p.value))

# ----------------------------------------------------------------------------
# 7. TAMANHO DO EFEITO (ETA-QUADRADO)
# ----------------------------------------------------------------------------

cat("\n\n📊 TAMANHO DO EFEITO\n")
cat("─────────────────────────────────────────────────────────────────────\n")

eta_sq <- ss_entre / ss_total
omega_sq <- (ss_entre - (df_entre * (ss_intra / df_intra))) / 
  (ss_total + (ss_intra / df_intra))

cat(sprintf("   Eta-quadrado (η²) = %.4f\n", eta_sq))
cat(sprintf("   Ômega-quadrado (ω²) = %.4f\n", omega_sq))

interpretacao_eta <- case_when(
  eta_sq < 0.01 ~ "desprezível",
  eta_sq < 0.06 ~ "pequeno",
  eta_sq < 0.14 ~ "médio",
  TRUE ~ "grande"
)
cat(sprintf("   Interpretação: %s\n", interpretacao_eta))

# ----------------------------------------------------------------------------
# 8. TESTE POST-HOC: TUKEY HSD
# ----------------------------------------------------------------------------

cat("\n\n📊 TESTE POST-HOC DE TUKEY HSD\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Comparações par a par com correção para múltiplos testes\n\n")

tukey_result <- TukeyHSD(modelo_anova)
print(tukey_result)

# Extrair resultados para dataframe
tukey_df <- as.data.frame(tukey_result$symbol)
tukey_df$comparacao <- rownames(tukey_df)
tukey_df <- tukey_df %>%
  separate(comparacao, into = c("grupo1", "grupo2"), sep = "-") %>%
  mutate(
    significativo = `p adj` < 0.05,
    estrelas = case_when(
      `p adj` < 0.001 ~ "***",
      `p adj` < 0.01 ~ "**",
      `p adj` < 0.05 ~ "*",
      TRUE ~ ""
    )
  )

cat("\n📈 COMPARAÇÕES SIGNIFICATIVAS:\n")
tukey_df %>%
  filter(significativo) %>%
  select(grupo1, grupo2, diff, `p adj`, estrelas) %>%
  arrange(`p adj`) %>%
  print()

# ----------------------------------------------------------------------------
# 9. ANOVA NÃO-PARAMÉTRICA (KRUSKAL-WALLIS)
# ----------------------------------------------------------------------------

cat("\n\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║           ANOVA NÃO-PARAMÉTRICA (KRUSKAL-WALLIS)                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

cat("\n📊 TESTE DE KRUSKAL-WALLIS\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Alternativa não-paramétrica à ANOVA (não assume normalidade)\n")
cat("Hipótese Nula: As distribuições dos grupos são iguais\n\n")

kruskal_result <- kruskal.test(retorno ~ symbol, data = dados_anova)

cat(sprintf("Kruskal-Wallis chi-squared = %.4f\n", kruskal_result$statistic))
cat(sprintf("Graus de liberdade = %d\n", kruskal_result$parameter))
cat(sprintf("p-valor = %.6f\n", kruskal_result$p.value))

if(kruskal_result$p.value < 0.05) {
  cat("\n❌ Rejeita H0: Distribuições significativamente diferentes\n")
} else {
  cat("\n✅ Não rejeita H0: Distribuições não diferem significativamente\n")
}

# ----------------------------------------------------------------------------
# 10. ANÁLISE DE RESÍDUOS
# ----------------------------------------------------------------------------

cat("\n\n📊 ANÁLISE DE RESÍDUOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

residuos <- residuals(modelo_anova)

# Teste de normalidade dos resíduos
shapiro_res <- shapiro.test(residuos[1:min(5000, length(residuos))])
cat(sprintf("\nTeste de normalidade dos resíduos (Shapiro-Wilk):\n"))
cat(sprintf("   W = %.4f | p-valor = %.6f\n", shapiro_res$statistic, shapiro_res$p.value))

if(shapiro_res$p.value < 0.05) {
  cat("   ⚠ Resíduos não seguem distribuição normal\n")
  cat("   → Recomendado usar ANOVA não-paramétrica (Kruskal-Wallis)\n")
} else {
  cat("   ✓ Resíduos seguem distribuição normal\n")
}

# ----------------------------------------------------------------------------
# 11. ANÁLISE DE ASSOCIAÇÃO - TESTE QUI-QUADRADO
# ----------------------------------------------------------------------------

cat("\n\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║         ANÁLISE DE ASSOCIAÇÃO - TESTE QUI-QUADRADO               ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

# Criar variável categórica de direção
retornos_cat <- retornos %>%
  filter(!is.na(retorno)) %>%
  mutate(
    direcao = factor(ifelse(retorno > 0, "Alta", "Baixa"),
                     levels = c("Alta", "Baixa")),
    symbol = as.factor(symbol)
  )

# Tabela de contingência
tabela_contingencia <- table(retornos_cat$symbol, retornos_cat$direcao)

cat("\n📊 TABELA DE CONTINGÊNCIA\n")
cat("─────────────────────────────────────────────────────────────────────\n")
print(tabela_contingencia)

# Teste Qui-Quadrado
cat("\n📊 TESTE QUI-QUADRADO DE INDEPENDÊNCIA\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Hipótese Nula (H0): Direção do movimento e ativo são independentes\n")
cat("Hipótese Alternativa (H1): Existe associação entre direção e ativo\n\n")

qui_quadrado <- chisq.test(tabela_contingencia)

cat(sprintf("Chi-quadrado = %.4f\n", qui_quadrado$statistic))
cat(sprintf("Graus de liberdade = %d\n", qui_quadrado$parameter))
cat(sprintf("p-valor = %.6f\n", qui_quadrado$p.value))

if(qui_quadrado$p.value < 0.05) {
  cat("\n❌ Rejeita H0: Existe associação entre ativo e direção\n")
} else {
  cat("\n✅ Não rejeita H0: Não há evidência de associação\n")
}

# Resíduos padronizados
residuos_chi <- qui_quadrado$residuals
cat("\n📊 RESÍDUOS PADRONIZADOS (|resíduo| > 2 indica contribuição significativa)\n")
print(round(residuos_chi, 2))

# V de Cramér (usando vcd::assocstats)
cat("\n📊 MEDIDAS DE ASSOCIAÇÃO\n")

assoc <- assocstats(tabela_contingencia)
cramer_v <- assoc$cramer

cat(sprintf("   V de Cramér = %.4f\n", cramer_v))

interpretacao_cramer <- case_when(
  cramer_v < 0.1 ~ "associação desprezível",
  cramer_v < 0.3 ~ "associação pequena",
  cramer_v < 0.5 ~ "associação média",
  TRUE ~ "associação forte"
)
cat(sprintf("   Interpretação: %s\n", interpretacao_cramer))

# ----------------------------------------------------------------------------
# 12. VISUALIZAÇÕES
# ----------------------------------------------------------------------------

cat("\n🎨 GERANDO VISUALIZAÇÕES\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# 1. Boxplots por grupo
cat("✓ Criando boxplots por grupo...\n")

p_box <- ggplot(dados_anova, aes(x = symbol, y = retorno, fill = symbol)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.3) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "red") +
  labs(
    title = "Distribuição dos Retornos por Ativo",
    subtitle = "Boxplots com média destacada (pontos vermelhos)",
    x = "Ativo",
    y = "Retorno Logarítmico Diário"
  ) +
  scale_fill_manual(values = c("WEGE3" = "#2E86AB", "HGLG11" = "#A23B72", "BTC-USD" = "#F18F01")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    legend.position = "none",
    axis.text.x = element_text(face = "bold")
  )

ggsave(file.path(PARTE, "graficos", "01_boxplots_por_grupo.png"), 
       p_box, width = 10, height = 6, dpi = 300)
cat("   ✅ Boxplots salvos\n")

# 2. Intervalos de confiança do Tukey
cat("✓ Criando gráfico de intervalos de confiança do Tukey...\n")

png(file.path(PARTE, "graficos", "02_intervalos_tukey.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(tukey_result, las = 1, col = "steelblue")
title(main = "Intervalos de Confiança - Tukey HSD",
      sub = "Intervalos que não cruzam zero indicam diferenças significativas")
dev.off()
cat("   ✅ Gráfico de Tukey salvo\n")

# 3. Gráficos de diagnóstico dos resíduos
cat("✓ Criando gráficos de diagnóstico...\n")

png(file.path(PARTE, "graficos", "03_diagnostico_residuos.png"), 
    width = 12, height = 8, units = "in", res = 300)
par(mfrow = c(2, 2))
plot(modelo_anova, which = 1, main = "Resíduos vs Valores Ajustados")
plot(modelo_anova, which = 2, main = "Q-Q Plot dos Resíduos")
plot(modelo_anova, which = 3, main = "Scale-Location Plot")
plot(modelo_anova, which = 4, main = "Cook's Distance")
par(mfrow = c(1, 1))
dev.off()
cat("   ✅ Gráficos de diagnóstico salvos\n")

# 4. Gráfico de barras empilhadas (direção por ativo)
cat("✓ Criando gráfico de barras empilhadas...\n")

df_barras <- as.data.frame(tabela_contingencia) %>%
  rename(Ativo = Var1, Direcao = Var2, Frequencia = Freq)

p_barras <- ggplot(df_barras, aes(x = Ativo, y = Frequencia, fill = Direcao)) +
  geom_bar(stat = "identity", position = "fill", alpha = 0.8) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Proporção de Dias de Alta e Baixa por Ativo",
    subtitle = sprintf("Chi-quadrado p-valor = %.4f | V de Cramér = %.3f", 
                       qui_quadrado$p.value, cramer_v),
    x = "Ativo",
    y = "Proporção",
    fill = "Direção"
  ) +
  scale_fill_manual(values = c("Alta" = "#2E86AB", "Baixa" = "#A23B72")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    legend.position = "bottom"
  )

ggsave(file.path(PARTE, "graficos", "04_barras_empilhadas.png"), 
       p_barras, width = 8, height = 6, dpi = 300)
cat("   ✅ Gráfico de barras empilhadas salvo\n")

# 5. Heatmap da tabela de contingência (alternativa ao mosaic plot)
cat("✓ Criando heatmap da tabela de contingência...\n")

df_heatmap <- as.data.frame(tabela_contingencia) %>%
  rename(Ativo = Var1, Direcao = Var2, Frequencia = Freq)

p_heatmap <- ggplot(df_heatmap, aes(x = Ativo, y = Direcao, fill = Frequencia)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = Frequencia), size = 5, fontface = "bold") +
  scale_fill_gradient(low = "#E8F4FD", high = "#2E86AB", 
                      name = "Frequência") +
  labs(
    title = "Tabela de Contingência - Frequência por Ativo e Direção",
    subtitle = sprintf("Chi-quadrado p-valor = %.4f | V de Cramér = %.3f", 
                       qui_quadrado$p.value, cramer_v),
    x = "Ativo",
    y = "Direção"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    axis.text = element_text(face = "bold", size = 11),
    legend.position = "right",
    panel.grid = element_blank()
  )

ggsave(file.path(PARTE, "graficos", "05_heatmap_contingencia.png"), 
       p_heatmap, width = 8, height = 5, dpi = 300)
cat("   ✅ Heatmap da tabela de contingência salvo\n")

cat("\n✅ Todos os gráficos salvos em:", file.path(PARTE, "graficos/"), "\n")

# ----------------------------------------------------------------------------
# 13. EXPORTAÇÃO DOS RESULTADOS
# ----------------------------------------------------------------------------

cat("\n📁 EXPORTANDO RESULTADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Estatísticas descritivas
write.csv(estatisticas_grupo, 
          file.path(PARTE, "resultados", "estatisticas_descritivas.csv"), 
          row.names = FALSE)
cat("✓ estatisticas_descritivas.csv\n")

# Resultados da ANOVA
anova_df <- data.frame(
  Fonte = c("Entre Grupos", "Intra Grupos"),
  SQ = c(ss_entre, ss_intra),
  GL = c(df_entre, df_intra),
  QM = c(ss_entre/df_entre, ss_intra/df_intra),
  F = c(f_stat, NA),
  p_valor = c(p_valor, NA)
)
write.csv(anova_df, 
          file.path(PARTE, "resultados", "resultados_anova.csv"), 
          row.names = FALSE)
cat("✓ resultados_anova.csv\n")

# Resultados do Tukey
write.csv(tukey_df, 
          file.path(PARTE, "resultados", "resultados_tukey.csv"), 
          row.names = FALSE)
cat("✓ resultados_tukey.csv\n")

# Resultados do Qui-Quadrado
chi_df <- data.frame(
  estatistica = qui_quadrado$statistic,
  gl = qui_quadrado$parameter,
  p_valor = qui_quadrado$p.value,
  cramer_v = cramer_v
)
write.csv(chi_df, 
          file.path(PARTE, "resultados", "resultados_quiquadrado.csv"), 
          row.names = FALSE)
cat("✓ resultados_quiquadrado.csv\n")

# Tabela de contingência
write.csv(as.data.frame(tabela_contingencia), 
          file.path(PARTE, "resultados", "tabela_contingencia.csv"), 
          row.names = TRUE)
cat("✓ tabela_contingencia.csv\n")

# Resultados do Kruskal-Wallis
kruskal_df <- data.frame(
  estatistica = kruskal_result$statistic,
  gl = kruskal_result$parameter,
  p_valor = kruskal_result$p.value
)
write.csv(kruskal_df, 
          file.path(PARTE, "resultados", "resultados_kruskal.csv"), 
          row.names = FALSE)
cat("✓ resultados_kruskal.csv\n")

# Salvar resultados completos
saveRDS(list(
  dados_anova = dados_anova,
  estatisticas_grupo = estatisticas_grupo,
  modelo_anova = modelo_anova,
  tukey = tukey_result,
  welch_anova = welch_anova,
  kruskal = kruskal_result,
  tabela_contingencia = tabela_contingencia,
  qui_quadrado = qui_quadrado,
  cramer_v = cramer_v
), file.path(PARTE, "resultados", "resultados_parte4.rds"))
cat("✓ resultados_parte4.rds\n")

cat("\n✅ Resultados exportados para:", file.path(PARTE, "resultados/"), "\n")

# ----------------------------------------------------------------------------
# 14. SUMÁRIO EXECUTIVO
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              SUMÁRIO EXECUTIVO - PARTE 4                         ║\n")
cat("║                   ANOVA E QUI-QUADRADO                           ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("📊 RESULTADOS DA ANOVA\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   F-statistic = %.4f\n", f_stat))
cat(sprintf("   p-valor = %.6f\n", p_valor))
cat(sprintf("   R² = %.4f (%.2f%%)\n", r2, r2 * 100))
cat(sprintf("   Tamanho do efeito: %s (η² = %.4f)\n", interpretacao_eta, eta_sq))

cat("\n📊 RESULTADOS DO KRUSKAL-WALLIS\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   Chi-quadrado = %.4f\n", kruskal_result$statistic))
cat(sprintf("   p-valor = %.6f\n", kruskal_result$p.value))

cat("\n📊 RESULTADOS DO TESTE QUI-QUADRADO\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   Chi-quadrado = %.4f\n", qui_quadrado$statistic))
cat(sprintf("   p-valor = %.6f\n", qui_quadrado$p.value))
cat(sprintf("   V de Cramér = %.4f (%s)\n", cramer_v, interpretacao_cramer))

cat("\n🎯 CONCLUSÃO\n")
cat("─────────────────────────────────────────────────────────────────────\n")

if(p_valor < 0.05) {
  cat("❌ ANOVA: Existem diferenças significativas entre os ativos\n")
} else {
  cat("✅ ANOVA: Não há evidência de diferenças entre os ativos\n")
}

if(kruskal_result$p.value < 0.05) {
  cat("❌ Kruskal-Wallis: Distribuições significativamente diferentes\n")
} else {
  cat("✅ Kruskal-Wallis: Distribuições não diferem significativamente\n")
}

if(qui_quadrado$p.value < 0.05) {
  cat("❌ Qui-Quadrado: Existe associação entre ativo e direção\n")
} else {
  cat("✅ Qui-Quadrado: Não há associação entre ativo e direção\n")
}

cat("\n📁 ARQUIVOS GERADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("✓ %s/graficos/ - 5 gráficos\n", PARTE))
cat(sprintf("✓ %s/resultados/estatisticas_descritivas.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_anova.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_tukey.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_quiquadrado.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_kruskal.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_parte4.rds\n", PARTE))
cat("\n")

cat("✅ PARTE 4 CONCLUÍDA COM SUCESSO!\n")

# ============================================================================
# FIM DA PARTE 4
# ============================================================================s