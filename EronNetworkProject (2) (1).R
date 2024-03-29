# Look at the data
set.seed(123)

## Load package
library(igraph)
# read data in
dat = read.delim("C:/Users/ANA GABRIELA/Downloads/sent-emails-long.txt", colClasses = 'character')
dat
names(dat) = c('sender', 'date', 'reciever', 'email_id')

# explore
head(dat)
summary(dat)

# leave only those connections that are employees
dat = dat[dat$reciever %in% unique(dat$sender),]
dat = dat[dat$sender %in% unique(dat$reciever),]
# length(union(dat$sender,dat$reciever))
# nrow(dat)

# add year month column
dat$yearm = as.numeric(substr(gsub("\\-","",dat$date),1,6))
#```

#```{r}
# necessary packages
install.packages("ndtv", "networkD3", "igraph", dependencies=T)
install.packages('animation')

library(igraph)

# edges
links = dat[,c("sender","reciever", "yearm")]
links = links[order(links$yearm,links$sender,links$reciever),]
links = links[links$sender != links$reciever,] # remove loops

i <- sapply(links, is.factor)
links[i] <- lapply(links[i], as.character)

# nodes
nodes.dyn = as.data.frame(table(unlist(links[,1:2])))
names(nodes.dyn) = c("name","freq")
vertices = base::union(links$sender,links$reciever)
nodes.dyn = nodes.dyn[nodes.dyn$name %in% vertices,]

# net
net = graph.data.frame(links[,1:2], nodes.dyn, directed=F)

# plot network
l = layout.fruchterman.reingold(net)
plot(net,
     rescale = T,
     layout = l,
     vertex.size = 10,
     main = 'Enron network over the period 1998-11 to 2001-04\nbased on sent emails',
     vertex.label.cex	= 0.6) # font size

# add colors
# The vertex and edge betweenness are (roughly) defined by the number of 
# geodesics (shortest paths) going through a vertex or an edge.
# http://www.inside-r.org/packages/cran/igraph/docs/betweenness

V(net)$community <- igraph::betweenness(net)
V(net)$group <- edge.betweenness.community(net)$membership

plot(net,
     vertex.color = V(net)$community,
     vertex.size = log(nodes.dyn$freq)*3,
     mark.groups = V(net)$group,
     rescale = T,
     layout = l,
     vertex.size = 10,
     vertex.label.cex	= 0.6, # font size
     xlab = 'Size indicates of connections.\nColor is a grouping by edge betweenness\n
            Background indicates the biggest tightly connected group by edgebetweenness '
) 

##```
###############################################################
# Interactive graphs

###```{r}
#install.packages("networkD3")
#install.packages('ndtv')
library(networkD3)

data(MisLinks)
data(MisNodes)

linksd3 = links[!duplicated(links[,1]) | !duplicated(links[,2]),] 

nodesd3 = as.data.frame(table(unlist(linksd3[,1:2])))
names(nodesd3) = c("name","freq")
nodesd3$group = V(net)$community
nodesd3 = nodesd3[order(nodesd3$name),]

linksd3 = linksd3[order(linksd3$sender),]


forceNetwork(Links = linksd3, Nodes = nodesd3,
             Source = "sender", Target = "reciever",
             NodeID = "name", #Value = '
             Group = "group", opacity = 0.8, bounded = T, fontSize = 20)
#```

# Dynamic social networks

#```{r, fig.width=8}
# Dynamic networks
library(ndtv)
library(animation)
library(network)

# check whether animation got the path for ImageMagic right
ani.options(convert="C:\\Program Files\\ImageMagick-7.0.1-Q16\\convert.exe") 
#ani.options("convert")

# prepare the time points
links.dyn = links[!duplicated(links[,1]),] 
links.dyn$onset = sapply(links.dyn$yearm, function(x) which(unique(links.dyn[,3]) == x)-1)

nodes = links.dyn[,1]
nodes = base::union(nodes,links.dyn[,2])

net2 <- network(links.dyn[,1:2], 
                #vertex.attr=nodes, 
                matrix.type="edgelist", 
                loops=F, multiple=F, ignore.eval = F)

par(mfrow = c(1,2))
plot(net2, main = "Enron network in the last period")

terminus = length(unique(links.dyn$yearm)) # point at which nodes and edges dissipate
onset.es = links.dyn$onset # list of time points at which edges appear


# vertices
vs <- data.frame(onset=0, 
                 terminus=terminus, 
                 vertex.id=1:length(nodes))
# edges
es <- data.frame(onset=onset.es, 
                 terminus=terminus, 
                 head=as.matrix(net2, matrix.type="edgelist")[,1],
                 tail=as.matrix(net2, matrix.type="edgelist")[,2])

net2.dyn <- networkDynamic(base.net=net2, edge.spells=es, vertex.spells=vs)

plot( network.extract(net2.dyn, at=0) ,  main = 'Enron Network in the  starting period')
par(mfrow = c(1,1))


### Enron network in strips

#```{r, fig.width=8}
filmstrip(net2.dyn, displaylabels=F, mfrow=c(2, 5),
          slice.par=list(start=0, end=terminus, interval=3, 
                         aggregate.dur=3, rule='any'))


### Enron Network over time
#The are several ways to display a social network over time. In this instance we keep the edges until the end instead of terminating tham if there was no contact in a given period.
#```{r}
compute.animation(net2.dyn, animation.mode = "kamadakawai",
                  slice.par=list(start=0, end=terminus, interval=2, 
                                 aggregate.dur=2, rule='any'))

render.d3movie(net2.dyn,displaylabels=TRUE, output.mode = 'htmlWidget') 
#```
#```{r, fig.height=9}
# Time Prism
compute.animation(net2.dyn)

timePrism(net2.dyn,at=c(0,5,10,15,20,terminus-1),
          displaylabels=F,planes=T,
          label.cex=0.5)
#```

#It is evident that the Enron network became hiighly grouped as its aproached the scandal point closer and closer. Below is the graph of the number of new edges that appeared in a given period. 

#```{r}
# stats
install.packages('tsna')
library(tsna)

plot(tEdgeFormation(net2.dyn), main = "Edge formation by period\nDate range: 1998-11->2001-04 by month", 
     xlab = "Count of edges", ylab = "Time period")

# clique.census(net2, mode = "digraph")

#```

#It would be helpful to know the number of cliques (groups) in the network. Unfortunately, here is what the documentation for the R package `sna` says.

#> The computational cost of calculating cliques grows very sharply in size and network density. It is possible that the expected completion time for your calculation may exceed your life expectancy (and those of subsequent generations).

