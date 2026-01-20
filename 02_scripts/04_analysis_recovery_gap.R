# ============================================================
# IJC437 - Analysis: Recovery Gap (2025 vs 2019)
#
# Input:
#   01_data/processed/regional_time_series.csv
#   Columns: Year, Region, Passenger_Journeys
#
# Output:
#   01_data/processed/rail_indexed_2019.csv
#   01_data/processed/recovery_gap_2019_2025.csv
#   03_figures/fig5_recovery_gap.png
#
# Working directory must be project root:
#   IJC437-UK-Rail-Recovery
# ============================================================

library(tidyverse)

# ------------------------------------------------------------
# 0. Safety check: working directory
# ------------------------------------------------------------
cat("Current working directory:\n")
print(getwd())

# ------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------
data_path <- "01_data/processed/regional_time_series.csv"

if (!file.exists(data_path)) {
  stop("File not found: ", data_path)
}

rail_raw <- read_csv(data_path, show_col_types = FALSE)

# ------------------------------------------------------------
# 2. Standardise column names
# ------------------------------------------------------------
rail <- rail_raw %>%
  rename(
    year = Year,
    region = Region,
    passenger_journeys = Passenger_Journeys
  ) %>%
  mutate(
    year = as.integer(year),
    passenger_journeys = as.numeric(passenger_journeys)
  )

# Basic structure check
required_cols <- c("year", "region", "passenger_journeys")
if (!all(required_cols %in% names(rail))) {
  stop("Required columns missing. Found: ", paste(names(rail), collapse = ", "))
}

# ------------------------------------------------------------
# 3. Check availability of baseline and comparison years
# ------------------------------------------------------------
baseline_year <- 2019
comparison_year <- 2025

years_available <- sort(unique(rail$year))
cat("Years available in data:\n")
print(years_available)

if (!(baseline_year %in% years_available)) {
  stop("Baseline year 2019 not found in data.")
}

if (!(comparison_year %in% years_available)) {
  stop("Comparison year 2025 not found in data.")
}

# ------------------------------------------------------------
# 4. Create 2019 baseline index
# ------------------------------------------------------------
baseline <- rail %>%
  filter(year == baseline_year) %>%
  select(region, baseline_pj = passenger_journeys)

rail_indexed <- rail %>%
  left_join(baseline, by = "region") %>%
  mutate(
    index_2019 = (passenger_journeys / baseline_pj) * 100
  )

# Save indexed dataset for reuse
write_csv(
  rail_indexed,
  "01_data/processed/rail_indexed_2019.csv"
)

# ------------------------------------------------------------
# 5. Calculate recovery gap (2025 vs 2019)
# ------------------------------------------------------------
recovery_gap <- rail_indexed %>%
  filter(year == comparison_year) %>%
  select(region, index_2019) %>%
  mutate(
    recovery_gap = index_2019 - 100
  ) %>%
  arrange(desc(recovery_gap))

cat("Recovery gap table:\n")
print(recovery_gap)

write_csv(
  recovery_gap,
  "01_data/processed/recovery_gap_2019_2025.csv"
)

# ------------------------------------------------------------
# 6. Visualisation: Recovery gap by region
# ------------------------------------------------------------
p <- ggplot(
  recovery_gap,
  aes(x = reorder(region, recovery_gap), y = recovery_gap)
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Recovery Gap in UK Rail Passenger Usage (2025 vs 2019)",
    x = "Region",
    y = "Recovery Gap (Index points; 2019 = 0)"
  ) +
  theme_minimal()

print(p)

ggsave(
  filename = "03_figures/fig5_recovery_gap.png",
  plot = p,
  width = 8,
  height = 5
)

# ------------------------------------------------------------
# 7. Done
# ------------------------------------------------------------
cat("Analysis complete.\n")