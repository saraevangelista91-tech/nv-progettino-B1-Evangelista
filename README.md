# nv-progettino-B1-Evangelista

**Autore:** Sara Evangelista
**Codice variante:** B1
**Repo:** https://github.com/.../nv-progettino-B1-Evangelista

## 1. Obiettivo

Capire a basso livello come funziona la comunicazione fra due network namespace direttamente connessi da una coppia veth, e in particolare leggere "in diretta" il traffico che passa con tcpdump/Wireshark per riconoscere i protocolli che entrano in gioco prima ancora dell'ICMP: la richiesta e la risposta ARP.
(2-4 righe: cosa fa il progettino e perché. Un paragrafo, niente liste.)

## 2. Architettura

Due namespace e una sola rete /24:

ns1 (10.0.1.10) ── veth-a ──────── veth-b ── (10.0.1.20) ns2
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

## 5. Verifica del funzionamento

(I comandi/azioni di verifica che dimostrano che il progettino funziona:
ping da X a Y, curl su porta Z, screenshot dell'output atteso, ecc.)

## 6. Riflessioni e punti aperti

(Cosa hai scoperto facendolo, eventuali difficoltà incontrate, cosa
miglioreresti, eventuali domande aperte. Non è un riempitivo: è la
parte che meglio mostra che hai capito ciò che hai fatto.)

## 7. Riferimenti

(Link a documentazione ufficiale, articoli, slide del corso, guide
dei materiali del corso che hai usato.)
Lunghezza ragionevole: 2-5 pagine una volta renderizzato. Se è molto più corto rischi di non avere abbastanza dettaglio per riprodurre il lavoro; se è molto più lungo, probabilmente stai scrivendo prosa che la demo mostra meglio.
