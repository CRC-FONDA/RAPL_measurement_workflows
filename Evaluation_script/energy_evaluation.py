import sys
import re
import os
import seaborn as sns
import pandas as pd
from datetime import datetime
from datetime import timedelta
#import datetime
import matplotlib.pyplot as plt
import plotly.express as px
import plotly.io as pio
from scipy.stats import pearsonr
import plotly.graph_objects as go

rapl_max_value_overflow = 262143328850
rapl_DRAM_max_value_overflow = 65712999613

# Get the directory where the script is located
script_dir = os.path.dirname(os.path.abspath(__file__))

#taskwise analysis in task_data
task_data = []
#trace = "example-results/trace_example"
#rapl_measurements = "example-results/measurements_example.txt"
#trace = "RNASeq_energy/shtest_16CPU_bowtie2/third_run_with_DRAM/exp_shtest_trace_run"
#rapl_measurements = "RNASeq_energy/shtest_16CPU_bowtie2/third_run_with_DRAM/energy_log_c36.txt"
trace = os.path.join(script_dir, "exp_shtest_trace_run")
rapl_measurements1 = os.path.join(script_dir, "energy_log_c37.txt")
rapl_measurements2 = os.path.join(script_dir, "energy_log_c38.txt")
DRAM_measurements1 = os.path.join(script_dir, "energy_DRAM_log_c37.txt")
DRAM_measurements2 = os.path.join(script_dir, "energy_DRAM_log_c38.txt")
#task_node = os.path.join(script_dir, "task_node_log.txt")



with open(trace) as file:
    lines = [line.rstrip() for line in file]

transformed = []
firstline = lines[0].split("\t")
firstline = firstline[:-4]

for x in range(len(lines)):
        if(x>0):
            line = lines[x].split("\t")
            line[0]
            try:
                first = int(line[0])
            except ValueError:
                first = 0
            if(first > 0): #only keep line if first value is int
                transformed.append(line)

df = pd.DataFrame(transformed, columns = firstline) #convert to pandas to save to csv

#print(df)

#read rapl measurements (node 37)
with open(rapl_measurements1) as file:
    measurements = [line.rstrip() for line in file]

rapl_raw = []
time_points = []
rapl_with_time1 = []

for i in range(len(measurements)):
    if (i % 2 == 0):
        rapl_raw.append(int(measurements[i]))
    if (i % 2 == 1):
        time_points.append(datetime.strptime(measurements[i][0:8], "%H:%M:%S"))

for j in range(len(rapl_raw)):
    rapl_with_time1.append((rapl_raw[j], time_points[j]))

#read rapl measurements (node 38)
with open(rapl_measurements2) as file:
    measurements = [line.rstrip() for line in file]

rapl_raw = []
time_points = []
rapl_with_time2 = []

for i in range(len(measurements)):
    if (i % 2 == 0):
        rapl_raw.append(int(measurements[i]))
    if (i % 2 == 1):
        time_points.append(datetime.strptime(measurements[i][0:8], "%H:%M:%S"))

for j in range(len(rapl_raw)):
    rapl_with_time2.append((rapl_raw[j], time_points[j]))


#read DRAM measurements (node 37)
with open(DRAM_measurements1) as file:
    measurements = [line.rstrip() for line in file]

rapl_raw = []
time_points = []
DRAM_with_time1 = []

for i in range(len(measurements)):
    if (i % 2 == 0):
        rapl_raw.append(int(measurements[i]))
    if (i % 2 == 1):
        time_points.append(datetime.strptime(measurements[i][0:8], "%H:%M:%S"))

for j in range(len(rapl_raw)):
    DRAM_with_time1.append((rapl_raw[j], time_points[j]))


#read DRAM measurements (node 38)
with open(DRAM_measurements2) as file:
    measurements = [line.rstrip() for line in file]

rapl_raw = []
time_points = []
DRAM_with_time2 = []

for i in range(len(measurements)):
    if (i % 2 == 0):
        rapl_raw.append(int(measurements[i]))
    if (i % 2 == 1):
        time_points.append(datetime.strptime(measurements[i][0:8], "%H:%M:%S"))

