#!/bin/bash

# Delete old data
echo "Alte Dateien werden gelöscht."
kubectl exec -n thammphi -it thammphi-pod-c37 -- rm -f /private-data/start_signal.txt
kubectl exec -n thammphi -it thammphi-pod-c37 -- rm -f /private-data/stop_signal.txt
kubectl exec -n thammphi -it thammphi-pod-c37 -- rm -rf /private-data/philipp/
kubectl exec -n thammphi -it thammphi-pod-c37 -- rm -f /private-data/energy_log.txt
kubectl exec -n thammphi -it thammphi-pod-c37 -- rm -f /private-data/energy_log_c37.txt
kubectl exec -n thammphi -it thammphi-pod-c37 -- rm -f /private-data/energy_log_c38.txt
kubectl exec -n thammphi -it thammphi-pod-c37 -- rm -f /private-data/energy_DRAM_log_c37.txt
kubectl exec -n thammphi -it thammphi-pod-c37 -- rm -f /private-data/energy_DRAM_log_c38.txt

#echo "Ausführung von auto_collect_energy_data_cXX.sh auf allen Nodes."
#kubectl exec -n thammphi -it thammphi-pod-c37 -- bash /private-data/auto_collect_energy_data_c37.sh &
#kubectl exec -n thammphi -it thammphi-pod-c38 -- bash /private-data/auto_collect_energy_data_c38.sh &

echo "Ausführung von collect_energy_data_cXX.sh auf allen Nodes."
kubectl exec -n thammphi thammphi-pod-c37 -- bash /private-data/collect_energy_data_c37.sh /private-data/energy_log_c37.txt /private-data/energy_DRAM_log_c37.txt &
kubectl exec -n thammphi thammphi-pod-c38 -- bash /private-data/collect_energy_data_c38.sh /private-data/energy_log_c38.txt /private-data/energy_DRAM_log_c38.txt &

echo "Überprüfung, ob die Energiemessung gestartet wurde."
kubectl exec -n thammphi -it thammphi-pod-c37 -- pgrep -af collect_energy_data_c37.sh
kubectl exec -n thammphi -it thammphi-pod-c38 -- pgrep -af collect_energy_data_c38.sh

echo "Warte bis Daten aus Energiemessung vorhanden sind."
sleep 10

# Execute Nextflow RNASeq workflow

#echo "Ausführung von RNASeq workflow auf dem Cluster."
#WORKFLOW_LOG="workflow.log"
#nextflow kuberun /data/Simon_data/example-rnaseq-workflow/main.nf -v thammphi-pvc:/data > $WORKFLOW_LOG 2>&1 &

# Execute Nextflow Quantms workflow

#echo "Ausführung von Quantms workflow auf dem Cluster."
#WORKFLOW_LOG="workflow.log"
#nextflow kuberun /data/Proteomics_workflow/quantms/main.nf -v thammphi-pvc:/data -profile docker --input "/data/Proteomics_workflow/quantms/BSA_design_urls.tsv" --database "/data/Proteomics_workflow/quantms/18Protein_SoCe_Tr_detergents_trace_target_decoy.fasta" --outdir /data/Proteomics_workflow/quantms/output/ > $WORKFLOW_LOG 2>&1 &

# Execute Nextflow Rangeland workflow
echo "Ausführung von Rangeland workflow auf dem Cluster."
WORKFLOW_LOG="workflow.log"
kubectl exec -n thammphi -it nextflow-pod -- sh -c "cd data/Remote_Sensing_workflow/rangeland/ && nextflow run main.nf -profile test,docker --outdir data/Remote_Sensing_workflow/output" > $WORKFLOW_LOG 2>&1 &
#kubectl exec -n thammphi -it nextflow-pod -- sh -c "cd data/Remote_Sensing_workflow/rangeland/ && nextflow run main.nf -profile test,docker --outdir data/Remote_Sensing_workflow/output"  > $WORKFLOW_LOG 2>&1 &

# Execute Nextflow Ampliseq workflow

#echo "Ausführung von Ampliseq workflow auf dem Cluster."
#WORKFLOW_LOG="workflow.log"
#nextflow kuberun /data/ampliseq_workflow/ampliseq/main.nf -v thammphi-pvc:/data -profile docker --input "/data/ampliseq_workflow/ampliseq/Samplesheet.tsv" --FW_primer GTGYCAGCMGCCGCGGTAA --RV_primer GGACTACNVGGGTWTCTAAT --metadata "/data/ampliseq_workflow/ampliseq/Metadata.tsv" --outdir /data/ampliseq_workflow/ampliseq/output/ > $WORKFLOW_LOG 2>&1 &

echo "Nextflow-Workflow gestartet. Logs werden in '$WORKFLOW_LOG' geschrieben."

# Warten, bis der Workflow-Name im Log erscheint
while ! grep -q "Launching " $WORKFLOW_LOG; do
  echo "Warte auf Workflow-Initialisierung..."
  sleep 5
done

