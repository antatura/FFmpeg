# Requirements: ffprobe.exe, matplotlib, numpy


import subprocess
import argparse
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime


parser = argparse.ArgumentParser()
parser.add_argument('input')
args = parser.parse_args()

print('\nRunning...')
startime = datetime.now()

csv = subprocess.Popen(
    ['ffprobe','-v','error','-select_streams','v:0','-show_entries',\
     'frame=pkt_pts_time,pkt_size','-of','csv=p=0',args.input],
    stdout=subprocess.PIPE,shell=True)

duration_b = subprocess.Popen(
    ['ffprobe','-v','error','-select_streams','v:0','-show_entries',\
     'stream=duration','-of','csv=p=0',args.input],
    stdout=subprocess.PIPE,shell=True)	

csv_list = list(csv.stdout)
# [b'0.000000,182002\r\n', b'0.016667,117\r\n', b'0.033333,189\r\n'......]
duration_list = list(duration_b.stdout)


sec = 1
s_size = 0
list_size = []

for a in range(len(csv_list)):
    if csv_list[a] != b'\r\n':
        aa = str(csv_list[a],'ascii')    # '0.016667,117\r\n'
        a_ = aa.index(',')
        ax = float(aa[:a_])    
        ay = int(aa[a_+1:-2])    # ax=0.016667, ay=117
        if ax < sec:
            s_size += ay*8/1000    # kbit
        else:
            list_size.append(s_size)
            s_size = ay*8/1000
            sec += 1        
list_size.append(s_size)


duration = float(str(duration_list[0],'ascii'))
maxi = int(np.max(list_size))
mean = int(np.sum(list_size)/duration)

endtime = datetime.now()
dur = str(endtime-startime)
w_title = '['+dur+']'+' '*3+args.input


plt.figure().canvas.set_window_title(w_title)
plt.title("Bitrate Histogram",fontsize=16,fontweight='bold')
plt.xlabel("time",fontsize=12,fontweight='bold')
plt.ylabel("kbit per sec",fontsize=12,fontweight='bold')
plt.grid(True)
plt.bar(range(len(list_size)),list_size,width=1,ec='#195f90',align='edge')
plt.axhline(y=maxi,color='r',lw=2,ls='--',label='max: '+str(maxi))
plt.axhline(y=mean,color='g',lw=2,ls='--',label='mean: '+str(mean))
plt.axvline(x=ax,color='b',lw=3,ls=':')
plt.legend(prop={'size': 18})
plt.show()

        


