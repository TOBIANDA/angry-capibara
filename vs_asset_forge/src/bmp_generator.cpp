#include "bmp_generator.h"
#include <vector>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <cmath>
#include <algorithm>
#include <functional>

namespace {
struct RGB {
	uint8_t r, g, b;
};

inline uint8_t ClampByte(float v) {
	return static_cast<uint8_t>(std::clamp(v, 0.0f, 255.0f));
}

inline RGB LerpRGB(RGB a, RGB b, float t) {
	t = std::clamp(t, 0.0f, 1.0f);
	return {
		ClampByte(a.r + (b.r - a.r) * t),
		ClampByte(a.g + (b.g - a.g) * t),
		ClampByte(a.b + (b.b - a.b) * t)
	};
}

inline float Hash2D(int x, int y, uint32_t seed) {
	uint32_t h = static_cast<uint32_t>(x) * 374761393u + static_cast<uint32_t>(y) * 668265263u + seed * 1442695041u;
	h = (h ^ (h >> 13)) * 1274126177u;
	return static_cast<float>((h ^ (h >> 16)) & 0xFFFFu) / 65535.0f;
}

inline float SmoothNoise(float x, float y, uint32_t seed) {
	int ix = static_cast<int>(std::floor(x));
	int iy = static_cast<int>(std::floor(y));
	float fx = x - ix;
	float fy = y - iy;
	fx = fx * fx * (3.0f - 2.0f * fx);
	fy = fy * fy * (3.0f - 2.0f * fy);

	float a = Hash2D(ix, iy, seed);
	float b = Hash2D(ix + 1, iy, seed);
	float c = Hash2D(ix, iy + 1, seed);
	float d = Hash2D(ix + 1, iy + 1, seed);

	return (a + (b - a) * fx) + ((c + (d - c) * fx) - (a + (b - a) * fx)) * fy;
}

bool WriteBMP24(const std::string& path, int w, int h, const std::function<RGB(float u, float v, int px, int py)>& shader) {
	const int rowBytes = 3 * w;
	const int padding = (rowBytes % 4) ? (4 - (rowBytes % 4)) : 0;
	const int stride = rowBytes + padding;
	const uint32_t dataSize = static_cast<uint32_t>(stride * h);
	const uint32_t fileSize = 54u + dataSize;

	uint8_t header[54] = {};
	header[0] = 'B';
	header[1] = 'M';
	std::memcpy(&header[2], &fileSize, 4);
	uint32_t offset = 54u;
	std::memcpy(&header[10], &offset, 4);
	uint32_t dibSize = 40u;
	std::memcpy(&header[14], &dibSize, 4);
	std::memcpy(&header[18], &w, 4);
	std::memcpy(&header[22], &h, 4);
	uint16_t planes = 1;
	std::memcpy(&header[26], &planes, 2);
	uint16_t bpp = 24;
	std::memcpy(&header[28], &bpp, 2);
	std::memcpy(&header[34], &dataSize, 4);

	std::ofstream out(path, std::ios::binary);
	if (!out.is_open()) return false;
	out.write(reinterpret_cast<const char*>(header), 54);

	std::vector<uint8_t> row(stride, 0);
	for (int y = 0; y < h; ++y) {
		float v = static_cast<float>(y) / static_cast<float>(h - 1);
		for (int x = 0; x < w; ++x) {
			float u = static_cast<float>(x) / static_cast<float>(w - 1);
			RGB c = shader(u, v, x, y);
			row[x * 3 + 0] = c.b;
			row[x * 3 + 1] = c.g;
			row[x * 3 + 2] = c.r;
		}
		out.write(reinterpret_cast<const char*>(row.data()), stride);
	}
	return out.good();
}

// Tekstur bulu painterly cerah dengan sapuan kuas tegas ala Angry Birds Toons
bool WriteStylizedFurTexture(const std::string& path, RGB shadowCol, RGB midCol, RGB highlightCol, uint32_t seed) {
	return WriteBMP24(path, 256, 256, [&](float u, float v, int, int) {
		float stroke = SmoothNoise(u * 24.0f, v * 7.5f, seed);
		float clump = SmoothNoise(u * 7.5f, v * 7.5f, seed + 29);
		float tuft = std::floor((stroke * 0.65f + clump * 0.35f) * 5.0f) / 5.0f;
		RGB col = (tuft < 0.5f)
			? LerpRGB(shadowCol, midCol, tuft * 2.0f)
			: LerpRGB(midCol, highlightCol, (tuft - 0.5f) * 2.0f);
		return LerpRGB(col, highlightCol, 0.16f * std::sin(v * 3.14159f));
	});
}
} // namespace

