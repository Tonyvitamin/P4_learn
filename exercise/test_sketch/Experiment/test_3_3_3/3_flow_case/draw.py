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
                ticks.append(str(idx)+'~'+str(idx+3)+' ')
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
    
def draw_comp(directory1, directory2, directory3):
    gt_flows_2_rate = []
    gt_flows_5_rate = []
    gt_flows_10_rate = []

    gt_flows_2_change = []
    gt_flows_5_change = []
    gt_flows_10_change = []

    x = []
    ticks = []
    for idx in range(3, 13):
        filename = str(idx)+'_result.txt'
        filename1 = directory1+filename
        filename2 = directory2+filename
        filename3 = directory3+filename
        throughput1 = 0
        throughput2 = 0
        throughput3 = 0
        with open(filename1) as f:
            for rate in f:
                if float(rate) > 20:
                    throughput1 = float(rate)/1000.0
                else:
                    throughput1 = float(rate)
                
        with open(filename2) as f:
            for rate in f:
                if float(rate) > 20:
                    throughput2 = float(rate)/1000.0
                else:
                    throughput2 = float(rate)
        with open(filename3) as f:
            for rate in f:
                if float(rate) > 20:
                    throughput3 = float(rate)/1000.0
                else:
                    throughput3 = float(rate)
        x.append(idx-2)        
        gt_flows_2_rate.append(throughput1)
        gt_flows_5_rate.append(throughput2) 
        gt_flows_10_rate.append(throughput3)
        ticks.append(idx-2)    
            




    plt.figure()
    plt.title('Throughput')
    plt.ylabel('Rate (Mbits/sec)')
    plt.xlabel('Flow ID')
    x = np.array(x)
    interval_1 = plt.bar(x, int_2_sec, 0.2, alpha=.4,  label='2 second', color="red")
    interval_2 = plt.bar(x+0.2, int_5_sec, 0.2, alpha=.4, label='5 second', color='blue')
    interval_3 = plt.bar(x+0.4, original, 0.2, alpha=.4, label='No sketch', color='green')

 

    plt.xticks(x+.1 / 2 ,ticks)

    plt.legend()
    plt.grid(True)
    filename = 'Throughput_comparison.png'

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
                ticks.append(str(idx)+'~'+str(idx+3)+' ')
                idx+=3

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
            de_y.append(round((detection[1] - detection[0])*1470.0*8/3.0/1000000, 2) )

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
                
                
        

if __name__ == "__main__":
    os.system('./parse_rate.sh')
    times = []
    with open('start_time.txt') as f:
        for time in f:
            times.append(float(time))
    draw_rate('3_result.txt', times[0], './1')
    draw_comp('3_result.txt', "./1/1.txt", times[0], './1')
    
    draw_rate('4_result.txt', times[1], './2')
    draw_comp('4_result.txt', "./2/2.txt", times[1], './2')
    
    draw_rate('5_result.txt', times[2], './3')
    draw_comp('5_result.txt', "./3/3.txt", times[2], './3')
    
    #draw_rate('6_result.txt', times[3], './4')
    #draw_comp('6_result.txt', "./4/4.txt", times[3], './4')
    
    #draw_rate('7_result.txt', times[4], './5')
    #draw_comp('7_result.txt', "./5/5.txt", times[4], './5')
    
    #draw_rate('8_result.txt', times[5], './6')
    #draw_comp('8_result.txt', "./6/6.txt", times[5], './6')
    
    #draw_rate('9_result.txt', times[6], './7')
    #draw_comp('9_result.txt', "./7/7.txt", times[6], './7')
    
    #draw_rate('10_result.txt', times[7], './8')
    #draw_comp('10_result.txt', "./8/8.txt", times[7], './8')
    
    #draw_rate('11_result.txt', times[8], './9')
    #draw_comp('11_result.txt', "./9/9.txt", times[8], './9')    
    
    #draw_rate('12_result.txt', times[9], './10')
    #draw_comp('12_result.txt', "./10/10.txt", times[9], './10')