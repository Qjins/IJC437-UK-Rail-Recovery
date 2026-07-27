# ============================================================
# IJC437 - Script 03: Report figures
#
# Produces every figure used in the report:
#   fig1_methodology_workflow.png   - data science process diagram
#   fig2_national_trend.png         - GB journeys 1996-2025 (RQ1)
#   fig3_regional_trajectories.png  - indexed regional paths vs national (RQ2, RQ3)
#   fig4_recovery_gap.png           - recovery gap by region, 2025 vs 2019 (RQ2)
#   fig5_counterfactual.png         - 2025 vs 2010-2019 trend projection (RQ3)
#   fig6_clusters.png               - k-means recovery trajectory clusters (RQ2)
#   fig7_station_recovery.png       - station-level recovery by region (RQ2)
#
# Input:  01_data/processed/*.csv (from scripts 01 and 02)
# Output: 03_figures/*.png (300 dpi)
# ============================================================

library(tidyverse)

if (basename(getwd()) == "02_scripts") setwd(dirname(getwd()))
if (!dir.exists("03_figures")) dir.create("03_figures")

# ---- shared style ------------------------------------------------
col_blue   <- "#2a78d6"   # primary series / above baseline
col_red    <- "#d03b3b"   # below baseline
col_orange <- "#eb6834"   # second categorical series (cluster 2)
col_ink    <- "#0b0b0b"
col_ink2   <- "#52514e"
col_muted  <- "#898781"
col_grid   <- "#e1e0d9"
col_axis   <- "#c3c2b7"

theme_report <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = col_grid, linewidth = 0.3),
      axis.text  = element_text(colour = col_ink2),
      axis.title = element_text(colour = col_ink2),
      plot.title = element_text(face = "bold", colour = col_ink, size = base_size + 2),
      plot.subtitle = element_text(colour = col_ink2, margin = margin(b = 8)),
      plot.caption  = element_text(colour = col_muted, size = base_size - 3, hjust = 0),
      plot.title.position = "plot",
      legend.position = "top"
    )
}

save_fig <- function(name, plot, width, height) {
  ggsave(file.path("03_figures", name), plot,
         width = width, height = height, dpi = 300, bg = "white")
  cat("Saved", name, "\n")
}

regional_indexed <- read_csv("01_data/processed/rail_indexed_2019.csv",     show_col_types = FALSE)
national         <- read_csv("01_data/processed/national_time_series.csv",  show_col_types = FALSE)
recovery_gap     <- read_csv("01_data/processed/recovery_gap_2019_2025.csv",show_col_types = FALSE)
counterfactual   <- read_csv("01_data/processed/counterfactual_2025.csv",   show_col_types = FALSE)
clusters         <- read_csv("01_data/processed/recovery_clusters.csv",     show_col_types = FALSE)
station          <- read_csv("01_data/processed/station_recovery.csv",      show_col_types = FALSE)

national_indexed <- national |>
  mutate(index_2019 = journeys_total / journeys_total[year == 2019] * 100)
national_index_2025 <- round(national_indexed$index_2019[national_indexed$year == 2025] - 100, 1)

# ------------------------------------------------------------------
# Figure 1: methodology workflow
# ------------------------------------------------------------------
stages <- tribble(
  ~step, ~label,
  1, "Data collection\nORR tables 1510, 1540-1590 (regional journeys) and 1415 (station usage)",
  2, "Cleaning and validation\nRobust year parsing, footnote handling ([b], [x], [z]), completeness checks",
  3, "Exploratory data analysis\nNational and regional trends before, during and after COVID-19",
  4, "Recovery indexing\nJourneys indexed to the 2019 rail year (2019 = 100); recovery gap = index - 100",
  5, "Modelling\nLinear-trend counterfactual for 2025 - k-means clustering - correlation analysis",
  6, "Interpretation and reporting\nAnswers to RQ1-RQ3, limitations, and links to the literature"
) |>
  mutate(y = rev(step))

fig1 <- ggplot(stages) +
  geom_rect(aes(xmin = 0, xmax = 10, ymin = y - 0.38, ymax = y + 0.38),
            fill = "#f0f4fa", colour = col_blue, linewidth = 0.4) +
  geom_text(aes(x = 5, y = y, label = label),
            size = 3.2, colour = col_ink, lineheight = 1.05) +
  geom_segment(data = filter(stages, step < 6),
               aes(x = 5, xend = 5, y = y - 0.38, yend = y - 0.62),
               arrow = arrow(length = unit(2.2, "mm"), type = "closed"),
               colour = col_ink2, linewidth = 0.5) +
  scale_x_continuous(limits = c(0, 10), expand = c(0, 0)) +
  theme_void()

