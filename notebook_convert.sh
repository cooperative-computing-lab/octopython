#!/bin/bash
INFILE=$1
OUTFILE=${INFILE%.*}.imp
cat $INFILE | sed -nE "s/.*(import [^\^ ]+).*/\1/p" | tee $OUTFILE > /dev/null 2>&1
