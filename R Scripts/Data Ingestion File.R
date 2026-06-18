library(sf)
library(dplyr)
library(readxl)
library(tidyr)

shp_path <- file.path("/Volumes/Transcend/Coding Projects/Data Science Projects/GIS Analysis Model/statsnz-statistical-area-2-2025-SHP/statistical-area-2-2025.shp")
dep_path <- file.path("/Volumes/Transcend/Coding Projects/Data Science Projects/GIS Analysis Model/NZDep2023_SA1.xlsx")


message("Reading SA2 shapefile...")
sa2 <- st_read(shp_path, quiet = TRUE) |>
  rename(
    sa2_code  = SA22025_V1,
    sa2_name  = SA22025__1,
    sa2_ascii = SA22025__2,
    land_area = LAND_AREA_,
    area_sqkm = AREA_SQ_KM
  ) |>
  mutate(sa2_code = as.integer(sa2_code))

message("CRS: ", st_crs(sa2)$input)  


northland <- sa2 |>
  filter(sa2_code >= 100100, sa2_code <= 113999)

message(sprintf("Northland SA2s: %d", nrow(northland)))


message("Reading NZDep2023_SA1.xlsx...")
dep_sa1 <- read_excel(dep_path, sheet = "NZDep2023_SA1") |>
  rename(
    sa1_code   = SA12023_code,
    dep_decile = NZDep2023,
    dep_score  = NZDep2023_Score,   
    pop        = URPopnSA1_2023,
    sa2_code   = SA22023_code,
    sa2_name   = SA22023_name
  ) |>
  mutate(
    sa2_code   = as.integer(sa2_code),
    pop        = as.numeric(pop)       
  )

glimpse(dep_sa1)



dep_sa2 <- dep_sa1 |>
  group_by(sa2_code, sa2_name) |>
  summarise(
    n_sa1            = n(),
    pop_total        = sum(pop, na.rm = TRUE),
    dep_score_wtd    = if (sum(pop, na.rm = TRUE) > 0)
      weighted.mean(dep_score, w = replace_na(pop, 0), na.rm = TRUE)
    else NA_real_,
    dep_decile_wtd   = if (sum(pop, na.rm = TRUE) > 0)
      weighted.mean(dep_decile, w = replace_na(pop, 0), na.rm = TRUE)
    else NA_real_,
    pct_high_dep     = sum(pop[dep_decile >= 8], na.rm = TRUE) /
      sum(pop, na.rm = TRUE) * 100,
    .groups = "drop"
  ) |>
  mutate(
    dep_decile_int = round(dep_decile_wtd))


glimpse(dep_sa2)


northland_dep <- northland |>
  left_join(dep_sa2 |>  select(sa2_code, dep_score_wtd, dep_decile_wtd, dep_decile_int, pct_high_dep, pop_total), by = "sa2_code")

n_matched <- sum(!is.na(northland_dep$dep_score_wtd))
message(sprintf("SA2s with deprivation data: %d / %d", n_matched, nrow(northland_dep)))

northland_dep |>
  st_drop_geometry() |>
  filter(is.na(dep_score_wtd)) |>
  select(sa2_code, sa2_name) |>
  print()


northland_dep <- northland_dep |>
  mutate(
    ta = case_when(
      sa2_code <= 104999 ~ "Far North District",
      sa2_code <= 110899 ~ "Whangārei District",
      TRUE               ~ "Kaipara / Auckland Fringe"
    ),
    dep_decile_int = round(dep_decile_wtd)
  )


saveRDS(northland_dep, "/Volumes/Transcend/Coding Projects/Data Science Projects/GIS Analysis Model/northland_sa2.rds")
message("Saved: data/northland_sa2.rds")


    