library(sf)
library(tmap)
library(ggplot2)
library(dplyr)
library(tidyr)
library(here)

northland_dep <- readRDS("/Volumes/Transcend/Coding Projects/Data Science Projects/GIS Analysis Model/northland_sa2.rds")
OUTPUT_DIR <- "/Volumes/Transcend/Coding Projects/Data Science Projects/GIS Analysis Model/output"
dir.create(OUTPUT_DIR, showWarnings = FALSE)

src_note <- paste0(
  "Source: NZDep2023 (University of Otago); Stats NZ SA2 2025 boundaries (CC-BY 4.0).\n",
  "Deprivation score aggregated from SA1 level using population-weighted mean.\n",
  "CRS: NZGD2000 / NZTM2000 (EPSG:2193)"
)



p_score <- ggplot(northland_dep) +
  geom_sf(aes(fill = dep_score_wtd), colour = "white", linewidth = 0.1) +
  scale_fill_distiller(
    palette   = "RdYlBu",
    direction = -1,             
    name      = "Deprivation\nScore",
    na.value  = "grey88",
    labels    = scales::comma
  ) +
  facet_wrap(~ta, ncol = 1) + 
  labs(
    title    = "NZDep2023: Deprivation Score: Northland / Te Tai Tokerau",
    subtitle = "Population-weighted mean SA1 score aggregated to SA2",
    caption  = src_note
  ) +
  theme_void(base_family = "sans") +
  theme(
    plot.title       = element_text(size = 13, face = "bold"),
    plot.subtitle    = element_text(size = 9, colour = "grey40", margin = margin(b = 6)),
    plot.caption     = element_text(size = 6.5, colour = "grey55", hjust = 0),
    strip.text       = element_text(size = 9, face = "bold"),
    legend.position  = "right",
    plot.background  = element_rect(fill = "#f5f5f0", colour = NA),
    plot.margin      = margin(10, 10, 10, 10)
  )

ggsave(file.path(OUTPUT_DIR, "northland_dep_score_static.png"),
       p_score, width = 8, height = 11, dpi = 300)
message("Saved: northland_dep_score_static.png")



northland_dep <- northland_dep |>
  mutate(dep_decile_f = factor(dep_decile_int, levels = 1:10, ordered = TRUE))


pal10 <- rev(RColorBrewer::brewer.pal(10, "RdYlBu"))

p_decile <- ggplot(northland_dep) +
  geom_sf(aes(fill = dep_decile_f), colour = "white", linewidth = 0.1) +
  scale_fill_manual(
    values   = pal10,
    name     = "NZDep2023\nDecile",
    na.value = "grey88",
    drop     = FALSE,
    labels   = c("1 (least)", 2:9, "10 (most)")
  ) +
  labs(
    title    = "NZDep2023: Deprivation Decile: Northland / Te Tai Tokerau",
    subtitle = "Population-weighted mean decile aggregated from SA1 to SA2",
    caption  = src_note
  ) +
  theme_void(base_family = "sans") +
  theme(
    plot.title      = element_text(size = 13, face = "bold"),
    plot.subtitle   = element_text(size = 9, colour = "grey40", margin = margin(b = 6)),
    plot.caption    = element_text(size = 6.5, colour = "grey55", hjust = 0),
    legend.position = "right",
    plot.background = element_rect(fill = "#f5f5f0", colour = NA),
    plot.margin     = margin(10, 10, 10, 10)
  )

ggsave(file.path(OUTPUT_DIR, "northland_dep_decile_static.png"),
       p_decile, width = 8, height = 10, dpi = 300)
message("Saved: northland_dep_decile_static.png")



tmap_mode("view")

map_interactive <- tm_shape(northland_dep) +
  tm_fill(
    col      = "dep_score_wtd",
    style    = "cont",
    palette  = "-RdYlBu",
    title    = "NZDep2023 Score\n(pop-wtd mean)",
    alpha    = 0.75,
    popup.vars = c(
      "SA2"              = "sa2_name",
      "TA"               = "ta",
      "Dep. score (wtd)" = "dep_score_wtd",
      "Dep. decile (wtd)"= "dep_decile_wtd",
      "% in deciles 8–10"= "pct_high_dep",
      "Population"       = "pop_total"
    )
  ) +
  tm_borders(col = "white", lwd = 0.15) +
  tm_basemap("CartoDB.Positron") +
  tm_view(set.zoom.limits = c(7, 14))

tmap_save(map_interactive,
          file.path(OUTPUT_DIR, "northland_dep_interactive.html"),
          selfcontained = TRUE)

tmap_mode("plot")
message("Saved: northland_dep_interactive.html")


p_hist <- northland_dep |>
  st_drop_geometry() |>
  filter(!is.na(dep_decile_wtd)) |>
  ggplot(aes(x = dep_decile_wtd, fill = ta)) +
  geom_histogram(binwidth = 0.5, colour = "white", linewidth = 0.2) +
  scale_fill_brewer(palette = "Set2", name = NULL) +
  scale_x_continuous(breaks = 1:10, limits = c(0.5, 10.5)) +
  labs(
    x       = "NZDep2023 Weighted Mean Decile (10 = most deprived)",
    y       = "SA2 count",
    title   = "Distribution of deprivation across Northland SA2s",
    caption = "Source: NZDep2023; Stats NZ SA2 2025"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(OUTPUT_DIR, "northland_dep_distribution.png"),
       p_hist, width = 8, height = 4, dpi = 300)
message("Saved: northland_dep_distribution.png")


dep_summary <- northland_dep |>
  st_drop_geometry() |>
  filter(!is.na(dep_score_wtd)) |>
  group_by(ta) |>
  summarise(
    n_sa2           = n(),
    mean_score      = round(mean(dep_score_wtd), 0),
    mean_decile     = round(mean(dep_decile_wtd), 2),
    pct_high_dep    = round(mean(pct_high_dep, na.rm = TRUE), 1),
    pop_total       = sum(pop_total, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(mean_decile))

print(dep_summary)
saveRDS(dep_summary, "/Volumes/Transcend/Coding Projects/Data Science Projects/GIS Analysis Model/dep_summary_by_ta.rds")