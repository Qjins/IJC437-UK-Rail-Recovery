# IJC437-UK-Rail-Recovery

# Uneven Recovery of UK Rail Passenger Usage After COVID-19

This project analyses the uneven recovery of rail passenger usage across UK regions following the COVID-19 pandemic.  
Using official data from the Office of Rail and Road (ORR), the study examines how recovery patterns differ temporally and regionally, and whether pre-pandemic levels of demand have been restored uniformly.

This repository contains the analysis, code, and figures for the **IJC437 – Introduction to Data Science** coursework.  
The same dataset is also used in the **IJC445 – Data Visualisation** coursework, where the focus is on how recovery patterns are visually communicated.

---

## Project Overview

- **Topic**: Uneven recovery of UK rail passenger usage after COVID-19  
- **Geographical scope**: UK regions (e.g. London, South East, North East, Scotland, etc.)
- **Time period**: 1996–2025 (April–March years)
- **Data source**: Office of Rail and Road (ORR)
- **Baseline**: 2019 passenger journeys (indexed to 100)

The project goes beyond national-level trends to investigate **regional disparities** in post-pandemic recovery using exploratory data analysis and quantitative recovery indicators.

---

## Research Questions

1. How did UK rail passenger usage change before, during, and after the COVID-19 pandemic?
2. To what extent has the recovery of rail passenger usage been uneven across UK regions?
3. Which regions have returned to or exceeded pre-pandemic passenger levels, and which have not?

---

## Repository Structure

```text
IJC437-UK-Rail-Recovery/
│
├─ 01_data/
│   ├─ raw/          # Raw ORR datasets
│   └─ processed/    # Cleaned and indexed datasets (2019 = 100)
│
├─ 02_scripts/
│   ├─ 01_data_import.R
│   ├─ 02_data_cleaning.R
│   ├─ 03_eda_summary.R
│   ├─ 04_analysis_recovery_gap.R
│   └─ 05_analysis_recovery_speed.R
│
├─ 03_figures/       # Figures used in the report
│
├─ 04_methodology/
│   └─ methodology_diagram.png
│
├─ 05_report/
│   └─ IJC437_Report.docx
│
└─ README.md
