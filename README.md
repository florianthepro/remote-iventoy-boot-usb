> [!CAUTION]
> disclaimer: Repo Made uder use of AI

# Remote iVentoy Boot USB

```text
Projektname: Remote iVentoy Boot USB
Repository:  remote-iventoy-boot-usb
Kürzel:      RIBU
Logo:        zu_erstellen_und_integriren
ISO:         remote-iventoy-boot-usb-amd64.iso
Buildskript: setup.sh
```

## Ziel

`Remote iVentoy Boot USB` erzeugt aus einer vollständigen Ubuntu-LTS-Desktop-Live-ISO eine minimale, hardwaretaugliche USB-Bootumgebung.

Der fertige Ablauf:

```text
USB-Stick einstecken
-> vom USB-Stick booten
-> RIBU startet ohne normalen Ubuntu-Desktop
-> Ethernet automatisch verbinden oder WLAN auswählen
-> iVentoy-Serverprofil auswählen oder Domain und Port eingeben
-> sichere Erreichbarkeit prüfen
-> verfügbare iVentoy-Bootziele anzeigen
-> ISO auswählen
-> kompatiblen Netzwerk-Bootpfad starten
```

Das System ist kein allgemeines Desktop-Linux. Es hat nur diese Aufgaben:

```text
- auf möglichst vielen x86_64-Laptops booten
- Ethernet und WLAN bereitstellen
- den iVentoy-Endpunkt erreichen
- auswählbare Bootmedien anzeigen
- das ausgewählte Bootziel starten
- verständliche Diagnose, Neustart und Ausschalten anbieten
```

## Repository-Inhalt

Das veröffentlichte Repository enthält ausschließlich:

```text
README.md
zu_erstellen_und_integriren
setup.sh
remote-iventoy-boot-usb-amd64.iso
```

Bedeutung:

```text
README.md
-> vollständiges Zielbild, Buildverfahren, Betrieb und Tests

zu_erstellen_und_integriren
-> Projektlogo für Repository, Bootoberfläche und ISO-Branding

setup.sh
-> vollständige, reproduzierbare Anpassung der in Cubic geöffneten Ubuntu-LTS-ISO

remote-iventoy-boot-usb-amd64.iso
-> fertig erzeugtes USB-/DVD-Bootimage
```

Temporäre Cubic-Projekte, Paketdownloads, Logs, Testabbilder, Schlüssel und Buildverzeichnisse gehören nicht in das Repository.

## Technischer Grundsatz

Das Projekt verwendet Ubuntu LTS als Hardware- und Sicherheitsbasis:

```text
Ubuntu-LTS-Kernel
Ubuntu-Firmware
Ubuntu-Sicherheitsupdates
NetworkManager
systemd
Casper-Live-System
signierte Ubuntu-UEFI-Bootkette
```

Es wird kein Linux From Scratch aufgebaut. `setup.sh` entfernt nicht blind alles, sondern reduziert Ubuntu kontrolliert auf die für Live-Boot, Hardware, Netzwerk, Oberfläche, Sicherheit, Diagnose und Remote-Boot notwendigen Komponenten.

## iVentoy und Remotezugriff

iVentoy ist ein PXE-/HTTPBoot-Server. Auf Linux wird es aus dem offiziellen Paket entpackt, mit `iventoy.sh start` gestartet und über die Weboberfläche auf Port `26000` verwaltet. ISO-Dateien liegen im Verzeichnis `iso`; iVentoy empfiehlt für spätere Upgrades, den gesamten ISO-Ordner extern zu halten und per Symlink einzubinden. citeturn31search156turn31search157

Ein Cloudflare Tunnel zur iVentoy-Weboberfläche allein ist nicht gleichbedeutend mit einem vollständigen Remote-PXE-Pfad. PXE verwendet je nach Konfiguration DHCP beziehungsweise ProxyDHCP, TFTP und anschließend HTTP; Broadcast- und UDP-basierte Schritte werden durch eine normale veröffentlichte HTTPS-Weboberfläche nicht automatisch transportiert. citeturn31search158

