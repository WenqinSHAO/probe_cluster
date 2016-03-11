### load library
library(moments)
library(changepoint)
library(pracma)
library(psd)
library(ggplot2)
library(clValid)
library(ggbiplot)
library(dtw)
library(cluster)

### load data from file

# meta data of probes
pbMeta <- read.csv('probes.csv', header = T, stringsAsFactors = F)
row.names(pbMeta) <- pbMeta$id

# ping value with each time stamp as an individual column
pingRaw <- read.csv("pingAL_min.csv", header = T)

# make it a matrix/or time-series each row for each probe
pbRTT <- data.frame(id = pingRaw$id, ts = I(as.matrix(pingRaw[,2:ncol(pingRaw)])))
row.names(pbRTT) <- pbRTT$id
row.names(pbRTT$ts) <- pbRTT$id

# calculate other timeseries representation
# segmemnts by changepoint analysis
ts.submin <- apply(pbRTT$ts, 1, subMin)
ts.submin <- t(ts.submin)
chptsMeanVar <- cpt.meanvar(ts.submin, test.stat = 'Poisson', method = 'PELT')
segLen <- lapply(chptsMeanVar, seg.len)
paraSeg <- lapply(chptsMeanVar, param.est)
paraSeg <- lapply(paraSeg, function(x){as.numeric(x[[1]])})
ts.seg <- t(mapply(repMulti, paraSeg, segLen))
row.names(ts.seg) <- pbRTT$id
pbRTT$seg <- ts.seg

#mode centred piece-wise scaled
ts.submode <- apply(pbRTT$ts, 1, subMod)
ts.submode <- t(ts.submode)
ts.mp <- as.matrix(t(apply(ts.submode, 1, myScale)))
row.names(ts.mp) <- pbRTT$id
pbRTT$mp <- ts.mp

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
pbFT$ncpts <- as.numeric(unlist(lapply(chptsMeanVar, ncpts)))

# get the maximum segment length in Mean changes
max.len <- lapply(segLen, max)
pbFT$MaxSegLen <- as.numeric(unlist(max.len))

# sample entropy
pbFT$smpen <- apply(pbRTT$ts, 1, sample_entropy)

# power spectum density
bins <- c(0, 1/12, 1/6, 1/2)
powerSpecFFT <-apply(pbRTT$ts, 1, function(x) powBinFFT(x, bins))
char.ft <- c('id', 'range', 'mode', 'mean', 'std', 'skewness', 'kurtosis', 'ncpts', 'smpen', 'MaxSegLen')
pbFT <- pbFT[, char.ft]
pbFT_fft <- pbFT
for (i in c(1:(length(bins)-1))){
  pbFT_fft[,sprintf('Spec%d',i)] = powerSpecFFT[i,]
  pbFT[,sprintf('fft%d',i)] = powerSpecFFT[i,]
  
}

# save ft dataframe for furhter uses, calculate smpen is costly
saveRDS(pbFT, file='features.Rda')

# load ft data from file
#pbFT = readRDS(file='features.Rda')

# calc scaled ft for each feature space
scale.fft <- scale(pbFT_fft[, !(variable.names(pbFT_fft) %in% c("id", "cls")), drop=F])
pca.fft <- princomp(scale.fft)

# compareing clustering settings with internal validation metrics
intval.fft <- clValid(scale.fft, 2:20, clMethods = c("hierarchical", "kmeans", "pam"), validation = "internal", method = "ward")

pdf('fft_intval.pdf', width=6, height = 4)
plot(intval.fft, main='')
dev.off()

# feature clustering analysis
pbFT_fft$cls <- NULL
pbFT_fft$cls <- clsAlyz(pbRTT$ts, pbFT_fft[, variable.names(pbFT_fft)!="id"], 2, "fft")

# distance mat on ts form of representationan
dist.ts <- dist(pbRTT$ts,pbRTT$ts, method = 'canberra')
dist.ts <- dist(pbRTT$ts, method = 'Euclidean')
dist.seg <- dist(pbRTT$seg, method = 'Euclidean')
dist.mp <- dist(pbRTT$mp, method='Euclidean')

#decide cluster number with ASW
sil.ts <- silPAM(dist.ts, 20)
sil.seg <- silPAM(dist.seg, 20)
sil.mp <- silPAM(dist.mp, 20)

pdf('sil_comp.pdf', width=8, height = 6)
sil.comp <- cbind(sil.ts, sil.seg, sil.mp)
matplot(2:20, sil.comp[-1,], type=c("b"), pch=1, col = 1:3, xlab = "k, number of cluster", ylab= "Average Silhouette Width", xlim=c(1,20), xaxp = c(2, 20, 9))
legend("topright", pch=1,legend=c("RTT", "Seg", "MP"), col = 1:3, bty="n")
dev.off()

NC <- 5

lb.ts <- clsAlyzTS(dist.ts, pca.fft, pbRTT$ts, NC, 'ts')
lb.seg <- clsAlyzTS(dist.seg, pca.fft, pbRTT$ts, NC, 'seg')
lb.ts <- clsAlyzTS(dist.mp, pca.fft, pbRTT$ts, NC, 'mp')


