#!/usr/bin/env python2
import argparse
import grpc
import os
import sys
import time
from time import sleep
import threading 
import math

import google.protobuf.text_format
import grpc
from scapy.all import *

import scapy.packet
import scapy.utils
from google.rpc import status_pb2, code_pb2
import struct 
# Import P4Runtime lib from parent utils dir
# Probably there's a better way of doing this.
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
                 './'))
import p4runtime_lib.bmv2
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper

SWITCH_TO_HOST_PORT = 1
SWITCH_TO_SWITCH_PORT = 2

class packet_store_entry:
    def __init__(self):
        self.pkt_list = []
        self.t1_packet_num = []
        self.t2_packet_num = []
        self.timestamp = []
        self.hit = 0
        self.flow_id = -1
        
        
def reset_sketch():
    #sleep(5)
    os.system('./reset.sh')

    
    print "Reset Sketch all"
    count = 0   
    prev_flag = 0
    flag = 0
    while True:
        os.system('echo register_read state_flag 0 | simple_switch_CLI --thrift-port 9090  | grep [0] | awk \'{print $3}\' > s1_state_flag.txt &')
        sleep(1)
        with open('s1_state_flag.txt') as f:
            for line in f:
                flag = int(line)
        if prev_flag != flag:
            print "Changing phase from ", prev_flag, " to ", flag 
            
            if flag == 1:
                os.system('./reset_state1.sh')
                os.system('./data_collect_5.sh')
            if flag == 2:
                os.system('./reset_state2.sh')
                os.system('./data_collect_1.sh')
            if flag == 3:
                os.system('./reset_state3.sh')
                os.system('./data_collect_2.sh')
            if flag == 4:
                os.system('./reset_state4.sh')
                os.system('./data_collect_3.sh')
            if flag == 5:
                os.system('./reset_state5.sh')
                os.system('./data_collect_4.sh')
            
            prev_flag = flag
            count = 0


        elif prev_flag == flag:
            os.system('./data_collect_1.sh')
            if count%10 == 0 and count > 1:
                print "idling at phase: ", flag, " staying ", count, " secs"
            count+=1


        if count >20 and flag != 0:
            print "stay in state: ", flag , " over 20 secs"
            print "Reset the sketch system" 
            count = 0
            os.system('echo register_reset start_flag | simple_switch_CLI --thrift-port 9090 > /dev/null &')
            os.system('echo register_reset start_flag | simple_switch_CLI --thrift-port 9090 > /dev/null &')
            os.system('./reset.sh')

            print "Reset sketch finish"

            
def writeforwardRules(p4info_helper, ingress_sw):
    """
    Installs three rules:
    1) An tunnel ingress rule on the ingress switch in the ipv4_lpm table that
       encapsulates traffic into a tunnel with the specified ID
    2) A transit rule on the ingress switch that forwards traffic based on
       the specified ID
    3) An tunnel egress rule on the egress switch that decapsulates traffic
       with the specified ID and sends it to the host

    :param p4info_helper: the P4Info helper
    :param ingress_sw: the ingress switch connection
    :param egress_sw: the egress switch connection
    :param tunnel_id: the specified tunnel ID
    :param dst_eth_addr: the destination IP to match in the ingress rule
    :param dst_ip_addr: the destination Ethernet address to write in the
                        egress rule
    """
    # 1) Tunnel Ingress Rule
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": ("10.0.1.1", 32)
        },
        action_name="MyIngress.ipv4_forward",
        action_params={
            "dstAddr": "08:00:00:00:01:01",
            "port": 2
        })
    ingress_sw.WriteTableEntry(table_entry)

    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": ("10.0.2.2", 32)
        },
        action_name="MyIngress.ipv4_forward",
        action_params={
            "dstAddr": "08:00:00:00:02:02",
            "port": 3
        })
    ingress_sw.WriteTableEntry(table_entry)

    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": ("10.0.3.3", 32)
        },
        action_name="MyIngress.ipv4_forward",
        action_params={
            "dstAddr": "08:00:00:00:03:03",
            "port": 4
        })   
    ingress_sw.WriteTableEntry(table_entry)

    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": ("10.0.4.4", 32)
        },
        action_name="MyIngress.ipv4_forward",
        action_params={
            "dstAddr": "08:00:00:00:04:04",
            "port": 5
        })   
    ingress_sw.WriteTableEntry(table_entry)
    
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": ("10.0.5.5", 32)
        },
        action_name="MyIngress.ipv4_forward",
        action_params={
            "dstAddr": "08:00:00:00:05:05",
            "port": 6
        })   
    ingress_sw.WriteTableEntry(table_entry)
    
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": ("10.0.6.6", 32)
        },
        action_name="MyIngress.ipv4_forward",
        action_params={
            "dstAddr": "08:00:00:00:06:06",
            "port": 7
        })   
    ingress_sw.WriteTableEntry(table_entry)
    
    
    print "Installed forward tunnel rule on %s" % ingress_sw.name

    # 2) Tunnel Transit Rule
    # The rule will need to be added to the myTunnel_exact table and match on
    # the tunnel ID (hdr.myTunnel.dst_id). Traffic will need to be forwarded
    # using the myTunnel_forward action on the port connected to the next switch.
    #
    # For our simple topology, switch 1 and switch 2 are connected using a
    # link attached to port 2 on both switches. We have defined a variable at
    # the top of the file, SWITCH_TO_SWITCH_PORT, that you can use as the output
    # port for this action.
    #
    # We will only need a transit rule on the ingress switch because we are
    # using a simple topology. In general, you'll need on transit rule for
    # each switch in the path (except the last switch, which has the egress rule),
    # and you will need to select the port dynamically for each switch based on
    # your topology.