for j in range(len(rapl_raw)):
    DRAM_with_time2.append((rapl_raw[j], time_points[j]))

#print(rapl_with_time)
#print(rapl_with_time2)
#print(DRAM_with_time)
#print(DRAM_with_time2)

#read nodes information
# Read the file and parse lines
#with open(task_node, "r") as file:
#    lines = file.readlines()

# Extract header (first line)
#header = lines[0].strip().split(",")

# Process the remaining lines
#data = [line.strip().split(",") for line in lines[1:]]

# Convert to DataFrame
#nodes_df = pd.DataFrame(data, columns=header)

# Convert the 'Timestamp' column to datetime
#nodes_df['Timestamp'] = pd.to_datetime(nodes_df['Timestamp'])

# Display the DataFrame
#print(nodes_df)

#print(df)
#print(nodes_df)
#print(rapl_with_time)
#print(nodes_df['Task Name'][2])
#print(nodes_df['Task Name'].tolist())
#print(df.to_markdown(index=False))

start = df["start"].tolist()
end = df["complete"].tolist()
processes = df["process"].tolist()
process_start_stamps = []
process_end_stamps = []
time_d = []
package_energy_per_task = []
DRAM_energy_per_task = []
energy_per_task = []
durations= df["duration"].tolist()

#energy_unit_joules = 15.3e-6  # 15.3 µJ converted to joules
energy_unit_joules = 15.3e-7 #Likely not the correct RAPL scaling factor for Intel(R) Xeon(R) Silver 4314 CPU

#Find on which node the task was executed
#tasks = df["native_id"]
#task_names = nodes_df["Task Name"]
#nodes = []
#for t in range(len(tasks)):
#    for n in range(len(task_names)):
#        if(tasks[t] == task_names[n]):
#            nodes.append(nodes_df["Node"][n])
#            break

#df["Node"] = nodes
#print(df)

#duration of processes to seconds
for k in range(len(start)):
    process_start_stamps.append(datetime.strptime(start[k][11:], "%H:%M:%S.%f"))
    process_end_stamps.append(datetime.strptime(end[k][11:], "%H:%M:%S.%f"))
    time_d.append((process_end_stamps[k] - process_start_stamps[k]).total_seconds())
    while(time_d[k] < 0):
        time_d[k] += 86400
    start_process = process_start_stamps[k]
    end_process = process_end_stamps[k]
    #print(df["start"])
    #print(df["complete"])
    #print(start_process)
    #print(end_process)
    calculated_consumption = False
    pos = 0
    start_point_found = False
    energy_consumed = 0
    start_energy = 0
    overflows = 0

    if(df["hostname"][k] == "hu-worker-c37"):
        rapl_with_time = rapl_with_time1
        DRAM_with_time = DRAM_with_time1
    elif(df["hostname"][k] == "hu-worker-c38"):
        rapl_with_time = rapl_with_time2
        DRAM_with_time = DRAM_with_time2
    else:
        rapl_with_time = []
        DRAM_with_time = []
        print("Node not found: " + df["hostname"][k])

    while(calculated_consumption==False):
        if(start_point_found==False):
            if(start_process == rapl_with_time[pos][1]):
                start_point_found = True
                start_activity = pos
                start_energy = rapl_with_time[pos][0]
                pos = pos - 1
        elif(start_point_found==True):
            if(rapl_with_time[pos][0] < rapl_with_time[pos - 1][0]):
                overflows += 1
            if(end_process == rapl_with_time[pos][1]):
                end_activity = pos
                energy_consumed = (rapl_with_time[pos][0] + (overflows * rapl_max_value_overflow) - start_energy) * energy_unit_joules
                calculated_consumption = True
        pos += 1

    #package_energy_per_task.append(energy_consumed/1000000000)
    package_energy_per_task.append(energy_consumed)

    calculated_consumption = False
    pos = 0
    start_point_found = False
    DRAM_energy_consumed = 0
    start_energy = 0
    overflows = 0

    while(calculated_consumption==False):
        if(start_point_found==False):
            if(start_process == DRAM_with_time[pos][1]):
                start_point_found = True
                start_activity = pos
                start_energy = DRAM_with_time[pos][0]
                pos = pos - 1
        elif(start_point_found==True):
            if(DRAM_with_time[pos][0] < DRAM_with_time[pos - 1][0]):
                overflows += 1
            if(end_process == DRAM_with_time[pos][1]):
                end_activity = pos
                DRAM_energy_consumed = (DRAM_with_time[pos][0] + (overflows * rapl_DRAM_max_value_overflow) - start_energy) * energy_unit_joules
                calculated_consumption = True
        pos += 1

    #DRAM_energy_per_task.append(DRAM_energy_consumed/1000000000)
    #energy_per_task.append((energy_consumed + DRAM_energy_consumed)/1000000000)
    DRAM_energy_per_task.append(DRAM_energy_consumed)
    energy_per_task.append(energy_consumed + DRAM_energy_consumed)


