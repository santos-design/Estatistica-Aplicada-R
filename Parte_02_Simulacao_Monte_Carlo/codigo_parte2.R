# ============================================================================
# PARTE 2: SIMULAÇÃO DE MONTE CARLO E ANÁLISE DE RISCO
# ============================================================================
#
# OBJETIVO:
#   Estimar a distribuição de probabilidade do patrimônio futuro através
#   de Simulação de Monte Carlo, utilizando bootstrap dos retornos históricos.
#
# CONCEITOS:
#   - Bootstrap: Reamostragem com reposição dos dados históricos
#   - Value at Risk (VaR): Pior perda esperada dentro de um nível de confiança
#   - Conditional VaR (CVaR): Média das perdas que excedem o VaR
#   - Drawdown: Queda máxima do patrimônio em relação ao pico
#
# AUTOR: Ivan Santos
# DATA: 2026-03-27
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
PARTE <- "Parte_02_Simulacao_Monte_Carlo"

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

cat("\n✅ Pacotes carregados com sucesso!\n")

# ----------------------------------------------------------------------------
# 2. CARREGAR DADOS DA PARTE 1
# ----------------------------------------------------------------------------

cat("\n📊 CARREGANDO DADOS DA PARTE 1\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Carregar os retornos calculados na Parte 1
if(file.exists("Parte_01_Prova_Nao_Normalidade/resultados/retornos_calculados.csv")) {
  retornos <- read.csv("Parte_01_Prova_Nao_Normalidade/resultados/retornos_calculados.csv")
  cat("✅ Dados carregados com sucesso!\n")
  cat("   Total de observações:", nrow(retornos), "\n")
  cat("   Ativos:", paste(unique(retornos$symbol), collapse = ", "), "\n")
} else {
  # Se não existir, baixar novamente
  cat("⚠ Dados não encontrados. Coletando novamente...\n")
  
  # Período
  periodo <- list(
    inicio = as.Date("2024-01-01"),
    fim = as.Date("2026-03-20")
  )
  
  # Função de coleta
  coletar_dados <- function(tickers, data_inicio, data_fim) {
    cache_dir <- file.path(tempdir(), "yfr_cache")
    dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
    
    dados_consolidados <- data.frame()
    
    for(ticker in tickers) {
      cat("Baixando:", ticker, "... ")
      
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
        dados_temp <- data.frame(
          symbol = ticker,
          date = as.Date(dados$ref_date),
          adjusted = dados$price_adjusted,
          stringsAsFactors = FALSE
        )
        dados_consolidados <- rbind(dados_consolidados, dados_temp)
        cat("✅", nrow(dados), "obs\n")
      }
    }
    return(dados_consolidados)
  }
  
  # Coletar dados
  dados <- coletar_dados(c("WEGE3", "HGLG11", "BTC-USD"), 
                         periodo$inicio, periodo$fim)
  
  # Calcular retornos
  retornos <- dados %>%
    group_by(symbol) %>%
    arrange(date) %>%
    mutate(retorno_log = log(adjusted / lag(adjusted))) %>%
    filter(!is.na(retorno_log)) %>%
    select(symbol, date, retorno_log)
  
  cat("✅ Dados coletados com sucesso!\n")
}

# ----------------------------------------------------------------------------
# 3. PARÂMETROS DA SIMULAÇÃO
# ----------------------------------------------------------------------------

