#!/usr/bin/env bash
# ============================================================
#  NZCloud Minecraft Server Setup & Manager
#  Version : 1.5
#  Author  : NazamaCloud
#  GitHub  : https://github.com/bacotbanget1/Minecraft-server
#  Tunnel  : playit.gg (publik tanpa port forwarding)
# ============================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────
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
PLAYIT_LOG="$SCRIPT_DIR/playit.log"
PID_FILE="$SCRIPT_DIR/server.pid"
PLAYIT_PID="$SCRIPT_DIR/playit.pid"
PLAYIT_BIN="$SCRIPT_DIR/playit"
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
  echo -e "${MAGENTA}${BOLD}  │         Tunnel: playit.gg  |  Version 1.0        │${RESET}"
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
  read -rp "$(echo -e "${YELLOW}$1 [y/N]: ${RESET}")" ans
  [[ "${ans,,}" == "y" ]]
}

# ── Detect Platform ───────────────────────────────────────────
detect_platform() {
  ARCH=$(uname -m)
  OS=$(uname -s)

  # Deteksi Termux
  if [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]]; then
    PLATFORM="termux"
  elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
  elif [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
  else
    PLATFORM="linux"
  fi

  # Arch untuk playit binary
  case "$ARCH" in
    x86_64)           PLAYIT_ARCH="x86_64" ;;
    aarch64|arm64)    PLAYIT_ARCH="aarch64" ;;
    armv7l|armv7)     PLAYIT_ARCH="armv7" ;;
    i686|i386)        PLAYIT_ARCH="i686" ;;
    *)                PLAYIT_ARCH="x86_64" ;;
  esac
}

# ── Install Dependencies ──────────────────────────────────────
check_deps() {
  local missing=()
  for cmd in curl wget java python3 jq unzip; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    success "Semua dependensi tersedia."
    return
  fi

  warn "Dependensi tidak ditemukan: ${missing[*]}"

  case "$PLATFORM" in
    termux)
      info "Menginstall via pkg (Termux)..."
      pkg update -y 2>/dev/null || true
      pkg install -y curl wget openjdk-17 python3 jq unzip 2>/dev/null || true
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        info "Menginstall via apt..."
        sudo apt-get update -qq
        sudo apt-get install -y curl wget default-jdk python3 jq unzip
      elif command -v pacman &>/dev/null; then
        info "Menginstall via pacman..."
        sudo pacman -Sy --noconfirm curl wget jdk-openjdk python jq unzip
      elif command -v dnf &>/dev/null; then
        info "Menginstall via dnf..."
        sudo dnf install -y curl wget java-17-openjdk python3 jq unzip
      elif command -v yum &>/dev/null; then
        info "Menginstall via yum..."
        sudo yum install -y curl wget java-17-openjdk python3 jq unzip
      else
        error "Package manager tidak dikenali. Install manual: ${missing[*]}"
        exit 1
      fi
      ;;
    macos)
      if command -v brew &>/dev/null; then
        info "Menginstall via Homebrew..."
        brew install curl wget openjdk python3 jq
      else
        error "Homebrew tidak ditemukan. Install dari https://brew.sh lalu coba lagi."
        exit 1
      fi
      ;;
  esac

  success "Dependensi berhasil diinstall."
}

# ── Install playit.gg ─────────────────────────────────────────
install_playit() {
  if [[ -f "$PLAYIT_BIN" ]]; then
    success "playit.gg sudah terinstall."
    return
  fi

  step "Menginstall playit.gg tunnel..."

  local url=""
  case "$PLATFORM" in
    termux)
      case "$PLAYIT_ARCH" in
        aarch64) url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-aarch64" ;;
        armv7)   url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-armv7" ;;
        x86_64)  url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64" ;;
        *)       url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-aarch64" ;;
      esac
      ;;
    linux)
      case "$PLAYIT_ARCH" in
        x86_64)  url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64" ;;
        aarch64) url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-aarch64" ;;
        armv7)   url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-armv7" ;;
        i686)    url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-i686" ;;
        *)       url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64" ;;
      esac
      ;;
    macos)
      url="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-darwin-amd64"
      ;;
  esac

  info "Download playit binary dari: ${DIM}$url${RESET}"
  if wget -q --show-progress -O "$PLAYIT_BIN" "$url"; then
    chmod +x "$PLAYIT_BIN"
    success "playit.gg berhasil diinstall di: $PLAYIT_BIN"
  else
    # Fallback: coba curl
    if curl -L --progress-bar -o "$PLAYIT_BIN" "$url"; then
      chmod +x "$PLAYIT_BIN"
      success "playit.gg berhasil diinstall (via curl)."
    else
      error "Gagal mendownload playit.gg. Cek koneksi internet."
      exit 1
    fi
  fi
}

