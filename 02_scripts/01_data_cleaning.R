# ============================================================
# IJC437 - Script 01: Data cleaning
#
# Builds tidy datasets from the raw ORR ODS tables.
#
# Input (raw ORR tables, Open Government Licence):
#   01_data/raw/national/table-1510-... .ods   (GB total journeys)
#   01_data/raw/regional/table-15XX-... .ods   (10 regional tables)
#   01_data/raw/station/table-1415-... .ods    (station entries & exits)
#
# Output:
#   01_data/processed/national_time_series.csv
#   01_data/processed/regional_time_series.csv
#   01_data/processed/station_recovery.csv
#
# Notes on the raw format:
#   - Each regional file holds the data in the sheet named
#     "15XX_journeys_<region>"; the first table (columns A-D) gives
#     journeys to/from other regions, within the region, and the total.
#   - Years are rail years running April to March. Throughout this
#     project a year label refers to the END of the rail year, so
#     2019 = April 2018 to March 2019.
#   - ORR marks breaks in the time series with "[b]" appended to the
#     time-period label (e.g. "Apr 2022 to Mar 2023 [b]"). The first
#     version of this pipeline extracted the year with the regex
#     "\\d{4}$", which silently failed on those rows and dropped
#     them. The regex below anchors on "Mar <year>" instead, so
#     flagged rows are retained and the break is kept as a variable.
#
# Working directory must be the project root: IJC437-UK-Rail-Recovery
# ============================================================

library(tidyverse)
library(readODS)

# ------------------------------------------------------------
# 0. Locate project root
# ------------------------------------------------------------
if (basename(getwd()) == "02_scripts") setwd(dirname(getwd()))
if (!dir.exists("01_data")) {
  stop("Project root not detected. Set the working directory to IJC437-UK-Rail-Recovery.")
}
dir.create("01_data/processed", showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# 1. Helper functions shared by all ORR tables
# ------------------------------------------------------------

# Rail years are labelled by their end year: "Apr 2018 to Mar 2019" -> 2019.
# Anchoring on "Mar " keeps rows whose label carries a footnote such as "[b]".
extract_end_year <- function(time_period) {
  as.integer(str_extract(time_period, "(?<=Mar )\\d{4}"))
}

# ORR uses shorthand codes ([x] not available, [z] not applicable,
# [b] break in series) inside data cells; coerce those to NA quietly.
to_numeric <- function(x) {
  suppressWarnings(as.numeric(gsub(",", "", as.character(x))))
}

# The data sheet is the one whose name contains "journeys"
# (e.g. "1560_journeys_north_west", "1510_journeys_great_britain").
data_sheet <- function(file_path) {
  sheets <- list_ods_sheets(file_path)
  sheets[str_detect(sheets, "journeys")][1]
}

# Consistent region names across the regional and station tables
# (the raw files disagree on capitalisation, e.g. "East of England"
# in table 1415 vs the file name "east-of-england" in table 1545).
tidy_region_name <- function(x) {
  str_to_title(x) |>
    str_replace_all(c(" Of " = " of ", " And The " = " and the "))
}

region_label <- function(file_path) {
  tools::file_path_sans_ext(basename(file_path)) |>
    str_replace("^table-\\d+-regional-passenger-journeys-", "") |>
    str_replace_all("-", " ") |>
    tidy_region_name()
}

# ------------------------------------------------------------
# 2. Regional tables (1540-1590): one tidy panel
# ------------------------------------------------------------
regional_files <- list.files("01_data/raw/regional", full.names = TRUE, pattern = "\\.ods$")
regional_files <- regional_files[!str_detect(regional_files, "~\\$")]  # drop editor lock files
stopifnot(length(regional_files) == 11)

clean_regional <- function(file_path) {
  read_ods(file_path, sheet = data_sheet(file_path), skip = 5, col_names = TRUE) |>
    select(1:4) |>
    set_names(c("time_period", "interregional_thousands", "within_thousands", "total_thousands")) |>
    mutate(
      year = extract_end_year(time_period),
      series_break = str_detect(time_period, fixed("[b]")),
      region = region_label(file_path),
      journeys_interregional = round(to_numeric(interregional_thousands) * 1000),
      journeys_within = round(to_numeric(within_thousands) * 1000),
      journeys_total = round(to_numeric(total_thousands) * 1000)
    ) |>
    filter(!is.na(year)) |>
    select(year, region, journeys_total, journeys_within, journeys_interregional, series_break)
}

regional <- map(regional_files, clean_regional) |>
  list_rbind() |>
  arrange(region, year)

# Completeness check: every region should now cover 1996-2025 with no gaps
completeness <- regional |>
  summarise(n_years = n_distinct(year), missing_values = sum(is.na(journeys_total)), .by = region)
print(completeness)
stopifnot(all(completeness$n_years == 30), all(completeness$missing_values == 0))

write_csv(regional, "01_data/processed/regional_time_series.csv")

# ------------------------------------------------------------
# 3. National table (1510): GB total journeys
# ------------------------------------------------------------
national_file <- list.files("01_data/raw/national", full.names = TRUE, pattern = "\\.ods$")[1]

national <- read_ods(national_file, sheet = data_sheet(national_file), skip = 4, col_names = TRUE) |>
  select(1:4) |>
  set_names(c("time_period", "between_thousands", "within_thousands", "total_thousands")) |>
  mutate(
    year = extract_end_year(time_period),
    series_break = str_detect(time_period, fixed("[b]")),
    journeys_total = round(to_numeric(total_thousands) * 1000)
  ) |>
  filter(!is.na(year)) |>
  select(year, journeys_total, series_break)

stopifnot(nrow(national) == 30, !any(is.na(national$journeys_total)))
write_csv(national, "01_data/processed/national_time_series.csv")

# ------------------------------------------------------------
# 4. Station table (1415a): entries & exits, wide -> long
#    Kept only for the 2019 baseline and 2025 comparison years,
#    which is all the station-level analysis needs.
# ------------------------------------------------------------
station_file <- list.files("01_data/raw/station", full.names = TRUE, pattern = "\\.ods$")[1]

station_raw <- read_ods(station_file, sheet = "1415a_Entries_and_Exits", skip = 3, col_names = TRUE)

station <- station_raw |>
  rename(station = `Station name`, region = Region) |>
  mutate(region = tidy_region_name(region)) |>
  select(station, region,
         entries_exits_2019 = matches("Apr 2018 to Mar 2019"),
         entries_exits_2025 = matches("Apr 2024 to Mar 2025")) |>
  mutate(across(starts_with("entries_exits"), to_numeric)) |>
  filter(!is.na(entries_exits_2019), !is.na(entries_exits_2025),
         entries_exits_2019 > 0, region %in% unique(regional$region)) |>
  mutate(recovery_index = entries_exits_2025 / entries_exits_2019 * 100)

cat("Stations with usable 2019 and 2025 values:", nrow(station), "\n")
write_csv(station, "01_data/processed/station_recovery.csv")

cat("Data cleaning complete.\n")
