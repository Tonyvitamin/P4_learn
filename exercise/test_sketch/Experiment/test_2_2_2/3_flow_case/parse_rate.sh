#! /bin/bash

hosts=5
accept=0
#rm result.txt
for i in $(seq 3 $hosts);
do
	cat  x_h2.txt | grep % | grep $i] | sed 's/-/ /'  | awk '{print $8}' > "${i}_result.txt"
done

