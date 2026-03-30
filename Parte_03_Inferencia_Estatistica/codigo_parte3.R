# ============================================================================
# PARTE 3: INFERÊNCIA ESTATÍSTICA E TESTES DE HIPÓTESES
# ============================================================================
#
# OBJETIVO:
#   Realizar inferência estatística robusta sobre os retornos dos ativos,
#   comparando distribuições e estimando parâmetros populacionais através
#   de técnicas paramétricas e não-paramétricas.
#
# CONCEITOS:
#   - Teste t de Student (paramétrico)
#   - Teste de Wilcoxon-Mann-Whitney (não-paramétrico)
#   - Teste de Kolmogorov-Smirnov (comparação de distribuições)
#   - Bootstrap para intervalos de confiança
#   - Tamanho de efeito (Cohen's d, Cliff's Delta)
#
# AUTOR: Ivan Santos
# DATA: 2026-03-29
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
PARTE <- "Parte_03_Inferencia_Estatistica"

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
library(moments)
library(car)
library(boot)

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
  
  periodo <- list(
    inicio = as.Date("2024-01-01"),
    fim = as.Date("2026-03-20")
  )
  
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
  
  dados <- coletar_dados(c("WEGE3", "HGLG11", "BTC-USD"), 
                         periodo$inicio, periodo$fim)
  
  retornos <- dados %>%
    group_by(symbol) %>%
    arrange(date) %>%
    mutate(retorno_log = log(adjusted / lag(adjusted))) %>%
    filter(!is.na(retorno_log)) %>%
    select(symbol, date, retorno_log)
  
  cat("✅ Dados coletados com sucesso!\n")
}

# Renomear coluna para padronizar
names(retornos)[names(retornos) == "retorno_log"] <- "retorno"

# ----------------------------------------------------------------------------
# 3. PREPARAÇÃO DOS DADOS
# ----------------------------------------------------------------------------

