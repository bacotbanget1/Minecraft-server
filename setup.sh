#!/usr/bin/env bash
# ============================================================
#  NZCloud Minecraft Server Setup & Manager
#  Version : 1.0
#  Author  : NZCloud
#  GitHub  : https://github.com/nzcloud/Minecraft_server-nzcloud
# ============================================================

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Paths ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADMIN_FILE="$SCRIPT_DIR/admin.json"
SERVER_DIR="$SCRIPT_DIR/server_data"
CONFIG_FILE="$SCRIPT_DIR/server.conf"
LOG_FILE="$SCRIPT_DIR/server.log"
PID_FILE="$SCRIPT_DIR/server.pid"
FILEMANAGER_LOCK="$REPO_ROOT/.nzcloud_fm_lock"

# ── Banner ───────────────────────────────────────────────────
print_banner() {
  clear
  echo -e "${CYAN}"
  cat << 'EOF'
  ███╗   ██╗███████╗ ██████╗██╗      ██████╗ ██╗   ██╗██████╗ 
  ████╗  ██║╚══███╔╝██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
  ██╔██╗ ██║  ███╔╝ ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ██║╚██╗██║ ███╔╝  ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ██║ ╚████║███████╗╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
  ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ 
EOF
  echo -e "${RESET}"
  echo -e "${MAGENTA}${BOLD}  ┌─────────────────────────────────────────────────┐${RESET}"
  echo -e "${MAGENTA}${BOLD}  │        Minecraft Server Manager - NZCloud        │${RESET}"
  echo -e "${MAGENTA}${BOLD}  │                  Version 1.0                     │${RESET}"
  echo -e "${MAGENTA}${BOLD}  └─────────────────────────────────────────────────┘${RESET}"
  echo ""
}

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
step()    { echo -e "${BLUE}${BOLD}[STEP]${RESET}  $*"; }
divider() { echo -e "${DIM}──────────────────────────────────────────────────${RESET}"; }

confirm_prompt() {
  local msg="$1"
  read -rp "$(echo -e "${YELLOW}${msg} [y/N]: ${RESET}")" ans
  [[ "${ans,,}" == "y" ]]
}

# ── Dependency Check ─────────────────────────────────────────
check_deps() {
  local missing=()
  for cmd in curl wget java python3 jq; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Dependensi berikut tidak ditemukan: ${missing[*]}"
    if command -v pkg &>/dev/null; then
      info "Terdeteksi Termux — menginstall dependensi..."
      pkg install -y curl wget openjdk-17 python3 jq 2>/dev/null || true
    elif command -v apt-get &>/dev/null; then
      info "Menginstall dependensi via apt..."
      sudo apt-get install -y curl wget default-jdk python3 jq 2>/dev/null || true
    else
      error "Silakan install manual: ${missing[*]}"
      exit 1
    fi
  fi
}

# ── Hash Password (SHA256) ───────────────────────────────────
hash_password() {
  echo -n "$1" | sha256sum | awk '{print $1}'
}

# ── Admin Auth ───────────────────────────────────────────────
require_admin_auth() {
  if [[ ! -f "$ADMIN_FILE" ]]; then
    error "File admin.json tidak ditemukan. Jalankan setup terlebih dahulu."
    exit 1
  fi

  local stored_user stored_hash
  stored_user=$(jq -r '.username' "$ADMIN_FILE")
  stored_hash=$(jq -r '.password_hash' "$ADMIN_FILE")

  echo -e "${YELLOW}${BOLD}🔐 Autentikasi Admin Diperlukan${RESET}"
  divider
  read -rp "$(echo -e "${WHITE}Username: ${RESET}")" input_user
  read -rsp "$(echo -e "${WHITE}Password: ${RESET}")" input_pass
  echo ""

  local input_hash
  input_hash=$(hash_password "$input_pass")

  if [[ "$input_user" != "$stored_user" || "$input_hash" != "$stored_hash" ]]; then
    error "Username atau password salah!"
    exit 1
  fi
  success "Autentikasi berhasil — Selamat datang, ${stored_user}!"
  divider
}

# ── Get Public IP ─────────────────────────────────────────────
get_public_ip() {
  local ip=""
  ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null) || \
  ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null) || \
  ip=$(curl -s --max-time 5 https://icanhazip.com 2>/dev/null) || \
  ip="UNKNOWN"
  echo "$ip"
}

