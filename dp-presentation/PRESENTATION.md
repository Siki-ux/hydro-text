### Snímok 1: Titulný snímok (~15 sec)

> Dobrý deň, vážená komisia, rád by som vám predstavil svoju diplomovú prácu, ktorá sa venuje návrhu a implementácii platformy pre zber a správu dát z environmentálnych senzorov.

---

### Snímok 2: Problém a motivácia (~1 min)

> Environmentálne senzorové siete produkujú nepretržité toky heterogénnych dát. Rôzni výrobcovia, rôzne protokoly, rôzne formáty.
>
> Česká zemědělská univerzita v Prahe prevádzkuje monitoring povodí, ale doteraz nemala jednotnú platformu na správu týchto dát.
>
> Ako východisko bol zvolený open-source systém Time.IO z Helmholtz Centre v Lipsku. 
>
> Práca vznikla v kontexte projektov Chytrých krajín ČZU a zároveň ako príprava pre pilotné nasadenie v rámci európskej výskumnej infraštruktúry eLTER.

---

### Snímok 3: Východisko: UFZ Time.IO (~1 min)

> Na tomto diagrame vidíte architektúru Time.IO tak, ako bola zdedená. Hore vstupujú dáta z MQTT senzorov do Mosquitto brokera. Ten ich rozdelí medzi ingestion workery, napríklad mqtt-ingest alebo file-ingest, ktoré ukladajú observácie do PostgreSQL. Každý senzor má vlastnú databázovú schému, takzvané per-thing schemas.
>
> Pod workermi sú služby. FROST-Server sprístupňuje dáta cez OGC SensorThings API. Keycloak rieši autentifikáciu. Grafana vizualizáciu. Cron spúšťa periodické úlohy. Súbory z SFTP alebo CSV uploadov idú priamo do MinIO ktore produkuje MQTT spravy pre file-ingest.
>
> Všimnite si ale červeno vyznačené části. Najvyraznejším z rady problemov bol Sensor Management System, ktorý sa nikdy nepodarilo sprevádzkovať. Záviseli na ňom FROST-Server, Grafana a ďalšie services. Upstream frontendy zase posielali nevalidné MQTT správy do brokera, čo spôsobovalo tiché zlyhania workerov a ich backendy očakavali úplne iný databázový model.

---

### Snímok 4: Analýza nedostatkov (~1 min 15 sec)

> Nedostatky som rozdelil do dvoch skupín. Prvá sú technické problémy v upstream kóde, teda tie červené časti z predchádzajúceho diagramu.
>
> Okrem nefunkčného SMS backendu a chybných frontendov bol celý systém hardcoded pre UFZ prostredie. Chybalo riešenie chýb, workeri padali pri každom neočakavanom inpute a k ničomu z toho neexistovala dokumentácia.
>
> Upstream TSM tím kontinuálne vyvíjal bez ohľadu na backward kompatibilitu a externých prispievateľov.
>
> Druhá skupina sú chýbajúce funkcie pre ČZU. Neexistoval fungujúci webový portál, projektová správa dát, správa senszorov, systém upozornení, jednotné nasadenie, viacjazyčnosť a iné. Celkovo som indetifikoval 11 zásadných nedostatkov, ktoré definovali rozsah mojej práce.

---

### Snímok 5: Ciele práce (~30 sec)

> V ramci práce boli zadefinované 4 ciele. Analyzovať Time.IO voči požiadavkám ČZU a eLTER a adadaptovat zdedené koponenty. Navrhnúť a implementovať Water Data Platform, ako aplikačnú vrstvu. Implementovať jednotné nasadenie, a nakoniec vyhodnotiť výslednú platformu voči identifikovaným požiadavkám.

---

### Snímok 6: Architektúra riešenia (~1 min 30 sec)

> Z návrhu vyznikla nasledovná architektúra.
>
> Platforma má dve runtime vrstvy. Vpravo je tsm-orchestration tada infraštruktúrna vrstva, ktorú som zdedil a upravil. Obsahuje FROST-Server, Keycloak, Grafanu, ingestion workery a cron scheduler. Komponenty v oranžovej farbe som značne modifikoval. Najmä ingestion workery, kde som pridaval provisioning, dynamické parsery, error handling a iné.
>
> Vľavo v modrej farbe je Water Data Platform. Celá táto vrstva je nová, navrhnutá a implementovaná v rámci tejto práce. Obsahuje FastAPI backend, Next.js frontend, Celery worker pre asynchrónne úlohy a GeoServer pre geospatial vrstvy.
>
> Na spodku je zdieľaná dátová vrstva. Teda PostgreSQL databaza s TimescaleDB extension, MinIO pre súbory a Mosquitto MQTT broker ako integračná chrbtica. Senzory posielajú dáta priamo do brokera.
>
> Kľúčovým rozhodnutím bolo forknúť tsm-orchestration a udržiavať ho ako samostatnú vrstvu. Vďaka tomu bolo možné vyvíjať vrstvy nezávisle a zároveň preberať updaty z upstreamu.

---

### Snímok 7: Čo som vytvoril (~1 min 15 sec)

