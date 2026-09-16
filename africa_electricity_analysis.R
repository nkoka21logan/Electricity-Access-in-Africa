# 1. Load required spatial and data manipulation packages
library(sf)
library(dplyr)
library(ggplot2)
library(ggrepel)

# 2. Import the spatial base map
africa_map <- st_read("africa (1).gpkg", layer = "all territories")

# 3. Read the electricity data, explicitly selecting the 2024 column (Index 7)
elec_data <- read.csv("electricity.csv", na.strings = c("..", "")) %>%
  select(Country.Code, Electricity_Access = `2024..YR2024.`) %>% 
  filter(!is.na(Electricity_Access))

# 4. Merge the spatial polygons with the electricity metric
map_data <- africa_map %>%
  left_join(elec_data, by = c("ISO" = "Country.Code"))

# 5. Isolate the Sahel "transitional deficit zone" states for our narrative annotations
sahel_epicenters <- map_data %>%
  filter(NAME_0 %in% c("Mali", "Niger", "Chad", "Sudan"))

# 6. Generate the Tufte-compliant Choropleth Map
pub_map <- ggplot(map_data) +
  # Base choropleth with thin white borders to reduce non-data ink
  geom_sf(aes(fill = Electricity_Access), color = "white", linewidth = 0.2) +
  
  # ggrepel pushes labels into empty space and draws a line to the country
  geom_text_repel(
    data = sahel_epicenters, 
    aes(label = NAME_0, geometry = geom),
    stat = "sf_coordinates",
    color = "darkred", 
    fontface = "bold", 
    size = 3.5,
    box.padding = 2,            
    min.segment.length = 0,     
    segment.color = "darkred",
    segment.linewidth = 0.6
  ) + 
  
  # Academic styling (yellow-to-dark-blue palette is great for electricity)
  scale_fill_gradient(low = "#ffeda0", high = "#08519c", na.value = "gray90",
                      name = "Access to Electricity\n(% of population)") +
  labs(
    title = "The Geographic Divide of Energy Poverty in Africa (2024)",
    subtitle = "Highlighting the Sahel region as the infrastructural boundary of electrification",
    caption = "Data: World Bank | Map: africa (1).gpkg"
  ) +
  
  # Strict Tufte compliance: theme_void() removes all coordinates, axes, and background panels
  theme_void() + 
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, face = "italic", hjust = 0.5),
    legend.position = "bottom",
    legend.title = element_text(size = 9, face = "bold")
  )

# 7. Save the high-resolution thematic map with a forced white background
ggsave("africa_electricity_map_2024.png", plot = pub_map, width = 8, height = 8, dpi = 300, bg = "white")