# ── Download Server JAR ───────────────────────────────────────
download_server_jar() {
  local mc_type="$1" software="$2" version="$3" dest="$4"
  local url=""

  step "Mengunduh server $software $version ($mc_type)..."

  case "${software,,}" in
    paper)
      if [[ "${mc_type,,}" == "java" ]]; then
        local build
        build=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" \
          | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['builds'][-1])")
        url="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$build/downloads/paper-$version-$build.jar"
      else
        error "Paper tidak tersedia untuk Bedrock."
        exit 1
      fi
      ;;
    purpur)
      if [[ "${mc_type,,}" == "java" ]]; then
        url="https://api.purpurmc.org/v2/purpur/$version/latest/download"
      else
        error "Purpur tidak tersedia untuk Bedrock."
        exit 1
      fi
      ;;
    spigot)
      warn "Spigot memerlukan BuildTools. Silakan download manual dari https://getbukkit.org/download/spigot"
      exit 1
      ;;
    vanilla)
      if [[ "${mc_type,,}" == "java" ]]; then
        local manifest
        manifest=$(curl -s "https://launchermeta.mojang.com/mc/game/version_manifest.json")
        local ver_url
        ver_url=$(echo "$manifest" | python3 -c "
import sys,json
m=json.load(sys.stdin)
for v in m['versions']:
    if v['id']=='$version':
        print(v['url']); break
")
        url=$(curl -s "$ver_url" | python3 -c "import sys,json; print(json.load(sys.stdin)['downloads']['server']['url'])")
      else
        error "Gunakan 'bedrock' sebagai software untuk server Bedrock."
        exit 1
      fi
      ;;
    bedrock)
      if [[ "${mc_type,,}" == "bedrock" ]]; then
        warn "Mengunduh Bedrock Dedicated Server..."
        url="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-latest.zip"
      else
        error "Pilih tipe 'bedrock' untuk software Bedrock."
        exit 1
      fi
      ;;
    *)
      error "Software '$software' tidak dikenali. Pilihan: paper, purpur, vanilla, bedrock"
      exit 1
      ;;
  esac

  info "Mengunduh dari: ${DIM}$url${RESET}"
  if [[ "${software,,}" == "bedrock" ]]; then
    wget -q --show-progress -O "$dest/bedrock-server.zip" "$url"
    cd "$dest" && unzip -q bedrock-server.zip && rm bedrock-server.zip && cd -
  else
    wget -q --show-progress -O "$dest/server.jar" "$url"
  fi
  success "Download selesai!"
}

