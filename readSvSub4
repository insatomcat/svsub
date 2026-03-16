function readSvSub4(){
  echo "getting p7c svSub 4"

  for dir in /etc/cap/ied-*; do
    if [ -d "${dir}/config" ]; then
      echo "" >> "${reportFileName}"
      echo "Reading svsub4 for directory: ${dir}" >> "${reportFileName}"
      sudo ./p7c_readsvsub.py "${dir}"
      sudo grep -E '(\[0\]:|wMsgQueueError|wLastSecondeCounter|iMaxDeltaTsNs|wNbLostSvTimeout|wNbTsOver1ms|wNbSeconde|wRequest|wAccepcted|wRejected|wSvUnavailable)' "${dir}"/output.txt >> "${reportFileName}"

      ied_name=$(basename "${dir}")
      # Extraction des lignes [0] et [1] (il peut y avoir 1 ou 2 lignes)
      svsub_line0=$(sudo grep '\[0\]:' "${dir}/output.txt" | sed -n 's/.*\[0\]:\s*\(.*\)/\1/p' | xargs)
      svsub_line1=$(sudo grep '\[1\]:' "${dir}/output.txt" | sed -n 's/.*\[1\]:\s*\(.*\)/\1/p' | xargs)

      # On stocke toujours la ligne [0], et on ajoute [1] uniquement si elle existe
      if [ -n "${svsub_line1}" ]; then
        svsub_outputs+=("${ied_name} ${svsub_line0} ${svsub_line1}")
      else
        svsub_outputs+=("${ied_name} ${svsub_line0}")
      fi
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
  --argjson svsub "$(printf '%s\n' "${svsub_outputs[@]}" | awk '{
    # 1 champ pour ied + 7 par ligne de données
    if (NF >= 15) {
      # Deux lignes de données : index 0 et 1
      printf("{\"ied\":\"%s\",\"receivedpersec_0\":\"%s\",\"received_0\":\"%s\",\"sup1ms_0\":\"%s\",\"sup3ms_0\":\"%s\",\"sup5ms_0\":\"%s\",\"sup10ms_0\":\"%s\",\"sup15ms_0\":\"%s\",\"receivedpersec_1\":\"%s\",\"received_1\":\"%s\",\"sup1ms_1\":\"%s\",\"sup3ms_1\":\"%s\",\"sup5ms_1\":\"%s\",\"sup10ms_1\":\"%s\",\"sup15ms_1\":\"%s\"}\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15);
    } else {
      # Une seule ligne de données : uniquement index 0
      printf("{\"ied\":\"%s\",\"receivedpersec_0\":\"%s\",\"received_0\":\"%s\",\"sup1ms_0\":\"%s\",\"sup3ms_0\":\"%s\",\"sup5ms_0\":\"%s\",\"sup10ms_0\":\"%s\",\"sup15ms_0\":\"%s\"}\n",$1,$2,$3,$4,$5,$6,$7,$8);
    }
  }' | jq -s '.')" \
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