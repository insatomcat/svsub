#!/usr/bin/env bash
json_file="/tmp/rt-report-svsub.json"
prom_file="/var/lib/node_exporter/textfile_collector/rt_report.prom"

jq -r '
  .delayed_sv_summary[] |
  "sv_received_per_sec{ied=\"" + .ied + "\"} " + .receivedpersec,
  "sv_received_total{ied=\"" + .ied + "\"} " + .received,
  "sv_sup1ms{ied=\"" + .ied + "\"} " + .sup1ms,
  "sv_sup3ms{ied=\"" + .ied + "\"} " + .sup3ms,
  "sv_sup5ms{ied=\"" + .ied + "\"} " + .sup5ms,
  "sv_sup10ms{ied=\"" + .ied + "\"} " + .sup10ms,
  "sv_sup15ms{ied=\"" + .ied + "\"} " + .sup15ms
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