def readTableRules(p4info_helper, sw):
    """
    Reads the table entries from all tables on the switch.

    :param p4info_helper: the P4Info helper
    :param sw: the switch connection
    """
    print '\n----- Reading tables rules for %s -----' % sw.name
    for response in sw.ReadTableEntries():
        for entity in response.entities:
            entry = entity.table_entry
            # TODO For extra credit, you can use the p4info_helper to translate
            #      the IDs in the entry to names
            table_name = p4info_helper.get_tables_name(entry.table_id)
            print '%s: ' % table_name,
            for m in entry.match:
                print p4info_helper.get_match_field_name(table_name, m.field_id),
                print '%r' % (p4info_helper.get_match_field_value(m),),
            action = entry.action.action
            action_name = p4info_helper.get_actions_name(action.action_id)
            print '->', action_name,
            for p in action.params:
                print p4info_helper.get_action_param_name(action_name, p.param_id),
                print '%r' % p.value,
            print

def printCounter(p4info_helper, sw, counter_name, index):
    """
    Reads the specified counter at the specified index from the switch. In our
    program, the index is the tunnel ID. If the index is 0, it will return all
    values from the counter.

    :param p4info_helper: the P4Info helper
    :param sw:  the switch connection
    :param counter_name: the name of the counter from the P4 program
    :param index: the counter index (in our case, the tunnel ID)
    """
    for response in sw.ReadCounters(p4info_helper.get_counters_id(counter_name), index):
        for entity in response.entities:
            counter = entity.counter_entry
            print "%s %s %d: %d packets (%d bytes)" % (
                sw.name, counter_name, index,
                counter.data.packet_count, counter.data.byte_count
            )

def printGrpcError(e):
    print "gRPC Error:", e.details(),
    status_code = e.code()
    print "(%s)" % status_code.name,
    traceback = sys.exc_info()[2]
    print "[%s:%d]" % (traceback.tb_frame.f_code.co_filename, traceback.tb_lineno)