cat("\n📊 PREPARANDO DADOS PARA INFERÊNCIA\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Extrair retornos por ativo
ativos <- unique(retornos$symbol)
dados_por_ativo <- list()

for(ativo in ativos) {
  ret_ativo <- retornos %>% 
    filter(symbol == ativo) %>% 
    pull(retorno)
  ret_ativo <- ret_ativo[!is.na(ret_ativo)]
  dados_por_ativo[[ativo]] <- ret_ativo
  
  cat(sprintf("   %s: %d observações\n", ativo, length(ret_ativo)))
}

# Estatísticas descritivas
cat("\n📈 ESTATÍSTICAS DESCRITIVAS\n")
for(ativo in ativos) {
  ret <- dados_por_ativo[[ativo]]
  cat(sprintf("\n%s:\n", ativo))
  cat(sprintf("   Média: %.6f\n", mean(ret)))
  cat(sprintf("   Mediana: %.6f\n", median(ret)))
  cat(sprintf("   Desvio Padrão: %.6f\n", sd(ret)))
  cat(sprintf("   Min: %.6f\n", min(ret)))
  cat(sprintf("   Max: %.6f\n", max(ret)))
}

# ----------------------------------------------------------------------------
# 4. TESTE T DE STUDENT (PARAMÉTRICO)
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              TESTE T DE STUDENT (PARAMÉTRICO)                    ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

# Comparação BTC vs WEGE3
cat("\n📊 COMPARAÇÃO: BTC-USD vs WEGE3\n")
cat("─────────────────────────────────────────────────────────────────────\n")

ret_btc <- dados_por_ativo[["BTC-USD"]]
ret_wege <- dados_por_ativo[["WEGE3"]]

# Teste de homogeneidade de variâncias
var_test <- var.test(ret_btc, ret_wege)
cat(sprintf("\nTeste de homogeneidade de variâncias:\n"))
cat(sprintf("   F = %.4f | p-valor = %.6f\n", var_test$statistic, var_test$p.value))

# Teste t (com correção de Welch se necessário)
if(var_test$p.value < 0.05) {
  cat("   ⚠ Variâncias diferentes - usando correção de Welch\n")
  t_test <- t.test(ret_btc, ret_wege, var.equal = FALSE)
} else {
  cat("   ✓ Variâncias homogêneas - usando t-test padrão\n")
  t_test <- t.test(ret_btc, ret_wege, var.equal = TRUE)
}

cat("\n📋 RESULTADOS DO TESTE T\n")
cat(sprintf("   t = %.4f\n", t_test$statistic))
cat(sprintf("   gl = %.1f\n", t_test$parameter))
cat(sprintf("   p-valor = %.6f\n", t_test$p.value))
cat(sprintf("   IC 95%%: [%.6f, %.6f]\n", t_test$conf.int[1], t_test$conf.int[2]))

if(t_test$p.value < 0.05) {
  cat("\n   ❌ Rejeita H0: Médias significativamente diferentes\n")
} else {
  cat("\n   ✅ Não rejeita H0: Médias não diferem significativamente\n")
}

# ----------------------------------------------------------------------------
# 5. TESTE DE WILCOXON-MANN-WHITNEY (NÃO-PARAMÉTRICO)
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║         TESTE DE WILCOXON-MANN-WHITNEY (NÃO-PARAMÉTRICO)         ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

cat("\n📊 COMPARAÇÃO: BTC-USD vs WEGE3\n")
cat("─────────────────────────────────────────────────────────────────────\n")

wilcox_test <- wilcox.test(ret_btc, ret_wege, conf.int = TRUE, conf.level = 0.95)

cat(sprintf("\n📋 RESULTADOS DO TESTE DE WILCOXON\n"))
cat(sprintf("   W = %.1f\n", wilcox_test$statistic))
cat(sprintf("   p-valor = %.6f\n", wilcox_test$p.value))
cat(sprintf("   Diferença estimada (Hodges-Lehmann): %.6f\n", wilcox_test$estimate))
cat(sprintf("   IC 95%%: [%.6f, %.6f]\n", wilcox_test$conf.int[1], wilcox_test$conf.int[2]))

if(wilcox_test$p.value < 0.05) {
  cat("\n   ❌ Rejeita H0: Distribuições significativamente diferentes\n")
} else {
  cat("\n   ✅ Não rejeita H0: Distribuições não diferem significativamente\n")
}

# ----------------------------------------------------------------------------
# 6. TESTE DE KOLMOGOROV-SMIRNOV
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              TESTE DE KOLMOGOROV-SMIRNOV                         ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

cat("\n📊 COMPARAÇÃO: BTC-USD vs WEGE3\n")
cat("─────────────────────────────────────────────────────────────────────\n")

ks_test <- ks.test(ret_btc, ret_wege)

cat(sprintf("\n📋 RESULTADOS DO TESTE KS\n"))
cat(sprintf("   D = %.6f\n", ks_test$statistic))
cat(sprintf("   p-valor = %.6f\n", ks_test$p.value))

if(ks_test$p.value < 0.05) {
  cat("\n   ❌ Rejeita H0: Distribuições significativamente diferentes\n")
} else {
  cat("\n   ✅ Não rejeita H0: Distribuições não diferem significativamente\n")
}

# ----------------------------------------------------------------------------
# 7. TAMANHO DO EFEITO (EFFECT SIZE)
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║                    TAMANHO DO EFEITO                             ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

# Cohen's d
pooled_sd <- sqrt(((length(ret_btc) - 1) * var(ret_btc) + 
                     (length(ret_wege) - 1) * var(ret_wege)) / 
                    (length(ret_btc) + length(ret_wege) - 2))
cohens_d <- (mean(ret_btc) - mean(ret_wege)) / pooled_sd

# Interpretação de Cohen
interpretacao_d <- case_when(
  abs(cohens_d) < 0.2 ~ "desprezível",
  abs(cohens_d) < 0.5 ~ "pequeno",
  abs(cohens_d) < 0.8 ~ "médio",
  TRUE ~ "grande"
)

cat("\n📊 COHEN'S D\n")
cat(sprintf("   Valor: %.4f\n", cohens_d))
cat(sprintf("   Interpretação: %s\n", interpretacao_d))

# Cliff's Delta (medida não-paramétrica)
n1 <- length(ret_btc)
n2 <- length(ret_wege)
cliff_delta <- sum(outer(ret_btc, ret_wege, function(x, y) (x > y) - (x < y))) / (n1 * n2)

interpretacao_cliff <- case_when(
  abs(cliff_delta) < 0.147 ~ "desprezível",
  abs(cliff_delta) < 0.33 ~ "pequeno",
  abs(cliff_delta) < 0.474 ~ "médio",
  TRUE ~ "grande"
)

cat("\n📊 CLIFF'S DELTA\n")
cat(sprintf("   Valor: %.4f\n", cliff_delta))
cat(sprintf("   Interpretação: %s\n", interpretacao_cliff))

# ----------------------------------------------------------------------------
# 8. COMPARAÇÕES MÚLTIPLAS (TESTE DE KRUSKAL-WALLIS)
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              TESTE DE KRUSKAL-WALLIS (COMPARAÇÕES MÚLTIPLAS)     ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

# Preparar dados no formato longo
df_longo <- data.frame()
for(ativo in ativos) {
  ret <- dados_por_ativo[[ativo]]
  df_longo <- rbind(df_longo, data.frame(
    ativo = ativo,
    retorno = ret
  ))
}

# Teste de Kruskal-Wallis
kruskal_result <- kruskal.test(retorno ~ ativo, data = df_longo)

cat("\n📋 RESULTADOS DO TESTE DE KRUSKAL-WALLIS\n")
cat(sprintf("   Chi-quadrado = %.4f\n", kruskal_result$statistic))
cat(sprintf("   Graus de liberdade = %d\n", kruskal_result$parameter))
cat(sprintf("   p-valor = %.6f\n", kruskal_result$p.value))

if(kruskal_result$p.value < 0.05) {
  cat("\n   ❌ Rejeita H0: Pelo menos um par de distribuições difere\n")
} else {
  cat("\n   ✅ Não rejeita H0: Distribuições não diferem significativamente\n")
}

# ----------------------------------------------------------------------------
# 9. BOOTSTRAP PARA INTERVALOS DE CONFIANÇA
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              BOOTSTRAP - INTERVALOS DE CONFIANÇA                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")

# Função para calcular média
f_media <- function(dados, indices) {
  return(mean(dados[indices]))
}

cat("\n📊 ANALISANDO: WEGE3\n")
cat("─────────────────────────────────────────────────────────────────────\n")

set.seed(123)
boot_wege <- boot(data = ret_wege, statistic = f_media, R = 10000)
ci_wege <- boot.ci(boot_wege, type = "perc")

cat(sprintf("   Média amostral: %.6f\n", mean(ret_wege)))
cat(sprintf("   IC 95%% (Percentil): [%.6f, %.6f]\n", 
            ci_wege$percent[4], ci_wege$percent[5]))

cat("\n📊 ANALISANDO: BTC-USD\n")
cat("─────────────────────────────────────────────────────────────────────\n")

boot_btc <- boot(data = ret_btc, statistic = f_media, R = 10000)
ci_btc <- boot.ci(boot_btc, type = "perc")

cat(sprintf("   Média amostral: %.6f\n", mean(ret_btc)))
cat(sprintf("   IC 95%% (Percentil): [%.6f, %.6f]\n", 
            ci_btc$percent[4], ci_btc$percent[5]))

cat("\n📊 ANALISANDO: HGLG11\n")
cat("─────────────────────────────────────────────────────────────────────\n")

ret_hglg <- dados_por_ativo[["HGLG11"]]
boot_hglg <- boot(data = ret_hglg, statistic = f_media, R = 10000)
ci_hglg <- boot.ci(boot_hglg, type = "perc")

cat(sprintf("   Média amostral: %.6f\n", mean(ret_hglg)))
cat(sprintf("   IC 95%% (Percentil): [%.6f, %.6f]\n", 
            ci_hglg$percent[4], ci_hglg$percent[5]))

# ----------------------------------------------------------------------------
# 10. VISUALIZAÇÕES
# ----------------------------------------------------------------------------

cat("\n🎨 GERANDO VISUALIZAÇÕES\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# 1. Boxplot comparativo
cat("✓ Criando boxplot comparativo...\n")

p_box <- ggplot(retornos, aes(x = symbol, y = retorno, fill = symbol)) +
  geom_boxplot(notch = TRUE, alpha = 0.7, outlier.alpha = 0.3) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "red") +
  labs(
    title = "Comparação de Retornos por Ativo",
    subtitle = "Notches que não se sobrepõem indicam diferença significativa",
    x = "Ativo",
    y = "Retorno Logarítmico Diário",
    caption = "Pontos vermelhos = média | Entalhes = IC 95% da mediana"
  ) +
  scale_fill_manual(values = c("WEGE3" = "#2E86AB", "HGLG11" = "#A23B72", "BTC-USD" = "#F18F01")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    legend.position = "none",
    axis.text.x = element_text(face = "bold", size = 11)
  )

ggsave(file.path(PARTE, "graficos", "01_boxplot_comparativo.png"), 
       p_box, width = 10, height = 6, dpi = 300)
cat("   ✅ Boxplot salvo\n")

# 2. Densidades comparativas
cat("✓ Criando gráfico de densidades...\n")

df_densidades <- data.frame()
for(ativo in ativos) {
  ret <- dados_por_ativo[[ativo]]
  dens <- density(ret)
  df_densidades <- rbind(df_densidades, data.frame(
    ativo = ativo,
    x = dens$x,
    y = dens$y
  ))
}

p_dens <- ggplot(df_densidades, aes(x = x, y = y, color = ativo)) +
  geom_line(size = 1.2) +
  labs(
    title = "Densidade dos Retornos por Ativo",
    subtitle = "Comparação da distribuição empírica",
    x = "Retorno Logarítmico",
    y = "Densidade",
    color = "Ativo"
  ) +
  scale_color_manual(values = c("WEGE3" = "#2E86AB", "HGLG11" = "#A23B72", "BTC-USD" = "#F18F01")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    legend.position = "bottom"
  )

ggsave(file.path(PARTE, "graficos", "02_densidades_comparativas.png"), 
       p_dens, width = 10, height = 6, dpi = 300)
cat("   ✅ Gráfico de densidades salvo\n")

# 3. Distribuição bootstrap
cat("✓ Criando gráfico de bootstrap...\n")

df_bootstrap <- data.frame(
  media = boot_wege$t
)

p_boot <- ggplot(df_bootstrap, aes(x = media)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "#2E86AB", alpha = 0.7) +
  geom_density(color = "darkred", size = 1) +
  geom_vline(xintercept = mean(ret_wege), color = "darkgreen", linetype = "dashed", size = 1) +
  geom_vline(xintercept = ci_wege$percent[4], color = "orange", linetype = "dotted", size = 0.8) +
  geom_vline(xintercept = ci_wege$percent[5], color = "orange", linetype = "dotted", size = 0.8) +
  labs(
    title = "Distribuição Bootstrap da Média - WEGE3",
    subtitle = sprintf("IC 95%%: [%.6f, %.6f]", ci_wege$percent[4], ci_wege$percent[5]),
    x = "Média",
    y = "Densidade",
    caption = "Linha verde = média amostral | Linhas laranja = IC 95%"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5)
  )

