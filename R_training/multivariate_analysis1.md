# Introduction to Multivariate analysis with `ade4` in `R`

## Input data: 
You need a discrete numeric data table, with samples as rows and variables as columns; tables in other formats can be coerced to the right format with `data.matrix()`.
```r
# your AMR gene pres/abs table (1 or 0 values)
amr = read.table(yourAMRtablefile)
# your virulence gene pres/abs table (1 or 0 values), same number of rows as AMR table
vfdb = read.table(yourVFtablefile) 
amr_vf = cbind(amr, vfdb) # combined table!
# categorical data (vector in factor format) that can be related to the above
# data vectors in other formats can be coerced to the right format with as.factor()
pathotype = as.factor(readLines(yourpathotypefile)) # factor vector, the same length as number of rows of AMR table
```

## the simple way: clustering 
An usual way of looking at data is to cluster your data, by either rows or columns.
Distance matrix of rows: to see how your samples are related in their AMR and VF gene profiles
```r
amr.rowdist = dist(amr, method = "euclidean")
plot(hclust(amr.rowdist))
```
Distance matrix of columns: to see how AMR and VF gened are related in their occurrence profiles among your samples 
```r
amr.coldist = dist(t(amr), method = "euclidean")
plot(hclust(amr.coldist))
```
You could visulatise these cluterings along with the heatmp of your data
```r
heatmap(amr, scale="none")
```
it's all well and good but an issue is that with a clustering approach you cannot know where the similarity among your samples/genes comes from. By using distances as the information to build your clustering, you're loosing information: you don't knw because of similarity in profiles of which genes some samples may be clustered together. Aslo, three samples may be all as similar to each other based on the distance, but this may be due to similaruty in _different_ sets of genes.

## the finer way: multivariate data analysis
So instead of simple clustering, you may want to use a multivariate data analyis approach.
This is a descriptive approach, which is powerful in athat it allows you to explore your data and to find where the detail of the signal comes from.
You should consider that your data can be represented into points sitting in a multidimentional space, with each variable (column) in you table an orthogonal dimension. The coordinate system in this multi-dimensional space folows the values taken by your variables for each of your samples. the fact the variables are thought orthogonal means that they should be independent!
So your samples are data points in that orthoganal variable space, forming a cloud. Looking at this cloud may not be easy because:
- there are more than 3 dimensions and our eyes can't deal with that; so you need to make a porjection onto a limited ammount of dimensions that we can handle, typically 2.
- you then need to find the right angle to project on, so that you see your data most clearly, typically looking to separate/spread the data points the best you can

To illustrate this, imagine a view of [a galaxy from outside](illustrations/1920px-Andromeda_Galaxy_(with_h-alpha).jpg); your samples here are stars, and the vraiables are actual space corrdinates. If looking at the galaxy [from the side](illustrations/potw1305a.jpg), you see the stars spread in length, but not much in height; it's not optimal. maybe your galaxy is an elongated elisis, not a circle. So let's say before you looked at it from the long side. Now, you can look from the short side: it's even worse; you see the starts cramed in height and quite packed in a short width too. And what about time, the fourth dimension of spacetime? If you'd consider it, there may be some variations among all your stars (maybe because of mass variations? don't ask me I'm no physicist), but the variation in their time coordinates would be so minute with respect to the other space variables, that you would see absolutely nothing by projecting your stars data onto the time axis. Thus the best projection of your star data is on the galactic plane i.e. seen [from above](illustrations/milkywayfromtop.png).

Multivariate data analyis methods such as correspondance analysis (CoA) or principal component analysis (PCA) allow you to opperate an optimal rotation of your multivariate data space into a projection, so that the variance of your sample points i.e. their spread is maximised on the first axes of the projection. The axes of this projection space are still orthogonal, they're just rotated from the initial coordinate base; new axes are ranked according to which captures the most variance, as indicated by their _eigenvalues_. 

To do such things, we'll now use the package `ade4`, but there are others that provide simialr function
```r
library(ade4)
```
Here we have discrete count data, so we'd better use Correspondance Analysis (CoA)
```r
ndim = ncol(amr) - 1
amr.coa = dudi.coa(amr, scannf = FALSE, nf = ndim)
```
NB: `nf` specifies the number of planes of the multi-dimensional projection that you store in your dudi object; it does not affect the queality of the results, but from there you only be able to explore the axis <= `nf`, so better select `nf` high. You can choose `nf = ncol(amr)-1` as the maximum.
You can explore your data by going through the various planes of the projection.
```r
scatter(dudi.amr, xax=1, yax=2)
scatter(dudi.amr, xax=2, yax=3)
scatter(dudi.amr, xax=3, yax=4)
```

