#include "home2d_painter.h"
#include "canvas2d_sdf.h"

#include <cmath>
#include <filesystem>
#include <iostream>
#include <vector>

namespace fs = std::filesystem;
using namespace c2d;

namespace {

constexpr float PI_F = 3.14159265359f;

// Helper: paint a glossy Rovio-style expressive eye (sclera, gradient iris, pupil, dual catchlights, optional half-lid)
void PaintExpressiveEye(
	Canvas2D& cv,
	const Vec2& pos,
	float rx, float ry,
	const Color4& irisTop,
	const Color4& irisBot,
	const Vec2& gazeOffset,
	bool halfLidded,
	float lidDropFrac,
	const Color4& lidCol,
	float tiltRad = 0.0f) {

	BBox box{ pos.x - rx - 8, pos.y - ry - 8, pos.x + rx + 8, pos.y + ry + 8 };

	// Soft eye-socket shading under sclera
	cv.PaintDropShadow(box, [&](const Vec2& p) { return sdEllipse(p, pos, rx, ry, tiltRad); },
		Vec2(0.0f, 2.5f), 4.5f, Color4(0.14f, 0.06f, 0.12f, 0.36f));

	// Sclera with top ambient occlusion shadow
	cv.FillSDF(box, [&](const Vec2& p) { return sdEllipse(p, pos, rx, ry, tiltRad); },
		[&](const Vec2& p, float) -> Color4 {
			float ny = clampf((p.y - (pos.y - ry)) / std::max(ry * 2.0f, 1.0f), 0.0f, 1.0f);
			Color4 sc = lerpColor(rgbHex(0xDCE4EE), rgbHex(0xFFFDF8), smoothstep(0.05f, 0.55f, ny));
			sc = lerpColor(sc, rgbHex(0xE8DFD8), smoothstep(0.75f, 1.0f, ny) * 0.45f);
			return sc;
		}, 1.2f);

	// Colored Iris + Pupil clipped inside sclera
	Vec2 iPos = pos + gazeOffset;
	float irx = rx * 0.62f;
	float iry = ry * 0.68f;
	cv.FillSDF(box,
		[&](const Vec2& p) {
			float dEye = sdEllipse(p, pos, rx - 0.8f, ry - 0.8f, tiltRad);
			float dIris = sdEllipse(p, iPos, irx, iry, tiltRad);
			return std::max(dEye, dIris);
		},
		[&](const Vec2& p, float dIris) -> Color4 {
			float ny = clampf((p.y - (iPos.y - iry)) / std::max(iry * 2.0f, 1.0f), 0.0f, 1.0f);
			Color4 col = lerpColor(irisTop, irisBot, ny);
			// Darker limbal ring around outer iris
			float ring = 1.0f - smoothstep(0.0f, 3.2f, -dIris);
			col = lerpColor(col, mulColor(irisTop, 0.42f), ring * 0.75f);
			// Crisp jet pupil
			float dPup = sdEllipse(p, iPos + Vec2(0.0f, 0.5f), irx * 0.56f, iry * 0.58f, tiltRad);
			float pupA = clampf(0.5f - dPup / 1.15f, 0.0f, 1.0f);
			col = lerpColor(col, rgbHex(0x160C12), pupA);
			return col;
		}, 1.1f);

	// Dual glossy white catchlights (gives authentic studio cartoon life!)
	Vec2 hi1 = iPos + Vec2(-irx * 0.34f, -iry * 0.34f);
	Vec2 hi2 = iPos + Vec2(irx * 0.32f, iry * 0.36f);
	float rHi1 = std::max(2.6f, rx * 0.24f);
	float rHi2 = std::max(1.5f, rx * 0.12f);
	cv.FillSDF(box, [&](const Vec2& p) { return std::min(sdCircle(p, hi1, rHi1), sdCircle(p, hi2, rHi2)); },
		[](const Vec2&, float) { return Color4(1.0f, 1.0f, 0.98f, 0.96f); }, 1.0f);

	// Optional heavy lazy/stoic upper eyelid (Yuzu Bomb & Heavy Onsen)
	if (halfLidded) {
		float lidY = pos.y - ry + ry * 2.0f * lidDropFrac;
		cv.FillSDF(box,
			[&](const Vec2& p) {
				float dEye = sdEllipse(p, pos, rx + 1.2f, ry + 1.2f, tiltRad);
				float dCut = p.y - (lidY + std::sin((p.x - pos.x) * 0.06f) * 2.5f);
				return std::max(dEye, dCut);
			},
			[&](const Vec2& p, float) -> Color4 {
				float ny = clampf((p.y - (pos.y - ry)) / std::max(ry * 1.4f, 1.0f), 0.0f, 1.0f);
				Color4 c = lerpColor(mulColor(lidCol, 1.12f), mulColor(lidCol, 0.72f), ny);
				return c;
			}, 1.1f);

		// Crisp dark lid crease line
		Vec2 l0(pos.x - rx * 1.02f, lidY - 1.5f);
		Vec2 l1(pos.x, lidY + 2.5f);
		Vec2 l2(pos.x + rx * 1.02f, lidY - 1.5f);
		cv.FillSDF(box,
			[&](const Vec2& p) { return sdQuadBezierStroke(p, l0, l1, l2, 2.2f, 2.2f, 10); },
			[](const Vec2&, float) { return rgbHex(0x241218); }, 1.1f);
	}
}

// Helper: Paint bold sculptural angry/expressive eyebrow with subtle sunlit top highlight
void PaintBrow(Canvas2D& cv, const Vec2& p0, const Vec2& p1, const Vec2& p2, float r0, float r1, const Color4& baseCol) {
	float minX = std::min({ p0.x, p1.x, p2.x }) - std::max(r0, r1) - 8;
	float maxX = std::max({ p0.x, p1.x, p2.x }) + std::max(r0, r1) + 8;
	float minY = std::min({ p0.y, p1.y, p2.y }) - std::max(r0, r1) - 8;
	float maxY = std::max({ p0.y, p1.y, p2.y }) + std::max(r0, r1) + 8;
	BBox box{ minX, minY, maxX, maxY };

	auto sdf = [&](const Vec2& p) { return sdQuadBezierStroke(p, p0, p1, p2, r0, r1, 14); };
	cv.PaintDropShadow(box, sdf, Vec2(0.0f, 4.0f), 5.0f, Color4(0.14f, 0.05f, 0.10f, 0.42f));
	cv.FillSDF(box, sdf, [&](const Vec2& p, float) -> Color4 {
		float t = clampf((p.y - minY) / std::max(maxY - minY, 1.0f), 0.0f, 1.0f);
		return lerpColor(mulColor(baseCol, 1.32f), mulColor(baseCol, 0.85f), t);
	}, 1.2f);
}

// Helper: Paint an anime red anger cross-vein mark
void PaintAngerMark(Canvas2D& cv, const Vec2& c, float sz) {
	BBox box{ c.x - sz * 1.4f, c.y - sz * 1.4f, c.x + sz * 1.4f, c.y + sz * 1.4f };
	auto sdf = [&](const Vec2& p) {
		float d = 1e9f;
		// 4 inward-curving corner brackets
		float s = sz;
		d = std::min(d, sdQuadBezierStroke(p, c + Vec2(-s, -s * 0.25f), c + Vec2(-s * 0.25f, -s * 0.25f), c + Vec2(-s * 0.25f, -s), 2.8f, 2.8f, 8));
		d = std::min(d, sdQuadBezierStroke(p, c + Vec2( s, -s * 0.25f), c + Vec2( s * 0.25f, -s * 0.25f), c + Vec2( s * 0.25f, -s), 2.8f, 2.8f, 8));
		d = std::min(d, sdQuadBezierStroke(p, c + Vec2(-s,  s * 0.25f), c + Vec2(-s * 0.25f,  s * 0.25f), c + Vec2(-s * 0.25f,  s), 2.8f, 2.8f, 8));
		d = std::min(d, sdQuadBezierStroke(p, c + Vec2( s,  s * 0.25f), c + Vec2( s * 0.25f,  s * 0.25f), c + Vec2( s * 0.25f,  s), 2.8f, 2.8f, 8));
		return d;
	};
	cv.PaintDropShadow(box, sdf, Vec2(1.0f, 2.0f), 3.0f, Color4(0.18f, 0.02f, 0.04f, 0.45f));
	cv.FillSDF(box, sdf, [](const Vec2&, float) { return rgbHex(0xEE2B2B); }, 1.1f);
}

// =========================================================================
// ENVIRONMENT LAYERS (Layers 00 .. 08)
// =========================================================================

void BuildLayer00_SkySun(const std::string& dir) {
	Canvas2D cv(1280, 720);
	// Anti-Slop Woodblock/Ghibli Daylight-Golden Sky (nol teal-oranye keruh khas AI!)
	Vec2 sunPos(640.0f, 395.0f);

	for (int y = 0; y < cv.h; ++y) {
		float ny = static_cast<float>(y) / static_cast<float>(cv.h - 1);
		Color4 skyCol;
		if (ny < 0.36f) {
			skyCol = lerpColor(rgbHex(0x5296BD), rgbHex(0x8DC0D2), smoothstep(0.0f, 0.36f, ny));
		} else if (ny < 0.68f) {
			skyCol = lerpColor(rgbHex(0x8DC0D2), rgbHex(0xE9D7AE), smoothstep(0.36f, 0.68f, ny));
		} else {
			skyCol = lerpColor(rgbHex(0xE9D7AE), rgbHex(0xF6E6BC), smoothstep(0.68f, 1.0f, ny));
		}

		for (int x = 0; x < cv.w; ++x) {
			Vec2 p(x + 0.5f, y + 0.5f);
			float dist = length(p - sunPos);
			// Pijar matahari washi hangat & bersih di lembah tengah (tanpa blob oranye radioaktif)
			float haloWide = std::exp(-(dist * dist) / (450.0f * 450.0f));
			float haloMid  = std::exp(-(dist * dist) / (240.0f * 240.0f));
			float haloCore = std::exp(-(dist * dist) / (120.0f * 120.0f));
			Color4 c = lerpColor(skyCol, rgbHex(0xF5D993), haloWide * 0.65f);
			c = lerpColor(c, rgbHex(0xFAF0CE), haloMid * 0.78f);
			c = lerpColor(c, rgbHex(0xFCF8E8), haloCore * 0.90f);
			c.a = 1.0f;
			cv.BlendPixelOver(x, y, c);
		}
	}

	// Inti cakram matahari washi-emas lembut
	BBox sunBox{ sunPos.x - 185, sunPos.y - 185, sunPos.x + 185, sunPos.y + 185 };
	cv.FillSDF(sunBox, [&](const Vec2& p) { return sdCircle(p, sunPos, 140.0f); },
		[&](const Vec2&, float d) -> Color4 {
			float t = clampf(-d / 140.0f, 0.0f, 1.0f);
			return lerpColor(rgbHex(0xF7DF9A), rgbHex(0xFDF9EB), smoothstep(0.0f, 0.65f, t));
		}, 24.0f);

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.04f, 0.015f, 0.010f, 1001);
	cv.SavePNG(dir + "/layer_00_sky_sun.png");
	std::cout << "  -> Exported home2d/layer_00_sky_sun.png (1280x720, anti-slop graded)\n";
}

void BuildLayer01_Sunburst(const std::string& dir) {
	Canvas2D cv(1280, 1280);
	Vec2 center(640.0f, 640.0f);

	// Pancaran sinar woodblock krem-madu tegas berhierarki (mengarahkan mata ke logo & MC)
	for (int y = 0; y < cv.h; ++y) {
		for (int x = 0; x < cv.w; ++x) {
			Vec2 d = Vec2(x + 0.5f, y + 0.5f) - center;
			float r = length(d);
			if (r > 638.0f) continue;
			float ang = std::atan2(d.y, d.x);

			float w1 = 0.5f + 0.5f * std::cos(ang * 12.0f + 0.15f);
			float w2 = 0.5f + 0.5f * std::cos(ang * 24.0f - 0.40f);
			float rayMain = smoothstep(0.46f, 0.72f, w1);
			float rayFine = smoothstep(0.64f, 0.86f, w2) * 0.35f;
			float ray = clampf(rayMain + rayFine, 0.0f, 1.0f);

			float coreGlow = std::exp(-(r * r) / (185.0f * 185.0f));
			float radialFade = (1.0f - smoothstep(160.0f, 628.0f, r));
			float alpha = clampf(ray * radialFade * 0.44f + coreGlow * 0.55f, 0.0f, 0.84f);

			if (alpha > 0.003f) {
				Color4 c = lerpColor(rgbHex(0xF2D488), rgbHex(0xFCF7E6), clampf(coreGlow * 1.15f + (1.0f - r / 640.0f) * 0.45f, 0.0f, 1.0f));
				c.a = alpha;
				cv.BlendPixelOver(x, y, c);
			}
		}
	}
	cv.SavePNG(dir + "/layer_01_sunburst.png");
	std::cout << "  -> Exported home2d/layer_01_sunburst.png (1280x1280, anti-slop woodblock rays)\n";
}

void PaintPuffyCloud(Canvas2D& cv, const Vec2& c, float sc, int seed) {
	auto sdf = [&](const Vec2& p) {
		float d = sdEllipse(p, c + Vec2(0.0f, 6.0f * sc), 125.0f * sc, 44.0f * sc);
		d = smin(d, sdCircle(p, c + Vec2(-74.0f * sc,  6.0f * sc), 44.0f * sc), 18.0f * sc);
		d = smin(d, sdCircle(p, c + Vec2(-28.0f * sc, -26.0f * sc), 54.0f * sc), 20.0f * sc);
		d = smin(d, sdCircle(p, c + Vec2( 36.0f * sc, -18.0f * sc), 46.0f * sc), 18.0f * sc);
		d = smin(d, sdCircle(p, c + Vec2( 84.0f * sc,  8.0f * sc), 38.0f * sc), 16.0f * sc);
		float flatCut = (c.y + 34.0f * sc) - p.y;
		d = smax(d, -flatCut, 18.0f * sc);
		return d;
	};
	BBox box{ c.x - 165 * sc, c.y - 95 * sc, c.x + 165 * sc, c.y + 55 * sc };
	// Awan Ghibli gading cerah + bayangan bawah slate-lavender sejuk (nol awan oranye keruh AI!)
	VolumetricStyle st;
	st.topCol = rgbHex(0xFDF9EE);
	st.midCol = rgbHex(0xEFE5D4);
	st.botCol = rgbHex(0xB4BFC8);
	st.rimCol = rgbHex(0xFFFFFF);
	st.lightDir = normalize(Vec2(0.0f, -1.0f));
	st.rimWidth = 9.0f * sc;
	st.rimStrength = 0.58f;
	st.aoDepth = 20.0f * sc;
	st.aoStrength = 0.22f;
	st.specStrength = 0.10f;
	st.brushAmp = 0.040f;
	st.brushAngle = 0.05f;
	st.brushAlong = 42.0f;
	st.brushAcross = 14.0f;
	st.seed = seed;
	cv.PaintVolumetricSDF(box, sdf, st, 2.0f);
}

void BuildLayer02_Clouds(const std::string& dir) {
	Canvas2D cv(1280, 420);
	PaintPuffyCloud(cv, Vec2(280.0f, 175.0f), 1.05f, 301);
	PaintPuffyCloud(cv, Vec2(990.0f, 165.0f), 1.12f, 302);
	PaintPuffyCloud(cv, Vec2(645.0f, 108.0f), 0.72f, 303);
	cv.ApplyAntiSlopMasterGrade(0.92f, 0.04f, 0.012f, 0.009f, 1002);
	cv.SavePNG(dir + "/layer_02_clouds.png");
	std::cout << "  -> Exported home2d/layer_02_clouds.png (1280x420)\n";
}

