# OneICU_profile_paper

This repository contains code to **summarize and compare** the characteristics of the OneICU database (developed by MeDiCU, Inc.) with the MIMIC‑IV and eICU databases **and** to **develop and evaluate machine‑learning models that predict hypotension in ICU patients** using vital signs and blood gas measurements across all three datasets. The goal is to provide a clear, reproducible approach for profiling, contrasting, and modeling these critical care databases.

---

## Table of Contents
- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Usage](#usage)
  - [SQL Queries](#sql-queries)
  - [Python Notebooks (Machine Learning)](#python-notebooks-machine-learning)
  - [R Scripts](#r-scripts)
- [Contact](#contact)
- [License](#license)

---

## Overview

The **OneICU_profile_paper** repository includes:

1. **SQL code** to query and summarize data from OneICU, MIMIC‑IV, and eICU.
2. **R scripts** to produce figures that summarize and compare key variables across the databases.
3. **Machine‑learning pipeline** to extract modeling datasets, train models with **H2O AutoML**, and evaluate **hypotension prediction** performance in **OneICU, MIMIC‑IV, and eICU**.
   - Modeling SQL lives under `sql/machine_learning/` and creates the inputs for training.
   - Python notebooks in `Python_scripts/` implement the end‑to‑end training/evaluation workflow.
   - For each database, we save **two model artifacts**: (i) the **leaderboard’s top AutoML model** (AutoML explores up to 20 base learners + 2 stacked ensembles) and (ii) a **simple GLM baseline**.  
   - **AUROC** is compared across the three datasets for both the AutoML best model and the GLM baseline.

By running the provided SQL, Python notebooks, and R scripts, researchers can reproduce the profiling steps and replicate the modeling workflow and evaluations.

---

## Repository Structure

```
OneICU_profile_paper
├── README.md
├── sql
│   ├── OneICU
│   │   └── *.sql
│   ├── MIMIC-IV
│   │   └── *.sql
│   ├── eICU
│   │   └── *.sql
│   └── machine_learning
│       ├── oneicu
│       │   └── *.sql
│       ├── mimiciv
│       │   └── *.sql
│       └── eicu
│           └── *.sql
├── Python_scripts
│   ├── 01_train_test_split.ipynb
│   ├── 02_machine_learning.ipynb
│   └── 03_model_evaluation.ipynb
└── R_scripts
    └── ...
```


- **sql**
  - **OneICU**, **MIMIC‑IV**, **eICU**: SQL scripts to profile each database (e.g., cohort selection, summaries) in Google BigQuery.
  - **machine_learning**:
    - **oneicu**, **mimiciv**, **eicu**: SQL to extract features/labels for **hypotension prediction** model training.
- **Python_scripts**
  - **01_train_test_split.ipynb** — creates train/test splits from the extracted datasets.
  - **02_machine_learning.ipynb** — trains models using **H2O AutoML**. We retain two artifacts per database: the **AutoML leaderboard top model** and a **GLM baseline**.
  - **03_model_evaluation.ipynb** — evaluates and **compares AUROC** across OneICU, MIMIC‑IV, and eICU for both the best AutoML model and the GLM model.
- **R_scripts**
  - `.R` scripts for figure generation and comparative analyses of database characteristics.

---

## Requirements

1. **Google BigQuery Access**  
   Access and credentials to query OneICU, MIMIC‑IV, and eICU in BigQuery.

2. **R**  
   R (≥ 4.0 recommended) to run the R scripts and generate figures.

3. **R Packages**  
   Common data analysis packages such as `tidyverse`, `ggplot2`, etc.  
   Check the header of each R script for exact library requirements.

4. **Python**  
   Python (≥ 3.8 recommended) with:
   - `h2o` (for AutoML)
   - `jupyter` (to run notebooks)
   - standard scientific stack (e.g., `pandas`, `numpy`)  
   Install via:  
   ```bash
   pip install polars scikit-learn numpy pandas h2o matplotlib seaborn


---

## Usage

### SQL Queries

1. **Navigate** to the appropriate SQL directory (e.g., sql/OneICU, sql/MIMIC-IV, sql/eICU) for profiling, or sql/machine_learning/<dataset>/ for modeling datasets.
2. **Open** the SQL script of interest.
3. **Copy** the script into your BigQuery console.
4. **Run** the query.

### Python Notebooks (Machine Learning)

1. **Prepare data**
Run the SQL under sql/machine_learning/oneicu, mimiciv, or eicu to materialize the training datasets (e.g., as BigQuery tables or exported files).
2. **Launch notebooks**
Start Jupyter (or VS Code with Jupyter) and open Python_scripts/.
3. **Train/test split**
Execute 01_train_test_split.ipynb to create reproducible splits.
4. **Model training (H2O AutoML)**
Run 02_machine_learning.ipynb. AutoML explores up to 20 base learners plus 2 stacked ensembles; we keep (a) the leaderboard best model and (b) a GLM baseline for each database.
5. **Evaluation**
Run 03_model_evaluation.ipynb to compute metrics and compare AUROC across OneICU, MIMIC‑IV, and eICU for the best AutoML model and the GLM model.

### R Scripts

1. **Clone** this repository or download the files.
2. **Open** your R environment (RStudio or equivalent).
3. **Install** any missing dependencies with install.packages("<package_name>").
4. **Run** the scripts in R_scripts/ to:
   - Load query outputs,
   - Perform data cleaning/manipulation as needed,
   - Generate summary tables/figures comparing the databases.

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