ggsave(file.path(PARTE, "graficos", "03_bootstrap_wege.png"), 
       p_boot, width = 10, height = 6, dpi = 300)
cat("   ✅ Gráfico de bootstrap salvo\n")

cat("\n✅ Todos os gráficos salvos em:", file.path(PARTE, "graficos/"), "\n")

# ----------------------------------------------------------------------------
# 11. EXPORTAÇÃO DOS RESULTADOS
# ----------------------------------------------------------------------------

cat("\n📁 EXPORTANDO RESULTADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")

# Consolidar resultados dos testes
resultados_testes <- data.frame(
  Teste = c("Teste t", "Wilcoxon", "Kolmogorov-Smirnov", "Kruskal-Wallis"),
  Estatistica = c(t_test$statistic, wilcox_test$statistic, ks_test$statistic, kruskal_result$statistic),
  p_valor = c(t_test$p.value, wilcox_test$p.value, ks_test$p.value, kruskal_result$p.value),
  Conclusao = c(
    ifelse(t_test$p.value < 0.05, "Rejeita H0", "Não rejeita H0"),
    ifelse(wilcox_test$p.value < 0.05, "Rejeita H0", "Não rejeita H0"),
    ifelse(ks_test$p.value < 0.05, "Rejeita H0", "Não rejeita H0"),
    ifelse(kruskal_result$p.value < 0.05, "Rejeita H0", "Não rejeita H0")
  )
)

