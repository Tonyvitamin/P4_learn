/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<8>  TCP_PROTOCOL = 0x06;
const bit<16> TYPE_IPV4 = 0x800;
const bit<19> ECN_THRESHOLD = 10;


// Sketch part
#define HASH_SEED_r1 10w12
#define HASH_SEED_r2 10w34
#define HASH_SEED_r3 10w56
#define HASH_BASE 10w0
#define HASH_MAX 10w19

// Report filter
#define HASH_SEED_BM 10w56
#define HASH_BASE_BM 10w0
#define HASH_MAX_BM 10w9999


#define IP_PROTO_TCP 8w6
#define IP_PROTO_UDP 8w17



/* MACROS */
/* Sketch part */
#define GET_Sketch_value(num, seed, flow_size) \
hash(meta.currentIndex, HashAlgorithm.crc32, (bit<32>)0, {meta.original_flowID, seed}, (bit<32>)ENTRIES_PER_TABLE);\
hp##num.read(meta.currentEntry, meta.currentIndex);\
meta.currentKey = meta.currentEntry[135:32];\
meta.currentCount = meta.currentEntry[31:0];\
if (meta.flowID - meta.currentKey == 0) {\
    flow_size = flow_size + meta.currentCount;\
}

/* Pipe part */
#define ENTRIES_PER_TABLE 20
#define ENTRY_WIDTH 136

#define HP_INIT(num) register<bit<ENTRY_WIDTH>>(ENTRIES_PER_TABLE) hp##num

#define GET_Value(num, seed, flow_size) \
hash(meta.currentIndex, HashAlgorithm.crc32, (bit<32>)0, {meta.original_flowID, seed}, (bit<32>)ENTRIES_PER_TABLE);\
hp##num.read(meta.currentEntry, meta.currentIndex);\
meta.currentKey = meta.currentEntry[135:32];\
meta.currentCount = meta.currentEntry[31:0];\
if (meta.flowID - meta.currentKey == 0) {\
    flow_size = flow_size + meta.currentCount;\
}


#define GET_ENTRY(num, seed) \
hash(meta.currentIndex, HashAlgorithm.crc32, (bit<32>)0, {meta.flowID, seed}, (bit<32>)ENTRIES_PER_TABLE);\
hp##num.read(meta.currentEntry, meta.currentIndex);

#define WRITE_ENTRY(num, entry) hp##num.write(meta.currentIndex, entry)

#define STAGE_N(num, seed) {\
meta.flowID = meta.carriedKey;\
GET_ENTRY(num, seed);\
meta.currentKey = meta.currentEntry[135:32];\
meta.currentCount = meta.currentEntry[31:0];\
if (meta.currentKey - meta.carriedKey == 0) {\
    meta.toWriteKey = meta.currentKey;\
    if (meta.fromSketch == 1){\
        meta.toWriteCount = meta.currentCount + meta.flow_cnt;\
    }\
    else{\
        meta.toWriteCount = meta.currentCount + meta.carriedCount;\
    }\
    meta.carriedKey = 0;\
    meta.carriedCount = 0;\
    meta.fromSketch = 0;\
} else {\
    if (meta.carriedCount > meta.currentCount) {\
        meta.toWriteKey = meta.carriedKey;\
        meta.toWriteCount = meta.carriedCount;\
\
        meta.carriedKey = meta.currentKey;\
        meta.carriedCount = meta.currentCount;\
        meta.fromSketch = 0;\
    } else {\
        meta.toWriteKey = meta.currentKey;\
        meta.toWriteCount = meta.currentCount;\
    }\
}\
bit<136> temp = meta.toWriteKey ++ meta.toWriteCount;\
WRITE_ENTRY(num, temp);\
}

/* Initialize HP*/
/* 2 pipe for each state*/
HP_INIT(0);
HP_INIT(1);

HP_INIT(2);
HP_INIT(3);

HP_INIT(4);
HP_INIT(5);

HP_INIT(6);
HP_INIT(7);

HP_INIT(8);
HP_INIT(9);


const bit<32> FLOW_TABLE_SIZE_EACH = 20;
const bit<48> INTERVAL_SIZE = 2000000;
const bit<32> CHANGE_THRESHOLD = 0;
const bit<32> CM_THRESHOLD = 100000;


const bit<32> BITMAP_FILTER_SIZE_EACH = 10000;



/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/



typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<16> port_t;