# ── Hash Password ─────────────────────────────────────────────
hash_password() {
  echo -n "$1" | sha256sum | awk '{print $1}'
}

# ── Admin Auth ────────────────────────────────────────────────
require_admin_auth() {
  if [[ ! -f "$ADMIN_FILE" ]]; then
    error "File admin.json tidak ditemukan. Jalankan setup terlebih dahulu."
    exit 1
  fi

  local stored_user stored_hash
  stored_user=$(jq -r '.username' "$ADMIN_FILE")
  stored_hash=$(jq -r '.password_hash' "$ADMIN_FILE")

  echo -e "${YELLOW}${BOLD}Autentikasi Admin Diperlukan${RESET}"
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

# ── Download Server JAR ───────────────────────────────────────
download_server_jar() {
  local mc_type="$1" software="$2" version="$3" dest="$4"
  local url=""

  step "Mengunduh server $software $version ($mc_type)..."

  case "${software,,}" in
    paper)
      local build
      build=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['builds'][-1])")
      url="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$build/downloads/paper-$version-$build.jar"
      wget -q --show-progress -O "$dest/server.jar" "$url"
      ;;
    purpur)
      url="https://api.purpurmc.org/v2/purpur/$version/latest/download"
      wget -q --show-progress -O "$dest/server.jar" "$url"
      ;;
    vanilla)
      local manifest ver_url
      manifest=$(curl -s "https://launchermeta.mojang.com/mc/game/version_manifest.json")
      ver_url=$(echo "$manifest" | python3 -c "
import sys,json
m=json.load(sys.stdin)
for v in m['versions']:
    if v['id']=='$version':
        print(v['url']); break
")
      if [[ -z "$ver_url" ]]; then
        error "Versi '$version' tidak ditemukan di manifest Mojang."
        exit 1
      fi
      url=$(curl -s "$ver_url" | python3 -c "import sys,json; print(json.load(sys.stdin)['downloads']['server']['url'])")
      wget -q --show-progress -O "$dest/server.jar" "$url"
      ;;
    bedrock)
      warn "Mengunduh Bedrock Dedicated Server..."
      url="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-latest.zip"
      wget -q --show-progress -O "$dest/bedrock-server.zip" "$url"
      cd "$dest" && unzip -q bedrock-server.zip && rm bedrock-server.zip
      chmod +x bedrock_server
      cd - > /dev/null
      ;;
    *)
      error "Software '$software' tidak dikenali. Pilihan: paper, purpur, vanilla, bedrock"
      exit 1
      ;;
  esac

  success "Download selesai!"
}

# ── Get Available RAM ─────────────────────────────────────────
get_available_ram() {
  local total_mb=1024
  if command -v free &>/dev/null; then
    total_mb=$(free -m | awk '/^Mem:/{print $2}')
  elif [[ "$PLATFORM" == "macos" ]]; then
    total_mb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 ))
  fi
  local ram=$(( total_mb * 70 / 100 ))
  [[ $ram -lt 512 ]] && ram=512
  echo "$ram"
}

