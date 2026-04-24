#!/usr/bin/env bash
json_file="/tmp/rt-report-svsub.json"
prom_file="/var/lib/node_exporter/textfile_collector/rt_report.prom"

jq -r '
  .delayed_sv_summary[] |
  select(.receivedpersec != null and .receivedpersec != "") |
  "sv_received_per_sec{ied=\"" + .ied + "\",index=\"" + .flux + "\"} " + .receivedpersec,
  "sv_received_total{ied=\""   + .ied + "\",index=\"" + .flux + "\"} " + .received,
  "sv_sup1ms{ied=\""           + .ied + "\",index=\"" + .flux + "\"} " + .sup1ms,
  "sv_sup3ms{ied=\""           + .ied + "\",index=\"" + .flux + "\"} " + .sup3ms,
  "sv_sup5ms{ied=\""           + .ied + "\",index=\"" + .flux + "\"} " + .sup5ms,
  "sv_sup10ms{ied=\""          + .ied + "\",index=\"" + .flux + "\"} " + .sup10ms,
  "sv_sup15ms{ied=\""          + .ied + "\",index=\"" + .flux + "\"} " + .sup15ms
' "$json_file" > "$prom_file"

jq -r '
  .maxdelta_summary[] |
  select(.maxsvdelta != "") |
  "sv_max_delta{ied=\"" + .ied + "\"} " + .maxsvdelta
' "$json_file" >> "$prom_file"

jq -r '
  .lostsv_summary[] |
  select(.nbsvlost != null and .nbsvlost != "") |
  "sv_lost_total{ied=\"" + .ied + "\"} " + .nbsvlost
' "$json_file" >> "$prom_file"

jq -r '
  .msgqueueerr_summary[] |
  select(.msgqueueerr != null and .msgqueueerr != "") |
  "sv_msg_queue_errors{ied=\"" + .ied + "\"} " + .msgqueueerr
' "$json_file" >> "$prom_file"

jq -r '
  .container_stats[] |
  "container_cpu_percent{ied=\""    + .ied + "\",container=\"" + .container + "\",status=\"" + .status + "\"} " + (.cpu_pct | tostring),
  "container_mem_percent{ied=\""    + .ied + "\",container=\"" + .container + "\",status=\"" + .status + "\"} " + (.mem_pct | tostring),
  "container_uptime_days{ied=\""    + .ied + "\",container=\"" + .container + "\"} " + (.uptime_days | tostring),
  "container_best_effort_cpu{ied=\"" + .ied + "\",container=\"" + .container + "\"} " + (.best_effort_cpu | tostring),
  "container_real_time_cpu{ied=\""  + .ied + "\",container=\"" + .container + "\"} " + (.real_time_cpu | tostring),
  "container_trace_level{ied=\""    + .ied + "\",container=\"" + .container + "\"} " + (.trace_level | tostring)
' "$json_file" >> "$prom_file"

jq -r '
  .memory |
  "host_memory_used_gb "      + (.used_gb | tostring),
  "host_memory_available_gb " + (.available_gb | tostring)
' "$json_file" >> "$prom_file"

chown nobody:nogroup $prom_file
