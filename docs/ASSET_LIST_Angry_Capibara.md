# Asset List & Manifest: Angry Capibara

| Atribut | Nilai |
| :--- | :--- |
| **Versi Dokumen** | 1.0 (Pre-Implementation Asset Manifest) |
| **Tanggal** | 2026-11-23 |
| **Pipeline 3D & Tekstur** | `vs_asset_forge/` (Visual Studio C++ OpenGL + GLM $\rightarrow$ `.obj`, `.mtl`, `.bmp`) |
| **Pipeline Audio & UI** | Generator lokal offline (`tools/audio_gen.py` / Godot UI Canvas) $\rightarrow$ `.wav`, `.png` |
| **Konvensi Skala & Pivot** | `1.0 unit OpenGL = 1.0 meter Godot`; *Y-up*, menghadap `+X` (proyektil) atau `-X` (musuh) |

---

## 1. Karakter Capibara (12 Varian — *Bicubic Bézier + Hierarchical Assembly*)

Semua model Capibara dibangun dari basis tubuh & kepala **Bicubic Bézier Surface Patch** ($4 \times 4$ *control points*, evaluasi Bernstein CPU) ditambah telinga, moncong, mata, kaki, dan aksesori hierarkis (`glm::mat4`). Pivot berada di **pusat massa (CoM) `(0, 0, 0)`** agar rotasi `RigidBody3D` akurat.

| ID | File Mesh (`.obj`) | Sub-Komponen & Aksesori Hierarkis | Dimensi (m) | Tekstur (`.bmp`) | Collider Godot |
| :-: | :--- | :--- | :---: | :--- | :--- |
| `01` | `capy_chill.obj` | Badan Bézier, kepala, moncong, 2 telinga, 4 kaki, mata datar | `0.85 × 0.65 × 0.70` | `tex_capy_brown.bmp` | `SphereShape3D(r=0.36)` |
| `02` | `capy_dash.obj` | Basis ramping + **Ikat Kepala Kuning** dengan ekor pita melengkung | `0.88 × 0.62 × 0.66` | `tex_capy_brown.bmp`, `tex_accent_gold.bmp` | `SphereShape3D(r=0.35)` |
| `03` | `capy_mini.obj` | Basis mungil + **Pita Biru** di kepala | `0.56 × 0.45 × 0.48` | `tex_capy_tan.bmp`, `tex_accent_blue.bmp` | `SphereShape3D(r=0.24)` |
| `04` | `capy_yuzu_bomb.obj` | Basis gelap + **Jeruk Yuzu Bézier** menyala & daun di atas kepala | `0.88 × 0.88 × 0.74` | `tex_capy_dark.bmp`, `tex_yuzu.bmp` | `SphereShape3D(r=0.40)` |
| `05` | `capy_seed_blaster.obj` | Basis + **Topi Petualang** + **Pelontar Biji** di sisi | `0.88 × 0.78 × 0.72` | `tex_capy_brown.bmp`, `tex_wood.bmp` | `SphereShape3D(r=0.37)` |
| `06` | `capy_bambu_saber.obj` | Basis + **Gagang & Bilah Pedang Bambu Hijau Menyala** | `0.92 × 0.85 × 0.72` | `tex_capy_brown.bmp`, `tex_saber_green.bmp` | `SphereShape3D(r=0.37)` |
| `07` | `capy_heavy_onsen.obj` | Basis jumbo lebar + **Batu Onsen & Handuk Putih** di punggung | `1.05 × 0.90 × 0.92` | `tex_capy_dark.bmp`, `tex_stone.bmp` | `SphereShape3D(r=0.48)` |
| `08` | `capy_zen_push.obj` | Basis + **Jubah & Tudung Biara** + cincin aura biru | `0.90 × 0.76 × 0.74` | `tex_capy_tan.bmp`, `tex_saber_blue.bmp` | `SphereShape3D(r=0.38)` |
| `09` | `capy_boomerang.obj` | Basis + **Sabuk Ungu** + **Bilah Bumerang Ganda** di punggung | `0.90 × 0.76 × 0.72` | `tex_capy_brown.bmp`, `tex_accent_purple.bmp` | `SphereShape3D(r=0.37)` |
| `10` | `capy_pinball.obj` | Basis kecil warna lumut + **Bilah Bambu Mini** | `0.66 × 0.56 × 0.58` | `tex_capy_moss.bmp`, `tex_saber_green.bmp` | `SphereShape3D(r=0.30)` |
| `11` | `capy_vortex_pull.obj` | Basis + **Mahkota Pita Putih** + aksen magenta | `0.86 × 0.78 × 0.70` | `tex_capy_tan.bmp`, `tex_accent_magenta.bmp` | `SphereShape3D(r=0.36)` |
| `12` | `capy_rocket_onsen.obj` | Basis + **Jetpack Tabung Uap Bambu Kembar** & nozel di punggung | `0.95 × 0.75 × 0.78` | `tex_capy_dark.bmp`, `tex_bamboo.bmp`, `tex_tnt.bmp` | `SphereShape3D(r=0.38)` |

