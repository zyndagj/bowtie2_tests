This makefile

- Builds
  - samtools
  - bowtie2
- Downloads
  - C. elegans reference genome
  - Zebrafish reference genome
- Simulates
  - approximately 1,000,000 paired reads from each genome
- Indexes
  - each genome with bowtie
- Aligns
  - Each read set using bowtie2

### Usage

```
make clean && make -j4 data && make align
```

### Comparing results

```
bash compare.sh file1.bam file2.bam
```