void BuildLayer03_MountainsFar(const std::string& dir) {
	Canvas2D cv(1280, 720);

	// Back misty ridge (soft woodblock pine-slate)
	for (int x = 0; x < cv.w; ++x) {
		float fx = static_cast<float>(x) / 1280.0f;
		float hFar = 340.0f
			- 105.0f * std::exp(-std::pow((fx - 0.16f) / 0.22f, 2.0f))
			- 95.0f * std::exp(-std::pow((fx - 0.85f) / 0.24f, 2.0f))
			- 58.0f * std::exp(-std::pow((fx - 0.52f) / 0.28f, 2.0f))
			+ std::sin(fx * 24.0f) * 5.0f;
		for (int y = std::max(0, static_cast<int>(hFar) - 2); y < cv.h; ++y) {
			float d = hFar - (y + 0.5f);
			float a = clampf(0.5f - d / 2.2f, 0.0f, 1.0f);
			float depth = clampf((y - hFar) / 280.0f, 0.0f, 1.0f);
			Color4 c = lerpColor(rgbHex(0x69948A), rgbHex(0xA4BFB0), depth);
			float crest = 1.0f - smoothstep(0.0f, 14.0f, y - hFar);
			c = lerpColor(c, rgbHex(0xDDE4BE), crest * 0.28f);
			c.a = a;
			cv.BlendPixelOver(x, y, c);
		}
	}

	// Closer layered misty hills (natural botanical sage)
	for (int x = 0; x < cv.w; ++x) {
		float fx = static_cast<float>(x) / 1280.0f;
		float hMid = 435.0f
			- 145.0f * std::exp(-std::pow((fx - 0.08f) / 0.25f, 2.0f))
			- 135.0f * std::exp(-std::pow((fx - 0.90f) / 0.24f, 2.0f))
			- 35.0f * std::exp(-std::pow((fx - 0.45f) / 0.22f, 2.0f))
			+ (fbm2D(fx * 14.0f, 1.5f, 2, 55) - 0.5f) * 14.0f;
		for (int y = std::max(0, static_cast<int>(hMid) - 2); y < cv.h; ++y) {
			float d = hMid - (y + 0.5f);
			float a = clampf(0.5f - d / 2.0f, 0.0f, 1.0f);
			float depth = clampf((y - hMid) / 240.0f, 0.0f, 1.0f);
			Color4 c = lerpColor(rgbHex(0x4E7A61), rgbHex(0x7DA37E), depth);
			float crest = 1.0f - smoothstep(0.0f, 12.0f, y - hMid);
			c = lerpColor(c, rgbHex(0xC2D49C), crest * 0.30f);
			float bn = brushNoise(static_cast<float>(x), static_cast<float>(y), -0.4f, 45.0f, 12.0f, 99);
			c = mulColor(c, 1.0f + bn * 0.045f);
			c.a = a;
			cv.BlendPixelOver(x, y, c);
		}
	}

	// Soft warm parchment mist along lower valley
	for (int y = 390; y < 600; ++y) {
		float t = 1.0f - std::fabs((y - 495.0f) / 105.0f);
		float a = smoothstep(0.0f, 1.0f, t) * 0.20f;
		for (int x = 0; x < cv.w; ++x) {
			cv.BlendPixelOver(x, y, Color4(0.97f, 0.92f, 0.80f, a));
		}
	}

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.05f, 0.015f, 0.010f, 1003);
	cv.SavePNG(dir + "/layer_03_mountains_far.png");
	std::cout << "  -> Exported home2d/layer_03_mountains_far.png (1280x720)\n";
}

void BuildLayer04_MidgroundOnsen(const std::string& dir) {
	Canvas2D cv(1280, 720);

	// -----------------------------------------------------------------
	// A. LEFT: Japanese Onsen Bathhouse nestled on a mossy terrace
	// -----------------------------------------------------------------
	{
		Vec2 base(355.0f, 455.0f);

		// Supporting mossy hillside mound under the onsen house (botanical matcha)
		BBox mBox{ 140, 395, 570, 620 };
		VolumetricStyle mSt;
		mSt.topCol = rgbHex(0x6C9454);
		mSt.midCol = rgbHex(0x4A7044);
		mSt.botCol = rgbHex(0x2B4935);
		mSt.rimCol = rgbHex(0xB9CE7C);
		mSt.brushAmp = 0.06f;
		mSt.seed = 401;
		cv.PaintVolumetricSDF(mBox, [&](const Vec2& p) {
			return sdEllipse(p, Vec2(355.0f, 520.0f), 205.0f, 105.0f);
		}, mSt, 1.8f);

		// Stone masonry foundation
		BBox stoneBox{ base.x - 102, base.y - 26, base.x + 102, base.y + 12 };
		VolumetricStyle stStone;
		stStone.topCol = rgbHex(0xBAB4A6);
		stStone.midCol = rgbHex(0x8A847A);
		stStone.botCol = rgbHex(0x5A5652);
		stStone.rimCol = rgbHex(0xECE3CE);
		stStone.rimWidth = 4.0f;
		stStone.brushAmp = 0.08f;
		stStone.seed = 402;
		cv.PaintVolumetricSDF(stoneBox, [&](const Vec2& p) {
			return sdRoundBox(p, Vec2(base.x, base.y - 8.0f), 96.0f, 16.0f, 4.0f);
		}, stStone);

		// Aged Cedar Timber Main Wall (muted natural wood, no neon orange)
		BBox wallBox{ base.x - 94, base.y - 122, base.x + 94, base.y - 20 };
		VolumetricStyle stWood;
		stWood.topCol = rgbHex(0xBD7D4A);
		stWood.midCol = rgbHex(0x93562D);
		stWood.botCol = rgbHex(0x5C321C);
		stWood.rimCol = rgbHex(0xEAD09C);
		stWood.rimWidth = 5.0f;
		stWood.brushAmp = 0.09f;
		stWood.brushAngle = 0.0f;
		stWood.brushAlong = 36.0f;
		stWood.brushAcross = 4.0f;
		stWood.seed = 403;
		cv.PaintVolumetricSDF(wallBox, [&](const Vec2& p) {
			return sdRoundBox(p, Vec2(base.x, base.y - 72.0f), 88.0f, 50.0f, 3.0f);
		}, stWood);

		// Horizontal cedar plank seams & dark corner pillars
		for (int i = 0; i < 4; ++i) {
			float py = base.y - 106.0f + i * 24.0f;
			cv.FillSDF(BBox{ base.x - 86, py - 2, base.x + 86, py + 2 },
				[&](const Vec2& p) { return sdCapsule(p, Vec2(base.x - 85, py), Vec2(base.x + 85, py), 1.0f); },
				[](const Vec2&, float) { return Color4(0.32f, 0.14f, 0.08f, 0.32f); });
		}
		for (float px : { base.x - 82.0f, base.x + 82.0f, base.x - 38.0f, base.x + 38.0f }) {
			cv.FillSDF(BBox{ px - 8, base.y - 122, px + 8, base.y - 20 },
				[&](const Vec2& p) { return sdRoundBox(p, Vec2(px, base.y - 72.0f), 5.0f, 50.0f, 1.5f); },
				[](const Vec2&, float) { return rgbHex(0x592A16); });
		}

		// Warm Glowing Shoji Lattice Window (with soft golden lantern halo!)
		BBox winBox{ base.x - 36, base.y - 102, base.x + 36, base.y - 42 };
		cv.FillSDF(winBox.expanded(36.0f),
			[&](const Vec2& p) { return sdRoundBox(p, Vec2(base.x, base.y - 72.0f), 32.0f, 26.0f, 3.0f); },
			[&](const Vec2&, float d) {
				float glow = std::exp(-std::max(d, 0.0f) * 0.085f);
				return Color4(1.0f, 0.84f, 0.36f, glow * 0.36f);
			}, 34.0f, true);

		cv.FillSDF(winBox, [&](const Vec2& p) { return sdRoundBox(p, Vec2(base.x, base.y - 72.0f), 30.0f, 24.0f, 2.5f); },
			[&](const Vec2& p, float) {
				float r = length(p - Vec2(base.x, base.y - 72.0f)) / 42.0f;
				return lerpColor(rgbHex(0xFFF9C8), rgbHex(0xFFC444), clampf(r, 0.0f, 1.0f));
			});
		// Lattice bars
		for (float gx : { base.x - 10.0f, base.x + 10.0f }) {
			cv.FillSDF(winBox, [&](const Vec2& p) { return sdCapsule(p, Vec2(gx, base.y - 96), Vec2(gx, base.y - 48), 1.6f); },
				[](const Vec2&, float) { return rgbHex(0x522814); });
		}
		for (float gy : { base.y - 80.0f, base.y - 64.0f }) {
			cv.FillSDF(winBox, [&](const Vec2& p) { return sdCapsule(p, Vec2(base.x - 30, gy), Vec2(base.x + 30, gy), 1.6f); },
				[](const Vec2&, float) { return rgbHex(0x522814); });
		}

		// Curved Upturned Japanese Charcoal Tiled Roof (Irimoya silhouette via Bezier polygon!)
		std::vector<Vec2> roofPts;
		roofPts.push_back(Vec2(base.x - 126.0f, base.y - 114.0f));
		AppendQuadBezierPts(roofPts, Vec2(base.x - 126.0f, base.y - 114.0f), Vec2(base.x - 90.0f, base.y - 126.0f), Vec2(base.x - 74.0f, base.y - 172.0f), 10);
		roofPts.push_back(Vec2(base.x + 74.0f, base.y - 172.0f));
		AppendQuadBezierPts(roofPts, Vec2(base.x + 74.0f, base.y - 172.0f), Vec2(base.x + 90.0f, base.y - 126.0f), Vec2(base.x + 126.0f, base.y - 114.0f), 10);
		AppendQuadBezierPts(roofPts, Vec2(base.x + 126.0f, base.y - 114.0f), Vec2(base.x, base.y - 106.0f), Vec2(base.x - 126.0f, base.y - 114.0f), 10);

		BBox roofBox{ base.x - 134, base.y - 184, base.x + 134, base.y - 102 };
		auto roofSdf = [&](const Vec2& p) { return sdPolygon(p, roofPts, 2.5f); };
		// Deep eaves cast shadow clipped strictly onto the cedar wall (clean against sky!)
		cv.FillSDF(BBox{ base.x - 88, base.y - 122, base.x + 88, base.y - 84 },
			[&](const Vec2& p) {
				float dWall = sdRoundBox(p, Vec2(base.x, base.y - 72.0f), 88.0f, 50.0f, 3.0f);
				float dShad = roofSdf(p - Vec2(0.0f, 12.0f));
				return std::max(dWall, dShad);
			},
			[](const Vec2&, float) { return Color4(0.14f, 0.06f, 0.12f, 0.44f); }, 6.5f);
		VolumetricStyle stRoof;
		stRoof.topCol = rgbHex(0x475A6E);
		stRoof.midCol = rgbHex(0x2D3B4D);
		stRoof.botCol = rgbHex(0x1B2330);
		stRoof.rimCol = rgbHex(0xFFE09E);
		stRoof.rimWidth = 6.0f;
		stRoof.rimStrength = 0.60f;
		stRoof.brushAmp = 0.06f;
		stRoof.seed = 404;
		cv.PaintVolumetricSDF(roofBox, roofSdf, stRoof);

		// Subtle vertical roof tile ribs
		for (int i = -6; i <= 6; ++i) {
			float rx = base.x + i * 16.0f;
			cv.FillSDF(roofBox,
				[&](const Vec2& p) {
					return std::max(roofSdf(p), sdCapsule(p, Vec2(rx * 0.85f + base.x * 0.15f, base.y - 168.0f), Vec2(rx * 1.10f - base.x * 0.10f, base.y - 114.0f), 1.4f));
				},
				[](const Vec2&, float) { return Color4(0.08f, 0.10f, 0.16f, 0.35f); });
		}
		// Golden ornate ridge beam cap
		cv.FillSDF(BBox{ base.x - 86, base.y - 182, base.x + 86, base.y - 162 },
			[&](const Vec2& p) { return sdRoundBox(p, Vec2(base.x, base.y - 172.0f), 78.0f, 5.5f, 3.0f); },
			[&](const Vec2& p, float) {
				float t = clampf((p.y - (base.y - 178.0f)) / 12.0f, 0.0f, 1.0f);
				return lerpColor(rgbHex(0xFFE080), rgbHex(0xB87A24), t);
			});
	}

	// -----------------------------------------------------------------
	// B. RIGHT: Rocky Bluff + Vermilion Torii Gate + Glowing Onsen Pool
	// -----------------------------------------------------------------
	{
		// Right mossy bluff (harmonized matcha-sage)
		BBox rbBox{ 800, 400, 1280, 680 };
		VolumetricStyle rbSt;
		rbSt.topCol = rgbHex(0x669254);
		rbSt.midCol = rgbHex(0x467046);
		rbSt.botCol = rgbHex(0x2A4B38);
		rbSt.rimCol = rgbHex(0xB8CE7F);
		rbSt.brushAmp = 0.06f;
		rbSt.seed = 410;
		cv.PaintVolumetricSDF(rbBox, [&](const Vec2& p) {
			return sdEllipse(p, Vec2(1070.0f, 550.0f), 240.0f, 130.0f);
		}, rbSt, 1.8f);

		// Atmospheric Vermilion Japanese Torii Gate (subtle distance mute so Chill Capi owns focal red!)
		Vec2 tc(1025.0f, 430.0f);
		VolumetricStyle stTorii;
		stTorii.topCol = rgbHex(0xDC5542);
		stTorii.midCol = rgbHex(0xBC3528);
		stTorii.botCol = rgbHex(0x751F1E);
		stTorii.rimCol = rgbHex(0xF2D49C);
		stTorii.rimWidth = 4.5f;
		stTorii.rimStrength = 0.50f;
		stTorii.brushAmp = 0.045f;
		stTorii.seed = 411;

		auto toriiSdf = [&](const Vec2& p) {
			// Two slightly inward-angled pillars
			float d = sdTaperedCapsule(p, tc + Vec2(-56, -112), tc + Vec2(-64, 22), 9.5f, 11.5f);
			d = std::min(d, sdTaperedCapsule(p, tc + Vec2( 56, -112), tc + Vec2( 64, 22), 9.5f, 11.5f));
			// Lower crossbar (nuki)
			d = std::min(d, sdRoundBox(p, tc + Vec2(0, -82), 82.0f, 7.5f, 2.5f));
			// Center vertical tablet strut
			d = std::min(d, sdRoundBox(p, tc + Vec2(0, -98), 8.5f, 14.0f, 2.0f));
			// Sweeping upturned upper lintel (kasagi)
			d = std::min(d, sdQuadBezierStroke(p, tc + Vec2(-98, -124), tc + Vec2(0, -108), tc + Vec2(98, -124), 9.0f, 9.0f, 16));
			return d;
		};
		BBox tBox{ tc.x - 115, tc.y - 142, tc.x + 115, tc.y + 34 };
		cv.PaintVolumetricSDF(tBox, toriiSdf, stTorii);

		// Dark slate cap on Torii top lintel & pillar bases
		cv.FillSDF(BBox{ tc.x - 114, tc.y - 140, tc.x + 114, tc.y - 108 },
			[&](const Vec2& p) { return sdQuadBezierStroke(p, tc + Vec2(-102, -130), tc + Vec2(0, -115), tc + Vec2(102, -130), 4.5f, 4.5f, 16); },
			[](const Vec2&, float) { return rgbHex(0x23242E); });
		for (float bx : { tc.x - 64.0f, tc.x + 64.0f }) {
			cv.FillSDF(BBox{ bx - 18, tc.y + 8, bx + 18, tc.y + 30 },
				[&](const Vec2& p) { return sdRoundBox(p, Vec2(bx, tc.y + 18.0f), 14.0f, 8.0f, 3.0f); },
				[](const Vec2&, float) { return rgbHex(0x282A33); });
		}

		// Glowing Turquoise Onsen Hot-Spring Pool in right midground
		Vec2 poolC(1045.0f, 558.0f);
		BBox poolBox{ 820, 490, 1275, 628 };
		cv.FillSDF(poolBox, [&](const Vec2& p) { return sdEllipse(p, poolC, 210.0f, 56.0f); },
			[&](const Vec2& p, float d) {
				float t = clampf(-d / 55.0f, 0.0f, 1.0f);
				Color4 c = lerpColor(rgbHex(0x4AB8A8), rgbHex(0x88F0DC), smoothstep(0.0f, 0.7f, t));
				// Soft painted water shimmer ripples
				float rip = std::sin((p.y - poolC.y) * 0.45f + std::sin(p.x * 0.04f) * 2.0f);
				if (rip > 0.72f) c = lerpColor(c, rgbHex(0xE0FFF8), (rip - 0.72f) * 1.4f);
				return c;
			}, 2.0f);

		// Smooth onsen boulders ringing the pool edge
		VolumetricStyle rockSt;
		rockSt.topCol = rgbHex(0xABA69D);
		rockSt.midCol = rgbHex(0x787674);
		rockSt.botCol = rgbHex(0x47484D);
		rockSt.rimCol = rgbHex(0xFFE6B0);
		rockSt.rimWidth = 4.5f;
		rockSt.brushAmp = 0.07f;
		const Vec2 rocks[] = { {845, 535}, {905, 514}, {1165, 518}, {1228, 540} };
		const float rockR[] = { 34.0f, 26.0f, 30.0f, 36.0f };
		for (int i = 0; i < 4; ++i) {
			rockSt.seed = 420 + i;
			BBox rkB{ rocks[i].x - rockR[i] - 8, rocks[i].y - rockR[i] - 8, rocks[i].x + rockR[i] + 8, rocks[i].y + rockR[i] + 8 };
			cv.PaintVolumetricSDF(rkB, [&](const Vec2& p) {
				return sdEllipse(p, rocks[i], rockR[i] * 1.15f, rockR[i] * 0.78f);
			}, rockSt);
		}
	}

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.06f, 0.015f, 0.010f, 1004);
	cv.SavePNG(dir + "/layer_04_midground_onsen.png");
	std::cout << "  -> Exported home2d/layer_04_midground_onsen.png (1280x720)\n";
}

