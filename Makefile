TL = "$(TBBROOT)/lib/intel64/gcc4.7"
TI = "$(TBBROOT)/include"

CC=gcc
CFLAGS=-O3 -m64 -march=haswell
LDFLAGS=-I$(TI) -L$(TL) -Wl,-rpath,$(TL)

#########################################
# Make Tools
#########################################
src:
	mkdir $@
# Make bowtie2
src/v2.3.4.1.tar.gz: | src
	cd src && wget https://github.com/BenLangmead/bowtie2/archive/v2.3.4.1.tar.gz
bin/bowtie2: | src/v2.3.4.1.tar.gz
	rm -rf bowtie2-2.3.4.1
	tar -xzf $|
	cd bowtie2-2.3.4.1 && make LDFLAGS="$(LDFLAGS)" RELEASE_FLAGS="$(CFLAGS)" WITH_AFFINITY=1 prefix=$(PWD) -j8 &> make_bowtie2.log && \
	make LDFLAGS="$(LDFLAGS)" RELEASE_FLAGS="$(CFLAGS)" WITH_AFFINITY=1 prefix=$(PWD) install
	rm -rf bowtie2-2.3.4.1
# Make samtools for processing output
src/samtools-1.7.tar.bz2: | src
	cd src && wget https://github.com/samtools/samtools/releases/download/1.7/samtools-1.7.tar.bz2
bin/samtools: | src/samtools-1.7.tar.bz2
	rm -rf samtools-1.7
	tar -xjf $|
	cd samtools-1.7 && ./configure --prefix $(PWD) && $(MAKE) -j8 &> make_samtools.log && $(MAKE) install
	rm -rf samtools-1.7 share
# Parent target
tools: bin/samtools bin/bowtie2

#########################################
# Download and prepare data
#########################################

references:
	mkdir $@
references/human.fa: | references
	curl -L http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.masked.gz | gzip -dc - > $|.tmp
	mv $|.tmp $|
references/zebrafish.fa: | references
	curl -L http://hgdownload.soe.ucsc.edu/goldenPath/danRer11/bigZips/danRer11.fa.masked.gz | gzip -dc - > $@.tmp
	mv $@.tmp $@
references/celegans.fa: | references
	wget http://hgdownload.soe.ucsc.edu/goldenPath/ce10/bigZips/chromFaMasked.tar.gz && tar -xzf chromFaMasked.tar.gz && rm chromFaMasked.tar.gz
	cat *masked > $@.tmp
	rm *masked
	mv $@.tmp $@
references/%.fa.fai: | references/%.fa bin/samtools
	REF=$@ && bin/samtools faidx $${REF%%.fai}

references/%.fa.1.bt2: | references/%.fa bin/bowtie2
	REF=$@ && REF=$${REF%%.1.bt2} && \
	bin/bowtie2-build --threads $$(nproc --all) --seed 1337 $${REF} $${REF} > $${REF}_bowtie.log

inputs:
	mkdir $@
inputs/%_1.fastq: | references/%.fa bin/samtools inputs
	REF=$(word 1, $|) && \
	R1=$@ && R2=$${R1/_1/_2} && \
	bin/wgsim -S 1337 -e 0.02 -r 0.0009 -R 0.0001 $$REF $$R1 $$R2 > /dev/null

data: | references/zebrafish.fa.fai references/zebrafish.fa.1.bt2 inputs/zebrafish_1.fastq references/celegans.fa.fai references/celegans.fa.1.bt2 inputs/celegans_1.fastq

#########################################
# Run Alignment
#########################################

outputs:
	mkdir $@

outputs/%.bam: | references/%.fa.1.bt2 inputs/%_1.fastq outputs
	REF=$(word 1, $|) && REF=$${REF%%.1.bt2} && \
	R1=$(word 2, $|) && R2=$${R1/_1/_2} && \
	bin/bowtie2 --seed 1337 -p $$(nproc --all) --no-discordant --no-mixed -x $$REF -1 $$R1 -2 $$R2 | bin/samtools view -bS -@ 4 | bin/samtools sort -@ 8 -T $$REF.tmp -o $@ -

align: | outputs/zebrafish.bam outputs/celegans.bam

#########################################
# things to clean up
#########################################
clean:
	rm -rf bowtie2-2.3.4.1
	rm -rf samtools-1.7
	rm -rf references
	rm -rf bin
	rm -rf src
	rm -rf outputs
	rm -rf inputs
