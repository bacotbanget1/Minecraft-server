<div align="center">

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/bash/bash-original.svg" width="80" alt="Bash" />

# Minecraft Server NZCloud

**Self-hosted Minecraft server manager — jalankan di Termux, Linux, macOS, dan lainnya.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Termux%20%7C%20Linux%20%7C%20macOS-blue?style=flat-square&logo=linux&logoColor=white)](https://github.com)
[![Minecraft](https://img.shields.io/badge/Minecraft-Java%20%26%20Bedrock-62B47A?style=flat-square&logo=minecraft&logoColor=white)](https://minecraft.net)
[![Version](https://img.shields.io/badge/Version-1.0-purple?style=flat-square)](https://github.com)
[![Release](https://img.shields.io/badge/Source-bacotbanget1%2FMinecraft--server-orange?style=flat-square&logo=github)](https://github.com/bacotbanget1/Minecraft-server/releases/latest)

<br/>

> Satu script. Perangkat apapun. Server Minecraft kamu online dalam hitungan menit.

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Cara Kerja Sistem](#-cara-kerja-sistem)
- [Persiapan — Download & Upload ZIP](#-persiapan--download--upload-zip)
- [Requirements per Platform](#-requirements-per-platform)
- [Installation](#-installation)
  - [Termux (Android)](#-termux-android)
  - [Ubuntu / Debian](#-ubuntu--debian)
  - [Arch Linux / Manjaro](#-arch-linux--manjaro)
  - [macOS](#-macos)
  - [CentOS / RHEL / Fedora](#-centos--rhel--fedora)
- [Quick Start](#-quick-start)
- [Usage](#-usage)
- [File Structure](#-file-structure)
- [Security](#-security)
- [Supported Software](#-supported-software)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌐 Overview

**NZCloud Minecraft Server** adalah manajer server Minecraft berbasis Bash yang sepenuhnya otomatis dan interaktif. Dirancang untuk berjalan di hampir semua sistem Unix — termasuk **Termux (Android)**, **Ubuntu/Debian**, **Arch Linux**, **macOS**, dan lainnya.

Clone repo kamu, jalankan satu script, jawab beberapa pertanyaan, dan server Minecraft kamu sudah online dengan **IP publik nyata** — tanpa konfigurasi manual.

Setelah setup pertama, repositori kamu otomatis menjadi **file manager server**, terlindungi oleh autentikasi admin.

---

## ✨ Features

<table>
<tr>
<td>

### 🎮 Server Management
- Java & Bedrock Edition support
- Paper, Purpur, Vanilla server software
- Auto-download server JAR yang sesuai
- Start / Stop / Restart controls
- Server berjalan di background (tidak mati saat terminal ditutup)
- Live log streaming

</td>
<td>

### 🌍 Network
- Auto-deteksi **IP publik** perangkat kamu
- Port default `25565`
- Support custom domain
- Support ganti port
- Update IP/domain/port kapan saja

</td>
</tr>
<tr>
<td>

### 🔐 Security
- Setup username + password admin
- Hashing password SHA-256
- Kredensial disimpan **lokal** (tidak pernah masuk repo)
- Repo auto-terkunci setelah setup pertama
- Autentikasi wajib untuk masuk kembali

</td>
<td>

### ⚡ Performance
- RAM otomatis terdeteksi dari perangkat kamu
- 70% dari RAM tersedia dialokasikan
- G1GC JVM flags untuk performa optimal
- Jalan native — tanpa Docker, tanpa container

</td>
</tr>
</table>

---

## 🔄 Cara Kerja Sistem

```
GitHub (bacotbanget1/Minecraft-server)
        │
        │  ① Download Minecraft-server.zip
        │     dari Releases → Latest
        ▼
  Komputer / HP Kamu
        │
        │  ② Buat repo baru di GitHub kamu
        │  ③ Upload ZIP ke repo kamu
        │  ④ git clone repo kamu
        ▼
  Terminal (Termux / Linux / dll)
        │
        │  ⑤ Masuk folder, chmod +x, jalankan setup.sh
        ▼
  Server Minecraft Online 🟢
```

---

## 📥 Persiapan — Download & Upload ZIP

> **Langkah ini wajib dilakukan sebelum instalasi.** File utama diambil dari repository sumber, lalu kamu upload ke repo kamu sendiri.

### Langkah 1 — Download ZIP dari Release

Buka link berikut dan download file `Minecraft-server.zip` dari release terbaru:

```
https://github.com/bacotbanget1/Minecraft-server/releases/latest
```

Atau via terminal:

```bash
# Download langsung via curl
curl -L -o Minecraft-server.zip \
  https://github.com/bacotbanget1/Minecraft-server/releases/latest/download/Minecraft-server.zip
```

### Langkah 2 — Buat Repositori Baru di GitHub

1. Login ke [github.com](https://github.com)
2. Klik tombol **`+`** → **New repository**
3. Isi nama repo, contoh: `my-minecraft-server`
4. Set ke **Public** atau **Private** sesuai keinginan
5. Klik **Create repository**

### Langkah 3 — Upload ZIP ke Repo Kamu

**Cara A — Via GitHub Web (mudah):**

1. Buka repo baru kamu di GitHub
2. Klik **`Add file`** → **`Upload files`**
3. Upload file `Minecraft-server.zip` yang sudah di-download
4. Klik **`Commit changes`**
5. Ekstrak / gunakan file tersebut sesuai struktur folder yang ada

**Cara B — Via Terminal:**

```bash
# Buat folder dan masuk
mkdir my-minecraft-server && cd my-minecraft-server

# Ekstrak ZIP yang sudah di-download
unzip ~/Minecraft-server.zip -d .

# Init git dan push ke repo kamu
git init
git add .
git commit -m "feat: init minecraft server nzcloud"
git branch -M main
git remote add origin https://github.com/USERNAME_KAMU/my-minecraft-server.git
git push -u origin main
```

> Ganti `USERNAME_KAMU` dengan username GitHub kamu, dan `my-minecraft-server` dengan nama repo yang kamu buat.

---

## 📦 Requirements per Platform

### 🤖 Termux (Android)

```bash
pkg update && pkg upgrade -y
pkg install git curl wget openjdk-17 python3 jq unzip -y
```

> Pastikan Termux diinstall dari **F-Droid**, bukan dari Play Store (versi Play Store sudah tidak diupdate).

### 🐧 Ubuntu / Debian / Raspberry Pi OS

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget default-jdk python3 jq unzip
```

### 🎩 Arch Linux / Manjaro

```bash
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git curl wget jdk-openjdk python jq unzip
```

### 🍎 macOS

```bash
# Install Homebrew jika belum ada
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependensi
brew install git curl wget openjdk python3 jq
```

### 🎩 CentOS / RHEL / Fedora

```bash
# Fedora
sudo dnf install -y git curl wget java-17-openjdk python3 jq unzip

# CentOS / RHEL
sudo yum install -y git curl wget java-17-openjdk python3 jq unzip
```

> **Catatan:** Script akan mencoba auto-install dependensi yang kurang saat pertama kali dijalankan di Termux dan Debian/Ubuntu.

---

## 🛠️ Installation

Setelah ZIP sudah di-upload ke repo kamu (lihat [Persiapan](#-persiapan--download--upload-zip)), ikuti langkah berikut:

---

### 📱 Termux (Android)

```bash
# 1. Install dependensi
pkg update && pkg upgrade -y
pkg install git curl wget openjdk-17 python3 jq unzip -y

# 2. Clone repo KAMU (ganti USERNAME & REPO sesuai milik kamu)
git clone https://github.com/USERNAME_KAMU/my-minecraft-server.git

# 3. Masuk folder
cd my-minecraft-server/Minecraft_server-nzcloud-v1.0

# 4. Beri izin eksekusi
chmod +x setup.sh

# 5. Jalankan!
./setup.sh
```

---

### 🐧 Ubuntu / Debian

```bash
# 1. Install dependensi
sudo apt update
sudo apt install -y git curl wget default-jdk python3 jq unzip

# 2. Clone repo KAMU
git clone https://github.com/USERNAME_KAMU/my-minecraft-server.git

# 3. Masuk folder
cd my-minecraft-server/Minecraft_server-nzcloud-v1.0

# 4. Beri izin eksekusi
chmod +x setup.sh

# 5. Jalankan!
./setup.sh
```

---

### 🎩 Arch Linux / Manjaro

```bash
# 1. Install dependensi
sudo pacman -S --noconfirm git curl wget jdk-openjdk python jq unzip

# 2. Clone repo KAMU
git clone https://github.com/USERNAME_KAMU/my-minecraft-server.git

# 3. Masuk folder
cd my-minecraft-server/Minecraft_server-nzcloud-v1.0

# 4. Beri izin eksekusi
chmod +x setup.sh

# 5. Jalankan!
./setup.sh
```

---

### 🍎 macOS

```bash
# 1. Install Homebrew (jika belum)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install dependensi
brew install git curl wget openjdk python3 jq

# 3. Clone repo KAMU
git clone https://github.com/USERNAME_KAMU/my-minecraft-server.git

# 4. Masuk folder
cd my-minecraft-server/Minecraft_server-nzcloud-v1.0

# 5. Beri izin eksekusi
chmod +x setup.sh

# 6. Jalankan!
./setup.sh
```

---

### 🎩 CentOS / RHEL / Fedora

```bash
# 1. Install dependensi (Fedora)
sudo dnf install -y git curl wget java-17-openjdk python3 jq unzip

# 2. Clone repo KAMU
git clone https://github.com/USERNAME_KAMU/my-minecraft-server.git

# 3. Masuk folder
cd my-minecraft-server/Minecraft_server-nzcloud-v1.0

# 4. Beri izin eksekusi
chmod +x setup.sh

# 5. Jalankan!
./setup.sh
```

---

## 🚀 Quick Start

```bash
# Clone repo kamu (ganti USERNAME_KAMU dan nama repo)
git clone https://github.com/USERNAME_KAMU/my-minecraft-server.git

# Masuk folder
cd my-minecraft-server/Minecraft_server-nzcloud-v1.0

# Beri izin eksekusi
chmod +x setup.sh

# Jalankan!
./setup.sh
```

Ikuti panduan interaktif:

```
[1/6] Pilih tipe Minecraft     →  Java / Bedrock
[2/6] Pilih software server    →  Paper / Purpur / Vanilla / Bedrock
[3/6] Masukkan versi Minecraft →  contoh: 1.21.1
[4/6] Masukkan nama server     →  contoh: MyServer
[5/6] Buat akun admin          →  username + password
[6/6] Konfigurasi jaringan     →  IP publik otomatis, opsional domain & port
```

---

## 📖 Usage

### Menu Utama

Setelah setup, jalankan kembali `./setup.sh` untuk membuka menu (akan diminta login admin):

```
┌─────────────────────────────────────────────────┐
│        Minecraft Server Manager - NZCloud        │
└─────────────────────────────────────────────────┘

  1) Start Server
  2) Stop Server
  3) Restart Server
  4) Lihat Log Server
  5) Update IP / Domain / Port
  6) Lihat Status
  0) Keluar
```

### Ganti Domain / Port

Di menu pilih **5 → Update IP / Domain / Port**, lalu masukkan domain atau port baru:

```
Host baru (domain/IP, kosongkan untuk skip): play.example.com
Port baru (kosongkan untuk skip): 19132
```

### Lihat Log Live

```bash
# Via menu: pilih opsi 4
# Atau langsung dari terminal:
tail -f Minecraft_server-nzcloud-v1.0/server.log
```

### Server Tetap Berjalan

Server berjalan di background menggunakan `nohup`. Menutup terminal **tidak mematikan** server. Untuk menghentikan, gunakan menu **Stop Server**.

---

## 📁 File Structure

```
my-minecraft-server/               ← repo kamu di GitHub
│
├── Minecraft_server-nzcloud-v1.0/
│   ├── setup.sh              ← Script utama (setup + manajemen)
│   ├── admin.json            ← Kredensial admin (LOKAL, tidak di-commit)
│   ├── server.conf           ← Konfigurasi server (LOKAL, tidak di-commit)
│   ├── server.log            ← Log server (LOKAL, tidak di-commit)
│   ├── server.pid            ← PID proses server (LOKAL)
│   └── server_data/          ← Data server Minecraft (LOKAL, tidak di-commit)
│       ├── server.jar        ← Server JAR (diunduh otomatis)
│       ├── eula.txt
│       ├── server.properties
│       └── world/
│
├── .gitignore                ← Melindungi file sensitif & data server
├── .nzcloud_fm_lock          ← Lock file (tandai repo sudah dipakai)
├── LICENSE
└── README.md
```

> ⚠️ **File `admin.json`, `server.conf`, dan `server_data/` tidak pernah masuk ke Git** — semuanya tercantum di `.gitignore` dan disimpan hanya di perangkat kamu.

---

## 🔐 Security

| Komponen | Penjelasan |
|---|---|
| **Password hashing** | SHA-256 via `sha256sum` — password tidak pernah disimpan plaintext |
| **admin.json** | Disimpan lokal di perangkat kamu, tidak pernah di-push ke GitHub |
| **File Manager Lock** | Setelah setup, repo terkunci dan membutuhkan autentikasi admin |
| **chmod 600** | File `admin.json` hanya bisa dibaca oleh user pemilik |
| **Tidak ada API key** | Tidak ada kredensial eksternal yang diperlukan |

---

## 🎮 Supported Software

| Software | Tipe | Keterangan |
|---|---|---|
| **Paper** | Java | ⭐ Direkomendasikan — performa terbaik, banyak plugin |
| **Purpur** | Java | Fork Paper dengan fitur tambahan |
| **Vanilla** | Java | Server resmi dari Mojang |
| **Bedrock DS** | Bedrock | Server resmi untuk Bedrock Edition |

> Dukungan untuk **Fabric**, **Forge**, dan **Folia** akan ditambahkan di versi mendatang.

---

## ❓ FAQ

**Q: Dari mana saya download file ZIP-nya?**  
A: Download dari [github.com/bacotbanget1/Minecraft-server/releases/latest](https://github.com/bacotbanget1/Minecraft-server/releases/latest), lalu upload ke repo GitHub kamu sendiri.

**Q: Kenapa harus upload ke repo sendiri, tidak langsung clone dari bacotbanget1?**  
A: Supaya repo kamu berfungsi sebagai **file manager server kamu sendiri**. Setelah setup, hanya kamu yang bisa mengaksesnya dengan password admin.

**Q: Apakah server saya bisa diakses dari internet / mabar jarak jauh?**  
A: Ya, langsung bisa! Script otomatis menginstall dan menjalankan **playit.gg** sebagai tunnel publik. Tidak perlu port forwarding, tidak perlu domain, tidak peduli CGNAT atau IP dinamis. Jalan di HP, laptop rumah, maupun VPS.

**Q: Berapa RAM yang digunakan server?**  
A: Script menggunakan 70% dari RAM tersedia di perangkat kamu secara otomatis (minimum 512 MB).

**Q: Saya lupa password admin, bagaimana cara reset?**  
A: Hapus file `admin.json` dan `.nzcloud_fm_lock` di folder `Minecraft_server-nzcloud-v1.0/`, lalu jalankan ulang `./setup.sh`.

**Q: Bagaimana cara dapat alamat server publiknya?**  
A: Setelah `./setup.sh` dijalankan dan server di-start, pilih menu **5 → Lihat Log Tunnel**. Cari baris bertuliskan `Claim URL` — buka URL itu di browser untuk aktivasi pertama kali. Setelah itu alamat format `xxx.joinmc.link:port` akan muncul di log dan di status menu.

**Q: Apakah bisa dijalankan di HP Android?**  
A: Ya! Gunakan [Termux](https://f-droid.org/packages/com.termux/) dari F-Droid. Diuji dan berfungsi di Android 10+.

**Q: Server mati ketika saya tutup terminal?**  
A: Tidak — server berjalan dengan `nohup`. Untuk menghentikan, gunakan menu **Stop Server**.

**Q: Apakah bisa dipakai di VPS / cloud server?**  
A: Ya, berjalan di Ubuntu, Debian, CentOS, dan distro Linux lainnya tanpa masalah.

---

## 🤝 Contributing

Kontribusi sangat disambut! Silakan:

1. Fork repositori ini
2. Buat branch fitur (`git checkout -b feature/nama-fitur`)
3. Commit perubahan (`git commit -m 'feat: tambahkan fitur X'`)
4. Push ke branch (`git push origin feature/nama-fitur`)
5. Buka Pull Request

Pastikan kode kamu:
- Mengikuti gaya Bash yang ada
- Diuji di Termux dan Linux
- Tidak menyimpan kredensial apapun

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">

Made with ❤️ by **NZCloud** &nbsp;·&nbsp; Source: [bacotbanget1/Minecraft-server](https://github.com/bacotbanget1/Minecraft-server)

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/linux/linux-original.svg" width="24" alt="Linux" />
&nbsp;
<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/bash/bash-original.svg" width="24" alt="Bash" />
&nbsp;
<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/java/java-original.svg" width="24" alt="Java" />

*Kalau project ini membantu, kasih ⭐ di GitHub ya!*

</div>