void BuildLayer05_SteamWisps(const std::string& dir) {
	Canvas2D cv(440, 440);
	// Soft curly vertical steam ribbons rising gracefully
	const Vec2 starts[] = { {130, 380}, {225, 405}, {315, 375} };
	for (int i = 0; i < 3; ++i) {
		Vec2 p0 = starts[i];
		Vec2 p1 = p0 + Vec2((i % 2 == 0 ? -36.0f : 38.0f), -135.0f);
		Vec2 p2 = p0 + Vec2((i % 2 == 0 ?  24.0f : -26.0f), -285.0f);
		BBox box{ 20, 20, 420, 420 };
		cv.FillSDF(box,
			[&](const Vec2& p) { return sdQuadBezierRibbon(p, p0, p1, p2, 16.0f, 32.0f, 8.0f, 18); },
			[&](const Vec2& p, float d) {
				float vertFade = smoothstep(410.0f, 310.0f, p.y) * smoothstep(75.0f, 185.0f, p.y);
				float edgeSoft = smoothstep(0.0f, 26.0f, -d);
				return Color4(1.0f, 0.98f, 0.92f, edgeSoft * vertFade * 0.34f);
			}, 14.0f);
	}
	cv.SavePNG(dir + "/layer_05_steam_wisps.png");
	std::cout << "  -> Exported home2d/layer_05_steam_wisps.png (440x440)\n";
}

void BuildLayer06_SlingshotCliff(const std::string& dir) {
	Canvas2D cv(1280, 720);

	// Mossy sunlit left cliff ledge supporting the Trio Mini & Bamboo Slingshot (natural botanical olive-moss)
	BBox clBox{ -40, 400, 390, 720 };
	VolumetricStyle clSt;
	clSt.topCol = rgbHex(0x78A24E);
	clSt.midCol = rgbHex(0x4C7638);
	clSt.botCol = rgbHex(0x2A482A);
	clSt.rimCol = rgbHex(0xC6D87A);
	clSt.rimWidth = 10.0f;
	clSt.brushAmp = 0.075f;
	clSt.seed = 601;
	cv.PaintVolumetricSDF(clBox, [&](const Vec2& p) {
		float d = sdEllipse(p, Vec2(125.0f, 610.0f), 235.0f, 185.0f);
		d = smin(d, sdEllipse(p, Vec2(215.0f, 650.0f), 150.0f, 120.0f), 32.0f);
		return d;
	}, clSt, 2.0f);

	// Hand-painted Classic Bamboo Y-Slingshot perched on the left cliff (natural warm bamboo)
	Vec2 base(165.0f, 445.0f);
	Vec2 fork(160.0f, 342.0f);
	Vec2 tipL(112.0f, 214.0f);
	Vec2 tipR(218.0f, 210.0f);

	VolumetricStyle bamSt;
	bamSt.topCol = rgbHex(0xA4BE5E);
	bamSt.midCol = rgbHex(0x70923C);
	bamSt.botCol = rgbHex(0x415B25);
	bamSt.rimCol = rgbHex(0xE2EC9E);
	bamSt.rimWidth = 5.5f;
	bamSt.rimStrength = 0.65f;
	bamSt.specStrength = 0.25f;
	bamSt.brushAmp = 0.06f;
	bamSt.brushAngle = 1.45f;
	bamSt.seed = 602;

	// Back-right arm first (slightly deeper for 2.5D depth)
	BBox sBox{ 80, 185, 255, 470 };
	auto backArmSdf = [&](const Vec2& p) { return sdQuadBezierStroke(p, fork, Vec2(198, 285), tipR, 14.0f, 12.0f, 14); };
	cv.PaintVolumetricSDF(sBox, backArmSdf, bamSt);

	// Crimson rubber sling band (back strand)
	cv.FillSDF(sBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, tipR + Vec2(-4, 18), Vec2(158, 272), Vec2(118, 282), 5.0f, 4.5f, 12); },
		[](const Vec2&, float) { return rgbHex(0xB8201C); });

	// Leather pouch hanging slightly relaxed
	cv.FillSDF(sBox, [&](const Vec2& p) { return sdEllipse(p, Vec2(118, 284), 16.0f, 11.0f, -0.25f); },
		[](const Vec2&, float) { return rgbHex(0x5E301B); });

	// Main trunk + front-left arm
	auto frontSdf = [&](const Vec2& p) {
		float d1 = sdTaperedCapsule(p, base, fork, 19.0f, 16.5f);
		float d2 = sdQuadBezierStroke(p, fork, Vec2(132, 286), tipL, 15.0f, 12.5f, 14);
		return smin(d1, d2, 10.0f);
	};
	cv.PaintVolumetricSDF(sBox, frontSdf, bamSt);

	// Bamboo segment rings & golden twine wrap at fork
	const Vec2 rings[][2] = {
		{ Vec2(146, 405), Vec2(180, 402) },
		{ Vec2(118, 270), Vec2(146, 260) },
		{ Vec2(186, 264), Vec2(214, 272) }
	};
	for (auto& rg : rings) {
		cv.FillSDF(sBox, [&](const Vec2& p) { return sdCapsule(p, rg[0], rg[1], 2.5f); },
			[](const Vec2&, float) { return rgbHex(0x3B6418); });
	}
	// Golden rope binding around Y-junction (natural hemp)
	for (int i = 0; i < 4; ++i) {
		float yOff = -8.0f + i * 6.0f;
		cv.FillSDF(sBox, [&](const Vec2& p) { return sdCapsule(p, fork + Vec2(-18, yOff), fork + Vec2(18, yOff + 2.0f), 3.4f); },
			[](const Vec2&, float) { return rgbHex(0xD2A048); });
	}
	// Front vermilion elastic band
	cv.FillSDF(sBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, tipL + Vec2(4, 18), Vec2(115, 255), Vec2(118, 284), 5.5f, 5.0f, 12); },
		[](const Vec2&, float) { return rgbHex(0xC83A2E); });

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.06f, 0.015f, 0.010f, 1006);
	cv.SavePNG(dir + "/layer_06_slingshot_cliff.png");
	std::cout << "  -> Exported home2d/layer_06_slingshot_cliff.png (1280x720)\n";
}

void BuildLayer07_ForegroundHill(const std::string& dir) {
	Canvas2D cv(1280, 420);

	// Rolling Ghibli meadow-moss hill (natural desaturated gouache green, ZERO neon acid green!)
	auto hillSdf = [&](const Vec2& p) {
		float fx = (p.x - 640.0f) / 720.0f;
		float crestY = 128.0f + fx * fx * 86.0f + std::sin(p.x * 0.0085f) * 14.0f;
		return crestY - p.y;
	};
	BBox hBox{ 0, 95, 1280, 420 };
	cv.FillSDF(hBox, hillSdf, [&](const Vec2& p, float d) -> Color4 {
		float depth = clampf(-d / 280.0f, 0.0f, 1.0f);
		Color4 c = lerpColor(rgbHex(0x749F4A), rgbHex(0x3F6A36), smoothstep(0.0f, 0.85f, depth));
		c = lerpColor(c, rgbHex(0x284329), smoothstep(0.65f, 1.0f, depth));
		// Soft warm cream-olive sunlit crest
		float rim = 1.0f - smoothstep(0.0f, 18.0f, -d);
		c = lerpColor(c, rgbHex(0xC4D678), rim * 0.52f);
		float bn = brushNoise(p.x, p.y, -0.18f, 52.0f, 12.0f, 701);
		c = mulColor(c, 1.0f + bn * 0.07f);
		return c;
	}, 2.2f);

	// Painterly grass tufts along crest
	for (int i = 0; i < 28; ++i) {
		float gx = 32.0f + i * 45.5f + std::sin(i * 2.1f) * 14.0f;
		float fx = (gx - 640.0f) / 720.0f;
		float gy = 136.0f + fx * fx * 86.0f + std::sin(gx * 0.0085f) * 14.0f;
		float lean = ((i % 2 == 0) ? 1.0f : -1.0f) * (10.0f + (i % 3) * 5.0f);
		float hBlade = 22.0f + (i % 4) * 8.0f;
		BBox gb{ gx - 30, gy - hBlade - 10, gx + 30, gy + 14 };
		cv.FillSDF(gb,
			[&](const Vec2& p) { return sdQuadBezierStroke(p, Vec2(gx, gy + 6), Vec2(gx + lean * 0.4f, gy - hBlade * 0.5f), Vec2(gx + lean, gy - hBlade), 5.5f, 1.0f, 10); },
			[&](const Vec2& p, float) {
				float t = clampf((gy - p.y) / hBlade, 0.0f, 1.0f);
				return lerpColor(rgbHex(0x527B34), rgbHex(0xB4C86A), t);
			}, 1.2f);
	}

	// Grounding contact shadow ellipses under the squad
	const Vec2 shPos[] = { {640, 208}, {465, 194}, {825, 198}, {290, 224}, {1005, 226} };
	const float shRx[] = { 130.0f, 88.0f, 102.0f, 74.0f, 78.0f };
	for (int i = 0; i < 5; ++i) {
		BBox sb{ shPos[i].x - shRx[i] - 25, shPos[i].y - 38, shPos[i].x + shRx[i] + 25, shPos[i].y + 38 };
		cv.FillSDF(sb, [&](const Vec2& p) { return sdEllipse(p, shPos[i], shRx[i], 20.0f); },
			[&](const Vec2&, float d) {
				float fall = clampf(1.0f - (d + 16.0f) / 36.0f, 0.0f, 1.0f);
				return Color4(0.12f, 0.20f, 0.14f, fall * 0.36f);
			}, 18.0f);
	}

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.06f, 0.015f, 0.011f, 1007);
	cv.SavePNG(dir + "/layer_07_foreground_hill.png");
	std::cout << "  -> Exported home2d/layer_07_foreground_hill.png (1280x420)\n";
}

void PaintBambooLeaf(Canvas2D& cv, const Vec2& root, float angRad, float len, float wid, const Color4& topC, const Color4& botC) {
	Vec2 dir(std::cos(angRad), std::sin(angRad));
	Vec2 perp(-dir.y, dir.x);
	Vec2 p0 = root;
	Vec2 p1 = root + dir * (len * 0.52f) + perp * (len * 0.14f);
	Vec2 p2 = root + dir * len;
	float minX = std::min({ p0.x, p1.x, p2.x }) - wid - 6;
	float maxX = std::max({ p0.x, p1.x, p2.x }) + wid + 6;
	float minY = std::min({ p0.y, p1.y, p2.y }) - wid - 6;
	float maxY = std::max({ p0.y, p1.y, p2.y }) + wid + 6;
	BBox box{ minX, minY, maxX, maxY };
	cv.FillSDF(box,
		[&](const Vec2& p) { return sdQuadBezierRibbon(p, p0, p1, p2, 1.5f, wid, 0.6f, 12); },
		[&](const Vec2& p, float) {
			float t = clampf(dot(p - p0, dir) / std::max(len, 1.0f), 0.0f, 1.0f);
			return lerpColor(botC, topC, t);
		}, 1.2f);
}

void PaintBambooStalk(Canvas2D& cv, const Vec2& p0, const Vec2& p1, const Vec2& p2, float radius, int seed) {
	float minX = std::min({ p0.x, p1.x, p2.x }) - radius - 14;
	float maxX = std::max({ p0.x, p1.x, p2.x }) + radius + 14;
	float minY = std::min({ p0.y, p1.y, p2.y }) - radius - 14;
	float maxY = std::max({ p0.y, p1.y, p2.y }) + radius + 14;
	BBox box{ minX, minY, maxX, maxY };

	VolumetricStyle st;
	st.topCol = rgbHex(0x9ABA5A);
	st.midCol = rgbHex(0x638838);
	st.botCol = rgbHex(0x345124);
	st.rimCol = rgbHex(0xDCE89A);
	st.lightDir = normalize(Vec2(p0.x < 640 ? 0.85f : -0.85f, -0.45f));
	st.rimWidth = 6.0f;
	st.rimStrength = 0.62f;
	st.specStrength = 0.20f;
	st.brushAmp = 0.055f;
	st.brushAngle = 1.52f;
	st.seed = seed;

	cv.PaintVolumetricSDF(box, [&](const Vec2& p) {
		return sdQuadBezierStroke(p, p0, p1, p2, radius * 1.12f, radius * 0.84f, 18);
	}, st);

	// Crisp bamboo segment nodes
	for (int k = 1; k <= 5; ++k) {
		float t = k / 6.0f;
		float u = 1.0f - t;
		Vec2 pt = p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
		Vec2 tan = normalize((p1 - p0) * (2 * u) + (p2 - p1) * (2 * t));
		Vec2 perp(-tan.y, tan.x);
		float r = lerpf(radius * 1.16f, radius * 0.88f, t);
		cv.FillSDF(BBox{ pt.x - r - 6, pt.y - r - 6, pt.x + r + 6, pt.y + r + 6 },
			[&](const Vec2& p) { return sdCapsule(p, pt - perp * r, pt + perp * r, 2.4f); },
			[](const Vec2&, float) { return rgbHex(0x2F4C1E); });
		cv.FillSDF(BBox{ pt.x - r - 6, pt.y - r - 6, pt.x + r + 6, pt.y + r + 6 },
			[&](const Vec2& p) { return sdCapsule(p, pt - perp * (r * 0.9f) + Vec2(0, -3.5f), pt + perp * (r * 0.9f) + Vec2(0, -3.5f), 1.6f); },
			[](const Vec2&, float) { return Color4(0.84f, 0.92f, 0.60f, 0.50f); });
	}
}

void BuildLayer08_BambooFrame(const std::string& dir) {
	Canvas2D cv(1280, 720);

	// Left framing bamboo stalks
	PaintBambooStalk(cv, Vec2(28, 740), Vec2(46, 360), Vec2(16, -20), 20.0f, 801);
	PaintBambooStalk(cv, Vec2(82, 740), Vec2(98, 410), Vec2(128, -20), 14.0f, 802);
	// Right framing bamboo stalks
	PaintBambooStalk(cv, Vec2(1248, 740), Vec2(1232, 360), Vec2(1262, -20), 21.0f, 803);
	PaintBambooStalk(cv, Vec2(1188, 740), Vec2(1176, 400), Vec2(1144, -20), 14.5f, 804);

	// Botanical olive-jade bamboo leaf fans
	PaintBambooLeaf(cv, Vec2(36, 130),  0.32f, 120, 14, rgbHex(0xA4C45E), rgbHex(0x4C742E));
	PaintBambooLeaf(cv, Vec2(36, 130), -0.18f, 105, 12, rgbHex(0xBCD472), rgbHex(0x588234));
	PaintBambooLeaf(cv, Vec2(94, 240),  0.55f, 110, 12, rgbHex(0x92B652), rgbHex(0x416828));
	PaintBambooLeaf(cv, Vec2(94, 240),  0.08f,  95, 11, rgbHex(0xB2CE6A), rgbHex(0x4E7830));
	PaintBambooLeaf(cv, Vec2(34, 415),  0.42f, 100, 12, rgbHex(0x8BB04C), rgbHex(0x3D6426));

	PaintBambooLeaf(cv, Vec2(1238, 120), PI_F - 0.30f, 125, 14, rgbHex(0xA4C45E), rgbHex(0x4C742E));
	PaintBambooLeaf(cv, Vec2(1238, 120), PI_F + 0.18f, 102, 12, rgbHex(0xBCD472), rgbHex(0x588234));
	PaintBambooLeaf(cv, Vec2(1174, 265), PI_F - 0.52f, 112, 12, rgbHex(0x92B652), rgbHex(0x416828));
	PaintBambooLeaf(cv, Vec2(1174, 265), PI_F - 0.06f,  94, 11, rgbHex(0xB2CE6A), rgbHex(0x4E7830));
	PaintBambooLeaf(cv, Vec2(1240, 445), PI_F - 0.40f, 105, 12, rgbHex(0x8BB04C), rgbHex(0x3D6426));

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.06f, 0.015f, 0.010f, 1008);
	cv.SavePNG(dir + "/layer_08_bamboo_frame.png");
	std::cout << "  -> Exported home2d/layer_08_bamboo_frame.png (1280x720)\n";
}

// =========================================================================
// 7 INDIVIDUAL LAYERED 2D CAPYBARA CHARACTER SPRITES (Lineless Rovio 2D)
// =========================================================================

enum class MouthKind { Roar, Grumpy, SumoFang, Smirk, Serious, ExcitedGrin, Cheeky };

struct Capy2DSpec {
	std::string filename;
	int canvasSize = 560;
	bool facingRight = true; // true = faces right (3/4), false = faces left (3/4)
	float bodyRx = 148.0f;
	float bodyRy = 132.0f;
	float headRx = 112.0f;
	float headRy = 96.0f;
	Color4 furTop, furMid, furBot, rimCol;
	Color4 bellyTop, bellyBot;
	Color4 snoutTop, snoutMid, snoutBot;
	Color4 irisTop, irisBot;
	Color4 browCol;
	bool halfLidded = false;
	float lidDrop = 0.45f;
	bool cynicalBrow = false;
	bool flatSumoBrow = false;
	bool softCuteBrow = false;
	MouthKind mouth = MouthKind::Roar;
	int seed = 1000;
};

