# ============================================================================
# PARTE 1: PROVA DA NÃO-NORMALIDADE DOS RETORNOS FINANCEIROS
# ============================================================================
#
# OBJETIVO PRINCIPAL:
#   Demonstrar estatisticamente que os retornos de ativos financeiros
#   NÃO seguem uma distribuição normal, contrariando uma das premissas
#   básicas da teoria financeira clássica.
#
# HIPÓTESES TESTADAS:
#   H0: Os retornos seguem distribuição normal
#   H1: Os retornos NÃO seguem distribuição normal
#
# AUTOR: Ivan Manoel dos Santos da Rosa
# DATA: 2026-03-27
# ============================================================================

# ----------------------------------------------------------------------------
# 1. CONFIGURAÇÃO INICIAL
# ----------------------------------------------------------------------------

# Limpeza do ambiente
rm(list = ls())
gc()

# Configuração de opções globais
options(
  stringsAsFactors = FALSE,
  scipen = 999,
  digits = 6,
  warn = 1
)

# Definir o nome da parte (para organização das pastas)
PARTE <- "Parte_01_Prova_Nao_Normalidade"

# Carregar pacotes
library(yfR)
library(dplyr)
library(tidyr)
library(lubridate)
library(moments)
library(nortest)
library(car)
library(ggplot2)
library(gridExtra)

cat("\n✅ Pacotes carregados com sucesso!\n")

# ----------------------------------------------------------------------------
# 2. CONFIGURAÇÃO DOS ATIVOS E PARÂMETROS
# ----------------------------------------------------------------------------

# Definição dos ativos
ativos_config <- data.frame(
  ticker = c("WEGE3", "HGLG11", "BTC-USD"),
  nome = c("WEG S.A.", "CSHG Logística FII", "Bitcoin"),
  classe = c("Ação Brasileira", "Fundo Imobiliário", "Criptomoeda"),
  moeda = c("BRL", "BRL", "USD"),
  stringsAsFactors = FALSE
)

# Período da análise
periodo <- list(
  inicio = as.Date("2024-01-01"),
  fim = as.Date("2026-03-20")
)

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║     PROJETO: PROVA DA NÃO-NORMALIDADE DOS RETORNOS FINANCEIROS   ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("📊 CONFIGURAÇÃO DA ANÁLISE\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Período:", format(periodo$inicio, "%d/%m/%Y"), 
    "até", format(periodo$fim, "%d/%m/%Y"), "\n")
cat("Ativos:", nrow(ativos_config), "\n\n")

# Exibir ativos
for(i in 1:nrow(ativos_config)) {
  cat(sprintf("   %s - %s (%s)\n", 
              ativos_config$ticker[i], 
              ativos_config$nome[i], 
              ativos_config$classe[i]))
}
cat("\n")

# ----------------------------------------------------------------------------
# 3. COLETA DE DADOS (VIA yfR)
# ----------------------------------------------------------------------------

