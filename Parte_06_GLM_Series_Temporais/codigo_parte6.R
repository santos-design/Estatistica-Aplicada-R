# ============================================================================
# PARTE 6: MODELOS LINEARES GENERALIZADOS (GLM) E SÉRIES TEMPORAIS (ARIMA)
# ============================================================================
#
# AUTOR: Ivan Santos
# DATA: 2026-04-06
# ============================================================================

# ----------------------------------------------------------------------------
# 1. CONFIGURAÇÃO INICIAL
# ----------------------------------------------------------------------------

rm(list = ls())
gc()

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  digits = 6,
  warn = 1
)

PARTE <- "Parte_06_GLM_Series_Temporais"

if(!dir.exists(file.path(PARTE, "graficos"))) {
  dir.create(file.path(PARTE, "graficos"), recursive = TRUE)
}
if(!dir.exists(file.path(PARTE, "resultados"))) {
  dir.create(file.path(PARTE, "resultados"), recursive = TRUE)
}

library(yfR)
library(dplyr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(forecast)
library(tseries)
library(lmtest)
library(pROC)
library(caret)

cat("\n✅ Pacotes carregados com sucesso!\n")

# ----------------------------------------------------------------------------
# 2. CARREGAR DADOS DAS PARTES ANTERIORES
# ----------------------------------------------------------------------------

cat("\n📊 CARREGANDO DADOS DAS PARTES ANTERIORES\n")
cat("─────────────────────────────────────────────────────────────────────\n")

if(file.exists("Parte_01_Prova_Nao_Normalidade/resultados/retornos_calculados.csv")) {
  retornos <- read.csv("Parte_01_Prova_Nao_Normalidade/resultados/retornos_calculados.csv")
  cat("✅ Dados da Parte 1 carregados!\n")
} else {
  stop("❌ Dados da Parte 1 não encontrados.")
}

names(retornos)[names(retornos) == "retorno_log"] <- "retorno"
retornos$date <- as.Date(retornos$date)

if(file.exists("Parte_05_Regressao_Linear_CAPM/resultados/resultados_parte5.rds")) {
  resultados_parte5 <- readRDS("Parte_05_Regressao_Linear_CAPM/resultados/resultados_parte5.rds")
  dados_ibov <- resultados_parte5$dados %>%
    select(date, retorno_mercado)
  cat("✅ Dados do Ibovespa carregados da Parte 5!\n")
} else {
  periodo <- list(inicio = as.Date("2024-01-01"), fim = as.Date("2026-03-20"))
  cache_dir <- file.path(tempdir(), "yfr_cache")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  dados_ibov <- yf_get(
    tickers = "^BVSP",
    first_date = periodo$inicio,
    last_date = periodo$fim,
    freq_data = "daily",
    type_return = "log",
    do_cache = TRUE,
    cache_folder = cache_dir,
    do_complete_data = TRUE
  ) %>%
    mutate(retorno_mercado = ret_adjusted_prices, date = as.Date(ref_date)) %>%
    select(date, retorno_mercado)
  
  cat("✅ Dados do Ibovespa baixados!\n")
}

retornos_btc <- retornos %>%
  filter(symbol == "BTC-USD") %>%
  arrange(date) %>%
  pull(retorno)

cat("\n📈 ESTATÍSTICAS DOS DADOS CARREGADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   Retornos BTC: %d observações\n", length(retornos_btc)))
cat(sprintf("   Retornos Ibovespa: %d observações\n", nrow(dados_ibov)))
cat(sprintf("   Período: %s a %s\n", 
            format(min(retornos$date), "%d/%m/%Y"),
            format(max(retornos$date), "%d/%m/%Y")))

# ----------------------------------------------------------------------------
# 3. REGRESSÃO LOGÍSTICA
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║         REGRESSÃO LOGÍSTICA - PREVISÃO DE EVENTOS EXTREMOS       ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