// Reusable rich organic lineless 2D capybara body + face renderer, with pre/post hooks for character accessories
void RenderCapybaraSprite(
	const std::string& outPath,
	const Capy2DSpec& sp,
	const std::function<void(Canvas2D&, Vec2, float)>& backAccessory,
	const std::function<void(Canvas2D&, Vec2, float)>& frontAccessory) {

	Canvas2D cv(sp.canvasSize, sp.canvasSize);
	const float dir = sp.facingRight ? 1.0f : -1.0f;
	const Vec2 ctr(sp.canvasSize * 0.5f, sp.canvasSize * 0.56f);

	// 0. Optional back accessories (flame plume behind head, scarf tails, katana sheath, speed streaks)
	if (backAccessory) backAccessory(cv, ctr, dir);

	// Helper coordinates relative to ctr
	Vec2 bodyC = ctr + Vec2(-dir * 16.0f, 34.0f);
	Vec2 headC = ctr + Vec2(dir * 26.0f, -44.0f);
	Vec2 earFar = headC + Vec2(dir * 66.0f, -72.0f);
	Vec2 earNear = headC + Vec2(-dir * 64.0f, -68.0f);
	Vec2 snoutC = headC + Vec2(dir * 66.0f, 24.0f);

	// 1. Far back paw & far ear (shaded slightly deeper for true 2.5D depth)
	{
		VolumetricStyle farSt;
		farSt.topCol = mulColor(sp.furMid, 0.92f);
		farSt.midCol = mulColor(sp.furBot, 1.05f);
		farSt.botCol = mulColor(sp.furBot, 0.72f);
		farSt.rimCol = sp.rimCol;
		farSt.rimWidth = 4.0f;
		farSt.rimStrength = 0.35f;
		farSt.brushAmp = 0.05f;
		farSt.seed = sp.seed + 1;

		Vec2 farPaw = bodyC + Vec2(dir * 82.0f, sp.bodyRy - 6.0f);
		cv.PaintVolumetricSDF(BBox{ farPaw.x - 44, farPaw.y - 40, farPaw.x + 44, farPaw.y + 40 },
			[&](const Vec2& p) { return sdEllipse(p, farPaw, 30.0f, 26.0f, dir * 0.15f); }, farSt);

		cv.PaintVolumetricSDF(BBox{ earFar.x - 42, earFar.y - 44, earFar.x + 42, earFar.y + 44 },
			[&](const Vec2& p) { return sdEllipse(p, earFar, 25.0f, 30.0f, dir * 0.32f); }, farSt);
	}

	// 2. Main Organic Smooth-Union Body + Head Silhouette (ZERO harsh disconnected circles!)
	auto bodySdf = [&](const Vec2& p) {
		float dBody = sdEllipse(p, bodyC, sp.bodyRx, sp.bodyRy, -dir * 0.08f);
		float dHead = sdEllipse(p, headC, sp.headRx, sp.headRy, dir * 0.06f);
		float dCheek = sdEllipse(p, headC + Vec2(-dir * 26.0f, 22.0f), sp.headRx * 0.62f, sp.headRy * 0.56f);
		float d = smin(dBody, dHead, 44.0f);
		d = smin(d, dCheek, 26.0f);
		return d;
	};
	BBox mainBox{ ctr.x - sp.bodyRx - 85, ctr.y - sp.headRy - 135, ctr.x + sp.bodyRx + 115, ctr.y + sp.bodyRy + 95 };

	VolumetricStyle furSt;
	furSt.topCol = sp.furTop;
	furSt.midCol = sp.furMid;
	furSt.botCol = sp.furBot;
	furSt.rimCol = sp.rimCol;
	furSt.lightDir = normalize(Vec2(-0.38f, -0.92f));
	furSt.rimWidth = 10.5f;
	furSt.rimStrength = 0.62f;
	furSt.specStrength = 0.18f;
	furSt.aoDepth = 26.0f;
	furSt.aoStrength = 0.36f;
	furSt.brushAmp = 0.082f;
	furSt.brushAngle = -dir * 0.38f;
	furSt.brushAlong = 28.0f;
	furSt.brushAcross = 6.5f;
	furSt.seed = sp.seed + 2;

	cv.PaintVolumetricSDF(mainBox, bodySdf, furSt, 1.4f);

	// 3. Soft Creamy Belly Patch clipped organically inside the main body silhouette
	{
		Vec2 belC = bodyC + Vec2(dir * 38.0f, sp.bodyRy * 0.30f);
		auto belSdf = [&](const Vec2& p) {
			return std::max(bodySdf(p) + 1.5f, sdEllipse(p, belC, sp.bodyRx * 0.66f, sp.bodyRy * 0.58f, -dir * 0.14f));
		};
		cv.FillSDF(mainBox, belSdf, [&](const Vec2& p, float) -> Color4 {
			float ny = clampf((p.y - (belC.y - sp.bodyRy * 0.5f)) / (sp.bodyRy * 1.05f), 0.0f, 1.0f);
			Color4 c = lerpColor(sp.bellyTop, sp.bellyBot, smoothstep(0.15f, 0.95f, ny));
			float bn = brushNoise(p.x, p.y, -dir * 0.25f, 24.0f, 7.0f, sp.seed + 3);
			return mulColor(c, 1.0f + bn * 0.04f);
		}, 2.2f);
	}

	// 4. Near Ear (with sunlit rim & warm inner ear hollow)
	{
		BBox earBox{ earNear.x - 45, earNear.y - 48, earNear.x + 45, earNear.y + 48 };
		auto earSdf = [&](const Vec2& p) { return sdEllipse(p, earNear, 27.0f, 33.0f, -dir * 0.32f); };
		cv.PaintDropShadow(earBox, earSdf, Vec2(dir * 3.0f, 6.0f), 6.0f, Color4(0.16f, 0.04f, 0.08f, 0.32f));
		cv.PaintVolumetricSDF(earBox, earSdf, furSt);
		cv.FillSDF(earBox, [&](const Vec2& p) { return sdEllipse(p, earNear + Vec2(dir * 3.0f, 3.0f), 14.0f, 19.0f, -dir * 0.32f); },
			[&](const Vec2& p, float) {
				float ny = clampf((p.y - (earNear.y - 16.0f)) / 32.0f, 0.0f, 1.0f);
				return lerpColor(mulColor(sp.furBot, 0.72f), mulColor(sp.snoutMid, 1.12f), ny);
			});
	}

	// 5. Two Chunky Stubby Front Paws with subtle grounding shadow
	{
		Vec2 paw1 = bodyC + Vec2(-dir * 52.0f, sp.bodyRy - 4.0f);
		Vec2 paw2 = bodyC + Vec2( dir * 32.0f, sp.bodyRy + 4.0f);
		for (Vec2 pw : { paw1, paw2 }) {
			BBox pb{ pw.x - 46, pw.y - 42, pw.x + 46, pw.y + 42 };
			auto pSdf = [&](const Vec2& p) { return sdEllipse(p, pw, 33.0f, 27.0f, -dir * 0.10f); };
			cv.PaintDropShadow(pb, pSdf, Vec2(0.0f, 5.0f), 6.5f, Color4(0.12f, 0.04f, 0.08f, 0.34f));
			cv.PaintVolumetricSDF(pb, pSdf, furSt);
		}
	}

	// 6. Iconic Sculpted Capybara Snout (plump rounded block extending cleanly in 3/4 view)
	{
		BBox snBox{ snoutC.x - 86, snoutC.y - 72, snoutC.x + 86, snoutC.y + 76 };
		auto snSdf = [&](const Vec2& p) {
			float d1 = sdRoundBox(p, snoutC, 58.0f, 44.0f, 30.0f, dir * 0.05f);
			float d2 = sdEllipse(p, snoutC + Vec2(dir * 16.0f, 8.0f), 46.0f, 36.0f);
			return smin(d1, d2, 18.0f);
		};
		// Cast shadow beneath snout onto chest
		cv.PaintDropShadow(snBox, snSdf, Vec2(-dir * 3.0f, 11.0f), 10.0f, Color4(0.14f, 0.05f, 0.08f, 0.38f));

		VolumetricStyle snSt;
		snSt.topCol = sp.snoutTop;
		snSt.midCol = sp.snoutMid;
		snSt.botCol = sp.snoutBot;
		snSt.rimCol = lerpColor(sp.snoutTop, sp.rimCol, 0.55f);
		snSt.rimWidth = 7.5f;
		snSt.rimStrength = 0.55f;
		snSt.specStrength = 0.24f;
		snSt.aoDepth = 18.0f;
		snSt.aoStrength = 0.36f;
		snSt.brushAmp = 0.055f;
		snSt.seed = sp.seed + 5;
		cv.PaintVolumetricSDF(snBox, snSdf, snSt);

		// Two slanted capybara nostrils
		Vec2 n1 = snoutC + Vec2(dir * 14.0f, -14.0f);
		Vec2 n2 = snoutC + Vec2(dir * 42.0f, -13.0f);
		cv.FillSDF(snBox, [&](const Vec2& p) {
			return std::min(sdEllipse(p, n1, 7.5f, 5.2f, dir * 0.42f), sdEllipse(p, n2, 6.2f, 4.6f, -dir * 0.35f));
		}, [](const Vec2&, float) { return rgbHex(0x1E0D09); });

		// Expressive Mouth per Character
		if (sp.mouth == MouthKind::Roar) {
			// Wide fierce roaring open mouth + bright pink tongue + crisp white fangs!
			Vec2 mc = snoutC + Vec2(dir * 14.0f, 20.0f);
			auto mSdf = [&](const Vec2& p) {
				float d = sdEllipse(p, mc, 36.0f, 22.0f, -dir * 0.06f);
				// Flat upper lip ridge for fierce angry snarl
				float topCut = (mc.y - 10.0f) - p.y;
				return smax(d, topCut, 8.0f);
			};
			cv.FillSDF(snBox, mSdf, [&](const Vec2& p, float) {
				float ny = clampf((p.y - (mc.y - 14.0f)) / 36.0f, 0.0f, 1.0f);
				return lerpColor(rgbHex(0x2A0810), rgbHex(0x52121E), ny);
			});
			// Curved pink tongue inside mouth
			cv.FillSDF(snBox, [&](const Vec2& p) {
				return std::max(mSdf(p), sdEllipse(p, mc + Vec2(dir * 4.0f, 14.0f), 22.0f, 11.0f));
			}, [&](const Vec2& p, float) {
				float ny = clampf((p.y - (mc.y + 4.0f)) / 18.0f, 0.0f, 1.0f);
				return lerpColor(rgbHex(0xFF7D92), rgbHex(0xD84460), ny);
			});
			// Twin sharp white fangs
			std::vector<Vec2> f1 = { mc + Vec2(-dir * 16, -12), mc + Vec2(-dir * 4, -12), mc + Vec2(-dir * 10, 4) };
			std::vector<Vec2> f2 = { mc + Vec2( dir * 16, -11), mc + Vec2( dir * 28, -11), mc + Vec2( dir * 23, 4) };
			cv.FillSDF(snBox, [&](const Vec2& p) { return std::min(sdPolygon(p, f1, 1.4f), sdPolygon(p, f2, 1.4f)); },
				[](const Vec2&, float) { return rgbHex(0xFFFDF8); });
		} else if (sp.mouth == MouthKind::Grumpy) {
			Vec2 m0 = snoutC + Vec2(-dir * 12, 22);
			Vec2 m1 = snoutC + Vec2( dir * 16, 12);
			Vec2 m2 = snoutC + Vec2( dir * 40, 24);
			cv.FillSDF(snBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, m0, m1, m2, 3.8f, 3.4f, 12); },
				[](const Vec2&, float) { return rgbHex(0x220E0A); });
		} else if (sp.mouth == MouthKind::SumoFang) {
			Vec2 m0 = snoutC + Vec2(-dir * 14, 18);
			Vec2 m1 = snoutC + Vec2( dir * 16, 13);
			Vec2 m2 = snoutC + Vec2( dir * 40, 20);
			cv.FillSDF(snBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, m0, m1, m2, 4.2f, 3.6f, 12); },
				[](const Vec2&, float) { return rgbHex(0x220E0A); });
			// Protruding stubborn lower fang
			std::vector<Vec2> fang = { snoutC + Vec2(dir * 20, 17), snoutC + Vec2(dir * 30, 18), snoutC + Vec2(dir * 26, 4) };
			cv.FillSDF(snBox, [&](const Vec2& p) { return sdPolygon(p, fang, 1.3f); },
				[](const Vec2&, float) { return rgbHex(0xFFFDF8); });
		} else if (sp.mouth == MouthKind::Smirk) {
			Vec2 m0 = snoutC + Vec2(-dir * 12, 22);
			Vec2 m1 = snoutC + Vec2( dir * 18, 22);
			Vec2 m2 = snoutC + Vec2( dir * 38, 10);
			cv.FillSDF(snBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, m0, m1, m2, 3.6f, 3.0f, 12); },
				[](const Vec2&, float) { return rgbHex(0x220E0A); });
		} else if (sp.mouth == MouthKind::Serious) {
			Vec2 m0 = snoutC + Vec2(-dir * 14, 19);
			Vec2 m1 = snoutC + Vec2( dir * 14, 15);
			Vec2 m2 = snoutC + Vec2( dir * 38, 18);
			cv.FillSDF(snBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, m0, m1, m2, 3.8f, 3.2f, 12); },
				[](const Vec2&, float) { return rgbHex(0x220E0A); });
		} else if (sp.mouth == MouthKind::ExcitedGrin) {
			Vec2 mc = snoutC + Vec2(dir * 14.0f, 18.0f);
			auto mSdf = [&](const Vec2& p) { return sdEllipse(p, mc, 30.0f, 16.0f, -dir * 0.12f); };
			cv.FillSDF(snBox, mSdf, [](const Vec2&, float) { return rgbHex(0x360C14); });
			cv.FillSDF(snBox, [&](const Vec2& p) { return std::max(mSdf(p), sdEllipse(p, mc + Vec2(dir * 2, 10), 18.0f, 9.0f)); },
				[](const Vec2&, float) { return rgbHex(0xFF7B90); });
			cv.FillSDF(snBox, [&](const Vec2& p) { return std::max(mSdf(p), sdRoundBox(p, mc + Vec2(0, -11), 24.0f, 5.0f, 2.0f)); },
				[](const Vec2&, float) { return rgbHex(0xFFFDF8); });
		} else {
			// Cheeky smile
			Vec2 m0 = snoutC + Vec2(-dir * 10, 14);
			Vec2 m1 = snoutC + Vec2( dir * 16, 28);
			Vec2 m2 = snoutC + Vec2( dir * 38, 14);
			cv.FillSDF(snBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, m0, m1, m2, 3.4f, 3.0f, 12); },
				[](const Vec2&, float) { return rgbHex(0x220E0A); });
		}
	}

	// 7. Expressive Eyes & Bold Sculpted Eyebrows
	Vec2 eyeNear = headC + Vec2(dir * 4.0f, -20.0f);
	Vec2 eyeFar = headC + Vec2(dir * 68.0f, -22.0f);
	PaintExpressiveEye(cv, eyeFar, 21.0f, 25.0f, sp.irisTop, sp.irisBot, Vec2(dir * 3.0f, 1.5f), sp.halfLidded, sp.lidDrop, sp.furMid, -dir * 0.08f);
	PaintExpressiveEye(cv, eyeNear, 26.0f, 29.0f, sp.irisTop, sp.irisBot, Vec2(dir * 5.0f, 1.5f), sp.halfLidded, sp.lidDrop, sp.furMid, -dir * 0.05f);

	if (sp.cynicalBrow) {
		// Seed-Blaster: cocky raised near brow + slanted far brow
		PaintBrow(cv, eyeNear + Vec2(-dir * 30, -24), eyeNear + Vec2(dir * 2, -40), eyeNear + Vec2(dir * 28, -24), 7.0f, 9.5f, sp.browCol);
		PaintBrow(cv, eyeFar + Vec2(-dir * 18, -22), eyeFar + Vec2(dir * 4, -27), eyeFar + Vec2(dir * 24, -34), 9.0f, 6.0f, sp.browCol);
	} else if (sp.flatSumoBrow) {
		// Heavy Onsen: thick heavy flat-angled sumo brows
		PaintBrow(cv, eyeNear + Vec2(-dir * 32, -26), eyeNear + Vec2(dir * 0, -24), eyeNear + Vec2(dir * 28, -16), 11.5f, 13.5f, sp.browCol);
		PaintBrow(cv, eyeFar + Vec2(-dir * 20, -16), eyeFar + Vec2(dir * 4, -24), eyeFar + Vec2(dir * 26, -28), 12.5f, 9.5f, sp.browCol);
	} else if (sp.softCuteBrow) {
		// Mini-Capi: playful cheeky slanted brows
		PaintBrow(cv, eyeNear + Vec2(-dir * 24, -32), eyeNear + Vec2(dir * 0, -34), eyeNear + Vec2(dir * 22, -22), 6.0f, 7.5f, sp.browCol);
		PaintBrow(cv, eyeFar + Vec2(-dir * 16, -22), eyeFar + Vec2(dir * 2, -32), eyeFar + Vec2(dir * 20, -30), 7.0f, 5.5f, sp.browCol);
	} else {
		// Iconic Angry Birds V-Brows (\ /) — thick fierce taper meeting toward bridge!
		PaintBrow(cv, eyeNear + Vec2(-dir * 34, -38), eyeNear + Vec2(dir * 2, -26), eyeNear + Vec2(dir * 30, -12), 10.5f, 14.5f, sp.browCol);
		PaintBrow(cv, eyeFar + Vec2(-dir * 22, -12), eyeFar + Vec2(dir * 4, -26), eyeFar + Vec2(dir * 28, -40), 13.5f, 9.0f, sp.browCol);
	}

	// 8. Optional Front Accessories (crown tufts, scarf collar, Yuzu fruit, straw hat, towel, katana slash!)
	if (frontAccessory) frontAccessory(cv, ctr, dir);

	cv.SavePNG(outPath);
	std::cout << "  -> Exported home2d/" << sp.filename << " (" << sp.canvasSize << "x" << sp.canvasSize << ")\n";
}