save_fig("fig1_methodology_workflow.png", fig1, width = 7.5, height = 5.6)

# ------------------------------------------------------------------
# Figure 2: national trend 1996-2025 (RQ1)
# ------------------------------------------------------------------
pandemic_band <- tibble(xmin = 2020.2, xmax = 2022.2)  # rail years ending 2021-2022

fig2 <- ggplot(national, aes(year, journeys_total / 1e9)) +
  annotate("rect", xmin = pandemic_band$xmin, xmax = pandemic_band$xmax,
           ymin = -Inf, ymax = Inf, fill = "#f0efec") +
  annotate("text", x = 2021.2, y = 1.62, label = "COVID-19\nrestrictions",
           size = 3.1, colour = col_ink2, lineheight = 1) +
  geom_hline(yintercept = national$journeys_total[national$year == 2019] / 1e9,
             linetype = "dotted", colour = col_muted, linewidth = 0.4) +
  annotate("text", x = 1996.2, y = 1.575, hjust = 0, size = 3.1, colour = col_ink2,
           label = "2019 level") +
  geom_line(colour = col_blue, linewidth = 0.9) +
  geom_point(data = filter(national, year %in% c(2019, 2021, 2025)),
             colour = col_blue, size = 2) +
  annotate("text", x = 2021, y = 0.28, label = "0.34bn (2021)",
           size = 3.1, colour = col_ink2) +
  annotate("text", x = 2024.9, y = 1.45, hjust = 1, size = 3.1, colour = col_ink2,
           label = "1.53bn (2025)") +
  scale_x_continuous(breaks = seq(1996, 2025, 4)) +
  scale_y_continuous(limits = c(0, 1.7), expand = c(0, 0)) +
  labs(x = "Rail year (ending 31 March)",
       y = "Passenger journeys (billions)") +
  theme_report()

save_fig("fig2_national_trend.png", fig2, width = 8, height = 4.4)

# ------------------------------------------------------------------
# Figure 3: regional indexed trajectories vs national (RQ2, RQ3)
# ------------------------------------------------------------------
facet_order <- recovery_gap |> arrange(desc(index_2025)) |> pull(region)

plot_data <- regional_indexed |>
  filter(year >= 2016) |>
  mutate(region = factor(region, levels = facet_order))

national_overlay <- national_indexed |>
  filter(year >= 2016) |>
  select(year, index_2019)

end_labels <- plot_data |>
  filter(year == 2025) |>
  mutate(label = sprintf("%.0f", index_2019))

fig3 <- ggplot(plot_data, aes(year, index_2019)) +
  geom_hline(yintercept = 100, linetype = "dotted", colour = col_muted, linewidth = 0.4) +
  geom_line(data = national_overlay, aes(year, index_2019),
            colour = col_muted, linetype = "dashed", linewidth = 0.5) +
  geom_line(colour = col_blue, linewidth = 0.8) +
  geom_text(data = end_labels, aes(label = label),
            hjust = -0.25, size = 3, colour = col_ink) +
  facet_wrap(~region, ncol = 4) +
  scale_x_continuous(breaks = c(2016, 2019, 2022, 2025), limits = c(2016, 2026.4)) +
  scale_y_continuous(breaks = c(0, 50, 100)) +
  labs(x = "Rail year (ending 31 March)",
       y = "Recovery index (2019 = 100)",
       caption = "Solid line: region. Dashed grey line: Great Britain. Labels show the 2025 index.") +
  theme_report() +
  theme(strip.text = element_text(colour = col_ink, face = "bold", size = 9),
        panel.spacing.x = unit(10, "pt"))

save_fig("fig3_regional_trajectories.png", fig3, width = 9, height = 5.6)

# ------------------------------------------------------------------
# Figure 4: recovery gap by region (RQ2)
# ------------------------------------------------------------------
gap_data <- recovery_gap |>
  mutate(region = fct_reorder(region, recovery_gap),
         direction = if_else(recovery_gap >= 0, "Above 2019 level", "Below 2019 level"))

fig4 <- ggplot(gap_data, aes(recovery_gap, region, fill = direction)) +
  geom_col(width = 0.72) +
  geom_vline(xintercept = 0, colour = col_axis, linewidth = 0.5) +
  geom_vline(xintercept = national_index_2025, linetype = "dashed",
             colour = col_ink2, linewidth = 0.45) +
  annotate("text", x = national_index_2025 + 0.6, y = 2.2, hjust = 0, size = 3.1,
           colour = col_ink2, label = sprintf("National: %+.1f", national_index_2025)) +
  geom_text(aes(label = sprintf("%+.1f", recovery_gap),
                hjust = if_else(recovery_gap >= 0, -0.18, 1.18)),
            size = 3.2, colour = col_ink) +
  scale_fill_manual(values = c("Above 2019 level" = col_blue, "Below 2019 level" = col_red)) +
  scale_x_continuous(limits = c(-19, 22)) +
  labs(x = "Recovery gap, 2025 vs 2019 (index points; 0 = full recovery)",
       y = NULL, fill = NULL) +
  theme_report()

