# ProgettoSI - Smart Contract Supply Chain

Sistema basato su Solidity per la gestione e il tracciamento di Dispositivi (Devices) e Prodotti (Products), con gestione granulare dei ruoli e controllo dello stato del contratto.

## 📋 Funzionalità

Amministrazione:

- activate() / deactivate(): Gestione stato del contratto.

- registerProducer(address): Abilita un account al ruolo di Produttore.

- transferAdmin(address): Trasferisce i permessi di amministrazione ruoli.

Operazioni Produttore:

- registerDevice(did, dpk): Registra un nuovo dispositivo nel sistema.

- registerProduct(pid, name, ...): Crea un nuovo profilo prodotto.

- link(pid, did): Collega un dispositivo esistente a un prodotto esistente.

Consultazione (Public)

- getDevice(did) / getProduct(pid): Recupera i dettagli del singolo elemento.

- getProductLinkedTo(did): Identifica il prodotto associato a un determinato device.

- getDeviceLinkedTo(pid): Restituisce la lista di tutti i device associati a un prodotto.

## ⚙️ Requisiti

- Solidity: ^0.8.2

- Librerie: OpenZeppelin Contracts (Ownable, AccessControl)

## 📝 Nota

Per ottimizzare la ricerca e distinguere tra elementi non trovati ed elementi validi, il contratto utilizza un elemento "dummy" all'indice 0 degli array, assicurando che ogni mappatura valida punti sempre a un indice > 0.