void BuildAll7CapybaraSprites(const std::string& dir) {
	// -----------------------------------------------------------------
	// 1. CHILL CAPI (MC Merah Crimson Mengaum — Hero Depan Tengah)
	// -----------------------------------------------------------------
	{
		Capy2DSpec sp;
		sp.filename = "char_01_chill_roar.png";
		sp.canvasSize = 620;
		sp.facingRight = true;
		sp.bodyRx = 158; sp.bodyRy = 138;
		sp.headRx = 118; sp.headRy = 100;
		sp.furTop = rgbHex(0xE82428);
		sp.furMid = rgbHex(0xBD141A);
		sp.furBot = rgbHex(0x6E0B18);
		sp.rimCol = rgbHex(0xFFD678);
		sp.bellyTop = rgbHex(0xFFF3DE);
		sp.bellyBot = rgbHex(0xDEC2A2);
		sp.snoutTop = rgbHex(0x7A422B);
		sp.snoutMid = rgbHex(0x522618);
		sp.snoutBot = rgbHex(0x2D120E);
		sp.irisTop = rgbHex(0xA41418);
		sp.irisBot = rgbHex(0xFF4232);
		sp.browCol = rgbHex(0x1E0D10);
		sp.mouth = MouthKind::Roar;
		sp.seed = 101;

		RenderCapybaraSprite(dir + "/" + sp.filename, sp, nullptr,
			[&](Canvas2D& cv, Vec2 ctr, float dir) {
				Vec2 headC = ctr + Vec2(dir * 26.0f, -44.0f);
				// Iconic 3-spike sweeping crimson crown hair tuft
				VolumetricStyle tfSt;
				tfSt.topCol = rgbHex(0xF83634);
				tfSt.midCol = rgbHex(0xC6161C);
				tfSt.botCol = rgbHex(0x780C18);
				tfSt.rimCol = rgbHex(0xFFE088);
				tfSt.rimWidth = 5.0f;
				tfSt.brushAmp = 0.06f;
				tfSt.seed = 111;
				BBox tBox{ headC.x - 90, headC.y - 185, headC.x + 85, headC.y - 55 };
				auto tuftSdf = [&](const Vec2& p) {
					float d = sdQuadBezierStroke(p, headC + Vec2(-18, -86), headC + Vec2(-12, -135), headC + Vec2(-42, -162), 20.0f, 3.0f, 12);
					d = smin(d, sdQuadBezierStroke(p, headC + Vec2(4, -90), headC + Vec2(16, -142), headC + Vec2(-4, -172), 22.0f, 3.0f, 12), 10.0f);
					d = smin(d, sdQuadBezierStroke(p, headC + Vec2(22, -88), headC + Vec2(44, -126), headC + Vec2(36, -150), 16.0f, 2.5f, 12), 10.0f);
					return d;
				};
				cv.PaintVolumetricSDF(tBox, tuftSdf, tfSt);

				// Golden-red collar band hugging upper neck/chest cleanly
				Vec2 c0 = ctr + Vec2(-96, 18);
				Vec2 c1 = ctr + Vec2(  8, 60);
				Vec2 c2 = ctr + Vec2( 96, 36);
				BBox cBox{ ctr.x - 118, ctr.y - 4, ctr.x + 118, ctr.y + 84 };
				auto colSdf = [&](const Vec2& p) { return sdQuadBezierStroke(p, c0, c1, c2, 9.5f, 8.5f, 14); };
				cv.PaintDropShadow(cBox, colSdf, Vec2(0, 5), 5.0f, Color4(0.18f, 0.02f, 0.06f, 0.36f));
				VolumetricStyle gSt;
				gSt.topCol = rgbHex(0xFFEE70);
				gSt.midCol = rgbHex(0xF5B622);
				gSt.botCol = rgbHex(0xA66212);
				gSt.rimCol = rgbHex(0xFFFDE0);
				gSt.rimWidth = 4.0f;
				cv.PaintVolumetricSDF(cBox, colSdf, gSt);
			});
	}

	// -----------------------------------------------------------------
	// 2. YUZU BOMB (Espresso Bulat + Buah Yuzu + Kobaran Api Menyala)
	// -----------------------------------------------------------------
	{
		Capy2DSpec sp;
		sp.filename = "char_02_yuzu_bomb.png";
		sp.canvasSize = 580;
		sp.facingRight = true;
		sp.bodyRx = 148; sp.bodyRy = 136;
		sp.headRx = 110; sp.headRy = 96;
		sp.furTop = rgbHex(0x744630);
		sp.furMid = rgbHex(0x4E2B1C);
		sp.furBot = rgbHex(0x281310);
		sp.rimCol = rgbHex(0xFFA648);
		sp.bellyTop = rgbHex(0xFFF1DA);
		sp.bellyBot = rgbHex(0xD8BC98);
		sp.snoutTop = rgbHex(0x5E3422);
		sp.snoutMid = rgbHex(0x3D1E14);
		sp.snoutBot = rgbHex(0x210F0B);
		sp.irisTop = rgbHex(0xC24808);
		sp.irisBot = rgbHex(0xFFA820);
		sp.browCol = rgbHex(0x180B0A);
		sp.halfLidded = true;
		sp.lidDrop = 0.46f;
		sp.mouth = MouthKind::Grumpy;
		sp.seed = 202;

		RenderCapybaraSprite(dir + "/" + sp.filename, sp,
			// Back: blazing multi-layered flame halo behind Yuzu fuse
			[&](Canvas2D& cv, Vec2 ctr, float) {
				Vec2 fBase = ctr + Vec2(28.0f, -182.0f);
				BBox fBox{ fBase.x - 110, fBase.y - 160, fBase.x + 115, fBase.y + 45 };
				// Soft additive fire glow
				cv.FillSDF(fBox, [&](const Vec2& p) { return sdEllipse(p, fBase + Vec2(6, -65), 68.0f, 88.0f); },
					[&](const Vec2&, float d) {
						float g = std::exp(-std::max(d, 0.0f) * 0.04f);
						return Color4(1.0f, 0.50f, 0.10f, g * 0.34f);
					}, 28.0f, true);
			},
			// Front: golden Yuzu citrus on head + braided fuse + fierce layered 2D flame tongues + anger mark
			[&](Canvas2D& cv, Vec2 ctr, float dir) {
				Vec2 headC = ctr + Vec2(dir * 26.0f, -44.0f);
				Vec2 yuzuC = headC + Vec2(4.0f, -108.0f);

				// Yuzu citrus fruit
				BBox yBox{ yuzuC.x - 56, yuzuC.y - 52, yuzuC.x + 56, yuzuC.y + 52 };
				auto ySdf = [&](const Vec2& p) { return sdEllipse(p, yuzuC, 42.0f, 38.0f); };
				cv.PaintDropShadow(yBox, ySdf, Vec2(0, 8), 7.0f, Color4(0.14f, 0.05f, 0.04f, 0.42f));
				VolumetricStyle ySt;
				ySt.topCol = rgbHex(0xFFF258);
				ySt.midCol = rgbHex(0xF6BE18);
				ySt.botCol = rgbHex(0xC27808);
				ySt.rimCol = rgbHex(0xFFFFCA);
				ySt.rimWidth = 6.0f;
				ySt.specStrength = 0.35f;
				ySt.brushAmp = 0.04f;
				cv.PaintVolumetricSDF(yBox, ySdf, ySt);

				// Sizzling braided fuse
				Vec2 fuseTip = yuzuC + Vec2(6.0f, -54.0f);
				cv.FillSDF(BBox{ yuzuC.x - 30, yuzuC.y - 72, yuzuC.x + 36, yuzuC.y - 22 },
					[&](const Vec2& p) { return sdQuadBezierStroke(p, yuzuC + Vec2(0, -34), yuzuC + Vec2(-8, -46), fuseTip, 5.5f, 4.5f, 10); },
					[](const Vec2&, float) { return rgbHex(0x6E482C); });

				// 3-layer sculpted painterly flame plume erupting from fuseTip!
				BBox flBox{ fuseTip.x - 95, fuseTip.y - 135, fuseTip.x + 105, fuseTip.y + 30 };
				// Outer crimson-orange tongues
				auto flameOuter = [&](const Vec2& p) {
					float d = sdQuadBezierRibbon(p, fuseTip + Vec2(0, 8), fuseTip + Vec2(-28, -48), fuseTip + Vec2(-6, -118), 24.0f, 36.0f, 2.0f, 16);
					d = smin(d, sdQuadBezierRibbon(p, fuseTip + Vec2(6, 4), fuseTip + Vec2(36, -34), fuseTip + Vec2(42, -88), 18.0f, 22.0f, 2.0f, 14), 10.0f);
					d = smin(d, sdQuadBezierRibbon(p, fuseTip + Vec2(-8, 4), fuseTip + Vec2(-48, -28), fuseTip + Vec2(-42, -74), 16.0f, 18.0f, 2.0f, 14), 10.0f);
					return d;
				};
				cv.FillSDF(flBox, flameOuter, [&](const Vec2& p, float) {
					float t = clampf((fuseTip.y - p.y) / 118.0f, 0.0f, 1.0f);
					return lerpColor(rgbHex(0xFF4212), rgbHex(0xFF9418), t);
				});
				// Inner golden-yellow flame core
				auto flameInner = [&](const Vec2& p) {
					return sdQuadBezierRibbon(p, fuseTip + Vec2(0, 6), fuseTip + Vec2(-12, -32), fuseTip + Vec2(2, -74), 15.0f, 22.0f, 2.0f, 14);
				};
				cv.FillSDF(flBox, flameInner, [&](const Vec2& p, float) {
					float t = clampf((fuseTip.y - p.y) / 76.0f, 0.0f, 1.0f);
					return lerpColor(rgbHex(0xFFF682), rgbHex(0xFFFFD8), 1.0f - t);
				});

				// Tiny red anger mark on temple
				PaintAngerMark(cv, headC + Vec2(-64.0f, -34.0f), 16.0f);
			});
	}

	// -----------------------------------------------------------------
	// 3. HEAVY ONSEN ("Merah Besar" — Titan Sumo Maroon + Handuk + Batu)
	// -----------------------------------------------------------------
	{
		Capy2DSpec sp;
		sp.filename = "char_03_heavy_onsen.png";
		sp.canvasSize = 620;
		sp.facingRight = false; // Stands on right shoulder looking toward center!
		sp.bodyRx = 176; sp.bodyRy = 152;
		sp.headRx = 122; sp.headRy = 104;
		sp.furTop = rgbHex(0xCF2E4E);
		sp.furMid = rgbHex(0x9E1938);
		sp.furBot = rgbHex(0x580C26);
		sp.rimCol = rgbHex(0xFFD292);
		sp.bellyTop = rgbHex(0xFFF4E4);
		sp.bellyBot = rgbHex(0xD8BEC2);
		sp.snoutTop = rgbHex(0x703D2C);
		sp.snoutMid = rgbHex(0x4D2419);
		sp.snoutBot = rgbHex(0x2A110E);
		sp.irisTop = rgbHex(0x3A1614);
		sp.irisBot = rgbHex(0x883824);
		sp.browCol = rgbHex(0x1C0C10);
		sp.halfLidded = true;
		sp.lidDrop = 0.50f;
		sp.flatSumoBrow = true;
		sp.mouth = MouthKind::SumoFang;
		sp.seed = 303;

		RenderCapybaraSprite(dir + "/" + sp.filename, sp, nullptr,
			[&](Canvas2D& cv, Vec2 ctr, float dir) {
				Vec2 headC = ctr + Vec2(dir * 26.0f, -44.0f);
				// Folded white Japanese onsen towel resting neatly on top of head
				Vec2 twC = headC + Vec2(-dir * 4.0f, -96.0f);
				BBox twBox{ twC.x - 86, twC.y - 44, twC.x + 86, twC.y + 44 };
				auto twSdf = [&](const Vec2& p) {
					float d = sdRoundBox(p, twC, 66.0f, 18.0f, 14.0f, -dir * 0.05f);
					// Soft draped towel corner on side
					d = smin(d, sdRoundBox(p, twC + Vec2(-dir * 48.0f, 14.0f), 18.0f, 14.0f, 8.0f, dir * 0.25f), 8.0f);
					return d;
				};
				cv.PaintDropShadow(twBox, twSdf, Vec2(0, 8), 7.0f, Color4(0.18f, 0.04f, 0.10f, 0.36f));
				VolumetricStyle twSt;
				twSt.topCol = rgbHex(0xFFFFFF);
				twSt.midCol = rgbHex(0xECE8E2);
				twSt.botCol = rgbHex(0xB8B4BE);
				twSt.rimCol = rgbHex(0xFFFDF0);
				twSt.rimWidth = 5.0f;
				twSt.brushAmp = 0.04f;
				cv.PaintVolumetricSDF(twBox, twSdf, twSt);

				// Smooth grey river pebble balanced atop towel
				Vec2 pbC = twC + Vec2(0.0f, -26.0f);
				BBox pbBox{ pbC.x - 48, pbC.y - 34, pbC.x + 48, pbC.y + 34 };
				auto pbSdf = [&](const Vec2& p) { return sdEllipse(p, pbC, 34.0f, 20.0f, dir * 0.06f); };
				cv.PaintDropShadow(pbBox, pbSdf, Vec2(0, 6), 5.0f, Color4(0.14f, 0.12f, 0.18f, 0.38f));
				VolumetricStyle pbSt;
				pbSt.topCol = rgbHex(0xD2D5DC);
				pbSt.midCol = rgbHex(0x989DA8);
				pbSt.botCol = rgbHex(0x5C606C);
				pbSt.rimCol = rgbHex(0xFFF6DC);
				pbSt.specStrength = 0.32f;
				cv.PaintVolumetricSDF(pbBox, pbSdf, pbSt);

				PaintAngerMark(cv, headC + Vec2(-dir * 72.0f, -26.0f), 16.0f);
			});
	}

	// -----------------------------------------------------------------
	// 4. SEED-BLASTER (Koboi Karamel Sinis + Topi Jerami + Blaster Kembar)
	// -----------------------------------------------------------------
	{
		Capy2DSpec sp;
		sp.filename = "char_04_seed_blaster.png";
		sp.canvasSize = 540;
		sp.facingRight = true;
		sp.bodyRx = 132; sp.bodyRy = 118;
		sp.headRx = 100; sp.headRy = 88;
		sp.furTop = rgbHex(0xF69632);
		sp.furMid = rgbHex(0xD86D1A);
		sp.furBot = rgbHex(0x883A12);
		sp.rimCol = rgbHex(0xFFE686);
		sp.bellyTop = rgbHex(0xFFF4DC);
		sp.bellyBot = rgbHex(0xE2C498);
		sp.snoutTop = rgbHex(0x6E3C24);
		sp.snoutMid = rgbHex(0x4A2315);
		sp.snoutBot = rgbHex(0x28110C);
		sp.irisTop = rgbHex(0xB85206);
		sp.irisBot = rgbHex(0xFFC828);
		sp.browCol = rgbHex(0x26100C);
		sp.cynicalBrow = true;
		sp.mouth = MouthKind::Smirk;
		sp.seed = 404;

		RenderCapybaraSprite(dir + "/" + sp.filename, sp, nullptr,
			[&](Canvas2D& cv, Vec2 ctr, float dir) {
				Vec2 headC = ctr + Vec2(dir * 26.0f, -44.0f);

				// Sleek silver-bamboo Twin Seed-Blaster slung across side
				Vec2 gunC = ctr + Vec2(-dir * 86.0f, 38.0f);
				BBox gBox{ gunC.x - 80, gunC.y - 54, gunC.x + 80, gunC.y + 54 };
				// Golden shoulder strap
				cv.FillSDF(BBox{ ctr.x - 135, ctr.y - 30, ctr.x + 40, ctr.y + 90 },
					[&](const Vec2& p) { return sdQuadBezierStroke(p, ctr + Vec2(-95, 22), ctr + Vec2(-45, 58), ctr + Vec2(12, 65), 7.5f, 7.0f, 12); },
					[](const Vec2&, float) { return rgbHex(0xE8A824); });
				VolumetricStyle gSt;
				gSt.topCol = rgbHex(0xD6DCE4);
				gSt.midCol = rgbHex(0x8D96A4);
				gSt.botCol = rgbHex(0x4E5462);
				gSt.rimCol = rgbHex(0xFFFFFF);
				gSt.specStrength = 0.36f;
				auto gSdf = [&](const Vec2& p) {
					float d = sdRoundBox(p, gunC, 54.0f, 16.0f, 8.0f, 0.24f);
					d = std::min(d, sdRoundBox(p, gunC + Vec2(-6, 16), 44.0f, 12.0f, 6.0f, 0.24f));
					return d;
				};
				cv.PaintDropShadow(gBox, gSdf, Vec2(4, 8), 6.0f, Color4(0.14f, 0.06f, 0.08f, 0.36f));
				cv.PaintVolumetricSDF(gBox, gSdf, gSt);

				// Woven Golden Straw Cowboy Hat
				Vec2 hatC = headC + Vec2(-dir * 6.0f, -84.0f);
				BBox hBox{ hatC.x - 130, hatC.y - 95, hatC.x + 130, hatC.y + 55 };
				auto brimSdf = [&](const Vec2& p) {
					return sdQuadBezierStroke(p, hatC + Vec2(-108, 12), hatC + Vec2(0, 26), hatC + Vec2(114, 4), 13.0f, 12.0f, 16);
				};
				auto crownSdf = [&](const Vec2& p) {
					float d = sdRoundBox(p, hatC + Vec2(0, -24), 56.0f, 34.0f, 20.0f, -0.06f);
					// Subtle cowboy crown dent at top center
					float dent = sdCircle(p, hatC + Vec2(2, -62), 20.0f);
					return smax(d, -dent, 10.0f);
				};
				cv.PaintDropShadow(hBox, brimSdf, Vec2(0, 12), 9.0f, Color4(0.18f, 0.06f, 0.04f, 0.42f));
				VolumetricStyle hatSt;
				hatSt.topCol = rgbHex(0xFFE468);
				hatSt.midCol = rgbHex(0xE89D24);
				hatSt.botCol = rgbHex(0x9E5812);
				hatSt.rimCol = rgbHex(0xFFFAC0);
				hatSt.rimWidth = 6.0f;
				hatSt.brushAmp = 0.075f;
				hatSt.brushAngle = 0.05f;
				hatSt.brushAlong = 28.0f;
				hatSt.brushAcross = 5.0f;
				hatSt.seed = 415;
				cv.PaintVolumetricSDF(hBox, crownSdf, hatSt);
				// Crimson cowboy hatband
				cv.FillSDF(hBox, [&](const Vec2& p) { return std::max(crownSdf(p), sdRoundBox(p, hatC + Vec2(0, 2), 62.0f, 8.5f, 3.0f, -0.06f)); },
					[](const Vec2&, float) { return rgbHex(0xCC2222); });
				cv.PaintVolumetricSDF(hBox, brimSdf, hatSt);
			});
	}

	// -----------------------------------------------------------------
	// 5. BAMBU-KATANA (Ronin Krem Emas + Pedang + Tebasan Sabit Cyan)
	// -----------------------------------------------------------------
	{
		Capy2DSpec sp;
		sp.filename = "char_05_bambu_katana.png";
		sp.canvasSize = 580;
		sp.facingRight = false; // Flanks bottom-right facing inward!
		sp.bodyRx = 132; sp.bodyRy = 118;
		sp.headRx = 102; sp.headRy = 88;
		sp.furTop = rgbHex(0xFFF2C8);
		sp.furMid = rgbHex(0xE6C682);
		sp.furBot = rgbHex(0xA6804A);
		sp.rimCol = rgbHex(0x9EF6FF);
		sp.bellyTop = rgbHex(0xFFFDF2);
		sp.bellyBot = rgbHex(0xE4D4B0);
		sp.snoutTop = rgbHex(0x703E26);
		sp.snoutMid = rgbHex(0x4D2516);
		sp.snoutBot = rgbHex(0x28120C);
		sp.irisTop = rgbHex(0x0E7A44);
		sp.irisBot = rgbHex(0x46E078);
		sp.browCol = rgbHex(0x1E1410);
		sp.mouth = MouthKind::Serious;
		sp.seed = 505;

		RenderCapybaraSprite(dir + "/" + sp.filename, sp, nullptr,
			[&](Canvas2D& cv, Vec2 ctr, float dir) {
				Vec2 headC = ctr + Vec2(dir * 26.0f, -44.0f);
				// Spiky golden anime ronin hair crest
				VolumetricStyle hrSt;
				hrSt.topCol = rgbHex(0xFFF078);
				hrSt.midCol = rgbHex(0xE8B426);
				hrSt.botCol = rgbHex(0xA86E14);
				hrSt.rimCol = rgbHex(0xFFFFD8);
				hrSt.rimWidth = 5.0f;
				hrSt.seed = 515;
				BBox hrBox{ headC.x - 105, headC.y - 148, headC.x + 105, headC.y - 44 };
				auto hrSdf = [&](const Vec2& p) {
					float d = sdQuadBezierStroke(p, headC + Vec2(-54, -76), headC + Vec2(-6, -118), headC + Vec2(56, -80), 24.0f, 18.0f, 12);
					d = smin(d, sdQuadBezierStroke(p, headC + Vec2(-34, -84), headC + Vec2(-56, -124), headC + Vec2(-84, -108), 18.0f, 4.0f, 12), 10.0f);
					d = smin(d, sdQuadBezierStroke(p, headC + Vec2(16, -88), headC + Vec2(54, -132), headC + Vec2(82, -110), 18.0f, 4.0f, 12), 10.0f);
					return d;
				};
				cv.PaintDropShadow(hrBox, hrSdf, Vec2(0, 7), 6.0f, Color4(0.24f, 0.14f, 0.06f, 0.32f));
				cv.PaintVolumetricSDF(hrBox, hrSdf, hrSt);

				// Gleaming Steel Katana Blade + Bamboo Hilt
				Vec2 hilt(ctr.x - 52.0f, ctr.y + 52.0f);
				Vec2 tip(ctr.x - 235.0f, ctr.y - 18.0f);
				BBox swBox{ 10, 120, 320, 460 };
				cv.FillSDF(swBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, hilt, Vec2(ctr.x - 145, ctr.y + 12), tip, 7.5f, 2.2f, 14); },
					[&](const Vec2& p, float) {
						float t = clampf((hilt.x - p.x) / 185.0f, 0.0f, 1.0f);
						return lerpColor(rgbHex(0xB8D2E8), rgbHex(0xF6FDFF), t);
					});
				// Golden tsuba guard + bamboo handle
				cv.FillSDF(swBox, [&](const Vec2& p) { return sdEllipse(p, hilt, 10.0f, 16.0f, 0.32f); },
					[](const Vec2&, float) { return rgbHex(0xF4BE2C); });
				cv.FillSDF(swBox, [&](const Vec2& p) { return sdCapsule(p, hilt, hilt + Vec2(36, 15), 6.5f); },
					[](const Vec2&, float) { return rgbHex(0x4E8E2A); });

				// Vibrant Luminous Cyan-Turquoise Crescent Katana Energy Slash!
				Vec2 s0(ctr.x - 255.0f, ctr.y - 42.0f);
				Vec2 s1(ctr.x - 210.0f, ctr.y + 84.0f);
				Vec2 s2(ctr.x - 62.0f,  ctr.y + 105.0f);
				BBox slBox{ 10, 180, 320, 480 };
				auto slSdf = [&](const Vec2& p) { return sdQuadBezierRibbon(p, s0, s1, s2, 2.5f, 22.0f, 1.5f, 18); };
				// Outer cyan glow aura
				cv.FillSDF(slBox.expanded(26), slSdf, [&](const Vec2&, float d) {
					float g = std::exp(-std::max(d, 0.0f) * 0.09f);
					return Color4(0.18f, 0.88f, 1.0f, g * 0.45f);
				}, 24.0f, true);
				// Crisp glowing slash body
				cv.FillSDF(slBox, slSdf, [&](const Vec2&, float d) {
					float core = clampf(-d / 14.0f, 0.0f, 1.0f);
					return lerpColor(rgbHex(0x1AC8FF), rgbHex(0xE8FFFF), smoothstep(0.25f, 0.95f, core));
				});
			});
	}

	// -----------------------------------------------------------------
	// 6. DASH CAPI (Sprinter Kuning Melesat di Langit Senja + Syal Merah)
	// -----------------------------------------------------------------
	{
		Capy2DSpec sp;
		sp.filename = "char_06_dash_leap.png";
		sp.canvasSize = 560;
		sp.facingRight = false; // Leaps dynamically toward center-left!
		sp.bodyRx = 136; sp.bodyRy = 104;
		sp.headRx = 98; sp.headRy = 86;
		sp.furTop = rgbHex(0xFFF048);
		sp.furMid = rgbHex(0xF6BA12);
		sp.furBot = rgbHex(0xB86E08);
		sp.rimCol = rgbHex(0xFFFFCA);
		sp.bellyTop = rgbHex(0xFFFDF0);
		sp.bellyBot = rgbHex(0xECD89C);
		sp.snoutTop = rgbHex(0x6E3C24);
		sp.snoutMid = rgbHex(0x4C2415);
		sp.snoutBot = rgbHex(0x28110C);
		sp.irisTop = rgbHex(0xB84606);
		sp.irisBot = rgbHex(0xFFA81A);
		sp.browCol = rgbHex(0x220E0A);
		sp.mouth = MouthKind::ExcitedGrin;
		sp.seed = 606;

		RenderCapybaraSprite(dir + "/" + sp.filename, sp,
			// Back: golden speed-streak trails + twin fluttering crimson scarf tails!
			[&](Canvas2D& cv, Vec2 ctr, float) {
				BBox spBox{ ctr.x - 40, ctr.y - 160, 550, ctr.y + 150 };
				// Golden aerodynamic speed streaks
				for (int i = 0; i < 3; ++i) {
					float dy = -48.0f + i * 52.0f;
					Vec2 a = ctr + Vec2(55, dy);
					Vec2 b = ctr + Vec2(165, dy - 18.0f);
					Vec2 c = ctr + Vec2(252 - i * 16.0f, dy - 38.0f);
					cv.FillSDF(spBox, [&](const Vec2& p) { return sdQuadBezierStroke(p, a, b, c, 12.0f, 1.5f, 14); },
						[&](const Vec2& p, float) {
							float t = clampf((p.x - a.x) / 200.0f, 0.0f, 1.0f);
							Color4 col = lerpColor(rgbHex(0xFFF680), rgbHex(0xFFA820), t);
							col.a = 1.0f - t * 0.72f;
							return col;
						});
				}
				// Twin fluttering crimson scarf tails
				VolumetricStyle scSt;
				scSt.topCol = rgbHex(0xFF3A34);
				scSt.midCol = rgbHex(0xD4181E);
				scSt.botCol = rgbHex(0x840C16);
				scSt.rimCol = rgbHex(0xFFE078);
				scSt.rimWidth = 4.0f;
				auto scarfSdf = [&](const Vec2& p) {
					float d1 = sdQuadBezierRibbon(p, ctr + Vec2(26, -70), ctr + Vec2(138, -118), ctr + Vec2(236, -98), 11.0f, 15.0f, 3.0f, 16);
					float d2 = sdQuadBezierRibbon(p, ctr + Vec2(32, -52), ctr + Vec2(142, -74), ctr + Vec2(226, -42), 10.0f, 13.0f, 2.5f, 16);
					return std::min(d1, d2);
				};
				cv.PaintVolumetricSDF(spBox, scarfSdf, scSt);
			},
			// Front: swept-back golden lightning tuft
			[&](Canvas2D& cv, Vec2 ctr, float dir) {
				Vec2 headC = ctr + Vec2(dir * 26.0f, -44.0f);
				VolumetricStyle tfSt;
				tfSt.topCol = rgbHex(0xFFF86E);
				tfSt.midCol = rgbHex(0xF6BA12);
				tfSt.botCol = rgbHex(0xB86E08);
				tfSt.rimCol = rgbHex(0xFFFFDE);
				tfSt.rimWidth = 4.5f;
				BBox tBox{ headC.x - 60, headC.y - 165, headC.x + 125, headC.y - 50 };
				auto tuftSdf = [&](const Vec2& p) {
					float d = sdQuadBezierStroke(p, headC + Vec2(-8, -80), headC + Vec2(34, -128), headC + Vec2(82, -142), 20.0f, 2.5f, 12);
					d = smin(d, sdQuadBezierStroke(p, headC + Vec2(12, -74), headC + Vec2(58, -104), headC + Vec2(98, -106), 16.0f, 2.0f, 12), 8.0f);
					return d;
				};
				cv.PaintVolumetricSDF(tBox, tuftSdf, tfSt);
			});
	}

	// -----------------------------------------------------------------
	// 7. TRIO MINI-CAPI (Bayi Kapibara Biru Langit Usil — Ditumpuk 3!)
	// -----------------------------------------------------------------
	{
		Capy2DSpec sp;
		sp.filename = "char_07_mini_capi.png";
		sp.canvasSize = 420;
		sp.facingRight = true;
		sp.bodyRx = 104; sp.bodyRy = 94;
		sp.headRx = 82; sp.headRy = 74;
		sp.furTop = rgbHex(0x52D6FF);
		sp.furMid = rgbHex(0x1E9EE8);
		sp.furBot = rgbHex(0x0E569E);
		sp.rimCol = rgbHex(0xD4F8FF);
		sp.bellyTop = rgbHex(0xF4FCFF);
		sp.bellyBot = rgbHex(0xBEDCF0);
		sp.snoutTop = rgbHex(0x6C3E2A);
		sp.snoutMid = rgbHex(0x4A2518);
		sp.snoutBot = rgbHex(0x28120D);
		sp.irisTop = rgbHex(0x0E4E88);
		sp.irisBot = rgbHex(0x36C8FF);
		sp.browCol = rgbHex(0x142034);
		sp.softCuteBrow = true;
		sp.mouth = MouthKind::Cheeky;
		sp.seed = 707;

		RenderCapybaraSprite(dir + "/" + sp.filename, sp, nullptr,
			[&](Canvas2D& cv, Vec2 ctr, float dir) {
				Vec2 headC = ctr + Vec2(dir * 26.0f, -44.0f);
				// Tiny adorable golden sprout tuft on top
				BBox tBox{ headC.x - 45, headC.y - 125, headC.x + 45, headC.y - 55 };
				VolumetricStyle gSt;
				gSt.topCol = rgbHex(0xFFF060);
				gSt.midCol = rgbHex(0xF0AE1A);
				gSt.botCol = rgbHex(0xAA660A);
				gSt.rimCol = rgbHex(0xFFFFD8);
				cv.PaintVolumetricSDF(tBox, [&](const Vec2& p) {
					float d = sdQuadBezierStroke(p, headC + Vec2(-4, -70), headC + Vec2(-14, -98), headC + Vec2(-28, -104), 10.0f, 2.0f, 10);
					d = smin(d, sdQuadBezierStroke(p, headC + Vec2(4, -70), headC + Vec2(16, -98), headC + Vec2(28, -100), 10.0f, 2.0f, 10), 6.0f);
					return d;
				}, gSt);
			});
	}
}