save_fig("fig4_recovery_gap.png", fig4, width = 8, height = 4.6)

# ------------------------------------------------------------------
# Figure 5: 2025 demand vs 2010-2019 trend projection (RQ3)
# ------------------------------------------------------------------
national_shortfall <- -17.5  # from script 02 output

cf_data <- counterfactual |>
  mutate(region = fct_reorder(region, shortfall_pct),
         direction = if_else(shortfall_pct >= 0, "Above projected trend", "Below projected trend"))

fig5 <- ggplot(cf_data, aes(shortfall_pct, region, fill = direction)) +
  geom_col(width = 0.72) +
  geom_vline(xintercept = 0, colour = col_axis, linewidth = 0.5) +
  geom_vline(xintercept = national_shortfall, linetype = "dashed",
             colour = col_ink2, linewidth = 0.45) +
  annotate("text", x = national_shortfall - 0.6, y = 10.6, hjust = 1, size = 3.1,
           colour = col_ink2, label = sprintf("National: %+.1f%%", national_shortfall)) +
  geom_text(aes(label = sprintf("%+.1f", shortfall_pct),
                hjust = if_else(shortfall_pct >= 0, -0.18, 1.18)),
            size = 3.2, colour = col_ink) +
  scale_fill_manual(values = c("Above projected trend" = col_blue,
                               "Below projected trend" = col_red)) +
  scale_x_continuous(limits = c(-37, 10)) +
  labs(x = "Actual 2025 journeys vs 2010-2019 linear trend projection (%)",
       y = NULL, fill = NULL) +
  theme_report()

save_fig("fig5_counterfactual.png", fig5, width = 8, height = 4.6)

# ------------------------------------------------------------------
# Figure 6: k-means clusters of recovery trajectories (RQ2)
# ------------------------------------------------------------------
cluster_data <- regional_indexed |>
  filter(year >= 2019) |>
  left_join(select(clusters, region, cluster_label), by = "region")

cluster_means <- cluster_data |>
  summarise(index_2019 = mean(index_2019), .by = c(year, cluster_label))

fig6 <- ggplot(cluster_data, aes(year, index_2019, colour = cluster_label)) +
  geom_hline(yintercept = 100, linetype = "dotted", colour = col_muted, linewidth = 0.4) +
  geom_line(aes(group = region), alpha = 0.35, linewidth = 0.5) +
  geom_line(data = cluster_means, linewidth = 1.3) +
  scale_colour_manual(values = c("Stronger recovery" = col_blue,
                                 "Weaker recovery" = col_orange)) +
  scale_x_continuous(breaks = 2019:2025) +
  labs(x = "Rail year (ending 31 March)",
       y = "Recovery index (2019 = 100)",
       colour = NULL,
       caption = "Thin lines: regions. Thick lines: cluster means. Clusters from k-means (k = 2) on standardised 2021-2025 indices.") +
  theme_report()

save_fig("fig6_clusters.png", fig6, width = 8, height = 4.8)

# ------------------------------------------------------------------
# Figure 7: station-level recovery by region (RQ2, granularity)
# ------------------------------------------------------------------
station_order <- station |>
  summarise(median_index = median(recovery_index), .by = region) |>
  arrange(median_index) |>
  pull(region)

n_truncated <- sum(station$recovery_index > 250)

fig7 <- ggplot(station, aes(recovery_index, factor(region, levels = station_order))) +
  geom_vline(xintercept = 100, linetype = "dashed", colour = col_ink2, linewidth = 0.45) +
  geom_boxplot(fill = "#f0efec", colour = col_ink2, linewidth = 0.4,
               outlier.size = 0.7, outlier.colour = col_muted, outlier.alpha = 0.5) +
  coord_cartesian(xlim = c(0, 250)) +
  labs(x = "Station recovery index, 2025 vs 2019 (2019 = 100)",
       y = NULL,
       caption = sprintf(
         "Entries and exits per station (ORR table 1415), n = %s stations.\nAxis truncated at 250 (%d stations above, mostly new or rebuilt stations).",
         format(nrow(station), big.mark = ","), n_truncated)) +
  theme_report()

save_fig("fig7_station_recovery.png", fig7, width = 8, height = 5)

cat("All figures saved.\n")
