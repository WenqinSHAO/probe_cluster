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

#calculate power bin, using psd 
powBinPSD <- function(x, bins){ # bins are frequency vector relative to sampling frequency e.g. c(0,1/12,1/6)
  res <- psdcore(x)
  specLen <- length(res$freq)
  bins <- 2 * specLen * bins
  pow <- apply(embed(bins, 2), 1, function(x) sum(res$spec[x[2]:x[1]]))
  pow <- pow/sum(res$spec)
  return(pow)
}

# pw spec with specturm()
powBinSpecturm <- function(x, bins){ # bins are frequency vector relative to sampling frequency e.g. c(0,1/12,1/6)
  res <- spectrum(x)
  specLen <- length(res$freq)
  bins <- 2 * specLen * bins
  pow <- apply(embed(bins, 2), 1, function(x) sum(res$spec[x[2]:x[1]]))
  pow <- pow/sum(res$spec)
  return(pow)
}

# pw spec with fft
powBinFFT <- function(x, bins){ # bins are frequency vector relative to sampling frequency e.g. c(0,1/12,1/6)
  res <- fft(x)
  res <- Mod(res)
  res <- res[1: (length(res)/2)]
  specLen <- length(res)
  bins <- 2 * specLen * bins
  pow <- apply(embed(bins, 2), 1, function(x) sum(res[x[2]:x[1]]))
  pow <- pow/sum(res)
  return(pow)
}


### load data from file

# meta data of probes
pbMeta <- read.csv('probes.csv', header = T, stringsAsFactors = F)

# ping value with each time stamp as an individual column
pingRaw <- read.csv("pingAL_min.csv", header = T)

# make it a matrix/or time-series each row for each probe
pbRTT <- data.frame(id = pingRaw$id, ts = I(as.matrix(pingRaw[,2:ncol(pingRaw)])))
row.names(pbRTT$ts) <- pbRTT$id

# formate timestamps
tstp<- as.POSIXct(as.integer(substr(colnames(pbRTT$ts), 2, nchar(colnames(pbRTT$ts)))), tz='UTC', origin='1970-01-01')

# merge time-series and the metadata
#probes <- merge(pingTS, metaProbe, by = 'id', all.x = T)

# dataframe for RTT features 
pbFT <- data.frame(id = pingRaw$id)
row.names(pbFT) <- pbFT$id

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


# handle NA valude of skewness and kurtosis
# fill NA skewness with 0, NA kurtosis with 3
na.idx <- which(is.na(pbFT$skewness))
if (length(na.idx) > 0){
  pbFT[na.idx,]$skewness <- 0
  pbFT[na.idx,]$kurtosis <- -3
}

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
bins <- c(0, 1/4, 1/2)
powerSpecPSD <- apply(pbRTT$ts, 1, function(x) powBinPSD(x, bins))
powerSpecFFT <-apply(pbRTT$ts, 1, function(x) powBinFFT(x, bins))

pbFT_psd <- pbFT
pbFT_fft <- pbFT

for (i in c(1:(length(bins)-1))){
  pbFT_psd[,sprintf('Spec%d',i)] = powerSpecPSD[i,]
  pbFT[,sprintf('psd%d',i)] = powerSpecPSD[i,]
  pbFT_fft[,sprintf('Spec%d',i)] = powerSpecFFT[i,]
  pbFT[,sprintf('fft%d',i)] = powerSpecFFT[i,]
}


# save ft dataframe for furhter uses, calculate smpen is costly
save(pbFT, file='features.Rda')

# compare the difference of FFT and PSD in histrogram
pw = c('Spec1', 'Spec2')
diff_PSD_FFT <- pbFT_psd[,pw] - pbFT_fft[,pw]
pdf("diff_psd_fft.pdf", width = 8, height = 6)
par(mfcol=c(1,length(variable.names(diff_PSD_FFT))))
par(mar=c(3,5,0,0), oma=c(2,1,1,1))
for (spec in variable.names(diff_PSD_FFT)){
  hist(diff_PSD_FFT[,spec], freq=T, main=NULL, ylab = spec)
  lines(density(diff_PSD_FFT[,spec]), col='blue')
}
mtext('Difference between PSD and FFT', side = 1, outer = T)
dev.off()

# clustering analysis
pbFT$cls <- NULL
pbFT_psd$cls <- NULL
pbFT_fft$cls <- NULL
pbFT$cls <- clsAlyz(pbRTT$ts, pbFT[, variable.names(pbFT)!="id"], 2, "both")
pbFT_fft$cls <- clsAlyz(pbRTT$ts, pbFT_fft[, variable.names(pbFT_fft)!="id"], 2, "fft")
pbFT_psd$cls <- clsAlyz(pbRTT$ts, pbFT_psd[, variable.names(pbFT_psd)!="id"], 2, "psd")