---

## 2. Musuh & Proyektil Skill (7 Mesh — *Hierarchical + Parametric*)

Pivot karakter musuh berada di **pusat massa**; proyektil *skill* menghadap `+X` secara default.

| ID | File Mesh (`.obj`) | Teknik Pemodelan (OpenGL C++) | Dimensi (m) | Tekstur (`.bmp`) | Collider Godot |
| :-: | :--- | :--- | :---: | :--- | :--- |
| `13` | `croc_minion.obj` | Ellipsoid badan, moncong prisma trapesium, gigi kerucut, ekor, mata | `0.90 × 0.72 × 0.72` | `tex_croc_scale.bmp` | `SphereShape3D(r=0.38)` |
| `14` | `croc_armored.obj` | Basis `croc_minion` + **Helm Batu/Baja** dengan paku kerucut | `0.98 × 0.88 × 0.82` | `tex_croc_scale.bmp`, `tex_stone.bmp` | `SphereShape3D(r=0.44)` |
| `15` | `croc_turret.obj` | Dudukan tripod silinder, bodi buaya operator, **Laras Meriam** | `1.10 × 0.92 × 0.85` | `tex_croc_scale.bmp`, `tex_stone.bmp` | `BoxShape3D(0.95, 0.90, 0.80)` |
| `16` | `croc_boss.obj` | Skala jumbo + **Mahkota Emas** bertatahkan yuzu + jubah punggung | `1.45 × 1.35 × 1.30` | `tex_croc_boss.bmp`, `tex_accent_gold.bmp` | `SphereShape3D(r=0.68)` |
| `17` | `proj_seed_bolt.obj` | Kapsul / proyektil biji memanjang + ujung lancip | `0.38 × 0.14 × 0.14` | `tex_yuzu.bmp` | `SphereShape3D(r=0.10)` |
| `18` | `proj_boomerang.obj` | Bilah bambu melengkung bentuk-V / salib tipis | `0.75 × 0.14 × 0.75` | `tex_accent_purple.bmp` | `SphereShape3D(r=0.36)` |
| `19` | `proj_yuzu_rocket.obj` | Silinder roket + sirip ekor + kepala yuzu oranye | `0.55 × 0.22 × 0.22` | `tex_tnt.bmp`, `tex_yuzu.bmp` | `SphereShape3D(r=0.15)` |

*(Peluru `TurretBullet` menggunakan `proj_seed_bolt.obj` dengan material merah/energi atau bola energi bertekstur `tex_tnt.bmp`.)*

---

## 3. Katapel (4 Varian World), Blok Struktur & Prop Interaktif (14 Mesh)

Seluruh blok memiliki **UV mapping proporsional (anti-distorsi)** agar serat kayu/bambu/es/batu tidak tampak gepeng. Pivot berada di **pusat geometri** (`(0,0,0)`), kecuali keempat model katapel di **dasar tiang** (`y = 0`).

