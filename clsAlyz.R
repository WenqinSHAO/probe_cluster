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