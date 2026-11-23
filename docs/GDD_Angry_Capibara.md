# Game Design Document (GDD): Angry Capibara

| Atribut | Nilai |
| :--- | :--- |
| **Judul Gim** | Angry Capibara |
| **Genre** | 3D Physics Slingshot Puzzle / Arcade |
| **Referensi Utama** | *Angry Birds Star Wars II* (20 sub-level/chapter + Boss di ke-20) & *Angry Birds Star Wars I* (Turret, Deflect, Low-G) |
| **Platform** | PC (Windows Desktop Standalone, 100% Offline) |
| **Versi Dokumen** | 4.0 (4 Worlds × 20 Sub-Levels = 80 Sub-Levels, 12 Capi Variants) |

---

## 1. Konsep Inti & Pilar Desain

### 1.1 High Concept
> *"Luncurkan 12 pasukan kapibara berkemampuan taktis ala Star Wars dari katapel bambu untuk menaklukkan 4 World benteng Klan Buaya Rakus (masing-masing 20 Sub-Level = 80 Stage total)—dengan perkembangan rintangan, pion, dan teknik baru di setiap fase 5 sub-level."*

### 1.2 Referensi & Ritme Pacing (*Angry Birds Star Wars*)
- Di *Angry Birds Star Wars I*, tiap episode berisi **40 sub-level**; di *Angry Birds Star Wars II*, tiap chapter utama berisi **20 sub-level** yang ditutup dengan pertarungan bos/klimaks di sub-level ke-20.
- **Angry Capibara** mengadopsi format **20 sub-level per World** (seperti *AB Star Wars II*) dengan **4 World berlatar belakang 3D berbeda** (total **80 Sub-Level**).
- Setiap **5 sub-level** di dalam satu World merupakan **1 Fase** (`1–5`, `6–10`, `11–15`, `16–20`) yang selalu memperkenalkan elemen baru (pion Capibara baru, rintangan/material baru, atau teknik lingkungan baru).

---

## 2. Struktur Leveling: 4 Worlds × 20 Sub-Levels (80 Stages)

### 2.1 Story Singkat, Capibara Baru & Bentuk Katapel per World

**Prolog:** Di Lembah Onsen yang damai, para kapibara hidup tenang berendam air hangat sambil menaruh jeruk yuzu di kepala. Suatu hari, **Klan Buaya Rakus (*Croc Raiders*)** pimpinan **King Croc** menyerbu lembah, menjarah persediaan jeruk yuzu, dan mendirikan benteng di empat wilayah. Pasukan kapibara bangkit untuk merebut kembali rumah dan mahkota yuzu mereka!

| World | Story Singkat | Capibara Baru yang Muncul | Bentuk Katapel (`Slingshot`) |
| :-: | :--- | :--- | :--- |
| **W1: Lembah Onsen Bambu** | Pos pengintai buaya berdiri di tepi pemandian air panas. Tiga kapibara pertama bangkit mempertahankan kampung halaman mereka. | 1. **Chill Capi** (`1-1`)<br>2. **Dash Capi** (`1-6`)<br>3. **Trio Mini-Capi** (`1-11`) | **Katapel Bambu Tradisional** (`slingshot_w1_bamboo.obj`): cabang Y dari batang bambu hijau beruas (*Bézier extrusion*) yang tertancap di alas batu kolam onsen. |
| **W2: Kebun Yuzu & Ngarai Turret** | Buaya mundur membawa peti yuzu ke ngarai bertebing merah sambil memasang meriam *Croc Turret*. Pendekar dan penembak jitu kapibara turun tangan. | 4. **Yuzu Bomb Capi** (`2-1`)<br>5. **Seed-Blaster Capi** (`2-6`)<br>6. **Bambu-Saber Capi** (`2-11`)<br>7. **Heavy Onsen Capi** (`2-16`) | **Katapel Kayu Ngarai & Lentera Yuzu** (`slingshot_w2_canyon.obj`): cabang kayu tebal berpenguat batu ngarai dengan lentera jeruk yuzu menggantung di pangkalnya. |
| **W3: Gua Kristal Es & Awan** | Klan buaya membekukan jarahan mereka di gua kristal hingga puncak awan. Lantai es licin menuntut teknik dorongan, pantulan, dan tarikan telekinetik. | 8. **Zen Push Capi** (`3-1`)<br>9. **Boomerang Capi** (`3-6`)<br>10. **Pinball Spin Capi** (`3-11`)<br>11. **Vortex Pull Capi** (`3-16`) | **Katapel Kristal Es & Awan** (`slingshot_w3_crystal.obj`): cabang Y prismatik dari kristal es biru bening yang berdiri di atas bongkahan batu salju melayang. |
| **W4: Istana Inti Raja Buaya** | Babak klimaks di benteng inti **King Croc** yang memancarkan medan *Low-Gravity*. Pasukan jetpack memimpin serangan terakhir bersama seluruh 12 kapibara. | 12. **Rocket Onsen Capi** (`4-6`)<br>*(+ Gabungan seluruh 12 Capi di fase akhir hingga Boss `4-20`)* | **Katapel Mekanik Istana Emas** (`slingshot_w4_royal.obj`): rangka batu gelap berlapis emas berkubah dengan cincin torus energi biru yang melingkari cabangnya. |