For ease of reading, you can try a dual plot with rows/samples on the left and columns/varaibles on the right:
```r
for (i in 1:(ncol(dudi.amr$li)-1)){
  # go through th various planes of the projection, using a for loop!
  j = i+1
  par(mfrow = c(1,2))
  s.arrow(dudi.amr$co, xax=i, yax=j, clab = 0.6)
  s.label(dudi.amr$li, xax=i, yax=j, clab = 0.6)
  par(mfrow = c(1,1))
}
```

## Exploring your data using the various axis/planes of your projection

Going through the dimensions of the projections, you may realise that the variance (spread of you sample points) in some of the axes is all due to the separation of a few samples with very specific patterns i.e. outliers vs. the rest of your samples that remain stuck together near the plane origin.
For instance, a sample with a unique profile presenting genes occurring only in this sample will separate very strongly - but it's a bit of a trivial information that should be dealt with separately.
```r
outlier = 'outliersample' # the row name of that outlier, as should appear on the plots above
row.outlier = which(rownames(amr.noout)==outlier) # the corresponding row number
amr.noout = amr[-row.outlier,]
amr.noout.coa = dudi.coa(amr.noout, scannf = FALSE, nf = ndim)
# ...
```
Or you have genes that always occur together, which is interesting but gives too much strength to that block pattern, which should be very obvious and not require multivariate analysis to be identified really - again this could better be studied on its own
```r
blockpatern_genes = c('gene1', 'gene2', 'gene3') # the column names of those genes
col.blockgenes = which(colnames(amr.noout) %in% blockpatern_genes) # the corresponding column numbers
amr.noblock = amr[-col.blockgenes,]
amr.noblock.coa = dudi.coa(amr.noblock, scannf = FALSE, nf = ndim)
# ...
amr.block = amr[col.blockgenes,]
amr.block.coa = dudi.coa(amr.block, scannf = FALSE, nf = ndim)
# ...
```
You can also try (advanced):
```r
blockpatern_samples = c('sample1', 'sample2', 'sample3') # the row name of samples in which this block of genes occur
# you can formally find those samples with:
blockpatern_samples = rownames(amr)[which(apply(as.logical(amr.block), 1, all))]
# separate samples as being with that block pattern or not
blockornot_samples = as.factor(ifelse(rownames(amr), 'withblock', 'noblock'))
s.arrow(dudi.amr$co, clab = 0.6, facets=blockornot_samples)
```

## Plotting elipses of categorical data on top of you multivariate plot
you can now try and give more sense to you data, by overlaying external data - typically categorical data - on top of your projection plots.
```r
s.class(dudi.amr$li, fac=pathotype)
# with colours
patho_colors = rainbow(length(levels(pathotype)))
s.class(dudi.amr$li, fac=pathotype, col=patho_colors)

for (i in 1:(ncol(dudi.amr$li)-1)){
  # go through th various planes of the projection, using a for loop!
  j = i+1
  s.class(dudi.amr$li, xax=i, yax=j, fac=pathotype, col=patho_colors)
}
```

Now you know how to explore and play with your data!
You can try and think of varying the factors that are projected on your data; you can also use different underlying varaibles to group your samples. For instance:
```r
# looking at your virulence factor gene abs/pres table
ndimvf = ncol(vf) - 1
vf.coa = dudi.coa(vf, scannf = FALSE, nf = ndimvf)
# looking at AMR and virulence factor gene abs/pres together!
amr_vf.coa = dudi.coa(amr_vf, scannf = FALSE, nf = ndimvf)
# this could reveal correlated patterns!
# check with:
s.arrow(dudi.amr_vf$co, clab = 0.6)
# or with simple clustering:
plot(hclust(dist(t(amr_vf), method = "euclidean")))
```
## For other type of data:
For continuous data, better use Principal Component Anlaysis (PCA); for this use `dudi.pca()`.  
With PCA, it is worth using the options: `scale=TRUE, centre=TRUE`, normalise and re-centre the range of values of your variable, so that vriation from each your variables are considered having an equal weight in the multi-dimensional space.
This can be quite relevant for phenotype data, for instance: if you put together morphometric measurements of different body/plant/cell parts, while they share the same metric (e.g. mm), they will likely not share the same scale. However, who is to judge that 1 cm variation in the jaw width is not as important as 10cm variation in the femur length? By normalising and recentring i.e. transforming values so that they fit to a *N*(0,1) gaussian distribution, you will give each variable an equal importance.
But if you believe that the varying scales or ranges of your data make sense in terms of weighting, you could keep them as is by turning the `scale` and `centre` parameters to `FALSE`, respectively, and see what you get.
