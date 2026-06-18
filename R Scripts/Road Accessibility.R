library(sf)
library(dplyr)
library(ggplot2)
library(tidyr)

BASE_DIR <- "/Volumes/Transcend/Coding Projects/Data Science Projects/GIS Analysis Model"
roads_path <- file.path(BASE_DIR, "lds-nz-road-centrelines-topo-150k-SHP", "nz-road-centrelines-topo-150k.shp")


OUTPUT_DIR <- file.path(BASE_DIR, "Output For Roads")
dir.create(OUTPUT_DIR, showWarnings = FALSE)

message("Loading northland_dep...")
northland_dep <- readRDS(file.path(BASE_DIR, "northland_sa2.rds"))

message("Loading road centrelines...")
roads <- st_read(roads_path, quiet = TRUE)

message("Roads CRS: ", st_crs(roads)$input)
message("SA2 CRS: ", st_crs(northland_dep)$input)

roads <- roads |>
  filter(is.na(status) | status != "under construction") |>
  rename(
    road_name = name,
    road_ascii = name_ascii,
    road_surface = surface
  )

message(sprintf("Road segments after filtering: %d", nrow(roads)))

roads_sealed <- roads |>
  filter(road_surface == "sealed")

message(sprintf("Sealed road segments: %d", nrow(roads_sealed)))
message(sprintf("All road segments: %d", nrow(roads)))

message("Computing SA2 centroids...")
centroids <- northland_dep |>
  st_point_on_surface()

message("Computing distance to nearest road (all surfaces)...")

nearest_idx_all <- st_nearest_feature(centroids, roads)
nearest_roads_all <- roads[nearest_idx_all, ]

northland_dep$dist_nearest_road_m <- st_distance(
  centroids,
  nearest_roads_all,
  by_element = TRUE
)

message("Computing distance to nearest sealed road...")

nearest_idx_sealed <- st_nearest_feature(centroids, roads_sealed)
nearest_roads_sealed <- roads_sealed[nearest_idx_sealed, ]

northland_dep$dist_nearest_sealed_m <- st_distance(
  centroids,
  nearest_roads_sealed,
  by_element = TRUE
)

northland_dep <- northland_dep |>
  mutate(
    dist_nearest_road_km = as.numeric(dist_nearest_road_m) / 1000,
    dist_nearest_sealed_km = as.numeric(dist_nearest_sealed_m) / 1000
  )

northland_dep |>
  st_drop_geometry() |>
  filter(!is.na(dep_score_wtd)) |>
  summarise(
    mean_dist_any_km = round(mean(dist_nearest_road_km), 3),
    mean_dist_sealed_km = round(mean(dist_nearest_sealed_km), 3),
    max_dist_sealed_km = round(max(dist_nearest_sealed_km), 3)
  ) |>
  print()

saveRDS(northland_dep, file.path(BASE_DIR, "northland_sa2_roads.rds"))
message("Saved: northland_sa2_roads.rds")

p_access <- ggplot(northland_dep |> filter(!is.na(dep_score_wtd))) +
  geom_sf(aes(fill = dist_nearest_sealed_km), colour = "white", linewidth = 0.1) +
  scale_fill_distiller(
    palette = "YlOrRd",
    direction = 1,
    name = "Distance to\n nearest sealed \n road (km)",
    na.value = "grey88",
    trans = "sqrt"
  ) +
  labs(
    title = "Road Accessibility in Northland / Te Tai Tokerau",
    subtitle = "Distance from SA2 centroid to nearest sealed road",
    caption = paste0( "Source: LINZ NZ Road Centrelines Topo 1:50k; Stats NZ SA2 2025 (CC-BY 4.0).\n",
                      "CRS: NZGD2000 / NZTM2000 (EPSG:2193). Distance measured from SA2 centroid.")
    
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

ggsave(file.path(OUTPUT_DIR, "northland_road_access.png"),
       p_access, width = 8, height = 10, dpi = 300)
message("Saved: northland_road_access.png")

names(northland_dep)

plot_data <- northland_dep |>
  st_drop_geometry() |>
  filter(!is.na(dep_score_wtd), !is.na(dist_nearest_sealed_km))

p_scatter <- ggplot(plot_data, aes(x = dist_nearest_sealed_km, y = dep_score_wtd)) +
  geom_point(aes(colour = ta, size = pop_total), alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, colour = "grey30", linewidth = 0.8) +
  scale_color_brewer(palette = "Set2", name = "Territorial\n Authority") +
  scale_size_continuous(name = "Population", range = c(1, 6), labels = scales::comma) +
  labs(
    x = "Distance to nearest sealed road (km)",
    y = "NZDep2023 Score (population-weighted mean)",
    title = "Deprivation vs Road Accessibility - Northland SA2s",
    subtitle = "Each point is one SA2; size = population; line = OLS fit",
    caption = "Source: NZDep2023 (University of Otago), LINZ Road Centrelines Topo 1:50k."
  ) +
  theme_minimal(base_family = "sans") +
  theme(
    plot.title = element_text(size = 13, face = "bold"),
    plot.subtitle = element_text(size = 9, colour = "grey40"),
    plot.caption = element_text(size = 7, colour = "grey55", hjust = 0),
    legend.position = "right"
  )

ggsave(file.path(OUTPUT_DIR, "dep_vs_road_scatter.png"),
       p_scatter, width = 9, height = 6, dpi = 300)
message("Saved: dep_vs_road_scatter.png")

model <- lm(dist_nearest_sealed_km ~ dep_score_wtd + log(pop_total), data = plot_data)
model_summary <- summary(model)
print(model_summary)

sink(file.path(OUTPUT_DIR, "dep_vs_road_regression.txt"))
cat("OLS Regression: Distance to nearest sealed road ~ Deprivation score + Population\n")
cat("Data: Northland SA2s with deprivation data (NZDep2023)\n\n")
print(model_summary)
sink()

message("Saved: dep_vs_road_regression.txt")

coef_table <- as.data.frame(summary(model)$coefficients)

write.csv(
  coef_table,
  file.path(OUTPUT_DIR, "road_regression_coefficients.csv"),
  row.names = TRUE
)