write.csv(resultados_testes, 
          file.path(PARTE, "resultados", "resultados_testes.csv"), 
          row.names = FALSE)
cat("✓ resultados_testes.csv\n")

# Tamanho do efeito
efeito_df <- data.frame(
  Medida = c("Cohen's d", "Cliff's Delta"),
  Valor = c(cohens_d, cliff_delta),
  Interpretacao = c(interpretacao_d, interpretacao_cliff)
)

write.csv(efeito_df, 
          file.path(PARTE, "resultados", "tamanho_efeito.csv"), 
          row.names = FALSE)
cat("✓ tamanho_efeito.csv\n")

# Intervalos de confiança bootstrap
ic_bootstrap <- data.frame(
  Ativo = c("WEGE3", "BTC-USD", "HGLG11"),
  Media_amostral = c(mean(ret_wege), mean(ret_btc), mean(ret_hglg)),
  IC_inferior = c(ci_wege$percent[4], ci_btc$percent[4], ci_hglg$percent[4]),
  IC_superior = c(ci_wege$percent[5], ci_btc$percent[5], ci_hglg$percent[5])
)

write.csv(ic_bootstrap, 
          file.path(PARTE, "resultados", "ic_bootstrap.csv"), 
          row.names = FALSE)
cat("✓ ic_bootstrap.csv\n")