### 2.2 Peta Progresi 4 Fase per World

| World | Latar Belakang 3D Unik | Fase 1 (`x-1`..`x-5`) | Fase 2 (`x-6`..`x-10`) | Fase 3 (`x-11`..`x-15`) | Fase 4 (`x-16`..`x-20`) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **W1: Lembah Onsen Bambu** | Langit pagi cerah, perbukitan hijau Bézier, rumpun bambu 3D & uap onsen | **Intro:** Bambu & *Chill Capi* | **+ Kayu** & **Dash Capi** | **+ Es/Kaca** & **Trio Mini-Capi** | **+ Tong Yuzu TNT** & **Mini-Boss Struktur Kembar (`1-20`)** |
| **W2: Kebun Yuzu & Ngarai Turret** | Senja jingga-tembaga, pohon jeruk yuzu 3D, tebing ngarai & menara pengawas | **+ Blok Batu** & **Yuzu Bomb Capi** | **+ Seed-Blaster Capi** (tembak 3 biji jarak jauh) | **+ Croc Turret** (menembak aktif) & **Bambu-Saber Capi** (*Deflect* peluru!) | **+ Armored Croc**, **Heavy Onsen Capi**, & **Benteng Multi-Turret (`2-20`)** |
| **W3: Gua Kristal Es & Awan** | Langit aurora dingin, pilar kristal es 3D, pulau batu melayang & awan | **+ Lantai Es Licin** & **Zen Push Capi** (*Force Push* ke kursor) | **+ Boomerang Capi** (potong dari belakang) | **+ Batu Pantul Onsen** (*Bounce Pad*) & **Pinball Spin Capi** | **+ Vortex Pull Capi** (*Tractor Beam*) & **Kubah Kristal Puncak (`3-20`)** |
| **W4: Istana Inti Raja Buaya** | Malam ungu gelap, menara istana emas & cincin energi bercahaya | **+ Zona Low-Gravity** (gravitasi 35%) | **+ Rocket Onsen Capi** (*Jetpack + Yuzu Missile*) | **+ Dual Turret + Low-G + Bounce Pad** (kombinasi teknik) | **+ Pengawal Elit** & **FINAL BOSS: King Croc (`4-20`)** |

---

## 3. Roster 12 Varian Capibara (Adaptasi *Angry Birds Star Wars I & II*)

Aktivasi *skill* dilakukan dengan **Klik Kiri** atau **`Spasi`** saat di udara (1x per peluncuran). Untuk *skill* terarah (`5`, `8`, `9`, `11`, `12`), arah serangan mengikuti **posisi kursor mouse** di arena.

| No | Nama Varian | Referensi AB Star Wars | Identitas Visual | Massa | Kemampuan Aktif (*Mid-Air Skill*) & Peran Taktis |
| :-: | :--- | :--- | :--- | :---: | :--- |
| **1** | **Chill Capi** | *Red (Pre-Saber)* | Kapibara cokelat klasik, ekspresi datar | `2.0 kg` | **Zen Bump:** Dorongan mikro ke bawah untuk merobohkan struktur miring. |
| **2** | **Dash Capi** | *Chuck (Yellow)* | Ikat kepala kuning aerodinamis | `1.8 kg` | **Turbo Dash:** Melesat lurus `2.2x` lebih cepat; menghancurkan **Kayu** dengan efektif. |
| **3** | **Trio Mini-Capi** | *The Blues* | Ukuran mungil, pita biru | `1.0 kg` | **Triple Split:** Membelah menjadi **3 kapibara kecil** menyebar ($\pm 12^\circ$); spesialis pemecah **Es/Kaca**. |
| **4** | **Yuzu Bomb Capi** | *Bomb / Thermal* | Jeruk yuzu menyala di kepala, badan gelap | `2.5 kg` | **Yuzu Shockwave:** Ledakan area radius `4.5 m` (`2.5x` damage ke **Batu** & pemicu **TNT**). |
| **5** | **Seed-Blaster Capi** | *Han Solo / Lando* | Topi petualang & pelontar biji | `2.0 kg` | **Triple Seed Blaster:** Menembakkan **3 peluru biji beruntun** lurus ke arah kursor tanpa mengubah gerak tubuh. |
| **6** | **Bambu-Saber Capi** | *Luke Skywalker* | Tongkat pedang bambu hijau menyala | `2.1 kg` | **Saber Slash & Deflect:** Tebasan `360°` memotong blok sekitar dan **memantulkan balik peluru Croc Turret** ke benteng musuh. |
| **7** | **Heavy Onsen Capi** | *Chewbacca* | Tubuh jumbo + batu onsen di punggung | `4.6 kg` | **Unstoppable Mass (Pasif):** Inersia raksasa; menerobos barikade kayu/batu dan *Armored Croc*. |
| **8** | **Zen Push Capi** | *Obi-Wan Kenobi* | Jubah cokelat muda & aura biru | `2.2 kg` | **Zen Force Push:** Gelombang dorong telekinetik **mengarah ke kursor**, mementalkan blok, puing, & buaya. |
| **9** | **Boomerang Capi** | *Mace Windu* | Sabuk ungu & bilah ganda | `2.1 kg` | **Boomerang Blade:** Melempar bilah bambu berputar menuju kursor yang memotong saat berangkat lalu **berbalik dari belakang**. |
| **10** | **Pinball Spin Capi** | *Yoda* | Ukuran kecil berwarna hijau lumut | `1.5 kg` | **Spinning Pinball:** Berputar cepat dan **memantul liar berkali-kali** selama `2.0 detik` di ruang tertutup. |
| **11** | **Vortex Pull Capi** | *Princess Leia* | Mahkota pita putih & aura magenta | `2.0 kg` | **Tractor Pull Beam:** Mengunci objek terdekat di dekat kursor lalu **menariknya** keluar dari keseimbangan. |
| **12** | **Rocket Onsen Capi** | *Boba Fett* | Jetpack tabung uap bambu di punggung | `2.2 kg` | **Jetpack & Yuzu Missile:** Menyalakan jet naik sekaligus **menembakkan 1 roket yuzu** tepat menuju titik klik kursor. |

