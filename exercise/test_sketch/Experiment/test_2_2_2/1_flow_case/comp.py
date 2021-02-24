import numpy as np
from  matplotlib import pyplot as plt
import seaborn as sns
import pandas as pd 
import os

def draw_flow_fig():
    var =  [0.01, 0.0, 0.01, 0.0,  \
            1.92, 1.51, 1.69, 0.88, 2.98, 0.32, 0.03, 0.07, 0.02, 4.88, 1.51, 0.76, 0.56, 1.27, 0.35, 0.01, 0.0, 0.0, 0.13, 0.01, 0.0, 3.14, 0.77, 0.81, \
            0.01, 0.01, 0.01, 0.01, 1.9, 0.2, 0.42, 0.01, 0.0, 2.18, 0.03, 0.28, 0.28, 0.34, 0.33, \
            0.0, 0.0, 1.65,  1.17, 0.63, 1.58, 0.63, 0.85, 0.3, 0.35, 0.28, 0.27, \
            0.89, 0.71, 0.47, 1.0, 0.7, 0.56, 0.6, 0.01, 1.14, 0.55, 0.85, 0.1, \
            0.58, 0.1, 1.33, 0.9, 0.38, 1.05, 0.6, 0.15, 0.05, 0.0, 0.07, 0.89, 2.25, 0.32, 0.07
            ]
    f_size = ["2 flows", "2 flows", "2 flows", "2 flows", \
              "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", \
              "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", \
              "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", "5 flows", \
              "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", \
              "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", \
              "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", \
              "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", \
              "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", "10 flows", \
              "10 flows", "10 flows", "10 flows", "10 flows"
            ]
    dat = {'Error size': var, 'Flow size': f_size}
    df = pd.DataFrame(dat)
    sns.set(style="whitegrid")
    ax = sns.boxplot(x='Flow size', y='Error size', data=df, width=0.2, palette="Set3")
    ax = sns.swarmplot(x='Flow size', y='Error size', data=df, color='red')
    fig = ax.get_figure()
    fig.savefig("comparsion_flow_size.png")

    
if __name__ == "__main__":
    draw_flow_fig()
