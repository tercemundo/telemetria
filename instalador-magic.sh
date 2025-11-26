#!/bin/bash
set -e

# Instala Kind si no está
if ! command -v kind &> /dev/null; then
  echo "Instalando Kind..."
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
fi

# Instala kubectl si no está
if ! command -v kubectl &> /dev/null; then
  echo "Instalando kubectl..."
  curl -LO "https://dl.k8s.io/release/v1.29.3/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Instala Helm si no está
if ! command -v helm &> /dev/null; then
  echo "Instalando Helm..."
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

# Crea cluster kind con 2 nodos y mapping en NodePort prometheus (30090)
cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30090
        hostPort: 30090
        protocol: TCP
  - role: worker
EOF

echo "Creando cluster Kind con mapping del puerto 30090..."
kind delete cluster --name demo || true
kind create cluster --name demo --config kind-config.yaml

# Espera que el cluster esté listo
sleep 10

# Instala Prometheus + Node Exporter con Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring || true
helm install prom prometheus-community/prometheus --namespace monitoring

# Instala kube-state-metrics para métricas de pods y deployments
helm install kube-state-metrics prometheus-community/kube-state-metrics --namespace monitoring

# Despliega Nginx como Deployment y Servicio NodePort
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

echo "Esperando 10 segundos para que arranquen los pods..."
sleep 10

echo "Cambiando Prometheus server a NodePort 30090..."
kubectl patch svc prom-prometheus-server \
  -n monitoring \
  -p '{"spec": {"type": "NodePort", "ports": [{"port":80,"targetPort":9090,"protocol":"TCP","nodePort":30090}]}}'

echo "Pods activos en el cluster:"
kubectl get pods --all-namespaces

echo
echo "Accede a Prometheus en:  http://localhost:30090"
echo "Accede al Pod Nginx en:  http://localhost:$(kubectl get svc nginx -o=jsonpath='{.spec.ports[0].nodePort}')"
echo
echo "Agregar alertas en Prometheus editando alert.rules.yml, por ejemplo:"
echo '
groups:
- name: k8s_alerts
  rules:
  - alert: NginxPodDown
    expr: kube_pod_status_phase{pod=~"nginx.*", phase!="Running"} > 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Pod Nginx caído o en estado no Running"
      description: "El pod nginx no está en estado Running por más de 2 minutos."
'
echo
echo "¡Script terminado! Toda la demo instalada localmente y Prometheus accesible en el puerto 30090."

