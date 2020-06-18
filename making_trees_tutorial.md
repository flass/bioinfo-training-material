# Making trees!

## 1. Installing programs

### with Anaconda
```sh
conda install -c bioconda clustalo
conda install -c bioconda raxml-ng
```
### or downloading separately

http://www.atgc-montpellier.fr/fastme/binaries.php
http://doua.prabi.fr/software/seaview

You can find a nice tutorialon how to use RAxML-NG on its wiki page: https://github.com/amkozlov/raxml-ng/wiki.


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

You may potentially have to remove sequences that do not seem homologous (or those that are the inverted complement of the sequence and won't align) by selecting them on the left and using `Edit > Delete sequence(s)`.

### Build a tree with RAxML-NG
```sh
# check the alignment is in the correct format and not corrupted
raxml-ng --check --msa Vibrio_spp_16S.aln --model GTR+G4

# search for maximum-likelhood tree
raxml-ng --search --msa Vibrio_spp_16S.aln.raxml.reduced.phy --model GTR+G4 --tree pars{1} --threads 4
# produce the ML tree file Vibrio_spp_16S.aln.raxml.reduced.phy.raxml.bestTree

# run bootstrap analysis = infer trees from many (here 10) subsamples of the alignment data (random picking the column of the alignment)
raxml-ng --bootstrap --msa Vibrio_spp_16S.aln.raxml.reduced.phy --model GTR+G4 --threads 4 --bs-trees 10
# produce the bootstrap tree file Vibrio_spp_16S.aln.raxml.reduced.phy.raxml.bootstraps

# map the bootstrap as supports to the main ML tree branches
# branch supports = frequency of observing the ML tree's splits in the sample of bootstrap trees
raxml-ng --support --msa Vibrio_spp_16S.aln.raxml.reduced.phy --model GTR+G4 --threads 4 \
 --tree Vibrio_spp_16S.aln.raxml.reduced.phy.raxml.bestTree \
 --bs-trees Vibrio_spp_16S.aln.raxml.reduced.phy.raxml.bootstraps
# produce the ML tree file with branch supports

raxml-ng --all --msa Vibrio_spp_16S.aln.raxml.reduced.phy.raxml.rba --model GTR+G4 --tree pars{1} --bs-trees 10  --threads 4
# do all this at once
```

## Big whole-genome alignment and tree


The whole-genome alignment is too big, with more than 4M sites (alignment collumns)! This would take unnecessarily long to process.

To tackle this, let's reduce the big whole-genome alignment to only the variable positions = a SNP alignment using `snp-sites`.
```sh
snp-sites -o 50yemen2018.pseudo_genome.snp.aln.raxml.reduced.phy.raxml.pseudo_genome.snp.aln 50yemen2018.pseudo_genome.aln 
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

