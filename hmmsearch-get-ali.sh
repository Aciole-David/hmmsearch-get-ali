#!/bin/bash

#Get alignment positions from hmmsearch after running gruber's hmmprospector 

#1 - Create folders to save intermediate files
mkdir temp
mkdir positions #it may look weird to create two temp folders, but that is how I like (sorry). 
echo "Temp folders created."
echo

#(2) - Get all vHMMs from the file "table2.csv"
grep -v "#" table2.csv>temp/vHMMs-list.txt #simply all lines except the first one, which has a comment

#(3) - Get contigs and respective vHMMs from the file vHMMs-list.txt and save as the file vHMMs-list2.txt
awk '{print $1}' temp/vHMMs-list.txt>temp/vHMMs-list2.txt #get the first column of all lines 

c=`wc -l temp/vHMMs-list2.txt | cut -f1 -d' ' `
n=$((c-1))


echo "Extraction of vHMMs list done."
echo
echo "Extracting contigs for each vHMM..."

#(4) - Get list of contigs and save as a file for each vHMM

for vhmm in `cat temp/vHMMs-list2.txt`; do #loop on all the vHMMs in the file vHMMs-list2.txt, storing them in the variable "vhmm" 


printf ''"   $n out of $c vHMMs remaining;"'  \e[7m%s\e[0m\n'  "$((100-((100*n)/c)))% done"

n=$((n-1))

echo "Extracting contigs for $vhmm"

grep $vhmm table1.csv>>temp/$vhmm.temp-contigs.txt #use the vhmm variable to search all lines containing each vHMM in the file table1.csv and
#save in a file for each vHMM, so we can isolate the contigs' names in the next step

#(5) - Get contigs of each vHMM
for contig in `awk '{print $1}' temp/$vhmm.temp-contigs.txt`; do #loop on all words of the first column of each vhmm.temp-contigs.txt file,
#which are the contigs' names, storing them in the "contig" variable
echo
echo "Extracting alignment of contig $contig and $vhmm..." #show contig and vHMM of current iteration 

#(6) Get lines containing the actual alignment characters
grep -A 2 "$vhmm" *_hmmsearch.txt | grep "$contig">temp/$vhmm.positions.txt #the first grep uses the vhmm variable to search lines containing each vhmm in the
#"x_hmmsearch.txt" file, which is one of the hmmsearch outputs, and, also get the following 2 lines of each result, which contain the actual alignment coordinates;
#The second grep uses the contig variable to extract only the 3rd line of the previous grep, because it starts with the contig name and that is what I want.
#the result is a line with a structure like "CONTIG START ALIGNMENT END" (separated by space)

awk '{$3=""; print $0}' temp/$vhmm.positions.txt>>positions/$vhmm.positions.txt #remove second part of previous results, because
#I dont want the caracters of ALIGNMENT, but the CONTIG, START and END only; save the results in a vhmm.positions.txt file


sed -i "s/$contig/$contig $vhmm/g" positions/$vhmm.positions.txt; #replace the contig name with the contig plus the respective vhmm, because
#afterwards I can merge them all in a single file with all positions, without overwriting different contigs that have the same contig.

done #end of loop of step 5

echo ; #print nothing. This is only to show the vHMMs separately in the terminal. Organized!  

done #end of loop of step 4

echo "Extraction of all alignments' coordinates done."
echo


#(7) - Merge all positions in the temp-all-positions.txt file
cat positions/*>positions/temp-all-positions.txt

#(8) - Replace some weird stuff in the results file
sed -i -e 's/  / /g' -e 's/ /\t/g' positions/temp-all-positions.txt #the first sed replaces all double spaces with a single space, the second sed
#replaces spaces with tabs, because is much better to work with tab-delimited files...

#(9) - Create header to help in any further manipulations of files
echo -e "vHMM\tcontig\tstart\tend" | cat - positions/temp-all-positions.txt > all-positions.txt #this adds a line in the start of the all-positions.txt file,
#which are the name of columns; vHMM, contig, start and end, separated by tabs.

#Remove all temporary folders and the files within
rm -R ./temp/ ./positions/
echo "Removing temporary files..."
echo 
echo "All alignments' coordinates writen to the file 'all-positions.txt'"

#