# ── Start playit tunnel ───────────────────────────────────────
start_playit() {
  # Cek apakah sudah jalan
  if [[ -f "$PLAYIT_PID" ]] && kill -0 "$(cat "$PLAYIT_PID")" 2>/dev/null; then
    info "playit.gg sudah berjalan (PID: $(cat "$PLAYIT_PID"))"
    return
  fi

  if [[ ! -f "$PLAYIT_BIN" ]]; then
    install_playit
  fi

  step "Menjalankan playit.gg tunnel..."
  nohup "$PLAYIT_BIN" >> "$PLAYIT_LOG" 2>&1 &
  echo $! > "$PLAYIT_PID"
  sleep 3

  if kill -0 "$(cat "$PLAYIT_PID")" 2>/dev/null; then
    success "playit.gg berjalan (PID: $(cat "$PLAYIT_PID"))"
    echo ""
    echo -e "${YELLOW}${BOLD}  ┌──────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${YELLOW}${BOLD}  │  PENTING: Cara dapat alamat publik playit.gg             │${RESET}"
    echo -e "${YELLOW}${BOLD}  │                                                          │${RESET}"
    echo -e "${YELLOW}${BOLD}  │  1. Buka log playit: pilih menu 'Lihat Log Tunnel'       │${RESET}"
    echo -e "${YELLOW}${BOLD}  │  2. Cari baris bertuliskan 'Claim URL' atau 'Address'    │${RESET}"
    echo -e "${YELLOW}${BOLD}  │  3. Buka URL claim di browser untuk aktivasi awal        │${RESET}"
    echo -e "${YELLOW}${BOLD}  │  4. Setelah itu alamat server kamu akan muncul           │${RESET}"
    echo -e "${YELLOW}${BOLD}  └──────────────────────────────────────────────────────────┘${RESET}"
    echo ""
  else
    error "playit.gg gagal dijalankan. Cek log: $PLAYIT_LOG"
  fi
}

# ── Stop playit tunnel ────────────────────────────────────────
stop_playit() {
  if [[ ! -f "$PLAYIT_PID" ]]; then
    return
  fi
  local pid
  pid=$(cat "$PLAYIT_PID")
  if kill -0 "$pid" 2>/dev/null; then
    kill -SIGTERM "$pid" 2>/dev/null || true
    sleep 1
    kill -SIGKILL "$pid" 2>/dev/null || true
  fi
  rm -f "$PLAYIT_PID"
}

# ── Get playit address from log ───────────────────────────────
get_playit_address() {
  if [[ ! -f "$PLAYIT_LOG" ]]; then
    echo "Belum tersedia (log tidak ada)"
    return
  fi
  # Cari alamat yang diberikan playit dari log
  local addr
  addr=$(grep -oE '[a-zA-Z0-9.-]+\.joinmc\.link:[0-9]+' "$PLAYIT_LOG" 2>/dev/null | tail -1)
  if [[ -z "$addr" ]]; then
    addr=$(grep -oE '[a-zA-Z0-9.-]+\.playit\.gg:[0-9]+' "$PLAYIT_LOG" 2>/dev/null | tail -1)
  fi
  if [[ -n "$addr" ]]; then
    echo "$addr"
  else
    echo "Sedang menghubungkan... (cek log tunnel)"
  fi
}

# ── Start Server ──────────────────────────────────────────────
start_server() {
  source "$CONFIG_FILE"

  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    warn "Server sudah berjalan (PID: $(cat "$PID_FILE"))"
    return
  fi

  step "Memulai server Minecraft: $SERVER_NAME..."

  local ram
  ram=$(get_available_ram)
  info "RAM dialokasikan: ${ram}MB (70% dari total)"

  if [[ "${MC_TYPE:-java}" == "java" ]]; then
    cd "$SERVER_DIR"
    nohup java \
      -Xms512M -Xmx${ram}M \
      -XX:+UseG1GC \
      -XX:+ParallelRefProcEnabled \
      -XX:MaxGCPauseMillis=200 \
      -XX:+UnlockExperimentalVMOptions \
      -XX:+DisableExplicitGC \
      -XX:G1NewSizePercent=30 \
      -XX:G1MaxNewSizePercent=40 \
      -XX:G1HeapRegionSize=8M \
      -jar server.jar nogui >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    cd - > /dev/null
  else
    cd "$SERVER_DIR"
    nohup ./bedrock_server >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    cd - > /dev/null
  fi

  sleep 3

  if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    success "Server Minecraft berjalan! (PID: $(cat "$PID_FILE"))"
  else
    error "Server gagal dimulai. Cek log: $LOG_FILE"
    return 1
  fi

  # Otomatis start playit tunnel
  echo ""
  start_playit

  echo ""
  divider
  echo -e "  ${WHITE}Nama Server :${RESET} $SERVER_NAME"
  echo -e "  ${WHITE}Port Lokal  :${RESET} ${SERVER_PORT:-25565}"
  local playit_addr
  playit_addr=$(get_playit_address)
  echo -e "  ${WHITE}Alamat Publik:${RESET} ${CYAN}${BOLD}${playit_addr}${RESET}"
  echo -e "  ${DIM}(Jika masih 'menghubungkan', tunggu beberapa detik lalu cek log tunnel)${RESET}"
  divider
}

