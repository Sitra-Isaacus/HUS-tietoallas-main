# HUS Tietoallas

HUS Tietoallas ja tietoallas-integraatiot on toteutettu Sitran ISAACUS-esituotantohankkeessa, Helsingin ja Uudenmaan sairaanhoitopiirin (HUS) ja Tieto Oyj:n toimesta.

## Tietoallas

Tietoallas on Big Data -järjestelmä, joka kykenee käsittelemään suuria tietomääriä ja mahdollistaa suurten tietomäärienanalytiikan. Tietoallas on tarkoitettu 

- tukemaan tiedolla johtamista sekä erilaisia lääketieteen tutkimushankkeita tarjoamalla tiedon tallennukseen, hallintaan ja analysointiin sopivia työkaluja, 
- tarjoamaan tehokas alusta sovellus- ja raportointikehitykseen, ja 
- tukemaan tulevaisuudessa operatiivisen tuotannon tarpeita tarjoamalla taustajärjestelmiä älypalveluille.

Tietoallas-järjestelmä toimii pilvessä. Tuettu alusta on Microsoft Azure. Merkittävimmät käytetyt Azure-palvelut ovat tiedon talletuksessa käytetty Data Lake Store ja HDInsightin tarjoama Apache Hadoop. Tietoallas-järjestelmä laajentaa Azuren tarjoamat palvelut kokonaiseksi tietoallasjärjestelmäksi sisältäen ominaisuuksia kuten pää- ja sivutietoaltaat, tuen tietolähdeintegraatioille, pääsynhallinnan, ja kattavan tiedon salauksen.

Päätietoallas on keskitetty tiedon tallennuspaikka tietoaltaaseen tuotavaa tietoa varten. Päätietoaltaan eheyden säilyttämiseksi, pääsy päätietoaltaaseen tulee rajata järjestelmän ylläpitäjille.

Sivutietoallas on tarkoitettu tietoaltaan loppukäyttäjien käytettäväksi. Sivutietoallas on päätietoaltaasta ja toisista sivutietoaltaista eriytetty kokonaisuus, jolla on omat prosessointiresurssit ja työtila tietojen tallennukseen. Sivutietoaltaaseen voi tuoda tietoa joko jakamalla päätietoaltaan tietoa sivutietoaltaalle tai tuomalla tieto suoraan sivutietoaltaaseen.

Tuki tietolähdeintegraatioille. Tietolähdeintegraatioilla tarkoitetaan tiedon automaattista tuomista lähdejärjestelmistä päätietoaltaaseen. Tietoallas tukee push ja pull -tyyppisiä tietolähdeintegraatioita.

Rajapinnat tiedon hyödyntämiseen. Tuettuja yhteys- ja datatyökaluja ovat mm. ovat Apache Hive, Apache Spark, Apache Zeppelin ja Jupyter Notebook. 

Tietoaltaan pääsynhallinnalla on mahdollista rajata tietoaltaan suorien loppukäyttäjien käyttöoikeudet pää- ja sivutietoallaskohtaisesti. Tietoaltaan pääsynhallinta on myös mahdollista integroida tietoallasta käyttävän organisaation pääsynhallinnan kanssa.

Tietoaltaaseen tuotu tieto on salattu AES256bit-salauksella. Tietoaltaan suorittama tiedonsiirto salataan TLS 1.2 tai myöhemmän standardin mukaisesti.

## Tietolähdeintegraatiot

Tietolähdeintegraatiolla tarkoitetaan ratkaisua, jolla Tietoaltaan ulkopuolisesta tietolähteestä saadaan tuotua dataa ja metadataa Tietoaltaaseen. Tietolähdeintegraatioratkaisu sisältää 

- kertaluontoisia töitä kuten konfiguraatioita, 
- datan alkulatauksen, ja 
- datan inkrementaalisen latauksen alkulatauksen jälkeen. 

Tietolähdeintegraation käyttöön saattaminen edellyttää toimenpiteitä sekä Tietoaltaan että tietolähteen puolella.

Tietolähdeintegraatiot on toteutettu seuraaville HUS:n käyttämille tietolähteille:

1. Cressida ODS
2. Codeserver
3. QPati
4. Caresuite
5. Clinisoft
6. Opera
7. CA
8. Healthweb
9. HUSRADU

# Lisenssi

HUS-tietoallas ja HUS:lle toteutetut tietolähdeintegraatiot on lisensioitu Apache License 2.0 lisenssillä.

# Yhteystiedot

- Sitra - https://www.sitra.fi/
- Helsingin ja Uudenmaan sairaanhoitopiiri (HUS) - http://www.hus.fi/
- Tieto Oyj - https://www.tieto.com/

# Tunnetut bugit ja huomioon otettavaa

- Tietoaltaan käyttämät Big Data -alustat ovat vielä kohtuullisen uusia ja voimakkaan kehityksen alaisia. Organisaatiolla, joka harkitsee Tietoaltaan käyttöönottoa, tulee olla tarvittava osaaminen Tietoaltaan käyttöönottoon, käytön tukeen sekä ratkaisun ylläpitoon ja jatkokehitykseen.
- Avoimena lähdekoodina julkaistu Tietoallas ei sisällä tietoaltaan operointiin liittyvää työkalupakkia, mm. monitorointi ja lokien hallinta eivät sisälly julkaisuun.
- Tietolähdeintegraatiot on toteutettu HUS:n käyttämille tietolähteille. Tietolähdeintegraation käyttöönotto muille organisaatioille edellyttää huolellista testaamista ja mahdollisia muutostöitä lähdejärjestelmän konfiguraation erotessa HUS:lla käytössä olevista konfiguraatioista.
- Avoimena lähdekoodina julkaistut tietolähdeintegraatiot eivät sisällä tietolähdejärjestelmien taulurakennetta paljastavaa osuutta, jos taulurakenteet eivät ole julkista tietoa.

# Riippuvuudet

Tietoallas toimii Microsoftin Azure-pilvipalvelussa. Tietoallas on kehitetty ja testattu Azure North Europe -konesalissa. Merkittävimmät käytetyt Azure-palvelut ja komponentit ovat HDInsight ja Data Lake Store. Tietoaltaan asennusta suunnitellessa tulee varmistua, että tarvittavat Azure-palvelut ja komponentit ovat saatavilla valitussa Azure-konesalissa. Tietoallas käyttää myös lukuisia avoimen lähdekoodin komponentteja. Parhaiten tietoaltaan riippuvuuksiin voi tutustua tarkastelemalla tietoaltaan ja tietolähdeintegraatioiden asennusautomaatioita.

# Tietoaltaan jatkokehitys

Tietoallasta tullaan jatkokehittämään. Jatkokehitykseen liittyen ota yhteyttä HUS:iin tai Tieto Oyj:hin.

# Tietoallas julkaisun sisältö

**HUS Tietoallas**

- Dokumentit
  - Tietoallas-asennusohje
  - Tietoallas-suunnitteludokumentti
- Lähdekoodi
  - Tietoaltaan lähdekoodi
  - Tietoaltaan asennus-skripti

**HUS-tietolähdeintegraatiot**

- Dokumentit
  - Tietoallas-integraatioiden yleiskuvaus
  - Integraatiokuvaus per integraatio

- Lähdekoodi
  - Tietolähdeintegraatioiden lähdekoodi
  - Tietolähdeintegraatioiden asennus-skriptit

## Lisätietoja

Asennussekvenssi on kuvattu tarkemmin dokumentissa [Infrastructure Installation Instructions](infra_automation/infrastructure_installation_instructions.md)