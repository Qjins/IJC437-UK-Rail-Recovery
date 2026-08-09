# Methodology

This project follows a structured data science workflow (Section 2 of the report):

1. **Data collection** - ORR tables 1510 and 1540-1590 (regional journeys) and 1415 (station usage), preserved raw in `01_data/raw/`.
2. **Cleaning and validation** - robust rail-year parsing, handling of ORR footnote markers (`[b]` series break, `[x]`/`[z]` missing), programmatic completeness checks (11 regions x 30 years).
3. **Exploratory data analysis** - national and regional trends before, during and after COVID-19.
4. **Recovery indexing** - journeys indexed to the 2019 rail year (2019 = 100); recovery gap = 2025 index - 100.
5. **Modelling** - per-region 2010-2019 linear-trend counterfactuals for 2025; k-means clustering of standardised 2021-2025 trajectories (k by silhouette width); Pearson/Spearman correlations of the gap with regional characteristics.
6. **Granular analysis** - station-level recovery indices (2,554 stations) to examine variation within regions.
7. **Interpretation** - answers to RQ1-RQ3, limitations and links to the literature.