Darum trennt RIBU:

```text
Adminzugriff
-> iVentoy-Weboberfläche
-> optional über Cloudflare Access geschützt
-> ausschließlich für Administration

Bootzugriff
-> verschlüsselter, gerouteter Zugang zum Bootnetz
-> Standard: WireGuard
-> Zugriff nur auf die für iVentoy notwendigen internen Ziele und Ports
```

Die RIBU-Oberfläche darf nicht einfach die administrative iVentoy-Weboberfläche ungeschützt einblenden. Sie zeigt eine für den Client gedachte Bootauswahl. Die Liste stammt aus einer read-only, signierten Zielbeschreibung des Servers oder aus einem ausdrücklich implementierten iVentoy-Katalogadapter.

## Unterstützter Serveraufbau

```text
Ubuntu Server LTS
-> iVentoy
-> externer ISO-Speicher
-> WireGuard-Endpunkt
-> read-only Bootkatalog
-> optional Cloudflare Access für Administration
```

Empfohlene Serverpfade:

```text
/opt/iventoy-<version>/
/opt/iventoy -> /opt/iventoy-<version>/
/srv/iventoy/iso/
/srv/iventoy/backup/
```

Der iVentoy-Ordner `iso` verweist per Symlink auf `/srv/iventoy/iso/`. Pfade und ISO-Namen enthalten keine Leerzeichen oder problematische Unicode-Zeichen. Diese Einschränkung und die Symlink-Möglichkeit sind in der offiziellen iVentoy-Dokumentation beschrieben. citeturn31search156

Serverstart:

```bash
cd /opt/iventoy
sudo bash iventoy.sh start
```

Nach einmaliger Konfiguration und gespeichertem PXE-Start:

```bash
cd /opt/iventoy
sudo bash iventoy.sh -R start
```

Die konkrete iVentoy-Version wird nicht in `setup.sh` des USB-Clients installiert. RIBU ist der Client; iVentoy wird getrennt auf dem Server betrieben.

## Buildumgebung

### Voraussetzungen

```text
- Ubuntu LTS x86_64 als Buildrechner
- Cubic bereits installiert
- offizielle Ubuntu-LTS-Desktop-amd64-ISO
- freier Speicher für Cubic-Projekt und ISO-Ausgabe
- Internetzugang für Ubuntu-Pakete
- dieses Repository lokal verfügbar
```

Cubic ist ein GUI-Assistent zum Erzeugen angepasster Ubuntu- und Debian-basierter Live-ISOs und stellt dafür eine integrierte Chroot-Umgebung bereit. citeturn31search162turn31search165

## Verwendung mit Cubic

### 1. Cubic-Projekt anlegen

```text
1. Cubic starten.
2. Ein neues, leeres Projektverzeichnis wählen.
3. Eine offiziell unterstützte Ubuntu-LTS-Desktop-amd64-ISO auswählen.
4. Cubic die ISO extrahieren lassen.
5. Bis zur Chroot-Terminalseite fortfahren.
```

### 2. Repository-Dateien in die Cubic-Chroot bringen

Auf der Chroot-Terminalseite müssen mindestens diese Dateien erreichbar sein:

```text
setup.sh
zu_erstellen_und_integriren
```

Die Dateien werden entweder über einen von Cubic sichtbaren Pfad eingebunden oder vor dem Start in die Chroot kopiert.

### 3. Skript ausführen

In der Cubic-Chroot:

```bash
chmod +x ./setup.sh
sudo ./setup.sh
```

Das Skript erkennt, dass es innerhalb der Cubic-Chroot arbeitet. Außerhalb einer geeigneten Cubic-Chroot bricht es ohne Änderungen mit einer eindeutigen Meldung ab.

### 4. Cubic abschließen

Nach erfolgreichem Skriptlauf:

```text
1. Skriptzusammenfassung und Fehlerfreiheit prüfen.
2. Chroot-Seite verlassen.
3. Cubic-Paketlisten prüfen.
4. ISO-Kompression auswählen.
5. Volume-ID auf RIBU setzen.
6. ISO als remote-iventoy-boot-usb-amd64.iso erzeugen.
7. ISO außerhalb von Cubic testen.
8. Erst nach bestandenen Tests die ISO in das Repository übernehmen.
```

## Verbindlicher Umfang von setup.sh

`setup.sh` enthält alle reproduzierbaren Änderungen vom vollständigen Ubuntu-LTS-Live-System zu RIBU. Nachträgliche manuelle Änderungen in Cubic sind nicht zulässig. Muss etwas geändert werden, wird `setup.sh` angepasst und die ISO neu gebaut.

Das Skript beginnt mit:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

Es implementiert diese Phasen in genau dieser Reihenfolge:

```text
00 Voraussetzungen prüfen
10 Ubuntu-Basis und Architektur prüfen
20 APT und Paketquellen vorbereiten
30 benötigte Pakete installieren
40 nicht benötigte Pakete entfernen
50 RIBU-Dateisystem und Anwendung installieren
60 Netzwerk, WireGuard und Firewall konfigurieren
70 systemd, Benutzer und Autostart konfigurieren
80 Branding und Bootoberfläche installieren
90 Live-System und initramfs bereinigen
95 Selbsttest ausführen
99 Buildzusammenfassung ausgeben
```

### 00 Voraussetzungen prüfen

Das Skript prüft:

```text
- Ausführung als root
- Bash
- Ubuntu-LTS-Basis
- x86_64/amd64
- Cubic-Chroot-Merkmale
- schreibbares Zielrootfs
- funktionierende DNS- und Paketquellen
- Vorhandensein von zu_erstellen_und_integriren
- ausreichend freien Speicher
```

Bei einer fehlenden Voraussetzung bricht es ab, bevor Pakete oder Konfiguration verändert werden.

### 10 Basis erfassen

Das Skript speichert für die Buildzusammenfassung:

```text
Ubuntu-Version
Kernelpakete
Architektur
Zeitpunkt
installierte Paketliste vor Anpassung
Git-Commit oder lokal verfügbare Skriptprüfsumme
```

Es baut keine versteckten Telemetrie- oder Netzwerkfunktionen ein.

### 20 APT vorbereiten

```text
- apt-get update ausführen
- niemals apt-key verwenden
- nur Ubuntu-Paketquellen der gewählten LTS verwenden
- keine zufälligen Fremd-PPAs in das fertige Image übernehmen
- DEBIAN_FRONTEND=noninteractive setzen
- Paketinstallationen ohne Empfehlungen durchführen, sofern Abhängigkeiten geprüft sind
```

### 30 Benötigte Pakete installieren

Mindestens erforderlich:

```text
network-manager
wpasupplicant
wireguard-tools
nftables
iproute2
iputils-ping
ethtool
rfkill
ca-certificates
curl
jq
openssl
kexec-tools
systemd-timesyncd
linux-firmware
pciutils
usbutils
zenity oder fest gewählte GTK-Laufzeit
plymouth
```

Die tatsächlich installierte Liste wird für die verwendete Ubuntu-LTS-Version im Skript gepflegt. Paketnamen werden nicht stillschweigend ignoriert. Fehlt ein Pflichtpaket, schlägt der Build fehl.

### 40 Ubuntu minimieren

Entfernt werden dürfen unter anderem:

```text
LibreOffice
Thunderbird
Spiele
allgemeine Medienanwendungen
Hilfe- und Tour-Anwendungen
Snap-Anwendungen ohne RIBU-Funktion
Ubuntu-Installer für die interne Festplatte
normaler Desktop-Autostart
Entwicklungswerkzeuge
Cubic-Komponenten innerhalb des Zielabbilds
```

Nicht entfernt werden dürfen, solange keine getestete Alternative existiert:

```text
Kernel
initramfs-tools
casper
systemd
udev
D-Bus
Polkit
NetworkManager
DNS- und Zeitunterbau
CA-Zertifikate
WLAN- und Ethernet-Firmware
Grafik- und Eingabetreiber
GRUB, shim und UEFI-Bootkomponenten
```

Nach jeder Paketentfernung führt das Skript `apt-get check` aus. Ein kaputtes Abhängigkeitsmodell beendet den Build.

### 50 RIBU-Anwendung installieren

Das Skript legt an:

```text
/opt/ribu/
  bin/
  lib/
  ui/
  assets/zu_erstellen_und_integriren

/etc/ribu/
  ribu.conf
  trusted-servers.json
  boot-signing-public-key.pem

/var/lib/ribu/
/var/log/ribu/
/run/ribu/
```

Die fertige Anwendung stellt bereit:

```text
- Vollbildoberfläche
- NetworkManager-Anbindung
- Ethernetstatus
- WLAN-Scan und WLAN-Anmeldung
- Serverprofil beziehungsweise Domain-und-Port-Eingabe
- WireGuard-Verbindungsstatus
- TLS- und Signaturprüfung
- read-only Bootzielliste
- Architektur- und Firmwarefilter
- Downloadfortschritt
- Neustart und Ausschalten
- redigierte Diagnose
```

Es erscheint kein normaler Ubuntu-Desktop.

### 60 Netzwerk und Sicherheit konfigurieren

```text
- Ethernet per DHCP automatisch versuchen
- WLAN über NetworkManager steuern
- WLAN-Passwort nur flüchtig verwenden
- eingehenden Verkehr standardmäßig blockieren
- ausgehend nur DNS, NTP, VPN und freigegebene Bootendpunkte zulassen
- WireGuard-Konfiguration nicht mit privatem Produktionsschlüssel im öffentlichen ISO ausliefern
- TLS niemals mit --insecure umgehen
- Serverzertifikat und signierten Bootkatalog prüfen
```

Manuelle Servereingabe:

```text
Domain oder IP
Port
Serverprofilname
```

Die Eingabe wird normalisiert und gegen erlaubte Formate geprüft. Shellzeichen werden niemals direkt in Befehle übernommen.

### 70 systemd und Benutzer

Das Skript richtet einen unprivilegierten Benutzer `ribu` und ein eigenes Target ein:

```text
ribu.target
NetworkManager.service
systemd-timesyncd.service
ribu-firewall.service
ribu-ui.service
```

Die UI startet automatisch. Root-Anmeldung, SSH, VNC und andere Remoteverwaltungsdienste bleiben deaktiviert.

Erforderliche privilegierte Aktionen laufen über kleine, fest definierte Helper und Polkit-Regeln:

```text
Netzwerk verbinden
WireGuard aktivieren/deaktivieren
Neustart
Ausschalten
validiertes Bootziel übergeben
```

Die UI erhält kein allgemeines Rootrecht.

### 80 Branding

```text
- zu_erstellen_und_integriren nach /opt/ribu/assets/zu_erstellen_und_integriren kopieren
- Vollbildoberfläche mit Projektname und Logo versehen
- Plymouth-Branding auf RIBU setzen
- Ubuntu-Desktop-Hintergrund und normale Shell nicht anzeigen
- Bootfehler weiterhin lesbar halten
```

Das Logo wird nicht im Skript eingebettet, sondern aus `zu_erstellen_und_integriren` übernommen.

### 90 Bereinigung

Vor Abschluss entfernt das Skript:

```text
APT-Paketcache
temporäre Downloads
Shell-Historien
Machine-ID
zufällig erzeugte SSH-Hostkeys
Buildlogs mit Umgebungsdaten
verwaiste Pakete
Cubic-spezifische temporäre Dateien im Zielrootfs
```

Danach:

```text
update-initramfs -c beziehungsweise -u für die installierten Kernel
systemctl presets kontrolliert anwenden
Dateirechte prüfen
fehlende Bibliotheken erkennen
```

### 95 Selbsttest

