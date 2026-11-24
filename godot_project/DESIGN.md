# DESIGN.md — Angry Capibara Anti-Slop Visual & Color System
*(Mengikuti prinsip filter `miqdadbadjuber/anti-slop`: palet terukur, nol gradasi AI default teal-oranye keruh, nol tombol warna-warni acak, satu atmosfer warna terpadu.)*

## 1. Aturan Palet Warna (`R-01`: Maksimal 3 Warna Inti + 1 Aksen + Netral Hangat)
- **Core 1 — Langit Woodblock & Kertas Washi (Cahaya Atmosfer):**
  - Zenith langit cerah: `#5A9EC4` (menggantikan teal gelap keruh khas AI)
  - Langit tengah: `#9AC8D8`
  - Horizon & pendar matahari washi: `#FBF0D4` / `#F6D482`
  - Awan: `#FCF6E8` (atas) + `#B8C3CE` (bawah teduh)
- **Core 2 — Hijau Botani Matcha & Bambu Alami (Nol Hijau Neon Digital):**
  - Pegunungan jauh: `#6E988E` → `#9DB9AC`
  - Bukit tengah: `#5B8454` → `#3E6244`
  - Bukit lumut depan: `#699848` → `#3D6835` → `#29452B`
  - Bambu & ketapel: `#7BA04A` → `#4E7232` → `#2F4A24`
- **Core 3 — Kayu Cedar & Netral Espresso Hangat (Grounding & UI Sekunder):**
  - Kayu Onsen: `#9E6338` → `#6B3D22`
  - Genteng arang: `#343D48`
  - Tinta / bayangan dalam / panel UI sekunder: `#241916` & `#2D221D`
  - Teks & border UI netral: `#F5ECD8` & `#D4BE98`
- **1 Aksen Fokus Tunggal — Vermilion Jepang (`#D1382B`):**
  - Dipakai khusus untuk titik fokus utama: **Chill Capi (MC)**, **Gerbang Torii** (diredupkan atmosfer `#C64535`), dan tombol CTA utama **`PLAY`**.

## 2. Disiplin UI Anti-Slop (`antislop-ui`)
- **Nol tombol pelangi:** Hanya tombol **`PLAY`** yang memakai aksen Vermilion (`#D1382B`). Seluruh tombol sekunder (`4 WORLD`, `CREDITS`, `EXIT`) memakai **satu warna netral konsisten** (*Warm Lacquer Espresso* `#2D221D`, border krem `#C9B28B`).
- **Gradasi dengan fungsi hierarki jelas:** Hanya digunakan pada langit & pancaran matahari untuk mengarahkan mata ke logo dan MC; tidak ada neon glow acak pada elemen UI.
- **Satu LUT Master Visual Studio C++:** Seluruh 9 layer latar & seluruh cutout kapibara 2D melewati fungsi harmonisasi warna & *washi paper tooth* yang sama di `vs_asset_forge`.
