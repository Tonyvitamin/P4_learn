import numpy as np
from  matplotlib import pyplot as plt
import os


def draw_rate(gt_file, start_time, directory):
    gt_x = []
    gt_y = []
    idx = 0
    ticks = []
    with open(gt_file) as f:
        for rate in f:
            if float(rate) > 0.0:
                gt_x.append(idx)
                if float(rate) > 20:
                    gt_y.append(float(rate)/1000.0)
                else:
                    gt_y.append(float(rate))
                ticks.append(str(idx)+'~'+str(idx+2)+' ')
                idx+=2

    gt_x.pop(len(gt_x)-1)
    gt_y.pop(len(gt_y)-1)

    plt.figure()
    plt.title('Flow Rate')
    plt.ylabel('Rate (Mbits/sec)')
    plt.xlabel('Time')
    plt.bar(gt_x, gt_y, label='Flow 1', color="red")

    for a,b in zip(gt_x, gt_y):
        plt.text(a, b, b,  ha='center')    
    
    plt.xticks(gt_x, ticks)
    ax = plt.gca()

    for label in ax.xaxis.get_ticklabels():
        label.set_rotation(45)

    plt.legend()
    filename = directory + '/flow_rate.png'

    plt.savefig(filename)
    plt.close()   
    
    
    
def draw_comp(gt_file, de_file, start_time, directory):
    
    gt_x = []
    tmp_y = [0.0]
    gt_y = []
    idx = 0
    ticks = []
    with open(gt_file) as f:
        for rate in f:
            if float(rate) > 0.0:
                gt_x.append(idx)
                if float(rate) > 20.0:
                    tmp_y.append(float(rate)/1000.0)
                else:
                    tmp_y.append(float(rate))
                ticks.append(str(idx)+'~'+str(idx+2)+' ')
                idx+=2

    tmp_y.pop(len(tmp_y)-1)

    for i in range(len(tmp_y)-1):
        gt_y.append(round(tmp_y[i+1] - tmp_y[i], 2))
    gt_x.pop(len(gt_x)-1)
    print(gt_x)
    print(gt_y)
    
    de_x = []
    de_y = []        
    with open(de_file) as f:
        for line in f:
            tmp = line[:-1].split(' ')
            detection = [float(tmp[0]), float(tmp[1]), float(tmp[2])]
            de_x.append(detection[2] - start_time)
            de_y.append(round((detection[1] - detection[0])*1470.0*8/2.0/1000000, 2) )

    print(de_x)
    print(de_y)    
    plt.figure()
    plt.title('Flow Rate variation' )
    plt.ylabel('Rate variation (Mbits/sec)')
    plt.xlabel('Time')
    plt.scatter(gt_x, gt_y, label='Real change', color="red")
    plt.scatter(de_x, de_y, label='Detected change', color="blue")

    for a,b in zip(gt_x, gt_y):
        plt.text(a, b, b,  ha='center') 

    for a,b in zip(de_x, de_y):
        plt.text(a, b, b,  ha='center') 
    #plt.xticks(gt_x, ticks)
    #ax = plt.gca()

    #for label in ax.xaxis.get_ticklabels():
    #    label.set_rotation(45)
    plt.legend()
    filename = directory + '/flow_detection.png'
    plt.savefig(filename)
    plt.close()     
                
                

def output_error(t1, t2):
    gt_flows_1_rate = [[0, 0.0]]
    gt_flows_2_rate = [[0, 0.0]]


    gt_flows_1_change = []
    gt_flows_2_change = []


    x = []
    ticks = []
    for idx in range(3, 5):
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
    gt_flows_1_rate.pop(len(gt_flows_1_rate)-1)
    gt_flows_2_rate.pop(len(gt_flows_2_rate)-1)
    #print(gt_flows_1_rate)
    #print(gt_flows_2_rate)
    #print(len(gt_flows_1_rate))
    #print(len(gt_flows_2_rate))

    filename = './2/2.txt'
    de_flows_1_change = []
    idx = 0
    with open(filename) as f:
        prev = 0
        for line in f:
            tmp = line[:-1].split(' ')
            detection = [float(tmp[0]), float(tmp[1]), float(tmp[2])]
            while round(detection[2] - prev) > 2 and idx != 0:
                de_flows_1_change.append([idx, 0.0])
                prev += 2
                idx += 2
            prev = detection[2]
            de_flows_1_change.append([round(detection[2] - times[1]-2), round((detection[1] - detection[0])*1470.0*8/2.0/1000000, 2)])
            idx += 2
    for i in range(len(de_flows_1_change), 15):
        de_flows_1_change.append([i*2, 0.0])

    print(de_flows_1_change)


    for prev, cur in zip(gt_flows_2_rate, gt_flows_2_rate[1:]):
        if abs(cur[1] - prev[1]) > 0.55:
            gt_flows_2_change.append( [cur[0], cur[1] - prev[1]] )
        else:
            gt_flows_2_change.append([cur[0], 0.0])
    print(gt_flows_2_change)


if __name__ == "__main__":
    #os.system('./parse_rate.sh')
    times = []
    with open('start_time.txt') as f:
        for time in f:
            times.append(float(time))
    output_error(times[0], times[1])
