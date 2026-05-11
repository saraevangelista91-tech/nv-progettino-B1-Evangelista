# nv-progettino-B1-Evangelista

**Autore:** Sara Evangelista
**Codice variante:** B1
**Repo:** https://github.com/.../nv-progettino-B1-Evangelista

## 1. Obiettivo

Capire a basso livello come funziona la comunicazione fra due network namespace direttamente connessi da una coppia veth, e in particolare leggere "in diretta" il traffico che passa con tcpdump/Wireshark per riconoscere i protocolli che entrano in gioco prima ancora dell'ICMP: la richiesta e la risposta ARP.

## 2. Architettura

<img width="976" height="644" alt="image" src="https://github.com/user-attachments/assets/0555572e-f32c-44b3-bf41-5df93c71f9b8" />


## 3. Prerequisiti

Per ripordurre il lavoro, bisogna aver installati WSL2 Ubuntu 24.04 e Wireshark

## 4. Come riprodurre passo-passo

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

ip neigh show #controllo che l'associazione non ci sia

#apro una shell per ns2

sudo su #entro in modalità super user

ip netns exec ns2 /bin/bash #entro dentro ns2

ip netns exec ns2 ip neigh flush dev veth-ns2 #elimino l'associazione indirizzo IP - indirizzo MAC dalla memoria

ip neigh show

#Cattura del primo ping

#shell ns2

tcpdump -n -e -i veth-ns2 -w /tmp/cattura.pcap #catturo i pacchetti e li salvo in un file cattura.pcap

#shell ns1

ping -c 3 10.0.1.20 #pingo ns2

ip neigh show #vedo che il MAC è stato associato a ns2

#nella barra degli indirizzi apro il file system della wsl file://wsl$/Ubuntu/tmp/
#apro il file cattura.pcap con Wireshark

#shell ns2

tcpdump -n -e -i veth-ns2 -w /tmp/cattura2.pcap #catturo i pacchetti e li salvo in un file cattura2.pcap

#shell ns1

ping -c 2 10.0.1.20 #pingo ns2

sudo ./scripts/teardown.sh #rimuove i namespace

## 5. Verifica del funzionamento

Primo ping da ns2 a ns1
La comunicazione tra ns2 e ns1 funziona correttamente: dalla shell di ns2 vedo che sono stati trasmessi e ricevuti 3 pacchetti 
<img width="735" height="183" alt="image" src="https://github.com/user-attachments/assets/a6e0e169-9ec1-4c21-a228-b0722d6f274f" />
Analisi dei pacchetti scambiati

Pacchetto 1 ARP-Request: ns1 non trova il MAC di ns2 e invia una richiesta a broadcast (IP 10.0.1.20 - MAC FF:FF:FF:FF:FF:FF) specificando il suo indirizzo (IP 10.0.1.10 - MAC 42:77:83:ae:be:92)
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

- Cosa succede se assegno a ns2 un IP fuori dalla /24 di ns1 (es. 10.0.2.20/24)? essendo su reti diversi, 10.0.2.20/24 non è raggiungibile, se non tramite router
<img width="571" height="57" alt="image" src="https://github.com/user-attachments/assets/167b4e54-fd54-4699-91b3-95fc20c880ed" />

- E se invece dimentico di mettere su up una delle due interfacce? Cosa vede ping e cosa vede tcpdump (sull'altro lato)? se un lato è down, è come se il cavo virtuale fosse scollegato da una parte. Il ping da ns1 a ns2 fa inviare un pacchetto ARP-Request da ns1 che però non viene ricevuto da ns2 e il ping fallisce per mancanza di ARP reply. tcpdump su ns2 non cattura nulla perchè non riceve nulla

- Tra il primo e il secondo ping, dopo quanto tempo la cache ARP si "scorda" l'entry, e da cosa dipende? (cenni a arp_table_timeout, gc_thresh). La cache ARP non viene dimenticata subito dopo il primo ping: Linux mantiene l’associazione IP-MAC per un certo tempo in stato REACHABLE (tipicamente ~30 s, controllato da base_reachable_time_ms). Dopo questo periodo l’entry diventa STALE: può ancora essere usata, ma al successivo traffico Linux può inviare una nuova ARP Request per verificare che il MAC sia ancora valido. La pulizia automatica della tabella dipende anche dai parametri di garbage collection (gc_stale_time, gc_thresh1/2/3), che controllano quando le entry vecchie vengono eliminate e quanti record ARP il kernel può mantenere.

- Questo schema (due namespace direttamente connessi) è quello che usa Docker quando crea due container nella stessa rete bridge di default? Quasi, ma c'è un pezzo in più — quale? (Spoiler: il bridge Linux fa da switch.)

## 7. Riferimenti
slide del corso itp-2526-HandsOn

