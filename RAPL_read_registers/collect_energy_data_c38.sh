#!/bin/bash

filename=$1
filename2=$2

while [ 1 ]
do
    #cat /energy-data/intel-rapl/intel-rapl:0/energy_uj >> $filename #/sys/class/powercap/intel-rapl
    #cat /energy-data/node-c36/intel-rapl:0/intel-rapl:0:0/energy_uj >> $filename #only CPU cores
    cat /energy-data/node-c38/intel-rapl:0/energy_uj >> $filename #package
    (date +"%H:%M:%S.%3N") >> $filename
    cat /energy-data/node-c38/intel-rapl:0/intel-rapl:0:0/energy_uj >> $filename2 #DRAM
    (date +"%H:%M:%S.%3N") >> $filename2
    #sleep until next full second; copied from https://stackoverflow.com/questions/33204838/bash-command-wait-until-next-full-second
    sleep 0.$(printf '%04d' $((10000 - 10#$(date +%4N))))
done
