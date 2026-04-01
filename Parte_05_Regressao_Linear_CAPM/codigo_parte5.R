# ============================================================================
# PARTE 5: REGRESSÃO LINEAR - MODELO DE PRECIFICAÇÃO DE ATIVOS (CAPM)
# ============================================================================
#
# OBJETIVO:
#   Estimar o Beta (β) de um ativo em relação ao mercado (Ibovespa) utilizando
#   regressão linear, fundamentando a análise no Capital Asset Pricing Model.
#
# CONCEITOS:
#   - CAPM: Ri - Rf = α + β × (Rm - Rf) + ε
#   - Beta (β): Medida de risco sistemático do ativo
#   - Alfa (α): Retorno anormal do ativo
#   - R²: Proporção da variância explicada
#   - Diagnóstico: Autocorrelação, heterocedasticidade, normalidade
#
# AUTOR: Ivan Santos
# DATA: 2026-04-01
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
  digits = 6,
  warn = 1
)

# Definir o nome da parte
PARTE <- "Parte_05_Regressao_Linear_CAPM"

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
library(lmtest)
library(sandwich)
library(broom)

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
# 3. COLETA DE DADOS DO MERCADO (IBOVESPA)
# ----------------------------------------------------------------------------

cat("\n📊 COLETANDO DADOS DO MERCADO (IBOVESPA)\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Período
periodo <- list(
  inicio = as.Date("2024-01-01"),
  fim = as.Date("2026-03-20")
)

# Coletar dados do Ibovespa
cache_dir <- file.path(tempdir(), "yfr_cache")
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

cat("Baixando dados do Ibovespa (^BVSP)...\n")

dados_ibov <- tryCatch({
  yf_get(
    tickers = "^BVSP",
    first_date = periodo$inicio,
    last_date = periodo$fim,
    freq_data = "daily",
    type_return = "log",
    do_cache = TRUE,
    cache_folder = cache_dir,
    do_complete_data = TRUE
  )
}, error = function(e) {
  cat("ERRO:", e$message, "\n")
  return(NULL)
})

if(is.null(dados_ibov) || nrow(dados_ibov) == 0) {
  stop("❌ Não foi possível coletar dados do Ibovespa.")
}

# Processar dados do Ibovespa - GARANTIR QUE DATE É DATE
dados_ibov <- dados_ibov %>%
  mutate(
    retorno_mercado = ret_adjusted_prices,
    date = as.Date(ref_date)  # Converter para Date
  ) %>%
  select(date, retorno_mercado)

cat("✅ Dados do Ibovespa coletados:", nrow(dados_ibov), "observações\n")
cat("   Período:", format(min(dados_ibov$date), "%d/%m/%Y"), 
    "a", format(max(dados_ibov$date), "%d/%m/%Y"), "\n")

# ----------------------------------------------------------------------------
# 4. PREPARAÇÃO DOS DADOS PARA REGRESSÃO
# ----------------------------------------------------------------------------

cat("\n📊 PREPARANDO DADOS PARA REGRESSÃO\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Selecionar ativo para análise (WEGE3)
ativo_analise <- "WEGE3"

# Garantir que os retornos da Parte 1 têm data no formato Date
retornos_ativo <- retornos %>%
  filter(symbol == ativo_analise) %>%
  select(date, retorno_ativo = retorno) %>%
  mutate(date = as.Date(date))  # Converter para Date

# Verificar formatos
cat("\n🔍 VERIFICANDO FORMATOS DAS DATAS\n")
cat(sprintf("   Data do ativo: %s\n", class(retornos_ativo$date)[1]))
cat(sprintf("   Data do mercado: %s\n", class(dados_ibov$date)[1]))

# Juntar dados
dados_regressao <- retornos_ativo %>%
  inner_join(dados_ibov, by = "date") %>%
  drop_na()

cat("\n📈 DADOS COMBINADOS\n")
cat(sprintf("   Nº observações: %d\n", nrow(dados_regressao)))
cat(sprintf("   Período: %s a %s\n", 
            format(min(dados_regressao$date), "%d/%m/%Y"),
            format(max(dados_regressao$date), "%d/%m/%Y")))

# Taxa livre de risco (Selic aproximada - 10.5% a.a.)
rf_anual <- 0.105
rf_diaria <- (1 + rf_anual)^(1/252) - 1

# Calcular retornos em excesso
dados_regressao <- dados_regressao %>%
  mutate(
    excesso_ativo = retorno_ativo - rf_diaria,
    excesso_mercado = retorno_mercado - rf_diaria
  )

cat("\n📈 ESTATÍSTICAS DESCRITIVAS\n")
cat(sprintf("   Ativo: %s\n", ativo_analise))
cat(sprintf("   Retorno médio do ativo: %.4f%%\n", mean(dados_regressao$retorno_ativo) * 100))
cat(sprintf("   Retorno médio do mercado: %.4f%%\n", mean(dados_regressao$retorno_mercado) * 100))
cat(sprintf("   Taxa livre de risco diária: %.4f%%\n", rf_diaria * 100))
cat(sprintf("   Correlação ativo-mercado: %.4f\n", 
            cor(dados_regressao$retorno_ativo, dados_regressao$retorno_mercado)))
# ----------------------------------------------------------------------------
# 5. ANÁLISE EXPLORATÓRIA
# ----------------------------------------------------------------------------

cat("\n📈 ANÁLISE EXPLORATÓRIA\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# 1. Gráfico de dispersão
p_dispersao <- ggplot(dados_regressao, aes(x = retorno_mercado, y = retorno_ativo)) +
  geom_point(alpha = 0.5, color = "steelblue", size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "red", fill = "red", alpha = 0.2) +
  labs(
    title = sprintf("Relação entre Retornos: %s vs Ibovespa", ativo_analise),
    subtitle = sprintf("Correlação = %.4f", 
                       cor(dados_regressao$retorno_ativo, dados_regressao$retorno_mercado)),
    x = "Retorno do Ibovespa",
    y = sprintf("Retorno da %s", ativo_analise)
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5)
  )

ggsave(file.path(PARTE, "graficos", "01_dispersao.png"), 
       p_dispersao, width = 10, height = 6, dpi = 300)
cat("   ✅ Gráfico de dispersão salvo\n")

# 2. Série temporal
dados_long <- dados_regressao %>%
  select(date, retorno_ativo, retorno_mercado) %>%
  pivot_longer(cols = -date, names_to = "serie", values_to = "retorno")

p_temporal <- ggplot(dados_long, aes(x = date, y = retorno, color = serie)) +
  geom_line(alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  labs(
    title = "Série Temporal dos Retornos",
    x = "Data",
    y = "Retorno Logarítmico Diário",
    color = "Série"
  ) +
  scale_color_manual(values = c("retorno_ativo" = "#2E86AB", "retorno_mercado" = "#F18F01"),
                     labels = c(ativo_analise, "Ibovespa")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    legend.position = "bottom"
  )

ggsave(file.path(PARTE, "graficos", "02_serie_temporal.png"), 
       p_temporal, width = 12, height = 6, dpi = 300)
cat("   ✅ Série temporal salva\n")

# ----------------------------------------------------------------------------
# 6. ESTIMAÇÃO DO MODELO CAPM
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              ESTIMAÇÃO DO MODELO CAPM                            ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

cat("\n📊 MODELO COM RETORNOS EM EXCESSO (CAPM)\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Ri - Rf = α + β × (Rm - Rf) + ε\n\n")

modelo_capm <- lm(excesso_ativo ~ excesso_mercado, data = dados_regressao)
modelo_summary <- summary(modelo_capm)
print(modelo_summary)

# Extrair coeficientes
beta <- coef(modelo_capm)[2]
alpha <- coef(modelo_capm)[1]
beta_std <- modelo_summary$coefficients[2, 2]
beta_t <- modelo_summary$coefficients[2, 3]
beta_p <- modelo_summary$coefficients[2, 4]

cat("\n📈 INTERPRETAÇÃO DOS COEFICIENTES\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("Beta (β): %.6f\n", beta))

if(beta > 1) {
  cat(sprintf("   → Ativo AGRESSIVO: %.2f%% mais volátil que o mercado\n", (beta - 1) * 100))
} else if(beta < 1) {
  cat(sprintf("   → Ativo DEFENSIVO: %.2f%% menos volátil que o mercado\n", (1 - beta) * 100))
} else {
  cat("   → Ativo NEUTRO: Mesma volatilidade do mercado\n")
}

cat(sprintf("\nAlfa (α): %.6f\n", alpha))
if(alpha > 0) {
  cat("   → Alfa positivo: Ativo gerou retorno anormal acima do mercado\n")
} else if(alpha < 0) {
  cat("   → Alfa negativo: Ativo gerou retorno anormal abaixo do mercado\n")
} else {
  cat("   → Alfa zero: Ativo performou conforme esperado pelo CAPM\n")
}

cat(sprintf("\nR²: %.4f (%.2f%% da variância explicada)\n", 
            modelo_summary$r.squared, modelo_summary$r.squared * 100))

# Intervalo de confiança do Beta
ci_beta <- confint(modelo_capm, "excesso_mercado", level = 0.95)
cat(sprintf("\n📊 INTERVALO DE CONFIANÇA (95%%)\n"))
cat(sprintf("   Beta: [%.6f, %.6f]\n", ci_beta[1], ci_beta[2]))

# ----------------------------------------------------------------------------
# 7. MODELO COM ERROS ROBUSTOS (WHITE)
# ----------------------------------------------------------------------------

cat("\n\n📊 MODELO COM ERROS ROBUSTOS (WHITE)\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Correção para heterocedasticidade\n\n")

cov_robust <- vcovHC(modelo_capm, type = "HC1")
modelo_robust <- coeftest(modelo_capm, vcov = cov_robust)
print(modelo_robust)

# ----------------------------------------------------------------------------
# 8. ANÁLISE DE RESÍDUOS (DIAGNÓSTICO)
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              ANÁLISE DE RESÍDUOS (DIAGNÓSTICO)                   ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

residuos <- residuals(modelo_capm)
ajustados <- fitted(modelo_capm)

# 8.1 Teste de normalidade
cat("\n📊 TESTE DE NORMALIDADE DOS RESÍDUOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

shapiro_res <- shapiro.test(residuos[1:min(5000, length(residuos))])
cat(sprintf("Shapiro-Wilk: W = %.4f | p-valor = %.6f\n", 
            shapiro_res$statistic, shapiro_res$p.value))

if(shapiro_res$p.value < 0.05) {
  cat("   ⚠ Resíduos não seguem distribuição normal\n")
} else {
  cat("   ✓ Resíduos seguem distribuição normal\n")
}

# 8.2 Teste de autocorrelação (Durbin-Watson)
cat("\n\n📊 TESTE DE AUTOCORRELAÇÃO (DURBIN-WATSON)\n")
cat("─────────────────────────────────────────────────────────────────────\n")

dw_test <- dwtest(modelo_capm)
cat(sprintf("Durbin-Watson: d = %.4f | p-valor = %.6f\n", 
            dw_test$statistic, dw_test$p.value))

if(dw_test$p.value < 0.05) {
  cat("   ⚠ Autocorrelação significativa nos resíduos\n")
} else {
  cat("   ✓ Sem evidência de autocorrelação\n")
}

# 8.3 Teste de heterocedasticidade (Breusch-Pagan)
cat("\n\n📊 TESTE DE HETEROCEDASTICIDADE (BREUSCH-PAGAN)\n")
cat("─────────────────────────────────────────────────────────────────────\n")

bp_test <- bptest(modelo_capm)
cat(sprintf("Breusch-Pagan: BP = %.4f | p-valor = %.6f\n", 
            bp_test$statistic, bp_test$p.value))

if(bp_test$p.value < 0.05) {
  cat("   ⚠ Heterocedasticidade significativa\n")
  cat("   → Usar erros robustos (White) para correção\n")
} else {
  cat("   ✓ Homocedasticidade: variância constante\n")
}

# 8.4 Teste de especificação (RESET)
cat("\n\n📊 TESTE DE ESPECIFICAÇÃO (RESET)\n")
cat("─────────────────────────────────────────────────────────────────────\n")

reset_test <- resettest(modelo_capm, power = 2:3)
cat(sprintf("RESET: F = %.4f | p-valor = %.6f\n", 
            reset_test$statistic, reset_test$p.value))

if(reset_test$p.value < 0.05) {
  cat("   ⚠ Evidência de má especificação do modelo\n")
} else {
  cat("   ✓ Modelo bem especificado\n")
}

# 8.5 Pontos influentes (Cook's distance)
cat("\n\n📊 ANÁLISE DE PONTOS INFLUENTES\n")
cat("─────────────────────────────────────────────────────────────────────\n")

cooksd <- cooks.distance(modelo_capm)
pontos_influentes <- which(cooksd > 4/length(cooksd))

if(length(pontos_influentes) > 0) {
  cat(sprintf("⚠ Encontrados %d pontos influentes\n", length(pontos_influentes)))
  cat("   Índices:", paste(head(pontos_influentes, 10), collapse = ", "), "\n")
} else {
  cat("   ✓ Nenhum ponto influente detectado\n")
}

# ----------------------------------------------------------------------------
# 9. GRÁFICOS DE DIAGNÓSTICO
# ----------------------------------------------------------------------------

cat("\n🎨 GERANDO GRÁFICOS DE DIAGNÓSTICO\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# 9.1 Gráficos padrão do R
png(file.path(PARTE, "graficos", "03_diagnostico_padrao.png"), 
    width = 12, height = 10, units = "in", res = 300)
par(mfrow = c(2, 2))
plot(modelo_capm, which = 1, main = "Resíduos vs Valores Ajustados")
plot(modelo_capm, which = 2, main = "Q-Q Plot dos Resíduos")
plot(modelo_capm, which = 3, main = "Scale-Location Plot")
plot(modelo_capm, which = 4, main = "Cook's Distance")
par(mfrow = c(1, 1))
dev.off()
cat("   ✅ Gráficos de diagnóstico padrão salvos\n")

# 9.2 Gráfico de resíduos com ggplot2
df_residuos <- data.frame(
  Ajustados = ajustados,
  Residuos = residuos,
  Residuos_Student = rstudent(modelo_capm),
  Cooks_Distance = cooksd
)

p_resid <- ggplot(df_residuos, aes(x = Ajustados, y = Residuos)) +
  geom_point(alpha = 0.5, color = "steelblue") +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  geom_smooth(se = FALSE, color = "darkorange", method = "loess") +
  labs(
    title = "Resíduos vs Valores Ajustados",
    x = "Valores Ajustados",
    y = "Resíduos"
  ) +
  theme_minimal()

ggsave(file.path(PARTE, "graficos", "04_residuos_ajustados.png"), 
       p_resid, width = 10, height = 6, dpi = 300)
cat("   ✅ Gráfico de resíduos salvo\n")

p_qq <- ggplot(df_residuos, aes(sample = Residuos)) +
  stat_qq(alpha = 0.5, color = "steelblue") +
  stat_qq_line(color = "red", linetype = "dashed") +
  labs(
    title = "Q-Q Plot dos Resíduos",
    x = "Quantis Teóricos",
    y = "Quantis Amostrais"
  ) +
  theme_minimal()

ggsave(file.path(PARTE, "graficos", "05_qqplot_residuos.png"), 
       p_qq, width = 8, height = 6, dpi = 300)
cat("   ✅ Q-Q Plot salvo\n")

# 9.3 Histograma dos resíduos
p_hist <- ggplot(df_residuos, aes(x = Residuos)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, 
                 fill = "steelblue", alpha = 0.7) +
  geom_density(color = "darkred", size = 1) +
  labs(
    title = "Histograma dos Resíduos",
    x = "Resíduos",
    y = "Densidade"
  ) +
  theme_minimal()

ggsave(file.path(PARTE, "graficos", "06_histograma_residuos.png"), 
       p_hist, width = 8, height = 6, dpi = 300)
cat("   ✅ Histograma dos resíduos salvo\n")

cat("\n✅ Todos os gráficos salvos em:", file.path(PARTE, "graficos/"), "\n")

# ----------------------------------------------------------------------------
# 10. ANÁLISE DE SENSIBILIDADE - BOOTSTRAP DO BETA
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              BOOTSTRAP DO BETA - ANÁLISE DE SENSIBILIDADE        ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

cat("\n📊 BOOTSTRAP DO BETA (10.000 reamostragens)\n")
cat("─────────────────────────────────────────────────────────────────────\n")

set.seed(123)
n_boot <- 10000
betas_bootstrap <- numeric(n_boot)

for(i in 1:n_boot) {
  indices <- sample(1:nrow(dados_regressao), replace = TRUE)
  dados_boot <- dados_regressao[indices, ]
  modelo_boot <- lm(excesso_ativo ~ excesso_mercado, data = dados_boot)
  betas_bootstrap[i] <- coef(modelo_boot)[2]
}

# Estatísticas do bootstrap
beta_mean <- mean(betas_bootstrap)
beta_sd <- sd(betas_bootstrap)
beta_ci <- quantile(betas_bootstrap, c(0.025, 0.975))

cat(sprintf("Beta estimado: %.6f\n", beta))
cat(sprintf("Beta bootstrap: %.6f\n", beta_mean))
cat(sprintf("Erro padrão bootstrap: %.6f\n", beta_sd))
cat(sprintf("IC 95%% bootstrap: [%.6f, %.6f]\n", beta_ci[1], beta_ci[2]))

# Gráfico da distribuição bootstrap
df_bootstrap <- data.frame(beta = betas_bootstrap)

p_boot <- ggplot(df_bootstrap, aes(x = beta)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, 
                 fill = "steelblue", alpha = 0.7) +
  geom_density(color = "darkred", size = 1) +
  geom_vline(xintercept = beta, color = "darkgreen", linetype = "dashed", size = 1) +
  geom_vline(xintercept = beta_ci[1], color = "orange", linetype = "dotted", size = 0.8) +
  geom_vline(xintercept = beta_ci[2], color = "orange", linetype = "dotted", size = 0.8) +
  labs(
    title = "Distribuição Bootstrap do Beta",
    subtitle = sprintf("10.000 reamostragens | IC 95%%: [%.4f, %.4f]", beta_ci[1], beta_ci[2]),
    x = "Beta",
    y = "Densidade",
    caption = "Linha verde = Beta estimado | Linhas laranja = IC 95%"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5)
  )

ggsave(file.path(PARTE, "graficos", "07_bootstrap_beta.png"), 
       p_boot, width = 10, height = 6, dpi = 300)
cat("   ✅ Gráfico de bootstrap salvo\n")

# ----------------------------------------------------------------------------
# 11. EXPORTAÇÃO DOS RESULTADOS
# ----------------------------------------------------------------------------

cat("\n📁 EXPORTANDO RESULTADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Coeficientes do modelo
coeficientes_df <- data.frame(
  Coeficiente = c("Alfa (α)", "Beta (β)"),
  Estimativa = c(alpha, beta),
  Erro_Padrao = c(modelo_summary$coefficients[1, 2], beta_std),
  t_valor = c(modelo_summary$coefficients[1, 3], beta_t),
  p_valor = c(modelo_summary$coefficients[1, 4], beta_p),
  IC_2_5 = c(confint(modelo_capm)[1, 1], ci_beta[1]),
  IC_97_5 = c(confint(modelo_capm)[1, 2], ci_beta[2])
)

write.csv(coeficientes_df, 
          file.path(PARTE, "resultados", "coeficientes_capm.csv"), 
          row.names = FALSE)
cat("✓ coeficientes_capm.csv\n")

# Métricas do modelo
metricas_df <- data.frame(
  Metrica = c("R²", "R² Ajustado", "F-statistic", "p-valor F", "AIC", "BIC"),
  Valor = c(modelo_summary$r.squared, modelo_summary$adj.r.squared,
            modelo_summary$fstatistic[1], 
            1 - pf(modelo_summary$fstatistic[1], 
                   modelo_summary$fstatistic[2], 
                   modelo_summary$fstatistic[3]),
            AIC(modelo_capm), BIC(modelo_capm))
)

write.csv(metricas_df, 
          file.path(PARTE, "resultados", "metricas_modelo.csv"), 
          row.names = FALSE)
cat("✓ metricas_modelo.csv\n")

# Resultados dos testes de diagnóstico
diagnostico_df <- data.frame(
  Teste = c("Shapiro-Wilk", "Durbin-Watson", "Breusch-Pagan", "RESET"),
  Estatistica = c(shapiro_res$statistic, dw_test$statistic, 
                  bp_test$statistic, reset_test$statistic),
  p_valor = c(shapiro_res$p.value, dw_test$p.value, 
              bp_test$p.value, reset_test$p.value),
  Conclusao = c(
    ifelse(shapiro_res$p.value < 0.05, "Não normal", "Normal"),
    ifelse(dw_test$p.value < 0.05, "Autocorrelação", "Sem autocorrelação"),
    ifelse(bp_test$p.value < 0.05, "Heterocedasticidade", "Homocedasticidade"),
    ifelse(reset_test$p.value < 0.05, "Má especificação", "Bem especificado")
  )
)

write.csv(diagnostico_df, 
          file.path(PARTE, "resultados", "diagnostico_modelo.csv"), 
          row.names = FALSE)
cat("✓ diagnostico_modelo.csv\n")

# Bootstrap do Beta
bootstrap_df <- data.frame(
  beta_estimado = beta,
  beta_bootstrap = beta_mean,
  erro_padrao_bootstrap = beta_sd,
  ic_inferior = beta_ci[1],
  ic_superior = beta_ci[2]
)

write.csv(bootstrap_df, 
          file.path(PARTE, "resultados", "bootstrap_beta.csv"), 
          row.names = FALSE)
cat("✓ bootstrap_beta.csv\n")

# Salvar resultados completos
saveRDS(list(
  dados = dados_regressao,
  modelo = modelo_capm,
  summary = modelo_summary,
  robusto = modelo_robust,
  beta = beta,
  alpha = alpha,
  r2 = modelo_summary$r.squared,
  diagnosticos = list(
    shapiro = shapiro_res,
    dw = dw_test,
    bp = bp_test,
    reset = reset_test
  ),
  bootstrap = betas_bootstrap
), file.path(PARTE, "resultados", "resultados_parte5.rds"))
cat("✓ resultados_parte5.rds\n")

cat("\n✅ Resultados exportados para:", file.path(PARTE, "resultados/"), "\n")

# ----------------------------------------------------------------------------
# 12. SUMÁRIO EXECUTIVO
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              SUMÁRIO EXECUTIVO - PARTE 5                         ║\n")
cat("║                   MODELO CAPM E REGRESSÃO LINEAR                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("📊 RESULTADOS DO MODELO CAPM\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   Ativo analisado: %s\n", ativo_analise))
cat(sprintf("   Beta (β): %.4f\n", beta))
cat(sprintf("   Alfa (α): %.6f\n", alpha))
cat(sprintf("   R²: %.4f (%.2f%%)\n", modelo_summary$r.squared, modelo_summary$r.squared * 100))

cat("\n📊 INTERPRETAÇÃO DO BETA\n")
cat("─────────────────────────────────────────────────────────────────────\n")
if(beta > 1) {
  cat(sprintf("   β = %.4f > 1 → Ativo AGRESSIVO\n", beta))
  cat(sprintf("   O ativo é %.1f%% mais volátil que o mercado\n", (beta - 1) * 100))
} else if(beta < 1) {
  cat(sprintf("   β = %.4f < 1 → Ativo DEFENSIVO\n", beta))
  cat(sprintf("   O ativo é %.1f%% menos volátil que o mercado\n", (1 - beta) * 100))
} else {
  cat(sprintf("   β = %.4f = 1 → Ativo NEUTRO\n", beta))
}

cat("\n📊 DIAGNÓSTICO DO MODELO\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   Teste de normalidade (Shapiro-Wilk): p = %.6f\n", shapiro_res$p.value))
cat(sprintf("   Teste de autocorrelação (Durbin-Watson): p = %.6f\n", dw_test$p.value))
cat(sprintf("   Teste de heterocedasticidade (BP): p = %.6f\n", bp_test$p.value))

cat("\n📊 BOOTSTRAP DO BETA\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   Beta estimado: %.4f\n", beta))
cat(sprintf("   Beta bootstrap: %.4f\n", beta_mean))
cat(sprintf("   IC 95%% bootstrap: [%.4f, %.4f]\n", beta_ci[1], beta_ci[2]))

cat("\n🎯 CONCLUSÃO\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("O %s apresenta um beta de %.4f, sendo um ativo ", ativo_analise, beta))
if(beta > 1) {
  cat("AGRESSIVO.\n")
  cat("Isso significa que o ativo tende a amplificar os movimentos do mercado.\n")
  cat("Em momentos de alta, tende a subir mais; em momentos de baixa, tende a cair mais.\n")
} else if(beta < 1) {
  cat("DEFENSIVO.\n")
  cat("Isso significa que o ativo tende a amortecer os movimentos do mercado.\n")
  cat("Oferece maior proteção em momentos de estresse do mercado.\n")
} else {
  cat("NEUTRO.\n")
  cat("O ativo se move em linha com o mercado.\n")
}

cat("\n📁 ARQUIVOS GERADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("✓ %s/graficos/ - 7 gráficos\n", PARTE))
cat(sprintf("✓ %s/resultados/coeficientes_capm.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/metricas_modelo.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/diagnostico_modelo.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/bootstrap_beta.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_parte5.rds\n", PARTE))
cat("\n")

cat("✅ PARTE 5 CONCLUÍDA COM SUCESSO!\n")

# ============================================================================
# FIM DA PARTE 5
# ============================================================================