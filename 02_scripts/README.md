# Scripts

R scripts for the full analysis pipeline. Run them in order from the project root (each script also detects and corrects the working directory if launched from this folder).

| Script | Purpose |
|---|---|
| `01_data_cleaning.R` | Parses the raw ORR ODS tables (regional, national, station), handles footnote markers (`[b]`, `[x]`, `[z]`), extracts rail years robustly and validates completeness (11 regions × 30 years, no missing values). |
| `02_analysis_recovery.R` | Computes the 2019 = 100 recovery index and recovery gap, fits per-region 2010–2019 linear-trend counterfactuals for 2025, runs k-means clustering of recovery trajectories (k chosen by silhouette width, fixed seed) and correlation tests, and summarises station-level recovery. |
| `03_figures.R` | Produces every figure used in the report (PNG, 300 dpi) into `03_figures/`. |

Required packages: `tidyverse`, `readODS`, `cluster`.