@controller_header("packet_in")
header packet_in_header_t {
    bit<9> ingress_port;
    bit<7> direction_id;

    bit<32> flow_size_1;
    bit<32> flow_size_2;
    bit<48> timestamp;
    //bit<8>  sign;

}

//_PKT_OUT_HDR_ANNOT_
@controller_header("packet_out")
header packet_out_header_t {
    bit<9> egress_port;
    bit<7> _padding;
}

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    diffserv;
    bit<2>    ecn;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length_;
    bit<16> checksum;
}

struct metadata {
    
    // Reward info
    bit<7> direction_id;

    bit<32> sketch1_r1;
    bit<32> sketch1_r2;
    bit<32> sketch1_r3;

    bit<32> sketch2_r1;
    bit<32> sketch2_r2;
    bit<32> sketch2_r3;

    bit<32> flow_size_1;
    bit<32> flow_size_2;
    bit<8>  sign;
    bit<48> timestamp;


    ip4Addr_t srcIP;
    ip4Addr_t dstIP;
    port_t    srcPort;
    port_t    dstPort;
    bit<8> protocol;

    bit<3>      fromSketch;
    bit<32>     currentIndex;
    bit<136>    currentEntry;

    bit<104>    currentKey;
    bit<32>     currentCount;

    bit<104>    carriedKey;
    bit<32>     carriedCount;

    bit<104>    toWriteKey;
    bit<32>     toWriteCount;


    bit<104> flowID;
    bit<104> original_flowID;
    bit<32> flow_cnt;


    bit<32> ha_r1;
    bit<32> ha_r2;
    bit<32> ha_r3;

    bit<32> bm_r1;

    bit<32> qc_r1;
    bit<32> qc_r2;
    bit<32> qc_r3;

}

struct headers {
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
    udp_t        udp;

}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition select(standard_metadata.ingress_port) {
            255: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.packet_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTO_TCP: parse_tcp;
            IP_PROTO_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        meta.srcIP = hdr.ipv4.srcAddr;
        meta.dstIP = hdr.ipv4.dstAddr;
        meta.protocol = hdr.ipv4.protocol;
        meta.srcPort = hdr.tcp.src_port;
        meta.dstPort = hdr.tcp.dst_port;
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
        meta.srcIP = hdr.ipv4.srcAddr;
        meta.dstIP = hdr.ipv4.dstAddr;
        meta.protocol = hdr.ipv4.protocol;
        meta.srcPort = hdr.udp.src_port;
        meta.dstPort = hdr.udp.dst_port;
        transition accept;
    }

}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}




