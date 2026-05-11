#!/bin/bash
set -e

echo "[1] Creazione namespace"
ip netns add ns1 || true
ip netns add ns2 || true

echo "[2] Creazione veth pair"
ip link add veth-ns1 type veth peer name veth-ns2

echo "[3] Spostamento interfacce nei namespace"
ip link set veth-ns1 netns ns1
ip link set veth-ns2 netns ns2

echo "[4] Configurazione ns1"
ip netns exec ns1 ip link set lo up
ip netns exec ns1 ip link set veth-ns1 up
ip netns exec ns1 ip addr add 10.0.1.10/24 dev veth-ns1

echo "[5] Configurazione ns2"
ip netns exec ns2 ip link set lo up
ip netns exec ns2 ip link set veth-ns2 up
ip netns exec ns2 ip addr add 10.0.1.20/24 dev veth-ns2

echo "[6] Verifica"
ip netns exec ns1 ip a
ip netns exec ns2 ip a
