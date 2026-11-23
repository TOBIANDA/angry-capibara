# Technical Requirements Document (TRD): Angry Capibara

| Atribut | Nilai |
| :--- | :--- |
| **Versi Dokumen** | 4.0 (Data-Driven 80 Sub-Levels: 4 Worlds × 20 Sub-Levels) |
| **Tanggal** | 2026-11-23 |
| **Toolchain Asset Forge** | Visual Studio (`v145`, C++20, `Win32`) + `C:\OpenGLwrappers` (FreeGLUT `2.8.1-1.mp`, GLEW `1.10.0`, GLM `0.9.7.5`) |
| **Toolchain Game Engine** | Godot Engine `4.7.1.stable.official.a13da4feb` (Win64) + Export Templates `4.7.1.stable` |
| **Target Output** | Windows Desktop x64 Standalone (`.exe` embedded PCK, 100% Offline) |

---

## 1. Arsitektur Sistem & Pipeline Data-Driven

Untuk mendukung **4 Worlds $\times$ 20 Sub-Levels (80 Stages)** secara bersih tanpa membuat 80 file `.tscn` yang berat, sistem menggunakan arsitektur **Single Scene Runner + JSON Stage Definitions**:

```text
[vs_asset_forge.exe (Win32 OpenGL C++)]
   ├── Geometri   : Bicubic Bezier Patch (CPU Bernstein) + Primitif CCW
   ├── Hierarki   : GLM mat4 + glPush/PopMatrix (12 Varian Capi + 4 Set Latar 3D)
   ├── Tekstur    : Procedural 24-bit Uncompressed BMP (getBMP compatible)
   └── Export     : --export-all -> godot_project/assets/generated/{models,textures}
           │
           ▼ Godot 4.7.1 Auto-Import
[godot_project/ (GL Compatibility)]
   ├── Autoloads  : GameManager, SaveManager, AudioManager, CreditsData, LevelCatalog
   ├── 4 Themes   : theme_w1.tres .. theme_w4.tres (Latar 3D, Langit, Cahaya, Friksi)
   ├── 80 Levels  : data/levels/w1/1-1.json .. w4/4-20.json (Ringan & Mudah Di-balance)
   ├── Runner     : LevelRunner.tscn (Instansiasi dinamis blok, musuh, turret, low-g)
   └── Export     : Windows Desktop x64 -> build/AngryCapibara.exe (Offline)
```

---

## 2. Subsistem 1: Visual Studio Asset Forge (`vs_asset_forge/`)

