# nv-progettino-B1-Evangelista

**Autore:** Sara Evangelista
**Codice variante:** B1
**Repo:** https://github.com/.../nv-progettino-B1-Evangelista

## 1. Obiettivo

Capire a basso livello come funziona la comunicazione fra due network namespace direttamente connessi da una coppia veth, e in particolare leggere "in diretta" il traffico che passa con tcpdump/Wireshark per riconoscere i protocolli che entrano in gioco prima ancora dell'ICMP: la richiesta e la risposta ARP.
(2-4 righe: cosa fa il progettino e perché. Un paragrafo, niente liste.)

## 2. Architettura

WSL - Indirizzo IPv4: 172.26.224.1/20
WSL - Indirizzo IPv6: fe80::7f79:523d:8fa1:3904%43

PC - Indirizzo IPv4: 192.168.1.6
PC - Indirizzo IPv6: fe80::7f79:523d:8fa1:3904%43
Indirizzo fisico: 7C-8A-E1-C2-98-63
Indirizzo IP pubblico: 2.39.112.7
AS 30722 VODAFONE-IT-ASN, IT

Router: 192.168.1.1

WSL
Interfaccia di loopback lo - IP 127.0.0.1/8
Interfaccia eth0 - 172.26.235.190/20 #router virtuale dentro la VM root


Due namespace e una sola rete /24:

ns1 (10.0.1.10) ── veth-ns1 ──────── veth-ns2 ── (10.0.1.20) ns2
                       rete 10.0.1.0/24
ns1: ha un'interfaccia veth-ns1 con IP 10.0.1.10/24, link UP.
ns2: ha un'interfaccia veth-ns2 con IP 10.0.1.20/24, link UP.
Nessun router, nessun NAT, nessuna default route necessaria (sono nella stessa rete).
Tutto deve essere creato/distrutto da due script bash: scripts/setup.sh (idempotente) e scripts/teardown.sh (rimuove namespace e veth).

(Descrizione delle componenti — container, VM, namespace, reti — e di
come comunicano tra loro. Una piccola figura ASCII art o un'immagine in
screenshots/ aiutano molto.)

## 3. Prerequisiti

(Cosa deve avere installato chi vuole riprodurre il tuo lavoro:
WSL2 Ubuntu 24.04, Docker Engine, VirtualBox 7.x, ecc. Indicare le versioni.)

## 4. Come riprodurre passo-passo

(Sequenza di comandi numerati che, eseguiti su un sistema con i prerequisiti,
porta dal repo appena clonato allo stato in cui la demo "funziona".
Ogni comando deve essere COMMENTATO con cosa ci si aspetta in output.)
#Costruzione dell'architettura

ip a #vedo le interfacce nella wsl
sudo su #entro in modalità super user
ip netns add ns1 #creo il namespace ns1
ip netns add ns2 #creo il namespace ns2
ip netns list #verifico che siano stati creati i namespace
ip netns exec ns1 /bin/bash #entro dentro ns1
ip link #verifico che esiste solo l'interfaccia di loopback, senza IP
exit #ritorno nel root
ip netns exec ns2 /bin/bash #entro dentro ns2
ip link #verifico che esiste solo l'interfaccia di loopback, senza IP
exit #ritorno nel root
ip link add veth-ns1 type veth peer name veth-ns2 #creo una coppia di interfacce virtuali collegate tra loro
ip link #verifico che le interfacce siano state create
ip link set veth-ns1 netns ns1 #sposto l'interfaccia veth-ns1 in ns1
ip netns exec ns1 /bin/bash #entro dentro ns1
ip link #verifico che esiste veth-ns1
ip link set veth-ns1 up #attivo l'interfaccia veth-ns1
ip addr add 10.0.1.10/24 dev veth-ns1 #assegno l'IP 10.0.1.10 a veth-ns1
ip a #verifico che l'IP sia stato assegnato
exit #ritorno nel root
ip link set veth-ns2 netns ns2 #sposto l'interfaccia veth-ns2 in ns2
ip netns exec ns2 /bin/bash #entro dentro ns2
ip link #verifico che esiste veth-ns2
ip link set veth-ns2 up #attivo l'interfaccia veth-ns2
ip addr add 10.0.1.20/24 dev veth-ns2 #assegno l'IP 10.0.1.20 a veth-ns2
ip a #verifico che l'IP sia stato assegnato
exit #ritorno nel root

#Pulizia ARP
#apro una shell per ns1
sudo su #entro in modalità super user
ip netns exec ns1 /bin/bash #entro dentro ns1
ip netns exec ns1 ip neigh flush dev veth-ns1 #elimino l'associazione indirizzo IP - indirizzo MAC dalla memoria 
#apro una shell per ns2
sudo su #entro in modalità super user
ip netns exec ns2 /bin/bash #entro dentro ns2
ip netns exec ns2 ip neigh flush dev veth-ns2 #elimino l'associazione indirizzo IP - indirizzo MAC dalla memoria

Cattura del primo ping
#shell ns2
tcpdump -n -e -i veth-ns2 -w /tmp/cattura.pcap
#shell ns1
ping -c 3 10.0.1.20
#nella barra degli indirizzi apro il file system della wsl file://wsl$/Ubuntu/tmp/
#apro il file cattura.pcap con Wireshark

## 5. Verifica del funzionamento

(I comandi/azioni di verifica che dimostrano che il progettino funziona:
ping da X a Y, curl su porta Z, screenshot dell'output atteso, ecc.)

Primo ping da ns2 a ns1
La comunicazione tra ns2 e ns1 funziona correttamente: dalla shell di ns2 vedo che sono stati trasmessi e ricevuti 3 pacchetti 
<img width="735" height="183" alt="image" src="https://github.com/user-attachments/assets/a6e0e169-9ec1-4c21-a228-b0722d6f274f" />
Analisi dei pacchetti scambiati
Pacchetto 1 ARP-Request: ns1 non trova il MAC di ns1 e invia una richiesta a broadcast (IP 10.0.1.20 - MAC FF:FF:FF:FF:FF:FF) specificando il suo indirizzo (IP 10.0.1.10 - MAC 42:77:83:ae:be:92)
<img width="1022" height="806" alt="image" src="https://github.com/user-attachments/assets/9539df9f-8d75-43a1-93ec-4563114f056d" />
Pacchetto 2 ARP- Reply: ns2 riceve il pacchetto e risponde a ns1 (IP 10.0.1.10 - MAC 42:77:83:ae:be:92) con il suo MAC (IP 10.0.1.20 - MAC 82:89:85:5e:d0:46)
<img width="1021" height="885" alt="image" src="https://github.com/user-attachments/assets/f643ac5f-b9e6-41c0-8fe1-d76c9c2eb0fa" />


## 6. Riflessioni e punti aperti

(Cosa hai scoperto facendolo, eventuali difficoltà incontrate, cosa
miglioreresti, eventuali domande aperte. Non è un riempitivo: è la
parte che meglio mostra che hai capito ciò che hai fatto.)

## 7. Riferimenti

(Link a documentazione ufficiale, articoli, slide del corso, guide
dei materiali del corso che hai usato.)
Lunghezza ragionevole: 2-5 pagine una volta renderizzato. Se è molto più corto rischi di non avere abbastanza dettaglio per riprodurre il lavoro; se è molto più lungo, probabilmente stai scrivendo prosa che la demo mostra meglio.
