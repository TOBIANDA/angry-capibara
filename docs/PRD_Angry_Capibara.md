# Product Requirements Document (PRD): Angry Capibara

| Atribut | Nilai |
| :--- | :--- |
| **Nama Produk** | Angry Capibara |
| **Mata Kuliah** | Komputer Grafika (Interactive Computer Graphics) |
| **Versi Dokumen** | 4.0 (4 Worlds × 20 Sub-Levels = 80 Sub-Levels, 12 Capi Variants) |
| **Tanggal** | 2026-11-23 |
| **Ketua Tim & Pengembang Saat Ini** | Tobias Andra Valentino (NIM: `245150200111076`) |
| **Target Toolchain** | Visual Studio (`v145`, OpenGL/FreeGLUT/GLEW/GLM) + Godot Engine `4.7.1.stable` |

---

## 1. Visi Produk & Kepatuhan Syarat Proyek

**Angry Capibara** adalah aplikasi permainan grafika komputer interaktif 3D bergenre *physics-based slingshot puzzle* dengan referensi utama ***Angry Birds Star Wars (I & II)***, menghadirkan **4 World (masing-masing 20 Sub-Level = 80 Sub-Level total)** dengan **latar belakang 3D berbeda di setiap World**, **stepped pacing setiap 5 sub-level** (`1–5`, `6–10`, `11–15`, `16–20`), **12 varian Capibara**, *Turret* musuh aktif, zona gravitasi rendah, dan kamera 3D interaktif (*2.5D Side-View* $\leftrightarrow$ *3D Orbit*).

Seluruh aset 3D dan tekstur `.bmp` dibuat di **Visual Studio (C++ OpenGL, FreeGLUT, GLEW, GLM)** sesuai materi praktikum, lalu diekspor secara lokal ke **Godot Engine `4.7.1.stable`** sebagai aplikasi PC Windows *standalone* dan *offline*.

### Matriks Kepatuhan Ketentuan Tugas

| Parameter Wajib | Implementasi pada Angry Capibara | Status |
| :--- | :--- | :---: |
| **Jumlah Tim (1–4 orang)** | Saat ini **1 orang (Solo / Ketua Tim)**, arsitektur proyek & repositori dirancang modular agar siap menerima hingga **3 anggota tambahan** tanpa perlu refaktor. | Terpenuhi |
| **Jenis Aplikasi** | *Interactive Computer Graphics* | Terpenuhi |
| **Tujuan** | **Permainan** & **Hiburan** | Terpenuhi |
| **Tampilan** | **3D** (Geometri 3D penuh, 4 tema latar 3D berbeda per World, gameplay 2.5D, plus mode inspeksi kamera 3D Orbit) | Terpenuhi |
| **Platform** | **PC** (Windows 64-bit Desktop Executable `.exe`) | Terpenuhi |
| **Tampilan Credits** | Menu **Credits** interaktif berisi daftar Nama, NIM, peran tiap anggota, dan teknologi yang digunakan (dapat diakses dari Main Menu & Pause/End Screen). | Terpenuhi |
| **Kemandirian (Offline)** | **100% Standalone & Offline** — seluruh aset, audio, dan penyimpanan progres (`user://`) bersifat lokal tanpa koneksi internet. | Terpenuhi |

---

## 2. Target Pengguna & User Stories

1. **Sebagai Evaluator**, saya ingin membuka `.exe` langsung di Windows tanpa koneksi internet dan tanpa instalasi Visual Studio/Godot, lalu melihat menu **Credits** yang menampilkan Nama dan NIM pembuat dengan jelas.
2. **Sebagai Evaluator**, saya ingin memutar dan menginspeksi aset 3D (di *Visual Studio Asset Forge* maupun lewat mode kamera **3D Orbit** di dalam gim) untuk memverifikasi *Bicubic Bézier patch*, pemodelan hierarkis 12 varian karakter, dan pemetaan tekstur bebas distorsi.
3. **Sebagai Pemain**, saya ingin memilih dari **4 World** bertema visual 3D berbeda, masing-masing berisi **20 Sub-Level** (`x-1` s.d. `x-20`), di mana setiap 5 sub-level memperkenalkan pion, rintangan, atau mekanik baru hingga pertarungan puncak di sub-level ke-20.
4. **Sebagai Pemain**, saya ingin mengarahkan *skill* mid-air kapibara ke posisi kursor mouse (*Zen Push*, *Seed-Blaster*, *Vortex Pull*, *Boomerang*, *Rocket*) serta memantulkan peluru turret dengan *Bambu-Saber*.
5. **Sebagai Pemain**, saya ingin progres bintang (hingga `60` per World / `240` total), skor terbaik, dan stage yang terbuka tersimpan otomatis secara lokal.