| ID | File Mesh (`.obj`) | Teknik Pemodelan (OpenGL C++) | Dimensi (m) | Tekstur (`.bmp`) | Collider Godot |
| :-: | :--- | :--- | :---: | :--- | :--- |
| `20a` | `slingshot_w1_bamboo.obj` | **W1:** Tiang bambu beruas + cabang Y (*Bézier extrusion*) + alas batu onsen | `0.70 × 2.60 × 1.20` | `tex_bamboo.bmp`, `tex_stone.bmp` | Visual only (`StaticBody` opsional) |
| `20b` | `slingshot_w2_canyon.obj` | **W2:** Cabang kayu ngarai tebal + penguat batu merah + lentera jeruk yuzu gantung | `0.75 × 2.65 × 1.25` | `tex_wood.bmp`, `tex_canyon.bmp`, `tex_yuzu.bmp` | Visual only (`StaticBody` opsional) |
| `20c` | `slingshot_w3_crystal.obj` | **W3:** Cabang Y kristal es prismatik + alas bongkahan es bersalju | `0.75 × 2.65 × 1.25` | `tex_ice.bmp`, `tex_cloud.bmp` | Visual only (`StaticBody` opsional) |
| `20d` | `slingshot_w4_royal.obj` | **W4:** Rangka istana batu gelap + kubah emas + cincin torus energi biru | `0.85 × 2.75 × 1.35` | `tex_stone_dark.bmp`, `tex_accent_gold.bmp`, `tex_saber_blue.bmp` | Visual only (`StaticBody` opsional) |
| `21` | `block_bamboo_long.obj` | Silinder beruas (3 segmen sambungan) | `2.40 × 0.36 × 0.36` | `tex_bamboo.bmp` | `BoxShape3D(2.40, 0.36, 0.36)` |
| `22` | `block_bamboo_short.obj` | Silinder beruas pendek | `1.20 × 0.36 × 0.36` | `tex_bamboo.bmp` | `BoxShape3D(1.20, 0.36, 0.36)` |
| `23` | `block_wood_long.obj` | Balok papan bevel CCW | `2.40 × 0.38 × 0.55` | `tex_wood.bmp` | `BoxShape3D(2.40, 0.38, 0.55)` |
| `24` | `block_wood_short.obj` | Balok kayu pendek | `1.20 × 0.38 × 0.55` | `tex_wood.bmp` | `BoxShape3D(1.20, 0.38, 0.55)` |
| `25` | `block_ice_cube.obj` | Kubus kristal es bevel | `0.90 × 0.90 × 0.60` | `tex_ice.bmp` | `BoxShape3D(0.90, 0.90, 0.60)` |
| `26` | `block_ice_plank.obj` | Lempeng kaca es panjang | `2.40 × 0.32 × 0.55` | `tex_ice.bmp` | `BoxShape3D(2.40, 0.32, 0.55)` |
| `27` | `block_stone_slab.obj` | Lempeng batu berat | `2.40 × 0.44 × 0.60` | `tex_stone.bmp` | `BoxShape3D(2.40, 0.44, 0.60)` |
| `28` | `block_stone_cube.obj` | Pilar/kubus batu padat | `0.90 × 0.90 × 0.60` | `tex_stone.bmp` | `BoxShape3D(0.90, 0.90, 0.60)` |
| `29` | `prop_tnt_barrel.obj` | Silinder tong + 2 cincin pengikat torus pipih | `0.82 × 0.96 × 0.82` | `tex_tnt.bmp` | `CylinderShape3D(h=0.96, r=0.41)` |
| `30` | `prop_onsen_pad.obj` | Silinder batu pemandian datar + cincin air panas di atas | `1.60 × 0.38 × 1.10` | `tex_stone.bmp`, `tex_ice.bmp` | `BoxShape3D(1.60, 0.38, 1.10)` |

---

## 4. Aset Latar Belakang 3D Unik per World (9 Mesh — *World Scenery*)

Setiap World menempatkan prop latar di zona kedalaman $Z \in [-8, -28]$ agar membentuk *parallax* 3D yang terlihat jelas terutama saat mode kamera **3D Orbit**.

