#!/bin/bash

if [ ! "$#" -ge 5 ]; then
	echo "Usage : $0 <SeqDB> <ProfileDB> <OutDB> <tmpDir> <eValThs> "
	exit -1;
fi

SEQDB=$1
OUTDB=$3
TMP=$4
# Copy of the profile DB that can be reduced as the search processes
ln -s $(realpath $2) $TMP/profileDB
sort -k1,1 $2.index > $TMP/profileDB.index
PROFILEDB=$TMP/profileDB
#THREADS=24
eval=$5

offset=0 #start with the first result

nProfiles=$(wc -l $PROFILEDB.index|cut -f1 -d' ')

while [ $nProfiles -gt 0 ]
do
    MEMORY_FOR_SWAPPING=$(free|grep Mem|awk '{print $4}') #1000000 #10000000

    # correct the evalue (searching with profiles vs searching with sequences)
    currentEval=$eval
    nSequences=$(wc -l $SEQDB.index|cut -f1 -d' ')
    currentEval=`echo $currentEval | sed -e 's/[eE]+*/\\*10\\^/'`
    currentEval=`echo "$currentEval*$nProfiles/$nSequences"|bc -l`

    # compute the max number of sequence that are reasonable to swap
    # according to the number of profiles
    let MAX_SEQS=$MEMORY_FOR_SWAPPING*1024/$nProfiles/90/2 # 90 bytes/query-result line max. and 2 is a safety guard

    echo "Memory for swapping: $MEMORY_FOR_SWAPPING" >> $TMP/log.txt
    echo "Current iteration: searching for $MAX_SEQS sequences using $nProfiles profiles with an offset of $offset in the results" >> $TMP/log.txt

    rm -f $TMP/aln_.* $TMP/pref_* $TMP/searchOut.notSwapped.$nProfiles* #$TMP/searchOut.current*
    SEARCHCOMMAND="mmseqs search $PROFILEDB $SEQDB $TMP/searchOut.notSwapped.$nProfiles $TMP -e $currentEval --max-seqs $MAX_SEQS --profile --offset-result $offset ${@:6}"
    echo $SEARCHCOMMAND >> $TMP/log.txt
    $SEARCHCOMMAND
    echo "Swapping results:" >> $TMP/log.txt
    echo $(ls -lh $TMP/searchOut.notSwapped.$nProfiles $TMP/searchOut.notSwapped.$nProfiles.index) >> $TMP/log.txt
    mmseqs swapresults $PROFILEDB $SEQDB $TMP/searchOut.notSwapped.$nProfiles $TMP/searchOut.current.$nProfiles --threads $THREADS
    # note here : we recover the right evalue, since it is computed according to the target db which is the full profiledb   
    echo $(ls -lh $TMP/searchOut.current.$nProfiles $TMP/searchOut.current.$nProfiles.index) >> $TMP/log.txt 

    if [ -f $TMP/searchOut ]; then
        if [ $(wc -l $TMP/searchOut|cut -f1 -d ' ') -ge 1 ]; then
            echo "Merging with older results..." >> $TMP/log.txt
            mmseqs mergedbs $SEQDB $TMP/searchOut.new $TMP/searchOut.current.$nProfiles $TMP/searchOut
            mv -f $TMP/searchOut.new $TMP/searchOut
            mv -f $TMP/searchOut.new.index $TMP/searchOut.index
        fi
    else
        echo "First iteration : Creating searchOut..." >> $TMP/log.txt
        mv -f $TMP/searchOut.current.$nProfiles $TMP/searchOut 
        mv -f $TMP/searchOut.current."$nProfiles".index $TMP/searchOut.index
    fi
    
    let offset=offset+MAX_SEQS # keep for the prefilter only the next hits
    
    # now remove the profiles that reached their eval threshold
    mmseqs result2stats $PROFILEDB $SEQDB $TMP/searchOut.notSwapped.$nProfiles $TMP/searchOut.count  --stat linecount
    mmseqs filterdb $TMP/searchOut.count $TMP/searchOut.toKeep --filter-column 1 --comparison-operator ge --comparison-value $MAX_SEQS --threads $THREADS

    join <(awk '$3>1{print $1}' $TMP/searchOut.toKeep.index|sort)  $PROFILEDB.index >  $PROFILEDB.index.tmp 
    mv -f $PROFILEDB.index.tmp $PROFILEDB.index # reduce the profile DB
    nProfiles=$(wc -l $PROFILEDB.index|cut -f1 -d' ')
    
done
# Save the results
mv -f $TMP/searchOut $OUTDB
mv -f $TMP/searchOut.index $OUTDB.index

# Clean up
#rm -f $TMP/searchOut.toKeep $TMP/searchOut.toKeep.index
#rm -f $TMP/searchOut.count $TMP/searchOut.count.index
#rm -f $TMP/aln_4.* $TMP/pref_4* $TMP/searchOut.notSwapped* $TMP/searchOut.current*
rm $TMP/profileDB*