---

## 3. Scope Produk (In-Scope vs Out-of-Scope)

### 3.1 In-Scope (Rilis v4.0)
- **Visual Studio Asset Forge (`vs_asset_forge/`):**
  - Program C++ OpenGL interaktif (preview rotasi X/Y/Z, wireframe/solid, tekstur) + eksportir otomatis ke `.obj`, `.mtl`, dan `.bmp` 24-bit.
  - Aset berbasis *Bicubic Bézier* + *Hierarchical Assembly* untuk **12 Varian Capibara**, **4 Varian Musuh** (termasuk *Croc Turret* dan *King Croc Boss*), Katapel Bambu, 6 objek blok/prop, dan **4 set elemen latar belakang 3D per World**.
- **Godot 4.7.1 Game (`godot_project/`):**
  - **4 Worlds $\times$ 20 Sub-Levels = 80 Sub-Levels** (berbasis arsitektur *data-driven* `LevelRunner.tscn` + definisi stage `.json` agar ke-80 sub-level konsisten, ringan, dan bebas duplikasi).
  - **12 Varian Capibara** (referensi utama *Angry Birds Star Wars I & II*).
  - **4 Varian Musuh** (*Minion*, *Armored*, *Croc Turret*, *King Croc Boss*).
  - **6 Elemen Struktur & Lingkungan:** Bambu, Kayu, Es, Batu, Tong Yuzu TNT, Batu Pantul Onsen, plus **Zona Low-Gravity** di World 4.
  - UI lengkap: Main Menu, World Select (4 World), Sub-Level Grid (1–20), Capybarapedia/Guide, HUD Gameplay, Pause Menu, Win/Lose Overlay, dan **Credits Screen**.
  - Audio SFX & BGM 100% lokal (offline) dan penyimpanan lokal `user://save_data.json`.

### 3.2 Out-of-Scope
- Multiplayer online, leaderboard cloud, atau koneksi internet dalam bentuk apa pun.
- Level editor *in-game* untuk pengguna akhir.
- Dukungan platform mobile (Android/iOS) atau VR headset.

---

## 4. Kebutuhan Fungsional (Functional Requirements)

| ID | Kebutuhan | Kriteria Penerimaan (Acceptance Criteria) | Prioritas |
| :--- | :--- | :--- | :---: |
| **FR-01** | **Main Menu & Navigasi** | Menampilkan judul gim, tombol *Play*, *Capybarapedia/Guide*, *Credits*, dan *Quit*. Respons `< 100 ms`. | P0 |
| **FR-02** | **World & 20-Sub-Level Grid** | Layar pilihan **4 Worlds** (progres bintang `x/60`, status kunci) menuju grid **20 Sub-Levels** (`x-1` s.d. `x-20`) per World. | P0 |
| **FR-03** | **Latar Belakang Unik per World** | Setiap World memuat *environment*, langit/kabut, pencahayaan, dan prop latar belakang 3D khas. | P0 |
| **FR-04** | **Credits Screen Dinamis** | Menampilkan Nama, NIM, Peran, dan rincian teknologi dari `CreditsData`. | P0 |
| **FR-05** | **Slingshot & Aiming** | Tarik-lepas katapel dengan tali karet dinamis, batas radius maksimum, pembatalan di titik pusat, dan pratinjau lintasan. | P0 |
| **FR-06** | **12 Varian Capibara & Directional Skills** | Seluruh 12 varian memiliki visual & kemampuan unik (termasuk arah ke kursor untuk *Zen Push*, *Seed-Blaster*, *Vortex Pull*, *Boomerang*, dan *Rocket*). | P0 |
| **FR-07** | **Fisika, Turret & Low-Gravity** | Struktur stabil saat spawn; *Croc Turret* menembak berkala dan pelurunya bisa dipantulkan *Bambu-Saber*; World 4 mendukung area gravitasi rendah. | P0 |
| **FR-08** | **Menang / Kalah & Bintang** | Menang saat `alive_crocs == 0`; hitung bonus sisa kapibara, simpan 1–3 bintang & buka sub-level/world berikutnya secara lokal. | P0 |
| **FR-09** | **Kontrol Kamera 3D Interaktif** | *Pan*, *zoom*, dan toggle **2.5D Side-View** $\leftrightarrow$ **3D Orbit Showcase** (`Tab` / tombol HUD). | P1 |
| **FR-10** | **Visual Studio Asset Exporter** | Executable C++ merender preview 3D dan mengekspor seluruh `.obj`, `.mtl`, dan `.bmp` ke folder aset Godot. | P0 |

