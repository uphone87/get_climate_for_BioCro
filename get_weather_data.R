library(lubridate)
latlon = read.csv('site_info.csv')

#NOTE: the NASA's time stamp is NOT UTC! It's the local time.
POWERNASA_to_BioCroInputs <- function(powernasa){
  solar <- powernasa$ALLSKY_SFC_PAR_TOT*4.25  #conversion from W/m2 to PPFD, See weach function. Note POWERNASA is PAR
  weatherdate <- as.Date(paste(powernasa$MO,"/",powernasa$DY,"/",powernasa$YEAR,sep=""),format=c("%m/%d/%Y"))
  doy <- yday(weatherdate)
  rh=powernasa$RH2M*0.01
  BioCroInputs <- data.frame(year=powernasa$YEAR,doy=doy,hour=powernasa$HR,temp=powernasa$T2M,rh=rh,
                             windspeed=powernasa$WS2M,precip=powernasa$PRECTOTCORR,solar=solar)
  return(BioCroInputs)
}

#first download the raw data from NASA
outfile_name=c()
for (i in 1:dim(latlon)[1]){
  lat = latlon$lat[i]
  lon = latlon$lon[i]
  year_start = latlon$year_start[i]
  year_end   = latlon$year_end[i]
  if(year_start<2001) stop("the starting year cannot be earlier than 2001!contact me for more info!")
  url=paste0("https://power.larc.nasa.gov/api/temporal/hourly/point?Time=LST&parameters=ALLSKY_SFC_PAR_TOT,T2M,RH2M,PRECTOTCORR,WS2M&community=AG&longitude=",lon,"&latitude=",lat,"&start=",year_start,"0101&end=",year_end,"1231&format=CSV")
  outfile_name[i] = paste0("NASA_powerdata_",year_start,"_",year_end,"_","site_",latlon$siteID[i],".csv")
  download.file(url, destfile = outfile_name[i], method="wget")
}

#then convert it to BioCro's input format
for (i in 1:dim(latlon)[1]){
  NASA_raw = read.csv(outfile_name[i],skip=13)
  biocro_climate <- POWERNASA_to_BioCroInputs(powernasa = NASA_raw)
  write.csv(biocro_climate,
            file = paste0('weather_for_BioCro/site_',i,'_',year_start,'_',year_end,'.csv'), row.names = FALSE)
}
system("rm NASA*.csv")