dados_logistico <- retornos %>%
  filter(symbol == "WEGE3") %>%
  left_join(dados_ibov, by = "date") %>%
  drop_na() %>%
  mutate(
    crise = ifelse(retorno < -0.02, 1, 0),
    retorno_mercado_pct = retorno_mercado * 100
  )

cat("\n📊 DISTRIBUIÇÃO DO EVENTO DE CRISE\n")
cat("─────────────────────────────────────────────────────────────────────\n")
n_total <- nrow(dados_logistico)
n_crises <- sum(dados_logistico$crise)
cat(sprintf("   Total: %d dias\n", n_total))
cat(sprintf("   Dias com crise (retorno < -2%%): %d (%.2f%%)\n", n_crises, n_crises / n_total * 100))

modelo_logistico <- glm(crise ~ retorno_mercado_pct, 
                        data = dados_logistico, 
                        family = binomial(link = "logit"))

print(summary(modelo_logistico))

odds_ratio <- exp(coef(modelo_logistico))
cat("\n📈 ODDS RATIO\n")
cat(sprintf("   retorno_mercado_pct: %.4f\n", odds_ratio[2]))

if(odds_ratio[2] > 1) {
  cat(sprintf("   → Para cada queda de 1%% no Ibovespa, a chance de crise aumenta %.1f%%\n", (odds_ratio[2] - 1) * 100))
} else {
  cat(sprintf("   → Para cada queda de 1%% no Ibovespa, a chance de crise diminui %.1f%%\n", (1 - odds_ratio[2]) * 100))
}

# ----------------------------------------------------------------------------
# 4. AVALIAÇÃO DO MODELO LOGÍSTICO
# ----------------------------------------------------------------------------

cat("\n📊 AVALIAÇÃO DO MODELO LOGÍSTICO\n")
cat("─────────────────────────────────────────────────────────────────────\n")

probabilidades <- predict(modelo_logistico, type = "response")
predicoes_binarias <- ifelse(probabilidades > 0.5, 1, 0)

conf_matrix <- table(Predito = predicoes_binarias, Real = dados_logistico$crise)
cat("\n📋 MATRIZ DE CONFUSÃO\n")
print(conf_matrix)

acuracia <- mean(predicoes_binarias == dados_logistico$crise)
cat(sprintf("\n   Acurácia: %.2f%%\n", acuracia * 100))

roc_obj <- roc(dados_logistico$crise, probabilidades)
auc_value <- auc(roc_obj)
cat(sprintf("   AUC: %.4f\n", auc_value))

# ----------------------------------------------------------------------------
# 5. MODELO ARIMA
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              MODELAGEM ARIMA - SÉRIES TEMPORAIS                  ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

serie_btc <- ts(retornos_btc, frequency = 252)

adf_test <- adf.test(serie_btc, alternative = "stationary")
cat("\n📊 TESTE DE ESTACIONARIEDADE (ADF)\n")
cat(sprintf("   p-valor = %.6f\n", adf_test$p.value))
cat(ifelse(adf_test$p.value < 0.05, "   ✓ Série estacionária\n", "   ⚠ Série não estacionária\n"))

set.seed(123)
modelo_arima <- auto.arima(serie_btc, max.p = 5, max.q = 5, max.d = 1,
                           seasonal = FALSE, stepwise = FALSE, approximation = FALSE)

cat("\n📈 MODELO SELECIONADO\n")
print(modelo_arima)

ordem <- arimaorder(modelo_arima)
cat(sprintf("\nOrdem: ARIMA(%d, %d, %d)\n", ordem[1], ordem[2], ordem[3]))

horizonte <- 10
previsoes <- forecast(modelo_arima, h = horizonte)

cat("\n📊 PREVISÕES PARA OS PRÓXIMOS 10 DIAS\n")
previsoes_df <- data.frame(
  Dia = 1:horizonte,
  Previsao = as.numeric(previsoes$mean),
  LI_80 = as.numeric(previsoes$lower[, 1]),
  LS_80 = as.numeric(previsoes$upper[, 1]),
  LI_95 = as.numeric(previsoes$lower[, 2]),
  LS_95 = as.numeric(previsoes$upper[, 2])
)
print(previsoes_df)

