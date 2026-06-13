### Snímok 1: Titulný snímok (~15 sec)

> Dobrý deň, volám sa Jakub Sikula a rád by som vám predstavil svoju diplomovú prácu s názvom „Design and Implementation of a Real-Time Sensor Data Platform for River and Catchment Monitoring". Vedúcim práce bol pan doktor Tomaš Rebok.

---

### Snímok 2: Problém a motivácia (~1 min)

> Environmentálne senzorové siete produkujú nepretržité toky heterogénnych dát. Rôzni výrobcovia, rôzne komunikačné protokoly — MQTT, SFTP, CSV upload — a rôzne dátové formáty. Zjednotiť tieto dáta pod jednu platformu je naozaj netriviálny problém.
>
> Česká zemědělská univerzita v Prahe prevádzkuje monitorovaciu infraštruktúru na riečnych povodiach, ale doteraz nemala žiadnu jednotnú platformu, ktorá by tieto dáta spravovala štandardizovaným spôsobom.
>
> Ako východisko sme zvolili open-source systém Time.IO, vyvinutý v Helmholtz Centre v Lipsku. Toto nasadenie je zároveň pilotným projektom v rámci európskej výskumnej infraštruktúry eLTER, ktorej cieľom je dlhodobý ekosystémový monitoring.

---

### Snímok 3: Východisko: UFZ Time.IO (~1 min)

> Na diagrame vidíte architektúru Time.IO tak, ako sme ju zdedili. Hore vstupujú dáta z MQTT senzorov do Mosquitto brokera. Ten ich rozdelí medzi ingestion workery — mqtt-ingest, file-ingest, run-qaqc a ďalšie — ktoré ukladajú observácie do PostgreSQL s TimescaleDB. Každý senzor má vlastnú schému, takzvané per-thing schemas.
>
> Pod workermi sú služby: FROST-Server pre OGC SensorThings API, Keycloak pre autentifikáciu, Grafana a Cron ktory spušťa ulohy na napriklad pravidelne getovanie dat z externych API. Súbory z SFTP alebo CSV uploadov idú priamo do MinIO.
>
> Ale všimnite si červené čiarky. SMS Backend nikdy nepodarilo sprevádzkovať — a FROST-Server aj Grafana na ňom záviseli cez SQL views. Upstream frontendy posielali nevalidné MQTT správy do brokera, čo spôsobovalo tiché zlyhania. Tieto a mnoho ďalších problémom definovalo rozsah mojej práce.

---

### Snímok 4: Analýza nedostatkov (~1 min 15 sec)

> Nedostatky som rozdelil do dvoch skupín. Prvá sú technické problémy v upstream kóde — to, čo vidíte na predchádzajúcom diagrame červenou.
>
> FROST-Server bol nefunkčný kvôli závislosti na SMS. Upstream frontendy posielali nevalidné MQTT správy. Celý systém bol hardcoded pre UFZ prostredie — Keycloak klienti s natvrdo zadanými UFZ prefixmi, špecificky nakonfigurované scopes — a k ničomu z toho neexistovala dokumentácia. Veľa času som strávil dolovaním z kódu, prečo niektoré časti nefungujú.
>
> K tomu upstream tím kontinuálne vyvíjal bez ohľadu na backward kompatibilitu — mazali staršie verzie a artefakty. Napriek pinnovaniu verzií som musel neustále preberať upstream zmeny. Nachádzal som závažné bugy, ktoré po pár týždňoch opravili, ale nemohol som ich reportovať, pretože mi nedali prístup k ich bug trackeru.
>
> Druhá skupina sú chýbajúce funkcie pre ČZU — žiadny webový portál, projektová správa, upozornenia, jednotné nasadenie a viacjazyčnosť.
>
> Celkovo jedenásť nedostatkov, ktoré definovali rozsah mojej práce.

---

### Snímok 5: Ciele práce (~30 sec)

> Ciele práce sú štyri. Prvý — analyzovať Time.IO voči požiadavkám ČZU a eLTER. Druhý — navrhnúť a implementovať Water Data Platform, teda aplikačnú vrstvu s projektmi, portálom, upozorneniami a mapami. Tretí — implementovať jednotné nasadenie, hydro-deploy. A štvrtý — vyhodnotiť výslednú platformu voči identifikovaným požiadavkám.

---

### Snímok 6: Architektúra riešenia (~1 min 30 sec)

> Toto je kľúčový snímok — architektúra celého riešenia.
>
> Platforma má dve runtime vrstvy. Vpravo je tsm-orchestration, infraštruktúrna vrstva, zdedená a upravená. Obsahuje FROST-Server, Keycloak, Grafanu, ingestion workery a cron scheduler. Komponenty v oranžovej farbe som modifikoval — najmä ingestion workery, kde som upravoval provisioning, parsery a MQTT integráciu.
>
> Vľavo, v modrej, je Water Data Platform — celá táto vrstva je nová, navrhnutá a implementovaná v rámci tejto práce. Obsahuje FastAPI backend, Next.js frontend, Celery worker pre asynchrónne úlohy a GeoServer pre geospatial vrstvy.
>
> Dole je zdieľaná dátová vrstva — jeden PostgreSQL s TimescaleDB, MinIO pre súbory a Mosquitto MQTT broker ako integračná chrbtica. MQTT zariadenia posielajú dáta priamo do brokera.
>
> Dôležité rozhodnutie: tieto dve vrstvy sú oddelené, čo umožňuje nezávislý vývoj a jednoduchšie updaty z upstreamu.

---