void HarmonizeExternal2DCapybaras(const std::string& dir) {
	// Harmonisasi seluruh cutout kapibara 2D kemarin dengan Master Anti-Slop LUT yang sama persis
	// dengan background Visual Studio C++ (angkat hitam spidol murni ke Warm Espresso #231917,
	// jinakkan saturasi berlebih AI, samakan suhu cahaya daylight-golden & tekstur kertas washi!)
	const std::pair<std::string, int> files[] = {
		{ "capi_2d_dash", 2001 },
		{ "capi_2d_trio_mini", 2002 },
		{ "capi_2d_squad_main", 2003 }
	};
	for (const auto& item : files) {
		std::string srcPath = dir + "/" + item.first + ".png";
		std::string dstPath = dir + "/" + item.first + "_graded.png";
		if (!fs::exists(srcPath)) continue;
		Canvas2D cv(1, 1);
		if (Canvas2D::LoadPNG(srcPath, cv)) {
			cv.ApplyAntiSlopMasterGrade(0.84f, 0.11f, 0.022f, 0.011f, item.second);
			if (cv.SavePNG(dstPath)) {
				std::cout << "  -> Harmonized (Anti-Slop LUT) home2d/" << item.first << "_graded.png (" << cv.w << "x" << cv.h << ")\n";
			}
		}
	}
}

// =========================================================================
// 4 FLOATING WORLD ISLAND ILLUSTRATIONS (400x400 RGBA — World Select Map)
// =========================================================================

