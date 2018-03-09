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

### Requirements

- valid `TBBROOT` environment variable
- gcc, g++
- The following libs
  - libbz2
  - libz
  - libcrypto
  - liblzma
  - libm
  - libssl
  - libtbbmalloc_proxy
  - libtbbmalloc
  - libtbb

### Usage

```
make clean && make -j4 data && make align
```

### Comparing results

```
bash compare.sh file1.bam file2.bam
```
