### FUCNTIONS
# get the list attribute content by name
getlistAtt <- function(l, name){
  return(as.numeric(unlist(l[name])))
}

# load from JSON file path stat file 
loadPathStat <- function(fn, att){
  temp <- fromJSON(file=fn)
  stat.path = data.frame(row.names=as.integer(attributes(temp)$names))
  for(str in att){
    att.stat = lapply(temp, getlistAtt, str)
    stat.path[[str]] = att.stat
  }
  return(stat.path)
}

# convert epic time interger to epic time data
toEpoc <- function(v){
  return(as.POSIXct(as.integer(unlist(v)), tz='UTC', origin='1970-01-01'))
}


# count the number of times that change distance is bigger than zero
countChange <- function(v){
  v = as.numeric(unlist(v))
  return(length(which(unlist(v)>0)))
}

# calculate the average change distance
avgChange <- function(v){
  v = as.numeric(unlist(v))
  v = v[which(v>0)]
  return(mean(v))
}

# for element in a, calculate the distance to the cloest element in b
minDis <- function(a, b){
  dis = vector()
  for (t in a){
    dis = append(dis, min(abs(as.numeric(b-t))))
  }
  return(dis)
}