void PaintFloatingIslandRock(
	Canvas2D& cv,
	const Color4& rockTop, const Color4& rockMid, const Color4& rockBot, const Color4& rockRim,
	const Color4& capTop, const Color4& capMid, const Color4& capBot, const Color4& capRim,
	int seed,
	bool drawPebbles = true) {

	// Tapered sculpted floating cliff underside
	std::vector<Vec2> rockPts = {
		{  74.0f, 224.0f },
		{ 126.0f, 216.0f },
		{ 274.0f, 216.0f },
		{ 326.0f, 224.0f },
		{ 312.0f, 266.0f },
		{ 278.0f, 306.0f },
		{ 244.0f, 326.0f },
		{ 204.0f, 354.0f },
		{ 166.0f, 328.0f },
		{ 128.0f, 304.0f },
		{  92.0f, 268.0f }
	};
	BBox rBox{ 56, 206, 344, 370 };
	VolumetricStyle rSt;
	rSt.topCol = rockTop;
	rSt.midCol = rockMid;
	rSt.botCol = rockBot;
	rSt.rimCol = rockRim;
	rSt.lightDir = normalize(Vec2(-0.45f, -0.89f));
	rSt.rimWidth = 7.0f;
	rSt.rimStrength = 0.42f;
	rSt.aoDepth = 24.0f;
	rSt.aoStrength = 0.36f;
	rSt.specStrength = 0.08f;
	rSt.brushAmp = 0.095f;
	rSt.brushAngle = 0.22f;
	rSt.brushAlong = 30.0f;
	rSt.brushAcross = 10.0f;
	rSt.seed = seed;
	cv.PaintVolumetricSDF(rBox, [&](const Vec2& p) { return sdPolygon(p, rockPts, 10.0f); }, rSt, 1.4f);

	// Subtle carved cliff facet shadow lines
	BBox fBox{ 90, 238, 310, 346 };
	cv.FillSDF(fBox, [&](const Vec2& p) {
		float d = sdQuadBezierStroke(p, Vec2(138, 244), Vec2(154, 282), Vec2(174, 320), 2.8f, 1.0f, 10);
		d = std::min(d, sdQuadBezierStroke(p, Vec2(256, 246), Vec2(242, 286), Vec2(218, 328), 2.8f, 1.0f, 10));
		d = std::min(d, sdQuadBezierStroke(p, Vec2(198, 250), Vec2(202, 294), Vec2(204, 336), 2.2f, 0.9f, 10));
		return d;
	}, [&](const Vec2&, float) { return Color4(rockBot.r * 0.65f, rockBot.g * 0.65f, rockBot.b * 0.65f, 0.48f); }, 1.2f);

	if (drawPebbles) {
		// Floating miniature rock shards drifting below the island
		auto paintShard = [&](Vec2 c, float rx, float ry, float rot) {
			BBox pb{ c.x - rx - 8, c.y - ry - 8, c.x + rx + 8, c.y + ry + 8 };
			cv.PaintVolumetricSDF(pb, [&](const Vec2& p) { return sdEllipse(p, c, rx, ry, rot); }, rSt, 1.2f);
		};
		paintShard(Vec2(124.0f, 356.0f), 14.0f, 8.5f, 0.25f);
		paintShard(Vec2(276.0f, 348.0f), 11.5f, 7.0f, -0.30f);
		paintShard(Vec2(236.0f, 368.0f), 7.5f, 5.0f, 0.15f);
	}

	// Lush plateau cap draped over the rock lip
	auto capSdf = [&](const Vec2& p) {
		float d = sdEllipse(p, Vec2(200.0f, 220.0f), 134.0f, 24.0f);
		d = smin(d, sdEllipse(p, Vec2(104.0f, 232.0f), 32.0f, 14.0f, 0.14f), 10.0f);
		d = smin(d, sdEllipse(p, Vec2(296.0f, 232.0f), 32.0f, 14.0f, -0.14f), 10.0f);
		d = smin(d, sdEllipse(p, Vec2(200.0f, 236.0f), 58.0f, 13.0f), 12.0f);
		return d;
	};
	BBox cBox{ 56, 186, 344, 260 };
	cv.PaintDropShadow(cBox, capSdf, Vec2(0.0f, 5.0f), 7.0f, Color4(0.10f, 0.08f, 0.08f, 0.40f));
	VolumetricStyle cSt;
	cSt.topCol = capTop;
	cSt.midCol = capMid;
	cSt.botCol = capBot;
	cSt.rimCol = capRim;
	cSt.lightDir = normalize(Vec2(-0.35f, -0.94f));
	cSt.rimWidth = 6.5f;
	cSt.rimStrength = 0.56f;
	cSt.aoDepth = 14.0f;
	cSt.aoStrength = 0.24f;
	cSt.specStrength = 0.12f;
	cSt.brushAmp = 0.065f;
	cSt.brushAngle = -0.10f;
	cSt.brushAlong = 28.0f;
	cSt.brushAcross = 8.0f;
	cSt.seed = seed + 17;
	cv.PaintVolumetricSDF(cBox, capSdf, cSt, 1.3f);
}

void BuildWorldIsland01_OnsenBamboo(const std::string& dir) {
	Canvas2D cv(400, 400);

	// 1. Floating mossy cliff base
	PaintFloatingIslandRock(
		cv,
		rgbHex(0x8D7762), rgbHex(0x5E4C3E), rgbHex(0x362B25), rgbHex(0xBBA48B),
		rgbHex(0x9EC05E), rgbHex(0x638B3C), rgbHex(0x365426), rgbHex(0xDCE89A),
		4101);

	// 2. Bamboo grove on the left
	PaintBambooStalk(cv, Vec2(102, 214), Vec2(96, 146), Vec2(88, 86), 6.2f, 4111);
	PaintBambooStalk(cv, Vec2(122, 212), Vec2(126, 152), Vec2(134, 96), 5.2f, 4112);
	PaintBambooLeaf(cv, Vec2(92, 118),  2.65f, 38, 5.2f, rgbHex(0xB4D268), rgbHex(0x4E7830));
	PaintBambooLeaf(cv, Vec2(96, 102), -0.45f, 34, 4.6f, rgbHex(0xC2DC78), rgbHex(0x568234));
	PaintBambooLeaf(cv, Vec2(128, 126), -0.22f, 36, 4.8f, rgbHex(0xA6C65E), rgbHex(0x466E2A));
	PaintBambooLeaf(cv, Vec2(126, 142),  2.85f, 30, 4.4f, rgbHex(0x96B852), rgbHex(0x3F6426));

	// 3. Warm wooden Onsen house (center-left)
	{
		BBox wBox{ 134, 134, 246, 216 };
		VolumetricStyle wallSt;
		wallSt.topCol = rgbHex(0xE0A862);
		wallSt.midCol = rgbHex(0xB6773A);
		wallSt.botCol = rgbHex(0x744622);
		wallSt.rimCol = rgbHex(0xF8DCA4);
		wallSt.rimWidth = 4.0f;
		wallSt.rimStrength = 0.45f;
		wallSt.seed = 4121;
		cv.PaintVolumetricSDF(wBox, [&](const Vec2& p) { return sdRoundBox(p, Vec2(190, 178), 42.0f, 30.0f, 4.0f); }, wallSt, 1.2f);

		// Glowing paper shoji window + espresso wood lattice
		BBox winB{ 162, 160, 218, 200 };
		cv.FillSDF(winB, [&](const Vec2& p) { return sdRoundBox(p, Vec2(190, 180), 20.0f, 14.0f, 2.5f); },
			[](const Vec2& p, float) {
				float ny = clampf((p.y - 166.0f) / 28.0f, 0.0f, 1.0f);
				return lerpColor(rgbHex(0xFFF6D2), rgbHex(0xF2C86E), ny);
			}, 1.0f);
		cv.FillSDF(winB, [&](const Vec2& p) {
			float d = sdCapsule(p, Vec2(190, 166), Vec2(190, 194), 1.4f);
			d = std::min(d, sdCapsule(p, Vec2(170, 180), Vec2(210, 180), 1.4f));
			d = std::min(d, sdCapsule(p, Vec2(180, 166), Vec2(180, 194), 1.0f));
			d = std::min(d, sdCapsule(p, Vec2(200, 166), Vec2(200, 194), 1.0f));
			return d;
		}, [](const Vec2&, float) { return rgbHex(0x3A2218); }, 0.9f);

		// Sweeping slate-indigo pagoda roof
		std::vector<Vec2> roofPts = {
			{ 132, 154 }, { 164, 122 }, { 216, 122 }, { 248, 154 },
			{ 238, 160 }, { 142, 160 }
		};
		BBox rfBox{ 124, 112, 256, 168 };
		VolumetricStyle rfSt;
		rfSt.topCol = rgbHex(0x5A7288);
		rfSt.midCol = rgbHex(0x36485A);
		rfSt.botCol = rgbHex(0x1E2834);
		rfSt.rimCol = rgbHex(0xB8D0E2);
		rfSt.rimWidth = 4.5f;
		rfSt.rimStrength = 0.52f;
		rfSt.seed = 4122;
		cv.PaintDropShadow(rfBox, [&](const Vec2& p) { return sdPolygon(p, roofPts, 3.0f); }, Vec2(0, 4), 5.0f, Color4(0.12f, 0.07f, 0.06f, 0.42f));
		cv.PaintVolumetricSDF(rfBox, [&](const Vec2& p) { return sdPolygon(p, roofPts, 3.0f); }, rfSt, 1.2f);

		// Golden ridge bar on roof peak
		cv.FillSDF(BBox{ 156, 114, 224, 128 },
			[&](const Vec2& p) { return sdCapsule(p, Vec2(162, 121), Vec2(218, 121), 3.2f); },
			[](const Vec2&, float) { return rgbHex(0xE8B94A); }, 1.0f);
	}

	// 4. Crimson Torii gate on the right
	{
		BBox tBox{ 242, 126, 330, 218 };
		VolumetricStyle trSt;
		trSt.topCol = rgbHex(0xE2503E);
		trSt.midCol = rgbHex(0xBC3226);
		trSt.botCol = rgbHex(0x7C1D18);
		trSt.rimCol = rgbHex(0xF8A488);
		trSt.rimWidth = 3.5f;
		trSt.rimStrength = 0.48f;
		trSt.seed = 4131;
		auto toriiSdf = [&](const Vec2& p) {
			float d = sdCapsule(p, Vec2(264, 208), Vec2(268, 146), 4.6f);
			d = std::min(d, sdCapsule(p, Vec2(308, 208), Vec2(304, 146), 4.6f));
			d = std::min(d, sdCapsule(p, Vec2(254, 160), Vec2(318, 160), 3.6f));
			d = std::min(d, sdQuadBezierStroke(p, Vec2(246, 142), Vec2(286, 149), Vec2(326, 142), 4.8f, 4.8f, 12));
			return d;
		};
		cv.PaintVolumetricSDF(tBox, toriiSdf, trSt, 1.1f);
		// Dark top cap on Torii kasagi
		cv.FillSDF(tBox,
			[&](const Vec2& p) { return sdQuadBezierStroke(p, Vec2(245, 138), Vec2(286, 145), Vec2(327, 138), 2.4f, 2.4f, 12); },
			[](const Vec2&, float) { return rgbHex(0x282022); }, 1.0f);
	}

	// 5. Jade Onsen hot-spring pool + gentle steam wisps
	{
		BBox pBox{ 146, 198, 250, 228 };
		cv.FillSDF(pBox, [&](const Vec2& p) { return sdEllipse(p, Vec2(198, 214), 44.0f, 10.0f); },
			[](const Vec2& p, float d) {
				float rim = 1.0f - smoothstep(0.0f, 4.5f, -d);
				return lerpColor(rgbHex(0x5EB6AC), rgbHex(0xB8EAE0), rim * 0.65f);
			}, 1.2f);

		BBox sBox{ 140, 62, 260, 204 };
		auto steamSdf = [&](const Vec2& p) {
			float d = sdQuadBezierRibbon(p, Vec2(174, 122), Vec2(164, 96), Vec2(180, 74), 2.0f, 6.5f, 1.5f, 12);
			d = std::min(d, sdQuadBezierRibbon(p, Vec2(204, 118), Vec2(218, 92), Vec2(202, 68), 2.0f, 7.2f, 1.5f, 12));
			d = std::min(d, sdQuadBezierRibbon(p, Vec2(232, 128), Vec2(242, 106), Vec2(228, 86), 1.6f, 5.0f, 1.2f, 12));
			return d;
		};
		cv.FillSDF(sBox, steamSdf, [](const Vec2& p, float) {
			float fade = clampf((p.y - 64.0f) / 64.0f, 0.0f, 1.0f);
			return Color4(0.99f, 0.97f, 0.92f, 0.56f * fade);
		}, 3.5f);
	}

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.06f, 0.015f, 0.010f, 4199);
	cv.SavePNG(dir + "/world_island_01.png");
	std::cout << "  -> Exported home2d/world_island_01.png (400x400)\n";
}

void BuildWorldIsland02_YuzuCanyon(const std::string& dir) {
	Canvas2D cv(400, 400);

	// 1. Terracotta / burnt-ochre canyon cliff + warm golden-sage mesa cap
	PaintFloatingIslandRock(
		cv,
		rgbHex(0xD48248), rgbHex(0x9E512A), rgbHex(0x5C2B1A), rgbHex(0xF0BA7A),
		rgbHex(0xD2B056), rgbHex(0x967A34), rgbHex(0x5A4820), rgbHex(0xF4DE8E),
		4201);

	// Horizontal canyon strata stripes on cliff face
	cv.FillSDF(BBox{ 96, 250, 304, 320 }, [&](const Vec2& p) {
		float d = sdCapsule(p, Vec2(106, 266), Vec2(292, 264), 4.2f);
		d = std::min(d, sdCapsule(p, Vec2(132, 294), Vec2(268, 292), 3.6f));
		return d;
	}, [](const Vec2&, float) { return Color4(0.45f, 0.20f, 0.11f, 0.34f); }, 2.0f);

	// 2. Sculpted Sandstone Canyon Arch (center-right background)
	{
		BBox aBox{ 162, 108, 294, 222 };
		VolumetricStyle archSt;
		archSt.topCol = rgbHex(0xDF9658);
		archSt.midCol = rgbHex(0xAE5E32);
		archSt.botCol = rgbHex(0x6C341E);
		archSt.rimCol = rgbHex(0xF8CE92);
		archSt.rimWidth = 5.0f;
		archSt.rimStrength = 0.50f;
		archSt.seed = 4211;
		auto archSdf = [&](const Vec2& p) {
			float outer = sdEllipse(p, Vec2(226, 206), 58.0f, 82.0f);
			float inner = sdEllipse(p, Vec2(226, 212), 32.0f, 54.0f);
			float d = std::max(outer, -inner);
			d = std::max(d, p.y - 212.0f);
			return d;
		};
		cv.PaintVolumetricSDF(aBox, archSdf, archSt, 1.3f);
	}

	// 3. Golden Yuzu Orchard Trees (left & center-left)
	auto paintYuzuTree = [&](Vec2 base, float sc, int seed) {
		BBox tBox{ base.x - 54 * sc, base.y - 110 * sc, base.x + 54 * sc, base.y + 12 };
		VolumetricStyle trunkSt;
		trunkSt.topCol = rgbHex(0x8C5E3A);
		trunkSt.midCol = rgbHex(0x603C24);
		trunkSt.botCol = rgbHex(0x3A2214);
		trunkSt.rimCol = rgbHex(0xBA8E5E);
		trunkSt.seed = seed;
		cv.PaintVolumetricSDF(tBox, [&](const Vec2& p) {
			float d = sdQuadBezierStroke(p, base, base + Vec2(-4 * sc, -26 * sc), base + Vec2(2 * sc, -54 * sc), 7.5f * sc, 4.5f * sc, 10);
			return d;
		}, trunkSt, 1.1f);

		VolumetricStyle leafSt;
		leafSt.topCol = rgbHex(0x88B248);
		leafSt.midCol = rgbHex(0x4E7A30);
		leafSt.botCol = rgbHex(0x28461E);
		leafSt.rimCol = rgbHex(0xCCE07E);
		leafSt.rimWidth = 5.5f * sc;
		leafSt.rimStrength = 0.54f;
		leafSt.seed = seed + 1;
		auto crownSdf = [&](const Vec2& p) {
			Vec2 c = base + Vec2(0.0f, -68.0f * sc);
			float d = sdCircle(p, c, 28.0f * sc);
			d = smin(d, sdCircle(p, c + Vec2(-20 * sc, 8 * sc), 20.0f * sc), 9.0f * sc);
			d = smin(d, sdCircle(p, c + Vec2(20 * sc, 6 * sc), 21.0f * sc), 9.0f * sc);
			d = smin(d, sdCircle(p, c + Vec2(0, -16 * sc), 19.0f * sc), 9.0f * sc);
			return d;
		};
		cv.PaintVolumetricSDF(tBox, crownSdf, leafSt, 1.3f);

		// Bright golden Yuzu citrus orbs nestled in foliage
		VolumetricStyle yzSt;
		yzSt.topCol = rgbHex(0xFFF06A);
		yzSt.midCol = rgbHex(0xF2B422);
		yzSt.botCol = rgbHex(0xB67210);
		yzSt.rimCol = rgbHex(0xFFFFD6);
		yzSt.rimWidth = 2.5f;
		yzSt.specStrength = 0.35f;
		yzSt.seed = seed + 2;
		const Vec2 offsets[] = { {-16, -64}, {12, -74}, {0, -54}, {20, -58}, {-6, -82} };
		for (int i = 0; i < 5; ++i) {
			Vec2 op = base + offsets[i] * sc;
			float r = 6.2f * sc;
			cv.PaintVolumetricSDF(BBox{ op.x - r - 4, op.y - r - 4, op.x + r + 4, op.y + r + 4 },
				[&](const Vec2& p) { return sdCircle(p, op, r); }, yzSt, 1.0f);
		}
	};
	paintYuzuTree(Vec2(118.0f, 212.0f), 1.05f, 4221);
	paintYuzuTree(Vec2(174.0f, 214.0f), 0.78f, 4225);

	// 4. Croc Turret Tower silhouette (right crest)
	{
		BBox tuBox{ 244, 114, 336, 218 };
		VolumetricStyle ironSt;
		ironSt.topCol = rgbHex(0x646C74);
		ironSt.midCol = rgbHex(0x3D434A);
		ironSt.botCol = rgbHex(0x20242A);
		ironSt.rimCol = rgbHex(0xA8B4C0);
		ironSt.rimWidth = 3.8f;
		ironSt.rimStrength = 0.48f;
		ironSt.seed = 4231;

		auto towerSdf = [&](const Vec2& p) {
			float d = sdRoundBox(p, Vec2(288, 178), 22.0f, 32.0f, 3.0f);
			// Crenellations
			d = std::min(d, sdRoundBox(p, Vec2(272, 144), 6.0f, 7.0f, 1.5f));
			d = std::min(d, sdRoundBox(p, Vec2(288, 144), 6.0f, 7.0f, 1.5f));
			d = std::min(d, sdRoundBox(p, Vec2(304, 144), 6.0f, 7.0f, 1.5f));
			// Tilted iron cannon barrel pointing left
			d = std::min(d, sdTaperedCapsule(p, Vec2(280, 162), Vec2(248, 152), 7.5f, 5.2f));
			return d;
		};
		cv.PaintVolumetricSDF(tuBox, towerSdf, ironSt, 1.1f);

		// Crimson turret pennant banner
		cv.FillSDF(BBox{ 284, 110, 326, 144 },
			[&](const Vec2& p) {
				float pole = sdCapsule(p, Vec2(292, 140), Vec2(292, 114), 1.6f);
				std::vector<Vec2> flg = { {293, 115}, {322, 122}, {293, 130} };
				return std::min(pole, sdPolygon(p, flg, 1.0f));
			},
			[](const Vec2& p, float) { return (p.x < 294.5f) ? rgbHex(0x3A2A22) : rgbHex(0xD63B2E); }, 1.0f);
	}

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.06f, 0.015f, 0.010f, 4299);
	cv.SavePNG(dir + "/world_island_02.png");
	std::cout << "  -> Exported home2d/world_island_02.png (400x400)\n";
}

