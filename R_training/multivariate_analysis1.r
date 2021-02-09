#!/usr/bin/env Rscript
library(ade4)

## input data: a discrete numeric data table, with samples as rows and variables as columns
# tables in other formats can be coerced to the right format with data.matrix()
amr = ... # your AMR gene pres/abs table (1 or 0 values)
vfdb = ... # your virulence gene pres/abs table (1 or 0 values), same number of rows as AMR table
amr_vf = cbind(amr, vfdb) # combined table!

# categorical data (vector in factor format) that can be related to the above
# data vectors in other formats can be coerced to the right format with as.factor()
pathotype = ... # factor vector, the same length as number of rows of AMR table

## a usual way of looking at data is to cluster your data
# distance matrix of rows: to see how your samples are related in their AMR and VF gene profiles
amr.rowdist = dist(amr, method = "euclidean")
plot(hclust(amr.rowdist))
# distance matrix of columns: to see how AMR and VF gened are related in their occurrence profiles among your samples 
amr.coldist = dist(t(amr), method = "euclidean")
plot(hclust(amr.coldist))
# you could visulatise these cluterings along with the heatmp of your data
heatmap(amr, scale="none")
# but an issue is that with a clustering approach you cannot know where the similarity among your samples/genes comes from 

## so instead you may want to use a multivariate data analyis approach
# this is a descriptive appraoch, which is powerful in athat it allows you to explore your data and to find where the detail of the signal comes from

# here with discrete count data, we better use Correspondance Analysis (CoA)
amr.coa = dudi.coa(amr, scannf = FALSE, nf = 6)
# NB: nf specifies the number of planes of the multi-dimensional projection that you store in your dudi object; it does not affect the queality of the results, but from there you only be able to explore the axis <= nf, so better select nf high
# you can choose nf = ncol(amr)-1 as the maximum
# go through the various planes of the projection
scatter(dudi.amr, xax=1, yax=2)
scatter(dudi.amr, xax=2, yax=3)
scatter(dudi.amr, xax=3, yax=4)

# for ease of reading, you can try a dual plot with rows/samples on the left and columns/varaibles on the right:
for (i in 1:5){
  # go through th various planes of the projection, using a for loop!
  j = i+1
  par(mfrow = c(1,2))
  s.arrow(dudi.amr$co, xax=i, yax=j, clab = 0.6)
  s.label(dudi.amr$li, xax=i, yax=j, clab = 0.6)
  par(mfrow = c(1,1))
}

## going through the dimensions of the prjections you may realise that the variance (spread of you sample points) in some of the axis is all due to the separation of a few samples with very specific patterns i.e. outliers vs. the rest of your samples that remain stuck together near the plane origin
# for instance, a sample with a unique profile presenting genes occurring only in this sample will separate very strongly - but it's a bit trivial information that should dealt with separately
outlier = 'outliersample' # the row name of that outlier, as should appear on the plots above
row.outlier = which(rownames(amr.noout)==outlier) # the corresponding row number
amr.noout = amr[-row.outlier,]
amr.noout.coa = dudi.coa(amr.noout, scannf = FALSE, nf = 6)
# ...

# or you have genes that always occur together, which is interesting but gives too much strength to that block pattern, which should be very obvious and not require multivariate analysis to be identified really - again this could better be studied on its own
blockpatern_genes = c('gene1', 'gene2', 'gene3') # the column names of those genes
col.blockgenes = which(colnames(amr.noout) %in% blockpatern_genes) # the corresponding column numbers
amr.noblock = amr[-col.blockgenes,]
amr.noblock.coa = dudi.coa(amr.noblock, scannf = FALSE, nf = 6)
# ...
amr.block = amr[col.blockgenes,]
amr.block.coa = dudi.coa(amr.block, scannf = FALSE, nf = 6)
# ...
# you can also try (advanced):
blockpatern_samples = c('sample1', 'sample2', 'sample3') # the row name of samples in which this block of genes occur
# you can formally find those samples with:
blockpatern_samples = rownames(amr)[which(apply(as.logical(amr.block), 1, all))]
# separate samples as being with that block pattern or not
blockornot_samples = as.factor(ifelse(rownames(amr), 'withblock', 'noblock'))
s.arrow(dudi.amr$co, clab = 0.6, facets=blockornot_samples)

## plotting elipses of categorical data on top of you multivariate plot
s.class(dudi.amr$li, fac=pathotype)
# with colours
patho_colors = rainbow()[1:length(levels(pathotype))]
s.class(dudi.amr$li, fac=pathotype, col=patho_colors)

for (i in 1:5){
  # go through th various planes of the projection, using a for loop!
  j = i+1
  s.class(dudi.amr$li, xax=i, yax=j, fac=pathotype, col=patho_colors)
}

# think of varying the factors that are projected on your data

# also you can use different underlying varaibles to group your samples 
# looking at your virulence factor gene abs/pres table
vf.coa = dudi.coa(vf, scannf = FALSE, nf = 12)
# looking at AMR and virulence factor gene abs/pres together!
amr_vf.coa = dudi.coa(amr_vf, scannf = FALSE, nf = 12)
# this could reveal correlated patterns!
# check with:
s.arrow(dudi.amr_vf$co, clab = 0.6)
# or with simple clustering:
plot(hclust(dist(t(amr_vf), method = "euclidean")))

# for other type of data:
# for continuous data, better use principla Component Anlaysis (PCA); use dudi.pca()
# with PCA, it is worth using the options: scale=TRUE, centre=TRUE
# but if you believe that the varying ranges or scales of your data makes sense in terms of weighting, you could turn those parameters to FLASE and see what you get.