#' Coleta dados de ativos via yfR
#'
coletar_dados_yfr <- function(tickers, data_inicio, data_fim) {
  cat("\n📥 COLETANDO DADOS VIA yfR\n")
  cat("─────────────────────────────────────────────────────────────────────\n")
  
  # Configurar cache
  cache_dir <- file.path(tempdir(), "yfr_cache")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Dataframe vazio para consolidar
  dados_consolidados <- data.frame()
  
  for(ticker in tickers) {
    cat("Baixando:", ticker, "... ")
    
    # Ajustar ticker para formato yfR
    ticker_yfr <- ticker
    if(ticker %in% c("WEGE3", "HGLG11")) {
      ticker_yfr <- paste0(ticker, ".SA")
    }
    
    dados <- tryCatch({
      yf_get(
        tickers = ticker_yfr,
        first_date = data_inicio,
        last_date = data_fim,
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
    
    if(!is.null(dados) && nrow(dados) > 0) {
      # Criar dataframe com dados processados (usando base R)
      dados_temp <- data.frame(
        symbol = ticker,
        date = as.Date(dados$ref_date),
        adjusted = as.numeric(dados$price_adjusted),
        volume = as.numeric(dados$volume),
        price_open = as.numeric(dados$price_open),
        price_high = as.numeric(dados$price_high),
        price_low = as.numeric(dados$price_low),
        price_close = as.numeric(dados$price_close),
        stringsAsFactors = FALSE
      )
      
      dados_consolidados <- rbind(dados_consolidados, dados_temp)
      cat("✅", nrow(dados), "observações\n")
    } else {
      cat("⚠ Nenhum dado\n")
    }
  }
  
  cat("\n✅ Total coletado:", nrow(dados_consolidados), "observações\n")
  return(dados_consolidados)
}

# Executar coleta
cat("\n🚀 INICIANDO COLETA DE DADOS\n")
cat("═══════════════════════════════════════════════════════════════════════\n")

dados_consolidados <- coletar_dados_yfr(
  tickers = c("WEGE3", "HGLG11", "BTC-USD"),
  data_inicio = periodo$inicio,
  data_fim = periodo$fim
)

# Verificar se os dados foram coletados
if(nrow(dados_consolidados) == 0) {
  stop("❌ Nenhum dado foi coletado. Verifique sua conexão com a internet.")
}

# ----------------------------------------------------------------------------
# 4. RESUMO DOS DADOS COLETADOS
# ----------------------------------------------------------------------------

cat("\n📊 RESUMO DOS DADOS COLETADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Calcular resumo por ativo usando base R
ativos <- unique(dados_consolidados$symbol)
for(ativo in ativos) {
  dados_ativo <- dados_consolidados[dados_consolidados$symbol == ativo, ]
  nome_ativo <- ativos_config$nome[ativos_config$ticker == ativo]
  cat(sprintf("\n%s (%s):\n", ativo, nome_ativo))
  cat(sprintf("   Observações: %d\n", nrow(dados_ativo)))
  cat(sprintf("   Período: %s a %s\n", 
              format(min(dados_ativo$date), "%d/%m/%Y"),
              format(max(dados_ativo$date), "%d/%m/%Y")))
  cat(sprintf("   Preço médio: R$ %.2f\n", mean(dados_ativo$adjusted, na.rm = TRUE)))
}

# ----------------------------------------------------------------------------
# 5. CÁLCULO DE RETORNOS LOGARÍTMICOS
# ----------------------------------------------------------------------------

cat("\n📈 CALCULANDO RETORNOS LOGARÍTMICOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Calcular retornos usando base R (evita conflitos)
retornos_list <- list()

for(ativo in ativos) {
  dados_ativo <- dados_consolidados[dados_consolidados$symbol == ativo, ]
  dados_ativo <- dados_ativo[order(dados_ativo$date), ]
  
  n <- nrow(dados_ativo)
  retornos <- rep(NA, n)
  
  for(i in 2:n) {
    retornos[i] <- log(dados_ativo$adjusted[i] / dados_ativo$adjusted[i-1])
  }
  
  retornos_list[[ativo]] <- data.frame(
    symbol = ativo,
    date = dados_ativo$date,
    retorno_log = retornos,
    retorno_simples = exp(retornos) - 1,
    stringsAsFactors = FALSE
  )
}

# Consolidar retornos
retornos <- do.call(rbind, retornos_list)
retornos <- retornos[!is.na(retornos$retorno_log), ]

# Estatísticas básicas
cat("\n✅ Retornos calculados:\n")
for(ativo in ativos) {
  ret_ativo <- retornos$retorno_log[retornos$symbol == ativo]
  cat(sprintf("\n%s:\n", ativo))
  cat(sprintf("   N: %d\n", length(ret_ativo)))
  cat(sprintf("   Média: %.6f\n", mean(ret_ativo)))
  cat(sprintf("   Mediana: %.6f\n", median(ret_ativo)))
  cat(sprintf("   Desvio Padrão: %.6f\n", sd(ret_ativo)))
}

# ----------------------------------------------------------------------------
# 6. MOMENTOS ESTATÍSTICOS (ASSIMETRIA E CURTOSE)
# ----------------------------------------------------------------------------

cat("\n📊 CALCULANDO MOMENTOS ESTATÍSTICOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

momentos <- data.frame()

for(ativo in ativos) {
  ret_ativo <- retornos$retorno_log[retornos$symbol == ativo]
  
  momentos <- rbind(momentos, data.frame(
    symbol = ativo,
    nome = ativos_config$nome[ativos_config$ticker == ativo],
    classe = ativos_config$classe[ativos_config$ticker == ativo],
    N = length(ret_ativo),
    Media = mean(ret_ativo),
    Mediana = median(ret_ativo),
    Desvio_Padrao = sd(ret_ativo),
    Assimetria = skewness(ret_ativo),
    Curtose = kurtosis(ret_ativo),
    Excesso_Curtose = kurtosis(ret_ativo) - 3,
    Prop_Positivos = mean(ret_ativo > 0),
    Retorno_Acumulado = exp(sum(ret_ativo)) - 1,
    stringsAsFactors = FALSE
  ))
}

cat("\n📈 MOMENTOS ESTATÍSTICOS:\n")
print(momentos[, c("symbol", "nome", "Assimetria", "Curtose", "Excesso_Curtose", "Prop_Positivos")])

# ----------------------------------------------------------------------------
# 7. TESTES DE NORMALIDADE
# ----------------------------------------------------------------------------

cat("\n🔬 APLICANDO TESTES DE NORMALIDADE\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat("Hipótese Nula (H0): Os retornos seguem distribuição normal\n")
cat("Hipótese Alternativa (H1): Os retornos NÃO seguem distribuição normal\n")
cat("Nível de significância: α = 0.05\n\n")

resultados_testes <- data.frame()

for(ativo in ativos) {
  cat("\n📊 ANALISANDO:", ativo, "\n")
  cat("   ", paste(rep("─", nchar(ativo) + 12), collapse = ""), "\n")
  
  ret_ativo <- retornos$retorno_log[retornos$symbol == ativo]
  ret_ativo <- ret_ativo[!is.na(ret_ativo)]
  n <- length(ret_ativo)
  
  # Teste de Shapiro-Wilk
  if(n <= 5000) {
    sw <- shapiro.test(ret_ativo)
    sw_stat <- sw$statistic
    sw_p <- sw$p.value
  } else {
    sw <- shapiro.test(sample(ret_ativo, 5000))
    sw_stat <- sw$statistic
    sw_p <- sw$p.value
  }
  
  # Teste de Jarque-Bera
  assimetria <- skewness(ret_ativo)
  curtose <- kurtosis(ret_ativo)
  jb_stat <- n * (assimetria^2 / 6 + ((curtose - 3)^2) / 24)
  jb_p <- pchisq(jb_stat, df = 2, lower.tail = FALSE)
  
  # Teste de Anderson-Darling
  ad <- ad.test(ret_ativo)
  
  resultados_testes <- rbind(resultados_testes, data.frame(
    Ativo = ativo,
    N = n,
    Shapiro_Wilk_W = sw_stat,
    Shapiro_Wilk_p = sw_p,
    Jarque_Bera_JB = jb_stat,
    Jarque_Bera_p = jb_p,
    Anderson_Darling_A = ad$statistic,
    Anderson_Darling_p = ad$p.value,
    Rejeita_H0 = ifelse(sw_p < 0.05, "SIM", "NÃO"),
    stringsAsFactors = FALSE
  ))
  
  cat(sprintf("   Shapiro-Wilk:     W = %.4f | p = %.2e | %s\n", 
              sw_stat, sw_p, ifelse(sw_p < 0.05, "❌ Rejeita H0", "✅ Não rejeita H0")))
  cat(sprintf("   Jarque-Bera:      JB = %.2f | p = %.2e | %s\n", 
              jb_stat, jb_p, ifelse(jb_p < 0.05, "❌ Rejeita H0", "✅ Não rejeita H0")))
  cat(sprintf("   Anderson-Darling: A = %.4f | p = %.2e | %s\n", 
              ad$statistic, ad$p.value, ifelse(ad$p.value < 0.05, "❌ Rejeita H0", "✅ Não rejeita H0")))
}

# ----------------------------------------------------------------------------
# 8. VISUALIZAÇÕES (SALVANDO NA PASTA DA PARTE 1)
# ----------------------------------------------------------------------------

# Criar pasta para gráficos DENTRO da Parte 1
graficos_dir <- file.path(PARTE, "graficos")
if(!dir.exists(graficos_dir)) {
  dir.create(graficos_dir, recursive = TRUE)
}

cat("\n🎨 GERANDO VISUALIZAÇÕES\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# 1. QQ-Plots com envelope de confiança
cat("✓ Criando QQ-Plots...\n")
for(ativo in ativos) {
  ret_ativo <- retornos$retorno_log[retornos$symbol == ativo]
  ret_ativo <- ret_ativo[!is.na(ret_ativo)]
  
  png(file.path(graficos_dir, sprintf("01_qqplot_%s.png", gsub("-", "_", ativo))),
      width = 8, height = 6, units = "in", res = 300)
  
  qqPlot(ret_ativo,
         distribution = "norm",
         main = paste("Q-Q Plot -", ativo),
         xlab = "Quantis Teóricos (Normal)",
         ylab = "Quantis Observados",
         envelope = 0.95,
         col = "steelblue",
         col.lines = "red")
  
  dev.off()
}
cat("   ✅ QQ-Plots gerados\n")

# 2. Histogramas com curva normal
cat("✓ Criando histogramas...\n")
for(ativo in ativos) {
  ret_ativo <- retornos$retorno_log[retornos$symbol == ativo]
  ret_ativo <- ret_ativo[!is.na(ret_ativo)]
  
  png(file.path(graficos_dir, sprintf("02_histograma_%s.png", gsub("-", "_", ativo))),
      width = 8, height = 6, units = "in", res = 300)
  
  # Criar histograma
  hist_data <- hist(ret_ativo, 
                    breaks = 50,
                    plot = FALSE)
  
  # Plotar histograma
  plot(hist_data, 
       col = "steelblue",
       border = "white",
       main = paste("Histograma -", ativo),
       xlab = "Retorno Logarítmico",
       ylab = "Densidade",
       freq = FALSE,
       ylim = c(0, max(hist_data$density, dnorm(mean(ret_ativo), mean(ret_ativo), sd(ret_ativo))) * 1.2))
  
  # Adicionar curva normal
  curve(dnorm(x, mean(ret_ativo), sd(ret_ativo)), 
        add = TRUE, col = "red", lwd = 2)
  
  # Adicionar legenda
  legend("topright", 
         legend = c("Densidade Empírica", "Normal Teórica"),
         fill = c("steelblue", "red"),
         bty = "n")
  
  dev.off()
}
cat("   ✅ Histogramas gerados\n")
# 3. Boxplots comparativos
cat("✓ Criando boxplots...\n")

png(file.path(graficos_dir, "03_boxplots_comparativos.png"), 
    width = 10, height = 6, units = "in", res = 300)

boxplot(retorno_log ~ symbol, 
        data = retornos,
        main = "Boxplot dos Retornos por Ativo",
        xlab = "Ativo",
        ylab = "Retorno Logarítmico",
        col = c("#2E86AB", "#A23B72", "#F18F01"),
        notch = TRUE)

dev.off()
cat("   ✅ Boxplots gerados\n")

# 4. Gráfico de p-valores
# 4. Gráfico de p-valores (Versão 3 - Pontos e Linhas)
cat("✓ Criando gráfico de p-valores...\n")

# Criar dataframe com todos os p-valores
pvalores_df <- data.frame(
  Ativo = rep(resultados_testes$Ativo, 3),
  Teste = rep(c("Shapiro-Wilk", "Jarque-Bera", "Anderson-Darling"), each = nrow(resultados_testes)),
  p_valor = c(resultados_testes$Shapiro_Wilk_p, 
              resultados_testes$Jarque_Bera_p,
              resultados_testes$Anderson_Darling_p)
)

# Converter para numérico
pvalores_df$p_valor <- as.numeric(pvalores_df$p_valor)

# Criar o gráfico com ggplot2 (Versão 3 - Pontos e Linhas)
library(ggplot2)

p <- ggplot(pvalores_df, aes(x = Teste, y = p_valor, color = Ativo, shape = Ativo)) +
  geom_point(size = 5, alpha = 0.9) +
  geom_line(aes(group = Ativo), linetype = "dotted", alpha = 0.5) +
  geom_hline(yintercept = 0.05, color = "#e74c3c", linetype = "dashed", size = 1) +
  scale_color_manual(
    values = c("WEGE3" = "#3498db", "HGLG11" = "#e67e22", "BTC-USD" = "#2ecc71"),
    labels = c("WEGE3 (Ação)", "HGLG11 (FII)", "BTC-USD (Bitcoin)")
  ) +
  scale_shape_manual(
    values = c("WEGE3" = 16, "HGLG11" = 17, "BTC-USD" = 18),
    labels = c("WEGE3 (Ação)", "HGLG11 (FII)", "BTC-USD (Bitcoin)")
  ) +
  scale_y_log10(
    breaks = c(1e-150, 1e-100, 1e-50, 1e-20, 1e-10, 0.001, 0.01, 0.05, 0.1, 0.5, 1),
    labels = c("10⁻¹⁵⁰", "10⁻¹⁰⁰", "10⁻⁵⁰", "10⁻²⁰", "10⁻¹⁰", "0.001", "0.01", "0.05", "0.1", "0.5", "1")
  ) +
  labs(
    title = "Análise de Normalidade dos Retornos",
    subtitle = "p-valores dos testes estatísticos por ativo",
    x = "",
    y = "p-valor (escala logarítmica)",
    color = "Ativo",
    shape = "Ativo",
    caption = "Todos os pontos estão abaixo de 0.05 → forte evidência contra a normalidade"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    plot.caption = element_text(size = 8, color = "gray50", hjust = 0, margin = margin(t = 10)),
    legend.position = "bottom",
    legend.box = "vertical",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9),
    axis.title.y = element_text(face = "bold", size = 11, margin = margin(r = 10)),
    axis.text.x = element_text(face = "bold", size = 11, color = "gray30"),
    axis.text.y = element_text(size = 9),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

# Salvar
ggsave(file.path(graficos_dir, "04_pvalores_testes.png"), 
       p, width = 10, height = 7, dpi = 300)

cat("   ✅ Gráfico de p-valores gerado\n")
# 9. EXPORTAÇÃO DOS RESULTADOS (SALVANDO NA PASTA DA PARTE 1)
# ----------------------------------------------------------------------------

# Criar pasta para resultados DENTRO da Parte 1
resultados_dir <- file.path(PARTE, "resultados")
if(!dir.exists(resultados_dir)) {
  dir.create(resultados_dir, recursive = TRUE)
}

cat("\n📁 EXPORTANDO RESULTADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Exportar retornos
write.csv(retornos, file.path(resultados_dir, "retornos_calculados.csv"), row.names = FALSE)
cat("✓ retornos_calculados.csv\n")

# Exportar momentos
write.csv(momentos, file.path(resultados_dir, "momentos_estatisticos.csv"), row.names = FALSE)
cat("✓ momentos_estatisticos.csv\n")

# Exportar testes
write.csv(resultados_testes, file.path(resultados_dir, "testes_normalidade.csv"), row.names = FALSE)
cat("✓ testes_normalidade.csv\n")

# Salvar em formato RDS
saveRDS(list(
  dados = dados_consolidados,
  retornos = retornos,
  momentos = momentos,
  testes = resultados_testes
), file.path(resultados_dir, "resultados_parte1.rds"))
cat("✓ resultados_parte1.rds\n")

cat("\n✅ Resultados exportados para:", resultados_dir, "\n")

# ----------------------------------------------------------------------------
# 10. SUMÁRIO EXECUTIVO
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              SUMÁRIO EXECUTIVO - PARTE 1                         ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("📊 RESULTADOS DOS TESTES DE NORMALIDADE\n")
cat("─────────────────────────────────────────────────────────────────────\n")
for(i in 1:nrow(resultados_testes)) {
  cat(sprintf("\n%s:\n", resultados_testes$Ativo[i]))
  cat(sprintf("   Shapiro-Wilk p-valor: %.2e\n", resultados_testes$Shapiro_Wilk_p[i]))
  cat(sprintf("   Jarque-Bera p-valor: %.2e\n", resultados_testes$Jarque_Bera_p[i]))
  cat(sprintf("   Anderson-Darling p-valor: %.2e\n", resultados_testes$Anderson_Darling_p[i]))
  cat(sprintf("   Conclusão: %s\n", resultados_testes$Rejeita_H0[i]))
}

cat("\n🎯 CONCLUSÃO GERAL\n")
cat("─────────────────────────────────────────────────────────────────────\n")

n_rejeita <- sum(resultados_testes$Rejeita_H0 == "SIM")
n_total <- nrow(resultados_testes)

if(n_rejeita == n_total) {
  cat("❌ TODOS os ativos rejeitam a hipótese de normalidade.\n")
  cat("   → Retornos financeiros NÃO seguem distribuição normal.\n")
  cat("   → Modelos baseados na normalidade devem ser usados com cautela.\n")
  cat("   → Recomendado usar modelos que consideram caudas pesadas.\n")
} else if(n_rejeita > 0) {
  cat("⚠ ALGUNS ativos rejeitam a hipótese de normalidade.\n")
  cat("   → Há evidência de não-normalidade em parte da amostra.\n")
} else {
  cat("✅ NENHUM ativo rejeita a hipótese de normalidade.\n")
  cat("   → Não há evidência de não-normalidade para os ativos analisados.\n")
}

cat("\n📁 ARQUIVOS GERADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("✓ %s/resultados/retornos_calculados.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/momentos_estatisticos.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/testes_normalidade.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_parte1.rds\n", PARTE))
cat(sprintf("✓ %s/graficos/ - 8 gráficos da análise\n", PARTE))
cat("\n")

cat("✅ PARTE 1 CONCLUÍDA COM SUCESSO!\n")
cat(sprintf("   Gráficos salvos em: %s/graficos/\n", PARTE))
cat(sprintf("   Resultados salvos em: %s/resultados/\n", PARTE))

# ============================================================================
# FIM DA PARTE 1
# ============================================================================