df["duration"] = time_d
df["CPU_energy_consumption"] = package_energy_per_task
df["DRAM_energy_consumption"] = DRAM_energy_per_task
df["energy_consumption"] = energy_per_task
power_per_task = []
for r in range(len(time_d)):
    if(time_d[r] > 0):
        power_per_task.append(energy_per_task[r]/time_d[r])
    else:
        power_per_task.append(0)
df["avg_power"] = power_per_task

#save processed data to task_data
task_data = df

#convert CPU usage (%) to float
tmp = task_data["%cpu"].tolist()
res = []
for el in tmp:
    res.append(float(el[:-1]))
task_data["%cpu"] = res

#transform data from MB/GB to MB; from str to float
categories = ["read_bytes", "write_bytes", "rss", "vmem","rchar","wchar"]
for el in categories:
    tmp = task_data[el].tolist()
    final = []
    for element in tmp:
        try:
            x = float(element)
        except ValueError:
            y = element.split(" ")
            if(y[-1]=="MB"):
                x = float(y[0])
            elif(y[-1]=="GB"):
                x = float(y[0]) * 1000
            elif(y[-1]=="KB"):
                x = float(y[0]) / 1000
            elif(y[-1]=="B"):
                x = float(y[0]) / 1000000
            else:
                raise Exception("object is not int, KB, MB, GB: " + element)
        final.append(x)
    task_data[el] = final
task_data.to_csv("task_data.csv")
#print(task_data)
columns = ['name','realtime','hostname','%cpu','%mem','peak_rss','CPU_energy_consumption','DRAM_energy_consumption','energy_consumption','avg_power']
#print(task_data[columns_to_display].to_string(index=False))
print("\nTask stats (Energy in Joule and power consumption in Watt):")
print(task_data[columns].to_markdown(index=False))

#Laufzeit und Energieverbrauch pro gesamtem Workflow berechnen, in neuem DF speichern.
#######################################################################################################################################

import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

wf_data = task_data.agg({"start": min, \
                          "complete": max, \
                          "read_bytes": sum,\
                          "write_bytes": sum,\
                          "rss": sum, \
                          "vmem": sum,\
                          "rchar": sum,\
                          "wchar": sum,\
                          "CPU_energy_consumption": sum,\
                          "DRAM_energy_consumption": sum,\
                          "energy_consumption": sum}).to_frame().T
#print(wf_data)
#print(wf_data.to_markdown(index=False))

start = wf_data["start"].tolist()
end = wf_data["complete"].tolist()
start_stamps = []
end_stamps = []
time_d = []
for k in range(len(start)):
    start_stamps.append(datetime.strptime(start[k][11:], "%H:%M:%S.%f"))
    end_stamps.append(datetime.strptime(end[k][11:], "%H:%M:%S.%f"))
    time_d.append((end_stamps[k] - start_stamps[k]).total_seconds())
    while(time_d[k] < 0):
                    time_d[k] += 86400
import datetime
wf_data["wf_duration"] = datetime.timedelta(seconds=time_d[0])
wf_data.reset_index(inplace=True)


avg_cpu = []
tasks_wf = task_data
cpus = tasks_wf["%cpu"].tolist()
durations = tasks_wf["duration"].tolist()
added = 0
for z in range(len(cpus)):
    added += cpus[z]*durations[z]