control Measurement(inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {

    /* Sketch 1: CM Sketch */
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r3;


    /* Sketch 2: CM Sketch */
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r3;

    /* Sketch 3: CM Sketch */
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch3_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch3_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch3_r3;


    /* Sketch 4: CM Sketch */
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch4_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch4_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch4_r3;

    /* Sketch 5: CM Sketch */
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch5_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch5_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch5_r3;

    /* Queried Mask(bloom filter) */
    // In case that queried flow keep forwarding packet to controller to remind controller this flow change
    register<bit<2> > (BITMAP_FILTER_SIZE_EACH) mask_queried_1;
    register<bit<2> > (BITMAP_FILTER_SIZE_EACH) mask_queried_2;
    register<bit<2> > (BITMAP_FILTER_SIZE_EACH) mask_queried_3;
    register<bit<2> > (BITMAP_FILTER_SIZE_EACH) mask_queried_4;
    register<bit<2> > (BITMAP_FILTER_SIZE_EACH) mask_queried_5;


    register<bit<48> > (1) last_timestamp;
    register<bit<48> > (1) cur_timestamp;
    register<bit<8> > (1) state_flag;
    register<bit<2> >(1) start_flag;


    action min_cnt(inout bit<32> mincnt, in bit<32> cnt1, in bit<32> cnt2, in bit<32> cnt3){
        if(cnt1 < cnt2){
            mincnt = cnt1;
        }
        else {
            mincnt = cnt2;
        }

        if(mincnt>cnt3){
            mincnt = cnt3;
        }
    }
    apply{


            meta.flowID[31:0] = meta.srcIP;
            meta.flowID[63:32] = meta.dstIP;
            meta.flowID[79:64] = meta.srcPort;
            meta.flowID[95:80] = meta.dstPort;
            meta.flowID[103:96] = meta.protocol;
            meta.original_flowID = meta.flowID;

            meta.flow_cnt = standard_metadata.packet_length;
            hash(meta.ha_r1, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_r1}, HASH_MAX);
            hash(meta.ha_r2, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_r2}, HASH_MAX);
            hash(meta.ha_r3, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_r3}, HASH_MAX);

            hash(meta.bm_r1, HashAlgorithm.crc16, HASH_BASE_BM, {meta.flowID, HASH_SEED_BM}, HASH_MAX_BM);


            bit<48>  t_diff;
            bit<48>  ct;
            bit<48>  lt;
            bit<8>   flag;
            bit<2>   s_flag;


            state_flag.read(flag, 0);
            start_flag.read(s_flag, 0);


            // Start detection
            if(s_flag==0){
                state_flag.write(0, 1);
                flag=1;
                start_flag.write(0, 1);
                last_timestamp.write(0, standard_metadata.ingress_global_timestamp);
            }
            ct = standard_metadata.ingress_global_timestamp;

            cur_timestamp.write(0, standard_metadata.ingress_global_timestamp);
            last_timestamp.read(lt, 0);
            t_diff = ct - lt;

            // Circular 5 State process & query 

            // State 1
            // 1. Process packet & store packet counter into sketch 1 (CM sketch)
            // 2. Query Sketch 5 & Sketch 4 ( S5[i] - S4[i] ), for any flow "i"
            // 3. Transition to State 2
            //else{
                if(flag==1){


                    // Process packet in S1

                    // Sketch part
                    cm_sketch1_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch1_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch1_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch1_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch1_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch1_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);

                    // CM threshold setting for sketch part
                    bit <32> est;
                    min_cnt(est, meta.qc_r1+meta.flow_cnt, meta.qc_r2+meta.flow_cnt, meta.qc_r3+meta.flow_cnt );

                    // Pipe part 
                    if (est > 10){
                        meta.carriedKey = meta.flowID;
                        meta.carriedCount = est;
                        meta.fromSketch = 1;
                        STAGE_N(0, 104w00000000000000000000);
                        STAGE_N(1, 104w11111111111111111111);
                    }

                    // Query S5-S4 if necessary
                        bit<2> index_1;


                        mask_queried_1.read(index_1, meta.bm_r1);


                        // Never Queried before
                        if(index_1!=1 ){


                            bit<32> old_est;
                            old_est = 0;
                            GET_Value(6, 104w66666666666666666666, old_est);
                            GET_Value(7, 104w77777777777777777777, old_est);

                            bit<32> new_est;
                            new_est = 0;
                            GET_Value(8, 104w88888888888888888888, new_est);
                            GET_Value(9, 104w99999999999999999999, new_est);
                                //standard_metadata.egress_spec = 255;
                                //meta.sign = 0;
                                //meta.timestamp = ct;
                                //meta.flow_size_1 = old_est;
                                //meta.flow_size_2 = new_est;

                            if(new_est > old_est + CHANGE_THRESHOLD){
                                mask_queried_1.write(meta.bm_r1, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.timestamp = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + CHANGE_THRESHOLD){
                                mask_queried_1.write(meta.bm_r1, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.timestamp = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }


                    // transition to State 2
                    if(t_diff>INTERVAL_SIZE){
                        state_flag.write(0, 2);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                    }

                }

                // State 2
                // 1. Process packet & store packet counter into sketch 2 (CM sketch)
                // 2. Query Sketch 1 & Sketch 5 ( S1[i] - S4[i] ), for any flow "i"
                // 3. Transition to State 3

                else if (flag==2){


                    // Process packet in S2
                    cm_sketch2_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch2_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch2_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch2_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch2_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch2_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);

                    // CM threshold setting for sketch part
                    bit <32> est;
                    min_cnt(est, meta.qc_r1+meta.flow_cnt, meta.qc_r2+meta.flow_cnt, meta.qc_r3+meta.flow_cnt );

                    // Pipe part 
                    if (est > 10){
                        meta.carriedKey = meta.flowID;
                        meta.carriedCount = est;
                        meta.fromSketch = 1;
                        STAGE_N(2, 104w22222222222222222222);
                        STAGE_N(3, 104w33333333333333333333);
                    }


                    // Query S1-S5 if necessary
                        bit<2> index_1;


                        mask_queried_2.read(index_1, meta.bm_r1);


                        // Never Queried before
                        if(index_1!=1){


                            bit<32> old_est;
                            old_est = 0;
                            GET_Value(8, 104w88888888888888888888, old_est);
                            GET_Value(9, 104w99999999999999999999, old_est);

                            bit<32> new_est;
                            new_est = 0;
                            GET_Value(0, 104w00000000000000000000, new_est);
                            GET_Value(1, 104w11111111111111111111, new_est);


                            if(new_est > old_est + CHANGE_THRESHOLD){
                                mask_queried_2.write(meta.bm_r1, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.timestamp = ct;


                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + CHANGE_THRESHOLD){
                                mask_queried_2.write(meta.bm_r1, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.timestamp = ct;

                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }

                    // transition to State 3
                    if(t_diff>INTERVAL_SIZE){
                        state_flag.write(0, 3);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);
                    }                


                }

                // State 3
                // 1. Process packet & store packet counter into sketch 3 (CM sketch)
                // 2. Query Sketch 2 & Sketch 1 ( S2[i] - S1[i] ), for any flow "i"
                // 3. Transition to State 4
                else if(flag==3){

                    // Process packet in S3
                    cm_sketch3_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch3_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch3_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch3_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch3_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch3_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);           


                    // CM threshold setting for sketch part
                    bit <32> est;
                    min_cnt(est, meta.qc_r1+meta.flow_cnt, meta.qc_r2+meta.flow_cnt, meta.qc_r3+meta.flow_cnt );

                    // Pipe part 
                    if (est > 10){
                        meta.carriedKey = meta.flowID;
                        meta.carriedCount = est;
                        meta.fromSketch = 1;
                        STAGE_N(4, 104w44444444444444444444);
                        STAGE_N(5, 104w55555555555555555555);
                    }


                    // Query S2-S1 if necessary
                        bit<2> index_1;


                        mask_queried_3.read(index_1, meta.bm_r1);


                        // Never Queried before
                        if(index_1!=1){


                            bit<32> old_est;
                            old_est = 0;
                            GET_Value(0, 104w00000000000000000000, old_est);
                            GET_Value(1, 104w11111111111111111111, old_est);

                            bit<32> new_est;
                            new_est = 0;
                            GET_Value(2, 104w22222222222222222222, new_est);
                            GET_Value(3, 104w33333333333333333333, new_est);


                            if(new_est > old_est + CHANGE_THRESHOLD){
                                mask_queried_3.write(meta.bm_r1, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.timestamp = ct;

                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + CHANGE_THRESHOLD){
                                mask_queried_3.write(meta.bm_r1, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.timestamp = ct;

  

                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }
                    // transition to State 4
                    if(t_diff>INTERVAL_SIZE){
                        state_flag.write(0, 4);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                    }
                }

                // State 4
                // 1. Process packet & store packet counter into sketch 4 (CM sketch)
                // 2. Query Sketch 3 & Sketch 2 ( S3[i] - S2[i] ), for any flow "i"
                // 3. Transition to State 1            
                else if(flag==4){

                    // Process packet in S4
                    cm_sketch4_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch4_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch4_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch4_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch4_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch4_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);
   
                    // CM threshold setting for sketch part
                    bit <32> est;
                    min_cnt(est, meta.qc_r1+meta.flow_cnt, meta.qc_r2+meta.flow_cnt, meta.qc_r3+meta.flow_cnt );

                    // Pipe part 
                    if (est > 10){
                        meta.carriedKey = meta.flowID;
                        meta.carriedCount = est;
                        meta.fromSketch = 1;
                        STAGE_N(6, 104w66666666666666666666);
                        STAGE_N(7, 104w77777777777777777777);
                    }


                    // Query S3-S2 if necessary
                        bit<2> index_1;


                        mask_queried_4.read(index_1, meta.bm_r1);


                        // Never Queried before
                        if(index_1!=1){


                            bit<32> old_est;
                            old_est = 0;
                            GET_Value(2, 104w22222222222222222222, old_est);
                            GET_Value(3, 104w33333333333333333333, old_est);

                            bit<32> new_est;
                            new_est = 0;
                            GET_Value(4, 104w44444444444444444444, new_est);
                            GET_Value(5, 104w55555555555555555555, new_est);




                            if(new_est > old_est + CHANGE_THRESHOLD){
                                mask_queried_4.write(meta.bm_r1, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.timestamp = ct;

                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + CHANGE_THRESHOLD){
                                mask_queried_4.write(meta.bm_r1, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.timestamp = ct;

                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }
                    // transition to State 5
                    if(t_diff>INTERVAL_SIZE){
                        state_flag.write(0, 5);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                    }
                }

                // State 5
                // 1. Process packet & store packet counter into sketch 5 (CM sketch)
                // 2. Query Sketch 4 & Sketch 3 ( S4[i] - S3[i] ), for any flow "i"
                // 3. Transition to State 1            
                else if(flag==5){

                    // Process packet in S4
                    cm_sketch5_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch5_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch5_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch5_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch5_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch5_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);
   
                    // CM threshold setting for sketch part
                    bit <32> est;
                    min_cnt(est, meta.qc_r1+meta.flow_cnt, meta.qc_r2+meta.flow_cnt, meta.qc_r3+meta.flow_cnt );

                    // Pipe part 
                    if (est > 10){
                        meta.carriedKey = meta.flowID;
                        meta.carriedCount = est;
                        meta.fromSketch = 1;
                        STAGE_N(8, 104w88888888888888888888);
                        STAGE_N(9, 104w99999999999999999999);
                    }


                    // Query S4-S3 if necessary
                        bit<2> index_1;


                        mask_queried_5.read(index_1, meta.bm_r1);


                        // Never Queried before
                        if(index_1!=1){


                            bit<32> old_est;
                            old_est = 0;
                            GET_Value(4, 104w44444444444444444444, old_est);
                            GET_Value(5, 104w55555555555555555555, old_est);

                            bit<32> new_est;
                            new_est = 0;
                            GET_Value(6, 104w66666666666666666666, new_est);
                            GET_Value(7, 104w77777777777777777777, new_est);


                            if(new_est > old_est + CHANGE_THRESHOLD){
                                mask_queried_5.write(meta.bm_r1, 1);

                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.timestamp = ct;


                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + CHANGE_THRESHOLD){
                                mask_queried_5.write(meta.bm_r1, 1);

                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.timestamp = ct;

                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }
                    // transition to State 1
                    if(t_diff>INTERVAL_SIZE){
                        state_flag.write(0, 1);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                    }
                }
            //}
    }
}

control packetio_ingress(inout headers hdr,
                         inout standard_metadata_t standard_metadata) {
    apply {
        if (standard_metadata.ingress_port == 255) {
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
            hdr.packet_out.setInvalid();
            exit;
        }
    }
}

control packetio_egress(inout headers hdr,
                        inout metadata meta, 
                        inout standard_metadata_t standard_metadata ) {
    apply {
        if (standard_metadata.egress_port == 255) {
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = 4;
            hdr.packet_in.direction_id = 5;//meta.direction_id;

            //hdr.packet_in.sketch1_r1 = meta.sketch1_r1;
            //hdr.packet_in.sketch1_r2 = meta.sketch1_r2;
            //hdr.packet_in.sketch1_r3 = meta.sketch1_r3;

            //hdr.packet_in.sketch2_r1 = meta.sketch2_r1;
            //hdr.packet_in.sketch2_r2 = meta.sketch2_r2;
            //hdr.packet_in.sketch2_r3 = meta.sketch2_r3;

            hdr.packet_in.flow_size_1 = meta.flow_size_1;
            hdr.packet_in.flow_size_2 = meta.flow_size_2;
            hdr.packet_in.timestamp = meta.timestamp;
            //hdr.packet_in.sign = meta.sign;

        }
    }
}
/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        meta.direction_id = 2;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action send_to_controller(){
        standard_metadata.egress_spec = 255;
        meta.direction_id = 1;
        meta.flow_size_1 = 1200;
        meta.flow_size_2= 1200;
        meta.timestamp = 20000000;
        //clone3(CloneType.I2E, 500, standard_metadata);
    
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            send_to_controller;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }



    apply {
        packetio_ingress.apply(hdr, standard_metadata);

        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
            if(hdr.tcp.isValid() || hdr.udp.isValid()){
                Measurement.apply(hdr, meta, standard_metadata);
            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    action mark_ecn() {
        hdr.ipv4.ecn = 3;
    }
    apply {
        packetio_egress.apply(hdr, meta, standard_metadata);


    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
	      hdr.ipv4.diffserv,
	      hdr.ipv4.ecn,	
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);

    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
