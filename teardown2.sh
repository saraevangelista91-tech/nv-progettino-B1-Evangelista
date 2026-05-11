#!/bin/bash

echo "[1] Eliminazione veth pair"
ip link del veth-ns1 2>/dev/null || true
ip link del veth-ns2 2>/dev/null || true

echo "[2] Eliminazione namespace"
ip netns del ns1 2>/dev/null || true
ip netns del ns2 2>/dev/null || true

echo "[3] Verifica finale"
ip netns list
ip link show | grep veth || true

echo "Teardown completato"
