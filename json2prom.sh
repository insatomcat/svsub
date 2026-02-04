#!/usr/bin/env bash
json_file="/tmp/rt-report-svsub.json"
prom_file="/var/lib/node_exporter/textfile_collector/rt_report.prom"

jq -r '
  .delayed_sv_summary[] |
  # Toujours index 0
  "sv_received_per_sec{ied=\"" + .ied + "\",index=\"0\"} " + .receivedpersec_0,
  "sv_received_total{ied=\"" + .ied + "\",index=\"0\"} " + .received_0,
  "sv_sup1ms{ied=\"" + .ied + "\",index=\"0\"} " + .sup1ms_0,
  "sv_sup3ms{ied=\"" + .ied + "\",index=\"0\"} " + .sup3ms_0,
  "sv_sup5ms{ied=\"" + .ied + "\",index=\"0\"} " + .sup5ms_0,
  "sv_sup10ms{ied=\"" + .ied + "\",index=\"0\"} " + .sup10ms_0,
  "sv_sup15ms{ied=\"" + .ied + "\",index=\"0\"} " + .sup15ms_0,

  # Index 1 uniquement si présent dans le JSON
  (if .receivedpersec_1 != null then
    "sv_received_per_sec{ied=\"" + .ied + "\",index=\"1\"} " + .receivedpersec_1,
    "sv_received_total{ied=\"" + .ied + "\",index=\"1\"} " + .received_1,
    "sv_sup1ms{ied=\"" + .ied + "\",index=\"1\"} " + .sup1ms_1,
    "sv_sup3ms{ied=\"" + .ied + "\",index=\"1\"} " + .sup3ms_1,
    "sv_sup5ms{ied=\"" + .ied + "\",index=\"1\"} " + .sup5ms_1,
    "sv_sup10ms{ied=\"" + .ied + "\",index=\"1\"} " + .sup10ms_1,
    "sv_sup15ms{ied=\"" + .ied + "\",index=\"1\"} " + .sup15ms_1
   else empty end)
' "$json_file" > "$prom_file"

jq -r '
  .maxdelta_summary[] |
  select(.maxsvdelta != "") |
  "sv_max_delta{ied=\"" + .ied + "\"} " + .maxsvdelta
' "$json_file" >> "$prom_file"

jq -r '
  .lostsv_summary[] |
  "sv_lost_total{ied=\"" + .ied + "\"} " + .nbsvlost
' "$json_file" >> "$prom_file"

chown nobody:nogroup $prom_file