| World | File Mesh (`.obj`) | Teknik Pemodelan (OpenGL C++) | Tekstur (`.bmp`) |
| :-: | :--- | :--- | :--- |
| **W1** | `bg_w1_hill.obj` | Bukit bergelombang dari **Bicubic Bézier Patch** lebar | `tex_grass.bmp` |
| **W1** | `bg_w1_bamboo_grove.obj` | Gugusan 3 batang bambu tinggi + helai daun | `tex_bamboo.bmp` |
| **W2** | `bg_w2_yuzu_tree.obj` | Batang silinder bercabang + tajuk bola + 4 buah jeruk yuzu | `tex_wood.bmp`, `tex_grass.bmp`, `tex_yuzu.bmp` |
| **W2** | `bg_w2_canyon_pillar.obj` | Pilar tebing ngarai bertingkat (prisma trapesium bertumpuk) | `tex_canyon.bmp` |
| **W3** | `bg_w3_ice_spire.obj` | Gugusan 3 pilar kristal heksagonal runcing | `tex_ice.bmp` |
| **W3** | `bg_w3_float_island.obj` | Lempeng tanah atas + kerucut batu runcing di bawah | `tex_ice.bmp`, `tex_stone.bmp` |
| **W3** | `bg_w3_cloud.obj` | Klaster 5 bola tumpang-tindih membentuk awan 3D | `tex_cloud.bmp` |
| **W4** | `bg_w4_citadel_tower.obj` | Menara gerbang istana bertingkat + kubah setengah bola emas | `tex_stone_dark.bmp`, `tex_accent_gold.bmp` |
| **W4** | `bg_w4_energy_ring.obj` | Torus cincin energi untuk latar & penanda **Zona Low-Gravity** | `tex_saber_blue.bmp` |

---

## 5. Tekstur Prosedural `.bmp` 24-Bit (`vs_asset_forge/bmp_generator`)

Seluruh tekstur berukuran `256×256` piksel (rasio 1:1) atau `512×256` (rasio 2:1 untuk tekstur silinder/badan), format **24-bit uncompressed BMP** kompatibel `getBMP.cpp` & Godot.

| No | Nama File | Pola Prosedural | Dipakai Oleh |
| :-: | :--- | :--- | :--- |
| `01` | `tex_capy_brown.bmp` | Bulu cokelat hangat + noise serat halus + area moncong/mata | `capy_chill`, `dash`, `seed_blaster`, `bambu_saber`, `boomerang` |
| `02` | `tex_capy_tan.bmp` | Bulu krem-cokelat muda + detail wajah | `capy_mini`, `zen_push`, `vortex_pull` |
| `03` | `tex_capy_dark.bmp` | Bulu cokelat gelap arang | `capy_yuzu_bomb`, `heavy_onsen`, `rocket_onsen` |
| `04` | `tex_capy_moss.bmp` | Bulu hijau lumut hangat | `capy_pinball` |
| `05` | `tex_yuzu.bmp` | Kulit jeruk yuzu cerah berpori + gradien oranye-kuning | Buah yuzu, roket, proyektil biji |
| `06` | `tex_bamboo.bmp` | Serat vertikal hijau bambu + garis cincin ruas horizontal | `slingshot_frame`, `block_bamboo_*`, `bg_w1_bamboo_grove` |
| `07` | `tex_wood.bmp` | Serat papan kayu cokelat + garis sambungan papan | `block_wood_*`, `bg_w2_yuzu_tree` |
| `08` | `tex_ice.bmp` | Gradien biru es + garis kilau kristal diagonal | `block_ice_*`, `bg_w3_ice_spire`, `prop_onsen_pad` |
| `09` | `tex_stone.bmp` | Pola batu berbutir abu-abu + bayangan retak samar | `block_stone_*`, `croc_armored`, `prop_onsen_pad` |
| `10` | `tex_stone_dark.bmp` | Batu vulkanik/istana ungu-abu gelap | `bg_w4_citadel_tower` |
| `11` | `tex_tnt.bmp` | Kayu merah tua + pita kuning bertuliskan/simbol peringatan `TNT` | `prop_tnt_barrel`, `capy_rocket_onsen` |
| `12` | `tex_croc_scale.bmp` | Sisik hijau zamrud berpola kotak-oval + mata kuning | `croc_minion`, `croc_armored`, `croc_turret` |
| `13` | `tex_croc_boss.bmp` | Sisik hijau tua berkontras + bekas luka & aksen gelap | `croc_boss` |
| `14` | `tex_grass.bmp` | Rumput lembah hijau bergradasi | Tanah W1 & `bg_w1_hill` |
| `15` | `tex_canyon.bmp` | Lapisan sedimen batu ngarai merah-terakota | Tanah W2 & `bg_w2_canyon_pillar` |
| `16` | `tex_cloud.bmp` | Putih lembut bergradasi biru muda | `bg_w3_cloud` |
| `17` | `tex_accent_gold.bmp` | Emas metalik hangat | Mahkota Raja Buaya, ikat kepala Dash, kubah W4 |
| `18` | `tex_accent_blue.bmp` | Biru cerah | Pita Trio Mini |
| `19` | `tex_accent_purple.bmp` | Ungu cerah | Sabuk & Boomerang Capi |
| `20` | `tex_accent_magenta.bmp` | Magenta neon | Aksen Vortex Pull |
| `21` | `tex_saber_green.bmp` | Hijau neon bercahaya (emissive tint di Godot) | Bilah `capy_bambu_saber`, `capy_pinball` |
| `22` | `tex_saber_blue.bmp` | Biru energi bercahaya | Aura `capy_zen_push`, `bg_w4_energy_ring` |

