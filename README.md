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
ip neigh show
#apro una shell per ns2
sudo su #entro in modalità super user
ip netns exec ns2 /bin/bash #entro dentro ns2
ip netns exec ns2 ip neigh flush dev veth-ns2 #elimino l'associazione indirizzo IP - indirizzo MAC dalla memoria
ip neigh show

Cattura del primo ping
#shell ns2
tcpdump -n -e -i veth-ns2 -w /tmp/cattura.pcap
#shell ns1
ping -c 3 10.0.1.20
ip neigh show #vedo che il MAC è stato associato a ns2 
#nella barra degli indirizzi apro il file system della wsl file://wsl$/Ubuntu/tmp/
#apro il file cattura.pcap con Wireshark

#shell ns2
tcpdump -n -e -i veth-ns2 -w /tmp/cattura2.pcap
#shell ns1
ping -c 2 10.0.1.20

sudo ./scripts/teardown.sh #rimuove i namespace

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
La cache ARP ora contiene l'entry per 10.0.1.20 con il MAC di veth-ns2 (82:89:85:5e:d0:46) e può iniziare la comunicazione tramite protocollo ICMP

Pacchetto 3 ICMP-ECO request: ns1 (IP 10.0.1.10 - MAC 42:77:83:ae:be:92) testa la raggiungibilità di ns2 (IP 10.0.1.20 - MAC 82:89:85:5e:d0:46) inviando un payload casuale
<img width="1899" height="695" alt="image" src="https://github.com/user-attachments/assets/99f42137-7745-4a19-9cfd-6a22fa497616" />

Pacchetto 4 ICMP-ECO reply: ns2 (IP 10.0.1.20 - MAC 82:89:85:5e:d0:46) risponde positivamente a ns1 (IP 10.0.1.10 - MAC 42:77:83:ae:be:92) rimandando indietro lo stesso contenuto
<img width="1894" height="746" alt="image" src="https://github.com/user-attachments/assets/a4e812c1-722a-4107-827b-3ad7a5eb98e8" />

Stessa cosa per i pacchetti successivi 5-6 e 7-8
<img width="1299" height="213" alt="image" src="https://github.com/user-attachments/assets/32f4ea92-7ba8-43b0-bf3a-1f08cf7c6e97" />

Dopo il secondo ping da ns1 a ns2 vengono scambiati subito pacchetti ICMP poichè l'indirizzo MAC di ns2 è stato salvato da ns1
<img width="1683" height="338" alt="image" src="https://github.com/user-attachments/assets/095fb1d1-7812-4173-860c-81bc351f4e21" />

## 6. Riflessioni e punti aperti

(Cosa hai scoperto facendolo, eventuali difficoltà incontrate, cosa
miglioreresti, eventuali domande aperte. Non è un riempitivo: è la
parte che meglio mostra che hai capito ciò che hai fatto.)

## 7. Riferimenti

(Link a documentazione ufficiale, articoli, slide del corso, guide
dei materiali del corso che hai usato.)
Lunghezza ragionevole: 2-5 pagine una volta renderizzato. Se è molto più corto rischi di non avere abbastanza dettaglio per riprodurre il lavoro; se è molto più lungo, probabilmente stai scrivendo prosa che la demo mostra meglio.
