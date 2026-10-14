# AGENTS.md

## Verbindliche Dateien

- `README.md` definiert das vollständige Zielbild, den Repository-Umfang, den Cubic-Ablauf, den Umfang von `setup.sh` und die Freigabekriterien.
- `RIBU.svg` ist das unveränderliche Projektlogo.
- `remote-iventoy-boot-usb-amd64.iso` ist das veröffentlichte Ergebnis von `setup.sh` und Cubic.
- Vor jeder Arbeit `README.md` vollständig lesen.
- Bei Unklarheiten, Widersprüchen oder fehlenden technischen Voraussetzungen nachfragen und nicht spekulieren.

## Erlaubter Repository-Umfang

Das Repository enthält ausschließlich:

```text
README.md
RIBU.svg
setup.sh
remote-iventoy-boot-usb-amd64.iso
```

Keine weiteren Dateien oder Verzeichnisse dauerhaft anlegen. Temporäre Arbeitsdateien ausschließlich außerhalb des Repositorys erzeugen und nach Abschluss entfernen.

## Bearbeitungsregeln

- `README.md` und `RIBU.svg` niemals ändern, ersetzen, umbenennen, verschieben oder löschen.
- Ausschließlich `setup.sh` bearbeiten.
- Die ISO nicht manuell verändern. Änderungen immer in `setup.sh` umsetzen und danach mit einer frischen Ubuntu-LTS-Basis in Cubic neu erzeugen.
- `remote-iventoy-boot-usb-amd64.iso` nur nach vollständig bestandener Testmatrix ersetzen.
- Keine manuellen Cubic-Schritte voraussetzen, die nicht ausdrücklich in `README.md` beschrieben sind.
- Der gesamte Umbau vom vollständigen Ubuntu-LTS-Live-System zu RIBU muss reproduzierbar durch `setup.sh` erfolgen.

## setup.sh

`setup.sh` muss:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

verwenden und außerhalb einer geeigneten Cubic-Chroot vor jeder Änderung sicher abbrechen.

Das Skript implementiert mindestens:

```text
Voraussetzungen und Cubic-Chroot prüfen
Ubuntu-LTS-Version und amd64 prüfen
APT vorbereiten
benötigte Pakete installieren
nicht benötigte Pakete kontrolliert entfernen
RIBU-Anwendung und Vollbildoberfläche erzeugen
RIBU.svg installieren
NetworkManager, WLAN und Ethernet einrichten
WireGuard, TLS-Prüfung und Firewall einrichten
systemd-Target, Dienste, Benutzer und Polkit konfigurieren
normalen Ubuntu-Desktop-Autostart deaktivieren
initramfs aktualisieren
Caches, temporäre Daten und Buildidentitäten bereinigen
Selbsttests ausführen
Buildzusammenfassung ausgeben
```

## Technische Grundsätze

- Ubuntu-LTS-Kernel, Casper, systemd, udev, NetworkManager, D-Bus, Polkit, CA-Zertifikate, Firmware sowie BIOS-/UEFI-/Secure-Boot-Komponenten nicht ungetestet entfernen.
- Hardwarefähigkeit hat Vorrang vor maximaler ISO-Minimierung.
- Keine fremden PPAs oder ungeprüften Downloads in das Zielimage übernehmen.
- TLS-Prüfung niemals deaktivieren.
- Keine Produktionsschlüssel, VPN-Private-Keys, Passwörter oder Tokens in Skript oder ISO einbetten.
- Die RIBU-Oberfläche läuft unprivilegiert. Privilegierte Aktionen nur über kleine, fest definierte Helper und minimale Polkit-Regeln ausführen.
- Eingehenden Netzwerkverkehr standardmäßig blockieren.
- Benutzereingaben für Domain, IP und Port strikt validieren und niemals direkt als Shellcode verwenden.
- Bootkatalog, Kernel, Initrd und weitere Bootartefakte vor Verwendung kryptografisch prüfen.
- Unbekannte ISO-Typen nicht als unterstützt ausgeben.
- Cloudflare-Adminzugriff nicht mit dem eigentlichen PXE-/Boot-Datenpfad verwechseln.

## Tests und Freigabe

Nach jeder Änderung mindestens prüfen:

```text
bash -n setup.sh
ShellCheck ohne unbegründete Fehler
Ausführung in einer frischen Cubic-Chroot
APT-Abhängigkeiten konsistent
RIBU.svg gültig und im Ziel vorhanden
NetworkManager und WireGuard vorhanden
nftables-Regeln syntaktisch gültig
systemd-Units verifizierbar
kein aktivierter SSH-/VNC-Dienst
keine privaten Schlüssel oder Secrets im Zielimage
RIBU-UI startet automatisch
Neustart und Ausschalten funktionieren
ISO bootet unter QEMU/OVMF
```

`remote-iventoy-boot-usb-amd64.iso` erst ersetzen, wenn zusätzlich die in `README.md` festgelegten physischen Hardware-, Netzwerk-, Sicherheits- und Bootadaptertests bestanden sind.

## Abschluss einer Änderung

Am Ende knapp ausgeben:

```text
Änderungen an setup.sh
verwendete Ubuntu-LTS-Basis
ausgeführte Tests und Ergebnisse
bekannte Grenzen oder fehlgeschlagene Tests
ob die ISO ersetzt werden darf
```