void BuildWorldIsland03_IceCrystal(const std::string& dir) {
	Canvas2D cv(400, 400);

	// 1. Back soft cloud cushion behind island rim
	PaintPuffyCloud(cv, Vec2(200.0f, 300.0f), 0.92f, 4301);

	// 2. Glacial slate cliff + crisp sunlit snow cap
	PaintFloatingIslandRock(
		cv,
		rgbHex(0x7898B8), rgbHex(0x476484), rgbHex(0x23344A), rgbHex(0xC2DCF0),
		rgbHex(0xF6FCFF), rgbHex(0xCFE6F6), rgbHex(0x8BB2CE), rgbHex(0xFFFFFF),
		4305, false);

	// 3. Glowing Cyan-Jade Crystal Spires (left, rear crown, and right)
	auto paintCrystal = [&](Vec2 base, float w, float h, float rot, int seed) {
		std::vector<Vec2> pts = {
			rotatePt(base + Vec2(-w * 0.55f, 4.0f), base, rot),
			rotatePt(base + Vec2(-w * 0.48f, -h * 0.72f), base, rot),
			rotatePt(base + Vec2(0.0f, -h), base, rot),
			rotatePt(base + Vec2(w * 0.48f, -h * 0.72f), base, rot),
			rotatePt(base + Vec2(w * 0.55f, 4.0f), base, rot)
		};
		BBox box{ base.x - h - 20, base.y - h - 20, base.x + h + 20, base.y + 30 };
		VolumetricStyle crSt;
		crSt.topCol = rgbHex(0xC4FBFF);
		crSt.midCol = rgbHex(0x4EC8E4);
		crSt.botCol = rgbHex(0x1E6C94);
		crSt.rimCol = rgbHex(0xFFFFFF);
		crSt.rimWidth = 5.0f;
		crSt.rimStrength = 0.74f;
		crSt.specStrength = 0.42f;
		crSt.aoDepth = 12.0f;
		crSt.aoStrength = 0.18f;
		crSt.brushAmp = 0.04f;
		crSt.seed = seed;
		cv.PaintVolumetricSDF(box, [&](const Vec2& p) { return sdPolygon(p, pts, 2.2f); }, crSt, 1.1f);

		// Crisp inner facet highlight line
		Vec2 tip = rotatePt(base + Vec2(0.0f, -h * 0.94f), base, rot);
		Vec2 mid = rotatePt(base + Vec2(-w * 0.08f, -h * 0.10f), base, rot);
		cv.FillSDF(box, [&](const Vec2& p) { return sdCapsule(p, tip, mid, 1.5f); },
			[](const Vec2&, float) { return Color4(0.95f, 1.0f, 1.0f, 0.70f); }, 0.9f);
	};

	paintCrystal(Vec2(114, 208), 26, 86, -0.26f, 4311);
	paintCrystal(Vec2(142, 206), 20, 62, -0.08f, 4312);
	paintCrystal(Vec2(204, 186), 30, 98,  0.04f, 4313);
	paintCrystal(Vec2(276, 206), 28, 90,  0.22f, 4314);
	paintCrystal(Vec2(298, 212), 18, 56,  0.40f, 4315);

	// 4. Arched Ice Cave Mouth (center foreground)
	{
		BBox cBox{ 146, 152, 254, 224 };
		// Outer frost arch
		VolumetricStyle archSt;
		archSt.topCol = rgbHex(0xE8F6FF);
		archSt.midCol = rgbHex(0x94C4DE);
		archSt.botCol = rgbHex(0x4C7A9E);
		archSt.rimCol = rgbHex(0xFFFFFF);
		archSt.rimWidth = 4.5f;
		archSt.rimStrength = 0.62f;
		archSt.seed = 4321;
		cv.PaintVolumetricSDF(cBox, [&](const Vec2& p) {
			float d = sdEllipse(p, Vec2(200, 214), 44.0f, 46.0f);
			return std::max(d, p.y - 216.0f);
		}, archSt, 1.2f);

		// Deep glowing cyan-indigo cave interior
		cv.FillSDF(cBox, [&](const Vec2& p) {
			float d = sdEllipse(p, Vec2(200, 216), 31.0f, 34.0f);
			return std::max(d, p.y - 216.0f);
		}, [](const Vec2& p, float) {
			float dist = length(p - Vec2(200, 208)) / 36.0f;
			return lerpColor(rgbHex(0x389EC2), rgbHex(0x14243A), smoothstep(0.15f, 0.95f, dist));
		}, 1.2f);

		// Hanging icicles along cave lip
		const Vec2 icPos[] = { {182, 184}, {194, 181}, {208, 182}, {219, 186} };
		const float icLen[] = { 13.0f, 17.0f, 14.0f, 11.0f };
		for (int i = 0; i < 4; ++i) {
			Vec2 a = icPos[i];
			Vec2 b = a + Vec2(0.0f, icLen[i]);
			cv.FillSDF(BBox{ a.x - 8, a.y - 4, a.x + 8, b.y + 6 },
				[&](const Vec2& p) { return sdTaperedCapsule(p, a, b, 3.0f, 0.7f); },
				[](const Vec2&, float) { return rgbHex(0xDDF8FF); }, 0.9f);
		}
	}

	// 5. Foreground soft cloud wisps hugging the floating base
	PaintPuffyCloud(cv, Vec2(128.0f, 324.0f), 0.56f, 4331);
	PaintPuffyCloud(cv, Vec2(274.0f, 320.0f), 0.52f, 4332);

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.06f, 0.015f, 0.010f, 4399);
	cv.SavePNG(dir + "/world_island_03.png");
	std::cout << "  -> Exported home2d/world_island_03.png (400x400)\n";
}

void BuildWorldIsland04_CrocCitadel(const std::string& dir) {
	Canvas2D cv(400, 400);

	// Helper: tilted glowing golden Low-G orbital ring (back half & front half)
	const Vec2 ringCtr(200.0f, 240.0f);
	const float ringRot = -0.20f;
	auto paintRingHalf = [&](bool frontHalf) {
		BBox box{ 14, 146, 386, 336 };
		cv.FillSDF(box, [&](const Vec2& p) {
			Vec2 q = rotatePt(p, ringCtr, -ringRot) - ringCtr;
			if (frontHalf && q.y < -4.0f) return 100.0f;
			if (!frontHalf && q.y > 4.0f) return 100.0f;
			float dOuter = sdEllipse(p, ringCtr, 174.0f, 52.0f, ringRot);
			float dInner = sdEllipse(p, ringCtr, 156.0f, 40.0f, ringRot);
			return std::max(dOuter, -dInner);
		}, [&](const Vec2& p, float d) {
			float core = 1.0f - smoothstep(0.0f, 6.0f, std::fabs(d + 4.5f));
			Color4 c = lerpColor(rgbHex(0xD68E1E), rgbHex(0xFFF29A), core * 0.85f);
			c.a = frontHalf ? 0.94f : 0.72f;
			return c;
		}, 2.2f);
	};

	// 1. Back half of golden Low-G ring
	paintRingHalf(false);

	// 2. Dark-indigo obsidian floating rock + royal-indigo stone terrace
	PaintFloatingIslandRock(
		cv,
		rgbHex(0x4C4E78), rgbHex(0x2C2C4C), rgbHex(0x17162B), rgbHex(0x9698C8),
		rgbHex(0x5A5C88), rgbHex(0x36365A), rgbHex(0x1E1E38), rgbHex(0xD8B45A),
		4401, true);

	// Glowing golden core veins in obsidian underside
	cv.FillSDF(BBox{ 118, 250, 282, 344 }, [&](const Vec2& p) {
		float d = sdQuadBezierStroke(p, Vec2(146, 258), Vec2(170, 294), Vec2(198, 336), 2.2f, 1.0f, 10);
		d = std::min(d, sdQuadBezierStroke(p, Vec2(252, 260), Vec2(232, 296), Vec2(206, 334), 2.2f, 1.0f, 10));
		return d;
	}, [](const Vec2&, float) { return Color4(0.98f, 0.78f, 0.24f, 0.76f); }, 1.4f);

	// 3. Royal Croc Citadel Keep & Flanking Towers
	{
		BBox kBox{ 104, 72, 296, 222 };
		VolumetricStyle wallSt;
		wallSt.topCol = rgbHex(0x4B4E7A);
		wallSt.midCol = rgbHex(0x2B2C4A);
		wallSt.botCol = rgbHex(0x17172C);
		wallSt.rimCol = rgbHex(0xE8C264);
		wallSt.rimWidth = 4.2f;
		wallSt.rimStrength = 0.56f;
		wallSt.seed = 4411;

		auto keepSdf = [&](const Vec2& p) {
			float d = sdRoundBox(p, Vec2(200, 174), 56.0f, 38.0f, 4.0f);
			d = std::min(d, sdRoundBox(p, Vec2(134, 168), 16.0f, 42.0f, 3.0f));
			d = std::min(d, sdRoundBox(p, Vec2(266, 168), 16.0f, 42.0f, 3.0f));
			// Upper throne tier
			d = std::min(d, sdRoundBox(p, Vec2(200, 128), 34.0f, 22.0f, 3.0f));
			return d;
		};
		cv.PaintVolumetricSDF(kBox, keepSdf, wallSt, 1.2f);

		// Glowing amber arched citadel gate + twin tower slit windows
		cv.FillSDF(kBox, [&](const Vec2& p) {
			float g = std::max(sdEllipse(p, Vec2(200, 208), 18.0f, 26.0f), p.y - 210.0f);
			float w1 = sdRoundBox(p, Vec2(134, 160), 4.0f, 9.0f, 2.0f);
			float w2 = sdRoundBox(p, Vec2(266, 160), 4.0f, 9.0f, 2.0f);
			return std::min({ g, w1, w2 });
		}, [](const Vec2& p, float) {
			float ny = clampf((p.y - 150.0f) / 60.0f, 0.0f, 1.0f);
			return lerpColor(rgbHex(0xFFF2A6), rgbHex(0xE89220), ny);
		}, 1.1f);

		// Sweeping Horned Palace Roofs (lower & upper tier)
		VolumetricStyle roofSt;
		roofSt.topCol = rgbHex(0x3C3F68);
		roofSt.midCol = rgbHex(0x22233E);
		roofSt.botCol = rgbHex(0x121224);
		roofSt.rimCol = rgbHex(0xF6D472);
		roofSt.rimWidth = 4.5f;
		roofSt.rimStrength = 0.65f;
		roofSt.seed = 4412;

		auto hornedRoof = [&](Vec2 c, float halfW, float h) {
			std::vector<Vec2> pts = {
				{ c.x - halfW - 14.0f, c.y - 6.0f },
				{ c.x - halfW * 0.60f, c.y + 4.0f },
				{ c.x - halfW * 0.42f, c.y - h },
				{ c.x + halfW * 0.42f, c.y - h },
				{ c.x + halfW * 0.60f, c.y + 4.0f },
				{ c.x + halfW + 14.0f, c.y - 6.0f },
				{ c.x + halfW * 0.72f, c.y + 12.0f },
				{ c.x - halfW * 0.72f, c.y + 12.0f }
			};
			cv.PaintVolumetricSDF(kBox, [&](const Vec2& p) { return sdPolygon(p, pts, 2.5f); }, roofSt, 1.1f);
		};
		hornedRoof(Vec2(200, 138), 64.0f, 18.0f);
		hornedRoof(Vec2(200, 108), 44.0f, 16.0f);

		// Pointed spire caps on flanking towers
		std::vector<Vec2> capL = { {114, 128}, {134, 102}, {154, 128} };
		std::vector<Vec2> capR = { {246, 128}, {266, 102}, {286, 128} };
		cv.PaintVolumetricSDF(kBox, [&](const Vec2& p) { return std::min(sdPolygon(p, capL, 1.5f), sdPolygon(p, capR, 1.5f)); }, roofSt, 1.1f);

		// Gleaming Golden Crown Emblem at apex
		VolumetricStyle gSt;
		gSt.topCol = rgbHex(0xFFF69A);
		gSt.midCol = rgbHex(0xF0B828);
		gSt.botCol = rgbHex(0x9E6410);
		gSt.rimCol = rgbHex(0xFFFFDE);
		gSt.rimWidth = 2.8f;
		gSt.specStrength = 0.45f;
		gSt.seed = 4415;
		std::vector<Vec2> crownPts = {
			{ 184, 92 }, { 180, 74 }, { 192, 83 }, { 200, 68 },
			{ 208, 83 }, { 220, 74 }, { 216, 92 }
		};
		cv.PaintVolumetricSDF(BBox{ 170, 60, 230, 102 }, [&](const Vec2& p) { return sdPolygon(p, crownPts, 1.2f); }, gSt, 1.0f);
	}

	// 4. Front half of glowing golden Low-G ring + orbiting golden motes
	paintRingHalf(true);
	const Vec2 motes[] = { {46, 266}, {352, 212}, {102, 294}, {314, 276} };
	for (int i = 0; i < 4; ++i) {
		Vec2 m = motes[i];
		cv.FillSDF(BBox{ m.x - 8, m.y - 8, m.x + 8, m.y + 8 },
			[&](const Vec2& p) { return sdCircle(p, m, 3.8f); },
			[](const Vec2&, float) { return rgbHex(0xFFF29C); }, 1.2f);
	}

	cv.ApplyAntiSlopMasterGrade(0.92f, 0.06f, 0.015f, 0.010f, 4499);
	cv.SavePNG(dir + "/world_island_04.png");
	std::cout << "  -> Exported home2d/world_island_04.png (400x400)\n";
}

void BuildAll4WorldIslands(const std::string& dir) {
	BuildWorldIsland01_OnsenBamboo(dir);
	BuildWorldIsland02_YuzuCanyon(dir);
	BuildWorldIsland03_IceCrystal(dir);
	BuildWorldIsland04_CrocCitadel(dir);
}

} // namespace

bool GenerateAllHome2DLayers(const std::string& outDir) {
	std::error_code ec;
	fs::create_directories(outDir, ec);
	if (ec) {
		std::cerr << "[ERROR] Failed creating home2d output dir: " << ec.message() << "\n";
		return false;
	}

	std::cout << "[AssetForge 2D] Rendering Anti-Slop harmonized 2D parallax layers -> " << outDir << "\n";
	BuildLayer00_SkySun(outDir);
	BuildLayer01_Sunburst(outDir);
	BuildLayer02_Clouds(outDir);
	BuildLayer03_MountainsFar(outDir);
	BuildLayer04_MidgroundOnsen(outDir);
	BuildLayer05_SteamWisps(outDir);
	BuildLayer06_SlingshotCliff(outDir);
	BuildLayer07_ForegroundHill(outDir);
	BuildLayer08_BambooFrame(outDir);
	BuildAll7CapybaraSprites(outDir);
	BuildAll4WorldIslands(outDir);
	HarmonizeExternal2DCapybaras(outDir);
	std::cout << "[AssetForge 2D] All transparent 2D PNG layers & Anti-Slop LUT harmonized sprites exported cleanly!\n";
	return true;
}
