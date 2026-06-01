<div align="center">

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/bash/bash-original.svg" width="80" alt="Bash" />

# Minecraft Server NZCloud

**Self-hosted Minecraft server manager — runs on Termux, Linux, and anywhere bash lives.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Termux%20%7C%20Linux%20%7C%20macOS-blue?style=flat-square&logo=linux&logoColor=white)](https://github.com)
[![Minecraft](https://img.shields.io/badge/Minecraft-Java%20%26%20Bedrock-62B47A?style=flat-square&logo=minecraft&logoColor=white)](https://minecraft.net)
[![Version](https://img.shields.io/badge/Version-1.0-purple?style=flat-square)](https://github.com)
[![Stars](https://img.shields.io/github/stars/nzcloud/Minecraft_server-nzcloud?style=flat-square&color=gold)](https://github.com)

<br/>

> One script. Any device. Your Minecraft server, online in minutes.

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Usage](#-usage)
- [File Structure](#-file-structure)
- [Security](#-security)
- [Supported Software](#-supported-software)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌐 Overview

**NZCloud Minecraft Server** is a fully automated, interactive Bash-based Minecraft server manager designed to work on virtually any Unix-like system — including **Termux (Android)**, **Ubuntu/Debian**, **Arch Linux**, **macOS**, and more.

Clone the repo, run one script, answer a few questions, and your Minecraft server is online with a real **public IP address** — no manual configuration required.

After the first setup, the repository itself becomes your **server's file manager**, protected behind admin authentication.

---

## ✨ Features

<table>
<tr>
<td>

### 🎮 Server Management
- Java & Bedrock Edition support
- Paper, Purpur, Vanilla server software
- Auto-download correct server JARs
- Start / Stop / Restart controls
- Background server (stays alive after menu exit)
- Live log streaming

</td>
<td>

### 🌍 Network
- Auto-detects your **public IP address**
- Default port `25565`
- Custom domain support
- Custom port support
- Update IP/domain/port anytime

</td>
</tr>
<tr>
<td>

### 🔐 Security
- Admin username + password setup
- SHA-256 password hashing
- Credentials stored **locally** (never in repo)
- Repo auto-locks after first setup
- Auth required to re-enter server manager

</td>
<td>

### ⚡ Performance
- RAM auto-detected from your device
- 70% of available RAM allocated
- G1GC JVM flags for optimal performance
- Runs natively — no Docker, no containers

</td>
</tr>
</table>

---

## 📦 Requirements

### Termux (Android)
```bash
pkg update && pkg upgrade -y
pkg install git curl wget openjdk-17 python3 jq -y
```

### Ubuntu / Debian
```bash
sudo apt update
sudo apt install -y git curl wget default-jdk python3 jq
```

### Arch Linux
```bash
sudo pacman -S git curl wget jdk-openjdk python jq
```

> **Note:** The script will attempt to auto-install missing dependencies on first run.

---

## 🚀 Quick Start

```bash
# 1. Clone repositori
git clone https://github.com/nzcloud/Minecraft_server-nzcloud.git

# 2. Masuk ke folder
cd Minecraft_server-nzcloud/Minecraft_server-nzcloud-v1.0

# 3. Beri izin eksekusi
chmod +x setup.sh

# 4. Jalankan!
./setup.sh
```

---

## 🛠️ Installation

### Step-by-Step

**1. Clone repositori ke perangkat Anda**

```bash
git clone https://github.com/nzcloud/Minecraft_server-nzcloud.git
cd Minecraft_server-nzcloud
```

**2. Buka folder server**

```bash
cd Minecraft_server-nzcloud-v1.0
```

**3. Beri izin eksekusi pada script**

```bash
chmod +x setup.sh
```

**4. Jalankan setup pertama kali**

```bash
./setup.sh
```

**5. Ikuti panduan interaktif:**

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

Setelah setup, jalankan kembali `./setup.sh` untuk membuka menu:

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

Di menu pilih **5 → Update IP / Domain / Port**, lalu masukkan domain atau port baru. Server akan otomatis restart jika diminta.

```
Host baru (domain/IP, kosongkan untuk skip): play.example.com
Port baru (kosongkan untuk skip): 19132
```

### Lihat Log Live

```bash
# Via menu: pilih opsi 4
# Atau langsung:
tail -f Minecraft_server-nzcloud-v1.0/server.log
```

### Server Tetap Berjalan

Server berjalan di background menggunakan `nohup`. Menutup terminal **tidak mematikan** server. Untuk menghentikan, gunakan menu **Stop Server**.

---

## 📁 File Structure

```
Minecraft_server-nzcloud/
│
├── Minecraft_server-nzcloud-v1.0/
│   ├── setup.sh              ← Script utama (setup + manajemen)
│   ├── admin.json            ← Kredensial admin (lokal, tidak di-commit)
│   ├── server.conf           ← Konfigurasi server (lokal, tidak di-commit)
│   ├── server.log            ← Log server (lokal, tidak di-commit)
│   ├── server.pid            ← PID proses server (lokal)
│   └── server_data/          ← Data server Minecraft (lokal, tidak di-commit)
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

> ⚠️ **File `admin.json`, `server.conf`, dan `server_data/` tidak pernah masuk ke Git** — semuanya ada di `.gitignore` dan disimpan hanya di perangkat Anda.

---

## 🔐 Security

| Komponen | Penjelasan |
|---|---|
| **Password hashing** | SHA-256 via `sha256sum` — password tidak pernah disimpan plaintext |
| **admin.json** | Disimpan lokal di perangkat Anda, tidak pernah di-push ke GitHub |
| **File Manager Lock** | Setelah setup, repo terkunci dan membutuhkan autentikasi admin |
| **chmod 600** | File admin.json hanya bisa dibaca oleh user pemilik |
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

**Q: Apakah server saya bisa diakses dari internet?**  
A: Ya! Script otomatis mendeteksi IP publik Anda. Pastikan port di-forward di router (jika di rumah) atau firewall cloud dibuka.

**Q: Berapa RAM yang digunakan server?**  
A: Script menggunakan 70% dari RAM tersedia di perangkat Anda secara otomatis (minimum 512 MB).

**Q: Saya lupa password admin, bagaimana cara reset?**  
A: Hapus file `admin.json` dan `.nzcloud_fm_lock` di folder `Minecraft_server-nzcloud-v1.0/`, lalu jalankan ulang `./setup.sh`.

**Q: Apakah bisa dijalankan di HP Android?**  
A: Ya! Gunakan [Termux](https://termux.dev) dari F-Droid. Diuji dan berfungsi di Android 10+.

**Q: Server mati ketika saya tutup terminal?**  
A: Tidak — server berjalan dengan `nohup`. Untuk menghentikan, gunakan menu **Stop Server**.

---

## 🤝 Contributing

Kontribusi sangat disambut! Silakan:

1. Fork repositori ini
2. Buat branch fitur (`git checkout -b feature/nama-fitur`)
3. Commit perubahan (`git commit -m 'feat: tambahkan fitur X'`)
4. Push ke branch (`git push origin feature/nama-fitur`)
5. Buka Pull Request

Pastikan kode Anda:
- Mengikuti gaya Bash yang ada
- Diuji di Termux dan Linux
- Tidak menyimpan kredensial apapun

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">

Made with ❤️ by **NZCloud**

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/linux/linux-original.svg" width="24" alt="Linux" />
&nbsp;
<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/bash/bash-original.svg" width="24" alt="Bash" />
&nbsp;
<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/java/java-original.svg" width="24" alt="Java" />

*If this project helped you, consider giving it a ⭐ on GitHub!*

</div>
