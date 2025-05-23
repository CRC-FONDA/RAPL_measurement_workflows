# RAPL Measurement Strategies for Scientific Workflows on Kubernetes Clusters

This repository contains the code, configuration files, and documentation for four different methods to measure energy consumption using Intel RAPL during the execution of scientific workflows on a compute cluster managed by Kubernetes, using the Nextflow workflow engine.

## Project Overview

This project explores strategies to measure energy consumption of workflow tasks in distributed environments. It presents and implements three RAPL-based measurement strategies and one strategy based on data from IPMI:

1. **Task-Based Measurement** – Uses workflow tasks to control RAPL measurement.
2. **Shell Script Wrapping** – Wraps the workflow execution with a controlling script.
3. **Nextflow Plugin Integration** – A custom Nextflow plugin automates measurement.
4. **Prometheus Monitoring** – Uses Prometheus to record power usage with system-level metrics.

Each method is evaluated for accuracy, completeness, portability, and ease of use, and the findings are detailed in the included research report.

## Repository Structure

```
Pods/                      # Pod definitions for deploying measurement and workflow containers
RAPL_read_registers/       # Bash scripts to read RAPL values from CPU and DRAM domains
Task_based/                # Scripts and instructions for task-based RAPL measurement
Shell_script/              # Shell script for wrapping workflow execution and energy logging
Plugin/                    # Code and configuration for Nextflow plugin-based approach
Prometheus/                # Instructions for querying Prometheus for energy metrics
Evaluation_script/         # Python script for post-processing energy log files
```

## Files of Interest

- `RAPL_Measurement_Strategies.pdf` – Full research report detailing all methods and experimental results.
- `Instructions.txt` – Step-by-step guide for setting up and executing workflows with energy measurement.
- `energy_evaluation.py` – Extracts workflow and task-level energy data from RAPL logs and Nextflow traces.

## Prerequisites

- Kubernetes and Docker setup on the compute cluster.
- Nextflow configured with Kubernetes as executor.
- Appropriate pod configurations and persistent volume claims (PVCs).
- Root access for RAPL readings or Prometheus configured on the cluster.

## How to Use

1. **Set Up the Cluster**
   - Deploy pods using YAML files in `Pods/`.
   - Mount PVCs for shared storage and logs.
   - Place scripts for reading RAPL counters (in `RAPL_read_registers/`) on the cluster.

2. **Choose a Measurement Strategy**
   - Follow the setup instructions in the respective folder.
   - See `Instructions.txt` for full details.

3. **Run the Workflow**
   - Use a Nextflow workflow (e.g., from nf-core) with Kubernetes executor.
   - Ensure trace file generation is enabled for post-processing.

4. **Evaluate Results**
   - Use `energy_evaluation.py` to extract energy consumption from logs and traces.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Citation

If you use this project in your own research, please cite our paper. See [CITATION.cff](CITATION.cff).

## Authors

- Philipp Thamm
- Ulf Leser
