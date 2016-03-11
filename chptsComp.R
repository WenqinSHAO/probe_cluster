library(changepoint)
library(RColorBrewer)
library(Rmisc)

plotMeanVarCpt <- function(idx, pbidObj, tsObj, cptObj){
  ts <- tsObj[idx,]
  cpts <- cpts(cptObj[[idx]])
  id <- pbidObj[idx]
  title <- sprintf("Probe %d MeanVar Change Poisson Minsub", id)
  filename <- sprintf("p_meanvar_%d", id)
  plotCpt(tstp, ts, cpts, title, filename)
}

plotCpt <- function(tstp, ts, cpts, title, filename) {
  fn <- sprintf("%s.pdf", filename)
  pdf(fn, width=10, height=7)
  plot(tstp, ts, type='l', xlab='Time', ylab='RTT(ms)', main=title)
  abline(v=tstp[cpts], col='red', lty=2)
  dev.off()
}

#merge consective short segment that is inferior to tau
absorbChpts <- function(v, tau){
  if (length(v) >=3 ){
    v_1 = v[-1]
    dis = v_1 - v[1:(length(v)-1)]
    dis_r = dis[-1]
    dis_l = dis[1:length(dis)-1]
    v_c = v_1[1: length(v_1)-1]
    new_v = v[1]
    for (i in 1:length(v_c)){
      if (dis_l[i] > tau || dis_r[i] > tau ){
        new_v = append(new_v, v_c[i])
      }
    }
    new_v = append(new_v, v[length(v)])
  } else{
    new_v = v
  }
  return(new_v)
}

# ping value with each time stamp as an individual column
pingRaw <- read.csv("pingAL_min.csv", header = T)

# make it a matrix/or time-series each row for each probe
pbRTT <- data.frame(id = pingRaw$id, ts = I(as.matrix(pingRaw[,2:ncol(pingRaw)])))
row.names(pbRTT) <- pbRTT$id
row.names(pbRTT$ts) <- pbRTT$id

# formate timestamps
tstp<- as.POSIXct(as.integer(substr(colnames(pbRTT$ts), 2, nchar(colnames(pbRTT$ts)))), tz='UTC', origin='1970-01-01')

# changepoint analysis
ts.submin01 <- apply(pbRTT$ts, 1, subMin01)
ts.submin01 <- t(ts.submin01)
ts.submin <- apply(pbRTT$ts, 1, subMin)
ts.submin <- t(ts.submin)
#ts.centerStd <- apply(pbRTT$ts, 1, centerStd)
#ts.submin <- t(ts.centerStd)


#ts.submin.gamma = ts.submin + 0.1
df.chpts = data.frame(id=pbRTT$id)
df.chpts[['Mean-Normal']] <- apply(ts.submin, 1, cpt.mean, test.stat = 'Normal', method= 'PELT')
df.chpts[['Var-Normal']] <- apply(ts.submin, 1, cpt.var, test.stat = 'Normal', method = 'PELT')
df.chpts[['MV-Poisson']] <- apply(ts.submin, 1, cpt.meanvar, test.stat = 'Poisson', method = 'PELT')
df.chpts[['MV-Gamma']] <- apply(ts.submin01,1, cpt.meanvar, test.stat='Gamma', method='PELT')
df.chpts[['MV-Exp']] <- apply(ts.submin, 1, cpt.meanvar, test.stat = 'Exponential', method = 'PELT')
df.chpts[['MV-Normal']] <- apply(ts.submin, 1, cpt.meanvar, test.stat = 'Normal', method = 'PELT')

#cls = brewer.pal(5, 'Set1')
mtd = names(df.chpts)[-1]
tau = 7
for(i in c(1:length(pbRTT$id))){
  id = pbRTT$id[i]
  fn = sprintf('chpts_%d.pdf', id)
  pdf(fn, width=8, height = 10)
  df.rtt = data.frame(time=tstp, rtt=as.numeric(unlist(pbRTT$ts[i,])))
  #chpts.all = double()
  #type.all = character()
  g = list()
  for(j in 1:length(mtd)){
    n = as.character(mtd[j])
    gt = ggplot(df.rtt, aes(time, rtt))
    gt = gt + geom_line()
    c = as.numeric(tstp[ cpts(df.chpts[[n]][[i]])])
    gt = gt + geom_vline(xintercept=c, col='blue', linetype=4)
    c = cpts(df.chpts[[n]][[i]])
    c = absorbChpts(c, tau)
    c = as.numeric(tstp[c])
    t = rep(n, length(c))
    #chpts.all = append(chpts.all, c)
    #type.all = append(type.all, t)
    gt = gt + geom_vline(xintercept=c, col='red', linewidth = 3, linetype=1, alpha=0.6)
    gt = gt + xlab('Time')
    gt = gt + ylab('RTT')
    gt = gt + annotate("text", x = df.rtt$time[length(df.rtt$time)], y = Inf, label = n, vjust=1, hjust=1)
    gt = gt + theme(text=element_text(size=14))
    #gt = gt + coord_cartesian(ylim=c(min(df.rtt$rtt)-3, min(df.rtt$rtt)+30))
    g[[j]] = gt
  }
  #df.chtime = data.frame(time = chpts.all, type=type.all)
  #g = g +geom_vline(data=df.chtime, aes(xintercept=time, col=type, linetype=type), show_guide=T)
  multiplot(plotlist = g, cols = 1)
  dev.off()
}


for (i in c(1:length(pbRTT$id))){
  plotMeanVarCpt(i, pbRTT$id, pbRTT$ts, chptsMeanVar)
}