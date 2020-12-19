import numpy as np
from  matplotlib import pyplot as plt
import os


def draw_rate(gt_file, start_time):
    gt_x = []
    gt_y = []
    idx = 0
    ticks = []
    with open(gt_file) as f:
        for rate in f:
            if float(rate) > 0.0:
                gt_x.append(idx)
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
    plt.savefig('flow_rate.png')
    plt.close()   
    
    
    
def draw_comp(gt_file, de_file, start_time):
    
    gt_x = []
    tmp_y = [0.0]
    gt_y = []
    idx = 0
    ticks = []
    with open(gt_file) as f:
        for rate in f:
            if float(rate) > 0.0:
                gt_x.append(idx)
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
    plt.savefig('flow_detection.png')
    plt.close()     
                
                
        

if __name__ == "__main__":
    os.system('./parse_rate.sh')
    times = []
    with open('start_time.txt') as f:
        for time in f:
            times.append(float(time))
    draw_rate('4_result.txt', times[0])
    draw_comp('4_result.txt', "./('10.0.1.1', '10.0.2.2', 60314, 5001, 17)/('10.0.1.1', '10.0.2.2', 60314, 5001, 17).txt", times[1])
    #draw_comp('4_result.txt', "('10.0.1.1', '10.0.2.2', 52852, 5001, 17)/('10.0.1.1', '10.0.2.2', 52852, 5001, 17).txt", times[1])
    #draw_comp('5_result.txt', "('10.0.1.1', '10.0.2.2', 45493, 5001, 17).txt", times[2])
    #draw_comp('6_result.txt', "('10.0.1.1', '10.0.2.2', 45493, 5001, 17).txt", times[3])
    #draw_comp('7_result.txt', "('10.0.1.1', '10.0.2.2', 45493, 5001, 17).txt", times[4])