### 2.1 Konfigurasi Proyek Visual Studio
Mengikuti konfigurasi praktikum ([UndistortedCray.vcxproj](file:///c:/Users/kuahs/Documents/kompgraf/UndistortedCray.vcxproj)):
- **Platform & Toolset:** `Win32` (x86), Toolset `v145`, `C++20` (`stdcpp20`), `GLEW_STATIC`.
- **Include & Libs:** `C:\OpenGLwrappers\glm-0.9.7.5`, `glew-1.10.0-win32`, `freeglut-MSVC-2.8.1-1.mp` (`glew32s.lib;freeglut.lib;opengl32.lib`).

### 2.2 Modular Hierarchical Builder (12 Varian Capi + 4 Set Latar 3D)
1. **Basis Tubuh Bersama (`BuildCapyCore`):**
   - Badan & kepala dibentuk dari **Bicubic Bézier Surface Patch** ($4 \times 4$ *control points*, evaluasi polinomial Bernstein di CPU dengan normal analitik $\frac{\partial S}{\partial u} \times \frac{\partial S}{\partial v}$).
   - Skala proporsi `(scaleX, scaleY, scaleZ)` membedakan tipe standar, mini (*Trio / Pinball*), dan jumbo (*Heavy Onsen*).
2. **Aksesori Hierarkis Terpisah (`AttachAccessory`):**
   - Dirakit memakai `glm::mat4` dan diekspor sebagai grup material (`usemtl`) terpisah: `acc_headband`, `acc_ribbon`, `acc_yuzu`, `acc_hat_blaster`, `acc_bamboo_saber`, `acc_onsen_stone`, `acc_robe_hood`, `acc_dual_blade`, `acc_jetpack`, dll.
3. **4 Set Prop Latar Belakang 3D (`BuildSceneryProps`):**
   - **W1 (Lembah Bambu):** `bg_w1_bamboo.obj`, `bg_w1_hill.obj` (bukit Bézier + rumpun bambu).
   - **W2 (Kebun Yuzu & Ngarai Turret):** `bg_w2_yuzu_tree.obj`, `bg_w2_canyon_pillar.obj`.
   - **W3 (Gua Es & Awan):** `bg_w3_ice_spire.obj`, `bg_w3_float_island.obj`, `bg_w3_cloud.obj`.
   - **W4 (Istana Raja Buaya):** `bg_w4_citadel_tower.obj`, `bg_w4_energy_ring.obj`.
4. **Generator Tekstur Prosedural `.bmp` 24-bit:**
   Menghasilkan 13+ tekstur `.bmp` (kompatibel `getBMP.cpp` & Godot) dengan koordinat UV bebas distorsi.

---

## 3. Subsistem 2: Game Engineering (`godot_project/` — Godot `4.7.1.stable`)

### 3.1 Pengaturan Engine & `LevelRunner.tscn`
- **Renderer:** `GL Compatibility` (`4.7`).
- **Gravity Default:** `18.0 m/s²` (ditimpa oleh `LowGravityZone` menjadi `6.3 m/s²` di area inti W4).
- **Stage Loader (`level_runner.gd`):**
  Membaca file JSON stage (mis. `res://data/levels/w2/2-8.json`):
  ```json
  {
    "id": "2-8",
    "world": 2,
    "sub": 8,
    "name": "Menara Meriam",
    "stars": [15000, 28000, 40000],
    "queue": ["bambu_saber", "bambu_saber", "seed_blaster"],
    "blocks": [
      { "type": "stone_pillar", "pos": [8.0, 1.2], "rot": 0.0 },
      { "type": "wood_plank",   "pos": [9.5, 2.6], "rot": 0.0 }
    ],
    "enemies": [
      { "type": "turret", "pos": [9.5, 3.3], "dir": [-1, 0] },
      { "type": "minion", "pos": [11.5, 0.4] }
    ],
    "zones": []
  }
  ```
  *Keunggulan:* 80 sub-level hanya memakan ~100 KB teks JSON, mudah di-balance dengan angka koordinat eksak (struktur tidak miring/overlap saat spawn), dan mempermudah validasi otomatis seluruh 80 stage sekaligus!

### 3.2 Implementasi Teknis 12 Kemampuan Capibara (`capybara_base.gd`)
Semua kapibara mewarisi `CapybaraProjectile` (`RigidBody3D`, `continuous_cd = true`, `axis_lock_linear_z = true`, `axis_lock_angular_x/y = true`). Arah bidik *skill* dihitung dari proyeksi ray kursor mouse ke bidang $Z = 0$: $\hat{u}_{\text{aim}} = \text{normalize}(\vec{p}_{\text{cursor}} - \vec{p}_{\text{capy}})$.

| ID | Varian | Implementasi Fisika & Node |
| :-: | :--- | :--- |
| `0` | **Chill** | `apply_central_impulse(Vector3(0, -1.5, 0))` + gelombang getar radius `1.5 m`. |
| `1` | **Dash** | `linear_velocity = linear_velocity.normalized() * 32.0` (atau ke $\hat{u}_{\text{aim}}$). |
| `2` | **Trio Mini** | Spawn 2 klon `capy_mini` dengan sudut kecepatan $\pm 12^\circ$ di bidang XY. |
| `3` | **Yuzu Bomb** | `intersect_shape(SphereShape3D(r=4.5))`: impuls radial + damage `2.5x` ke Batu & memicu TNT. |
| `4` | **Seed-Blaster** | Spawn 3 `SeedBolt` berinterval `0.09 s` menuju $\hat{u}_{\text{aim}}$ ($\pm 2^\circ$). |
| `5` | **Bambu-Saber** | `intersect_shape(SphereShape3D(r=2.8))`: damage tebas ke blok sekitar + **membalikkan vektor kecepatan `TurretBullet` (`deflect`)** menuju target terdekat. |
| `6` | **Heavy Onsen** | Pasif (`mass = 4.6`), inersia tinggi menembus blok ringan/sedang tanpa memantul mundur. |
| `7` | **Zen Push** | `intersect_shape(SphereShape3D(r=5.5))` dalam kerucut arah $\hat{u}_{\text{aim}}$ (`dot > 0.35`): dorong impuls kuat ke blok & musuh. |
| `8` | **Boomerang** | Spawn `BoomerangBlade` sepanjang kurva Bézier kuadratik keluar menuju $\vec{p}_{\text{cursor}} + 4\hat{u}_{\text{aim}}$ lalu kembali ke kapibara. |
| `9` | **Pinball Spin** | `bounce = 0.95`, `gravity_scale = 0.25`, kecepatan minimum `18.0 m/s` selama `2.0 s` dengan dorongan tiap benturan. |
| `10` | **Vortex Pull** | Query objek terdekat di sekitar $\vec{p}_{\text{cursor}}$ (radius `3.0 m`), tarik ke arah $\vec{p}_{\text{capy}}$ selama `0.6 s`. |
| `11` | **Rocket Onsen** | Impuls jetpack `Vector3(4, 14, 0)` pada kapibara + spawn 1 `YuzuRocket` ke $\vec{p}_{\text{cursor}}$. |

### 3.3 Skema `user://save_data.json` (80 Sub-Levels)
```json
{
  "version": 4,
  "audio": { "master": 0.85, "bgm": 0.6, "sfx": 0.9, "muted": false },
  "progress": {
    "1-1": { "unlocked": true, "best_score": 28400, "stars": 3 }
  }
}
```
*Aturan Unlock:* Menyelesaikan `W-S` (1+ bintang) membuka `W-(S+1)`, atau jika `S == 20` membuka `(W+1)-1`.

---

## 4. Strategi Validasi Otomatis 80 Stage & Export Offline

1. **Automated 80-Stage Stability Validator (Headless Godot Script):**
   - Menjalankan loop validasi terhadap seluruh `80` file JSON (`w1/1-1.json` .. `w4/4-20.json`) melalui `Godot_v4.7.1-stable_win64_console.exe --headless`:
   - Memverifikasi bahwa setiap stage memiliki musuh $\ge 1$, antrian kapibara $\ge 1$, dan setelah simulasi fisika berjalan selama `2.0 detik` tanpa tembakan, **seluruh musuh masih hidup dan struktur stabil** (tidak roboh sendiri karena koordinat meleset!).
2. **Export Standalone (`4.7.1.stable`):**
   - Preset `Windows Desktop` (`x86_64`), `embed_pck = true` $\rightarrow$ `AngryCapibara.exe` 100% offline.