bool GenerateAllTexturesW12(const std::string& texDir) {
	bool ok = true;

	// 1. Warna Unik per Karakter (Vibrasi Angry Birds!)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_red.bmp",      { 178, 42, 32 },  { 228, 66, 46 },  { 252, 114, 78 },  101); // Chill (Merah-Terracotta)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_yellow.bmp",   { 208, 146, 14 }, { 250, 198, 28 }, { 255, 232, 96 },  155); // Dash (Kuning Listrik)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_sky.bmp",      { 36, 126, 212 }, { 74, 174, 248 }, { 138, 216, 255 }, 202); // Mini (Biru Langit)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_obsidian.bmp", { 36, 36, 46 },   { 58, 58, 72 },   { 92, 92, 112 },   303); // Yuzu Bomb (Hitam Arang)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_caramel.bmp",  { 158, 86, 32 },  { 208, 126, 52 }, { 242, 168, 84 },  333); // Seed-Blaster (Karamel)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_jedi.bmp",     { 196, 152, 102 }, { 232, 192, 138 }, { 252, 224, 178 }, 344); // Bambu-Saber (Krem Hangat)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_maroon.bmp",   { 108, 24, 48 },  { 152, 42, 72 },  { 192, 72, 104 },  366); // Heavy Onsen (Marun Beri)

	// 2. Perut, Pipi, Sklera, Pupil, Moncong
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_belly.bmp", { 232, 206, 168 }, { 248, 228, 198 }, { 255, 246, 228 }, 355);
	ok &= WriteBMP24(texDir + "/tex_capy_cheek.bmp", 128, 128, [](float, float, int px, int py) -> RGB {
		float n = SmoothNoise(px * 0.15f, py * 0.15f, 388);
		return LerpRGB({ 246, 112, 118 }, { 255, 164, 164 }, n);
	});
	ok &= WriteBMP24(texDir + "/tex_capy_eye_white.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float rim = std::clamp((u - 0.5f) * (u - 0.5f) + (v - 0.5f) * (v - 0.5f), 0.0f, 0.25f) * 2.0f;
		return LerpRGB({ 255, 255, 255 }, { 222, 232, 246 }, rim);
	});
	ok &= WriteBMP24(texDir + "/tex_capy_eye.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float dx = u - 0.60f, dy = v - 0.64f;
		if (dx * dx + dy * dy < 0.055f) return { 255, 255, 255 };
		float dx2 = u - 0.36f, dy2 = v - 0.36f;
		if (dx2 * dx2 + dy2 * dy2 < 0.018f) return { 230, 242, 255 };
		return { 18, 16, 20 };
	});
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_snout.bmp", { 84, 48, 36 }, { 118, 70, 52 }, { 148, 92, 68 }, 404);

	// 3. Aksesori Khusus (Kacamata, Visor, Sumbu Api, Rambut, Topi, Jubah)
	ok &= WriteBMP24(texDir + "/tex_shades_black.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float glint = std::exp(-std::abs((u - v) - 0.18f) * 22.0f);
		return LerpRGB({ 18, 22, 30 }, { 130, 175, 220 }, glint * 0.65f);
	});
	ok &= WriteBMP24(texDir + "/tex_visor_orange.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float glint = std::exp(-std::abs((u - v) - 0.15f) * 18.0f);
		return LerpRGB({ 248, 112, 18 }, { 255, 232, 128 }, glint * 0.7f);
	});
	ok &= WriteBMP24(texDir + "/tex_hair_blonde.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float streak = SmoothNoise(u * 24.0f, v * 5.0f, 444);
		return LerpRGB({ 218, 164, 34 }, { 255, 224, 98 }, streak);
	});
	ok &= WriteBMP24(texDir + "/tex_accent_red.bmp", 128, 128, [](float u, float v, int px, int py) -> RGB {
		float weave = 0.5f + 0.5f * std::sin(px * 0.5f);
		return LerpRGB({ 212, 28, 36 }, { 255, 78, 68 }, weave * 0.6f);
	});
	ok &= WriteBMP24(texDir + "/tex_fuse_spark.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		return LerpRGB({ 255, 92, 12 }, { 255, 245, 92 }, v);
	});
	ok &= WriteBMP24(texDir + "/tex_mouth_dark.bmp", 64, 64, [](float, float, int, int) -> RGB {
		return { 68, 16, 22 };
	});
	ok &= WriteBMP24(texDir + "/tex_tongue_pink.bmp", 64, 64, [](float, float v, int, int) -> RGB {
		return LerpRGB({ 238, 92, 118 }, { 255, 146, 164 }, v);
	});
	ok &= WriteBMP24(texDir + "/tex_eye_socket.bmp", 64, 64, [](float, float, int, int) -> RGB {
		return { 112, 116, 126 };
	});
	ok &= WriteBMP24(texDir + "/tex_katana_steel.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		// Bilah baja katana mengkilap dengan garis hamon terang di sisi tajam
		float edge = std::clamp((u - 0.5f) * 2.0f, 0.0f, 1.0f);
		return LerpRGB({ 148, 158, 172 }, { 244, 248, 255 }, edge * 0.85f + 0.1f * std::sin(v * 24.0f));
	});

	// 4. Jeruk Yuzu, Daun & Material Lingkungan
	ok &= WriteBMP24(texDir + "/tex_yuzu.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float dimple = SmoothNoise(px * 0.28f, py * 0.28f, 505);
		float glow = 0.5f + 0.5f * std::sin(v * 3.14159f);
		return LerpRGB({ 248, 144, 10 }, { 255, 220, 48 }, 0.45f * dimple + 0.45f * glow);
	});
	ok &= WriteBMP24(texDir + "/tex_yuzu_leaf.bmp", 128, 128, [](float u, float v, int px, int py) -> RGB {
		float vein = std::exp(-std::abs(v - 0.5f) * 16.0f);
		float n = SmoothNoise(px * 0.2f, py * 0.2f, 606);
		RGB base = LerpRGB({ 42, 168, 52 }, { 96, 218, 74 }, n);
		return LerpRGB(base, { 170, 242, 114 }, vein * 0.6f);
	});
	ok &= WriteBMP24(texDir + "/tex_accent_gold.bmp", 128, 128, [](float u, float v, int px, int py) -> RGB {
		float weave = 0.5f + 0.5f * std::sin(px * 0.55f) * std::cos(py * 0.55f);
		return LerpRGB({ 240, 178, 16 }, { 255, 232, 74 }, weave * 0.65f);
	});
	ok &= WriteBMP24(texDir + "/tex_accent_blue.bmp", 128, 128, [](float u, float v, int px, int py) -> RGB {
		float weave = 0.5f + 0.5f * std::sin(px * 0.5f);
		return LerpRGB({ 32, 142, 248 }, { 104, 198, 255 }, weave * 0.6f);
	});
	ok &= WriteBMP24(texDir + "/tex_saber_green.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float core = std::exp(-std::abs(u - 0.5f) * 5.0f);
		return LerpRGB({ 36, 236, 98 }, { 232, 255, 238 }, core * 0.8f);
	});
	ok &= WriteBMP24(texDir + "/tex_bamboo.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float grain = SmoothNoise(px * 0.35f, py * 0.05f, 707);
		RGB col = LerpRGB({ 88, 164, 52 }, { 142, 208, 78 }, grain);
		float ring = std::fmod(v * 3.0f, 1.0f);
		if (ring < 0.06f) col = LerpRGB(col, { 54, 106, 30 }, 0.78f);
		return col;
	});
	ok &= WriteBMP24(texDir + "/tex_wood.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float ring = 0.5f + 0.5f * std::sin(u * 26.0f + SmoothNoise(u * 4.0f, v * 8.0f, 808) * 3.5f);
		return LerpRGB({ 136, 82, 38 }, { 194, 128, 68 }, ring);
	});
	ok &= WriteBMP24(texDir + "/tex_stone.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float n1 = SmoothNoise(px * 0.12f, py * 0.12f, 909);
		float n2 = SmoothNoise(px * 0.35f, py * 0.35f, 910);
		return LerpRGB({ 110, 118, 128 }, { 168, 176, 186 }, 0.65f * n1 + 0.35f * n2);
	});
	ok &= WriteBMP24(texDir + "/tex_towel.bmp", 128, 128, [](float u, float v, int px, int py) -> RGB {
		float weave = SmoothNoise(px * 0.5f, py * 0.5f, 950);
		RGB white = LerpRGB({ 236, 236, 230 }, { 252, 252, 248 }, weave);
		if (v < 0.14f || v > 0.86f) return LerpRGB(white, { 58, 148, 224 }, 0.8f);
		return white;
	});

	ok &= GenerateAnimeTexturesW12(texDir);
	return ok;
}

