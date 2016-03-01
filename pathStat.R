library(lattice)
library(ggplot2)
#load time traceroute timestamp
temp = fromJSON(file='trace_tsmp.json')
time.epc = lapply(temp, getlistAtt, 'time_epc')
time.epc  = lapply(time.epc, toEpoc)
time.trace = data.frame(row.names=as.integer(attributes(temp)$names), tstp=I(time.epc), stringsAsFactors = F)

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
pdf('countPriva_ip_AvgPerPb.pdf', width=4, height = 4)
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
pdf('posPriva_ip_byGroup.pdf', width = 4, height=4)
g = ggplot(pos.byCount, aes(x=pos, fill=as.factor(group)))
g = g + geom_histogram(breaks=seq(0,1,0.05), position = 'stack', alpha=0.8)
g = g + coord_cartesian(xlim = c(0,1))
g = g + scale_fill_discrete(name="Private IP # level")
g = g + xlab("Normalized Position")
g = g + ylab("Count")
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
pdf('posPriva_asmg_byProbe.pdf', width = 4, height=4)
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
pdf('posStar_ip.pdf', width = 6, height = 4)
g <- qplot(pos, geom="histogram", breaks=seq(0,1,0.05), xlab="Normalized position in IP path", ylab = "* Count")
g = g + theme(text=element_text(size=14))
print(g)
dev.off()

# number of stars in AS MG
pbs = row.names(path.stat[which(path.stat$starCount.ASMG > 10),])
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
pdf('posStar_asmg_byProbe.pdf', width = 4, height=4)
g = ggplot(pos.byProbe, aes(x=as.factor(round(posHop,0)), fill=as.factor(pbid)))
g = g + geom_histogram(position = 'stack', alpha=1)
#g = g + coord_cartesian(xlim = c(1,2))
g = g + scale_fill_discrete(name="Probe")
g = g + xlab("AS hop")
g = g + ylab("* Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()


#number and pos of unknown
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
pdf('posUnk_asmg_byProbe.pdf', width = 5, height=4)
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

# IP avg. path length
avg.len = round(as.numeric(unlist(path.stat$avgPathLen.IP)),0)
pdf('len_ip.pdf', width=4, height=4)
hist(avg.len, breaks=seq(9,27,1), xlab = 'Average IP path length', main='')
dev.off()
len.byCounty = data.frame(avg.len = avg.len, country = pbMeta[row.names(path.stat),]$country_code)
pdf('len_ip_byCountry.pdf', width = 8, height=6)
g = ggplot(len.byCounty, aes(x=avg.len))
g = g + geom_histogram(breaks=seq(9,27,1), position = 'stack', alpha=0.8)
g = g + coord_cartesian(xlim = c(9,27))
g = g + facet_wrap(~country)
g = g + scale_fill_discrete(name="Country Code")
g = g + xlab("Average IP path length")
g = g + ylab("Probe Count")
#g = g + theme(legend.position='top')
g = g + theme(text=element_text(size=14))
print(g)
dev.off()