### Snímok 7: Čo som vytvoril (~1 min)

> Poďme si zhrnúť tri hlavné príspevky.
>
> Prvý — TSM adaptácia. Nahradil som nefunkčné STA views deviatimi lokálnymi views, čím sa FROST-Server stal funkčným. Upravil som tiež ingestion workery — provisioning, parsery a MQTT integráciu. Celkovo je v kóde osemnásť označených workaroundov, pripravených na jednoduchý revert.
>
> Druhý — Water Data Platform. Kompletne nová aplikačná vrstva: FastAPI backend a Next.js 15 portál s projektovou správou, dvojúrovňovým RBAC, systémom upozornení, interaktívnymi mapami a podporou troch jazykov.
>
> Tretí — hydro-deploy. Jediný príkaz `make up` naštartuje dvadsaťdva kontajnerov. Automatická správa hesiel a health-check.

---

### Snímok 8: Portál – správa projektov a senzorov (~1 min 30 sec)

> Tu vidíte ukážky z portálu. Vľavo je zoznam projektov — každý projekt zobrazuje popis, počet prepojených senzorov a rolu používateľa. Projekty sú filtrovateľné podľa Keycloak skupín.
>
> Vpravo je detail senzora s vizualizáciou časových radov. Grafy sú interaktívne — podporujú zoom, výber časového rozsahu a prepínanie medzi datastreams. Dáta sa načítavajú cez React Query s cachingom.
>
> Celý portál je viacjazyčný — angličtina, čeština a slovenčina — s automatickou detekciou jazyka prehliadača.

---

### Snímok 9: Interaktívna mapa a GeoServer vrstvy (~1 min)

> Ďalšou kľúčovou funkciou je interaktívna mapa. Senzory sú zobrazené ako farebné markery na CARTO basemape. Po kliknutí na senzor sa zobrazí popup s aktuálnymi hodnotami — tu napríklad vodná hladina a teplota.
>
> Cez GeoServer je možné prekryť WMS vrstvy — napríklad hranice povodí alebo geologické mapy. Vrstva sa dá zapnúť a vypnúť v layer selectore vľavo hore. Celé je postavené na MapLibre GL JS s tridsaťsekundovým auto-refreshom.

---

### Snímok 10: Nasadenie jedným príkazom (~1 min)

> Posledný komponent je deployment layer. Operátor spustí `make up` a celá platforma — dvadsaťdva kontajnerov — sa naštartuje v správnom poradí.
>
> Funguje to tak, že štyri Docker Compose súbory sa mergujú do jednej konfigurácie. Skripty automaticky vygenerujú kryptograficky bezpečné heslá a synchronizujú ich medzi stackami.
>
> `make check` overí zdravie všetkých služieb. Celé je navrhnuté tak, aby operátor nepotreboval znalosti vnútornej architektúry. Podporovaný je aj rootless Podman pre prostredia bez Docker démona.

---

### Snímok 11: Testovanie a validácia (~1 min 30 sec)

> Teraz k validácii. Backend má osemsto štyri testov pokrývajúcich API endpointy, služby, RBAC a alerty. Frontend má deväťdesiatšesť testov cez Vitest. Z upstreamu sme zdedili stotridsaťjeden testov — všetky prechádzajú. Celkovo vyše tisíc automatizovaných testov.
>
> Z dvadsiatich štyroch funkčných požiadaviek sme dvadsaťtri splnili úplne. Jedna — správa Keycloak skupín cez portál — bola čiastočne splnená, používatelia ju riešia priamo cez Keycloak admin konzolu.
>
> Záťažové testy cez Locust potvrdili odozvu pod tristodesať milisekúnd na deväťdesiatom piatom percentile pri dvadsiatich piatich súbežných používateľoch. Platforma je nasadená na cloud.muni.cz a ČZU ju aktuálne testuje v malom rozsahu s niekoľkými senzormi.

---

### Snímok 12: Kľúčové zistenie (~1 min)

> Aké je hlavné zistenie tejto práce?
>
> Architektonické myšlienky za Time.IO sú správne. Per-thing izolácia v databáze, MQTT-driven worker pipeline a OGC SensorThings API ako interoperabilný štandard — to všetko funguje.
>
> Problém je v upstream implementácii. SMS služba nikdy nebola funkčná, frontendy generovali chybné správy, kód bol hardcoded pre UFZ bez dokumentácie a upstream tím kontinuálne lámal backward kompatibilitu. Podpora pre externých prispievateľov prakticky neexistuje — nemali sme ani prístup k bug trackeru. V kóde je stále osemnásť dočasných workaroundov.
>
> Záver je, že účelová implementácia zameraná na konkrétne potreby eLTER by bola udržateľnejšia než ďalšia adaptácia upstream kódu.

---

### Snímok 13: Obmedzenia a budúca práca (~1 min)

> Budem úprimný ohľadom obmedzení. TSM-TEMP workaroundy sú stále v kóde. Testovacie pokrytie FROST clienta je len štrnásť percent. Platforma nebola overená vo väčšej mierke než ČZU a ešte nie je pripravená pre plnú eLTER integráciu.
>
> Budúca práca zahŕňa prepísanie TSM komponentov s čistou STA vrstvou, integráciu eLTER metadátových štandardov — DEIMS-SDR, EnvThes a LogIn — a implementáciu federácie medzi nezávislými inštanciami platformy.

---

### Snímok 14: Ďakujem za pozornosť (~10 sec)

> Ďakujem za pozornosť. Som pripravený odpovedať na otázky z posudkov, a potom na vaše otázky.