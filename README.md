# 🛰️ Superpor22 - srsRAN 4G/LTE + Open5GS + GNU Radio

## 📘 Descripción general
Este proyecto implementa una **red 4G/LTE con srsRAN_4G y Open5GS** utilizando **GNU Radio** como intermediario para la comunicación entre el **gNB (en este caso eNodeB)** y un **único UE emulado** a través de **ZeroMQ sockets**.

El objetivo es construir un entorno de pruebas totalmente funcional en el que el UE se conecta al core de Open5GS mediante una capa de enlace simulada con GNU Radio, sin necesidad de hardware SDR.

---

## ⚙️ Arquitectura

```
+------------------+          +------------------+          +------------------+
|     srsUE        | <==ZMQ==>|    GNU RADIO     | <==ZMQ==>|      gNB         |
| (srsRAN_4G UE)   |          | (Flow Graph)     |          | (srsRAN Project) |
+------------------+          +------------------+          +------------------+
                                  |
                                  v
                          +------------------+
                          |     Open5GS      |
                          | (5GC Dockerized) |
                          +------------------+
```

Los **sockets ZMQ** utilizados para la comunicación entre el UE y el gNB están configurados de la siguiente manera (según `prueba1.py`):

| Dirección | Tipo | Descripción |
|------------|------|-------------|
| `tcp://*:2000` | REP | gNB RX (recibe desde GNU Radio) |
| `tcp://*:2001` | REQ | gNB TX (envía hacia GNU Radio) |
| `tcp://*:2100` | REP | UE RX |
| `tcp://*:2101` | REQ | UE TX |

---

## 🧩 Dependencias y requisitos

### 📦 Paquetes del sistema
```bash
sudo apt update
sudo apt install build-essential cmake git libzmq3-dev python3-pip
sudo apt install gnuradio gnuradio-dev
sudo apt install docker docker-compose
```

### 🧱 Librerías Python (para GNU Radio Companion)
```bash
pip install PyQt5 gnuradio
```

---

## 🏗️ Instalación

### 1️⃣ Compilar **srsRAN_4G**
```bash
git clone https://github.com/srsRAN/srsRAN_4G.git
cd srsRAN_4G
mkdir build && cd build
cmake ../
make -j$(nproc)
```

### 2️⃣ Compilar **srsRAN_Project** con soporte ZMQ
```bash
git clone https://github.com/srsRAN/srsRAN_Project.git
cd srsRAN_Project
mkdir build && cd build
cmake ../ -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
make -j$(nproc)
```

Durante la compilación asegúrate de que aparezcan las líneas:
```
-- FINDING ZEROMQ.
-- Found libZEROMQ: /usr/local/include, /usr/local/lib/libzmq.so
```

### 3️⃣ Desplegar **Open5GS** (vía Docker)
```bash
cd srsRAN_Project/docker
sudo docker compose up --build 5gc
```

En `open5gs.env`, configura:
```
MONGODB_IP=127.0.0.1
OPEN5GS_IP=10.53.1.2
UE_IP_BASE=10.45.0
DEBUG=false
```

---

## ⚙️ Configuración

### 🛰️ gNB (srsRAN_Project)
Archivo: `gnb_zmq.yaml`
```yaml
ru_sdr:
  device_driver: zmq
  device_args: tx_port=tcp://127.0.0.1:2000,rx_port=tcp://127.0.0.1:2001,base_srate=11.52e6
  srate: 11.52
  tx_gain: 75
  rx_gain: 75

cell_cfg:
  dl_arfcn: 368500
  band: 3
  channel_bandwidth_MHz: 10
  common_scs: 15
  plmn: "00101"
  tac: 7
```

### 📱 UE (srsRAN_4G)
Archivo: `ue_zmq.conf`
```ini
[rf]
device_name = zmq
device_args = tx_port=tcp://127.0.0.1:2101,rx_port=tcp://127.0.0.1:2100,base_srate=11.52e6
srate = 11.52e6
tx_gain = 50
rx_gain = 40

[usim]
imsi = 001010123456780
k    = 00112233445566778899aabbccddeeff
opc  = 63BFA50EE6523365FF14C1F45F88737D
imei = 353490069873319

[nas]
apn = srsapn
apn_protocol = ipv4

[gw]
netns = ue1
ip_devname = tun_srsue
ip_netmask = 255.255.255.0
```

Crea el *network namespace*:
```bash
sudo ip netns add ue1
```

---

## 🔄 GNU Radio (Intermediario)

El archivo `prueba1.py` implementa el flujo de señal intermedio entre gNB y UE mediante **bloques ZMQ**.  
Para ejecutarlo:

```bash
python3 prueba1.py
```

---

## ▶️ Ejecución completa

1. **Levantar el core:**
   ```bash
   sudo docker compose up --build 5gc
   ```

2. **Ejecutar GNU Radio:**
   ```bash
   python3 prueba1.py
   ```

3. **Ejecutar el gNB:**
   ```bash
   cd srsRAN_Project/build/apps/gnb
   sudo ./gnb -c gnb_zmq.yaml
   ```

4. **Ejecutar el UE:**
   ```bash
   cd srsRAN_4G/build/srsue/src/
   sudo ./srsue ue_zmq.conf
   ```

---

## 🌐 Rutas de red

```bash
sudo ip ro add 10.45.0.0/16 via 10.53.1.2
sudo ip netns exec ue1 ip route add default via 10.45.1.1 dev tun_srsue

sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
```

---

## 🧪 Pruebas

### 🔹 Conectividad
```bash
sudo ip netns exec ue1 ping 10.45.1.1
ping 10.45.1.2
```

### 🔹 Throughput (iperf3)
Servidor (Core):
```bash
iperf3 -s -i 1
```
Cliente (UE):
```bash
sudo ip netns exec ue1 iperf3 -c 10.53.1.1 -i 1 -t 60
```

---

## 📚 Referencias

- **Documentación oficial srsUE:**  
  [https://docs.srsran.com/projects/project/en/latest/tutorials/source/srsUE/source/index.html](https://docs.srsran.com/projects/project/en/latest/tutorials/source/srsUE/source/index.html)

- **Open5GS (Docker):**  
  [https://open5gs.org/open5gs/docs/guide/02-building-open5gs-from-sources/](https://open5gs.org/open5gs/docs/guide/02-building-open5gs-from-sources/)

---

## 🧠 Autor
Proyecto desarrollado por **Superpor22**  
Integración de **srsRAN 4G**, **Open5GS** y **GNU Radio** para la emulación de redes 5G con un único UE conectado vía **ZeroMQ**.
