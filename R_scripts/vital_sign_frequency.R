if (!require('tidyverse')) install.packages('tidyverse')
library(tidyverse)

data_dir <- 'data/'
output_dir <- 'output/'

oneicu_vital <- read.csv(paste0(data_dir, 'oneicu_vital.csv')) %>% 
  mutate(Database = 'OneICU')
mimic_vital <- read.csv(paste0(data_dir, 'mimic_vital.csv')) %>% 
  mutate(Database = 'MIMIC-IV')
eicu_vital <- read.csv(paste0(data_dir, 'eicu_vital.csv')) %>% 
  mutate(Database = 'eICU')

oneicu_vital %>% pull(hr_per_hour) %>% quantile(c(0.25, 0.5, 0.75))
mimic_vital %>% pull(hr_per_hour) %>% quantile(c(0.25, 0.5, 0.75))
eicu_vital %>% pull(hr_per_hour) %>% quantile(c(0.25, 0.5, 0.75))

metrics_vital <- c('hr_per_hour', 'rr_per_hour', 'invasive_bp_per_hour',
                 'non_invasive_bp_per_hour', 'spo2_per_hour', 'bt_per_hour')

combined_vital <- bind_rows(oneicu_vital, mimic_vital, eicu_vital) %>% 
  pivot_longer(cols = c(hr_per_hour, rr_per_hour, invasive_bp_per_hour,
                         non_invasive_bp_per_hour, spo2_per_hour, bt_per_hour),
               names_to = 'Metric',
               values_to = 'Frequency') %>% 
  mutate(
    Metric = factor(
      Metric,
      levels = metrics_vital,
      labels = c('HR', 'RR', 'Invasive BP', 'Non Invasive BP', 'SpO2', 'BT')
    )
  ) %>% 
  mutate(
    Database = factor(
      Database,
      levels = c('OneICU', 'MIMIC-IV', 'eICU')
    )
  )

color_palette <- c('#6CC5B0FF', '#4269D0FF', '#FF8AB7FF')

fig_vital_measurements_box <- ggplot(combined_vital, aes(x = Metric, y = Frequency, fill = Database)) +
  geom_boxplot(outlier.shape = NA, lwd = 0.1, position = position_dodge(width = 0.9)) + # Box plot
  scale_fill_manual(values = c('OneICU' = color_palette[1], 'MIMIC-IV' = color_palette[2], 'eICU' = color_palette[3])) +
  scale_x_discrete(labels = c('HR', 'RR', 'Invasive BP', 'Non Invasive BP', 'SpO2', 'BT')) +
  scale_y_continuous(limits = c(0, 60)) +
  labs(
    title = 'Vital Sign Measurement Frequency during the Entire ICU stay',
    x = NULL,
    y = 'Measurement (/hour)',
    fill = 'Database'
  ) +
  theme_classic() +
  theme(
    text = element_text(family = "Arial"),
    plot.title = element_text(size = 7, hjust = -0.5, color = 'black'),
    axis.title.x = element_text(size = 6, color = 'black'),
    axis.title.y = element_text(size = 6, color = 'black'),
    axis.text.x = element_text(size = 4, angle = 45, hjust = 1, color = 'black'),
    axis.text.y = element_text(size = 4, color = 'black'),
    legend.title = element_text(size = 5, color = 'black'),
    legend.text = element_text(size = 4, color = 'black'),
    legend.key.size = unit(0.05, 'inch'),
    axis.line = element_line(linewidth = 0.1, color = 'black'),
    axis.ticks = element_line(linewidth = 0.1, color = 'black')
  )

fig_vital_measurements_box
ggsave(paste0(output_dir, 'fig_vital.tiff'), fig_vital_measurements_box,
       width = 3.5, height = 2, dpi=600)