---

## 6. Aset UI, VFX & Audio Offline (`godot_project/assets/`)

### 6.1 VFX & Material Dinamis (Godot)
- **Material Retak Blok (`crack_overlay`):** Modulasi albedo + *emission* saat `HP <= 50%` (atau varian tekstur retak).
- **Partikel (`CPUParticles3D`):** Serpihan bambu/kayu/es/batu, ledakan api-jeruk Yuzu, uap onsen, kilau tebasan saber, dan gelombang cincin *Zen Push*.

### 6.2 UI & Ikon
- **Ikon 12 Capibara & Musuh:** Dirender langsung dari model 3D `.obj` melalui *SubViewport thumbnail baker* atau ikon vektor/prosedural `.png` di Godot agar konsisten dengan model 3D.
- **Layar Wajib:** Main Menu, World Select (4 World), Sub-Level Grid (`1..20`), Capybarapedia (ensiklopedia 12 Capi + musuh), Pause, Win/Lose, dan **Credits Screen** (Nama & NIM).

### 6.3 Audio Lokal Offline (`assets/audio/*.wav`)
Seluruh suara dibangkitkan secara lokal/offline menggunakan skrip generator synthesizer (`tools/generate_audio.py`) sehingga 100% bebas hak cipta dan tidak memerlukan internet:
- **BGM (2 trek loop `.wav`):** `bgm_menu_chill.wav` (marimba santai) & `bgm_battle_tense.wav` (ritme perkusi ringan).
- **SFX (15 efek `.wav`):** `sfx_stretch.wav`, `sfx_launch.wav`, `sfx_skill_dash.wav`, `sfx_skill_split.wav`, `sfx_skill_explosion.wav`, `sfx_skill_saber.wav`, `sfx_skill_force.wav`, `sfx_skill_blaster.wav`, `sfx_hit_wood.wav`, `sfx_hit_ice.wav`, `sfx_hit_stone.wav`, `sfx_turret_fire.wav`, `sfx_croc_defeat.wav`, `sfx_win.wav`, `sfx_lose.wav`.

---

## Ringkasan Total Aset
- **42 Mesh 3D (`.obj` + `.mtl`)** yang seluruhnya diproduksi & dapat dipratinjau di **Visual Studio OpenGL Asset Forge**.
- **22 Tekstur `.bmp` 24-bit** hasil generator prosedural C++ OpenGL.
- **17 Berkas Audio `.wav`** lokal offline.