# Salvar resultados completos
saveRDS(list(
  dados_por_ativo = dados_por_ativo,
  t_test = t_test,
  wilcox_test = wilcox_test,
  ks_test = ks_test,
  kruskal_result = kruskal_result,
  cohens_d = cohens_d,
  cliff_delta = cliff_delta,
  bootstrap = list(wege = boot_wege, btc = boot_btc, hglg = boot_hglg),
  ic_bootstrap = ic_bootstrap
), file.path(PARTE, "resultados", "resultados_parte3.rds"))
cat("✓ resultados_parte3.rds\n")

cat("\n✅ Resultados exportados para:", file.path(PARTE, "resultados/"), "\n")

# ----------------------------------------------------------------------------
# 12. SUMÁRIO EXECUTIVO
# ----------------------------------------------------------------------------

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║              SUMÁRIO EXECUTIVO - PARTE 3                         ║\n")
cat("║              INFERÊNCIA ESTATÍSTICA                              ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("📊 RESULTADOS DOS TESTES\n")
cat("─────────────────────────────────────────────────────────────────────\n")
print(resultados_testes)

cat("\n📊 TAMANHO DO EFEITO\n")
cat("─────────────────────────────────────────────────────────────────────\n")
print(efeito_df)

cat("\n📊 INTERVALOS DE CONFIANÇA (BOOTSTRAP)\n")
cat("─────────────────────────────────────────────────────────────────────\n")
print(ic_bootstrap)

cat("\n🎯 CONCLUSÃO\n")
cat("─────────────────────────────────────────────────────────────────────\n")

if(t_test$p.value < 0.05) {
  cat("❌ Os testes indicam diferenças significativas entre os ativos.\n")
} else {
  cat("✅ Os testes NÃO indicam diferenças significativas entre os ativos.\n")
}
cat(sprintf("   Tamanho do efeito: %s (Cohen's d = %.4f)\n", interpretacao_d, abs(cohens_d)))

cat("\n📁 ARQUIVOS GERADOS\n")
cat("─────────────────────────────────────────────────────────────────────\n")
cat(sprintf("✓ %s/graficos/ - 3 gráficos\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_testes.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/tamanho_efeito.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/ic_bootstrap.csv\n", PARTE))
cat(sprintf("✓ %s/resultados/resultados_parte3.rds\n", PARTE))
cat("\n")

cat("✅ PARTE 3 CONCLUÍDA COM SUCESSO!\n")

# ============================================================================
# FIM DA PARTE 3
# ============================================================================