# kWIP-nf
A nextflow pipeline to estimate sample (dis)similarity using kWIP

## Usage

To run on MENDEL:

```
module load Nextflow
module load Miniconda3
```

Single end:
```
nextflow run Gregor-Mendel-Institute/kWIP-nf --reads '/path/to/*fastq.gz' -profile mendel,conda
```

Paired end:
```
nextflow run Gregor-Mendel-Institute/kWIP-nf --reads --pairedEnd '/path/to/*{1,2}*fastq.gz' -profile mendel,conda
```


## Parameters

* `--reads` (path to read(pair)s `required`)
* `--pairedEnd` (set if dealing with paired end reads `default false`)
* `--trim` (trim reads `default true`)
* `--clip_r1` (bases to trim off 5' read 1 `default 0`)
* `--clip_r2` (bases to trim off 5' read 2 `default 0`)
* `--three_prime_clip_r1` (bases to trim off 3' read 1 `default 0`)
* `--three_prime_clip_r1` (bases to trim off 3' read 2 `default 0`)
* `--k_size` (size of k-mers `default 20`)
* `--tablesize` (size of hashtable `default 1e9`)

## Further reading

https://doi.org/10.1371/journal.pcbi.1005727

https://github.com/FelixKrueger/TrimGalore/blob/master/Docs/Trim_Galore_User_Guide.md

https://khmer.readthedocs.io

https://kwip.readthedocs.io
