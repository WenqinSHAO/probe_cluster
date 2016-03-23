library(rjson)
library(lattice)
library(ggplot2)

#load time traceroute timestamp
temp = fromJSON(file='trace_tsmp.json')
time.epc = lapply(temp, getlistAtt, 'time_epc')
time.epc  = lapply(time.epc, toEpoc)
time.trace = data.frame(row.names=as.integer(attributes(temp)$names), tstp=I(time.epc), stringsAsFactors = F)

#load paris id
temp = fromJSON(file='trace_paris.json')
paris.id = data.frame(row.names = names(temp), parisID = I(temp))

#load ip path stat file
fn ='stat_ip_path.json'
att = c('length', 'countPriva', 'countStar','disChange', 'posChange', 'posPriva', 'posStar')
stat.ippath = loadPathStat(fn, att)

# load AS path mg stat file
fn = 'stat_as_path_mg.json'
att = c('length', 'countPriva', 'countStar','disChange', 'posChange', 'posPriva', 'posStar', 'countUnknown', 'posUnknown')
stat.asmg = loadPathStat(fn, att)

# load AS AS path ap stat file
fn = 'stat_as_path_ap.json'
att = c('length', 'countPriva', 'countStar','disChange', 'posChange', 'posPriva', 'posStar', 'countUnknown', 'posUnknown')
stat.asap = loadPathStat(fn, att)

# calculate statistics
path.stat = data.frame(row.names = row.names(stat.ippath))
path.stat[['dataLen']] = lapply(stat.ippath$length, length)

path.stat[['avgPathLen.IP']] = lapply(stat.ippath$length, mean)
path.stat[['modePathLen.IP']] = lapply(stat.ippath$length, Mode)
path.stat[['avgPathLen.ASMG']] = lapply(stat.asmg$length, mean)
path.stat[['modePathLen.ASMG']] = lapply(stat.asmg$length, Mode)
path.stat[['avgPathLen.ASAP']] = lapply(stat.asap$length, mean)
path.stat[['modePathLen.ASAP']] = lapply(stat.asap$length, Mode)

path.stat[['changeCount.IP']] = lapply(stat.ippath$disChange, countChange)
path.stat[['changeDis.IP']] = lapply(stat.ippath$disChange, avgChange)
path.stat[['changeCount.ASMG']] = lapply(stat.asmg$disChange, countChange)
path.stat[['changeDis.ASMG']] = lapply(stat.asmg$disChange, avgChange)
path.stat[['changeCount.ASAP']] = lapply(stat.asap$disChange, countChange)
path.stat[['changeDis.ASAP']] = lapply(stat.asap$disChange, avgChange)

path.stat[['privaCount.IP']] = lapply(stat.ippath$countPriva, sum)
path.stat[['starCount.IP']] = lapply(stat.ippath$countStar, sum)

path.stat[['privaCount.ASMG']] = lapply(stat.asmg$countPriva, sum)
path.stat[['starCount.ASMG']] = lapply(stat.asmg$countStar, sum)
path.stat[['unknownCount.ASMG']] = lapply(stat.asmg$countUnknown, sum)

path.stat[['privaCount.ASAP']] = lapply(stat.asap$countPriva, sum)
path.stat[['starCount.ASAP']] = lapply(stat.asap$countStar, sum)
path.stat[['unknownCount.ASAP']] = lapply(stat.asap$countUnknown, sum)


# number of private addresses in IP path
pdf('countPriva_ip_AvgPerPb.pdf', width=5, height = 4)
count.level = round(as.double(unlist(path.stat$privaCount.IP))/336,0)
#hist(count.level, breaks=c(0, 0.5, 1,2,3,4), main='', xlab = 'Avg. private address number per probe', freq = T)
g <- qplot(as.factor(count.level), geom="histogram", xlab="Avg. private address number per probe", ylab = "Probe Count")
g = g + theme(text=element_text(size=14))
print(g)
dev.off()
count.level = as.factor(count.level)
table(count.level)
# 71/128 probes have no IP-paths containing private IP address; 
# 46 probes have constantly 1 private address in the IP path;
# 8 probes have 2 private address
# 2 have three
# 1 have 4

