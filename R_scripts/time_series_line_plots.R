if (!require('tidyverse')) install.packages('tidyverse')
library(tidyverse)

data_dir <- 'data/'
output_dir <- 'output/'

age_apsii_over_time <- read.csv(paste0(data_dir, 'age_apsii_over_time.csv'))
age_over_time <- age_apsii_over_time %>% filter(field_name == 'age')

fig_age_over_time <- ggplot(age_over_time, aes(x = icu_admission_year, y = median)) +
  geom_line(linewidth = 0.6, color = "#6CC5B0FF") +
  scale_x_continuous(limits = c(2013, 2024), breaks = c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024)) +
  scale_y_continuous(limits = c(60, 72), breaks = c(60, 65, 70)) +
  labs(title = 'Age Over Time',
       x = 'ICU Admission Year',
       y = 'Median Age (year)') +
  theme_classic() +
  theme(
    text = element_text(family = 'Arial'),
    plot.title = element_text(size = 7, hjust = 0.45, color = 'black'),
    axis.title.x = element_text(size = 6, color = 'black'),
    axis.title.y = element_text(size = 6, color = 'black'),
    axis.text.x = element_text(size = 5, color = 'black'),
    axis.text.y = element_text(size = 5, color = 'black'),
    legend.position = 'none',
    axis.line = element_line(linewidth = 0.1, color = 'black'),
    axis.ticks = element_line(linewidth = 0.1, color = 'black')
  )
fig_age_over_time
ggsave(paste0(output_dir, 'fig_age.tiff'), fig_age_over_time,
       width = 3.5, height = 2, dpi=600)

agsii_over_time <- age_apsii_over_time %>% filter(field_name == 'apsii')

fig_apsii_over_time <- ggplot(agsii_over_time, aes(x = icu_admission_year, y = median)) +
  geom_line(linewidth = 0.6, color = "#4269D0FF") +
  scale_x_continuous(limits = c(2013, 2024), breaks = c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024)) +
  scale_y_continuous(limits = c(12, 18), breaks = c(12, 15, 18)) +
  labs(title = 'Acute Physiology Score II Over Time',
       x = 'ICU Admission Year',
       y = 'Median Acute Physiology Score II') +
  theme_classic() +
  theme(
    text = element_text(family = 'Arial'),
    plot.title = element_text(size = 7, hjust = 0.45, color = 'black'),
    axis.title.x = element_text(size = 6, color = 'black'),
    axis.title.y = element_text(size = 6, color = 'black'),
    axis.text.x = element_text(size = 5, color = 'black'),
    axis.text.y = element_text(size = 5, color = 'black'),
    legend.position = 'none',
    axis.line = element_line(linewidth = 0.1, color = 'black'),
    axis.ticks = element_line(linewidth = 0.1, color = 'black')
  )
fig_apsii_over_time
ggsave(paste0(output_dir, 'fig_apsii.tiff'), fig_apsii_over_time,
       width = 3.5, height = 2, dpi=600)

mortality_over_time <- read.csv(paste0(data_dir, 'mortality_over_time.csv'))

fig_mortality_over_time <- ggplot(mortality_over_time, aes(x = icu_admission_year)) +
  geom_line(aes(y = icu_mortality, color = 'ICU Mortality'), linewidth = 0.6) +
  geom_line(aes(y = in_hospital_mortality, color = 'In-Hospital Mortality'), linewidth = 0.6) +
  scale_color_manual(values = c('ICU Mortality' = '#A463F2FF', 'In-Hospital Mortality' = '#FF8AB7FF')) +
  scale_x_continuous(limits = c(2013, 2024), breaks = c(2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024)) +
  scale_y_continuous(limits = c(0, 12)) +
  labs(title = 'Mortality Over Time',
       x = 'ICU Admission Year',
       y = 'Mortality (%)',
       color = 'Mortality Type') +
  theme_classic() +
  theme(
    text = element_text(family = 'Arial'),
    plot.title = element_text(size = 7, hjust = 0.45, color = 'black'),
    axis.title.x = element_text(size = 6, color = 'black'),
    axis.title.y = element_text(size = 6, color = 'black'),
    axis.text.x = element_text(size = 5, color = 'black'),
    axis.text.y = element_text(size = 5, color = 'black'),
    legend.position = 'none',
    axis.line = element_line(linewidth = 0.1, color = 'black'),
    axis.ticks = element_line(linewidth = 0.1, color = 'black')
  )
fig_mortality_over_time
ggsave(paste0(output_dir, 'fig_mortality.tiff'), fig_mortality_over_time,
       width = 3.5, height = 2, dpi=600)
