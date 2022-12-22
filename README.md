# MPA-data-processing

This repository holds scripts for processing some of the data related to the MPA working group.

Author: Ian Brunjes, SCCOOS

## GLORYS Temperature Data

https://data.marine.copernicus.eu/product/GLOBAL_MULTIYEAR_PHY_001_030/description

Data processing on the GLORYS12V1 product derives Sea water potential temperature at sea floor (bottomT) for California MPAs where available.
NetCDF data is accessed through the Copernicus Marine Data Service via OpenDAP using R.

The location of each MPA is approximated using the nearest lat/long coordinate available given the GLORYS spatial resolution to the MPA's centroid.
Sea water potential temperature at sea floor (bottomT) is pulled, where available, across the full timespan of the dataset: 1993-01-01 to 2020-12-31
