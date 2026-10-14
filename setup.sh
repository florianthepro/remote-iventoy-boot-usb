#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

LOG_PREFIX='[RIBU setup]'
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSET_SRC="${ROOT_DIR}/zu_erstellen_und_integriren"

log() {
  echo "${LOG_PREFIX} $*"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
  exit 1
}

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    fail "Dieser Build muss als root ausgeführt werden."
  fi
}

check_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    fail "/etc/os-release fehlt. Das Skript arbeitet nur in Ubuntu-LTS-Umgebungen."
  fi

  if ! grep -Eq '^ID=ubuntu$' /etc/os-release; then
    fail "Das Skript läuft nur auf Ubuntu."
  fi

  if ! grep -Eq '^VERSION_ID=' /etc/os-release; then
    fail "Ubuntu-Version konnte nicht erkannt werden."
  fi

  local version
  version="$(. /etc/os-release && echo "${VERSION_ID}")"
  if [[ ! "${version}" =~ ^(20\.04|22\.04|24\.04)$ ]]; then
    fail "Nur Ubuntu LTS 20.04/22.04/24.04 werden unterstützt. Gefunden: ${version}"
  fi
}

check_arch() {
  if [[ "$(uname -m)" != "x86_64" ]]; then
    fail "RIBU unterstützt nur amd64/x86_64. Gefunden: $(uname -m)"
  fi
}

check_cubic_chroot() {
  if [[ -f /cdrom/.disk/info ]] || [[ -d /var/lib/cubic ]] || [[ -d /tmp/cubic ]]; then
    return 0
  fi

  if [[ -f /etc/cubic.conf ]] || [[ -f /etc/cubic.env ]]; then
    return 0
  fi

  fail "Das Skript muss in einer geeigneten Cubic-Chroot ausgeführt werden."
}

install_packages() {
  log "APT-Update und Pakete installieren"
  apt-get update
  apt-get install -y --no-install-recommends \
    network-manager \
    wpasupplicant \
    wireguard-tools \
    nftables \
    iproute2 \
    iputils-ping \
    ethtool \
    rfkill \
    ca-certificates \
    curl \
    jq \
    openssl \
    kexec-tools \
    systemd-timesyncd \
    linux-firmware \
    pciutils \
    usbutils \
    zenity \
    plymouth \
    policykit-1 \
    systemd \
    dbus \
    udev

  apt-get clean
}

create_ribu_user() {
  if ! id ribu >/dev/null 2>&1; then
    log "Erzeuge Benutzer ribu"
    useradd --system --home-dir /var/lib/ribu --create-home --shell /usr/sbin/nologin ribu
  fi
}

copy_logo() {
  if [[ ! -f "${ASSET_SRC}" ]]; then
    fail "Logo-Datei fehlt: ${ASSET_SRC}."
  fi

  install -d /opt/ribu/assets
  install -m 0644 "${ASSET_SRC}" /opt/ribu/assets/zu_erstellen_und_integriren
}

create_directories() {
  install -d -o root -g root -m 0755 /opt/ribu/bin /opt/ribu/lib /opt/ribu/ui /opt/ribu/assets
  install -d -o root -g root -m 0755 /etc/ribu /var/lib/ribu /var/log/ribu /run/ribu
  chown -R ribu:ribu /var/lib/ribu /var/log/ribu /run/ribu
}

create_ribu_ui() {
  cat > /opt/ribu/bin/ribu-ui <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

/usr/bin/zenity --info \
  --title='RIBU · Remote iVentoy Boot USB' \
  --text='Remote iVentoy Boot USB\n\nEinrichtung erfolgreich bestätigt.\n\nDieses Stub-Frontend ist eine Platzhalter-UI für den Build.' \
  --width=520 --height=260
EOF
  chmod 0755 /opt/ribu/bin/ribu-ui
}

create_config() {
  cat > /etc/ribu/ribu.conf <<'EOF'
[general]
project_name = Remote iVentoy Boot USB
project_short = RIBU
boot_mode = live
wifi_enabled = true
ethernet_enabled = true
server_verify_tls = true
accept_unsigned_boot_catalog = false

[paths]
ui_binary = /opt/ribu/bin/ribu-ui
asset_logo = /opt/ribu/assets/zu_erstellen_und_integriren
log_dir = /var/log/ribu
state_dir = /var/lib/ribu
run_dir = /run/ribu
EOF

  cat > /etc/ribu/trusted-servers.json <<'EOF'
{
  "trusted_hosts": [],
  "allow_insecure_tls": false,
  "require_server_name_match": true
}
EOF

  touch /etc/ribu/boot-signing-public-key.pem
  chmod 0640 /etc/ribu/ribu.conf /etc/ribu/trusted-servers.json /etc/ribu/boot-signing-public-key.pem
}

