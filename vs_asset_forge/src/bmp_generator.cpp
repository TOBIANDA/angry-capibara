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
	// Seamless periodic smooth noise helper (wraps cleanly at period px, py)
	auto TileNoise = [](float u, float v, float freqX, float freqY, uint32_t seed) -> float {
		int px = std::max(1, static_cast<int>(std::round(freqX)));
		int py = std::max(1, static_cast<int>(std::round(freqY)));
		float x = u * px;
		float y = v * py;
		int ix = static_cast<int>(std::floor(x));
		int iy = static_cast<int>(std::floor(y));
		float fx = x - ix;
		float fy = y - iy;
		fx = fx * fx * (3.0f - 2.0f * fx);
		fy = fy * fy * (3.0f - 2.0f * fy);
		int x0 = ((ix % px) + px) % px;
		int x1 = (x0 + 1) % px;
		int y0 = ((iy % py) + py) % py;
		int y1 = (y0 + 1) % py;
		float a = Hash2D(x0, y0, seed);
		float b = Hash2D(x1, y0, seed);
		float c = Hash2D(x0, y1, seed);
		float d = Hash2D(x1, y1, seed);
		return (a + (b - a) * fx) + ((c + (d - c) * fx) - (a + (b - a) * fx)) * fy;
	};

	// Hand-painted segmented sage/matcha-gold bamboo culms (512x512 seamless)
	ok &= WriteBMP24(texDir + "/tex_bamboo.bmp", 512, 512, [&](float u, float v, int, int) -> RGB {
		const float culms = 3.0f;
		float cu = std::fmod(u * culms, 1.0f);
		int culmIdx = static_cast<int>(std::floor(u * culms));
		// Cylindrical shading across each bamboo stalk
		float cyl = std::sin(cu * 3.14159265f);
		float fiber = TileNoise(u, v, 48.0f, 8.0f, 707);
		float broad = TileNoise(u, v, 6.0f, 6.0f, 711);
		float toneShift = (culmIdx == 1) ? 0.08f : ((culmIdx == 2) ? -0.06f : 0.0f);

		RGB deepCol  = { 68, 96, 44 };
		RGB midCol   = { 118, 148, 66 };
		RGB lightCol = { 172, 192, 98 };
		float shade = std::clamp(cyl * 0.72f + fiber * 0.20f + broad * 0.14f + toneShift, 0.0f, 1.0f);
		RGB col = (shade < 0.55f)
			? LerpRGB(deepCol, midCol, shade / 0.55f)
			: LerpRGB(midCol, lightCol, (shade - 0.55f) / 0.45f);

		// Subtle warm vertical sheen on sunlit side of culm
		float sheen = std::exp(-std::pow((cu - 0.36f) / 0.14f, 2.0f));
		col = LerpRGB(col, { 216, 226, 148 }, sheen * 0.28f);

		// Dark crease between adjacent bamboo stalks
		float seamDist = std::min(cu, 1.0f - cu);
		if (seamDist < 0.045f) {
			col = LerpRGB({ 42, 62, 28 }, col, seamDist / 0.045f);
		}

		// Staggered bamboo internode rings with raised highlight lip + dark groove
		float vOff = std::fmod(v * 3.0f + culmIdx * 0.31f, 1.0f);
		if (vOff < 0.045f) {
			col = LerpRGB(col, { 44, 64, 28 }, 0.80f);
		} else if (vOff < 0.095f) {
			float hi = 1.0f - (vOff - 0.045f) / 0.050f;
			col = LerpRGB(col, { 214, 224, 146 }, hi * 0.58f);
		} else if (vOff > 0.945f) {
			float sh = (vOff - 0.945f) / 0.055f;
			col = LerpRGB(col, { 54, 78, 36 }, sh * 0.45f);
		}
		return col;
	});

	// Hand-painted warm cedar planks with beveled seams, wood grain & knots (512x512 seamless)
	ok &= WriteBMP24(texDir + "/tex_wood.bmp", 512, 512, [&](float u, float v, int, int) -> RGB {
		const float planks = 4.0f;
		float pv = std::fmod(v * planks, 1.0f);
		int pIdx = static_cast<int>(std::floor(v * planks));
		float plankVar = Hash2D(pIdx, 17, 801);

		// Staggered vertical plank end-joint
		float jointU = std::fmod(u + pIdx * 0.37f, 1.0f);
		float grainWarp = TileNoise(u, v, 4.0f, 12.0f, 808) * 0.42f + TileNoise(u, v, 10.0f, 24.0f, 809) * 0.16f;
		float grain = 0.5f + 0.5f * std::sin((pv * 9.5f + grainWarp * 6.0f + pIdx * 1.7f) * 3.14159f);
		float fineFiber = TileNoise(u, v, 12.0f, 64.0f, 812);

		// Subtle wood knot per plank
		float ku = std::fmod(u + pIdx * 0.29f + 0.18f, 1.0f) - 0.5f;
		float kv = pv - 0.52f;
		float knotD = std::sqrt((ku * ku) * 6.0f + (kv * kv) * 28.0f);
		float knotRing = (knotD < 0.55f) ? (0.5f + 0.5f * std::cos(knotD * 22.0f)) * (1.0f - knotD / 0.55f) : 0.0f;

		RGB darkCedar  = { 112, 74, 46 };
		RGB midCedar   = { 156, 108, 66 };
		RGB lightCedar = { 196, 146, 96 };
		float t = std::clamp(grain * 0.52f + fineFiber * 0.26f + plankVar * 0.22f - knotRing * 0.28f, 0.0f, 1.0f);
		RGB col = (t < 0.5f)
			? LerpRGB(darkCedar, midCedar, t * 2.0f)
			: LerpRGB(midCedar, lightCedar, (t - 0.5f) * 2.0f);

		// Crisp horizontal plank bevel & recessed dark espresso seam
		if (pv < 0.045f || pv > 0.955f) {
			col = LerpRGB(col, { 58, 36, 22 }, 0.82f);
		} else if (pv > 0.86f) {
			float bev = (pv - 0.86f) / 0.095f;
			col = LerpRGB(col, { 222, 178, 124 }, bev * 0.42f);
		} else if (pv < 0.13f) {
			float sh = 1.0f - (pv - 0.045f) / 0.085f;
			col = LerpRGB(col, { 76, 48, 30 }, sh * 0.35f);
		}

		// Subtle vertical end-joint seam + tiny wooden peg dots
		float jDist = std::min(jointU, 1.0f - jointU);
		if (jDist < 0.012f) {
			col = LerpRGB(col, { 62, 38, 24 }, 0.72f);
		} else if (jDist > 0.025f && jDist < 0.055f) {
			float duPeg = jDist - 0.040f;
			float dvPeg1 = pv - 0.30f;
			float dvPeg2 = pv - 0.70f;
			if (duPeg * duPeg * 900.0f + dvPeg1 * dvPeg1 * 40.0f < 0.12f ||
				duPeg * duPeg * 900.0f + dvPeg2 * dvPeg2 * 40.0f < 0.12f) {
				col = LerpRGB(col, { 72, 46, 28 }, 0.65f);
			}
		}
		return col;
	});

	// Hand-painted chiseled ashlar stone masonry with mortar & subtle moss (512x512 seamless)
	ok &= WriteBMP24(texDir + "/tex_stone.bmp", 512, 512, [&](float u, float v, int, int) -> RGB {
		const float rows = 4.0f;
		const float cols = 3.0f;
		float rv = std::fmod(v * rows, 1.0f);
		int rIdx = static_cast<int>(std::floor(v * rows));
		float uShift = u * cols + ((rIdx % 2) ? 0.5f : 0.0f);
		float cu = std::fmod(uShift, 1.0f);
		int cIdx = static_cast<int>(std::floor(uShift)) % static_cast<int>(cols);

		float blockTone = Hash2D(cIdx, rIdx, 905);
		float n1 = TileNoise(u, v, 12.0f, 12.0f, 909);
		float n2 = TileNoise(u, v, 32.0f, 32.0f, 910);
		float pit = TileNoise(u, v, 48.0f, 48.0f, 913);

		RGB darkStone  = { 108, 110, 114 };
		RGB midStone   = { 150, 150, 146 };
		RGB lightStone = { 188, 185, 176 };
		float t = std::clamp(0.45f * n1 + 0.25f * n2 + 0.30f * blockTone - (pit > 0.78f ? 0.16f : 0.0f), 0.0f, 1.0f);
		RGB col = (t < 0.5f)
			? LerpRGB(darkStone, midStone, t * 2.0f)
			: LerpRGB(midStone, lightStone, (t - 0.5f) * 2.0f);

		// Chisel bevel highlights (top & left edges) + shadow bevels (bottom & right)
		float edgeX = std::min(cu, 1.0f - cu);
		float edgeY = std::min(rv, 1.0f - rv);
		float mortarW = 0.042f;
		float mortarH = 0.058f;
		if (edgeX < mortarW || edgeY < mortarH) {
			col = LerpRGB({ 68, 70, 76 }, { 84, 86, 88 }, n2);
			// Subtle matcha moss tucked into select mortar crevices
			float mossN = TileNoise(u, v, 8.0f, 8.0f, 919);
			if (mossN > 0.62f) {
				col = LerpRGB(col, { 98, 126, 62 }, (mossN - 0.62f) * 2.1f);
			}
		} else {
			if (rv > 0.84f || cu < 0.10f) {
				col = LerpRGB(col, { 216, 212, 200 }, 0.38f);
			} else if (rv < 0.14f || cu > 0.90f) {
				col = LerpRGB(col, { 84, 86, 92 }, 0.36f);
			}
		}
		return col;
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

	// 5. Tekstur Arena 2.5D Bamboo-Onsen & Musuh Crocodile Raider (Hand-Painted Studio Quality, Seamless)
	auto TileNoise2 = [](float u, float v, float freqX, float freqY, uint32_t seed) -> float {
		int px = std::max(1, static_cast<int>(std::round(freqX)));
		int py = std::max(1, static_cast<int>(std::round(freqY)));
		float x = u * px;
		float y = v * py;
		int ix = static_cast<int>(std::floor(x));
		int iy = static_cast<int>(std::floor(y));
		float fx = x - ix;
		float fy = y - iy;
		fx = fx * fx * (3.0f - 2.0f * fx);
		fy = fy * fy * (3.0f - 2.0f * fy);
		int x0 = ((ix % px) + px) % px;
		int x1 = (x0 + 1) % px;
		int y0 = ((iy % py) + py) % py;
		int y1 = (y0 + 1) % py;
		float a = Hash2D(x0, y0, seed);
		float b = Hash2D(x1, y0, seed);
		float c = Hash2D(x0, y1, seed);
		float d = Hash2D(x1, y1, seed);
		return (a + (b - a) * fx) + ((c + (d - c) * fx) - (a + (b - a) * fx)) * fy;
	};

	ok &= WriteBMP24(texDir + "/tex_croco_green.bmp", 256, 256, [&](float u, float v, int, int) -> RGB {
		// Painted jade-olive reptile scales/scutes (pops cleanly against warm matcha bamboo/moss)
		const float sCols = 10.0f;
		const float sRows = 12.0f;
		float rv = std::fmod(v * sRows, 1.0f);
		int rIdx = static_cast<int>(std::floor(v * sRows));
		float cu = std::fmod(u * sCols + ((rIdx % 2) ? 0.5f : 0.0f), 1.0f);
		float dx = (cu - 0.5f) * 2.0f;
		float dy = (rv - 0.5f) * 2.0f;
		float scDist = std::sqrt(dx * dx * 0.85f + dy * dy);
		float scaleDome = std::clamp(1.0f - scDist * 0.88f, 0.0f, 1.0f);

		float broad = TileNoise2(u, v, 5.0f, 5.0f, 1901);
		float blotch = TileNoise2(u, v, 14.0f, 12.0f, 1902);
		float t = std::clamp(0.46f * broad + 0.24f * blotch + 0.30f * scaleDome, 0.0f, 1.0f);
		RGB col = (t < 0.5f)
			? LerpRGB({ 44, 92, 54 }, { 76, 134, 72 }, t * 2.0f)
			: LerpRGB({ 76, 134, 72 }, { 124, 174, 96 }, (t - 0.5f) * 2.0f);
		// Subtle warm top rim on each scale facet + deep scale seam
		if (scDist > 0.88f) col = LerpRGB(col, { 32, 66, 42 }, 0.42f);
		else if (dy > 0.15f && scDist < 0.72f) col = LerpRGB(col, { 154, 196, 114 }, 0.20f);
		return LerpRGB(col, { 138, 182, 102 }, 0.12f * std::sin(v * 3.14159f));
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
	ok &= WriteBMP24(texDir + "/tex_torii_red.bmp", 256, 256, [&](float u, float v, int, int) -> RGB {
		// Deep atmospheric Vermilion lacquer wood grain (calm #B6382C, no noisy flat streaks)
		float grain = TileNoise2(u, v, 24.0f, 4.0f, 1910);
		float broad = TileNoise2(u, v, 5.0f, 5.0f, 1912);
		RGB col = LerpRGB({ 124, 34, 28 }, { 188, 56, 42 }, 0.55f * grain + 0.25f * broad + 0.20f * v);
		float seam = std::fmod(u * 4.0f, 1.0f);
		if (seam < 0.04f) col = LerpRGB(col, { 78, 20, 18 }, 0.45f);
		return col;
	});
	ok &= WriteBMP24(texDir + "/tex_moss_top.bmp", 256, 256, [&](float u, float v, int, int) -> RGB {
		float broad = TileNoise2(u, v, 6.0f, 6.0f, 1920);
		float tuft = TileNoise2(u, v, 22.0f, 18.0f, 1921);
		RGB col = LerpRGB({ 68, 102, 46 }, { 116, 148, 66 }, 0.60f * broad + 0.40f * tuft);
		if (tuft > 0.72f) col = LerpRGB(col, { 164, 188, 92 }, (tuft - 0.72f) * 2.0f);
		return col;
	});
	// Warm stratified earthy cliff rock with chiseled strata ledges & organic moss lip (512x512 seamless)
	ok &= WriteBMP24(texDir + "/tex_cliff_rock.bmp", 512, 512, [&](float u, float v, int, int) -> RGB {
		float warp = TileNoise2(u, v, 4.0f, 6.0f, 1930) * 0.22f;
		float sv = std::fmod((v + warp) * 5.0f, 1.0f);
		int bandIdx = static_cast<int>(std::floor((v + warp) * 5.0f));
		float bandTone = Hash2D(bandIdx, 3, 1933);
		float facet = TileNoise2(u, v, 10.0f, 8.0f, 1931);
		float grain = TileNoise2(u, v, 28.0f, 24.0f, 1932);

		// Lifted warm earthy terracotta-umber & sandstone-slate (ZERO dark muddy void!)
		RGB crevice  = { 72, 56, 46 };
		RGB midRock  = { 118, 94, 76 };
		RGB litLedge = { 164, 136, 108 };
		float t = std::clamp(0.44f * facet + 0.24f * grain + 0.32f * bandTone, 0.0f, 1.0f);
		RGB col = (t < 0.5f)
			? LerpRGB(crevice, midRock, t * 2.0f)
			: LerpRGB(midRock, litLedge, (t - 0.5f) * 2.0f);

		// Crisp sedimentary ledge highlight & underside shadow seam
		if (sv < 0.08f) {
			col = LerpRGB(col, { 54, 40, 34 }, 0.62f);
		} else if (sv > 0.86f) {
			col = LerpRGB(col, { 190, 162, 128 }, 0.42f);
		}

		// Vertical chiseled rock fracture cracks
		float crackU = std::fmod(u * 4.0f + bandIdx * 0.37f + warp * 1.6f, 1.0f);
		if (crackU < 0.032f) {
			col = LerpRGB(col, { 52, 38, 32 }, 0.58f);
		}

		// Gentle organic scalloped moss lip along top edge
		float lip = 0.86f + (TileNoise2(u, v, 12.0f, 4.0f, 1939) - 0.5f) * 0.09f;
		if (v > lip) {
			float mt = std::clamp((v - lip) / 0.08f, 0.0f, 1.0f);
			col = LerpRGB(col, { 92, 124, 56 }, mt * 0.85f);
		}
		return col;
	});

	// 6. Tekstur Painterly Rovio (bebas noise kasar & bebas pucat!)
	ok &= WriteStylizedFurTexture(texDir + "/tex_capy_crimson.bmp", { 132, 16, 22 }, { 196, 26, 30 }, { 230, 52, 44 }, 2001);

	// Calm Ghibli matcha-olive meadow with layered grass & clover tufts (512x512 seamless, zero neon stretch!)
	ok &= WriteBMP24(texDir + "/tex_moss_painterly.bmp", 512, 512, [&](float u, float v, int, int) -> RGB {
		float broad = TileNoise2(u, v, 5.0f, 5.0f, 2010);
		float patch = TileNoise2(u, v, 12.0f, 12.0f, 2011);

		// Calm desaturated matcha-olive palette matching Home Screen hills
		RGB deepMoss  = { 66, 98, 48 };
		RGB midMoss   = { 104, 138, 62 };
		RGB warmOlive = { 148, 174, 84 };
		float baseT = std::clamp(0.62f * broad + 0.38f * patch, 0.0f, 1.0f);
		RGB col = (baseT < 0.55f)
			? LerpRGB(deepMoss, midMoss, baseT / 0.55f)
			: LerpRGB(midMoss, warmOlive, (baseT - 0.55f) / 0.45f);

		// Layered hand-painted grass tuft arcs on a staggered grid (breaks up any flat wash!)
		const float gCols = 12.0f;
		const float gRows = 12.0f;
		float gv = std::fmod(v * gRows, 1.0f);
		int rIdx = static_cast<int>(std::floor(v * gRows));
		float gu = std::fmod(u * gCols + ((rIdx % 2) ? 0.5f : 0.0f), 1.0f);
		int cIdx = static_cast<int>(std::floor(u * gCols + ((rIdx % 2) ? 0.5f : 0.0f))) % static_cast<int>(gCols);
		float cellRnd = Hash2D(cIdx, rIdx, 2022);
		float dx = gu - 0.5f;
		float dy = gv - 0.45f;
		// 3 curved grass blade strokes per tuft
		float blade1 = std::abs(dx - dy * 0.25f) + std::max(0.0f, std::abs(dy) - 0.26f) * 2.0f;
		float blade2 = std::abs((dx + 0.16f) + dy * 0.35f) + std::max(0.0f, std::abs(dy) - 0.22f) * 2.0f;
		float blade3 = std::abs((dx - 0.16f) - dy * 0.38f) + std::max(0.0f, std::abs(dy) - 0.22f) * 2.0f;
		float bladeD = std::min({ blade1, blade2, blade3 });
		if (cellRnd > 0.28f && bladeD < 0.075f) {
			float tip = std::clamp((gv - 0.20f) / 0.55f, 0.0f, 1.0f);
			RGB bladeCol = LerpRGB({ 58, 88, 42 }, { 174, 196, 102 }, tip);
			col = LerpRGB(col, bladeCol, (1.0f - bladeD / 0.075f) * 0.65f);
		}
		// Occasional tiny sunlit clover/wildflower fleck
		if (cellRnd > 0.88f && (dx * dx + dy * dy) < 0.022f) {
			col = LerpRGB(col, { 228, 218, 152 }, 0.55f);
		}
		return col;
	});

	// Crisp Japanese kawara curved slate roof tiles (256x256 seamless)
	ok &= WriteBMP24(texDir + "/tex_roof_tile.bmp", 256, 256, [&](float u, float v, int, int) -> RGB {
		const float cols = 8.0f;
		const float rows = 8.0f;
		float rv = std::fmod(v * rows, 1.0f);
		int rIdx = static_cast<int>(std::floor(v * rows));
		float cu = std::fmod(u * cols + ((rIdx % 2) ? 0.5f : 0.0f), 1.0f);
		float curve = std::sin(cu * 3.14159265f);
		float grain = TileNoise2(u, v, 16.0f, 16.0f, 2031);
		RGB col = LerpRGB({ 40, 48, 60 }, { 78, 90, 108 }, 0.58f * curve + 0.24f * rv + 0.18f * grain);
		// Curved bottom overlap shadow + sunlit upper-edge lip
		float archEdge = 0.14f + 0.08f * (1.0f - curve);
		if (rv < archEdge) {
			col = LerpRGB(col, { 22, 26, 36 }, 0.78f);
		} else if (rv < archEdge + 0.10f) {
			col = LerpRGB(col, { 114, 128, 148 }, 0.35f);
		}
		float seamX = std::min(cu, 1.0f - cu);
		if (seamX < 0.055f) col = LerpRGB(col, { 26, 30, 40 }, 0.65f);
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