# position of priva address in IP path
pos.byCount = data.frame()
for (i in levels(count.level)){
  pos = as.numeric(unlist(stat.ippath[which(count.level==i),]$posPriva))
  pos = pos[! pos %in% c(-1)]
  group = as.numeric(rep(i, length(pos)))
  newgroup = cbind(pos, group)
  pos.byCount = rbind(pos.byCount, newgroup)
}
pdf('posPriva_ip_byGroup.pdf', width = 5, height=4)
g = ggplot(pos.byCount, aes(x=pos, fill=as.factor(group)))
g = g + geom_histogram(breaks=seq(0,1,0.05), position = 'stack', alpha=0.8)
#g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Private IP # level")
g = g + xlab("Normalized Position")
g = g + ylab("Private IP Count")
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

# number and position of Probes having Priva in AS MG
pbs = row.names(path.stat[which(path.stat$privaCount.ASMG > 0),])
pos.byProbe = data.frame()
for (pb in pbs){
  pos = as.numeric(unlist(stat.asmg[pb,]$posPriva))
  pos = pos[! pos %in% c(-1)]
  posHop = pos * path.stat[pb,]$avgPathLen.ASMG[[1]]
  pbid = as.numeric(rep(pb, length(pos)))
  newgroup = cbind(pos, posHop, pbid)
  pos.byProbe = rbind(pos.byProbe, newgroup)
}
pdf('posPriva_asmg_byProbe.pdf', width = 5, height=4)
g = ggplot(pos.byProbe, aes(x=as.factor(round(posHop,0)), fill=as.factor(pbid)))
g = g + geom_histogram(position = 'stack', alpha=0.8)
#g = g + coord_cartesian(xlim = c(1,2))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("AS hop")
g = g + ylab("Private IP Count")
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

# number of stars in IP path
count.level = as.double(unlist(path.stat$starCount.IP))
pdf('countStar_ip.pdf', width = 6, height=4)
g <- qplot(as.factor(count.level), geom="histogram", xlab="Number of * in all IP paths", ylab = "Probe Count")
g = g + theme(text=element_text(size=14))
print(g)
dev.off()
# position of these stars
pos = as.numeric(unlist(stat.ippath$posStar))
pos = pos[! pos %in% c(-1)]
pdf('posStar_ip.pdf', width = 5, height = 3)
g <- qplot(pos, geom="histogram", breaks=seq(0,1,0.05), col=I('white'), xlab="Normalized position in IP path", ylab = "* Count")
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

# number of stars in AS MG
count.level = as.double(unlist(path.stat$starCount.ASMG))
pdf('countStar_asmg.pdf', width = 5, height=4)
g <- qplot(as.factor(count.level), geom="histogram", xlab="Number of * in AS IP paths", ylab = "Probe Count")
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

