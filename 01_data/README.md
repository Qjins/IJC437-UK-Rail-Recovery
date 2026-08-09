# Data

- `raw/` - unmodified ORR OpenDocument tables, preserved exactly as downloaded from the [ORR data portal](https://dataportal.orr.gov.uk/) (Open Government Licence v3.0):
  - `national/` table 1510 (GB journeys), `regional/` tables 1540-1590 (11 regions), `station/` table 1415 (entries and exits by station).
- `processed/` - cleaned datasets and analysis outputs written by the scripts in `02_scripts/`:
  - `national_time_series.csv`, `regional_time_series.csv`, `station_recovery.csv` (from script 01)
  - `rail_indexed_2019.csv`, `recovery_gap_2019_2025.csv`, `counterfactual_2025.csv`, `recovery_correlates*.csv`, `recovery_clusters.csv`, `station_summary_by_region.csv` (from script 02)

Years are rail years (April-March) labelled by end year: 2019 = April 2018 to March 2019.
