#!/bin/bash
set -e

# Instala Docker Compose si falta
if ! command -v docker-compose &> /dev/null; then
  echo "Instalando Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.4/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Instala python3.12-venv
echo "Instalando python3.12-venv..."
sudo apt update
sudo apt install -y python3.12-venv

# Crea y activa virtual env en ./venv
python3.12 -m venv venv
source venv/bin/activate

# Instala Flask en el entorno virtual
pip install flask

# Webhook Python que escribe alerta a fichero
cat > filewriter.py <<EOF
from flask import Flask, request
app = Flask(__name__)
@app.route("/alert", methods=["POST"])
def alert():
    with open("/tmp/prom_alert.log", "a") as f:
        f.write("Alerta activada: %s\\n" % request.data.decode())
    return "ok"
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
EOF

# Ejecuta webhook Flask en segundo plano
nohup venv/bin/python filewriter.py &

# Descubre la ip gateway del host para Docker (normalmente 172.17.0.1)
GWHOST="172.30.1.2"
echo "Usando IP del gateway del host para Docker: $GWHOST"

# docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alert.rules.yml:/etc/prometheus/alert.rules.yml
    ports:
      - "9090:9090"
    depends_on:
      - node-exporter
      - alertmanager
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    volumes:
      - /:/host:ro,rslave
    command:
      - '--path.rootfs=/host'
    ports:
      - "9100:9100"
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    ports:
      - "9093:9093"
EOF

# prometheus.yml
cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
rule_files:
  - /etc/prometheus/alert.rules.yml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]
EOF

# alert.rules.yml
cat > alert.rules.yml <<EOF
groups:
- name: disk_alerts
  rules:
  - alert: DiskUsageOver50Percent
    expr: (node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay|squashfs"} - node_filesystem_free_bytes{mountpoint="/",fstype!~"tmpfs|overlay|squashfs"}) / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay|squashfs"} > 0.5
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "Disco/root sobre 50%"
      description: "El uso del disco / superó el 50% durante 2 minutos."
EOF

# alertmanager.yml con webhook IP del host
cat > alertmanager.yml <<EOF
route:
  receiver: 'filewriter'
receivers:
- name: 'filewriter'
  webhook_configs:
  - url: 'http://$GWHOST:5001/alert'
EOF

# llenar-disco.sh
cat > llenar-disco.sh <<EOF
#!/bin/bash
dd if=/dev/zero of=archivo_6GB.test bs=1G count=6
echo "Archivo de 6GB creado en \$(pwd)/archivo_6GB.test"
EOF
chmod +x llenar-disco.sh

# Levanta los servicios de monitoreo
echo "Arrancando Prometheus, Node Exporter y Alertmanager con Docker Compose..."
docker-compose up -d

echo
echo "Acceso:"
echo "Prometheus:    http://localhost:9090"
echo "Node Exporter: http://localhost:9100/metrics"
echo "Alertmanager:  http://localhost:9093"
echo
echo "Ejecuta ./llenar-disco.sh para consumir espacio y disparar la alerta (>50% en /)."
echo "Cuando la alerta se active, observa /tmp/prom_alert.log (escrito automáticamente por el webhook Python)."
echo
echo "Para simular manualmente el envío de una alerta POST al webhook:"
echo "curl -X POST http://$GWHOST:5001/alert -d 'Test manual de alerta'"
echo
echo "Si tienes problemas de red, asegúrate que el puerto 5001 está accesible desde los contenedores. Usa la IP mostrada ($GWHOST)."

ubuntu:~$ 
ubuntu:~$ cat install.sh 
#!/bin/bash
set -e

# Instala Docker Compose si falta
if ! command -v docker-compose &> /dev/null; then
  echo "Instalando Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.4/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Instala python3.12-venv
echo "Instalando python3.12-venv..."
sudo apt update
sudo apt install -y python3.12-venv

# Crea y activa virtual env en ./venv
python3.12 -m venv venv
source venv/bin/activate

# Instala Flask en el entorno virtual
pip install flask

# Webhook Python que escribe alerta a fichero
cat > filewriter.py <<EOF
from flask import Flask, request
app = Flask(__name__)
@app.route("/alert", methods=["POST"])
def alert():
    with open("/tmp/prom_alert.log", "a") as f:
        f.write("Alerta activada: %s\\n" % request.data.decode())
    return "ok"
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
EOF

# Ejecuta webhook Flask en segundo plano
nohup venv/bin/python filewriter.py &

# Descubre la ip gateway del host para Docker (normalmente 172.17.0.1)
GWHOST="172.30.1.2"
echo "Usando IP del gateway del host para Docker: $GWHOST"

# docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alert.rules.yml:/etc/prometheus/alert.rules.yml
    ports:
      - "9090:9090"
    depends_on:
      - node-exporter
      - alertmanager
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    volumes:
      - /:/host:ro,rslave
    command:
      - '--path.rootfs=/host'
    ports:
      - "9100:9100"
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    ports:
      - "9093:9093"
EOF

# prometheus.yml
cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
rule_files:
  - /etc/prometheus/alert.rules.yml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]
EOF

# alert.rules.yml
cat > alert.rules.yml <<EOF
groups:
- name: disk_alerts
  rules:
  - alert: DiskUsageOver50Percent
    expr: (node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay|squashfs"} - node_filesystem_free_bytes{mountpoint="/",fstype!~"tmpfs|overlay|squashfs"}) / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay|squashfs"} > 0.5
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "Disco/root sobre 50%"
      description: "El uso del disco / superó el 50% durante 2 minutos."
EOF

# alertmanager.yml con webhook IP del host
cat > alertmanager.yml <<EOF
route:
  receiver: 'filewriter'
receivers:
- name: 'filewriter'
  webhook_configs:
  - url: 'http://$GWHOST:5001/alert'
EOF

# llenar-disco.sh
cat > llenar-disco.sh <<EOF
#!/bin/bash
dd if=/dev/zero of=archivo_6GB.test bs=1G count=6
echo "Archivo de 6GB creado en \$(pwd)/archivo_6GB.test"
EOF
chmod +x llenar-disco.sh

# Levanta los servicios de monitoreo
echo "Arrancando Prometheus, Node Exporter y Alertmanager con Docker Compose..."
docker-compose up -d

echo
echo "Acceso:"
echo "Prometheus:    http://localhost:9090"
echo "Node Exporter: http://localhost:9100/metrics"
echo "Alertmanager:  http://localhost:9093"
echo
echo "Ejecuta ./llenar-disco.sh para consumir espacio y disparar la alerta (>50% en /)."
echo "Cuando la alerta se active, observa /tmp/prom_alert.log (escrito automáticamente por el webhook Python)."
echo
echo "Para simular manualmente el envío de una alerta POST al webhook:"
echo "curl -X POST http://$GWHOST:5001/alert -d 'Test manual de alerta'"
echo
echo "Si tienes problemas de red, asegúrate que el puerto 5001 está accesible desde los contenedores. Usa la IP mostrada ($GWHOST)."