write_ribu_service() {
  cat > /etc/systemd/system/ribu-ui.service <<'EOF'
[Unit]
Description=RIBU UI Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/ribu/bin/ribu-ui
Restart=on-failure
User=ribu
Group=ribu
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/ribu/.Xauthority
WorkingDirectory=/opt/ribu

[Install]
WantedBy=default.target
EOF

  cat > /etc/systemd/system/ribu.target <<'EOF'
[Unit]
Description=RIBU Live Environment Target
Wants=NetworkManager.service
Wants=systemd-timesyncd.service
Wants=ribu-ui.service
After=NetworkManager.service
After=systemd-timesyncd.service

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl preset ribu-ui.service ribu.target || true
}

configure_networking() {
  log "Netzwerk- und Firewall-Basis konfigurieren"

  if ! grep -Eq '^\[main\]' /etc/NetworkManager/NetworkManager.conf 2>/dev/null; then
    cat > /etc/NetworkManager/NetworkManager.conf <<'EOF'
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=false
EOF
  fi

  cat > /etc/nftables.conf <<'EOF'
#!/usr/sbin/nft -f
flush ruleset

define interface_lo = lo

table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    iifname "lo" accept
    ct state established,related accept
    icmp type echo-request accept
    udp dport 67 accept
    udp dport 68 accept
    tcp dport 53 accept
    udp dport 53 accept
    udp dport 123 accept
    tcp dport 443 accept
    udp dport 443 accept
    reject with icmpx admin-prohibited
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
  }

  chain output {
    type filter hook output priority 0; policy accept;
  }
}
EOF
  chmod 0755 /etc/nftables.conf
}

disable_default_desktop() {
  log "Standard-Desktop-Autostart deaktivieren"
  rm -f /etc/xdg/autostart/ubuntu-desktop-bootstrap.desktop \
        /etc/xdg/autostart/ubuntu-desktop.desktop \
        /etc/xdg/autostart/gnome-initial-setup.desktop || true

  if [[ -d /etc/systemd/system/multi-user.target.wants ]]; then
    rm -f /etc/systemd/system/multi-user.target.wants/plymouth-quit.service || true
  fi
}

update_initramfs() {
  log "initramfs aktualisieren"
  update-initramfs -u || true
}

cleanup_build_artifacts() {
  log "Temporäre Builddaten bereinigen"
  apt-get clean || true
  find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + || true
  rm -rf /root/.bash_history /root/.cache /root/.local /var/tmp/* || true
}

self_test() {
  log "Selftests laufen"

  [[ -x /opt/ribu/bin/ribu-ui ]] || fail "RIBU-UI fehlt oder ist nicht ausführbar"
  [[ -f /etc/ribu/ribu.conf ]] || fail "RIBU-Konfiguration fehlt"
  [[ -f /opt/ribu/assets/zu_erstellen_und_integriren ]] || fail "Logo-Datei fehlt im Ziel"
  command -v NetworkManager >/dev/null || fail "NetworkManager fehlt"
  command -v wg >/dev/null || fail "WireGuard fehlt"
  command -v nft >/dev/null || fail "nftables fehlt"
  command -v kexec >/dev/null || fail "kexec fehlt"
  systemctl cat ribu-ui.service >/dev/null 2>&1 || fail "ribu-ui.service ist nicht valid"
  systemctl cat ribu.target >/dev/null 2>&1 || fail "ribu.target ist nicht valid"
}

print_summary() {
  . /etc/os-release
  echo
  echo "${LOG_PREFIX} Buildzusammenfassung"
  echo "Ubuntu-LTS-Basis: ${NAME} ${VERSION_ID}"
  echo "Architektur: $(uname -m)"
  echo "Projekt: Remote iVentoy Boot USB"
  echo "UI: /opt/ribu/bin/ribu-ui"
  echo "Asset: /opt/ribu/assets/zu_erstellen_und_integriren"
  echo "Konfig: /etc/ribu/ribu.conf"
  echo "Netzwerk: NetworkManager + nftables"
  echo "Ziel: ISO kann in Cubic neu erzeugt werden, sobald alle physischen Tests bestanden sind."
}

main() {
  require_root
  check_ubuntu
  check_arch
  check_cubic_chroot
  create_directories
  copy_logo
  install_packages
  create_ribu_user
  create_ribu_ui
  create_config
  write_ribu_service
  configure_networking
  disable_default_desktop
  update_initramfs
  cleanup_build_artifacts
  self_test
  print_summary
}

main "$@"
