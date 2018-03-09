usageStr="\n\tusage: compare.sh in1.bam in2.bam\n"

[ ! -n "$1" ] && echo "Please use two arguments" && echo -e $usageStr && exit 1
[ ! -n "$2" ] && echo "Please use two arguments" && echo -e $usageStr && exit 1
[ ! -e $1 ] && echo "$1 does not exist" && echo -e $usageStr && exit 1
[ ! -e $2 ] && echo "$2 does not exist" && echo -e $usageStr && exit 1

SARGS="view -f 2 -F 0x100"
AWKSTR='{OFS="\t"; print $3,$4-1,$4-1+length($10)}'
diff --speed-large-files \
	<( bin/samtools $SARGS $1 | awk "$AWKSTR" ) \
	<( bin/samtools $SARGS $2 | awk "$AWKSTR" ) && echo "$1 and $2 are the same" || echo "$1 and $2 differ"
