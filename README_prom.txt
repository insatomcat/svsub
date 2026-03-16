bien ajouter l'option pour le textfile_collector, par exemple sur un docker run: --collector.textfile.directory=/host/var/lib/node_exporter/textfile_collector

docker rm -f node_exporter; docker run -d  --network=host -p 9100:9100 --pid="host" --hostname SEdemo6 --name node_exporter -v "/:/host:ro,rslave"   --restart unless-stopped quay.io/prometheus/node-exporter:latest   --path.rootfs=/host --collector.textfile.directory=/host/var/lib/node_exporter/textfile_collector