retorno_acumulado <- sum(previsoes$mean)
cat(sprintf("\n   Retorno acumulado esperado: %.4f%%\n", retorno_acumulado * 100))

# ----------------------------------------------------------------------------
# 6. VISUALIZAÇÕES
# ----------------------------------------------------------------------------

cat("\n🎨 GERANDO VISUALIZAÇÕES\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Curva ROC
png(file.path(PARTE, "graficos", "01_curva_roc.png"), width = 8, height = 8, units = "in", res = 300)
plot(roc_obj, main = paste("Curva ROC - AUC =", round(auc_value, 4)), col = "steelblue", lwd = 2)
abline(a = 0, b = 1, lty = 2, col = "gray50")
dev.off()
cat("   ✅ Curva ROC salva\n")

# Previsões ARIMA
png(file.path(PARTE, "graficos", "02_previsoes_arima.png"), width = 12, height = 7, units = "in", res = 300)
plot(previsoes, main = "Previsão de Retornos do Bitcoin - ARIMA")
dev.off()
cat("   ✅ Previsões ARIMA salvas\n")

# Série temporal
png(file.path(PARTE, "graficos", "03_serie_temporal.png"), width = 12, height = 6, units = "in", res = 300)
plot(serie_btc, main = "Série Temporal: Retornos Diários do Bitcoin", ylab = "Retorno", xlab = "Tempo")
abline(h = 0, col = "red", lty = 2)
dev.off()
cat("   ✅ Série temporal salva\n")

cat("\n✅ Gráficos salvos em:", file.path(PARTE, "graficos/"), "\n")

# ----------------------------------------------------------------------------
# 7. EXPORTAÇÃO
# ----------------------------------------------------------------------------

cat("\n📁 EXPORTANDO RESULTADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

coeficientes_df <- data.frame(
  Variavel = names(coef(modelo_logistico)),
  Coeficiente = coef(modelo_logistico),
  Odds_Ratio = odds_ratio,
  p_valor = summary(modelo_logistico)$coefficients[, 4]
)
write.csv(coeficientes_df, file.path(PARTE, "resultados", "coeficientes_logistico.csv"), row.names = FALSE)
cat("✓ coeficientes_logistico.csv\n")

write.csv(previsoes_df, file.path(PARTE, "resultados", "previsoes_arima.csv"), row.names = FALSE)
cat("✓ previsoes_arima.csv\n")

saveRDS(list(
  modelo_logistico = modelo_logistico,
  auc = auc_value,
  modelo_arima = modelo_arima,
  previsoes = previsoes
), file.path(PARTE, "resultados", "resultados_parte6.rds"))
cat("✓ resultados_parte6.rds\n")

# ----------------------------------------------------------------------------
# 8. SUMÁRIO
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              SUMÁRIO EXECUTIVO - PARTE 6                         ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("📊 REGRESSÃO LOGÍSTICA\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   Odds Ratio: %.4f\n", odds_ratio[2]))
cat(sprintf("   AUC: %.4f\n", auc_value))
cat(sprintf("   Acurácia: %.2f%%\n", acuracia * 100))

cat("\n📊 MODELO ARIMA\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("   Ordem: ARIMA(%d, %d, %d)\n", ordem[1], ordem[2], ordem[3]))
cat(sprintf("   AIC: %.2f\n", AIC(modelo_arima)))
cat(sprintf("   Retorno acumulado esperado: %.4f%%\n", retorno_acumulado * 100))

cat("\n✅ PARTE 6 CONCLUÍDA COM SUCESSO!\n")
cat("🎉 PROJETO COMPLETO - 6 PARTES FINALIZADAS! 🎉\n")

# ============================================================================
# FIM DA PARTE 6
# ============================================================================s