namespace {
enum class EyeMood {
	AngrySlant,   // Kelopak atas miring tajam ke arah hidung (MARAH)
	WideFierce,   // Mata melotot fokus pupil tajam (HIPERAKTIF / TERIAK)
	SlySinis,     // Menyipit licik/sinis
	LazyHalfLid   // Kelopak datar berat turun 45% (MALAS / SUMBU PENDEK)
};

// outerToInnerX: x = -1 adalah sisi dalam (hidung), x = +1 adalah sisi luar (telinga)
bool WriteAnimeEyeTexture(const std::string& path, RGB irisTop, RGB irisBot, EyeMood mood) {
	return WriteBMP24(path, 256, 256, [&](float u, float v, int, int) -> RGB {
		float x = (u - 0.5f) * 2.0f;
		float y = (v - 0.5f) * 2.0f;
		float r = std::sqrt(x * x + y * y);

		// Kelopak atas sesuai emosi (x < 0 = sisi dalam dekat hidung)
		float lidY = 0.65f;
		RGB lidFill = { 20, 14, 18 };
		switch (mood) {
		case EyeMood::AngrySlant:
			// Sisi dalam (x=-1) turun rendah ke y=-0.06, sisi luar (x=+1) naik ke y=0.58 -> miring tajam!
			lidY = 0.26f + 0.32f * x;
			break;
		case EyeMood::WideFierce:
			lidY = 0.56f + 0.14f * x;
			break;
		case EyeMood::SlySinis:
			// Menyipit sinis dari atas & sedikit dari bawah, kelopak abu gelap agar terpisah dari alis
			lidY = 0.16f + 0.12f * x;
			lidFill = { 84, 68, 66 };
			if (y < -0.52f) return { 24, 18, 22 };
			break;
		case EyeMood::LazyHalfLid:
			// Kelopak datar berat setengah menutup mata (ekspresi malas / sumbu pendek)
			lidY = 0.08f - 0.03f * x * x;
			lidFill = { 96, 74, 70 };
			break;
		}

		if (y > lidY) {
			if (y < lidY + 0.10f) return { 18, 12, 16 }; // Garis bulu mata hitam tegas
			return lidFill;
		}

		if (r > 0.90f) return { 24, 18, 22 };

		RGB sclera = (y > lidY - 0.14f) ? RGB{ 196, 204, 222 } : RGB{ 252, 253, 255 };

		float irisR = (mood == EyeMood::WideFierce) ? 0.54f : 0.62f;
		if (r < irisR) {
			float ir = r / irisR;
			float grad = std::clamp((0.45f - y) * 0.95f, 0.0f, 1.0f);
			RGB col = LerpRGB(irisTop, irisBot, grad);

			float pupilR = (mood == EyeMood::AngrySlant || mood == EyeMood::WideFierce) ? 0.38f : 0.44f;
			if (ir < pupilR) col = { 18, 12, 20 };
			else if (ir > 0.84f) col = LerpRGB(col, { 20, 14, 22 }, 0.78f);

			// Highlight specular anime tajam
			float h1 = (x + 0.24f) * (x + 0.24f) + (y - 0.12f) * (y - 0.12f);
			float h2 = (x - 0.20f) * (x - 0.20f) + (y + 0.22f) * (y + 0.22f);
			if (h1 < 0.022f) return { 255, 255, 255 };
			if (h2 < 0.010f) return { 255, 255, 255 };

			return col;
		}
		return sclera;
	});
}
} // namespace