Der Build schlägt fehl, wenn mindestens einer dieser Tests fehlschlägt:

```text
NetworkManager vorhanden und aktivierbar
RIBU-UI vorhanden und ausführbar
zu_erstellen_und_integriren vorhanden und valides SVG
CA-Zertifikate vorhanden
WireGuard-Werkzeuge vorhanden
nftables-Regeln syntaktisch gültig
kexec vorhanden
systemd-Units syntaktisch gültig
kein aktivierter SSH-/VNC-Dienst
kein Produktions-Private-Key im Image
keine fehlenden dynamischen Bibliotheken der RIBU-Anwendung
```

## Benutzeroberfläche

### Startansicht

```text
┌──────────────────────────────────────────────────────┐
│ RIBU · Remote iVentoy Boot USB                      │
├──────────────────────────────────────────────────────┤
│ Netzwerk                                            │
│ Ethernet  Verbunden                                 │
│ WLAN      Nicht verbunden                           │
│                                                      │
│ Bootserver                                          │
│ Profil     Nicht ausgewählt                         │
│ Adresse    __________________________                │
│ Port       ______                                    │
│                                                      │
│ [WLAN] [Verbinden] [Diagnose] [Neustart] [Aus]      │
└──────────────────────────────────────────────────────┘
```

### Zielauswahl

```text
┌──────────────────────────────────────────────────────┐
│ Bootziel auswählen                                  │
├──────────────────────────────────────────────────────┤
│ Ubuntu Rescue             Linux · x86_64 · UEFI     │
│ Windows Setup             Windows · x86_64 · UEFI   │
│ Hardware Diagnostics      Utility · x86_64 · UEFI   │
│                                                      │
│ [Starten] [Details] [Aktualisieren] [Zurück]         │
└──────────────────────────────────────────────────────┘
```

### Zustände

```text
BOOTING
NETWORK_REQUIRED
NETWORK_CONNECTING
SERVER_REQUIRED
TUNNEL_CONNECTING
SERVER_VERIFYING
TARGETS_LOADING
TARGET_SELECTION
TARGET_DOWNLOADING
TARGET_VERIFYING
TARGET_BOOTING
ERROR
```

Ein Fehler startet niemals ungeprüft ein Bootziel. Die Oberfläche bietet Wiederholen, Zurück und Diagnose.

## Bootziel und ISO-Auswahl

iVentoy kann zahlreiche ISO-Typen direkt über PXE beziehungsweise HTTPBoot bereitstellen und unterstützt laut Hersteller Legacy BIOS sowie mehrere UEFI-Architekturen. citeturn31search157

RIBU ist jedoch bereits ein gestartetes Linux-System. Ein ausgewähltes ISO kann deshalb nicht allein durch Öffnen der iVentoy-Webseite gestartet werden.

Das Projekt unterstützt zwei technisch getrennte Übergabepfade:

```text
A. Neustart in einen getesteten iVentoy-/iPXE-/HTTPBoot-Pfad
B. Laden eines getesteten Kernel-/Initrd-Ziels und Übergabe per kexec
```

Ein Bootziel wird nur angezeigt, wenn ein passender Adapter für Architektur, Firmware und Zieltyp vorhanden und getestet ist.

Nicht zulässig:

```text
- unbekannte ISO blind an kexec übergeben
- unvalidierte Kernelparameter aus dem Netzwerk ausführen
- Prüfsummen oder Signaturen überspringen
- annehmen, dass ein im ersten Linux aufgebauter VPN-Tunnel einen Neustart überlebt
```

## ISO-Datei

Der Repository-Release enthält genau eine fertige ISO:

```text
remote-iventoy-boot-usb-amd64.iso
```

Zusätzlich zum Repository-Download sollte jeder Release außerhalb des Repository-Inhalts veröffentlichen:

```text
SHA-256-Prüfsumme
Signatur der Prüfsumme oder des Release-Artefakts
Ubuntu-LTS-Basisversion
Buildskript-Commit
Liste bestandener Tests
```

