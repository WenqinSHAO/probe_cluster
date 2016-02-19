#calculate the mode value of a vector
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

#substract a vector by its minmum val
subMin <- function(x) {
  return(as.vector(x-min(x)))
}

#substract a vector by its mode val
subMod <- function(x) {
  return(as.vector(x-Mode(x)))
}

# given two vector of identical length val and rep
# repreat the val_i rep_i times
# reture the combined vector
repMulti <- function(val, rep) {
  try(if(length(val)!=length(rep)) stop("Two vectors of different length."))
  res <- vector('double')
  for (i in c(1:length(val))) {
    res <- append(res, rep(val[i], rep[i]))
  }
  return(res)
}

#piece-wise scaling function
myScale <- function(x) {
  res <- ifelse(
    abs(x)<10, 0,
    ifelse(
      10<=abs(x) & abs(x)<60, abs(x)-10, 
      10*log2(abs(x))- (10*log2(60)-50)))
  return(res)
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

clsAlyz <- function(df.ts, df.ft, k, fnPref){
  # rows in df.ts and df.ft shall be in the same order
  # id's are removed
  # bettr is to give a row name that is identical to id
  
  #scale feature
  ftScale <- scale(df.ft)
  
  # pca
  ftPCA <- princomp(ftScale)

  # kmean clustering
  clsKM <- kmeans(ftScale, centers = k, iter.max = 200, nstart = 2000)
  lb <- factor(clsKM$cluster)

  # plot clusters on PCA
  fn <- sprintf("%s_pca.pdf", fnPref)
  pdf(fn, width = 6, height = 6)
  g <- ggbiplot(ftPCA, groups = lb, ellipse = T, var.axes = T, scale = 0)
  g <- g + theme(legend.direction = "horizontal", legend.position = "top", text=element_text(size=14))
  g <- g + coord_fixed(ratio = 1.5)
  print(g)
  dev.off()
  
  # plot ts of each cluster
  for(i in levels(lb))
  {
    fn <- sprintf("%s_cls%s.pdf",fnPref, i)
    pdf(fn, width=8, height=6)
    idx <- which(lb==i)
    ts.plot(as.ts(t(df.ts[idx,])))
    dev.off()
    fn <- sprintf("%s_cls%s.3dp", fnPref, i)
    prob_id <- row.names(df.ts)[idx]
    write(prob_id, file = fn, ncolumns = 1)
  }
  
  # boxplot of features by cluters
  fn <- sprintf("%s_box.pdf", fnPref)
  pdf(fn, width=8, height=8)
  par(mfrow=c(3,4))
  par(mar=c(3,5,0,0), oma=c(1,1,1,1))
  for(ft in variable.names(df.ft)){
    boxplot(df.ft[,ft]~lb, ylab=ft)
  }
  dev.off()
  
  # return clustering results
  return(lb)
  
}

# calculate silhoutte width for a range of k using PAM
silPAM <- function(mat, k) {
  aws <- -100
  for (i in 2:k) {
    pam_res <- pam(mat, diss = T, k=i)
    aws[i] <- pam_res$silinfo$avg.width
  }
  return(aws)
}

clsAlyzTS <- function(dist.ts, pca.ts, df.ts, Nclus, fnPref) {
  pam.ts <- pam(dist.ts, k=Nclus, diss=T)
  lab.ts <- factor(pam.ts$clustering)

  fn <- sprintf("%s_pca.pdf", fnPref)
  pdf(fn, width = 6, height = 6)
  g <- ggbiplot(pca.fft, scale=0, groups = lab.ts, ellipse = T, var.axes = T)
  g <- g + theme(legend.direction = "horizontal", legend.position = "top", text=element_text(size=14))
  g <- g + coord_fixed(ratio = 1.5)
  print(g)
  dev.off()
  
  fn <- sprintf("%s_sil.pdf", fnPref)
  pdf(fn, width = 6, height = 7)
  plot(pam.ts, main="")
  dev.off()

  for(i in levels(lab.ts))
  {
    fn <- sprintf("%s_cls%s.pdf", fnPref, i)
    pdf(fn, width=8, height=6)
    idx <- which(lab.ts==i)
    ts.plot(as.ts(t(df.ts[idx,])))
    dev.off()
    fn <- sprintf("%s_cls%s.3dpp", fnPref, i)
    prob_id <- row.names(df.ts)[idx]
    write(prob_id, file = fn, ncolumns = 1)
  }
  
  return(lab.ts)
}