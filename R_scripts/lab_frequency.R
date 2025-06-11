if (!require('tidyverse')) install.packages('tidyverse')
library(tidyverse)

data_dir <- 'data/'
output_dir <- 'output/'

oneicu_lab <- read.csv(paste0(data_dir, 'oneicu_lab.csv')) %>% 
  mutate(Database = 'OneICU')
mimic_lab <- read.csv(paste0(data_dir, 'mimic_lab.csv')) %>% 
  mutate(Database = 'MIMIC-IV')
eicu_lab <- read.csv(paste0(data_dir, 'eicu_lab.csv')) %>% 
  mutate(Database = 'eICU')

metrics_lab <- c('ph_per_day', 'lactate_per_day', 'wbc_per_day', 'hemoglobin_per_day',
                 'sodium_per_day', 'albumin_per_day', 'inr_per_day', 'd_dimer_per_day')

combined_lab <- bind_rows(oneicu_lab, mimic_lab, eicu_lab) %>% 
  pivot_longer(cols = c(ph_per_day, lactate_per_day, wbc_per_day, hemoglobin_per_day,
                        sodium_per_day, albumin_per_day, inr_per_day, d_dimer_per_day),
               names_to = 'Metric',
               values_to = 'Frequency') %>% 
  mutate(
    Metric = factor(
      Metric,
      levels = metrics_lab,
      labels = c('pH', 'Lactate', 'WBC', 'Hb', 'Na', 'Alb', 'PT-INR', 'D-dimer')
    )
  ) %>% 
  mutate(
    Database = factor(
      Database,
      levels = c('OneICU', 'MIMIC-IV', 'eICU')
    )
  )

# 'y_axis_upper_limit' sets an upper threshold for measurement frequencies.
# Any frequency above this threshold will be replaced with 'y_axis_upper_limit',
# ensuring that a few extreme outliers do not drastically compress the y-axis scale.
# This makes it easier to compare the majority of the data without sacrificing clarity.
y_axis_upper_limit <- 6

combined_lab <- combined_lab %>% 
  mutate(
    Frequency = pmin(Frequency, y_axis_upper_limit)
  )

color_palette <- c('#6CC5B0FF', '#4269D0FF', '#FF8AB7FF')

fig_lab_measurements_box <- ggplot(combined_lab, aes(x = Metric, y = Frequency, fill = Database)) +
  geom_boxplot(outlier.shape = NA, lwd = 0.1, position = position_dodge(width = 0.9)) + # Box plot
  scale_fill_manual(values = c('OneICU' = color_palette[1], 'MIMIC-IV' = color_palette[2], 'eICU' = color_palette[3])) +
  scale_x_discrete(labels = c('pH', 'Lactate', 'WBC', 'Hb', 'Na', 'Alb', 'PT-INR', 'D-dimer')) +
  scale_y_continuous(breaks = seq(1, y_axis_upper_limit), limits = c(0, y_axis_upper_limit)) +
  labs(
    title = 'Laboratory Test Measurement Frequency during the Entire ICU Stay',
    x = NULL,
    y = 'Measurement (/day)',
    fill = 'Database'
  ) +
  theme_classic() +
  theme(
    text = element_text(family = "Arial"),
    plot.title = element_text(size = 7, hjust = 0, color = 'black'),
    axis.title.x = element_text(size = 6, color = 'black'),
    axis.title.y = element_text(size = 6, color = 'black'),
    axis.text.x = element_text(size = 5, angle = 45, hjust = 1, color = 'black'),
    axis.text.y = element_text(size = 5, color = 'black'),
    legend.title = element_text(size = 5, color = 'black'),
    legend.text = element_text(size = 5, color = 'black'),
    legend.key.size = unit(0.05, 'inch'),
    axis.line = element_line(linewidth = 0.1, color = 'black'),
    axis.ticks = element_line(linewidth = 0.1, color = 'black')
  )

fig_lab_measurements_box
ggsave(paste0(output_dir, 'fig_lab.tiff'), fig_lab_measurements_box,
       width = 3.5, height = 2, dpi=600)