# ── First Setup ───────────────────────────────────────────────
run_setup() {
  print_banner
  info "Memulai setup server Minecraft pertama kali..."
  divider

  check_deps

  mkdir -p "$SERVER_DIR"

  # ── Pilih tipe Minecraft ──────────────────────────────────
  echo -e "\n${BOLD}${WHITE}[1/6] Pilih Tipe Minecraft:${RESET}"
  echo -e "  ${GREEN}1)${RESET} Java Edition"
  echo -e "  ${GREEN}2)${RESET} Bedrock Edition"
  read -rp "$(echo -e "${YELLOW}Pilih [1/2]: ${RESET}")" mc_choice
  case "$mc_choice" in
    1) MC_TYPE="java" ;;
    2) MC_TYPE="bedrock" ;;
    *) error "Pilihan tidak valid."; exit 1 ;;
  esac
  success "Tipe: $MC_TYPE"

  # ── Pilih Software ────────────────────────────────────────
  echo -e "\n${BOLD}${WHITE}[2/6] Pilih Software Server:${RESET}"
  if [[ "$MC_TYPE" == "java" ]]; then
    echo -e "  ${GREEN}1)${RESET} Paper    ${DIM}(Direkomendasikan, performa tinggi)${RESET}"
    echo -e "  ${GREEN}2)${RESET} Purpur   ${DIM}(Fork Paper, lebih banyak fitur)${RESET}"
    echo -e "  ${GREEN}3)${RESET} Vanilla  ${DIM}(Official Mojang)${RESET}"
    read -rp "$(echo -e "${YELLOW}Pilih [1/2/3]: ${RESET}")" sw_choice
    case "$sw_choice" in
      1) SOFTWARE="paper" ;;
      2) SOFTWARE="purpur" ;;
      3) SOFTWARE="vanilla" ;;
      *) error "Pilihan tidak valid."; exit 1 ;;
    esac
  else
    SOFTWARE="bedrock"
    echo -e "  ${GREEN}→${RESET} Bedrock Dedicated Server (otomatis)"
  fi
  success "Software: $SOFTWARE"

  # ── Versi Minecraft ───────────────────────────────────────
  echo -e "\n${BOLD}${WHITE}[3/6] Masukkan Versi Minecraft:${RESET}"
  echo -e "  ${DIM}Contoh: 1.21.1, 1.20.4, 1.19.4${RESET}"
  read -rp "$(echo -e "${YELLOW}Versi: ${RESET}")" MC_VERSION
  [[ -z "$MC_VERSION" ]] && { error "Versi tidak boleh kosong."; exit 1; }
  success "Versi: $MC_VERSION"

  # ── Nama Server ───────────────────────────────────────────
  echo -e "\n${BOLD}${WHITE}[4/6] Masukkan Nama Server:${RESET}"
  read -rp "$(echo -e "${YELLOW}Nama Server: ${RESET}")" SERVER_NAME
  [[ -z "$SERVER_NAME" ]] && { error "Nama server tidak boleh kosong."; exit 1; }
  success "Nama: $SERVER_NAME"

  # ── Admin Credentials ─────────────────────────────────────
  echo -e "\n${BOLD}${WHITE}[5/6] Buat Akun Admin:${RESET}"
  read -rp "$(echo -e "${YELLOW}Username Admin: ${RESET}")" ADMIN_USER
  [[ -z "$ADMIN_USER" ]] && { error "Username tidak boleh kosong."; exit 1; }

  while true; do
    read -rsp "$(echo -e "${YELLOW}Password Admin: ${RESET}")" ADMIN_PASS
    echo ""
    [[ -z "$ADMIN_PASS" ]] && { warn "Password tidak boleh kosong."; continue; }
    read -rsp "$(echo -e "${YELLOW}Konfirmasi Password: ${RESET}")" ADMIN_PASS2
    echo ""
    [[ "$ADMIN_PASS" == "$ADMIN_PASS2" ]] && break
    warn "Password tidak cocok, coba lagi."
  done

  local pass_hash
  pass_hash=$(hash_password "$ADMIN_PASS")

  # Simpan admin.json di direktori lokal (bukan repo)
  cat > "$ADMIN_FILE" << EOF
{
  "username": "$ADMIN_USER",
  "password_hash": "$pass_hash",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
  chmod 600 "$ADMIN_FILE"
  success "Akun admin '$ADMIN_USER' berhasil dibuat dan disimpan di: $ADMIN_FILE"

  # ── Generate IP & Port ────────────────────────────────────
  echo -e "\n${BOLD}${WHITE}[6/6] Konfigurasi Jaringan:${RESET}"
  info "Mendapatkan IP publik..."
  PUBLIC_IP=$(get_public_ip)
  DEFAULT_PORT=25565

  echo -e "  ${GREEN}IP Publik Anda:${RESET} ${WHITE}${BOLD}$PUBLIC_IP${RESET}"
  echo -e "  ${GREEN}Port Default:${RESET}  ${WHITE}${BOLD}$DEFAULT_PORT${RESET}"
  echo ""

  read -rp "$(echo -e "${YELLOW}Ganti IP dengan domain? (kosongkan untuk skip): ${RESET}")" CUSTOM_DOMAIN
  read -rp "$(echo -e "${YELLOW}Ganti port? (kosongkan untuk pakai $DEFAULT_PORT): ${RESET}")" CUSTOM_PORT

  SERVER_HOST="${CUSTOM_DOMAIN:-$PUBLIC_IP}"
  SERVER_PORT="${CUSTOM_PORT:-$DEFAULT_PORT}"

  # Simpan konfigurasi
  cat > "$CONFIG_FILE" << EOF
MC_TYPE=$MC_TYPE
SOFTWARE=$SOFTWARE
MC_VERSION=$MC_VERSION
SERVER_NAME=$SERVER_NAME
SERVER_HOST=$SERVER_HOST
SERVER_PORT=$SERVER_PORT
PUBLIC_IP=$PUBLIC_IP
SETUP_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  # ── Download Server ───────────────────────────────────────
  divider
  download_server_jar "$MC_TYPE" "$SOFTWARE" "$MC_VERSION" "$SERVER_DIR"

  # ── EULA (Java only) ──────────────────────────────────────
  if [[ "$MC_TYPE" == "java" ]]; then
    echo "eula=true" > "$SERVER_DIR/eula.txt"
    success "EULA otomatis disetujui."
  fi

  # ── server.properties ─────────────────────────────────────
  if [[ "$MC_TYPE" == "java" && ! -f "$SERVER_DIR/server.properties" ]]; then
    cat > "$SERVER_DIR/server.properties" << EOF
server-name=$SERVER_NAME
server-port=$SERVER_PORT
motd=$SERVER_NAME — Powered by NZCloud
max-players=20
online-mode=true
difficulty=normal
gamemode=survival
EOF
    success "server.properties dibuat."
  fi

  # Tandai bahwa setup sudah selesai
  touch "$FILEMANAGER_LOCK"

  divider
  echo -e "\n${GREEN}${BOLD}✅ Setup selesai!${RESET}\n"
  echo -e "  ${WHITE}Server  :${RESET} $SERVER_NAME"
  echo -e "  ${WHITE}Tipe    :${RESET} $MC_TYPE"
  echo -e "  ${WHITE}Software:${RESET} $SOFTWARE $MC_VERSION"
  echo -e "  ${WHITE}Alamat  :${RESET} ${CYAN}${BOLD}$SERVER_HOST:$SERVER_PORT${RESET}"
  echo ""
  echo -e "${DIM}Jalankan './setup.sh' lagi untuk mengelola server.${RESET}\n"
}