---

## 5. Kebutuhan Non-Fungsional (Non-Functional Requirements)

| Kategori | Spesifikasi |
| :--- | :--- |
| **Standalone & Offline** | Build Windows (`.exe`) portabel tanpa internet maupun instalasi Visual Studio/Godot di PC penguji. |
| **Performa** | Stabil $\ge 60\text{ FPS}$ pada $1280 \times 720$ (`GL Compatibility`). |
| **Skalabilitas 80 Stage** | Seluruh 80 sub-level didefinisikan sebagai file data `.json` ringan yang dimuat oleh 1 `LevelRunner.tscn`, bukan 80 scene terpisah, sehingga ukuran build kecil dan bebas duplikasi kode. |
| **Kualitas Grafika** | Normal mesh `.obj` mengarah keluar (CCW) dan pemetaan UV `.bmp` bebas distorsi. |

---

## 6. Tata Kelola Tim Best Practice (Skalabel 1–4 Orang)

| Slot Peran | Pemegang Saat Ini | Modul yang Dimiliki (Terisolasi) |
| :--- | :--- | :--- |
| **Role A: Ketua Tim & Core Gameplay Engineer** | Tobias Andra Valentino (`245150200111076`) | `scripts/autoload/`, `slingshot.gd`, `capybara_base.gd`, arsitektur 12 *skills*, `LevelRunner`, build `.exe`, & multiplier |
| **Role B: Graphics Asset Programmer (VS OpenGL)** | *(Ketua saat solo / Anggota 2)* | `vs_asset_forge/` (basis Bézier + 12 aksesori Capi + 4 set prop latar 3D + `.bmp` generator) |
| **Role C: World & Level Designer** | *(Ketua saat solo / Anggota 3)* | `data/levels/w1..w4/` (80 JSON sub-level), `WorldTheme` resources (4 latar), balancing skor & HP |
| **Role D: UI/UX, Audio & QA/Laporan** | *(Ketua saat solo / Anggota 4)* | `scenes/ui/` (World Select, Sub-Level Grid 1–20, Capybarapedia, Credits), `assets/audio/`, QA 80 stage, & laporan BRONE |

**Rubrik Multiplier Ketua Tim (`0.0 – 1.0`):** `0.90–1.00` (tuntas & terintegrasi bersih), `0.70–0.89` (selesai dengan revisi minor), `0.40–0.69` (parsial), `0.00–0.39` (minim/tidak terintegrasi). Saat ini anggota aktif: Tobias Andra Valentino (`245150200111076`, Multiplier `1.00`).

---

## 7. Milestone & Deliverables

| Fase | Target Utama | Kriteria Selesai |
| :--- | :--- | :--- |
| **M1 — Review Dokumen** | Finalisasi PRD, TRD, dan GDD v4.0 | Disetujui sebelum mulai coding |
| **M2 — Asset Forge (VS C++)** | Program Visual Studio + 12 Capi + 4 Musuh + Blok + 4 Set Latar 3D | Build Win32 sukses, preview interaktif jalan, `.obj`/`.mtl`/`.bmp` ter-ekspor |
| **M3 — Core Engine & LevelRunner** | `LevelRunner.tscn`, katapel, 12 *skills*, *Croc Turret*, *Low-G Zone*, kamera 2.5D/3D | Seluruh 12 Capi & mekanik teruji pada loader JSON |
| **M4 — 4 Worlds, 80 Sub-Levels & UI** | 4 Tema Latar 3D, 80 file level JSON (`1-1` s.d. `4-20`), UI Grid 1–20, Capybarapedia, Credits, Audio, Save | Seluruh 80 stage lolos validasi stabilitas & dapat dimainkan |
| **M5 — Export & Verifikasi Offline** | Windows `.exe` standalone + Laporan & Video Demo | Uji di mode offline tanpa editor Godot berhasil 100% |