Diese Release-Metadaten werden nicht als weitere feste Repository-Dateien geführt.

## USB-Stick erstellen

Vor dem Schreiben die ISO-Prüfsumme kontrollieren.

Ubuntu:

```bash
lsblk
sudo umount /dev/sdX* 2>/dev/null || true
sudo dd if=remote-iventoy-boot-usb-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

`/dev/sdX` ist das gesamte Zielgerät, nicht eine Partition. Eine falsche Auswahl überschreibt Daten.

Alternativ können GNOME Disks oder ein anderer Image-Schreiber verwendet werden, der die ISO unverändert als Laufwerksabbild schreibt.

## Testmatrix

### Virtuell

```text
QEMU + OVMF UEFI
QEMU Legacy BIOS, falls unterstützt
virtio-net
E1000
kein Netzwerk
DNS-Fehler
NTP-Fehler
ungültiges TLS-Zertifikat
nicht erreichbarer VPN-Endpunkt
manipulierter Bootkatalog
falsche Artefaktprüfsumme
fehlgeschlagener Übergabepfad
```

### Physische Geräte

```text
Intel-Laptop mit Intel-WLAN
AMD-Laptop
Realtek-Ethernet
Realtek-WLAN
USB-Ethernetadapter
UEFI mit Secure Boot
UEFI ohne Secure Boot
verschiedene Displayauflösungen
Tastatur und Touchpad
Gerät ohne unterstützten WLAN-Adapter
```

### Freigabekriterien

Die ISO wird nur ersetzt, wenn:

```text
- setup.sh in einer frischen Cubic-Chroot erfolgreich durchläuft
- keine manuellen Änderungen nach dem Skript nötig sind
- ISO unter QEMU/OVMF bootet
- mindestens zwei physische Geräte booten
- Ethernet funktioniert
- definierte WLAN-Hardware funktioniert
- Server- und Zertifikatsfehler sicher behandelt werden
- manipulierte Kataloge und Artefakte abgelehnt werden
- kein privater Schlüssel im ISO gefunden wird
- UI, Neustart und Ausschalten funktionieren
- angebotene Bootadapter einzeln getestet sind
```

## Aktualisierung auf eine neue Ubuntu LTS

```text
neue offizielle Ubuntu-LTS-Desktop-amd64-ISO laden
-> neues Cubic-Projekt anlegen
-> setup.sh und zu_erstellen_und_integriren in die Chroot bringen
-> setup.sh ausführen
-> Paketänderungen oder Fehler ausschließlich im Skript korrigieren
-> ISO bauen
-> vollständige Testmatrix ausführen
-> remote-iventoy-boot-usb-amd64.iso ersetzen
```

Eine Live-ISO ist ein Snapshot. Ubuntu-Sicherheitsupdates gelangen erst durch einen neuen Build in die veröffentlichte ISO. Deshalb wird die ISO regelmäßig mit den aktuellen Paketen der unterstützten LTS neu gebaut.

## Bekannte Grenzen

```text
- Cloudflare Tunnel zur Admin-Weboberfläche ersetzt keinen vollständigen PXE-Pfad.
- WLAN-Zustand des RIBU-Linux wird nicht automatisch an einen neu gestarteten Bootloader weitergegeben.
- Secure Boot kann kexec oder unsignierte Zielkernel blockieren.
- Nicht jede ISO ist direkt per Kernel und Initrd startbar.
- Windows-Setup benötigt einen eigenen getesteten Adapter.
- Aggressive Paket- oder Firmwareentfernung verschlechtert Hardwareunterstützung.
- Ein öffentliches ISO darf keinen gemeinsamen dauerhaften VPN-Private-Key enthalten.
```

## Quellen

- [Offizielle iVentoy-Produktseite](https://iventoy.com/en/)
- [Offizielle iVentoy-Erste-Schritte-Dokumentation](https://www.iventoy.com/en/doc_start.html)
- [Offizielles Cubic-Repository](https://github.com/PJ-Singh-001/Cubic)
