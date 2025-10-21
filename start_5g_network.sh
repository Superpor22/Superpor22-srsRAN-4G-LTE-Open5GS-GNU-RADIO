#!/bin/bash

echo "========================================="
echo "  Iniciando Red 5G SA con GNU Radio"
echo "========================================="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Crear namespace
echo -e "${GREEN}[1/5]${NC} Creando network namespace..."
sudo ip netns add ue1 2>/dev/null || echo "Namespace ue1 ya existe"
sleep 1

# 2. Iniciar Open5GS Core
echo -e "${GREEN}[2/5]${NC} Iniciando Open5GS 5G Core (Docker)..."
cd ./srsRAN_Project/docker
gnome-terminal --title="Open5GS 5G Core" --geometry=100x30+0+0 -- bash -c "docker compose up 5gc; exec bash"
echo "Esperando a que el core se inicie..."
sleep 15

# 3. Iniciar gNB
echo -e "${GREEN}[3/5]${NC} Iniciando srsRAN Project gNB..."
cd ../build/apps/gnb
gnome-terminal --title="srsRAN gNB" --geometry=100x30+0+400 -- bash -c "sudo ./gnb -c gnb_zmq.yaml; exec bash"
echo "Esperando a que el gNB se conecte al core..."
sleep 8

# 4. Iniciar UE
echo -e "${GREEN}[4/5]${NC} Iniciando srsUE..."
cd ../../../../srsRAN_4G/build/srsue/src
gnome-terminal --title="srsUE (UE1)" --geometry=100x30+800+0 -- bash -c "sudo ./srsue ue_zmq.conf; exec bash"
echo "UE iniciado, esperando GNU Radio..."
sleep 3

# 5. Mensaje para GNU Radio
echo ""
echo "========================================="
echo -e "${YELLOW}[5/5] ACCIÓN REQUERIDA:${NC}"
echo "========================================="
echo ""
echo "Debes iniciar MANUALMENTE GNU Radio Companion:"
echo ""
echo "  1. Abre una nueva terminal"
echo "  2. Ejecuta: gnuradio-companion multi_ue_scenario.grc"
echo "  3. Presiona el botón Execute (▶️) o F6"
echo ""
echo "O ejecuta directamente:"
echo "  python3 multi_ue_scenario.py"
echo ""
echo -e "${GREEN}Una vez iniciado GNU Radio, el UE se conectará automáticamente.${NC}"
echo ""
echo "========================================="