# ── Start Server ──────────────────────────────────────────────
start_server() {
  source "$CONFIG_FILE"

  if [[ -f "$PID_FILE" ]]; then
    local old_pid
    old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      warn "Server sudah berjalan (PID: $old_pid)"
      return
    fi
  fi

  step "Memulai server $SERVER_NAME..."

  if [[ "$MC_TYPE" == "java" ]]; then
    cd "$SERVER_DIR"
    nohup java -Xms512M -Xmx$(get_available_ram)M \
      -XX:+UseG1GC -XX:+ParallelRefProcEnabled \
      -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions \
      -jar server.jar nogui >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    cd -
  else
    cd "$SERVER_DIR"
    nohup ./bedrock_server >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    cd -
  fi

  sleep 2
  if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    success "Server berjalan! PID: $(cat "$PID_FILE")"
    echo -e "  ${WHITE}Alamat  :${RESET} ${CYAN}${BOLD}$SERVER_HOST:$SERVER_PORT${RESET}"
    echo -e "  ${DIM}Log     : tail -f $LOG_FILE${RESET}"
  else
    error "Server gagal dimulai. Cek log: $LOG_FILE"
  fi
}

# ── Stop Server ───────────────────────────────────────────────
stop_server() {
  if [[ ! -f "$PID_FILE" ]]; then
    warn "Server tidak sedang berjalan."
    return
  fi

  local pid
  pid=$(cat "$PID_FILE")

  if kill -0 "$pid" 2>/dev/null; then
    step "Menghentikan server (PID: $pid)..."
    kill -SIGTERM "$pid"
    sleep 3
    if kill -0 "$pid" 2>/dev/null; then
      kill -SIGKILL "$pid"
    fi
    rm -f "$PID_FILE"
    success "Server berhasil dihentikan."
  else
    warn "Proses tidak ditemukan, membersihkan PID file..."
    rm -f "$PID_FILE"
  fi
}

# ── Restart Server ────────────────────────────────────────────
restart_server() {
  step "Me-restart server..."
  stop_server
  sleep 2
  start_server
}

# ── Get Available RAM ─────────────────────────────────────────
get_available_ram() {
  local total_mb
  if command -v free &>/dev/null; then
    total_mb=$(free -m | awk '/^Mem:/{print $2}')
  else
    total_mb=1024
  fi
  # Gunakan 70% RAM yang tersedia, min 512MB
  local ram
  ram=$(( total_mb * 70 / 100 ))
  [[ $ram -lt 512 ]] && ram=512
  echo "$ram"
}

# ── Server Status ─────────────────────────────────────────────
server_status() {
  source "$CONFIG_FILE"
  echo -e "\n${BOLD}${WHITE}Status Server:${RESET}"
  divider
  echo -e "  ${WHITE}Nama    :${RESET} $SERVER_NAME"
  echo -e "  ${WHITE}Tipe    :${RESET} $MC_TYPE"
  echo -e "  ${WHITE}Software:${RESET} $SOFTWARE $MC_VERSION"
  echo -e "  ${WHITE}Alamat  :${RESET} ${CYAN}$SERVER_HOST:$SERVER_PORT${RESET}"

  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      echo -e "  ${WHITE}Status  :${RESET} ${GREEN}● RUNNING${RESET} (PID: $pid)"
    else
      echo -e "  ${WHITE}Status  :${RESET} ${RED}● STOPPED${RESET} (PID file stale)"
    fi
  else
    echo -e "  ${WHITE}Status  :${RESET} ${RED}● STOPPED${RESET}"
  fi

  divider
  echo -e "  ${DIM}RAM tersedia: $(get_available_ram) MB${RESET}"
  echo ""
}

