#! /bin/bash

hosts=6
accept=0
#rm result.txt
touch result.txt
for i in $(seq 2 $hosts);
do
	cat x_h$i.txt | sed 1,7d | sed 51,52d | sed 's/-/ /' | awk '{print $6}' > h1_h$i.txt
	cat x_h$i.txt | sed 1,7d | sed 51,52d | sed 's/-/ /' | awk '{print $6}' | wc -l

done