# ── Stop Server ───────────────────────────────────────────────
stop_server() {
  local stopped=0

  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      step "Menghentikan server Minecraft (PID: $pid)..."
      kill -SIGTERM "$pid" 2>/dev/null || true
      sleep 3
      kill -SIGKILL "$pid" 2>/dev/null || true
      stopped=1
    fi
    rm -f "$PID_FILE"
  fi

  if [[ -f "$PLAYIT_PID" ]]; then
    step "Menghentikan playit.gg tunnel..."
    stop_playit
    stopped=1
  fi

  if [[ $stopped -eq 1 ]]; then
    success "Server dan tunnel berhasil dihentikan."
  else
    warn "Tidak ada proses yang berjalan."
  fi
}

# ── Restart Server ────────────────────────────────────────────
restart_server() {
  step "Me-restart server dan tunnel..."
  stop_server
  sleep 2
  start_server
}

# ── Server Status ─────────────────────────────────────────────
server_status() {
  source "$CONFIG_FILE" 2>/dev/null || true

  echo -e "\n${BOLD}${WHITE}Status Server:${RESET}"
  divider
  echo -e "  ${WHITE}Nama    :${RESET} ${SERVER_NAME:-N/A}"
  echo -e "  ${WHITE}Tipe    :${RESET} ${MC_TYPE:-N/A}"
  echo -e "  ${WHITE}Software:${RESET} ${SOFTWARE:-N/A} ${MC_VERSION:-}"

  # Status Minecraft
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo -e "  ${WHITE}Minecraft:${RESET} ${GREEN}● RUNNING${RESET} (PID: $(cat "$PID_FILE"))"
  else
    echo -e "  ${WHITE}Minecraft:${RESET} ${RED}● STOPPED${RESET}"
  fi

  # Status playit
  if [[ -f "$PLAYIT_PID" ]] && kill -0 "$(cat "$PLAYIT_PID")" 2>/dev/null; then
    local playit_addr
    playit_addr=$(get_playit_address)
    echo -e "  ${WHITE}Tunnel   :${RESET} ${GREEN}● RUNNING${RESET} (PID: $(cat "$PLAYIT_PID"))"
    echo -e "  ${WHITE}Alamat   :${RESET} ${CYAN}${BOLD}${playit_addr}${RESET}"
  else
    echo -e "  ${WHITE}Tunnel   :${RESET} ${RED}● STOPPED${RESET}"
    echo -e "  ${WHITE}Alamat   :${RESET} ${DIM}Tidak tersedia${RESET}"
  fi

  divider
  echo -e "  ${DIM}RAM tersedia: $(get_available_ram) MB${RESET}"
  echo ""
}

# ── Show Logs ─────────────────────────────────────────────────
show_logs() {
  if [[ -f "$LOG_FILE" ]]; then
    info "Log Minecraft (Ctrl+C untuk keluar)..."
    tail -f "$LOG_FILE"
  else
    warn "Belum ada log Minecraft."
  fi
}

show_playit_log() {
  if [[ -f "$PLAYIT_LOG" ]]; then
    info "Log playit.gg tunnel (Ctrl+C untuk keluar)..."
    echo -e "${DIM}Cari baris 'Claim URL' atau alamat .joinmc.link / .playit.gg${RESET}"
    echo ""
    tail -f "$PLAYIT_LOG"
  else
    warn "Belum ada log playit. Jalankan server terlebih dahulu."
  fi
}