# ── Update IP/Domain ──────────────────────────────────────────
update_network() {
  source "$CONFIG_FILE"
  echo -e "\n${BOLD}${WHITE}Update Konfigurasi Jaringan:${RESET}"
  divider
  echo -e "  ${WHITE}IP Publik Saat Ini :${RESET} $(get_public_ip)"
  echo -e "  ${WHITE}Host Saat Ini      :${RESET} $SERVER_HOST"
  echo -e "  ${WHITE}Port Saat Ini      :${RESET} $SERVER_PORT"
  echo ""

  read -rp "$(echo -e "${YELLOW}Host baru (domain/IP, kosongkan untuk skip): ${RESET}")" new_host
  read -rp "$(echo -e "${YELLOW}Port baru (kosongkan untuk skip): ${RESET}")" new_port

  [[ -n "$new_host" ]] && sed -i "s/^SERVER_HOST=.*/SERVER_HOST=$new_host/" "$CONFIG_FILE"
  [[ -n "$new_port" ]] && sed -i "s/^SERVER_PORT=.*/SERVER_PORT=$new_port/" "$CONFIG_FILE"

  success "Konfigurasi jaringan diperbarui."
  if confirm_prompt "Restart server sekarang?"; then
    restart_server
  fi
}

# ── Show Logs ─────────────────────────────────────────────────
show_logs() {
  if [[ -f "$LOG_FILE" ]]; then
    info "Menampilkan log terakhir (Ctrl+C untuk keluar)..."
    tail -f "$LOG_FILE"
  else
    warn "Belum ada log."
  fi
}

# ── Main Menu ─────────────────────────────────────────────────
main_menu() {
  while true; do
    print_banner
    source "$CONFIG_FILE" 2>/dev/null || true
    server_status

    echo -e "${BOLD}${WHITE}Menu Utama:${RESET}"
    echo -e "  ${GREEN}1)${RESET} Start Server"
    echo -e "  ${GREEN}2)${RESET} Stop Server"
    echo -e "  ${GREEN}3)${RESET} Restart Server"
    echo -e "  ${GREEN}4)${RESET} Lihat Log Server"
    echo -e "  ${GREEN}5)${RESET} Update IP / Domain / Port"
    echo -e "  ${GREEN}6)${RESET} Lihat Status"
    echo -e "  ${RED}0)${RESET} Keluar"
    divider
    read -rp "$(echo -e "${YELLOW}Pilih menu: ${RESET}")" choice

    case "$choice" in
      1) start_server ;;
      2) stop_server ;;
      3) restart_server ;;
      4) show_logs ;;
      5) update_network ;;
      6) server_status ;;
      0) info "Keluar. Server tetap berjalan di background."; exit 0 ;;
      *) warn "Pilihan tidak valid." ;;
    esac

    echo ""
    read -rp "$(echo -e "${DIM}Tekan Enter untuk kembali ke menu...${RESET}")" _
  done
}

# ── Entry Point ───────────────────────────────────────────────
main() {
  print_banner

  # Cek apakah sudah ada file lock (file manager mode)
  if [[ -f "$FILEMANAGER_LOCK" ]]; then
    # Server sudah pernah di-setup — wajib autentikasi
    echo -e "${MAGENTA}${BOLD}Server sudah dikonfigurasi. Autentikasi diperlukan.${RESET}\n"
    require_admin_auth
    main_menu
  else
    # Setup pertama kali
    if [[ -f "$CONFIG_FILE" && -f "$ADMIN_FILE" ]]; then
      # Konfigurasi ada tapi lock tidak ada (kasus edge)
      touch "$FILEMANAGER_LOCK"
      require_admin_auth
      main_menu
    else
      info "Setup awal terdeteksi. Memulai konfigurasi server..."
      divider
      run_setup
      echo ""
      if confirm_prompt "Mulai server sekarang?"; then
        start_server
      fi
      echo ""
      if confirm_prompt "Buka menu manajemen server?"; then
        main_menu
      fi
    fi
  fi
}

main "$@"
