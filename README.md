# Uneven Recovery of UK Rail Passenger Usage After COVID-19

A regional data science analysis of how unevenly rail passenger demand in Great Britain has recovered from the COVID-19 pandemic, produced for the **IJC437 – Introduction to Data Science** coursework (University of Sheffield).

The analysis uses official Office of Rail and Road (ORR) statistics: regional passenger journeys for the 11 regions of Great Britain (1996–2025), the national journey series, and station-level usage estimates for 2,554 stations. Years refer to rail years running April–March and are labelled by their end year (2019 = April 2018 to March 2019).

## Research questions

1. **RQ1**: How did national rail passenger usage in Great Britain change before, during and after the COVID-19 pandemic?
2. **RQ2**: To what extent has the recovery of rail passenger usage been uneven across regions and stations?
3. **RQ3**: How do regional recovery patterns compare with the overall national recovery trend?

## Key findings

- National usage collapsed to **22.6% of the 2019 baseline** in 2021 and returned to **100.8** (index, 2019 = 100) by 2025 — but composition changed: within-region journeys are +6% vs 2019 while inter-regional journeys remain −9.8%.
- Recovery is uneven: only **3 of 11 regions** (North East +17.4, South West +6.7, London +5.1) exceed their 2019 level; the West Midlands (−15.7), Scotland (−12.3), South East (−11.1) and East of England (−10.5) lag furthest.
- Measured against each region's **2010–2019 linear trend**, every region except the North East (+4.8%) remains in shortfall; nationally demand is **17.5% below** the pre-pandemic trajectory.
- K-means clustering (k = 2, chosen by silhouette width) separates a stronger-recovery group (North East, South West, London, East Midlands, Yorkshire and the Humber, North West) from a weaker one (Wales, East of England, South East, Scotland, West Midlands).
- At station level only **43.1% of 2,554 stations** have recovered; London combines an above-baseline aggregate with a median station at 88.5, showing recovery concentrated in a few large hubs (Elizabeth line effect).

## Repository structure

```text
IJC437-UK-Rail-Recovery/
│
├─ 01_data/
│   ├─ raw/            # Unmodified ORR ODS tables (1510, 1540–1590, 1415)
│   └─ processed/      # Cleaned datasets and analysis outputs (CSV)
│
├─ 02_scripts/
│   ├─ 01_data_cleaning.R      # Parse ODS tables, handle footnotes, validate completeness
│   ├─ 02_analysis_recovery.R  # Index, recovery gap, trend counterfactual, k-means, correlations
│   └─ 03_figures.R            # All report figures
│
├─ 03_figures/         # Figures used in the report (PNG, 300 dpi)
├─ 04_methodology/     # Methodology summary
├─ 05_report/          # Coursework report (Word)
└─ README.md
```

## How to reproduce the analysis

**Requirements**: R (≥ 4.3) with the packages `tidyverse`, `readODS` and `cluster`.

```r
install.packages(c("tidyverse", "readODS", "cluster"))
```

**Steps** (run from the repository root; each script also works from `02_scripts/`):

```r
source("02_scripts/01_data_cleaning.R")     # raw ODS -> processed CSVs (validates 11 regions x 30 years)
source("02_scripts/02_analysis_recovery.R") # recovery metrics, models, cluster and correlation outputs
source("02_scripts/03_figures.R")           # writes all figures to 03_figures/
```

The scripts are deterministic (fixed seed for k-means) and every figure and number in the report is regenerated from the raw ORR files.

## Data sources and licence

- ORR **Regional rail usage** tables 1510 and 1540–1590 — https://dataportal.orr.gov.uk/statistics/usage/regional-rail-usage/
- ORR **Estimates of station usage** table 1415 — https://dataportal.orr.gov.uk/statistics/usage/estimates-of-station-usage/

Data are published under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

## Related project

The companion repository for the **IJC445 – Data Visualisation** coursework uses the same source data with a visualisation-focused brief: https://github.com/Qjins/IJC445-UK-Rail-Recovery-Visualisation
