if (!require('tidyverse')) install.packages('tidyverse')
library(tidyverse)

data_dir <- 'data/'
output_dir <- 'output/'

oneicu_sofa <- read.csv(paste0(data_dir, 'oneicu_sofa.csv'))
mimic_sofa <- read.csv(paste0(data_dir, 'mimic_sofa.csv'))
eicu_sofa <- read.csv(paste0(data_dir, 'eicu_sofa.csv'))

metrics <- c('respiration', 'cardiovascular', 'coagulation', 'liver', 'renal', 'cns')

sofa_data_combined <- bind_rows(
  oneicu_sofa %>% 
    select(ends_with('notnull_rate')) %>%
    rename_with(~ metrics, ends_with('notnull_rate')) %>%
    pivot_longer(cols = metrics, names_to = 'Metric', values_to = 'NonNullRate') %>%
    mutate(Database = 'OneICU'),
  mimic_sofa %>% 
    select(ends_with('notnull_rate')) %>%
    rename_with(~ metrics, ends_with('notnull_rate')) %>%
    pivot_longer(cols = metrics, names_to = 'Metric', values_to = 'NonNullRate') %>%
    mutate(Database = 'MIMIC-IV'),
  eicu_sofa %>% 
    select(ends_with('notnull_rate')) %>%
    rename_with(~ metrics, ends_with('notnull_rate')) %>%
    pivot_longer(cols = metrics, names_to = 'Metric', values_to = 'NonNullRate') %>%
    mutate(Database = 'eICU')
) %>% 
  mutate(
    Metric = factor(
      Metric,
      levels = metrics
    ),
    Database = factor(
      Database,
      levels = c('OneICU', 'MIMIC-IV', 'eICU')
    )
  )

color_palette <- c('#6CC5B0FF', '#4269D0FF', '#FF8AB7FF')

fig_nonnull_rates <- ggplot(sofa_data_combined, aes(x = Metric, y = NonNullRate, fill = Database)) +
  geom_bar(stat = 'identity', position = position_dodge(width = 0.8), width = 0.66, color = 'black', linewidth = 0.1) +
  scale_fill_manual(values = c('OneICU' = color_palette[1], 'MIMIC-IV' = color_palette[2], 'eICU' = color_palette[3])) +
  labs(
    title = 'Comparison of Non-Null Rates in Databases',
    x = NULL,
    y = 'Non-Null Rate (%)',
    fill = 'Database'
  ) +
  theme_classic() +
  theme(
    text = element_text(family = 'Arial'),
    plot.title = element_text(size = 7, hjust = 0.6, color = 'black'),
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

# Save the plot
fig_nonnull_rates
ggsave(paste0(output_dir, 'fig_sofa_missing.tiff'), fig_nonnull_rates,
       width = 3.5, height = 2, dpi=600)