def main(p4info_file_path, bmv2_file_path):
    # Instantiate a P4Runtime helper from the p4info file
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    try:
        # Create a switch connection object for s1 and s2;
        # this is backed by a P4Runtime gRPC connection.
        # Also, dump all P4Runtime messages sent to switch to given txt files.
        s1 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s1',
            address='127.0.0.1:50051',
            device_id=0,
            proto_dump_file='logs/s1-p4runtime-requests.txt')
  

        # Send master arbitration update message to establish this controller as
        # master (required by P4Runtime before performing any other write operation)
        s1.MasterArbitrationUpdate()

        # Install the P4 program on the switches
        s1.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                       bmv2_json_file_path=bmv2_file_path)
        print "Installed P4 Program using SetForwardingPipelineConfig on s1"
        writeforwardRules(p4info_helper, ingress_sw=s1)


        # TODO Uncomment the following two lines to read table entries from s1 and s2
        readTableRules(p4info_helper, s1)
        # Print the tunnel counters every 2 seconds
        num = 0
        t1 = threading.Thread(target=reset_sketch)
        t1.start()
        s1_flow_detection = {}
        key = 0
        os.system('rm -f ./Experiment/n_flows/*.txt')
        while True:


            
            packetin = s1.PacketIn()
            if packetin:
                print '\n----- Packet in -----'
                packet = packetin.packet.payload
                pkt = Ether(packet)
                #pkt.show2()
                if pkt[Ether].type==0x0800:
                    if pkt[IP].proto==0x06:
                        key = (pkt[IP].src, pkt[IP].dst, pkt[TCP].sport, pkt[TCP].dport, pkt[IP].proto)
                        print pkt[IP].src, pkt[IP].dst, pkt[TCP].sport, pkt[TCP].dport, pkt[IP].proto

                    elif pkt[IP].proto==0x11:
                        key = (pkt[IP].src, pkt[IP].dst, pkt[UDP].sport, pkt[UDP].dport, pkt[IP].proto)
                        print pkt[IP].src, pkt[IP].dst, pkt[UDP].sport, pkt[UDP].dport, pkt[IP].proto
                    else:
                        continue
                else:
                    continue
                    
                        
                #print pkt
                #print packetin.packet.header
                
                t1_packet_num = 0
                t2_packet_num = 0
                timestamp =  0
                state = 0
                metadata = packetin.packet.metadata
                for i, meta in enumerate(metadata):
                    #print meta
                    metadata_id = meta.metadata_id
                    value = meta.value
                    if i > 1:
                        #print map(ord, value)
                        tmp = map(ord, value)
                        v = 0
                        index = 0
                        for i in reversed(tmp):
                            v += i * math.pow(2, index)
                            index+=8           
                            
                        if metadata_id == 3:
                            print "Packet count in time interval i: ", v
                            t1_packet_num = v
                        elif metadata_id ==4:
                            print "Packet count in time interval i+1: ", v
                            t2_packet_num = v
                        elif metadata_id ==5:
                            print "Timestamp of this packet: ", v
                            timestamp = v
                        elif metadata_id ==6:
                            print "State of this packet: ", v
                            state = v

                cur_time = time.time()
                print time.time()
                if key in s1_flow_detection:
                    s1_flow_detection[key].t1_packet_num.append(t1_packet_num)
                    s1_flow_detection[key].t2_packet_num.append(t2_packet_num)
                    s1_flow_detection[key].timestamp.append(timestamp)
                    s1_flow_detection[key].hit += 1
                else:
                    entry = packet_store_entry()
                    entry.t1_packet_num.append(t1_packet_num)
                    entry.t2_packet_num.append(t2_packet_num)
                    entry.timestamp.append(timestamp)
                    entry.hit +=1
                    entry.flow_id = len(s1_flow_detection) + 1
                    s1_flow_detection[key] = entry
                         
                num+=1
                #print s1_flow_detection
                print "Received : ", num, " packets"
                directory = './Experiment/test_2_2_2/1_flow_case/' + str(s1_flow_detection[key].flow_id)
                if not os.path.exists(directory):
                    os.mkdir(directory)
                filename = directory+'/'+str(s1_flow_detection[key].flow_id)+".txt"
                with open(filename, 'a') as f:
                    string = str(t1_packet_num)+ ' ' +str(t2_packet_num)+' ' +str(cur_time) + '\n'
                    f.write(string)

 

    except KeyboardInterrupt:
        print " Shutting down."
    except grpc.RpcError as e:
        printGrpcError(e)

    ShutdownAllSwitchConnections()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    parser.add_argument('--p4info', help='p4info proto in text format from p4c',
                        type=str, action="store", required=False,
                        default='./build/ecn.p4.p4info.txt')
    parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
                        type=str, action="store", required=False,
                        default='./build/ecn.json')
    args = parser.parse_args()

    if not os.path.exists(args.p4info):
        parser.print_help()
        print "\np4info file not found: %s\nHave you run 'make'?" % args.p4info
        parser.exit(1)
    if not os.path.exists(args.bmv2_json):
        parser.print_help()
        print "\nBMv2 JSON file not found: %s\nHave you run 'make'?" % args.bmv2_json
        parser.exit(1)
    main(args.p4info, args.bmv2_json)