cat("\n🎲 CONFIGURANDO SIMULAÇÃO DE MONTE CARLO\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Parâmetros gerais
investimento_inicial <- 10000  # R$ 10.000
horizonte_dias <- 252           # 1 ano (dias úteis)
n_simulacoes <- 10000           # Número de cenários simulados
nivel_confianca <- 0.95         # Nível de confiança para VaR

# Selecionar ativo para análise (pode mudar para "HGLG11" ou "BTC-USD")
ativo_analise <- "WEGE3"

# Extrair retornos do ativo selecionado
retornos_ativos <- retornos$retorno_log[retornos$symbol == ativo_analise]

cat("\n📊 PARÂMETROS DA SIMULAÇÃO\n")
cat(sprintf("   Ativo analisado: %s\n", ativo_analise))
cat(sprintf("   Investimento inicial: R$ %s\n", format(investimento_inicial, big.mark = ".")))
cat(sprintf("   Horizonte: %d dias úteis (1 ano)\n", horizonte_dias))
cat(sprintf("   Número de simulações: %s\n", format(n_simulacoes, big.mark = ".")))
cat(sprintf("   Nível de confiança: %.0f%%\n", nivel_confianca * 100))

# Estatísticas dos retornos históricos
cat("\n📈 ESTATÍSTICAS DOS RETORNOS HISTÓRICOS\n")
cat(sprintf("   Média diária: %.4f%%\n", mean(retornos_ativos) * 100))
cat(sprintf("   Volatilidade diária: %.2f%%\n", sd(retornos_ativos) * 100))
cat(sprintf("   Retorno anualizado: %.2f%%\n", mean(retornos_ativos) * 252 * 100))
cat(sprintf("   Volatilidade anualizada: %.2f%%\n", sd(retornos_ativos) * sqrt(252) * 100))

# ----------------------------------------------------------------------------
# 4. FUNÇÃO DE SIMULAÇÃO (BOOTSTRAP)
# ----------------------------------------------------------------------------

#' Simula um único caminho de preços via bootstrap
#'
#' @param retornos_hist Vetor com retornos históricos
#' @param investimento Valor inicial
#' @param n_dias Número de dias a simular
#' @return Vetor com o caminho dos preços
#'
simular_caminho <- function(retornos_hist, investimento, n_dias) {
  # Amostragem com reposição (bootstrap)
  retornos_sim <- sample(retornos_hist, size = n_dias, replace = TRUE)
  
  # Cálculo do caminho: P(t) = P(0) * exp(Σ retornos)
  caminho <- investimento * exp(cumsum(retornos_sim))
  
  return(caminho)
}

# ----------------------------------------------------------------------------
# 5. EXECUTAR SIMULAÇÕES
# ----------------------------------------------------------------------------

cat("\n🎲 EXECUTANDO SIMULAÇÕES\n")
cat("─────────────────────────────────────────────────────────────────────\n")

set.seed(123)  # Para reprodutibilidade

# Matriz para armazenar resultados (dias x simulações)
resultados <- matrix(NA, nrow = horizonte_dias, ncol = n_simulacoes)

# Barra de progresso
cat("Progresso: ")

for(i in 1:n_simulacoes) {
  resultados[, i] <- simular_caminho(retornos_ativos, investimento_inicial, horizonte_dias)
  
  # Atualizar barra a cada 500 simulações
  if(i %% 500 == 0) {
    cat(sprintf("%.0f%% ", i / n_simulacoes * 100))
  }
}

cat("\n\n✅ Simulações concluídas!\n")

# Nomes para as linhas e colunas
rownames(resultados) <- paste0("dia_", 1:horizonte_dias)
colnames(resultados) <- paste0("sim_", 1:n_simulacoes)

# ----------------------------------------------------------------------------
# 6. ANÁLISE DOS RESULTADOS
# ----------------------------------------------------------------------------

cat("\n📊 ANÁLISE DOS RESULTADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Valores finais (último dia de cada simulação)
valores_finais <- resultados[horizonte_dias, ]

# Estatísticas básicas
media_final <- mean(valores_finais)
mediana_final <- median(valores_finais)
min_final <- min(valores_finais)
max_final <- max(valores_finais)
dp_final <- sd(valores_finais)

# Probabilidades
prob_lucro <- mean(valores_finais > investimento_inicial) * 100
prob_prejuizo <- mean(valores_finais < investimento_inicial) * 100

# Value at Risk (VaR)
var_90 <- quantile(valores_finais, 0.10)
var_95 <- quantile(valores_finais, 0.05)
var_99 <- quantile(valores_finais, 0.01)

# Conditional VaR (Expected Shortfall)
cvar_95 <- mean(valores_finais[valores_finais <= var_95])

# Retorno esperado
retorno_esperado <- (media_final / investimento_inicial - 1) * 100

cat("\n📈 ESTATÍSTICAS DOS VALORES FINAIS (R$)\n")
cat(sprintf("   Média: R$ %s\n", format(round(media_final, 2), big.mark = ".")))
cat(sprintf("   Mediana: R$ %s\n", format(round(mediana_final, 2), big.mark = ".")))
cat(sprintf("   Desvio Padrão: R$ %s\n", format(round(dp_final, 2), big.mark = ".")))
cat(sprintf("   Mínimo: R$ %s\n", format(round(min_final, 2), big.mark = ".")))
cat(sprintf("   Máximo: R$ %s\n", format(round(max_final, 2), big.mark = ".")))

cat("\n📊 PROBABILIDADES\n")
cat(sprintf("   Lucro: %.1f%%\n", prob_lucro))
cat(sprintf("   Prejuízo: %.1f%%\n", prob_prejuizo))
cat(sprintf("   Retorno esperado: %.1f%%\n", retorno_esperado))

cat("\n📊 VALUE AT RISK (VaR)\n")
cat(sprintf("   VaR 90%%: R$ %s\n", format(round(var_90, 2), big.mark = ".")))
cat(sprintf("   VaR 95%%: R$ %s\n", format(round(var_95, 2), big.mark = ".")))
cat(sprintf("   VaR 99%%: R$ %s\n", format(round(var_99, 2), big.mark = ".")))
cat(sprintf("   CVaR 95%%: R$ %s (média dos piores 5%% cenários)\n", 
            format(round(cvar_95, 2), big.mark = ".")))

# ----------------------------------------------------------------------------
# 7. ANÁLISE DE DRAWDOWN
# ----------------------------------------------------------------------------

cat("\n📉 ANÁLISE DE DRAWDOWN (Máxima Queda)\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Função para calcular drawdown máximo de um caminho
calcular_drawdown <- function(caminho) {
  pico <- cummax(caminho)
  drawdown <- (pico - caminho) / pico
  return(max(drawdown, na.rm = TRUE))
}

# Calcular drawdown para todas as simulações
drawdowns <- apply(resultados, 2, calcular_drawdown)

# Estatísticas de drawdown
dd_medio <- mean(drawdowns) * 100
dd_mediano <- median(drawdowns) * 100
dd_p95 <- quantile(drawdowns, 0.95) * 100
dd_max <- max(drawdowns) * 100

cat(sprintf("   Drawdown médio: %.1f%%\n", dd_medio))
cat(sprintf("   Drawdown mediano: %.1f%%\n", dd_mediano))
cat(sprintf("   Drawdown p95: %.1f%%\n", dd_p95))
cat(sprintf("   Drawdown máximo: %.1f%%\n", dd_max))

# ----------------------------------------------------------------------------
# 8. VISUALIZAÇÕES
# ----------------------------------------------------------------------------

cat("\n🎨 GERANDO VISUALIZAÇÕES\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# 1. Evolução dos caminhos simulados (amostra de 500)
cat("✓ Criando gráfico de evolução...\n")

n_amostra <- min(500, n_simulacoes)
indices_amostra <- sample(1:n_simulacoes, n_amostra)

df_caminhos <- data.frame()
for(i in indices_amostra) {
  df_caminhos <- rbind(df_caminhos, data.frame(
    dia = 1:horizonte_dias,
    valor = resultados[, i],
    simulacao = i
  ))
}

p_caminhos <- ggplot(df_caminhos, aes(x = dia, y = valor, group = simulacao)) +
  geom_line(alpha = 0.1, color = "steelblue") +
  geom_hline(yintercept = investimento_inicial, color = "darkgreen", 
             linetype = "dashed", size = 1) +
  labs(
    title = "Simulação de Monte Carlo - Evolução do Patrimônio",
    subtitle = sprintf("%s cenários simulados | Ativo: %s", 
                       format(n_simulacoes, big.mark = "."), ativo_analise),
    x = "Dias Úteis",
    y = "Valor do Patrimônio (R$)",
    caption = "Cada linha cinza representa um cenário possível | Linha verde = investimento inicial"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    plot.caption = element_text(hjust = 0, face = "italic")
  ) +
  scale_y_continuous(labels = scales::label_currency(prefix = "R$", big.mark = "."))

ggsave(file.path(PARTE, "graficos", "01_caminhos_simulacao.png"), 
       p_caminhos, width = 12, height = 7, dpi = 300)
cat("   ✅ Gráfico de evolução salvo\n")

# 2. Distribuição dos valores finais
cat("✓ Criando histograma dos valores finais...\n")

df_finais <- data.frame(valor = valores_finais)

p_hist <- ggplot(df_finais, aes(x = valor)) +
  geom_histogram(aes(y = after_stat(density)), bins = 100, 
                 fill = "steelblue", alpha = 0.7) +
  geom_density(color = "darkred", size = 1) +
  geom_vline(xintercept = investimento_inicial, color = "darkgreen", 
             linetype = "dashed", size = 1) +
  geom_vline(xintercept = media_final, color = "red", 
             linetype = "dashed", size = 1) +
  labs(
    title = "Distribuição dos Valores Finais após 1 Ano",
    subtitle = sprintf("Média: R$ %s | Mediana: R$ %s",
                       format(round(media_final, 2), big.mark = "."),
                       format(round(mediana_final, 2), big.mark = ".")),
    x = "Valor Final (R$)",
    y = "Densidade",
    caption = "Linha verde = investimento inicial | Linha vermelha = média"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5)
  ) +
  scale_x_continuous(labels = scales::label_currency(prefix = "R$", big.mark = "."))

ggsave(file.path(PARTE, "graficos", "02_distribuicao_valores_finais.png"), 
       p_hist, width = 10, height = 6, dpi = 300)
cat("   ✅ Histograma salvo\n")

# 3. Boxplot temporal
cat("✓ Criando boxplot temporal...\n")

dias_amostra <- round(seq(1, horizonte_dias, length.out = 15))
df_temporal <- data.frame()

for(dia in dias_amostra) {
  df_temporal <- rbind(df_temporal, data.frame(
    dia = factor(dia),
    valor = resultados[dia, ]
  ))
}

p_boxplot <- ggplot(df_temporal, aes(x = dia, y = valor)) +
  geom_boxplot(fill = "steelblue", alpha = 0.7, outlier.alpha = 0.3) +
  geom_hline(yintercept = investimento_inicial, color = "darkgreen", 
             linetype = "dashed", size = 1) +
  labs(
    title = "Evolução da Distribuição do Patrimônio",
    subtitle = "Boxplots mostram a dispersão dos valores ao longo do tempo",
    x = "Dias Úteis",
    y = "Valor do Patrimônio (R$)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  scale_y_continuous(labels = scales::label_currency(prefix = "R$", big.mark = "."))

ggsave(file.path(PARTE, "graficos", "03_boxplot_temporal.png"), 
       p_boxplot, width = 12, height = 6, dpi = 300)
cat("   ✅ Boxplot temporal salvo\n")

# 4. Análise de drawdown
cat("✓ Criando análise de drawdown...\n")

df_drawdown <- data.frame(drawdown = drawdowns * 100)

p_drawdown <- ggplot(df_drawdown, aes(x = drawdown)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, 
                 fill = "coral", alpha = 0.7) +
  geom_density(color = "darkred", size = 1) +
  geom_vline(xintercept = dd_medio, color = "red", linetype = "dashed", size = 1) +
  geom_vline(xintercept = dd_p95, color = "orange", linetype = "dashed", size = 1) +
  labs(
    title = "Análise de Drawdown - Máxima Queda do Patrimônio",
    subtitle = sprintf("Drawdown médio: %.1f%% | Drawdown p95: %.1f%%", dd_medio, dd_p95),
    x = "Drawdown Máximo (%)",
    y = "Densidade"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5)
  )

ggsave(file.path(PARTE, "graficos", "04_analise_drawdown.png"), 
       p_drawdown, width = 10, height = 6, dpi = 300)
cat("   ✅ Análise de drawdown salva\n")

# 5. Função de distribuição acumulada
cat("✓ Criando função de distribuição acumulada...\n")

p_cdf <- ggplot(df_finais, aes(x = valor)) +
  stat_ecdf(geom = "step", color = "steelblue", size = 1.2) +
  geom_vline(xintercept = investimento_inicial, color = "darkgreen", 
             linetype = "dashed", size = 1) +
  geom_hline(yintercept = 0.5, color = "red", linetype = "dotted", size = 0.8) +
  labs(
    title = "Função de Distribuição Acumulada (CDF)",
    subtitle = sprintf("Probabilidade de lucro: %.1f%% | Probabilidade de prejuízo: %.1f%%",
                       prob_lucro, prob_prejuizo),
    x = "Valor Final (R$)",
    y = "Probabilidade Acumulada"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5)
  ) +
  scale_x_continuous(labels = scales::label_currency(prefix = "R$", big.mark = ".")) +
  scale_y_continuous(labels = scales::percent)

ggsave(file.path(PARTE, "graficos", "05_cdf_valores_finais.png"), 
       p_cdf, width = 10, height = 6, dpi = 300)
cat("   ✅ CDF salva\n")

cat("\n✅ Todos os gráficos salvos em:", file.path(PARTE, "graficos/"), "\n")

# ----------------------------------------------------------------------------
# 9. EXPORTAÇÃO DOS RESULTADOS
# ----------------------------------------------------------------------------

cat("\n📁 EXPORTANDO RESULTADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Criar dataframe com resultados
resultados_df <- data.frame(
  simulação = 1:n_simulacoes,
  valor_final = valores_finais,
  retorno_percentual = (valores_finais / investimento_inicial - 1) * 100,
  drawdown_percentual = drawdowns * 100
)

# Exportar CSV
write.csv(resultados_df, 
          file.path(PARTE, "resultados", "simulacoes.csv"), 
          row.names = FALSE)
cat("✓ simulacoes.csv\n")

# Estatísticas resumidas
estatisticas_df <- data.frame(
  metrica = c("Média (R$)", "Mediana (R$)", "Desvio Padrão (R$)", 
              "Mínimo (R$)", "Máximo (R$)",
              "Probabilidade de Lucro (%)", "Probabilidade de Prejuízo (%)",
              "VaR 95% (R$)", "CVaR 95% (R$)",
              "Drawdown Médio (%)", "Drawdown Máximo (%)"),
  valor = c(media_final, mediana_final, dp_final, min_final, max_final,
            prob_lucro, prob_prejuizo, var_95, cvar_95, dd_medio, dd_max)
)

write.csv(estatisticas_df, 
          file.path(PARTE, "resultados", "estatisticas.csv"), 
          row.names = FALSE)
cat("✓ estatisticas.csv\n")

# Salvar resultados completos em RDS
saveRDS(list(
  valores_finais = valores_finais,
  resultados_sim = resultados,
  drawdowns = drawdowns,
  estatisticas = estatisticas_df,
  parametros = list(
    ativo = ativo_analise,
    investimento_inicial = investimento_inicial,
    horizonte_dias = horizonte_dias,
    n_simulacoes = n_simulacoes,
    nivel_confianca = nivel_confianca
  )
), file.path(PARTE, "resultados", "resultados_parte2.rds"))
cat("✓ resultados_parte2.rds\n")

cat("\n✅ Resultados exportados para:", file.path(PARTE, "resultados/"), "\n")

# ----------------------------------------------------------------------------
# 10. SUMÁRIO EXECUTIVO
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              SUMÁRIO EXECUTIVO - PARTE 2                         ║\n")
cat("║              SIMULAÇÃO DE MONTE CARLO                            ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("📊 RESULTADOS DA SIMULAÇÃO\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("\nAtivo analisado: %s\n", ativo_analise))
cat(sprintf("Investimento inicial: R$ %s\n", format(investimento_inicial, big.mark = ".")))
cat(sprintf("Horizonte: 1 ano (%d dias úteis)\n", horizonte_dias))
cat(sprintf("Número de simulações: %s\n", format(n_simulacoes, big.mark = ".")))

cat("\n📈 PROBABILIDADES\n")
cat(sprintf("   Lucro: %.1f%%\n", prob_lucro))
cat(sprintf("   Prejuízo: %.1f%%\n", prob_prejuizo))
cat(sprintf("   Retorno esperado: %.1f%%\n", retorno_esperado))

cat("\n📊 MEDIDAS DE RISCO\n")
cat(sprintf("   VaR 95%%: R$ %s\n", format(round(var_95, 2), big.mark = ".")))
cat(sprintf("   CVaR 95%%: R$ %s (média dos piores 5%% cenários)\n", 
            format(round(cvar_95, 2), big.mark = ".")))
cat(sprintf("   Drawdown médio: %.1f%%\n", dd_medio))
cat(sprintf("   Drawdown máximo esperado (p95): %.1f%%\n", dd_p95))

cat("\n🎯 CONCLUSÃO\n")
cat("─────────────────────────────────────────────────────────────────────\n")
if(prob_lucro > 50) {
  cat(sprintf("✅ Probabilidade de lucro de %.1f%% após 1 ano.\n", prob_lucro))
} else {
  cat(sprintf("⚠️ Probabilidade de prejuízo de %.1f%% após 1 ano.\n", prob_prejuizo))
}
cat(sprintf("   O pior cenário esperado (VaR 95%%) é uma perda de R$ %s.\n",
            format(round(investimento_inicial - var_95, 2), big.mark = ".")))
cat(sprintf("   Em 5%% dos piores cenários, a perda média é de R$ %s.\n",
            format(round(investimento_inicial - cvar_95, 2), big.mark = ".")))

cat("\n📁 ARQUIVOS GERADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("✓ %s/graficos/ - 5 gráficos\n", PARTE))
cat(sprintf("✓ %s/resultados/simulacoes.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/estatisticas.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_parte2.rds\n", PARTE))
cat("\n")

cat("✅ PARTE 2 CONCLUÍDA COM SUCESSO!\n")

# ============================================================================
# FIM DA PARTE 2
# ============================================================================