# ── Update Network ────────────────────────────────────────────
update_network() {
  source "$CONFIG_FILE"
  echo -e "\n${BOLD}${WHITE}Konfigurasi Jaringan:${RESET}"
  divider
  echo -e "  ${WHITE}Port Server Saat Ini:${RESET} ${SERVER_PORT:-25565}"
  echo ""
  echo -e "  ${DIM}Catatan: Alamat publik dikelola oleh playit.gg secara otomatis.${RESET}"
  echo -e "  ${DIM}Untuk ganti port server lokal, masukkan port baru di bawah.${RESET}"
  echo ""
  read -rp "$(echo -e "${YELLOW}Port baru (kosongkan untuk skip): ${RESET}")" new_port
  if [[ -n "$new_port" ]]; then
    sed -i "s/^SERVER_PORT=.*/SERVER_PORT=$new_port/" "$CONFIG_FILE"
    # Update server.properties juga
    if [[ -f "$SERVER_DIR/server.properties" ]]; then
      sed -i "s/^server-port=.*/server-port=$new_port/" "$SERVER_DIR/server.properties"
    fi
    success "Port diperbarui ke $new_port"
    if confirm_prompt "Restart server sekarang?"; then
      restart_server
    fi
  fi
}

# ── First Setup ───────────────────────────────────────────────
run_setup() {
  print_banner
  info "Memulai setup server Minecraft pertama kali..."
  divider

  detect_platform
  info "Platform terdeteksi: ${BOLD}${PLATFORM}${RESET} (${ARCH})"
  check_deps
  install_playit

  mkdir -p "$SERVER_DIR"

  # [1/6] Tipe Minecraft
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

  # [2/6] Software
  echo -e "\n${BOLD}${WHITE}[2/6] Pilih Software Server:${RESET}"
  if [[ "$MC_TYPE" == "java" ]]; then
    echo -e "  ${GREEN}1)${RESET} Paper   ${DIM}(Direkomendasikan — performa tinggi, banyak plugin)${RESET}"
    echo -e "  ${GREEN}2)${RESET} Purpur  ${DIM}(Fork Paper dengan fitur ekstra)${RESET}"
    echo -e "  ${GREEN}3)${RESET} Vanilla ${DIM}(Server resmi Mojang)${RESET}"
    read -rp "$(echo -e "${YELLOW}Pilih [1/2/3]: ${RESET}")" sw_choice
    case "$sw_choice" in
      1) SOFTWARE="paper" ;;
      2) SOFTWARE="purpur" ;;
      3) SOFTWARE="vanilla" ;;
      *) error "Pilihan tidak valid."; exit 1 ;;
    esac
  else
    SOFTWARE="bedrock"
    echo -e "  ${GREEN}→${RESET} Bedrock Dedicated Server (otomatis dipilih)"
  fi
  success "Software: $SOFTWARE"

  # [3/6] Versi
  echo -e "\n${BOLD}${WHITE}[3/6] Masukkan Versi Minecraft:${RESET}"
  echo -e "  ${DIM}Contoh: 1.21.4, 1.20.4, 1.19.4${RESET}"
  read -rp "$(echo -e "${YELLOW}Versi: ${RESET}")" MC_VERSION
  [[ -z "$MC_VERSION" ]] && { error "Versi tidak boleh kosong."; exit 1; }
  success "Versi: $MC_VERSION"

  # [4/6] Nama Server
  echo -e "\n${BOLD}${WHITE}[4/6] Masukkan Nama Server:${RESET}"
  read -rp "$(echo -e "${YELLOW}Nama Server: ${RESET}")" SERVER_NAME
  [[ -z "$SERVER_NAME" ]] && { error "Nama tidak boleh kosong."; exit 1; }
  success "Nama: $SERVER_NAME"

  # [5/6] Admin
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
  cat > "$ADMIN_FILE" << EOF
{
  "username": "$ADMIN_USER",
  "password_hash": "$pass_hash",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
  chmod 600 "$ADMIN_FILE"
  success "Akun admin '$ADMIN_USER' tersimpan di: $ADMIN_FILE"

  # [6/6] Port
  echo -e "\n${BOLD}${WHITE}[6/6] Port Server:${RESET}"
  echo -e "  ${DIM}Alamat publik akan digenerate otomatis oleh playit.gg${RESET}"
  echo -e "  ${DIM}Port lokal default: 25565 (Java) / 19132 (Bedrock)${RESET}"
  local default_port=25565
  [[ "$MC_TYPE" == "bedrock" ]] && default_port=19132
  read -rp "$(echo -e "${YELLOW}Port server [${default_port}]: ${RESET}")" SERVER_PORT
  SERVER_PORT="${SERVER_PORT:-$default_port}"
  success "Port: $SERVER_PORT"

  # Simpan config
  cat > "$CONFIG_FILE" << EOF
MC_TYPE=$MC_TYPE
SOFTWARE=$SOFTWARE
MC_VERSION=$MC_VERSION
SERVER_NAME=$SERVER_NAME
SERVER_PORT=$SERVER_PORT
SETUP_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PLATFORM=$PLATFORM
EOF

  # Download server
  divider
  download_server_jar "$MC_TYPE" "$SOFTWARE" "$MC_VERSION" "$SERVER_DIR"

  # EULA
  if [[ "$MC_TYPE" == "java" ]]; then
    echo "eula=true" > "$SERVER_DIR/eula.txt"
    success "EULA otomatis disetujui."
  fi

  # server.properties
  if [[ "$MC_TYPE" == "java" ]]; then
    cat > "$SERVER_DIR/server.properties" << EOF
server-name=$SERVER_NAME
server-port=$SERVER_PORT
motd=$SERVER_NAME — Powered by NZCloud
max-players=20
online-mode=true
difficulty=normal
gamemode=survival
allow-nether=true
enable-command-block=false
EOF
    success "server.properties dibuat."
  fi

  touch "$FILEMANAGER_LOCK"

  divider
  echo -e "\n${GREEN}${BOLD}Setup selesai!${RESET}\n"
  echo -e "  ${WHITE}Server  :${RESET} $SERVER_NAME"
  echo -e "  ${WHITE}Tipe    :${RESET} $MC_TYPE | $SOFTWARE $MC_VERSION"
  echo -e "  ${WHITE}Port    :${RESET} $SERVER_PORT"
  echo -e "  ${CYAN}Alamat publik akan muncul setelah server distart via playit.gg${RESET}"
  echo ""
}

