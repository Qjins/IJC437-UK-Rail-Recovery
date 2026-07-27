# ============================================================
# IJC437 - Script 02: Analysis
#
# Quantifies post-pandemic recovery of UK rail passenger usage:
#   1. 2019-baseline recovery index and recovery gap by region
#   2. Regional vs national comparison (RQ3)
#   3. Linear-trend counterfactual: where would demand be in 2025
#      had the 2010-2019 trend continued? (regression/prediction)
#   4. Correlates of recovery (pre-pandemic growth, market size,
#      inter-regional journey share)
#   5. K-means clustering of recovery trajectories 2021-2025
#   6. Station-level recovery summary (within-region variation)
#
# Input:  01_data/processed/*.csv (from 01_data_cleaning.R)
# Output: 01_data/processed/rail_indexed_2019.csv
#         01_data/processed/recovery_gap_2019_2025.csv
#         01_data/processed/counterfactual_2025.csv
#         01_data/processed/recovery_correlates.csv
#         01_data/processed/recovery_clusters.csv
#         01_data/processed/station_summary_by_region.csv
#
# Baseline definition: 2019 = rail year April 2018 to March 2019,
# the last complete rail year unaffected by the pandemic (the
# 2019-20 rail year already includes the March 2020 lockdown).
# ============================================================

library(tidyverse)
library(cluster)   # silhouette widths for choosing k

if (basename(getwd()) == "02_scripts") setwd(dirname(getwd()))
if (!dir.exists("01_data")) stop("Set the working directory to the project root.")

set.seed(437)  # reproducible k-means

baseline_year   <- 2019
comparison_year <- 2025
trend_years     <- 2010:2019  # consistent post-2009-break, pre-pandemic decade

regional <- read_csv("01_data/processed/regional_time_series.csv", show_col_types = FALSE)
national <- read_csv("01_data/processed/national_time_series.csv", show_col_types = FALSE)
station  <- read_csv("01_data/processed/station_recovery.csv",     show_col_types = FALSE)

# ------------------------------------------------------------
# 1. Recovery index (2019 = 100) and recovery gap by region
# ------------------------------------------------------------
baseline <- regional |>
  filter(year == baseline_year) |>
  select(region, baseline_journeys = journeys_total)

regional_indexed <- regional |>
  left_join(baseline, by = "region") |>
  mutate(index_2019 = journeys_total / baseline_journeys * 100)

write_csv(regional_indexed, "01_data/processed/rail_indexed_2019.csv")

national_indexed <- national |>
  mutate(index_2019 = journeys_total / journeys_total[year == baseline_year] * 100)

recovery_gap <- regional_indexed |>
  filter(year == comparison_year) |>
  transmute(region,
            journeys_2019_m = round(baseline_journeys / 1e6, 1),
            journeys_2025_m = round(journeys_total / 1e6, 1),
            index_2025 = round(index_2019, 1),
            recovery_gap = round(index_2019 - 100, 1)) |>
  arrange(desc(recovery_gap))

national_index_2025 <- national_indexed$index_2019[national_indexed$year == comparison_year]
cat(sprintf("National recovery index 2025 (2019 = 100): %.1f\n", national_index_2025))
cat(sprintf("Regions at or above the 2019 baseline: %d of %d\n\n",
            sum(recovery_gap$recovery_gap >= 0), nrow(recovery_gap)))
print(recovery_gap)

write_csv(recovery_gap, "01_data/processed/recovery_gap_2019_2025.csv")

# ------------------------------------------------------------
# 2. Linear-trend counterfactual for 2025
#    A separate OLS regression of journeys on year is fitted for
#    each region over 2010-2019, then extrapolated to 2025. The
#    shortfall compares actual 2025 demand with that projection,
#    i.e. recovery measured against where demand was heading
#    rather than where it stood in 2019.
# ------------------------------------------------------------
fit_counterfactual <- function(df) {
  model <- lm(journeys_total ~ year, data = filter(df, year %in% trend_years))
  predicted_2025 <- predict(model, newdata = tibble(year = comparison_year))
  tibble(
    predicted_2025  = predicted_2025,
    r_squared       = summary(model)$r.squared,
    annual_growth_m = round(coef(model)["year"] / 1e6, 2)
  )
}

counterfactual <- regional |>
  group_by(region) |>
  group_modify(~ fit_counterfactual(.x)) |>
  ungroup() |>
  left_join(filter(regional, year == comparison_year) |> select(region, actual_2025 = journeys_total),
            by = "region") |>
  mutate(shortfall_pct = round((actual_2025 - predicted_2025) / predicted_2025 * 100, 1),
         predicted_2025_m = round(predicted_2025 / 1e6, 1),
         actual_2025_m    = round(actual_2025 / 1e6, 1)) |>
  select(region, actual_2025_m, predicted_2025_m, shortfall_pct, r_squared, annual_growth_m) |>
  arrange(shortfall_pct)

