import numpy as np
from  matplotlib import pyplot as plt
import os

def createLabels(data):
    for item in data:
        height = item.get_height()
        plt.text(
            item.get_x()+item.get_width()/2., 
            height*1, 
            '%.2f' % float(height),
            ha = "center",
            va = "bottom",
        )

def draw_rate_comp(directory1, directory2):
    
    int_2_sec = []
    int_5_sec = []
    original = []
    x = []
    ticks = []
    for idx in range(3, 13):
        filename = str(idx)+'_result.txt'
        filename1 = directory1+filename
        filename2 = directory2+filename
        filename3 = './'+filename
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
        int_2_sec.append(throughput1)
        int_5_sec.append(throughput2) 
        original.append(throughput3)
        ticks.append(idx-2)    
            




    plt.figure()
    plt.title('Throughput')
    plt.ylabel('Rate (Mbits/sec)')
    plt.xlabel('Flow ID')
    x = np.array(x)
    interval_1 = plt.bar(x, int_2_sec, 0.2, alpha=.4,  label='2 second', color="red")
    interval_2 = plt.bar(x+0.2, int_5_sec, 0.2, alpha=.4, label='5 second', color='blue')
    interval_3 = plt.bar(x+0.4, original, 0.2, alpha=.4, label='No sketch', color='green')

    #createLabels(interval_1)
    #createLabels(interval_2)
    #for a,b in zip(x, int_2_sec):
    #    plt.text(a, b, b,  ha='center')    
    
    #for a,b in zip(x, int_5_sec):
    #    plt.text(a, b, b,  ha='center')       

    plt.xticks(x+.1 / 2 ,ticks)


    #plt.xticks(gt_x, ticks)
    #ax = plt.gca()

    #for label in ax.xaxis.get_ticklabels():
    #    label.set_rotation(45)

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
                ticks.append(str(idx)+'~'+str(idx+1)+' ')
                idx+=1

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
            de_y.append(round((detection[1] - detection[0])*1470.0*8/5.0/1000000, 2) )

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
    #os.system('./parse_rate.sh')
    #times = []
    #with open('start_time.txt') as f:
    #    for time in f:
    #        times.append(float(time))
    draw_rate_comp('./2_sec/', './5_sec/')
