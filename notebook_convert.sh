#!/bin/bash
INFILE=$1
OUTFILE=${INFILE%.*}.imp
FILENAME=${OUTFILE%.*}
for i in *.py; do
	FILENAME=$FILENAME\|${i%.*}
done
FILENAME=$FILENAME$(cat $INFILE | sed -nE "s/.*from ([^\^ ]+) import ([^\^ ]+).*/|\2/p")
cat $INFILE | sed -nE "s/.*(import [^\^ ]+).*/\1/p" | \
	sed -E "s/.*import ($FILENAME).*//" | \
	tee $OUTFILE > /dev/null 2>&1
