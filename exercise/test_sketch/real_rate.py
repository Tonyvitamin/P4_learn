import numpy as np
from  matplotlib import pyplot as plt


if __name__ == "__main__":
    x_f1 = []
    y_f1 = []
    with open('h1_h2.txt') as f:
        for idx, rate in enumerate(f):
            x_f1.append(idx)
            if float(rate) < 100.0:
                y_f1.append(float(rate)*1024*1024/1470.0)
            else:
                y_f1.append(float(rate)*1024/1470.0)

    x_f2 = []
    y_f2 = []
    with open('h1_h3.txt') as f:
        for idx, rate in enumerate(f):
            x_f2.append(idx)
            if float(rate) < 100.0:
                y_f2.append(float(rate)*1024*1024/1470.0)
            else:
                y_f2.append(float(rate)*1024/1470.0)    
                
    x_f3 = []
    y_f3 = []
    with open('h1_h4.txt') as f:
        for idx, rate in enumerate(f):
            x_f3.append(idx)
            if float(rate) < 100.0:
                y_f3.append(float(rate)*1024*1024/1470.0)
            else:
                y_f3.append(float(rate)*1024/1470.0)    
    
    x_f4 = []
    y_f4 = []
    with open('h1_h5.txt') as f:
        for idx, rate in enumerate(f):
            x_f4.append(idx)
            if float(rate) < 100.0:
                y_f4.append(float(rate)*1024*1024/1470.0)
            else:
                y_f4.append(float(rate)*1024/1470.0)    
    x_f5 = []
    y_f5 = []
    with open('h1_h6.txt') as f:
        for idx, rate in enumerate(f):
            x_f5.append(idx)
            if float(rate) < 100.0:
                y_f5.append(float(rate)*1024*1024/1470.0)
            else:
                y_f5.append(float(rate)*1024/1470.0)    
    
    
    plt.figure()
    plt.plot(x_f1, y_f1,  color='b', label='f1')
    plt.plot(x_f2, y_f2,  color='c', label='f2')
    plt.plot(x_f3, y_f3,  color='g', label='f3')
    plt.plot(x_f4, y_f4,  color='m', label='f4')
    plt.plot(x_f5, y_f5,  color='r', label='f5')

    plt.legend()
    plt.show()