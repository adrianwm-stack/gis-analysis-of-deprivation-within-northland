**Deprivation & Road Access in Northland / Te Tai Tokerau**

A GIS analysis of socioeconomic deprivation and road accessibility across Northland, New Zealand; using R, RStudio, and public data both from the New Zealand government, and The University of Otago.

**Overview**

This project maps deprivation scores and sealed road accessibility across Northland's Statistical Area 2 (SA2) geographies, then tests whether more deprived communities systematically have worse access to sealed roads; a key infrastructure within New Zealand.

**Key outputs:**

 - Choropleth maps of deprivation and road accessibility at SA2 level
 - Population-weighted deprivation scores (means, aka averages) aggregated from SA1 data
 - Distances to the nearest sealed road for each SA2 centroid
 - OLS (Only Least Squares) regression of deprivation against road accessibility
 - Interactive HTML map (hosted at [Link yet to be hosted])

**Data Sources:**

All data is freely available online, under open licenses. 

- Data: Statistical Area 2 2025 boundaries; Source: https://datafinder.stats.govt.nz/layer/120978-statistical-area-2-2025/; License: CC-BY 4.0
- Data: NZDep2023 SA1 Index; Source: https://www.otago.ac.nz/wellington/research/groups/research-groups-in-the-department-of-public-health/hirp/socioeconomic-deprivation-indexes; License: Free (for research, academic purposes)
- Data: NZ Road Centrelines Topo 1:50k; Source: https://data.linz.govt.nz/layer/50329-nz-road-centrelines-topo-150k/; License: CC-BY 4.0

**Stuff I used:**

- R: Version 4.5.3 (2026-03-11) -- "Reassured Reassurer"
- **Packages:**

 - *sf:* Used for encoding, manipulating, and analysing GIS/spatial data. This package is essential for the type of analysis I have conducted here.
 -  *dplyr:* Another essential data manipulation library, essential to basically any data analysis/data science project conducted within R in my opinion.
 -   *ggplot2:* Used for visualisation of data analysis outputs; very common for visualising the models used to process data within R.
 -  *tidyr:* Data cleaning library. Data, especially at these quantities, is messy; you'll want something like tidyr to clean the data at hand to properly analyse the data.
 -  *readxl:* Used to read, and import the data from a .xlsx (Excel file). Used to import the data from the NZDep2023 data set.
 -  tmap:* GIS/spatial data visualisation library. Similar to ggplot2 in function, and again, essential to GIS data analysis.
 -   *here:* Simplfies file referencing, and building paths to directories. Not essential, but helpful for making finding files easier within the script.

  
