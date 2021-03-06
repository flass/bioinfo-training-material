# Making trees!

## 1. Installing programs

### with Anaconda
```sh
conda install -c bioconda clustalo
conda install -c bioconda raxml-ng
conda install -c bioconda snp-sites
conda install -c bioconda cd-hit
```
### or downloading separately

http://www.atgc-montpellier.fr/fastme/binaries.php  
http://doua.prabi.fr/software/seaview  
http://sanger-pathogens.github.io/snp-sites/  

You can find a nice tutorial on how to use RAxML-NG on its wiki page: https://github.com/amkozlov/raxml-ng/wiki.


## 2. Building 16S rRNA gene tree

### Search NCBI for sequences

Search `Vibrio` in the NCBI Taxonomy database at https://www.ncbi.nlm.nih.gov/Taxonomy.  
(results at https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=662&lvl=3&lin=f&keep=1&srchmode=1&unlock )

Then use the links on the right to get to the nucleotide sequence for this taxon.

You can also search directly the Nucleotide database using this search term: `txid666[Organism:exp]`.

Query all Vibrio spp. 16S genes in NCBI Nuleotide using the filters on the left to select rRNA molecules.  
(results at https://www.ncbi.nlm.nih.gov/nuccore/?term=txid662[Organism:exp]%20AND%20biomol_rrna[PROP] )

Combine search terms (or filters) to select only sequences from RefSeq collection and filter then based on sequence lengths:  
`txid662[Organism:exp] AND biomol_rrna[PROP] AND refseq[filter] AND ("1000"[SLEN] : "10000"[SLEN])` 

Download the sequences using the **Send to** button; name the file `Vibrio_spp_16S.fasta`.

### Align the sequences using Clustal Omega

#### using the command line
```sh
#  print the usage manual
clustalo -h
# align the 16S sequences using 4 CPUs 
clustalo -i Vibrio_spp_16S.fasta -o Vibrio_spp_16S.aln --threads 4
```

#### using Seaview integrated tools
Select all sequences with `Edit > Select all` then Algn with `Align > Align all`.


### Look at the alignment!

Using Seaview

```sh
# can be launched from the command line! useful when connected to a server (requires connection with `ssh -X` or `ssh -Y`)
seaview Vibrio_spp_16S.aln &
```

Some sequences do not seem homologous or are the inverted complement of the sequence and won't align; tou may have to remove these sequences from the alignment by selecting them on the left and using `Edit > Delete sequence(s)`.
A copy excluding these sequences is saved in the file `Vibrio_spp_16S.excludeInvertedSeqs.fasta`.

You may then want to re-align the restricted set of sequences:
```sh
clustalo -i Vibrio_spp_16S.excludeInvertedSeqs.fasta -o Vibrio_spp_16S.excludeInvertedSeqs.aln --threads 4
```

### Build a tree with RAxML-NG
```sh
# check the alignment is in the correct format and not corrupted
raxml-ng --check --msa Vibrio_spp_16S.excludeInvertedSeqs.aln --model GTR+G4

# there are unauthorized characters in the sequence labels!
# produce clean labels
sed -e 's/ 16S.*//g' Vibrio_spp_16S.excludeInvertedSeqs.aln | sed -e 's/ /_/g' > Vibrio_spp_16S.excludeInvertedSeqs.cleannames.aln

# check the alignment is now in the correct format
raxml-ng --check --msa Vibrio_spp_16S.excludeInvertedSeqs.cleannames.aln --model GTR+G4

# search for maximum-likelhood tree
raxml-ng --search --msa Vibrio_spp_16S.excludeInvertedSeqs.cleannames.aln.raxml.reduced.phy --model GTR+G4 --tree pars{1} --threads 4
# produce the ML tree file Vibrio_spp_16S.aln.raxml.reduced.phy.raxml.bestTree

# run bootstrap analysis = infer trees from many (here 10) subsamples of the alignment data (random picking the column of the alignment)
raxml-ng --bootstrap --msa Vibrio_spp_16S.excludeInvertedSeqs.cleannames.aln.raxml.reduced.phy --model GTR+G4 --threads 4 --bs-trees 10
# produce the bootstrap tree file Vibrio_spp_16S.aln.raxml.reduced.phy.raxml.bootstraps

# map the bootstrap as supports to the main ML tree branches
# branch supports = frequency of observing the ML tree's splits in the sample of bootstrap trees
raxml-ng --support --msa Vibrio_spp_16S.excludeInvertedSeqs.cleannames.aln.raxml.reduced.phy --model GTR+G4 --threads 4 \
 --tree Vibrio_spp_16S.excludeInvertedSeqs.cleannames.aln.raxml.reduced.phy.raxml.bestTree \
 --bs-trees Vibrio_spp_16S.excludeInvertedSeqs.cleannames.aln.raxml.reduced.phy.raxml.bootstraps
# produce the ML tree file with branch supports

raxml-ng --all --msa Vibrio_spp_16S.excludeInvertedSeqs.cleannames.aln.raxml.reduced.phy.raxml.rba --model GTR+G4 --tree pars{1} --bs-trees 10  --threads 4
# do all this at once
```

### Cluster sequences into OTUs with CD-HIT

Building phylogenies is often used as a way to classify an organism of unknown taxonomic identity. However, a phylogeny built on 16S rDNA sequences may provide only an approximate link to taxonomic classification because of the instable nature of this classification (it is modified regularly by scientists based on evolving evidence) and its potential disagreement with results of phylogenetic investigations (bacteruial taxa are often found to be not monophyletic in trees). This is notably due to the possibility of horizontal transfer of the 16S gene among taxa, but also due to the uneven breath of diversity covered by bacterial species. For this reason, it may be more practical to reason in terms of Operational Taxonomic Units (OTUs) when attempting to assign a taxonomic identity to a sequence from an unknown organism.
OTUs are simply groups of organisms based on the clustering of sequences of a marker gene such as the 16S rDNA at a given cutoff, often 95% identity for the 16S.
These OTUs then can be robustly referred to without having to worry about the volatility of the classification.

We will thus clster the 16S sequences at hand to establish a reference set of OTUs, to which we will compare an unknown sequence obtained from an organism we ssuspect to be a vibrio.

```sh
# produce clean labels
sed -e 's/ 16S.*//g' Vibrio_spp_16S.excludeInvertedSeqs.fasta | sed -e 's/ /_/g' > Vibrio_spp_16S.excludeInvertedSeqs.cleannames.fasta

# cluster sequences at 95% similarity cutoff
cd-hit -i Vibrio_spp_16S.excludeInvertedSeqs.cleannames.fasta -o Vibrio_spp_16S.excludeInvertedSeqs.cleannames.cd-hit.clust -c 0.95

# add the unknown sequence to the file containing the representatives of each cluster
cat unknown_sequence.fasta Vibrio_spp_16S.excludeInvertedSeqs.cleannames.cd-hit.clust > Vibrio_spp_16S.excludeInvertedSeqs.cleannames.cd-hit.clust.withunknown

# align those sequences
clustalo -i Vibrio_spp_16S.excludeInvertedSeqs.cleannames.cd-hit.clust.withunknown -o Vibrio_spp_16S.excludeInvertedSeqs.cleannames.cd-hit.clust.withunknown.aln

# compute a tree feturing the unknown sequence in the context of the reference OTUs
raxml-ng --all --msa Vibrio_spp_16S.excludeInvertedSeqs.cleannames.cd-hit.clust.withunknown.aln --model GTR+G4 --tree pars{1} --bs-trees 10  --threads 4
```

## 3. Big whole-genome alignment and tree

We'll try and build a tree from a whole-genome alignment, based on a subset of data from the study by Weill et al. (Nature, 2018) on the Yemen cholera epidemics: https://www.nature.com/articles/s41586-018-0818-3.  

The alignment was obtained by mapping each set of sequencing reads to the reference genome of strain N16961 (assembly [GCF_900205735.1](https://www.ncbi.nlm.nih.gov/assembly/GCF_900205735.1) with SMALT (this will be covered by another tutorial!).

The whole-genome alignment is too big, with more than 4M sites (alignment collumns)! This would take unnecessarily long to tree-building process.

To tackle this, let's reduce the big whole-genome alignment to only the variable positions = a SNP alignment using `snp-sites`.
```sh
snp-sites -o 50yemen2018.pseudo_genome.snp.aln 50yemen2018.pseudo_genome.aln 
```

The original big alignment is not provided in this repository for the sake of file space, but the SNP alignment is provided in its compressed version; it can be unconpressed with the commmand:
```sh
gzip -d 50yemen2018.pseudo_genome.snp.aln.gz
```


Look at the alignment with seaview
```sh
seaview 50yemen2018.pseudo_genome.snp.aln
```
Now let's get started on the tree:
```sh
# check the alignment is in the correct format and not corrupted
raxml-ng --check --msa 50yemen2018.pseudo_genome.snp.aln
```

We have to specify a model!
We can use a GTR model, with 4 categories of sites with different substitution rates, and with the ascertainement bias correction;
for the latter we can use the simplest (Lewis') ascertainement bias correction:
```sh
raxml-ng --check --msa 50yemen2018.pseudo_genome.snp.aln --model GTR+G4+ASC_LEWIS
```

Or we can use the most accurate (Stamatakis') ascertainement bias correction; for this, we need to compute the number of invariant sites (for each base type) that were removed from the alignment to give it to the ASC_STAM correction.
We can just compute it from the first sequence otherwise it is too long to load in `R`; so let's extract the first sequence into its own file:
```sh
# check where the second sequence starts in the fasta alignment file
grep -n '>' 50yemen2018.pseudo_genome.aln | head -n2
#1:>CNRVC000043
#67228:>CNRVC000085
head -n 67227 50yemen2018.pseudo_genome.aln > 50yemen2018.pseudo_genome.aln.firstseq

grep -n '>' 50yemen2018.pseudo_genome.snp.aln | head -n2
#1:>CNRVC000043
#3:>CNRVC000085
head -n 2 50yemen2018.pseudo_genome.snp.aln > 50yemen2018pseudo_genome.snp.aln.firstseq
```

Use R to compute the number of invariant sites (for each base type):
```R
library(ape)
ali.full = read.dna('50yemen2018.pseudo_genome.aln.firstseq', format='fasta')
ali.snp = read.dna('50yemen2018.pseudo_genome.snp.aln.firstseq', format='fasta')
base.freq(ali.full, freq=T)
base.freq(ali.snp, freq=T)
base.freq(ali.full, freq=T) - base.freq(ali.snp, freq=T)
#      a       c       g       t 
#1033912  936904  944544 1044465 
quit(save='no')
```

Check the alignment:
```sh
raxml-ng --check --msa 50yemen2018.pseudo_genome.snp.aln.first50seqs --model GTR+G4+ASC_STAM{1033912/936904/944544/1044465}
```
This produced the reduced alignment file in PHYLIP format


Compute a distance-based tree with FastME using this PHYLIP format SNP alignment:
```sh
fastme 
```
Use the interactive prompt for `fastme` (commands are indicated below, one per line):
- first enter the name of the input file
- `I` -> input type: `D` -> DNA alignment;
- `E` -> which model?: `P` -> P-distance = SNP distance;
- `B` -> run bootstrapanalysis: `10` -> 10 replicates;
- `Y` -> all is good, go!

```
50yemen2018.pseudo_genome.snp.aln.first50seqs.raxml.reduced.phy
I
D
E
P
B
10
Y
```

This can also be done through the command line
```sh
fastme -i 50yemen2018.pseudo_genome.snp.aln.first50seqs.raxml.reduced.phy -d p -b 10
# preferably use multiple threads - if yo have several CPU cores on your computer!
fastme -i 50yemen2018.pseudo_genome.snp.aln.first50seqs.raxml.reduced.phy -d p -b 10 -T 4
```
Compute maximum-likelihood tree with bootstrap support with RAxML-NG
```sh
raxml-ng --all --msa 50yemen2018.pseudo_genome.snp.aln.first50seqs.raxml.reduced.phy --model GTR+G4 --tree pars{1} --bs-trees 10  --threads 4
```


### Plot the tree in front of metadata with R
```R
library(phytools)
vcmetadata = read.table('50yemen2018.pseudo_genome.first50seqs.metadata.tsv', comment.char='', sep='\t', header=T,quote='')
vctree = read.tree('50yemen2018.pseudo_genome.snp.aln.first50seqs.raxml.reduced.phy.raxml.support')
rownames(vcmetadata) = vcmetadata[,'Isolate.name']
vcmetadata[,'outbreak.year'] = vcmetadata[,'Isolation.year'] - min(vcmetadata[,'Isolation.year'])
phylo.heatmap(vctree, data.matrix(vcmetadata[, c('Country', 'outbreak.year')]))
quit(save='no')
```

