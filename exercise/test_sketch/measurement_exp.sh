#!/bin/sh



for interval in $(seq 1 300)
do 
    /bin/bash ./s1_read_timestamp.sh  | sed '1,3d' | sed '2,5d' | awk '{print $1 $2}' >> s1_timestamp.txt
    #echo register_read  cur_timestamp | simple_switch_CLI --thrift-port 9090
    #echo register_read  last_timestamp | simple_switch_CLI --thrift-port 9090

    #echo register_read  cur_timestamp | simple_switch_CLI --thrift-port 9091
    #echo register_read  last_timestamp | simple_switch_CLI --thrift-port 9091

    /bin/bash ./s1_read_estimate.sh   >> s1_estimate.txt
    #echo register_read  old_cms_estimate | simple_switch_CLI --thrift-port 9090
    #echo register_read  new_cms_estimate | simple_switch_CLI --thrift-port 9090

    #echo register_read  old_cms_estimate | simple_switch_CLI --thrift-port 9091
    #echo register_read  new_cms_estimate | simple_switch_CLI --thrift-port 9091

    sleep 1
done
