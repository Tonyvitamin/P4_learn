
# Copyright 2013-present Barefoot Networks, Inc.
# Copyright 2018-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import Queue
import argparse
import json
import logging
import os
import re
import struct
import subprocess
import sys
import threading
import datetime
from collections import OrderedDict
import time
from StringIO import StringIO
from collections import Counter
from functools import wraps, partial
from unittest import SkipTest
from scapy.all import *
from netaddr import IPAddress

import google.protobuf.text_format
import grpc
from p4.tmp import p4config_pb2
from p4.v1 import p4runtime_pb2

from basic import P4RuntimeClient, stringify, packet_sotre_entry 

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("pi_client")

def readTableRules(sw, table_name = None):
    """
    Reads the table entries from all tables on the switch.
    :param p4info_helper: the P4Info helper
    :param sw: the switch connection
    """
    print '\n----- Reading tables rules -----'
    if table_name is not None:
        t_id = sw.get_table_id(table_name)
    else:
        t_id = None
    for response in sw.ReadTableEntries(table_id = t_id):
        for entity in response.entities:
            entry = entity.table_entry
            # TODO For extra credit, you can use the p4info_helper to translate
            #      the IDs the entry to names
            table_name = sw.p4info_helper.get_tables_name(entry.table_id)
            print '%s: ' % table_name,
            for m in entry.match:
                print sw.p4info_helper.get_match_field_name(table_name, m.field_id),
                print '%r' % (sw.p4info_helper.get_match_field_value(m),),
            action = entry.action.action
            action_name = sw.p4info_helper.get_actions_name(action.action_id)
            print '->', action_name,
            for p in action.params:
                print sw.p4info_helper.get_action_param_name(action_name, p.param_id),
                print '%r' % p.value,
            print
    print

def error(msg, *args, **kwargs):
    logger.error(msg, *args, **kwargs)


def warn(msg, *args, **kwargs):
    logger.warn(msg, *args, **kwargs)


def info(msg, *args, **kwargs):
    logger.info(msg, *args, **kwargs)


