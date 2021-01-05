import numpy as np
from  matplotlib import pyplot as plt
import os



                

def output_error(t1, t2):
    gt_flows_1_rate = [[0, 0.0]]
    gt_flows_2_rate = [[0, 0.0]]
    gt_flows_3_rate = [[0, 0.0]]
    gt_flows_4_rate = [[0, 0.0]]
    gt_flows_5_rate = [[0, 0.0]]

    gt_flows_1_change = []
    gt_flows_2_change = []
    gt_flows_3_change = []
    gt_flows_4_change = []
    gt_flows_5_change = []
    
    
    x = []
    ticks = []
    for idx in range(3, 8):
        filename = str(idx)+'_result.txt'

        throughput = 0
 
        with open(filename) as f:
            for timestamp, rate in enumerate(f):
                if float(rate) > 0.0:
                    if float(rate) > 20:
                       throughput = float(rate)/1000.0
                    else:
                        throughput = float(rate)

                    if idx == 3:           
                        gt_flows_1_rate.append([timestamp*2, throughput])
                    if idx == 4:
                        gt_flows_2_rate.append([(timestamp-1)*2, throughput])
                    if idx == 5:           
                        gt_flows_3_rate.append([(timestamp-2)*2, throughput])
                    if idx == 6:
                        gt_flows_4_rate.append([(timestamp-3)*2, throughput])
                    if idx == 7:           
                        gt_flows_5_rate.append([(timestamp-4)*2, throughput])
                     

    gt_flows_1_rate.pop(len(gt_flows_1_rate)-1)
    gt_flows_2_rate.pop(len(gt_flows_2_rate)-1)
    gt_flows_3_rate.pop(len(gt_flows_3_rate)-1)
    gt_flows_4_rate.pop(len(gt_flows_4_rate)-1)
    gt_flows_5_rate.pop(len(gt_flows_5_rate)-1)
    #print(gt_flows_1_rate)
    #print(gt_flows_2_rate)
    #print(len(gt_flows_1_rate))
    #print(len(gt_flows_2_rate))

    filename = './4/4.txt'
    de_flows_1_change = []
    idx = 0
    with open(filename) as f:
        prev = 0
        for line in f:
            tmp = line[:-1].split(' ')
            detection = [float(tmp[0]), float(tmp[1]), float(tmp[2])]

            de_flows_1_change.append([round(detection[2] - times[2]-2), round((detection[1] - detection[0])*1470.0*8/2.0/1000000, 2)])
            idx += 2


    print(de_flows_1_change)


    for prev, cur in zip(gt_flows_4_rate, gt_flows_4_rate[1:]):
        if abs(cur[1] - prev[1]) > 0.55:
            gt_flows_4_change.append( [cur[0], cur[1] - prev[1]] )

    print(gt_flows_4_change)


if __name__ == "__main__":
    #os.system('./parse_rate.sh')
    times = []
    with open('start_time.txt') as f:
        for time in f:
            times.append(float(time))
    output_error(times[0], times[1])