# Workflow-Name extrahieren
WORKFLOW_NAME=$(grep "Launching " $WORKFLOW_LOG | awk -F'[][]' '{print $2}')
echo "Workflow-Name: $WORKFLOW_NAME"

# Starte Logging-Prozess
#bash log_task_nodes.sh "$WORKFLOW_NAME" &
# Store the process ID to manage it later if needed
#LOGGING_PID=$!
#echo "Logging process started (PID: $LOGGING_PID)"

# Überwachungsschleife
MAX_IDLE_COUNT=100
idle_count=0

while true; do
  # Get all running Nextflow task pods with their assigned nodes
  PODS=$(kubectl get pods -n thammphi -l "nextflow.io/runName=$WORKFLOW_NAME" -o jsonpath="{range .items[*]}{.metadata.name} {.spec.nodeName}{'\n'}{end}")

  # If no pods are running, exit loop
  if [[ -z "$PODS" ]]; then
    ((idle_count++))
    echo "No more Nextflow task pods detected. Idle count: $idle_count"

    # If idle count exceeds threshold, stop the script
    if [[ $idle_count -ge $MAX_IDLE_COUNT ]]; then
      echo "No new task pods detected for a while. Stopping logging."
      break
    fi
  fi
  sleep 1  # Adjust sleep time if needed
done
#while true; do
#  #POD_STATUS=$(kubectl get pods -n thammphi -l "nextflow.io/runName=$WORKFLOW_NAME" -o jsonpath='{.items[*].status.phase}')
#  POD_STATUS=$(kubectl get pod -n thammphi $WORKFLOW_NAME -o jsonpath='{.status.phase}')
#
#  if [[ "$POD_STATUS" == *"Succeeded"* ]]; then
#    echo "Nextflow-Workflow erfolgreich abgeschlossen."
#    break
#  elif [[ "$POD_STATUS" == *"Failed"* ]]; then
#    echo "Nextflow-Workflow fehlgeschlagen. Überprüfe die Logs der Pods:"
#    kubectl logs -n thammphi $WORKFLOW_NAME
#    exit 1
#  else
#    echo "Workflow läuft noch (Status: $POD_STATUS)..."
#  fi
#
#  sleep 30
#done


# Weiterer Code wird nur ausgeführt, wenn der Workflow erfolgreich war
echo "Fahre mit dem nächsten Schritt fort..."

# Energiemessung stoppen
kubectl exec -n thammphi -it thammphi-pod-c37 -- pkill -f collect_energy_data_c37.sh
kubectl exec -n thammphi -it thammphi-pod-c38 -- pkill -f collect_energy_data_c38.sh

kubectl exec -n thammphi -it test-pod -- mkdir /data/auto_reports_traces

# Daten in Verzeichnis zur Übertragung kopieren
kubectl exec -n thammphi -it test-pod -- cp /data/energy_log_c37.txt /data/auto_reports_traces/
kubectl exec -n thammphi -it test-pod -- cp /data/energy_log_c38.txt /data/auto_reports_traces/
kubectl exec -n thammphi -it test-pod -- cp /data/energy_DRAM_log_c37.txt /data/auto_reports_traces/
kubectl exec -n thammphi -it test-pod -- cp /data/energy_DRAM_log_c38.txt /data/auto_reports_traces/
kubectl exec -n thammphi -it test-pod -- cp /data/Remote_Sensing_workflow/rangeland/exp_shtest_trace_run /data/auto_reports_traces/
kubectl exec -n thammphi -it test-pod -- cp /data/Remote_Sensing_workflow/rangeland/exp_shtest_report.html /data/auto_reports_traces/

# Verzeichnis an den lokalen Rechner übertragen
kubectl cp test-pod:/data/auto_reports_traces last_run/

#Task node log nach last_run kopieren
#cp task_node_log.txt last_run/

# Daten vom Cluster löschen
kubectl exec -n thammphi -it test-pod -- rm -f /data/start_signal.txt
kubectl exec -n thammphi -it test-pod -- rm -f /data/stop_signal.txt
kubectl exec -n thammphi -it test-pod -- rm -f /data/energy_log_c37.txt
kubectl exec -n thammphi -it test-pod -- rm -f /data/energy_log_c38.txt
kubectl exec -n thammphi -it test-pod -- rm -f /data/energy_DRAM_log_c37.txt
kubectl exec -n thammphi -it test-pod -- rm -f /data/energy_DRAM_log_c38.txt
kubectl exec -n thammphi -it test-pod -- rm -rf /data/philipp/
kubectl exec -n thammphi -it test-pod -- rm -rf /data/auto_reports_traces/

# Log anzeigen und Pod löschen
#kubectl logs -n thammphi $WORKFLOW_NAME
#kubectl get pod -n thammphi $WORKFLOW_NAME -o jsonpath='{.status.phase}'
#kubectl delete pod -n thammphi $WORKFLOW_NAME

# Warte auf Beendigung des Logging-Prozesses
#wait $LOGGING_PID

# Skript zur Berechnung des Energieverbrauchs ausführen
echo "Run energy_evaluation.py"
python3 last_run/energy_evaluation.py