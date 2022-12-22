library(tidyverse)
library(lubridate)
library(tidync)
library(here)

# Read MPA data
mpas = readRDS(here::here("data", "CA_MPA_polygons.Rds"))

# Build dataset access URL
# The Copernicus Marine Data Store requires account credentials for persistent access
un = ##
pw = ##
datasetID = 'cmems_mod_glo_phy_my_0.083_P1D-m'
url = paste ("https://",un, ":", pw,"@my.cmems-du.eu/thredds/dodsC/",datasetID, sep = "")

# Open connection to dataset
glorys = tidync(url)

# Pull the dimensions for indexing
dim_lat = glorys %>% activate("D1") %>% hyper_tibble()
dim_lon = glorys %>% activate("D2") %>% hyper_tibble()
dim_time = glorys %>% activate("D3") %>% hyper_tibble()

# Create mapping of posix time to date
time_map = data.frame(time = dim_time) %>% 
  mutate(
    date = as.Date(time/24, origin="1950-01-01"),
  )

# Function to find closest coord
closest <- function(xv,sv){
  which(abs(xv-sv)==min(abs(xv-sv)))
}

# Find closest lat/lon coord for each MPA
mpas_mod <- mpas %>%
  rowwise() %>%
  mutate(
    long_nearest_ix = closest(dim_lon$longitude, long_dd),
    long_nearest = dim_lon$longitude[long_nearest_ix],
    lat_nearest_ix = closest(dim_lat$latitude, lat_dd),
    lat_nearest = dim_lat$latitude[lat_nearest_ix]
  ) %>% select(-c('geometry')) # Note: splicing bulky geometry column out for now


# Pull and save data in chunks for each MPA lat/long
for (i in 1:nrow(mpas_mod)) {
  current_mpa = mpas_mod[i,]
  
  # Pull bottom temperature data for MPA
  print(paste(i, ": Pulling data for", current_mpa$name))
  mpa_data <- glorys %>%
    activate("D2,D1,D3", select_var = c("bottomT")) %>%
    hyper_filter(
      latitude = index == mpas_mod[i,]$lat_nearest_ix,
      longitude = index == mpas_mod[i,]$long_nearest_ix
    ) %>%
    hyper_tibble()
  print (paste("Completed data pull for", current_mpa$name))
  
  # Aggregate and format data
  mpa_data_mod = mpa_data %>%
    mutate(
      mpa_name = current_mpa$name,
      long_dd = current_mpa$long_dd,
      lat_dd = current_mpa$lat_dd,
      long_approx = longitude,
      lat_approx = latitude,
    ) %>%
    merge(y = time_map, by = "time", all.x = TRUE) %>% 
    select(mpa_name, date, bottomT, long_dd, lat_dd, long_approx, lat_approx)
  
  write_csv(mpa_data_mod, here::here("data", "chunked_results", paste0("mpa_bottomT_", i, ".csv")))
}

# Read all data chunks into single dataframe
MPAs_Temp_Data = list.files(path = here::here("data", "chunked_results"), pattern = "*.csv", full.names = T) %>%
  lapply(read_csv) %>% 
  bind_rows()

# Filter to see which MPAs returned no data
MPAs_No_Data = mpas_mod %>% filter(!name %in% unique(MPAs_Temp_Data$mpa_name))

# Write data to file
#MPAs_Temp_Data %>% write_csv(here::here("data", "CA_MPA_glorys_bottomT.csv"))

### To pull in the additional information from the columns of the original MPA table, join on "name"=="mpa_name"
### Though it may be better to subset/filter the temp data externally
### Sample plot: time series of bottom temp for all central coast reserves
# central_mpas = mpas_mod %>% filter(region == "CCSR") %>% pull("name") 
# MPAs_Temp_Data %>%
#   filter(mpa_name %in% central_mpas) %>% 
#   ggplot(aes(x = date, y = bottomT, color = mpa_name)) +
#   geom_line() +
#   theme(legend.key.size = unit(.25, 'cm'), legend.text = element_text(size = 8)) +
#   guides(color=guide_legend(ncol=1))
