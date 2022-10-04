# A tutorial about preparing taxon-specific reference files for Prokka

There are two main steps where optioal reference files can be passed on to Prokka.

First, a training file can be passed on to Prodigal, the gene caller i.e. the program that finds the ORFs in the raw contigs; see [Prokka option --prodigaltf](https://github.com/tseemann/prokka#option---prodigaltf).

Second, a custom reference protein database can be provided for when it runs the BLASTP search with the predicted proteome as query to find the closest matches with a functional annotation; [Prokka option --proteins](https://github.com/tseemann/prokka#option---proteins).

Regarding the latter option, a strategy can be used to dereplicate those reference protein databases, as is explained about the [Prokka option --usegenus](https://github.com/tseemann/prokka#the-genus-databases)

In this tutorial, we'll assume we're interested in annotating _Streptococcus suis_ genomes.

## Prepare the Prodigal training file
### Download the genomic fasta file archive from the NCBI Assembly website

Here we need good quality genomes that are hopefully diverse enough to cover the diversity of the species, but not too manay (see note below), so we put stringent criteria on the search when we go shopping for genome assemblies on the [NCBI Assembly database](https://www.ncbi.nlm.nih.gov/assembly), notably restricting to the RefSeq collection and only complete genomes.

Search terms: `"Streptococcus suis"[Organism] AND ("latest refseq"[filter] AND "complete genome"[filter] AND all[filter] NOT anomalous[filter])`

(Here you could manually select only 16 genomes out of the result list)
Use `Download Assemblies` > `Source database: RefSeq` > `File type Genomic fasta (.fna)`

### Upload to the farm (can use rsync)

### Uncompress and combine the files into a single fasta file
```sh
tar -xf genome_assemblies_genome_fasta.tar
for f in $(ls $PWD/ncbi-genomes-2022-09-14/*.fna.gz) ; do zcat $f ; done > combined_111_Strepsuis_genomic.fna
```

### Run prodigal to produce a training file (this is so fast that you probably don’t need to submit a job for this; I’ve run it on an interactive sub job)

To start an interactive job:
```sh
memmb=4000
bsub -Is -n2 -R "select[mem>${memmb}] rusage[mem=${memmb}] span[hosts=1]" -M${memmb} bash
```

To run Prodigal:
```sh
# on the Sanger cluster, load the module
module load prodigal/2.6.3--h516909a_2
prodigal -i combined_111_Strepsuis_genomic.fna -p single -o combined_111_Strepsuis_genomic -t combined_111_Strepsuis_genomic.trn
```
The file `combined_111_Strepsuis_genomic.trn` is the training file that can be passed on to Prokka via the option `--prodigaltf`.

Note: Prodigal has a built-in limit of 32Mbp genome data as input.

In the case of _Streptococcus suis_, this amounts to ~ 16 genomes. I think it’s still increasing the sensitivity of the model - but be aware it does it in a way that weighted towards the core genome (core genes being represented 16 times) but encapsulating more diversity of the accessory genome.

I think it’s worth doing and not too hard to do so (once troubleshooted !) but in truth regular practice is to just train the model on the genome to be scanned (see Prodigal paper [Hyatt et al., 2010](https://doi.org/10.1186/1471-2105-11-119)). 

In the end you are the only judge on whether you want to integrate that Prodigal training step in your annotation pipeline or not. 

If you do so, remember that only 32Mbp genome data ~ 16 Strep genomes are considered, so you may want to hand pick these genomes so as to best represent the species' diversity.


## Producing a custom protein database as reference for the BLAST step (towards functional annotation transfer).

This other step I definitely recommended to do as it will significantly improve the functional annotation of the proteome - I actually think it is more important than training the Prodigal model, but that depends if you’re more interested in predicting the protein sequence vs. their functional annotation.

For this you can/should download as many genomes as you want - I suggest taking the wider set of 1983 _Streptococcus suis_ genomes available in RefSeq for this, as their proteomes are easily dereplicated using MMseqs.

### Download the protein fasta file archive from the NCBI Assembly website

Search terms: `"Streptococcus suis"[Organism] AND ("latest refseq"[filter] AND all[filter] NOT anomalous[filter])`

Use `Download Assemblies` > `Source database: RefSeq` > `File type: protein fasta (.faa)`

In this case the ~2k proteomes amount to ~ 800MB compressed data (1.5 GB uncompressed)

(You can also download the `All file types` archive containing folders of all the file flavours - I find it handy for further reference, but it does take more space)

### Upload to the farm (can use rsync)

### Uncompress and combine the files into a single gzipped fasta file (no need to uncompress the individual proteome files)
```sh
tar -xf genome_assemblies_prot_fasta.tar
cat $PWD/ncbi-genomes-2022-09-14/*.faa.gz > combined_1983_Strepsuis_protein.faa.gz
```

### Dereplicate using MMseqs

On the Sanger cluster, load the module
```sh
module load  mmseqs2/12
mkdir -p tmp/
```
Then submit a job for the clustering. The following command is running the clustering with 100% id threshold so just dereplicating perfectly identical proteins.
```sh
bsub -o linclust.%J.log -e linclust.%J.log -J linclust -R "select[mem>32000] rusage[mem=32000] span[hosts=1]" -M32000 -n 8 -q long \
mmseqs easy-linclust combined_1983_Strepsuis_protein.faa.gz STREPSUIS100 tmp --min-seq-id 1.0 --min-aln-len 2 --threads 8
```
Output dereplicated protein fasta `STREPSUIS100_rep_seq.fasta` is 156MB (from 1.5 GB, so 10-fold gain) ; still that might be a bit big as a BLAST db; in comparison the built-in Prokka standard `Bacteria` reference database is 80MB .

```sh
bsub -o linclust.%J.log -e linclust.%J.log -J linclust -R "select[mem>32000] rusage[mem=32000] span[hosts=1]" -M32000 -n 8 -q long \
mmseqs easy-linclust combined_1983_Strepsuis_protein.faa.gz STREPSUIS099 tmp --min-seq-id 0.99 --min-aln-len 2 --threads 8

bsub -o linclust.%J.log -e linclust.%J.log -J linclust -R "select[mem>32000] rusage[mem=32000] span[hosts=1]" -M32000 -n 8 -q long \
mmseqs easy-linclust combined_1983_Strepsuis_protein.faa.gz STREPSUIS098 tmp --min-seq-id 0.98 --min-aln-len 2 --threads 8
```
(Note that all those jobs take at most 5min each)

```sh
ls -lh *_rep_seq.fasta
-rw-r--r-- 1 fl4 team216  77M Sep 14 15:20 STREPSUIS098_rep_seq.fasta
-rw-r--r-- 1 fl4 team216 103M Sep 14 15:20 STREPSUIS099_rep_seq.fasta
-rw-r--r-- 1 fl4 team216 156M Sep 14 15:11 STREPSUIS100_rep_seq.fasta
```

Looks like to me that the 98% protein id dereplication achieves a good size reduction

So you could use `STREPSUIS098_rep_seq.fasta` as the file to pass on to Prokka via the `--proteins` option

From there you sort of have a pipeline for preparation of a Prokka run!


