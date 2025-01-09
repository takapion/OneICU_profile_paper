# OneICU_profile_paper

This repository contains code to summarize and compare the characteristics of the OneICU database (developed by MeDiCU, Inc.) with the MIMIC-IV database and the eICU database. The goal is to provide a clear, reproducible approach for profiling and contrasting these three critical care databases.

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Usage](#usage)
  - [SQL Queries](#sql-queries)
  - [R Scripts](#r-scripts)
- [Contact](#contact)
- [License](#license)

---

## Overview

The **OneICU_profile_paper** repository includes:
1. **SQL code** to query and summarize data from OneICU, MIMIC-IV, and eICU.  
2. **R scripts** to produce figures summarizing and comparing key variables in these databases.

By running the provided SQL queries and R scripts, researchers can replicate the profiling steps and reproduce the figures for their own data comparisons and analyses.

---

## Repository Structure

```
OneICU_profile_paper
├── README.md
├── sql
│   ├── OneICU
│   │   └── ...
│   ├── MIMIC-IV
│   │   └── ...
│   └── eICU
│       └── ...
└── R_scripts
    └── ...
```

- **sql**  
  - **OneICU/**: SQL scripts specifically tailored to query the OneICU database in Google BigQuery.  
  - **MIMIC-IV/**: SQL scripts for querying the MIMIC-IV database in Google BigQuery.  
  - **eICU/**: SQL scripts for querying the eICU database in Google BigQuery.

- **R_scripts**  
  - Contains `.R` scripts for figure generation and analyses.

---

## Requirements

1. **Google BigQuery Access**  
   - To run the SQL scripts, you will need access to Google BigQuery and appropriate credentials to query each of the databases (OneICU, MIMIC-IV, and eICU).

2. **R**  
   - You will need R installed (version 4.0 or higher is recommended) to run the R scripts and generate figures.
   
3. **R Packages**  
   - Common data analysis packages like `tidyverse`, `ggplot2`, etc.   
   - Check the top of each R script for specific library requirements.

---

## Usage

### SQL Queries

1. **Navigate** to the appropriate SQL directory (e.g., `OneICU`, `MIMIC-IV`, or `eICU`).
2. **Open** the SQL script of interest.  
3. **Copy** the script into your BigQuery console.
4. **Run** the query.  
   - Ensure you have access to the respective dataset(s) and that your [BigQuery billing project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) is configured correctly.

### R Scripts

1. **Clone** this repository or download the files locally.
2. **Open** your R environment (RStudio or equivalent).
3. **Install** any missing R packages by running `install.packages("<package_name>")`.
4. **Run** the scripts in the `R_scripts` folder in the recommended order to:
   - Load query outputs.
   - Perform data cleaning or manipulation as needed.
   - Generate summary tables or figures comparing the databases.

---

## Contact

For questions or collaboration inquiries, please reach out to us by email:

- [MeDiCU, Inc.](mailto:info@medicu.co.jp)

---

## License
This project is licensed under the GNU General Public License (GPL) - see the [LICENSE.md](LICENSE.md) file for details.

---

**Disclaimer:**  
The code in this repository is provided for academic research and educational purposes. Individual patient data are not provided.