# ── Main Menu ─────────────────────────────────────────────────
main_menu() {
  while true; do
    print_banner
    server_status

    echo -e "${BOLD}${WHITE}Menu Utama:${RESET}"
    echo -e "  ${GREEN}1)${RESET} Start Server + Tunnel"
    echo -e "  ${GREEN}2)${RESET} Stop Server + Tunnel"
    echo -e "  ${GREEN}3)${RESET} Restart Server + Tunnel"
    echo -e "  ${GREEN}4)${RESET} Lihat Log Minecraft"
    echo -e "  ${GREEN}5)${RESET} Lihat Log Tunnel (playit.gg)"
    echo -e "  ${GREEN}6)${RESET} Ganti Port Server"
    echo -e "  ${GREEN}7)${RESET} Refresh Status"
    echo -e "  ${RED}0)${RESET} Keluar ${DIM}(server tetap berjalan)${RESET}"
    divider
    read -rp "$(echo -e "${YELLOW}Pilih menu: ${RESET}")" choice

    case "$choice" in
      1) start_server ;;
      2) stop_server ;;
      3) restart_server ;;
      4) show_logs ;;
      5) show_playit_log ;;
      6) update_network ;;
      7) server_status ;;
      0) info "Keluar. Server & tunnel tetap berjalan di background."; exit 0 ;;
      *) warn "Pilihan tidak valid." ;;
    esac

    echo ""
    read -rp "$(echo -e "${DIM}Tekan Enter untuk kembali ke menu...${RESET}")" _
  done
}

# ── Entry Point ───────────────────────────────────────────────
main() {
  detect_platform

  if [[ -f "$FILEMANAGER_LOCK" ]]; then
    print_banner
    echo -e "${MAGENTA}${BOLD}Server sudah dikonfigurasi. Login admin diperlukan.${RESET}\n"
    require_admin_auth
    main_menu
  elif [[ -f "$CONFIG_FILE" && -f "$ADMIN_FILE" ]]; then
    touch "$FILEMANAGER_LOCK"
    print_banner
    require_admin_auth
    main_menu
  else
    run_setup
    echo ""
    if confirm_prompt "Start server sekarang?"; then
      start_server
    fi
    echo ""
    if confirm_prompt "Buka menu manajemen?"; then
      main_menu
    fi
  fi
}

main "$@"
