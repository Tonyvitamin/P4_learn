#! /bin/bash

echo register_reset start_flag | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset time_flag | simple_switch_CLI --thrift-port 9090 > /dev/null

#echo register_reset last_timestamp | simple_switch_CLI --thrift-port 9090 > /dev/null
#echo register_reset cur_timestamp | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch2_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch2_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch2_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null
                 
echo register_reset cm_sketch3_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch3_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch3_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null
            
echo register_reset cm_sketch4_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch4_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch4_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null
              
echo register_reset cm_sketch1_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch1_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch1_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null    
    
    
echo register_reset cm_sketch5_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch5_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch5_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null
    
echo register_reset mask_queried_1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset mask_queried_2 | simple_switch_CLI --thrift-port 9090 > /dev/null  
echo register_reset mask_queried_3 | simple_switch_CLI --thrift-port 9090 > /dev/null   
echo register_reset mask_queried_4 | simple_switch_CLI --thrift-port 9090 > /dev/null   
echo register_reset mask_queried_5 | simple_switch_CLI --thrift-port 9090 > /dev/null