national_model <- lm(journeys_total ~ year, data = filter(national, year %in% trend_years))
national_pred  <- predict(national_model, newdata = tibble(year = comparison_year))
national_actual <- national$journeys_total[national$year == comparison_year]
cat(sprintf("\nNational 2025 vs 2010-2019 trend: %.1f%% (trend R^2 = %.3f)\n",
            (national_actual - national_pred) / national_pred * 100,
            summary(national_model)$r.squared))
print(counterfactual)

write_csv(counterfactual, "01_data/processed/counterfactual_2025.csv")

# ------------------------------------------------------------
# 3. Correlates of the recovery gap
#    Small sample (n = 11 regions), so Pearson and Spearman are
#    both reported and results are treated as indicative only.
# ------------------------------------------------------------
correlates_data <- regional |>
  filter(year == baseline_year) |>
  transmute(region,
            log_journeys_2019 = log10(journeys_total),
            interregional_share_2019 = journeys_interregional / journeys_total * 100) |>
  left_join(
    regional |>
      filter(year %in% range(trend_years)) |>
      select(region, year, journeys_total) |>
      pivot_wider(names_from = year, values_from = journeys_total, names_prefix = "y") |>
      mutate(cagr_2010_2019 = ((y2019 / y2010)^(1 / 9) - 1) * 100) |>
      select(region, cagr_2010_2019),
    by = "region") |>
  left_join(select(recovery_gap, region, recovery_gap), by = "region")

test_correlate <- function(x_name) {
  p <- cor.test(correlates_data[[x_name]], correlates_data$recovery_gap, method = "pearson")
  s <- cor.test(correlates_data[[x_name]], correlates_data$recovery_gap, method = "spearman", exact = FALSE)
  tibble(variable = x_name,
         pearson_r = round(p$estimate, 2), pearson_p = round(p$p.value, 3),
         spearman_rho = round(s$estimate, 2), spearman_p = round(s$p.value, 3))
}

correlations <- map(c("cagr_2010_2019", "log_journeys_2019", "interregional_share_2019"),
                    test_correlate) |> list_rbind()
cat("\nCorrelates of the 2025 recovery gap (n = 11 regions):\n")
print(correlations)

write_csv(correlates_data, "01_data/processed/recovery_correlates_data.csv")
write_csv(correlations,    "01_data/processed/recovery_correlates.csv")

# ------------------------------------------------------------
# 4. K-means clustering of recovery trajectories
#    Features: recovery index in each pandemic/recovery year
#    (2021-2025), standardised. k chosen by average silhouette
#    width over k = 2..4.
# ------------------------------------------------------------
trajectory_features <- regional_indexed |>
  filter(year >= 2021) |>
  select(region, year, index_2019) |>
  pivot_wider(names_from = year, values_from = index_2019, names_prefix = "index_") |>
  column_to_rownames("region")

scaled_features <- scale(trajectory_features)

silhouette_width <- function(k) {
  km <- kmeans(scaled_features, centers = k, nstart = 50)
  mean(silhouette(km$cluster, dist(scaled_features))[, "sil_width"])
}
sil <- tibble(k = 2:4, avg_silhouette = map_dbl(k, silhouette_width))
cat("\nAverage silhouette width by k:\n"); print(sil)

best_k <- sil$k[which.max(sil$avg_silhouette)]
km_final <- kmeans(scaled_features, centers = best_k, nstart = 50)

clusters <- tibble(region = rownames(trajectory_features),
                   cluster = km_final$cluster) |>
  left_join(select(recovery_gap, region, recovery_gap), by = "region") |>
  arrange(cluster, desc(recovery_gap))

# Label clusters by their mean recovery gap so the labels are data-driven
label_sets <- list(
  `2` = c("Stronger recovery", "Weaker recovery"),
  `3` = c("Recovered / above baseline", "Near baseline", "Lagging recovery"),
  `4` = c("Recovered / above baseline", "Near baseline", "Lagging recovery", "Weakest recovery")
)
cluster_labels <- clusters |>
  summarise(mean_gap = mean(recovery_gap), .by = cluster) |>
  arrange(desc(mean_gap)) |>
  mutate(cluster_label = label_sets[[as.character(best_k)]][seq_len(n())])

clusters <- left_join(clusters, cluster_labels, by = "cluster")
cat(sprintf("\nK-means clusters (k = %d):\n", best_k))
print(clusters)

write_csv(clusters, "01_data/processed/recovery_clusters.csv")

# ------------------------------------------------------------
# 5. Station-level recovery: variation within regions
# ------------------------------------------------------------
station_summary <- station |>
  summarise(n_stations = n(),
            median_index = round(median(recovery_index), 1),
            q1 = round(quantile(recovery_index, 0.25), 1),
            q3 = round(quantile(recovery_index, 0.75), 1),
            share_recovered_pct = round(mean(recovery_index >= 100) * 100, 1),
            .by = region) |>
  arrange(desc(median_index))

cat("\nStation-level recovery by region (index, 2019 = 100):\n")
print(station_summary)
cat(sprintf("\nGB stations at or above their 2019 usage: %.1f%% of %d stations\n",
            mean(station$recovery_index >= 100) * 100, nrow(station)))

write_csv(station_summary, "01_data/processed/station_summary_by_region.csv")

cat("\nAnalysis complete.\n")