def main():
    parser = argparse.ArgumentParser(
        description="A simple P4Runtime Client")
    parser.add_argument('--device',
                        help='Target device',
                        type=str, action="store", required=True,
                        choices=['tofino', 'bmv2'])
    parser.add_argument('--p4info',
                        help='Location of p4info proto in text format',
                        type=str, action="store", required=True, 
                        default='/home/sdn/onos/pipelines/basic/src/main/resources/p4c-out/bmv2/basic.p4info')
    parser.add_argument('--config',
                        help='Location of Target Dependant Binary',
                        type=str, action="store",
                        default='/home/sdn/onos/pipelines/basic/src/main/resources/p4c-out/bmv2/basic.json')
    parser.add_argument('--ctx-json',
                        help='Location of Context.json',
                        type=str, action="store")
    parser.add_argument('--grpc-addr',
                        help='Address to use to connect to P4 Runtime server',
                        type=str, default='localhost:50051')
    parser.add_argument('--device-id',
                        help='Device id for device under test',
                        type=int, required=True, default=0)
    parser.add_argument('--skip-config',
                        help='Assume a device with pipeline already configured',
                        action="store_true", default=False)
    parser.add_argument('--skip-role-config',
                        help='Assume a device do not need role config',
                        action="store_true", default=False)
    parser.add_argument('--election-id',
                        help='ID for mastership election',
                        type=int, required=True, default=False)
    parser.add_argument('--role-id',
                        help='ID for distinguish different client',
                        type=int, required=False, default=0)
    args, unknown_args = parser.parse_known_args()

    # device = args.device

    if not os.path.exists(args.p4info):
        error("P4Info file {} not found".format(args.p4info))
        sys.exit(1)

    # grpc_port = args.grpc_addr.split(':')[1]

    try:
        print "Try to connect to P4Runtime Server"
        s1 = P4RuntimeClient(grpc_addr = args.grpc_addr, 
                             device_id = args.device_id, 
                             device = args.device,
                             election_id = args.election_id,
                             role_id = args.role_id,
                             config_path = args.config,
                             p4info_path = args.p4info,
                             ctx_json = args.ctx_json)
        s1.handshake()
        if not args.skip_config:
            s1.update_config()

        if not args.skip_role_config:
            # Role config must be set after fwd pipeline or table info not appear in server may cause server crash.
            roleconfig = s1.get_new_roleconfig()
            s1.add_roleconfig_entry(roleconfig, "ingress.table0_control.table0", 1)
            s1.add_roleconfig_entry(roleconfig, "ingress.table1_control.table1", 1)
            s1.handshake(roleconfig)

        # If send to CPU, send to both ONOS and embd ctrler
        # NOTICE: BMv2 ONLY (Modify CPU Port for egress_spec matching)
        req = s1.get_new_write_request()
        s1.push_update_add_entry_to_action(
            req,
            "MyIngress.ipv4_lpm",
            [s1.Lpm("hdr.ipv4.dstAddr", '10.0.2.2', 32)],
            "MyIngress.ipv4_forward", [["dstAddr", "08:00:00:00:02:02"], ["port", "3"]  ], 110)
        s1.write_request(req)
        '''
        print "Send packet to CPU to both Controller"
        req = s1.get_new_write_request()
        s1.push_update_add_entry_to_action(
            req,
            "ingress.tableNCS_control.tableNCS",
            [s1.Ternary("standard_metadata.egress_spec", '\x00\xff', '\x01\xff')],
            "tableNCS_control.send_to_both_cpu", [], 110)
        s1.write_request(req)
        
        # Set Permission ACL
        print "Copy All TCP Pkt to CPU"
        req = s1.get_new_write_request()
        s1.push_update_add_entry_to_action(
            req,
            "ingress.tableNCS_control.tableNCS",
            [s1.Ternary("hdr.ipv4.protocol", '\x06', '\xff')],
            "tableNCS_control.copy_to_embd_cpu", [], 100)
        s1.write_request(req)

        print "Copy All UDP Pkt to CPU"
        req = s1.get_new_write_request()
        s1.push_update_add_entry_to_action(
            req,
            "ingress.tableNCS_control.tableNCS",
            [s1.Ternary("hdr.ipv4.protocol", '\x17', '\xff')],
            "tableNCS_control.copy_to_embd_cpu", [], 100)
        s1.write_request(req)
        '''
        # readTableRules(s1)

        # pkt = '\xaa\xaa\xaa\x0a\x00\x00\x6e\xd2\xeb\x60\xf4\x69\x08\x00\x45\x00\x00\x54\x44\xa0\x40\x00\x40\x01\xe2\x06\x0a\x00\x00\x01\x0a\x00\x00\x02\x08\x00\x88\x06\x08\xab\x00\x09\xbc\x3b\xea\x5c\x00\x00\x00\x00\xf5\xd9\x0c\x00\x00\x00\x00\x00\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37'
        # port = 255

        # print(datetime.datetime.now(), "Send Packet Out to CPU_Port")
        # s1.send_packet_out(pkt, port)

	
        while 1:
            s1.packetin_rdy.clear()
            s1.packetin_rdy.wait()
            packetin = s1.get_packet_in()
            if packetin:
                pkt = packetin.payload
                pkt.show2()
                parsed_pkt = Ether(packetin.payload)
                key_bypass = 0
                key_r_bypass = 0
                
                # Only accept TCP and UDP
                if parsed_pkt[Ether].type == 0x0800:
                    if parsed_pkt[IP].proto != 0x06 and parsed_pkt[IP].proto != 0x11:
                        continue
                else:
                    continue

                if parsed_pkt[IP].proto == 0x06:
                    key = (parsed_pkt[IP].src, parsed_pkt[IP].dst, parsed_pkt[IP].proto, parsed_pkt[TCP].sport, parsed_pkt[TCP].dport)
                    key_r = (parsed_pkt[IP].dst, parsed_pkt[IP].src, parsed_pkt[IP].proto, parsed_pkt[TCP].dport, parsed_pkt[TCP].sport)
                else:
                    key = (parsed_pkt[IP].src, parsed_pkt[IP].dst, parsed_pkt[IP].proto, parsed_pkt[UDP].sport, parsed_pkt[UDP].dport)
                    key_r = (parsed_pkt[IP].dst, parsed_pkt[IP].src, parsed_pkt[IP].proto, parsed_pkt[UDP].dport, parsed_pkt[UDP].sport)

                # Already more than 784
                if key in s1.packet_store:
                    if s1.packet_store[key].pkt_total_len >= s1.flow_size_max:
                        s1.packet_store[key].overhit_count += 1
                        print "Flow Already over", s1.flow_size_max, "bytes", ", overhit", s1.packet_store[key].overhit_count, "times"
                        continue

                if s1.session_mode:
                    if key_r in s1.packet_store:
                        if s1.packet_store[key_r].pkt_total_len >= s1.flow_size_max:
                            s1.packet_store[key_r].overhit_count += 1
                            print "Session Already over", s1.flow_size_max, "bytes", ", overhit", s1.packet_store[key_r].overhit_count, "times"
                            continue

                if key in s1.packet_store:
                    # print "Dict entry already exist!"
                    if parsed_pkt[IP].proto == 0x06:
                        entry = s1.packet_store[key]
                    else:
                        entry = s1.packet_store[key]
                    entry.pkt_total_len += len(pkt)
                    entry.pkt_list.append(pkt)
                    # print "Flow Total Length is ", s1.packet_store[key].pkt_total_len
                else:
                    if s1.session_mode and key_r in s1.packet_store:
                        # print "Dict entry already exist!"
                        if parsed_pkt[IP].proto == 0x06:
                            entry = s1.packet_store[key_r]
                        else:
                            entry = s1.packet_store[key_r]
                        entry.pkt_total_len += len(pkt)
                        entry.pkt_list.append(pkt)
                        # print "Flow Total Length is ", s1.packet_store[key].pkt_total_len
                    else:
                        # print "Create dict entry"
                        entry = packet_sotre_entry()
                        entry.pkt_total_len = len(pkt)
                        entry.pkt_list.append(pkt)
                        if parsed_pkt[IP].proto == 0x06:
                            s1.packet_store[key] = entry
                        else:
                            s1.packet_store[key] = entry

                        # print "Flow Total Length is ", s1.packet_store[key].pkt_total_len

                # print

                # Check key 
                if key in s1.packet_store:
                    if s1.packet_store[key].pkt_total_len >= s1.flow_size_max:
                        key_bypass = 1

                # Check key_r 
                if key_r in s1.packet_store:
                    if s1.packet_store[key_r].pkt_total_len >= s1.flow_size_max:
                        key_r_bypass = 1

                if key_bypass is 0 and key_r_bypass is 0: # Do nothing
                    continue
                else:
                    # Parameter initilize
                    ipsrc_str = stringify(int(IPAddress(parsed_pkt[IP].src)), 4)
                    ipdst_str = stringify(int(IPAddress(parsed_pkt[IP].dst)), 4)
                    ipproto_str = stringify(parsed_pkt[IP].proto, 1)

                    if parsed_pkt[IP].proto == 0x06:
                        print "IP_src ", parsed_pkt[IP].src, ", IP_dst ", parsed_pkt[IP].dst, ", IP_proto ", parsed_pkt[IP].proto, ", sport ", parsed_pkt[TCP].sport, ", dport ", parsed_pkt[TCP].dport
                        l4_sport = stringify(parsed_pkt[TCP].sport, 2)
                        l4_dport = stringify(parsed_pkt[TCP].dport, 2)
                    else:
                        print "IP_src ", parsed_pkt[IP].src, ", IP_dst ", parsed_pkt[IP].dst, ", IP_proto ", parsed_pkt[IP].proto, ", sport ", parsed_pkt[UDP].sport, ", dport ", parsed_pkt[UDP].dport
                        l4_sport = stringify(parsed_pkt[UDP].sport, 2)
                        l4_dport = stringify(parsed_pkt[UDP].dport, 2)
                    print
                    
                    # Bypass key 
                    if key_bypass or (s1.session_mode and key_r_bypass):
                        req = s1.get_new_write_request()
                        s1.push_update_add_entry_to_action(
                            req,
                            "ingress.tableNCS_control.tableNCS",
                            [s1.Ternary("hdr.ipv4.protocol", ipproto_str, '\xff'),
                            s1.Ternary("hdr.ipv4.src_addr", ipsrc_str, '\xff\xff\xff\xff'),
                            s1.Ternary("hdr.ipv4.dst_addr", ipdst_str, '\xff\xff\xff\xff'),
                            s1.Ternary("local_metadata.l4_src_port", l4_sport, '\xff\xff'),
                            s1.Ternary("local_metadata.l4_dst_port", l4_dport, '\xff\xff')],
                            "tableNCS_control.bypass", [], 200)
                        s1.write_request(req)
                        i = 0
                        # for pkt in s1.packet_store[key].pkt_list:
                        #     print "Packet ", i
                        #     print " ".join("{:02x}".format(ord(c)) for c in pkt)
                        #     i = i+1

                    # Bypass key_r
                    if key_r_bypass or (s1.session_mode and key_bypass):
                        req = s1.get_new_write_request()
                        s1.push_update_add_entry_to_action(
                            req,
                            "ingress.tableNCS_control.tableNCS",
                            [s1.Ternary("hdr.ipv4.protocol", ipproto_str, '\xff'),
                            s1.Ternary("hdr.ipv4.src_addr", ipdst_str, '\xff\xff\xff\xff'),
                            s1.Ternary("hdr.ipv4.dst_addr", ipsrc_str, '\xff\xff\xff\xff'),
                            s1.Ternary("local_metadata.l4_src_port", l4_dport, '\xff\xff'),
                            s1.Ternary("local_metadata.l4_dst_port", l4_sport, '\xff\xff')],
                            "tableNCS_control.bypass", [], 200)
                        s1.write_request(req)
                        
        s1.tearDown()

    except Exception:
        raise
        s1.tearDown()

    except KeyboardInterrupt:
	print "Ctrl+C pressed..."
        s1.tearDown()


if __name__ == '__main__':
    main()