bool GenerateAnimeTexturesW12(const std::string& texDir) {
	bool ok = true;

	// 1. Bulu Capibara Asli yang Hangat, Bersih, dan Cel-Friendly
	ok &= WriteStylizedFurTexture(texDir + "/tex_anime_fur_cinnamon.bmp", { 132, 76, 44 },  { 176, 108, 66 }, { 208, 138, 92 },  1101);
	ok &= WriteStylizedFurTexture(texDir + "/tex_anime_fur_honey.bmp",    { 178, 118, 52 }, { 218, 158, 76 }, { 242, 192, 112 }, 1102);
	ok &= WriteStylizedFurTexture(texDir + "/tex_anime_fur_cream.bmp",    { 196, 158, 118 }, { 232, 198, 156 }, { 250, 224, 188 }, 1103);
	ok &= WriteStylizedFurTexture(texDir + "/tex_anime_fur_espresso.bmp", { 66, 46, 38 },   { 98, 70, 58 },   { 132, 98, 82 },   1104);
	ok &= WriteStylizedFurTexture(texDir + "/tex_anime_fur_caramel.bmp",  { 148, 92, 46 },  { 192, 126, 68 }, { 224, 162, 102 }, 1105);
	ok &= WriteStylizedFurTexture(texDir + "/tex_anime_fur_ash.bmp",      { 142, 124, 108 }, { 184, 164, 144 }, { 216, 198, 178 }, 1106);
	ok &= WriteStylizedFurTexture(texDir + "/tex_anime_fur_umber.bmp",    { 82, 48, 36 },   { 122, 76, 56 },  { 156, 104, 78 },  1107);

	// 2. Mata Anime Resolusi 256x256 sesuai Watak (Marah / Fokus / Sinis / Malas)
	ok &= WriteAnimeEyeTexture(texDir + "/tex_anime_eye_chill.bmp",   { 185, 28, 22 },  { 255, 96, 38 },  EyeMood::AngrySlant);  // MC Merah: MARAH
	ok &= WriteAnimeEyeTexture(texDir + "/tex_anime_eye_dash.bmp",    { 208, 118, 12 }, { 255, 224, 52 }, EyeMood::WideFierce);  // Dash: TERIAK FOKUS
	ok &= WriteAnimeEyeTexture(texDir + "/tex_anime_eye_mini.bmp",    { 24, 96, 212 },  { 84, 198, 255 }, EyeMood::SlySinis);    // Mini: NAKAL / SINIS
	ok &= WriteAnimeEyeTexture(texDir + "/tex_anime_eye_bomb.bmp",    { 188, 52, 14 },  { 255, 162, 28 }, EyeMood::LazyHalfLid); // Bomb: MALAS BERAT
	ok &= WriteAnimeEyeTexture(texDir + "/tex_anime_eye_katana.bmp",  { 18, 138, 76 },  { 92, 240, 142 }, EyeMood::AngrySlant);  // Katana: DINGIN TAJAM
	ok &= WriteAnimeEyeTexture(texDir + "/tex_anime_eye_heavy.bmp",   { 138, 16, 42 },  { 232, 54, 82 },  EyeMood::LazyHalfLid); // Heavy: TATAPAN DINGIN BERAT

	// 3. Aksen Anime Cerah (Syal, Simbol Marah, Ink Outline Hitam)
	ok &= WriteBMP24(texDir + "/tex_anime_scarf_red.bmp", 128, 128, [](float, float v, int, int) -> RGB {
		return (v < 0.06f || v > 0.94f) ? RGB{ 255, 212, 72 } : RGB{ 228, 38, 42 };
	});
	ok &= WriteBMP24(texDir + "/tex_anime_scarf_blue.bmp", 128, 128, [](float, float v, int, int) -> RGB {
		return (v < 0.15f || v > 0.85f) ? RGB{ 255, 255, 255 } : RGB{ 42, 142, 248 };
	});
	ok &= WriteBMP24(texDir + "/tex_anime_ink.bmp", 32, 32, [](float, float, int, int) -> RGB {
		return { 24, 18, 24 };
	});
	ok &= WriteBMP24(texDir + "/tex_anime_anger.bmp", 64, 64, [](float, float, int, int) -> RGB {
		return { 248, 52, 48 };
	});

	// 4. Tekstur Key-Art Home Screen (Bukit Organik, Bulan Yuzu, Batu Gelap, Api, Slash)
	ok &= WriteBMP24(texDir + "/tex_home_hill.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float n1 = SmoothNoise(px * 0.08f, py * 0.08f, 1501);
		float n2 = SmoothNoise(px * 0.22f, py * 0.22f, 1502);
		float crater = SmoothNoise(px * 0.055f, py * 0.055f, 1509);
		RGB darkEarth = { 46, 25, 13 };
		RGB midEarth  = { 98, 56, 28 };
		RGB rimGold   = { 156, 102, 48 };
		RGB col = LerpRGB(darkEarth, midEarth, 0.45f * n1 + 0.35f * n2 + 0.25f * v);
		if (crater > 0.68f) col = LerpRGB(col, { 26, 14, 8 }, (crater - 0.68f) * 2.6f);
		// Puncak bukit menerima bias cahaya bulan hangat
		if (v > 0.72f) col = LerpRGB(col, rimGold, (v - 0.72f) * 2.4f);
		return col;
	});

	ok &= WriteBMP24(texDir + "/tex_home_yuzu_moon.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float n1 = SmoothNoise(px * 0.07f, py * 0.07f, 1601);
		float c1 = SmoothNoise(px * 0.045f, py * 0.045f, 1602);
		RGB col = LerpRGB({ 255, 224, 96 }, { 255, 248, 178 }, n1 * 0.75f + 0.25f * v);
		if (c1 > 0.64f) col = LerpRGB(col, { 236, 186, 56 }, (c1 - 0.64f) * 2.2f);
		return col;
	});

	ok &= WriteBMP24(texDir + "/tex_home_rock_dark.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float n1 = SmoothNoise(px * 0.09f, py * 0.09f, 1701);
		float ridge = SmoothNoise(px * 0.20f, py * 0.20f, 1702);
		RGB col = LerpRGB({ 24, 28, 62 }, { 56, 62, 112 }, 0.6f * n1 + 0.4f * ridge);
		if (v > 0.78f) col = LerpRGB(col, { 92, 104, 168 }, (v - 0.78f) * 2.5f);
		return col;
	});

	ok &= WriteBMP24(texDir + "/tex_home_flame.bmp", 128, 128, [](float, float v, int px, int py) -> RGB {
		float flick = SmoothNoise(px * 0.18f, py * 0.14f, 1801) * 0.18f;
		float t = std::clamp(v + flick - 0.08f, 0.0f, 1.0f);
		if (t < 0.35f) return LerpRGB({ 255, 254, 224 }, { 255, 212, 54 }, t / 0.35f);
		if (t < 0.72f) return LerpRGB({ 255, 212, 54 }, { 255, 96, 20 }, (t - 0.35f) / 0.37f);
		return LerpRGB({ 255, 96, 20 }, { 215, 32, 16 }, (t - 0.72f) / 0.28f);
	});

	ok &= WriteBMP24(texDir + "/tex_home_slash.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float core = std::exp(-std::abs(u - 0.5f) * 4.5f);
		return LerpRGB({ 42, 210, 255 }, { 236, 255, 255 }, core * (0.65f + 0.35f * v));
	});

	ok &= WriteBMP24(texDir + "/tex_home_speed.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float core = std::exp(-std::abs(u - 0.5f) * 4.2f);
		return LerpRGB({ 255, 146, 18 }, { 255, 248, 152 }, core * (0.60f + 0.40f * v));
	});

	// 5. Tekstur Arena 2.5D Bamboo-Onsen & Musuh Crocodile Raider (Painterly Halus Anti-Slop, serasi dengan Kapibara!)
	ok &= WriteBMP24(texDir + "/tex_croco_green.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		// Kulit reptil painterly halus hijau-giok/zaitun (bebas pola polkadot/kotak kasar & bebas neon!)
		float broad = SmoothNoise(px * 0.032f, py * 0.032f, 1901);
		float blotch = SmoothNoise(px * 0.085f, py * 0.065f, 1902);
		float scaleHint = 0.5f + 0.5f * std::sin(u * 38.0f + std::sin(v * 20.0f) * 1.4f) * std::sin(v * 34.0f);
		float t = std::clamp(0.58f * broad + 0.30f * blotch + 0.12f * scaleHint, 0.0f, 1.0f);
		RGB col = (t < 0.5f)
			? LerpRGB({ 52, 102, 54 }, { 84, 140, 68 }, t * 2.0f)
			: LerpRGB({ 84, 140, 68 }, { 126, 174, 92 }, (t - 0.5f) * 2.0f);
		// Gradasi cahaya halus bagian atas tubuh
		return LerpRGB(col, { 142, 186, 102 }, 0.14f * std::sin(v * 3.14159f));
	});
	ok &= WriteBMP24(texDir + "/tex_croco_scale_dark.bmp", 128, 128, [](float u, float v, int px, int py) -> RGB {
		float n = SmoothNoise(px * 0.08f, py * 0.08f, 1904);
		float ridge = 0.5f + 0.5f * std::sin(v * 18.0f);
		return LerpRGB({ 24, 52, 32 }, { 52, 92, 48 }, 0.55f * n + 0.45f * ridge);
	});
	ok &= WriteBMP24(texDir + "/tex_croco_belly.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		// Perut buaya krem-oker bergaris-garis (ribbed scutes klasik!)
		float rib = std::fmod(v * 9.0f, 1.0f);
		float n = SmoothNoise(px * 0.06f, py * 0.06f, 1907);
		RGB col = LerpRGB({ 214, 194, 134 }, { 244, 228, 174 }, 0.55f * n + 0.45f * std::sin(rib * 3.14159f));
		if (rib < 0.12f || rib > 0.90f) col = LerpRGB(col, { 156, 130, 76 }, 0.65f);
		return col;
	});
	ok &= WriteBMP24(texDir + "/tex_croco_eye.bmp", 256, 256, [](float u, float v, int, int) -> RGB {
		// Mata reptil kuning-amber tajam + pupil celah vertikal + kelopak atas licik + catchlight ganda
		float du = (u - 0.50f) * 2.0f;
		float dv = (v - 0.50f) * 2.0f;
		float r = std::sqrt(du * du + dv * dv);
		// Iris emas-amber hangat dengan tepi oranye-tembaga
		RGB iris = LerpRGB({ 254, 224, 72 }, { 226, 142, 22 }, std::clamp(r * 1.15f, 0.0f, 1.0f));
		if (r > 0.84f) iris = LerpRGB(iris, { 68, 42, 18 }, std::clamp((r - 0.84f) * 6.0f, 0.0f, 1.0f));
		// Pupil celah vertikal reptil khas buaya nakal
		float slitX = du / 0.22f;
		float slitY = dv / 0.68f;
		float slitD = slitX * slitX + slitY * slitY;
		if (slitD < 1.0f) {
			float edge = std::clamp((1.0f - slitD) * 4.0f, 0.0f, 1.0f);
			iris = LerpRGB(iris, { 20, 14, 12 }, edge);
		}
		// Bayangan kelopak atas miring (ekspresi licik!)
		float lidLine = 0.56f - du * 0.18f;
		if (dv > lidLine) {
			iris = LerpRGB(iris, { 34, 62, 34 }, std::clamp((dv - lidLine) * 5.0f, 0.0f, 0.85f));
		}
		// Kilau anime putih tajam (catchlight utama + sekunder)
		float c1 = (du - 0.24f) * (du - 0.24f) + (dv - 0.22f) * (dv - 0.22f);
		float c2 = (du + 0.20f) * (du + 0.20f) + (dv + 0.22f) * (dv + 0.22f);
		if (c1 < 0.030f) return { 255, 254, 246 };
		if (c2 < 0.008f) return { 255, 248, 224 };
		return iris;
	});
	ok &= WriteBMP24(texDir + "/tex_torii_red.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float grain = SmoothNoise(px * 0.25f, py * 0.05f, 1910);
		return LerpRGB({ 146, 32, 24 }, { 206, 56, 36 }, 0.65f * grain + 0.35f * v);
	});
	ok &= WriteBMP24(texDir + "/tex_moss_top.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float n1 = SmoothNoise(px * 0.10f, py * 0.10f, 1920);
		float n2 = SmoothNoise(px * 0.30f, py * 0.30f, 1921);
		RGB col = LerpRGB({ 44, 108, 36 }, { 108, 174, 52 }, 0.65f * n1 + 0.35f * n2);
		if (n2 > 0.78f) col = LerpRGB(col, { 156, 206, 74 }, 0.55f);
		return col;
	});
	ok &= WriteBMP24(texDir + "/tex_cliff_rock.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float strata = 0.5f + 0.5f * std::sin(v * 20.0f + SmoothNoise(px * 0.08f, py * 0.08f, 1930) * 3.0f);
		float grain = SmoothNoise(px * 0.24f, py * 0.24f, 1931);
		RGB col = LerpRGB({ 48, 38, 34 }, { 92, 74, 62 }, 0.55f * strata + 0.45f * grain);
		if (v > 0.80f) col = LerpRGB(col, { 54, 114, 42 }, (v - 0.80f) * 3.2f);
		return col;
	});

	// 6. Tekstur Painterly Rovio (bebas noise kasar & bebas pucat!)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_crimson.bmp", { 132, 16, 22 }, { 196, 26, 30 }, { 230, 52, 44 }, 2001);
	ok &= WriteBMP24(texDir + "/tex_moss_painterly.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float broad = SmoothNoise(px * 0.032f, py * 0.032f, 2010);
		float brush = SmoothNoise(px * 0.09f, py * 0.045f, 2011);
		RGB col = LerpRGB({ 44, 94, 38 }, { 86, 148, 54 }, 0.65f * broad + 0.35f * brush);
		if (broad > 0.68f) col = LerpRGB(col, { 118, 176, 68 }, (broad - 0.68f) * 2.2f);
		return col;
	});
	ok &= WriteBMP24(texDir + "/tex_roof_tile.bmp", 256, 256, [](float u, float v, int px, int py) -> RGB {
		float wave = 0.5f + 0.5f * std::sin(u * 44.0f);
		float row = std::fmod(v * 10.0f, 1.0f);
		RGB col = LerpRGB({ 38, 44, 54 }, { 68, 78, 92 }, 0.65f * wave + 0.35f * row);
		if (row < 0.12f) col = LerpRGB(col, { 22, 26, 34 }, 0.72f);
		return col;
	});
	ok &= WriteBMP24(texDir + "/tex_shoji_glow.bmp", 128, 128, [](float u, float v, int, int) -> RGB {
		float gu = std::fmod(u * 4.0f, 1.0f);
		float gv = std::fmod(v * 3.0f, 1.0f);
		if (gu < 0.09f || gu > 0.91f || gv < 0.09f || gv > 0.91f) return { 72, 44, 24 };
		return LerpRGB({ 255, 214, 112 }, { 255, 244, 184 }, 1.0f - std::abs(v - 0.5f));
	});

	return ok;
}