avg = added / sum(durations)
avg_cpu.append(avg)
wf_data["avg_cpu_wf"] = avg_cpu


workflow_consumption = wf_data["energy_consumption"][0]
avg_power = []

#for r in range(len(workflow_consumption)):
avg_power.append(workflow_consumption/time_d[0])

wf_data["avg_power_wf"] = avg_power


#tmp = task_data["avg_power"].tolist()
#task_data["avg_power"] = [1000 * el for el in tmp]
wf_data.reset_index(inplace=True)
wf_data.to_csv("wf_data.csv")

columns = ['start','complete','wf_duration','avg_cpu_wf','CPU_energy_consumption','DRAM_energy_consumption','energy_consumption','avg_power_wf']
print("\nWorkflow stats (Energy in Joule and power consumption in Watt):")
print(wf_data[columns].to_markdown(index=False))

#########################################################################################################################################
#########################################################################################################################################

from datetime import datetime
start = df["start"].tolist()
end = df["complete"].tolist()
processes = df["process"].tolist()
time_d = []
package_energy_per_task = []
DRAM_energy_per_task = []
energy_per_task = []
durations= df["duration"].tolist()

rapl1 = 0
rapl2 = 0
DRAM1 = 0
DRAM2 = 0

#duration of processes to seconds
k = 0
while (k < 2):
    start_process = min(process_start_stamps)
    end_process = max(process_end_stamps)
    #print(start_process)
    #print(end_process)
    calculated_consumption = False
    pos = 0
    start_point_found = False
    energy_consumed = 0
    start_energy = 0
    overflows = 0

    if(k == 0):
        rapl_with_time = rapl_with_time1
        DRAM_with_time = DRAM_with_time1
    elif(k == 1):
        rapl_with_time = rapl_with_time2
        DRAM_with_time = DRAM_with_time2
    else:
        rapl_with_time = []
        DRAM_with_time = []

    while(calculated_consumption==False):
        if(start_point_found==False):
            if(start_process == rapl_with_time[pos][1]):
                start_point_found = True
                start_activity = pos
                start_energy = rapl_with_time[pos][0]
                pos = pos - 1
        elif(start_point_found==True):
            if(rapl_with_time[pos][0] < rapl_with_time[pos - 1][0]):
                overflows += 1
            if(end_process == rapl_with_time[pos][1]):
                end_activity = pos
                energy_consumed = (rapl_with_time[pos][0] + (overflows * rapl_max_value_overflow) - start_energy) * energy_unit_joules
                calculated_consumption = True
        pos += 1

    if(k == 0):
        rapl1 = energy_consumed
        #print("rapl1: ", rapl1)
    elif(k == 1):
        rapl2 = energy_consumed
        #print("rapl2: ", rapl2)

    calculated_consumption = False
    pos = 0
    start_point_found = False
    DRAM_energy_consumed = 0
    start_energy = 0
    overflows = 0

    while(calculated_consumption==False):
        if(start_point_found==False):
            if(start_process == DRAM_with_time[pos][1]):
                start_point_found = True
                start_activity = pos
                start_energy = DRAM_with_time[pos][0]
        elif(start_point_found==True):
            if(DRAM_with_time[pos][0] < DRAM_with_time[pos - 1][0]):
                overflows += 1
            if(end_process == DRAM_with_time[pos][1]):
                end_activity = pos
                DRAM_energy_consumed = (DRAM_with_time[pos][0] + (overflows * rapl_DRAM_max_value_overflow) - start_energy) * energy_unit_joules
                calculated_consumption = True
        pos += 1

    if(k == 0):
        DRAM1 = DRAM_energy_consumed
        #print("DRAM1: ", DRAM1)
    elif(k == 1):
        DRAM2 = DRAM_energy_consumed
        #print("DRAM2: ", DRAM2)
    energy_per_task.append(energy_consumed + DRAM_energy_consumed)

    k = k + 1

total_wf_energy = rapl1 + rapl2 + DRAM1 + DRAM2
print("\nTotal Workflow Energy Consumption (including idle times during execution): ", round(total_wf_energy,2), "Joules")