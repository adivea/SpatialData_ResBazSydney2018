###   PLOTTING IN LEAFLET USING ONLINE DATA FROM CA


###   Example from UC Davis RUser group
###   https://ryanpeek.github.io/2017-08-03-converting-XY-data-with-sf-package/
  
# Packages
  
install.packages("htmltab")
install.packages("leaflet")

# Load libraries
suppressMessages({
  library(tidyverse)
  library(sf)
  library(htmltab)
})

# Download data
url <- "http://www.hotspringsdirectory.com/usa/ca/gps-usa-ca.html"
df <- htmltab(url, which=1, header = 1,
              colNames = c("STATE","LAT","LONG","SpringName","Temp_F", "Temp_C", "AREA", "USGS_quad") )  # get the data


# Convert Lat/Long columns to numeric:

sapply(df, class)  # dataframe is  of character class now
cols.num<- c("LAT","LONG", "Temp_F", "Temp_C")  # select columns which need to be numeric
df[cols.num]<-sapply(df[cols.num], as.numeric)  
# beware that some NA's will appear where there are no temperatures available

df$LONG<-df$LONG*(-1)   # sanity check given the western hemisphere
head(df)

# The chunk above does the following:
#   
# Function from the htmltab package goes and grabs the first table on the page, 
# parses it out into a dataframe, and adds custom column names. 
# We should have 303 rows and 8 columns of data, including the temperature in °F and °C.
# Then identify the column classes and select columns we want to convert to numeric.
# Apply those changes to those columns using sapply
# Make sure our longitude is negative, so that these plot in the right hemisphere. :)




# Make the UTM cols spatial (X/Easting/lon, Y/Northing/lat)
df.SP <- st_as_sf(df, coords = c("LONG", "LAT"), crs = 4326)
st_crs(df.SP)


# to project the file to UTM 10N
st_crs(32610)
df.SP <- st_transform(df.SP, crs=32610) # but tiles in Leaflet use Web Mercator 4326

# To get projected coordinates (Northing&Easting) and feed them back into the csv
df.SP$utm_E <- st_coordinates(df.SP)[,1]
df.SP$utm_N <- st_coordinates(df.SP)[,2]
st_coordinates(df.SP)

# Coerce back to data.frame:
df.SP<-st_set_geometry(df.SP, NULL)

plot(df.SP)


## PLOTTING in Leaflet

# Reproject into Web Mercator for display in Leaflet
df.SP <- st_transform(df.SP, crs=4326) # Base imagery is 3D


library(leaflet)

leaflet() %>%
  addTiles() %>%
  addProviderTiles("Esri.WorldTopoMap", group = "Topo") %>%
  addProviderTiles("Esri.WorldImagery", group = "ESRI Aerial") %>%
  addCircleMarkers(data=df.SP, group="Hot Springs", radius = 4, opacity=1, fill = "darkblue",stroke=TRUE,
                   fillOpacity = 0.75, weight=2, fillColor = "yellow",
                   popup = paste0("Spring Name: ", df.SP$SpringName,
                                  "<br> Temp_F: ", df.SP$Temp_F,
                                  "<br> Area: ", df.SP$AREA)) %>%
  addLayersControl(
    baseGroups = c("Topo","ESRI Aerial", "Night"),
    overlayGroups = c("Hot SPrings"),
    options = layersControlOptions(collapsed = T))


