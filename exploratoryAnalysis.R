### load library
library(moments)
library(changepoint)
library(pracma)
library(psd)


### functions

#Mode <- function(x) {
#  ux <- unique(x)
#  ux[which.max(tabulate(match(x, ux)))]
#}

#calculate power bin
powBin <- function(x, bins){ # bins are frequency vector relative to sampling frequency e.g. c(0,1/12,1/6)
  res <- psdcore(x)
  specLen <- length(res$freq)
  bins <- 2 * specLen * bins
  pow <- apply(embed(bins, 2), 1, function(x) sum(res$spec[x[2]:x[1]]))
  pow <- pow/sum(res$spec)
  return(pow)
}
### load data from file

# meta data of probes
pbMeta <- read.csv('probes.csv', header = T, stringsAsFactors = F)

# ping value with each time stamp as an individual column
pingRaw <- read.csv("pingAL_min.csv", header = T)

# make it a matrix/or time-series each row for each probe
pbRTT <- data.frame(id = pingRaw$id, ts = I(as.matrix(pingRaw[,2:ncol(pingRaw)])))

# formate timestamps
tstp<- as.POSIXct(as.integer(substr(colnames(pbRTT$ts), 2, nchar(colnames(pbRTT$ts)))), tz='UTC', origin='1970-01-01')

# merge time-series and the metadata
#probes <- merge(pingTS, metaProbe, by = 'id', all.x = T)

# dataframe for RTT features 
pbFT <- data.frame(id = pingRaw$id)

### calculated statistic features of the pingtrace for each probe

# value level
range_ <- apply(pbRTT$ts, 1, range)
pbFT$range <- range_[2,] - range_[1,]
pbFT$mode <- apply(pbRTT$ts, 1, Mode)

# moments
pbFT$mean <- apply(pbRTT$ts, 1, mean)
pbFT$std <- apply(pbRTT$ts, 1, sd)
pbFT$skewness <- apply(pbRTT$ts, 1, skewness)
pbFT$kurtosis <- apply(pbRTT$ts, 1, kurtosis)

# change points; the way change number is calculated need further discussion
MeanCpts <- cpt.mean(pbRTT$ts, test.stat = 'Normal', method = 'PELT')
#MeanCpts1000 <- cpt.mean(probes$ts, test.stat = 'Normal', method = 'PELT', penalty = 'Manual', pen.value = 1000)
pbFT$MeanCpts <- as.numeric(unlist(lapply(MeanCpts, ncpts)))
MeanVarCpts <- cpt.meanvar(pbRTT$ts, test.stat = 'Poisson', method='PELT')
#MeanVarCpts08 <- cpt.meanvar(probes$ts, test.stat = 'Poisson', method='PELT', penalty = 'Manual', pen.value = 0.8)
pbFT$MeanVarCpts <- as.numeric(unlist(lapply(MeanVarCpts, ncpts)))

# sample entropy
pbFT$smpen <- apply(pbRTT$ts, 1, sample_entropy)

# power spectum density
bins <- c(0,1/12,1/6,1/2)
powerSpec <- apply(pbRTT$ts, 1, function(x) powBin(x, bins))
for (i in c(1:(length(bins)-1))){
  pbFT[,sprintf('Spec%d',i)] = powerSpec[i,]
}

# save ft dataframe for furhter uses
save(pbFT, file='features.Rda')