pbs = row.names(path.stat[which(path.stat$starCount.ASMG > 0),])
length(pbs)
pos.byProbe = data.frame()
for (pb in pbs){
  pos = as.numeric(unlist(stat.asmg[pb,]$posStar))
  pos = pos[! pos %in% c(-1)]
  posHop = pos * path.stat[pb,]$avgPathLen.ASMG[[1]]
  pbid = as.numeric(rep(pb, length(pos)))
  newgroup = cbind(pos, posHop, pbid)
  pos.byProbe = rbind(pos.byProbe, newgroup)
}
pdf('posStarASHOP_asmg_byProbe.pdf', width = 5, height=5)
g = ggplot(pos.byProbe, aes(x=as.factor(round(posHop,0)), fill=as.factor(pbid)))
g = g + geom_histogram(position = 'stack', alpha=1)
#g = g + coord_cartesian(xlim = c(1,2))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("AS hop")
g = g + ylab("* Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
g = g + theme(legend.text = element_text(size = 10))
g = g + guides(fill=guide_legend(ncol=3))
print(g)
dev.off()
pdf('posStar_asmg_byProbe.pdf', width = 5, height=5)
g = ggplot(pos.byProbe, aes(x=pos, fill=as.factor(pbid)))
g = g + geom_histogram(breaks=seq(0,1,0.1),position = 'stack', alpha=1)
#g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("AS hop")
g = g + ylab("* Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
g = g + theme(legend.text = element_text(size = 10))
g = g + guides(fill=guide_legend(ncol=3))
print(g)
dev.off()

#number and pos of unknown in AS MG
pbs = row.names(path.stat[which(path.stat$unknownCount.ASMG > 0),])
length(pbs)
pos.byProbe = data.frame()
for (pb in pbs){
  pos = as.numeric(unlist(stat.asmg[pb,]$posUnknown))
  pos = pos[! pos %in% c(-1)]
  posHop = pos * path.stat[pb,]$avgPathLen.ASMG[[1]]
  pbid = as.numeric(rep(pb, length(pos)))
  newgroup = cbind(pos, posHop, pbid)
  pos.byProbe = rbind(pos.byProbe, newgroup)
}
pdf('posUnkASHOP_asmg_byProbe.pdf', width = 5, height=4)
g = ggplot(pos.byProbe, aes(x=as.factor(round(posHop,0)), fill=as.factor(pbid)))
g = g + geom_histogram(position = 'stack', alpha=1)
#g = g + coord_cartesian(xlim = c(1,2))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("AS hop")
g = g + ylab("Unknown IP mapping Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
g = g + guides(fill=guide_legend(ncol=2))
print(g)
dev.off()
pdf('posUnk_asmg_byProbe.pdf', width = 5, height=4)
g = ggplot(pos.byProbe, aes(x=pos, fill=as.factor(pbid)))
g = g + geom_histogram(breaks=seq(0,1,0.1),position = 'stack', alpha=1)
#g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("Normalized Position")
g = g + ylab("Unknown IP mapping Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
g = g + guides(fill=guide_legend(ncol=2))
print(g)
dev.off()


# number and position of stars in ASAP
pbs = row.names(path.stat[which(path.stat$starCount.ASAP > 0),])
length(pbs)
pos.byProbe = data.frame()
for (pb in pbs){
  pos = as.numeric(unlist(stat.asmg[pb,]$posStar))
  #pos = pos[! pos %in% c(-1,1)]
  #pos = pos[pos %in% c(0)]
  # change the above term to plot all, mid, and * at the very end
  posHop = pos * path.stat[pb,]$avgPathLen.ASMG[[1]]
  pbid = as.numeric(rep(pb, length(pos)))
  newgroup = cbind(pos, posHop, pbid)
  pos.byProbe = rbind(pos.byProbe, newgroup)
}
pdf('posStarASHOP_asap_byProbe.pdf', width = 4, height=4)
g = ggplot(pos.byProbe, aes(x=as.factor(round(posHop,0)), fill=as.factor(pbid)))
g = g + geom_histogram()
g = g + geom_histogram(position = 'stack', alpha=1, col=I('white'), show_guide=FALSE)
#g = g + coord_cartesian(xlim = c(1,2))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("AS hop")
g = g + ylab("* Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
g = g + theme(legend.text = element_text(size = 11))
g = g + guides(fill=guide_legend(ncol=2))
print(g)
dev.off()
#pdf('posStar_asap_byProbe.pdf', width = 4, height=4)
g = ggplot(pos.byProbe, aes(x=pos, fill=as.factor(pbid)))
g = g + geom_histogram()
g = g + geom_histogram(breaks=seq(0,1,0.1),position = 'stack', alpha=1, col=I('white'), show_guide=FALSE)
#g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("Normalized Position")
g = g + ylab("* Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
g = g + theme(legend.text = element_text(size = 10))
g = g + guides(fill=guide_legend(ncol=1))
print(g)
#dev.off()

# unknown mapping in ASAP
pbs = row.names(path.stat[which(path.stat$unknownCount.ASAP > 0),])
length(pbs)
pos.byProbe = data.frame()
for (pb in pbs){
  pos = as.numeric(unlist(stat.asmg[pb,]$posUnknown))
  pos = pos[! pos %in% c(-1)]
  posHop = pos * path.stat[pb,]$avgPathLen.ASMG[[1]]
  pbid = as.numeric(rep(pb, length(pos)))
  newgroup = cbind(pos, posHop, pbid)
  pos.byProbe = rbind(pos.byProbe, newgroup)
}
pdf('posUnkASHOP_asap_byProbe.pdf', width = 5, height=4)
g = ggplot(pos.byProbe, aes(x=as.factor(round(posHop,0)), fill=as.factor(pbid)))
g = g + geom_histogram(position = 'stack', alpha=1)
#g = g + coord_cartesian(xlim = c(1,2))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("AS hop")
g = g + ylab("Unknown IP mapping Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
#g = g + guides(fill=guide_legend(ncol=2))
print(g)
dev.off()
pdf('posUnk_asap_byProbe.pdf', width = 5, height=4)
g = ggplot(pos.byProbe, aes(x=pos, fill=as.factor(pbid)))
g = g + geom_histogram(breaks=seq(0,1,0.1),position = 'stack', alpha=1)
#g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("Normalized Position")
g = g + ylab("Unknown IP mapping Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
#g = g + guides(fill=guide_legend(ncol=2))
print(g)
dev.off()

# IP avg. path length
avg.len = as.factor(round(as.numeric(unlist(path.stat$avgPathLen.IP)),0))
pdf('len_ip.pdf', width=4, height=4)
g = qplot(avg.len, geom = "histogram", xlab = 'Average IP path length', ylab = 'Probe Count', main='', col=I("white"))
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

len.byCounty = data.frame(avg.len = avg.len, country = pbMeta[row.names(path.stat),]$country_code)
pdf('len_ip_byCountry.pdf', width = 10, height=6)
g = ggplot(len.byCounty, aes(x=avg.len))
g = g + geom_histogram(col=I('white'))
g = g + facet_wrap(~country)
g = g + scale_fill_discrete(name="Country Code")
g = g + xlab("Average IP path length")
g = g + ylab("Probe Count")
g = g + theme(text=element_text(size=14), axis.text.x = element_text(angle=90, vjust=0.5, size=10))
print(g)
dev.off()

# ASAP length
avg.len = as.factor(round(as.numeric(unlist(path.stat$avgPathLen.ASAP)),0))
pdf('len_asap.pdf', width=4, height=4)
g = qplot(avg.len, geom = "histogram", xlab = 'Average AS path length', ylab = 'Probe Count', main='', col=I("white"))
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

len.byCounty = data.frame(avg.len = avg.len, country = pbMeta[row.names(path.stat),]$country_code)
pdf('len_asap_byCountry.pdf', width = 10, height=6)
g = ggplot(len.byCounty, aes(x=avg.len))
g = g + geom_histogram(col=I('white'))
g = g + facet_wrap(~country)
g = g + scale_fill_discrete(name="Country Code")
g = g + xlab("Average IP path length")
g = g + ylab("Probe Count")
g = g + theme(text=element_text(size=14), axis.text.x = element_text(angle=90, vjust=0.5, size=10))
print(g)
dev.off()

# number of IP path changes each probe
change.count = as.double(unlist(path.stat$changeCount.IP))/336
change.level = cut(change.count, breaks=c(0,0.25,0.4,0.75,1), labels=c('Rare', 'Low', 'Mid', 'High'))

pdf('countChange_ip.pdf', width=4, height=4)
g = qplot(change.count, geom = "histogram", binwidth=0.05, position = 'stack', xlab = 'Path Change Frequency', ylab = 'Probe Count', main='', fill = change.level)
g = g + theme(text=element_text(size=14))
g = g + scale_fill_discrete(name="Probe group")
g = g + theme(legend.position='top')
print(g)
dev.off()

pos = double()
group = factor()
for (i in levels(change.level)){
  p = as.numeric(unlist(stat.ippath[which(change.level==i),]$posChange))
  p = p[! p %in% c(-1)]
  g = rep(i, length(p))
  pos = append(pos, as.numeric(p))
  group = append(group, g)
}
group = as.factor(group)

group = factor(group, levels(group)[c(4,2,3,1)])
pos.byCount = data.frame(pos=pos, group=as.factor(group))
pdf('posChange_ip_byGroup.pdf', width = 4, height=4)
g = ggplot(pos.byCount, aes(x=pos, fill=group))
g = g + geom_histogram(breaks=seq(0,1,0.05))
g = g + geom_histogram(breaks=seq(0,1,0.05), position = 'stack', alpha=0.8, color=I('white'), show_guide=F)
#g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Probe group")
g = g + xlab("Normalized Position")
g = g + ylab("Path Change Count")
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

# number of AS AP path changes each probe
change.count = as.factor(unlist(path.stat$changeCount.ASAP))
df.tab = as.data.frame(table(change.count))
colnames(df.tab)[1] <- 'x'
change.countIP = as.double(unlist(path.stat$changeCount.IP))/336
change.levelIP = cut(change.countIP, breaks=c(0,0.25,0.4,0.75,1), labels=c('Rare', 'Low', 'Mid', 'High'))
pdf('countChange_asap.pdf', width = 4, height = 4)
g = qplot(change.count, geom = "histogram", fill=change.levelIP,  position = 'stack', xlab = 'AS Path Change Times', ylab = 'Probe Count', main='')
#g = g + geom_text(data=df.tab, aes(x=x, y=Freq, label=as.character(Freq)))
g = g + scale_fill_discrete(name="Probe group")
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()


pos = double()
posHop = integer()
pbid = character()
change.group = character()
for (i in 1:nrow(stat.asap)){
  if (path.stat[i,]$changeCount.ASAP > 0){
    for (j in 1:length(stat.asap[i,]$posChange[[1]])){
      if (stat.asap[i,]$posChange[[1]][j] > 0){
        pos = append(pos, stat.asap[i,]$posChange[[1]][j])
        posHop = append(posHop, stat.asap[i,]$posChange[[1]][j] * stat.asap[i,]$length[[1]][j-1])
        pbid = append(pbid, row.names(stat.asap)[i])
        change.group = append(change.group, as.character(change.levelIP[i]))
      }
    }
  }
}
change.group = as.factor(change.group)
levels(change.group)
change.group = factor(change.group, levels(change.group)[c(4,2,3,1)])
df.pos = data.frame(pos=pos, posHop=posHop, id = pbid, probe.group = change.group)
pdf('posChangeASHOP_asap_byGroup.pdf', width = 4, height=4)
g = ggplot(df.pos, aes(x=as.factor(round(posHop,0)), fill=change.group))
g = g + geom_histogram(position = 'stack', alpha=0.8)
#g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Probe group")
g = g + xlab("AS Hop")
g = g + ylab("Path Change Count")
#g = g + facet_wrap(~probe.group, scales = 'free_y')
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

pdf('posChange_asap_byGroup.pdf', width = 4, height=4)
g = ggplot(df.pos, aes(x=pos, fill=change.group))
g = g + geom_histogram(position = 'stack', alpha=0.8)
#g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Probe group")
g = g + xlab("Normalized Position")
g = g + ylab("Path Change Count")
#g = g + facet_wrap(~probe.group, scales = 'free_y')
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

#change distance IP
change.count = as.double(unlist(path.stat$changeCount.IP))/336
change.level = cut(change.count, breaks=c(0,0.25,0.4,0.75,1), labels=c('Rare', 'Low', 'Mid', 'High'))
change.dist = as.numeric(unlist(path.stat$changeDis.IP)) / as.numeric(unlist(path.stat$avgPathLen.IP))
change.dist = as.data.frame(change.dist)
change.dist[['level']] = change.level
pdf('dist_ip.pdf', width=4, height=4)
g = ggplot(change.dist, aes(x=change.dist, fill=level))
g = g + geom_histogram()
g = g + geom_histogram(poisition='stack', color=I('white'), alpha= 1, show_guide=F )
g = g + xlab('Average Path Change Distance /\n Average Path Length')
g = g + ylab('Probe Count')
g = g + scale_fill_discrete(name="Probe group")
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

#path change distance at as level
change.dist = as.numeric(unlist(path.stat$changeDis.ASAP)) / as.numeric(unlist(path.stat$avgPathLen.ASAP))
change.dist = as.data.frame(change.dist)
change.dist[['level']] = change.level
pdf('dist_asap.pdf', width=4, height=4)
g = ggplot(na.omit(change.dist), aes(x=change.dist, fill=level))
g = g + geom_histogram()
g = g + geom_histogram(poisition='stack', color=I('white'), alpha= 1, show_guide=F )
g = g + xlab('Average Path Change Distance /\n Average Path Length')
g = g + ylab('Probe Count')
g = g + scale_fill_discrete(name="Probe group")
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

change.dist = round(as.numeric(unlist(path.stat$changeDis.ASAP)),1)
change.dist = as.data.frame(change.dist)
change.dist[['level']] = change.level
pdf('distASHOP_asap.pdf', width=4, height=4)
g = ggplot(na.omit(change.dist), aes(x=as.factor(change.dist), fill=level))
g = g + geom_histogram()
g = g + geom_histogram(poisition='stack', color=I('white'), alpha= 1, show_guide=F )
g = g + xlab('Average Path Change Distance')
g = g + ylab('Probe Count')
g = g + scale_fill_discrete(name="Probe group")
g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

ts.submin <- apply(pbRTT$ts, 1, subMin)
ts.submin <- t(ts.submin)
chptsMeanVar <- apply(ts.submin, 1, cpt.meanvar, test.stat = 'Poisson', method = 'PELT')
# relation between RTT, changepoints, path changes, and Paris ID
for (pb in row.names(stat.ippath)){
  rtt.ts = pbRTT[pb,]$ts
  idx = which(row.names(pbRTT)==pb)
  chptsChange = cpts(chptsMeanVar[[idx]])
  ippathChange = time.trace[pb,][[1]][which(stat.ippath[pb,]$disChange[[1]]>0)]
  aspathChange = time.trace[pb,][[1]][which(stat.asap[pb,]$disChange[[1]]>0)]
  filename <- sprintf("change_%s.pdf", pb)
  pdf(filename, width = 14, height = 10)
  par(mar = c(5,5,1,5))
  plot(tstp, rtt.ts, type='l', xlab='Time', ylab='RTT(ms)')
  abline(v=tstp[chptsChange], col='red', lwd=1.5)
  abline(v=ippathChange, col='blue')
  abline(v=aspathChange, col='green', lwd=3, lty=3)
  par(new=T)
  plot(time.trace[pb,][[1]], paris.id[pb,][[1]], type='l', col='#636363', axes=F, xlab=NA, ylab=NA)
  axis(side=4)
  mtext(side = 4, line = 3, 'Paris ID')
  dev.off()
}

# for each AS path change, find the distance in time to the closet RTT change found by changepoint analysis
df.chDis = data.frame(id=as.numeric(row.names(stat.asap)), row.names = row.names(stat.asap))
tau = 7 # short segment absorption threshould
disASRTT = list()
disASRTT.vector = vector()
coreFlag = vector() # flag the probes all of AS changes are non-matching
for( pb in row.names(df.chDis)){
  idx = which(row.names(pbRTT)==pb)
  chptsChange = cpts(chptsMeanVar[[idx]])
  chptsChange = absorbChpts(chptsChange, tau)
  rttChange = tstp[chptsChange]
  aspathChange = time.trace[pb,][[1]][which(stat.asap[pb,]$disChange[[1]]>0)]
  d = minDis(aspathChange, rttChange)
  disASRTT.vector = append(disASRTT.vector, d)
  if (length(d)==0){
    coreFlag = append(coreFlag, -1)
  }else if (length(d[d<1800])==0){
    coreFlag = append(coreFlag, 1)
  }else{
    coreFlag = append(coreFlag, 0)
  }
  d = list(d)
  names(d) = pb
  disASRTT = append(disASRTT, d)
}
df.chDis[['DisASRTT']] = disASRTT
df.chDis[['coreFlag']] = coreFlag

#cdf graph for the AS path change and RTT distance
disASRTT.minute = as.double(disASRTT.vector)/60
cdf = ecdf(disASRTT.minute)
n = length(disASRTT.minute)
options(scipen = 999)
pdf('dis_as_rtt.pdf', width=6, height = 4)
plot(sort(disASRTT.minute), 1:n, main='', log='xy', type='s', xlab='Distance in Time (minute)', ylab='Number of AS Path Changes')
abline(v=30, col='blue', lty=2)
abline(h=cdf(30)*n, col='blue', lty=2)
lab = sprintf("%d AS path changes have an RTT change within 30min", cdf(30)*n)
mtext(lab, 3)
dev.off()

# load all the paths, large fie
temp = fromJSON(file='trace_path.json')
# for those have no matching AS path change, time index of path change and path
id = which(df.chDis$coreFlag==1)
pbs = row.names(df.chDis[id,])
pos = list()
pos.path = list()
pos.ippath = list()
for(pb in pbs){
  p = which(stat.asap[pb,]$disChange[[1]]>0)
  asp = list(temp[[pb]]$as_path_ap[as.vector(p)])
  names(asp) = pb
  pos.path = append(pos.path, asp)
  ipp = list(temp[[pb]]$ip_path[as.vector(p)])
  names(ipp) = pb
  pos.ippath = append(pos.ippath, ipp)
  p =  list(p)
  names(p) = pb
  pos = append(pos, p)
}
# all of these path changes are due to *

# we generalize the case there
# for each non-RTT-matching AS path change, we identify
# where in path the change happens, IP and ASN
# the probe it belongs
# the hop before change, IP and ASN
# ? the ip hop that cause AS path change
# check also matched AS path changes
dict = read.csv2('dic_ip2asn_merg.csv', header = F, stringsAsFactors = F)
iptoASN <- function(s, dict){
  asn = 0
  if(s == '*'){
    asn = -3
  }else if(s == 'TRUC'){
    asn = -4
  }else if(s=='DIFFHEAD'){
    asn = -5
  }else{
    asn = asn = dict[dict$V1==s,]$V2
  }
  return(asn)
}
nomatch.pb = vector()
nomatch.curASN = vector()
nomatch.prevASN = vector()
match.pb = vector()
match.curASN = vector()
match.prevASN = vector()
for (pb in row.names(df.chDis)){
  nmIdx = which(df.chDis[pb,]$DisASRTT[[1]]>1800)
  mIdx = which(df.chDis[pb,]$DisASRTT[[1]]<=1800)
  if(length(nmIdx)>0){
    IDpchg = which(stat.asap[pb,]$disChange[[1]]>0)
    IDpchg.nm = IDpchg[nmIdx]
    for(pid in IDpchg.nm){
      nomatch.pb = append(nomatch.pb, pb)
      cur = temp[[pb]]$as_path_ap[[pid]]
      prev = temp[[pb]]$as_path_ap[[pid-1]]
      s = cur[cur!=prev][1]
      if(is.na(s)){
        s= -1 # -1 for trucation eg. cur 12541  1273, prev 2541  1273  2914   226
      }
      nomatch.curASN = append(nomatch.curASN, s)
      ss = cur[cur == prev]
      ss = ss[!is.na(ss)]
      s = tail(ss, n=1)
      if (length(s)==0){
        # the case with total path lost
        #e.g. cur -3 prev 31669   174  2914   226 or the other way around
         s = -4 # for total loss
      }else if(is.na(s)){
        print('NA')
        print(cur)
        print(prev)
      }
      nomatch.prevASN = append(nomatch.prevASN, s)
    }
  }
  if(length(mIdx)>0){
    IDpchg = which(stat.asap[pb,]$disChange[[1]]>0)
    IDpchg.nm = IDpchg[mIdx]
    for(pid in IDpchg.nm){
      match.pb = append(match.pb, pb)
      cur = temp[[pb]]$as_path_ap[[pid]]
      prev = temp[[pb]]$as_path_ap[[pid-1]]
      s = cur[cur!=prev][1]
      if(is.na(s)){
        s= -1 # -1 for trucation eg. cur 12541  1273, prev 2541  1273  2914   226
      }
      match.curASN = append(match.curASN, s)
      ss = cur[cur == prev]
      ss = ss[!is.na(ss)]
      s = tail(ss, n=1)
      if (length(s)==0){
        # the case with total path lost
        #e.g. cur -3 prev 31669   174  2914   226 or the other way around
        s = -4 # for total loss
      }else if(is.na(s)){
        print('NA')
        print(cur)
        print(prev)
      }
      match.prevASN = append(match.prevASN, s)
    }
  }
}
df.nomatch = data.frame(pb = nomatch.pb,  curASN = nomatch.curASN, prevASN = nomatch.prevASN)
df.match = data.frame(pb = match.pb,  curASN = match.curASN, prevASN = match.prevASN)

# number of non-matching AS path change to each probe
df.tab = data.frame(table(as.character(nomatch.pb)), stringsAsFactors = F)
names(df.tab)[1] <- 'pb'

# probes with few such changes
p = df.tab[df.tab$Freq<=3,]$pb
fewNomatch = df.nomatch[df.nomatch$pb %in% p,]
nrow(fewNomatch)
# 41 entries, only 6 of them are due to AS path changes, others -3, -1
#c('383', '384', '960', '961', '966', '967')

# probes with a lot non matching changes
p = df.tab[df.tab$Freq>3,]$pb
manyNomatch = df.nomatch[df.nomatch$pb %in% p,]
nrow(manyNomatch)
#928 entries
df.tab[df.tab$Freq>3,]
table(manyNomatch$prevASN)
table(manyNomatch[manyNomatch$prev == 226,]$curASN)

# number of matching AS path change to each probe
df.Mtab = data.frame(table(as.character(match.pb)), stringsAsFactors = F)
names(df.Mtab)[1] <- 'pb'
table(df.match$prevASN)
table(df.match$curASN)

# how RTT change, increasing or lower, when the 90 matched changes happen
qpb = '23428'
plot(tstp[1100:1300], pbRTT[qpb,]$ts[1100:1300], type='l')
abline(v=time.trace[qpb,][[1]][which(stat.asap[qpb,]$disChange[[1]]>0)], col='red')
abline(v=tstp[cpts(chptsMeanVar[[qpb]])], lty=2)