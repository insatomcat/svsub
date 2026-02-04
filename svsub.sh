function readSvSub4(){
  echo "getting p7c svSub 4"

  for dir in /etc/cap/ied-*; do
    if [ -d "${dir}/config" ]; then
      echo "" >> "${reportFileName}"
      echo "Reading svsub4 for directory: ${dir}" >> "${reportFileName}"
      sudo ./p7c_readsvsub.py "${dir}"
      sudo grep -E '(\[0\]:|wMsgQueueError|wLastSecondeCounter|iMaxDeltaTsNs|wNbLostSvTimeout|wNbTsOver1ms|wNbSeconde|wRequest|wAccepcted|wRejected|wSvUnavailable)' "${dir}"/output.txt >> "${reportFileName}"

      ied_name=$(basename "${dir}")
      svsub_output=$(sudo grep '\[0\]:' "${dir}/output.txt" | sed -n 's/.*\[0\]:\s*\(.*\)/\1/p' | xargs)
      svsub_outputs+=("${ied_name} ${svsub_output}")
      maxdelta_output=$(sudo grep 'iMaxDeltaTsNs' "${dir}/output.txt" | awk -F':' '{print $6}')
      if [ -z "$maxdelta_output" ]; then
        maxdelta_outputs+=("${ied_name} 0")
      else
        maxdelta_outputs+=("${ied_name} ${maxdelta_output}")
      fi
      nblost_output=$(sudo grep 'wNbLostSvTimeout' "${dir}/output.txt" | awk -F':' '{gsub(/^ +| +$/,"",$5); print $5}')
      if [ -z "$nblost_output" ]; then
        nblost_outputs+=("${ied_name} 0")
      else
        nblost_outputs+=("${ied_name} ${nblost_output}")
      fi
      msgqueueerr_output=$(sudo grep 'wMsgQueueError' "${dir}/output.txt" | awk '{print $5}' | head -n 1)
      msgqueueerr_outputs+=("${ied_name} ${msgqueueerr_output}")
    fi
  done

  echo "" >> "${reportFileName}"
  echo "svSub 4 -- delayed sv summary" >> "${reportFileName}"
  for output in "${svsub_outputs[@]}"; do
    echo -e "$output" >> "${reportFileName}"
  done
  echo "svSub 4 -- iMaxDeltaTsNs summary" >> "${reportFileName}"
  for output in "${maxdelta_outputs[@]}"; do
    echo -e "$output" >> "${reportFileName}"
  done
  echo "svSub 4 -- wNbLostSvTimeout summary" >> "${reportFileName}"
  for output in "${nblost_outputs[@]}"; do
    echo -e "$output" >> "${reportFileName}"
  done
  echo "svSub 4 -- wMsgQueueError summary" >> "${reportFileName}"
  for output in "${msgqueueerr_outputs[@]}"; do
    echo -e "$output" >> "${reportFileName}"
  done

  jq -n \
  --argjson svsub "$(printf '%s\n' "${svsub_outputs[@]}" | awk '{print "{\"ied\":\""$1"\",\"receivedpersec\":\""$2"\",\"received\":\""$3"\",\"sup1ms\":\""$4"\",\"sup3ms\":\""$5"\",\"sup5ms\":\""$6"\",\"sup10ms\":\""$7"\",\"sup15ms\":\""$8"\"}"}' | jq -s '.')" \
  --argjson maxdelta "$(printf '%s\n' "${maxdelta_outputs[@]}" | awk '{print "{\"ied\":\""$1"\",\"maxsvdelta\":\""($2?$2:"")"\"}"}' | jq -s '.')" \
  --argjson nblost "$(printf '%s\n' "${nblost_outputs[@]}" | awk '{print "{\"ied\":\""$1"\",\"nbsvlost\":\""($2?$2:"")"\"}"}' | jq -s '.')" \
  --argjson msgqueueerr "$(printf '%s\n' "${msgqueueerr_outputs[@]}" | awk '{print "{\"ied\":\""$1"\",\"msgqueueerr\":\""($2?$2:"0")"\"}"}' | jq -s '.')" \
  '{delayed_sv_summary: $svsub, maxdelta_summary: $maxdelta, lostsv_summary: $nblost, msgqueueerr_summary: $msgqueueerr}' | sudo sponge /tmp/rt-report-svsub.json

  sudo mkdir -p /var/cap/telegraf/input_files
  sudo cp /tmp/rt-report-svsub.json /var/cap/telegraf/input_files/rt-report-svsub.json
  #AJOUT RTE
  sudo /usr/local/bin/json2prom.sh
  #FIN AJOUT RTE
  sudo chmod 644 /tmp/rt-report-svsub.json
  sudo chmod 644 /var/cap/telegraf/input_files/rt-report-svsub.json

  getInterruptStats
}