---

## 4. Musuh, Turret & Material Struktur

### 4.1 Varian Musuh (*Croc Raiders*)

| Musuh | HP | Skala | Skor | Mekanika Khas |
| :--- | :---: | :---: | :---: | :--- |
| **Croc Minion** | `35` | $0.75\text{ m}$ | `5.000` | Prajurit dasar; kalah dari benturan langsung atau tertimpa balok. |
| **Armored Croc** | `95` | $0.88\text{ m}$ | `7.500` | Helm batu; tahan serpihan kecil, rentan tebasan, ledakan, atau *Heavy Onsen*. |
| **Croc Turret** | `65` | $0.90\text{ m}$ | `8.500` | Menembakkan peluru energi tiap `3.5 detik`. Peluru dapat menghancurkan blok sendiri bila terguling atau **dipantulkan oleh Bambu-Saber Capi**. |
| **King Croc Boss** | `240` | $1.35\text{ m}$ | `25.000` | Bos akhir pada `4-20` (dan versi mini-boss struktur di `1-20`, `2-20`, `3-20`). |

### 4.2 Material Struktur & Lingkungan

| Material / Prop | HP | Massa Relatif | Ambang Kerusakan | Skor | Perilaku Khas |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Bambu** | `30` | `0.8 kg` | `3.0` | `300` | Ringan, mudah dipatahkan. |
| **Es / Kaca** | `40` | `1.0 kg` | `2.5` | `500` | Licin; menerima `2.0x` damage dari **Trio Mini** & **Seed-Blaster**. |
| **Kayu** | `75` | `1.5 kg` | `5.5` | `600` | Struktur utama; menerima `1.8x` damage dari **Dash** & **Bambu-Saber**. |
| **Batu** | `165` | `3.5 kg` | `10.0` | `1.000` | Keras; efektif dihancurkan dengan **Yuzu Bomb** (`2.5x`), **Heavy Onsen**, atau **Rocket**. |
| **Tong Yuzu TNT** | `20` | `1.2 kg` | `3.5` | `1.500` | Meledak radius `5.0 m` saat hancur, memicu reaksi berantai. |
| **Batu Pantul Onsen** | $\infty$ | Statis | — | `250` | Memantulkan proyektil/puing dengan restitusi tinggi (`0.9`). |
| **Zona Low-Gravity** | — | Area | — | — | Khusus W4: mengurangi gravitasi menjadi `35%` di dalam cincin energi. |

---

## 5. Sistem Skor, Kontrol & Alur UI/UX

- **Skor & Kombo:** Penghancuran objek (`300–1.500`), eliminasi musuh (`5.000–25.000`), sisa kapibara (`+10.000` per ekor), serta pengali *Yuzu Combo* (`x1.0` $\rightarrow$ `x1.5` $\rightarrow$ `x2.0` $\rightarrow$ `x3.0`).
- **Bintang:** 1–3 Bintang per sub-level (`60 Bintang` per World, `240 Bintang` total) tersimpan lokal di `user://save_data.json`.
- **Kontrol:** Drag katapel untuk membidik, `Klik Kiri`/`Spasi` untuk *skill* (diarahkan ke kursor), drag area kosong/`A-D` untuk *pan*, `Scroll` untuk *zoom*, `Tab` untuk toggle **2.5D Classic $\leftrightarrow$ 3D Orbit** (klik kanan drag), `R` restart, `Esc` pause.
- **Alur UI:** `Main Menu` $\rightarrow$ `World Select (4 Worlds)` $\rightarrow$ `Sub-Level Grid (1..20)` $\rightarrow$ `Gameplay HUD` (+ `Capybarapedia` & `Credits` berisi Nama, NIM, peran, dan teknologi).
