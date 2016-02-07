#Aligning and handling invalid value
*alignRTT.py* handles both tasks.
The methods adopted here below described.
##Aligning timestamp
For a single probe, the moments at which its measurements are performed at not necessary evenly placed.
This might due to the queuing of measurement tasks, or entire miss of measurement results at this probe round.
For different probes, though of same probe interval, their probe round are not synchronized.
Therefore, measurement traces need to be aligned so that they can be compared to each other.
The nature of alignment is to displace a measurement value in time and assume it happens at the same moment as other values.
In order to minimize the distortion that such operation might introduce, one has to minimize the timestamp displacement needed.
Our approach is to use *k-means* clustering algorithm to automatically form cluster of timestamps that are close to each other.
Then use the centroid, i.e. the average, of each cluster as the new timestamp for all the member timestamps.
By definition, *k-means* algorithm minimizes the total/avaerge distance from each member to its centroids, i.e. timestamp displacement in our case.
However, there is no guarantee that the algorithm converges at the global minimum.
The achieved final results depends heavily on the initial centroids.
We set initial centroids to the timestamps of the longest measurement trace.
It turned out that with this heuristic, the resulted distortion is all the time smaller (empiric observation, not necessarily always true in a theoretical way) than randomly selected centroids.
Such resulted 'aligned' timestamps have a mean interval of 240.00 sec, which corresponds well to the configured value, and the standard deviation is 1.97 sec.
The mean time displacement of all measurements is 55.01 sec, much smaller than the interval, and the maximum displacement is bordered by a value around 120 sec, which is the half of the configured interval.

##Handling invalid values
There are two type of invalid values.
One is the holes results by alignment, as not all the traces are as as the longest one.
Second is invalid values mentioned in *cleaning.md*, caused by timeout, system error etc.
These cases might take actual values in implementation, such as 0 for holes and -1 for timeouts, or NA for all cases.
Such values can be easily disregarded when calculating certain statistic measures, such as mean, std, etc.
However, the existence of such values can be problematic when describing or comparing measurement in time series form.
Since traces have already been cleaned, such cases are pretty rare in this final stage of processing, we decided to replace these invalid values with valid ones and still very limited impact can be expected.
Assuming that RTT measurement values have temporal locality, i.e. measurements effected close in time shall have little difference, we assign timestamps with invalid values with valid ones that is the closest (consider both directions) in time. 