> Práca má dva hlavné príspevky.
>
> Prvým je adaptácia TSM vrstvy. Nahradil som nefunkčné databázové pohľady 9 lokálnymi pohľadmi a tým som dostal FROST-Server do funkčného stavu. Celkovo je v kóde 18 označených dočasných workarounds, pripravených na jednoduchý návrat k pôvodnému stavu, a množstvo menších opráv.
>
> Druhým príspevkom je Water Data Platform. Kompletne nová aplikačná vrstva s FastAPI backendom a Next.js 15 portálom. Obsahuje projektovú správu senzorov s dvojúrovňovým RBAC, zjednodušenú správu senzorov ako náhradu nefunkčného SMS z upstreamu, konfiguráciu QA/QC pipeline cez SaQC, systém upozornení, interaktívne mapy, viacjazyčnú podporu a ďalšie.
>
> K tomu patrí aj deployment vrstva, kde je možné jedným príkazom naštartovať celú platformu s automatickou správou hesiel a health-checkom.

---

### Snímok 8: Portál – správa projektov a senzorov (~1 min 30 sec)

> K user facing portalu,...
> Vľavo môžete vidieť zoznam projektov. Kde každý projekt zobrazuje popis, počet prepojených senzorov a rolu prihláseného používateľa. Projekty sú filtrovateľné podľa Keycloak skupín.
>
> Vpravo je detail konkrétneho senzoru s vizualizáciou časovej rady. Grafy sú interaktívne, podporujú zoom, výber časového rozsahu a prepínanie medzi datastreams. Dáta sa načítavajú cez React Query s cachingom.
>
> Celý portál je viacjazyčný. Momentalne podporuje angličtinu, češtinu a slovenčinu, s automatickou detekciou jazyka prehliadača.

---

### Snímok 9: Interaktívna mapa a GeoServer vrstvy (~1 min)

> Ďalšou kľúčovou funkciou sú interaktívne mapy. Senzory sú zobrazené ako farebné markery na CARTO basemape. Po kliknutí na senzor sa zobrazí popup s aktuálnymi hodnotami, tu je to napríklad vodná hladina a teplota.
>
> Vďaka GeoServeru je možné prekryť WMS vrstvy, napríklad hranice povodí alebo geologické mapy. Vrstvy sa dajú zapnúť a vypnúť v layer selectore vľavo hore.

---

### Snímok 10: Správa senzorov a QA/QC (~1 min)

> Vľavo vidíte rozhranie pre správu senzorov. Toto je zjednodušená náhrada nefunkčného upstream sensor management systemu. Operátor tu definuje senzory, ich parsery a konfiguráciu priamo cez portál.
>
> Vpravo je konfigurácia QA/QC pipeline. Užívateľ si môže nakonfigurovať kontrolné pravidlá pre každý datastream.

---

### Snímok 11: Testovanie a validácia (~1 min 30 sec)

> Vytvorených bolo 804 testov pre backend, pokrývajúcich API endpointy, služby, RBAC a alerty. Frontend má 96 testov cez Vitest. Z upstreamu som zdedil 131 testov, ktoré všetky prechádzajú aj napriek zásadným zmenám v kóde. Celkovo vyše tisíc automatizovaných testov.
>
> Z  funkčných požiadaviek bolo 23 splnených úplne. Správa Keycloak skupín cez portál, bola splnená len čiastočne. Užívatelia chceli využívať priamo Keycloak.
>
> Záťažové testy cez Locust potvrdili rýchlu odozvu pri 25 súbežných používateľoch a 150 simulovaných senzoroch. Platforma je nasadená na cloud.muni.cz a ČZU ju niekoľko týždňov testovala v malom rozsahu s reálnymi senzormi. Na základe tejto testovacej prevádzky sa nedávno rozhodli pre plnú integráciu svojej senzorovej infraštruktúry do platformy.

---

### Snímok 12: Kľúčové zistenie (~1 min)

> Teda aké je hlavné zistenie tejto práce?
>
> Architektonické myšlienky za Time.IO sú správne. Per-thing izolácia v databáze, MQTT-driven worker pipeline a OGC SensorThings API ako otvorený štandard. To všetko na papieri funguje.
>
> Problém je v kvalite upstream implementácie a v prístupe upstream tímu k externým prispievateľom.
>
> Môj záver je, že účelová implementácia zameraná na konkrétne potreby eLTERu by bola udržateľnejšia než ďalšia adaptácia tohto upstream kódu.

---

### Snímok 13: Obmedzenia a budúca práca (~1 min)

> Ohľadom obmedzení. V TSM vrstve sa stále používajú dočasné riešenia. Chýbajú automatizované integračné a systémové testy. Platforma nebola overená vo väčšej mierke než stovkách virtuálnych senzorov a desiatkach simulovaných používateľov. Platforma podporuje potrebné štandardy, ale samotná integrácia so službami eLTER infraštruktúry ešte nebola realizovaná.
>
> Budúca práca zahŕňa prepísanie TSM komponentov bez závislosti na upstream kóde, napojenie na služby infraštruktúry eLTER a rozšírenie záťažových testov s pilotným nasadením na ďalších pracoviskách.

---

### Snímok 14: Ďakujem za pozornosť (~10 sec)

> Ďakujem za pozornosť. Som pripravený odpovedať na otázky z posudkov a potom na vaše otázky.