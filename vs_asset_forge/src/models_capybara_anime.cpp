#include "models_capybara_anime.h"
#include "geometry_builders.h"
#include <glm/gtc/matrix_transform.hpp>
#include <algorithm>

namespace {
enum class AnimeMouth {
	GrumpySmirk,
	OpenShout,
	CatSmile,      // ':3' / cute happy anime smile
	FierceGrin,
	SmugSide,
	HeavyFangs,
	HeroRoar       // Mulut mengaum terbuka lebar dramatis untuk Key-Art Home
};

enum class AnimeBrow {
	AngryV,
	WildHigh,
	CuteArch,
	FierceSlope,
	CockyOneUp,
	HeavyUnibrow
};

MaterialDef MakeMat(const std::string& name, const std::string& tex,
					glm::vec3 kd = glm::vec3(1.0f),
					glm::vec3 ke = glm::vec3(0.0f),
					float shine = 24.0f) {
	MaterialDef m;
	m.name = name;
	m.textureFile = tex;
	m.kd = kd;
	m.ke = ke;
	m.shininess = shine;
	return m;
}

glm::mat4 TRS(glm::vec3 t, glm::vec3 rotDeg = glm::vec3(0.0f), glm::vec3 s = glm::vec3(1.0f)) {
	glm::mat4 m(1.0f);
	m = glm::translate(m, t);
	m = glm::rotate(m, glm::radians(rotDeg.z), glm::vec3(0, 0, 1));
	m = glm::rotate(m, glm::radians(rotDeg.y), glm::vec3(0, 1, 0));
	m = glm::rotate(m, glm::radians(rotDeg.x), glm::vec3(1, 0, 0));
	m = glm::scale(m, s);
	return m;
}

// =========================================================================
// Helper Geometri Mulut 3D Kontur Moncong (Snout-Hugging Parametric Shells)
// Menempel rapat mengikuti kelengkungan elipsoid moncong -> nol tonjolan bola/lump!
// =========================================================================
inline void EvalSnoutSurface(
	const glm::vec3& snoutPos, float hs, float theta, float phi, float offset,
	glm::vec3& outPos, glm::vec3& outNrm) {
	const float rx = 0.106f * hs;
	const float ry = 0.112f * hs;
	const float rz = 0.148f * hs;
	const float cp = std::cos(phi), sp = std::sin(phi);
	const float ct = std::cos(theta), st = std::sin(theta);

	glm::vec3 localP(rx * cp * ct, ry * sp, rz * cp * st);
	glm::vec3 localN = glm::normalize(glm::vec3(
		(cp * ct) / std::max(rx, 1e-4f),
		sp / std::max(ry, 1e-4f),
		(cp * st) / std::max(rz, 1e-4f)));

	// Rotasi -5 derajat sumbu Z menyamai TRS moncong
	const float rad = glm::radians(-5.0f);
	const float c = std::cos(rad), s = std::sin(rad);
	glm::vec3 rotP(localP.x * c - localP.y * s, localP.x * s + localP.y * c, localP.z);
	glm::vec3 rotN = glm::normalize(glm::vec3(localN.x * c - localN.y * s, localN.x * s + localN.y * c, localN.z));

	outPos = snoutPos + rotP + rotN * offset;
	outNrm = rotN;
}

// Membuat patch mulut lengkung solid 2-sisi tipis yang memeluk permukaan moncong 100% mulus
template <typename BotFn, typename TopFn>
SubMesh BuildSnoutMouthPatch(
	const glm::vec3& snoutPos, float hs,
	float thetaMin, float thetaMax,
	BotFn phiBotFn, TopFn phiTopFn,
	float offset, int nu = 16, int nv = 6) {
	SubMesh m;
	const int cols = nu + 1;
	const int rows = nv + 1;
	m.vertices.reserve(static_cast<size_t>(cols * rows));
	for (int iv = 0; iv <= nv; ++iv) {
		float v = static_cast<float>(iv) / static_cast<float>(nv);
		for (int iu = 0; iu <= nu; ++iu) {
			float u = static_cast<float>(iu) / static_cast<float>(nu);
			float th = thetaMin + (thetaMax - thetaMin) * u;
			float pb = phiBotFn(u);
			float pt = phiTopFn(u);
			float ph = pb + (pt - pb) * v;
			glm::vec3 pos, nrm;
			EvalSnoutSurface(snoutPos, hs, th, ph, offset, pos, nrm);
			m.vertices.push_back({ pos, nrm, glm::vec2(u, v) });
		}
	}
	for (int iv = 0; iv < nv; ++iv) {
		for (int iu = 0; iu < nu; ++iu) {
			uint32_t a = static_cast<uint32_t>(iv * cols + iu);
			uint32_t b = a + 1;
			uint32_t c = static_cast<uint32_t>((iv + 1) * cols + iu);
			uint32_t d = c + 1;
			// Winding menghadap luar (+X/+N) — pastikan normal selaras dengan outNrm
			m.indices.push_back(a); m.indices.push_back(c); m.indices.push_back(b);
			m.indices.push_back(b); m.indices.push_back(c); m.indices.push_back(d);
		}
	}
	return m;
}

// Membuat garis bibir kurva 3D menempel rapat pada permukaan moncong (untuk cemberut/frown tegas!)
template <typename PhiFn>
SubMesh BuildSnoutLipCurve(
	const glm::vec3& snoutPos, float hs,
	float thetaMin, float thetaMax,
	PhiFn phiFn, float radius, float offset, int steps = 14) {
	SubMesh out;
	std::vector<glm::vec3> pts(steps + 1);
	for (int i = 0; i <= steps; ++i) {
		float u = static_cast<float>(i) / static_cast<float>(steps);
		float th = thetaMin + (thetaMax - thetaMin) * u;
		glm::vec3 pos, nrm;
		EvalSnoutSurface(snoutPos, hs, th, phiFn(u), offset, pos, nrm);
		pts[i] = pos;
	}
	// Gabungkan sebagai rantai segmen bezier pendek agar radius konsisten & mulus di moncong
	for (int i = 0; i < steps; ++i) {
		glm::vec3 p0 = pts[i];
		glm::vec3 p3 = pts[i + 1];
		glm::vec3 p1 = glm::mix(p0, p3, 0.33f);
		glm::vec3 p2 = glm::mix(p0, p3, 0.67f);
		float uMid = (i + 0.5f) / static_cast<float>(steps);
		float taper = 0.72f + 0.28f * std::sin(uMid * 3.1415926f);
		AppendTransformedMesh(out, BuildBezierTube({{ p0, p1, p2, p3 }}, radius * taper, radius * taper, 3, 7, true), glm::mat4(1.0f));
	}
	return out;
}

// Kubah mata anime: UV diproyeksikan langsung dari bidang Z-Y depan agar tekstur iris 256x256 tampil tajam 1:1
// mirrorU = true untuk mata kiri (-Z) sehingga sisi dalam dekat hidung selalu x < 0!
SubMesh BuildAnimeEyeLens(float rx, float ry, float rz, bool mirrorU) {
	SubMesh m = BuildEllipsoid(rx, ry, rz, 14, 18);
	float sign = mirrorU ? -1.0f : 1.0f;
	for (auto& v : m.vertices) {
		float u = 0.5f + sign * 0.48f * (v.pos.z / std::max(rz, 1e-4f));
		float vv = 0.5f + 0.48f * (v.pos.y / std::max(ry, 1e-4f));
		v.uv = glm::vec2(std::clamp(u, 0.02f, 0.98f), std::clamp(vv, 0.02f, 0.98f));
	}
	return m;
}

// Simbol urat marah anime 3D ringkas & rapi di pelipis
SubMesh BuildAngerVeinMark() {
	SubMesh m;
	for (int k = 0; k < 4; ++k) {
		float ang = k * 90.0f;
		std::array<glm::vec3, 4> arm = {{
			{ 0.0f, 0.012f, 0.008f },
			{ 0.0f, 0.013f, 0.019f },
			{ 0.0f, 0.024f, 0.030f },
			{ 0.0f, 0.038f, 0.038f }
		}};
		SubMesh tube = BuildBezierTube(arm, 0.007f, 0.004f, 8, 6, true);
		AppendTransformedMesh(m, tube, TRS(glm::vec3(0.0f), glm::vec3(ang, 0.0f, 0.0f)));
	}
	return m;
}

// Basis tubuh KAPIBARA ASLI ber-siluet loaf 4 kaki + kepala kotak-bulat + wajah Anime super ekspresif
void BuildAnimeCapyCore(
	ModelAsset& asset,
	const std::string& furMat,
	const std::string& furTex,
	const std::string& eyeTex,
	glm::vec3 bodyScale,
	float headScale,
	float eyeScale,
	AnimeBrow browStyle,
	AnimeMouth mouthStyle,
	bool hasAngerMark = false)
{
	AddUniqueMaterial(asset, MakeMat(furMat, furTex));
	AddUniqueMaterial(asset, MakeMat("mat_belly", "tex_capy_belly.bmp"));
	AddUniqueMaterial(asset, MakeMat("mat_snout", "tex_capy_snout.bmp"));
	AddUniqueMaterial(asset, MakeMat("mat_anime_eye", eyeTex, glm::vec3(1.0f), glm::vec3(0.08f), 64.0f));
	AddUniqueMaterial(asset, MakeMat("mat_ink", "tex_anime_ink.bmp", glm::vec3(0.15f), glm::vec3(0.0f), 8.0f));
	AddUniqueMaterial(asset, MakeMat("mat_mouth_dark", "tex_mouth_dark.bmp"));
	AddUniqueMaterial(asset, MakeMat("mat_tongue", "tex_tongue_pink.bmp"));
	AddUniqueMaterial(asset, MakeMat("mat_white", "tex_capy_eye_white.bmp"));

	// 1. Tubuh horizontal khas Kapibara (loaf memanjang pada sumbu X + 4 kaki pendek)
	SubMesh furPart;
	furPart.objectName = "anime_capy_body";
	furPart.materialName = furMat;

	std::array<glm::vec2, 4> torsoProf = {{
		{ 0.00f, -0.40f }, { 0.34f, -0.30f }, { 0.32f, 0.14f }, { 0.00f, 0.25f }
	}};
	SubMesh torso = BuildBezierRevolvedProfile(torsoProf, 20, 24);
	AppendTransformedMesh(furPart, torso, TRS(glm::vec3(-0.06f, -0.04f, 0.0f), glm::vec3(0.0f), bodyScale * glm::vec3(1.0f, 0.90f, 1.02f)));

	// Kepala kotak-membulat khas kapibara (lebih besar bergaya anime chibi agar ekspresi terbaca kuat)
	const glm::vec3 headPos = glm::vec3(0.18f * bodyScale.x, 0.13f * bodyScale.y, 0.0f);
	SubMesh head = BuildEllipsoid(0.24f * headScale, 0.205f * headScale, 0.205f * headScale, 16, 22);
	AppendTransformedMesh(furPart, head, TRS(headPos, glm::vec3(0, 0, -6.0f)));

	// Telinga bulat kecil di belakang atas kepala (ciri khas kapibara!)
	SubMesh ear = BuildEllipsoid(0.055f * headScale, 0.072f * headScale, 0.036f * headScale, 10, 14);
	AppendTransformedMesh(furPart, ear, TRS(headPos + glm::vec3(-0.10f * headScale, 0.175f * headScale,  0.145f * headScale), glm::vec3(-18, 0, 22)));
	AppendTransformedMesh(furPart, ear, TRS(headPos + glm::vec3(-0.10f * headScale, 0.175f * headScale, -0.145f * headScale), glm::vec3( 18, 0, 22)));

	// Empat kaki pendek bulat & ekor kecil
	SubMesh leg = BuildEllipsoid(0.068f * bodyScale.x, 0.082f * bodyScale.y, 0.065f * bodyScale.z, 10, 12);
	AppendTransformedMesh(furPart, leg, TRS(glm::vec3( 0.11f * bodyScale.x, -0.23f * bodyScale.y,  0.14f * bodyScale.z)));
	AppendTransformedMesh(furPart, leg, TRS(glm::vec3( 0.11f * bodyScale.x, -0.23f * bodyScale.y, -0.14f * bodyScale.z)));
	AppendTransformedMesh(furPart, leg, TRS(glm::vec3(-0.22f * bodyScale.x, -0.23f * bodyScale.y,  0.14f * bodyScale.z)));
	AppendTransformedMesh(furPart, leg, TRS(glm::vec3(-0.22f * bodyScale.x, -0.23f * bodyScale.y, -0.14f * bodyScale.z)));

	SubMesh tail = BuildEllipsoid(0.05f, 0.045f, 0.045f, 8, 10);
	AppendTransformedMesh(furPart, tail, TRS(glm::vec3(-0.43f * bodyScale.x, -0.05f * bodyScale.y, 0.0f)));
	asset.parts.push_back(std::move(furPart));

	// 2. Perut krem lembut
	SubMesh bellyPart;
	bellyPart.objectName = "anime_capy_belly";
	bellyPart.materialName = "mat_belly";
	AppendTransformedMesh(bellyPart, BuildEllipsoid(0.24f * bodyScale.x, 0.15f * bodyScale.y, 0.21f * bodyScale.z, 12, 16),
		TRS(glm::vec3(0.02f * bodyScale.x, -0.11f * bodyScale.y, 0.0f), glm::vec3(0, 0, 12)));
	asset.parts.push_back(std::move(bellyPart));

	// 3. Moncong tumpul kotak-bulat ringkas khas Kapibara 2.5D (+X) agar menyatu ekspresif dengan mata depan
	const glm::vec3 snoutPos = headPos + glm::vec3(0.158f * headScale, -0.028f * headScale, 0.0f);
	SubMesh snoutPart;
	snoutPart.objectName = "anime_capy_snout";
	snoutPart.materialName = "mat_snout";
	AppendTransformedMesh(snoutPart, BuildEllipsoid(0.106f * headScale, 0.112f * headScale, 0.148f * headScale, 12, 16),
		TRS(snoutPos, glm::vec3(0, 0, -5.0f)));
	asset.parts.push_back(std::move(snoutPart));

	// 4. Telinga dalam krem hangat (TANPA pipi pink!)
	SubMesh innerEarPart;
	innerEarPart.objectName = "anime_capy_inner_ears";
	innerEarPart.materialName = "mat_belly";
	SubMesh innerEar = BuildEllipsoid(0.030f * headScale, 0.044f * headScale, 0.016f * headScale, 8, 10);
	AppendTransformedMesh(innerEarPart, innerEar, TRS(headPos + glm::vec3(-0.08f * headScale, 0.175f * headScale,  0.155f * headScale), glm::vec3(-18, 10, 22)));
	AppendTransformedMesh(innerEarPart, innerEar, TRS(headPos + glm::vec3(-0.08f * headScale, 0.175f * headScale, -0.155f * headScale), glm::vec3( 18,-10, 22)));
	asset.parts.push_back(std::move(innerEarPart));

	// 5. MATA ANIME BESAR BER-IRIS (lebih menghadap depan ±12 deg seperti Key-Art 2D!)
	const glm::vec3 eyeCenter = headPos + glm::vec3(0.140f * headScale, 0.068f * headScale, 0.0f);
	const float eyeSepZ = 0.090f * headScale;
	SubMesh eyePart;
	eyePart.objectName = "anime_capy_eyes";
	eyePart.materialName = "mat_anime_eye";
	SubMesh eyeLensR = BuildAnimeEyeLens(0.048f * eyeScale, 0.066f * eyeScale, 0.060f * eyeScale, false);
	SubMesh eyeLensL = BuildAnimeEyeLens(0.048f * eyeScale, 0.066f * eyeScale, 0.060f * eyeScale, true);
	AppendTransformedMesh(eyePart, eyeLensR, TRS(eyeCenter + glm::vec3(0.0f, 0.0f,  eyeSepZ), glm::vec3(0, -12, 0)));
	AppendTransformedMesh(eyePart, eyeLensL, TRS(eyeCenter + glm::vec3(0.0f, 0.0f, -eyeSepZ), glm::vec3(0,  12, 0)));
	asset.parts.push_back(std::move(eyePart));

	// 6. ALIS TINTA TEBAL MENEMPEL RENDAH DI ATAS MATA & LUBANG HIDUNG
	SubMesh inkPart;
	inkPart.objectName = "anime_capy_brows_nostrils";
	inkPart.materialName = "mat_ink";

	SubMesh nostril = BuildEllipsoid(0.015f * headScale, 0.016f * headScale, 0.013f * headScale, 6, 8);
	AppendTransformedMesh(inkPart, nostril, TRS(snoutPos + glm::vec3(0.096f * headScale, 0.032f * headScale,  0.048f * headScale)));
	AppendTransformedMesh(inkPart, nostril, TRS(snoutPos + glm::vec3(0.096f * headScale, 0.032f * headScale, -0.048f * headScale)));

	const glm::vec3 browBase = eyeCenter + glm::vec3(0.012f * eyeScale, 0.044f * eyeScale, 0.0f);
	switch (browStyle) {
	case AnimeBrow::AngryV: {
		// Alis MARAH V-tebal menyapu lengkung dahi (dari pangkal hidung menukik ke pelipis luar!)
		const float hs = headScale;
		std::array<glm::vec3, 4> bR = {{
			browBase + glm::vec3( 0.042f * hs, -0.028f * hs,  0.016f * hs),
			browBase + glm::vec3( 0.034f * hs, -0.012f * hs,  0.062f * hs),
			browBase + glm::vec3( 0.010f * hs,  0.016f * hs,  0.114f * hs),
			browBase + glm::vec3(-0.022f * hs,  0.042f * hs,  0.156f * hs)
		}};
		std::array<glm::vec3, 4> bL = {{
			browBase + glm::vec3( 0.042f * hs, -0.028f * hs, -0.016f * hs),
			browBase + glm::vec3( 0.034f * hs, -0.012f * hs, -0.062f * hs),
			browBase + glm::vec3( 0.010f * hs,  0.016f * hs, -0.114f * hs),
			browBase + glm::vec3(-0.022f * hs,  0.042f * hs, -0.156f * hs)
		}};
		AppendTransformedMesh(inkPart, BuildBezierTube(bR, 0.028f * hs, 0.015f * hs, 12, 8, true), glm::mat4(1.0f));
		AppendTransformedMesh(inkPart, BuildBezierTube(bL, 0.028f * hs, 0.015f * hs, 12, 8, true), glm::mat4(1.0f));
		break;
	}
	case AnimeBrow::WildHigh: {
		// Alis menukik agresif ala Dash saat berteriak!
		SubMesh bar = BuildBox(0.030f, 0.026f, 0.104f * headScale);
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.002f, 0.008f,  eyeSepZ - 0.008f), glm::vec3(-22, -24, 0)));
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.002f, 0.008f, -eyeSepZ + 0.008f), glm::vec3( 22,  24, 0)));
		break;
	}
	case AnimeBrow::CuteArch: {
		// Alis nakal miring ke dalam (\ /) untuk Trio Mini yang tengil
		SubMesh bar = BuildBox(0.026f, 0.020f, 0.094f * headScale);
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.0f, 0.002f,  eyeSepZ - 0.004f), glm::vec3(-18, -24, 0)));
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.0f, 0.002f, -eyeSepZ + 0.004f), glm::vec3( 18,  24, 0)));
		break;
	}
	case AnimeBrow::FierceSlope: {
		// Alis datar berat / malas-sumbu-pendek duduk tepat di atas kelopak setengah tertutup
		SubMesh bar = BuildBox(0.032f, 0.024f, 0.108f * headScale);
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.002f, 0.006f,  eyeSepZ - 0.008f), glm::vec3(-4, -26, 0)));
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.002f, 0.006f, -eyeSepZ + 0.008f), glm::vec3( 4,  26, 0)));
		break;
	}
	case AnimeBrow::CockyOneUp: {
		// Alis SINIS jelas: satu menekan marah (-24 deg), satu terangkat tinggi sinis (+14 deg)
		SubMesh bar = BuildBox(0.030f, 0.024f, 0.106f * headScale);
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.002f, -0.006f,  eyeSepZ - 0.008f), glm::vec3(-24, -24, 0)));
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.002f,  0.026f, -eyeSepZ + 0.008f), glm::vec3(-14,  24, 0)));
		break;
	}
	case AnimeBrow::HeavyUnibrow: {
		// Alis tunggal tebal duduk jelas tepat di atas kelopak mata Heavy Onsen
		SubMesh bar = BuildBox(0.046f, 0.036f, 0.28f * headScale);
		AppendTransformedMesh(inkPart, bar, TRS(browBase + glm::vec3(0.020f, -0.004f, 0.0f), glm::vec3(0, 0, -4)));
		break;
	}
	}
	asset.parts.push_back(std::move(inkPart));

	// 7. MULUT ANIME 2.5D EKSPRESIF (Contour-Hugging Snout Shells — menempel sempurna & terbaca tajam!)
	const float hs = headScale;
	SubMesh mouthCav;   mouthCav.objectName = "anime_mouth";   mouthCav.materialName = "mat_mouth_dark";
	SubMesh tonguePart; tonguePart.objectName = "anime_tongue"; tonguePart.materialName = "mat_tongue";
	SubMesh teethPart;  teethPart.objectName = "anime_teeth";  teethPart.materialName = "mat_white";
	SubMesh lipRimPart; lipRimPart.objectName = "anime_lip_rim"; lipRimPart.materialName = "mat_ink";

	switch (mouthStyle) {
	case AnimeMouth::HeroRoar: {
		// CHILL CAPI: Mulut mengaum lebar dramatis memeluk lengkung moncong + taring atas/bawah + lidah pink!
		auto botC = [](float u) { float d = (u - 0.5f) * 2.0f; return -0.68f + 0.26f * d * d; };
		auto topC = [](float u) { float d = (u - 0.5f) * 2.0f; return -0.06f - 0.24f * d * d; };
		// Bingkai bibir gelap tegas
		AppendTransformedMesh(lipRimPart, BuildSnoutMouthPatch(snoutPos, hs, -0.58f, 0.58f,
			[&](float u) { return botC(u) - 0.055f; }, [&](float u) { return topC(u) + 0.055f; }, 0.0030f * hs, 18, 6), glm::mat4(1.0f));
		// Rongga mulut gelap bagian dalam
		AppendTransformedMesh(mouthCav, BuildSnoutMouthPatch(snoutPos, hs, -0.51f, 0.51f, botC, topC, 0.0052f * hs, 18, 6), glm::mat4(1.0f));
		// Lidah merah muda melengkung di dasar mulut
		AppendTransformedMesh(tonguePart, BuildSnoutMouthPatch(snoutPos, hs, -0.34f, 0.34f,
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.64f + 0.14f * d * d; },
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.38f - 0.14f * d * d; }, 0.0074f * hs, 14, 5), glm::mat4(1.0f));
		// Barisan gigi atas putih bersih + 2 taring atas + 2 taring bawah (identik Key-Art 2D!)
		AppendTransformedMesh(teethPart, BuildSnoutMouthPatch(snoutPos, hs, -0.40f, 0.40f,
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.18f - 0.12f * d * d; },
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.06f - 0.18f * d * d; }, 0.0086f * hs, 14, 3), glm::mat4(1.0f));
		AppendTransformedMesh(teethPart, BuildSnoutMouthPatch(snoutPos, hs, -0.34f, 0.34f,
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.66f + 0.18f * d * d; },
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.56f + 0.10f * d * d; }, 0.0086f * hs, 12, 3), glm::mat4(1.0f));
		// 4 taring runcing menempel rapat pada sudut barisan gigi
		for (float sgn : { -1.0f, 1.0f }) {
			glm::vec3 upP, upN, loP, loN;
			EvalSnoutSurface(snoutPos, hs, sgn * 0.31f, -0.22f, 0.009f * hs, upP, upN);
			EvalSnoutSurface(snoutPos, hs, sgn * 0.27f, -0.56f, 0.009f * hs, loP, loN);
			AppendTransformedMesh(teethPart, BuildCone(0.014f * hs, 0.032f * hs, 8), TRS(upP, glm::vec3(0, 0, 180)));
			AppendTransformedMesh(teethPart, BuildCone(0.012f * hs, 0.026f * hs, 8), TRS(loP, glm::vec3(0, 0, 0)));
		}
		break;
	}
	case AnimeMouth::OpenShout: {
		// DASH CAPI: Mulut teriak energi tinggi melengkung rapat mengikuti moncong (NOL benjolan bola!)
		auto botC = [](float u) { float d = (u - 0.5f) * 2.0f; return -0.64f + 0.28f * d * d; };
		auto topC = [](float u) { float d = (u - 0.5f) * 2.0f; return -0.08f - 0.22f * d * d; };
		AppendTransformedMesh(lipRimPart, BuildSnoutMouthPatch(snoutPos, hs, -0.50f, 0.50f,
			[&](float u) { return botC(u) - 0.055f; }, [&](float u) { return topC(u) + 0.055f; }, 0.0030f * hs, 16, 6), glm::mat4(1.0f));
		AppendTransformedMesh(mouthCav, BuildSnoutMouthPatch(snoutPos, hs, -0.44f, 0.44f, botC, topC, 0.0052f * hs, 16, 6), glm::mat4(1.0f));
		// Gigi atas putih cerah + lidah pink
		AppendTransformedMesh(teethPart, BuildSnoutMouthPatch(snoutPos, hs, -0.35f, 0.35f,
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.21f - 0.10f * d * d; },
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.09f - 0.16f * d * d; }, 0.0082f * hs, 12, 3), glm::mat4(1.0f));
		AppendTransformedMesh(tonguePart, BuildSnoutMouthPatch(snoutPos, hs, -0.28f, 0.28f,
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.60f + 0.14f * d * d; },
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.39f - 0.12f * d * d; }, 0.0074f * hs, 12, 4), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::CatSmile: {
		// TRIO MINI-CAPI: Senyum nyengir putih lebar tengil melengkung ke atas (persis Trio Mini 2D!)
		auto botC = [](float u) { float d = (u - 0.5f) * 2.0f; return -0.52f + 0.36f * d * d; };
		auto topC = [](float u) { float d = (u - 0.5f) * 2.0f; return -0.24f + 0.10f * d * d; };
		AppendTransformedMesh(lipRimPart, BuildSnoutMouthPatch(snoutPos, hs, -0.58f, 0.58f,
			[&](float u) { return botC(u) - 0.055f; }, [&](float u) { return topC(u) + 0.055f; }, 0.0032f * hs, 16, 5), glm::mat4(1.0f));
		AppendTransformedMesh(teethPart, BuildSnoutMouthPatch(snoutPos, hs, -0.51f, 0.51f, botC, topC, 0.0064f * hs, 16, 5), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::SmugSide: {
		// SEED-BLASTER: Nyengir koboi sinis putih asimetris naik tajam di pipi kanan (persis 2D!)
		auto botC = [](float u) {
			float tilt = (u - 0.35f) * 0.36f;
			float arch = (u - 0.5f) * (u - 0.5f) * 0.65f;
			return -0.50f + tilt + arch;
		};
		auto topC = [](float u) {
			float tilt = (u - 0.35f) * 0.36f;
			float arch = (u - 0.5f) * (u - 0.5f) * 0.25f;
			return -0.24f + tilt + arch;
		};
		AppendTransformedMesh(lipRimPart, BuildSnoutMouthPatch(snoutPos, hs, -0.34f, 0.64f,
			[&](float u) { return botC(u) - 0.052f; }, [&](float u) { return topC(u) + 0.052f; }, 0.0032f * hs, 16, 5), glm::mat4(1.0f));
		AppendTransformedMesh(teethPart, BuildSnoutMouthPatch(snoutPos, hs, -0.28f, 0.58f, botC, topC, 0.0064f * hs, 16, 5), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::GrumpySmirk: {
		// YUZU BOMB: Cemberut turun berat tebal menempel moncong + celah hidung khas kapibara
		AppendTransformedMesh(lipRimPart, BuildSnoutLipCurve(snoutPos, hs, -0.52f, 0.52f,
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.24f - 0.24f * d * d; },
			0.013f * hs, 0.0045f * hs, 14), glm::mat4(1.0f));
		// Garis belah bibir atas vertikal menuju pangkal hidung
		glm::vec3 pTop, nTop, pBot, nBot;
		EvalSnoutSurface(snoutPos, hs, 0.0f,  0.04f, 0.004f * hs, pTop, nTop);
		EvalSnoutSurface(snoutPos, hs, 0.0f, -0.24f, 0.004f * hs, pBot, nBot);
		AppendTransformedMesh(lipRimPart, BuildBezierTube({{ pTop, glm::mix(pTop, pBot, 0.33f), glm::mix(pTop, pBot, 0.67f), pBot }},
			0.009f * hs, 0.010f * hs, 6, 7, true), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::FierceGrin: {
		// BAMBU-KATANA: Garis bibir datar-tegas serius + bayangan bibir bawah tajam
		AppendTransformedMesh(lipRimPart, BuildSnoutLipCurve(snoutPos, hs, -0.52f, 0.52f,
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.28f - 0.14f * d * d; },
			0.013f * hs, 0.0048f * hs, 14), glm::mat4(1.0f));
		// Garis dagu pendek halus di bawah bibir
		AppendTransformedMesh(mouthCav, BuildSnoutLipCurve(snoutPos, hs, -0.20f, 0.20f,
			[](float) { return -0.46f; },
			0.007f * hs, 0.0038f * hs, 8), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::HeavyFangs: {
		// HEAVY ONSEN: Mulut sumo cemberut rapi + 2 taring gading kokoh tepat di bawah kumis putih!
		AppendTransformedMesh(lipRimPart, BuildSnoutLipCurve(snoutPos, hs, -0.54f, 0.54f,
			[](float u) { float d = (u - 0.5f) * 2.0f; return -0.32f - 0.16f * d * d; },
			0.015f * hs, 0.0045f * hs, 14), glm::mat4(1.0f));
		for (float sgn : { -1.0f, 1.0f }) {
			glm::vec3 tp, tn;
			EvalSnoutSurface(snoutPos, hs, sgn * 0.36f, -0.44f, 0.016f * hs, tp, tn);
			AppendTransformedMesh(teethPart, BuildCone(0.022f * hs, 0.068f * hs, 10),
				TRS(tp, glm::vec3(sgn * -10.0f, 0.0f, 168.0f)));
		}
		break;
	}
	}
	if (!lipRimPart.vertices.empty()) asset.parts.push_back(std::move(lipRimPart));
	if (!mouthCav.vertices.empty())   asset.parts.push_back(std::move(mouthCav));
	if (!tonguePart.vertices.empty()) asset.parts.push_back(std::move(tonguePart));
	if (!teethPart.vertices.empty())  asset.parts.push_back(std::move(teethPart));

	// 8. Simbol urat marah anime merah di pelipis (opsional!)
	if (hasAngerMark) {
		AddUniqueMaterial(asset, MakeMat("mat_anger", "tex_anime_anger.bmp", glm::vec3(1.0f), glm::vec3(0.4f, 0.05f, 0.05f)));
		SubMesh angerPart;
		angerPart.objectName = "anime_anger_mark";
		angerPart.materialName = "mat_anger";
		AppendTransformedMesh(angerPart, BuildAngerVeinMark(), TRS(headPos + glm::vec3(0.04f * headScale, 0.14f * headScale, 0.21f * headScale), glm::vec3(0, -15, 0)));
		asset.parts.push_back(std::move(angerPart));
	}
}
} // namespace

const std::vector<CapyInfo>& GetCapyAnimeW12Roster() {
	static const std::vector<CapyInfo> roster = {
		{ CapyVariant::Chill,       "anime_capy_chill",        "Anime Chill Capi",        "W1 (1-1) - Merah + Syal" },
		{ CapyVariant::Dash,        "anime_capy_dash",         "Anime Dash Capi",         "W1 (1-6) - Kuning + Goggles" },
		{ CapyVariant::Mini,        "anime_capy_mini",         "Anime Trio Mini-Capi",    "W1 (1-11) - Biru Langit + Baling2" },
		{ CapyVariant::YuzuBomb,    "anime_capy_yuzu_bomb",    "Anime Yuzu Bomb Capi",    "W2 (2-1) - Espresso + Yuzu Api" },
		{ CapyVariant::SeedBlaster, "anime_capy_seed_blaster", "Anime Seed-Blaster Capi", "W2 (2-6) - Karamel + Visor" },
		{ CapyVariant::BambuSaber,  "anime_capy_katana",       "Anime Bambu-Katana Capi", "W2 (2-11) - Krem + Katana Baja" },
		{ CapyVariant::HeavyOnsen,  "anime_capy_heavy_onsen",  "Anime Heavy Onsen Capi",  "W2 (2-16) - Marun Sumo + Batu" }
	};
	return roster;
}

ModelAsset BuildCapybaraAnimeW12(CapyVariant variant) {
	ModelAsset asset;

	switch (variant) {
	// 1. CHILL CAPI: Merah Crimson Pekat + Mulut Mengaum Heroik + Syal + Jambul + Urat Marah
	case CapyVariant::Chill: {
		asset.modelName = "anime_capy_chill";
		BuildAnimeCapyCore(asset, "mat_fur_crimson", "tex_capy_crimson.bmp", "tex_anime_eye_chill.bmp",
			glm::vec3(1.0f, 1.0f, 1.0f), 1.08f, 1.15f, AnimeBrow::AngryV, AnimeMouth::HeroRoar, true);

		AddUniqueMaterial(asset, MakeMat("mat_scarf_red", "tex_anime_scarf_red.bmp"));
		SubMesh scarf;
		scarf.objectName = "acc_anime_scarf";
		scarf.materialName = "mat_scarf_red";
		AppendTransformedMesh(scarf, BuildTorus(0.18f, 0.042f, 22, 10), TRS(glm::vec3(0.08f, 0.03f, 0.0f), glm::vec3(0, 0, -35)));
		std::array<glm::vec3, 4> tail = {{ {0.02f,0.06f,0.10f}, {-0.14f,0.11f,0.16f}, {-0.32f,0.05f,0.20f}, {-0.48f,0.10f,0.16f} }};
		AppendTransformedMesh(scarf, BuildBezierTube(tail, 0.048f, 0.022f), glm::mat4(1.0f));
		asset.parts.push_back(std::move(scarf));

		// Jambul bulu merah crimson runcing kecil di puncak kepala
		SubMesh tuft;
		tuft.objectName = "acc_chill_tuft";
		tuft.materialName = "mat_fur_crimson";
		AppendTransformedMesh(tuft, BuildCone(0.042f, 0.115f, 8), TRS(glm::vec3(0.18f, 0.355f, 0.0f), glm::vec3(0, 0, 22)));
		AppendTransformedMesh(tuft, BuildCone(0.032f, 0.090f, 8), TRS(glm::vec3(0.14f, 0.345f, 0.035f), glm::vec3(12, 0, 36)));
		AppendTransformedMesh(tuft, BuildCone(0.032f, 0.090f, 8), TRS(glm::vec3(0.14f, 0.345f,-0.035f), glm::vec3(-12, 0, 36)));
		asset.parts.push_back(std::move(tuft));
		break;
	}

	// 2. DASH CAPI: Warna Kuning #2 + Ramping Panjang + Rambut Runcing + Goggles + Mulut Teriak
	case CapyVariant::Dash: {
		asset.modelName = "anime_capy_dash";
		BuildAnimeCapyCore(asset, "mat_fur_yellow", "tex_capy_yellow.bmp", "tex_anime_eye_dash.bmp",
			glm::vec3(1.16f, 0.88f, 0.88f), 1.02f, 1.18f, AnimeBrow::WildHigh, AnimeMouth::OpenShout, false);

		AddUniqueMaterial(asset, MakeMat("mat_hair_blonde", "tex_hair_blonde.bmp"));
		SubMesh hair;
		hair.objectName = "acc_dash_anime_hair";
		hair.materialName = "mat_hair_blonde";
		AppendTransformedMesh(hair, BuildCone(0.062f, 0.18f, 10), TRS(glm::vec3(0.14f, 0.35f, 0.0f), glm::vec3(0, 0, 26)));
		AppendTransformedMesh(hair, BuildCone(0.045f, 0.14f, 10), TRS(glm::vec3(0.06f, 0.33f, 0.05f), glm::vec3(12, 0, 44)));
		AppendTransformedMesh(hair, BuildCone(0.045f, 0.14f, 10), TRS(glm::vec3(0.06f, 0.33f,-0.05f), glm::vec3(-12,0, 44)));
		asset.parts.push_back(std::move(hair));

		AddUniqueMaterial(asset, MakeMat("mat_scarf_red", "tex_anime_scarf_red.bmp"));
		SubMesh band;
		band.objectName = "acc_dash_headband";
		band.materialName = "mat_scarf_red";
		AppendTransformedMesh(band, BuildTorus(0.185f, 0.022f, 24, 10), TRS(glm::vec3(0.16f, 0.21f, 0.0f), glm::vec3(0, 0, -20), glm::vec3(1.06f, 1.0f, 0.98f)));
		std::array<glm::vec3, 4> t1 = {{ {0.02f,0.23f,0.03f}, {-0.14f,0.31f,0.09f}, {-0.30f,0.22f,0.14f}, {-0.45f,0.26f,0.11f} }};
		std::array<glm::vec3, 4> t2 = {{ {0.02f,0.23f,-0.03f}, {-0.14f,0.26f,-0.09f}, {-0.30f,0.17f,-0.12f}, {-0.43f,0.19f,-0.10f} }};
		AppendTransformedMesh(band, BuildBezierTube(t1, 0.022f, 0.008f), glm::mat4(1.0f));
		AppendTransformedMesh(band, BuildBezierTube(t2, 0.022f, 0.008f), glm::mat4(1.0f));
		asset.parts.push_back(std::move(band));

		AddUniqueMaterial(asset, MakeMat("mat_visor", "tex_visor_orange.bmp", glm::vec3(1.0f), glm::vec3(0.2f, 0.08f, 0.0f)));
		SubMesh gog;
		gog.objectName = "acc_dash_goggles";
		gog.materialName = "mat_visor";
		AppendTransformedMesh(gog, BuildCylinder(0.048f, 0.048f, 0.038f, 14), TRS(glm::vec3(0.27f, 0.295f,  0.085f), glm::vec3(0, 15, -52)));
		AppendTransformedMesh(gog, BuildCylinder(0.048f, 0.048f, 0.038f, 14), TRS(glm::vec3(0.27f, 0.295f, -0.085f), glm::vec3(0,-15, -52)));
		asset.parts.push_back(std::move(gog));
		break;
	}

	// 3. TRIO MINI-CAPI: Warna Biru Langit #2 + Chibi Imut + Topi Baling-baling
	case CapyVariant::Mini: {
		asset.modelName = "anime_capy_mini";
		BuildAnimeCapyCore(asset, "mat_fur_sky", "tex_capy_sky.bmp", "tex_anime_eye_mini.bmp",
			glm::vec3(0.72f, 0.74f, 0.74f), 0.88f, 1.05f, AnimeBrow::CuteArch, AnimeMouth::CatSmile, false);

		AddUniqueMaterial(asset, MakeMat("mat_scarf_blue", "tex_anime_scarf_blue.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_gold", "tex_accent_gold.bmp"));
		SubMesh cap;
		cap.objectName = "acc_mini_prop_cap";
		cap.materialName = "mat_scarf_blue";
		AppendTransformedMesh(cap, BuildEllipsoid(0.115f, 0.065f, 0.115f, 10, 14), TRS(glm::vec3(0.10f, 0.26f, 0.0f)));
		AppendTransformedMesh(cap, BuildTorus(0.14f, 0.028f, 20, 8), TRS(glm::vec3(0.06f, 0.02f, 0.0f), glm::vec3(0, 0, -32)));
		asset.parts.push_back(std::move(cap));

		SubMesh prop;
		prop.objectName = "acc_mini_propeller";
		prop.materialName = "mat_gold";
		AppendTransformedMesh(prop, BuildCylinder(0.014f, 0.014f, 0.045f, 10), TRS(glm::vec3(0.10f, 0.33f, 0.0f)));
		AppendTransformedMesh(prop, BuildBox(0.22f, 0.014f, 0.036f), TRS(glm::vec3(0.10f, 0.35f, 0.0f), glm::vec3(0, 25, 0)));
		AppendTransformedMesh(prop, BuildBox(0.036f, 0.014f, 0.22f), TRS(glm::vec3(0.10f, 0.35f, 0.0f), glm::vec3(0, 25, 0)));
		asset.parts.push_back(std::move(prop));
		break;
	}

	// 4. YUZU BOMB CAPI: Kapibara Espresso Bulat Gemuk + Mulut Cemberut Berat + Jeruk Yuzu + Sumbu Api
	case CapyVariant::YuzuBomb: {
		asset.modelName = "anime_capy_yuzu_bomb";
		BuildAnimeCapyCore(asset, "mat_fur_espresso", "tex_anime_fur_espresso.bmp", "tex_anime_eye_bomb.bmp",
			glm::vec3(1.02f, 1.12f, 1.15f), 1.12f, 1.18f, AnimeBrow::FierceSlope, AnimeMouth::GrumpySmirk, true);

		AddUniqueMaterial(asset, MakeMat("mat_yuzu", "tex_yuzu.bmp", glm::vec3(1.0f), glm::vec3(0.35f, 0.18f, 0.0f)));
		AddUniqueMaterial(asset, MakeMat("mat_spark", "tex_fuse_spark.bmp", glm::vec3(1.0f), glm::vec3(0.85f, 0.45f, 0.05f)));
		AddUniqueMaterial(asset, MakeMat("mat_wood", "tex_wood.bmp"));

		SubMesh yuzuPart;
		yuzuPart.objectName = "acc_yuzu_fruit";
		yuzuPart.materialName = "mat_yuzu";
		std::array<glm::vec2, 4> yuzuProf = {{ {0.0f,-0.12f}, {0.16f,-0.09f}, {0.15f,0.09f}, {0.0f,0.13f} }};
		AppendTransformedMesh(yuzuPart, BuildBezierRevolvedProfile(yuzuProf, 16, 18), TRS(glm::vec3(0.14f, 0.45f, 0.0f), glm::vec3(0, 0, 90)));
		asset.parts.push_back(std::move(yuzuPart));

		SubMesh fusePart;
		fusePart.objectName = "acc_yuzu_fuse";
		fusePart.materialName = "mat_wood";
		std::array<glm::vec3, 4> fCurve = {{ {0.14f,0.56f,0.0f}, {0.13f,0.66f,0.03f}, {0.05f,0.71f,0.05f}, {-0.01f,0.67f,0.02f} }};
		AppendTransformedMesh(fusePart, BuildBezierTube(fCurve, 0.020f, 0.014f), glm::mat4(1.0f));
		asset.parts.push_back(std::move(fusePart));

		SubMesh sparkPart;
		sparkPart.objectName = "acc_yuzu_spark";
		sparkPart.materialName = "mat_spark";
		AppendTransformedMesh(sparkPart, BuildEllipsoid(0.058f, 0.058f, 0.058f, 8, 10), TRS(glm::vec3(-0.01f, 0.67f, 0.02f)));
		AppendTransformedMesh(sparkPart, BuildCone(0.026f, 0.095f, 8), TRS(glm::vec3(-0.01f, 0.74f, 0.02f)));
		asset.parts.push_back(std::move(sparkPart));
		break;
	}

	// 5. SEED-BLASTER CAPI: Warna Karamel #2 + Topi Petualang + Visor Bidik Anime + Double Blaster
	case CapyVariant::SeedBlaster: {
		asset.modelName = "anime_capy_seed_blaster";
		BuildAnimeCapyCore(asset, "mat_fur_caramel", "tex_capy_caramel.bmp", "tex_anime_eye_dash.bmp",
			glm::vec3(1.04f, 1.0f, 0.98f), 1.04f, 1.10f, AnimeBrow::CockyOneUp, AnimeMouth::SmugSide, false);

		AddUniqueMaterial(asset, MakeMat("mat_wood", "tex_wood.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_gold", "tex_accent_gold.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_stone", "tex_stone.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_visor", "tex_visor_orange.bmp", glm::vec3(1.0f), glm::vec3(0.22f, 0.08f, 0.0f)));

		SubMesh hat;
		hat.objectName = "acc_hat";
		hat.materialName = "mat_wood";
		AppendTransformedMesh(hat, BuildCylinder(0.30f, 0.29f, 0.026f, 20), TRS(glm::vec3(0.13f, 0.365f, 0.0f), glm::vec3(0, 0, -14)));
		AppendTransformedMesh(hat, BuildCylinder(0.15f, 0.115f, 0.14f, 18),  TRS(glm::vec3(0.14f, 0.435f, 0.0f), glm::vec3(0, 0, -14)));
		asset.parts.push_back(std::move(hat));

		SubMesh gold;
		gold.objectName = "acc_gold_gear";
		gold.materialName = "mat_gold";
		AppendTransformedMesh(gold, BuildCylinder(0.156f, 0.148f, 0.032f, 18), TRS(glm::vec3(0.135f, 0.390f, 0.0f), glm::vec3(0, 0, -14)));
		AppendTransformedMesh(gold, BuildTorus(0.31f, 0.022f, 24, 10), TRS(glm::vec3(-0.04f, -0.04f, 0.0f), glm::vec3(0, 0, 38)));
		asset.parts.push_back(std::move(gold));

		SubMesh visor;
		visor.objectName = "acc_visor";
		visor.materialName = "mat_visor";
		// Bingkai scouter terbuka yang menggantung di pinggir topi agar mata sinis tetap terlihat jelas!
		AppendTransformedMesh(visor, BuildTorus(0.056f, 0.010f, 16, 8), TRS(glm::vec3(0.35f, 0.225f, 0.145f), glm::vec3(0, -24, 90)));
		AppendTransformedMesh(visor, BuildBox(0.018f, 0.085f, 0.018f), TRS(glm::vec3(0.30f, 0.285f, 0.155f), glm::vec3(0, 0, -25)));
		asset.parts.push_back(std::move(visor));

		SubMesh blaster;
		blaster.objectName = "acc_blaster";
		blaster.materialName = "mat_stone";
		AppendTransformedMesh(blaster, BuildCylinder(0.032f, 0.038f, 0.38f, 14), TRS(glm::vec3(0.18f, 0.01f, 0.36f), glm::vec3(0, 0, -90)));
		AppendTransformedMesh(blaster, BuildCylinder(0.032f, 0.038f, 0.34f, 14), TRS(glm::vec3(0.16f,-0.05f, 0.36f), glm::vec3(0, 0, -90)));
		AppendTransformedMesh(blaster, BuildBox(0.14f, 0.10f, 0.085f), TRS(glm::vec3(0.04f,-0.02f, 0.35f)));
		asset.parts.push_back(std::move(blaster));
		break;
	}

	// 6. BAMBU-KATANA CAPI: Warna Krem Jedi #2 + Poni Anime Pirang + Katana Baja Lengkung!
	case CapyVariant::BambuSaber: {
		asset.modelName = "anime_capy_katana";
		BuildAnimeCapyCore(asset, "mat_fur_jedi", "tex_capy_jedi.bmp", "tex_anime_eye_katana.bmp",
			glm::vec3(1.02f, 0.98f, 0.96f), 1.04f, 1.14f, AnimeBrow::AngryV, AnimeMouth::FierceGrin, false);

		AddUniqueMaterial(asset, MakeMat("mat_hair_blonde", "tex_hair_blonde.bmp"));
		SubMesh hair;
		hair.objectName = "acc_anime_ronin_hair";
		hair.materialName = "mat_hair_blonde";
		std::array<glm::vec3, 4> b1 = {{ {0.06f,0.37f,0.0f}, {0.16f,0.40f,0.10f}, {0.23f,0.36f,0.18f}, {0.26f,0.30f,0.22f} }};
		std::array<glm::vec3, 4> b2 = {{ {0.06f,0.37f,0.0f}, {0.16f,0.40f,-0.10f}, {0.23f,0.36f,-0.18f}, {0.26f,0.30f,-0.22f} }};
		AppendTransformedMesh(hair, BuildEllipsoid(0.16f, 0.068f, 0.18f, 10, 14), TRS(glm::vec3(0.12f, 0.34f, 0.0f), glm::vec3(0, 0, -6)));
		AppendTransformedMesh(hair, BuildBezierTube(b1, 0.040f, 0.014f), glm::mat4(1.0f));
		AppendTransformedMesh(hair, BuildBezierTube(b2, 0.040f, 0.014f), glm::mat4(1.0f));
		asset.parts.push_back(std::move(hair));

		AddUniqueMaterial(asset, MakeMat("mat_bamboo", "tex_bamboo.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_gold", "tex_accent_gold.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_katana_steel", "tex_katana_steel.bmp", glm::vec3(1.0f), glm::vec3(0.10f), 110.0f));

		const glm::mat4 katanaXf = TRS(glm::vec3(0.12f, -0.06f, 0.37f), glm::vec3(10, 0, -52));
		SubMesh hilt;
		hilt.objectName = "acc_katana_hilt";
		hilt.materialName = "mat_bamboo";
		AppendTransformedMesh(hilt, BuildCylinder(0.026f, 0.028f, 0.22f, 12), katanaXf);
		asset.parts.push_back(std::move(hilt));

		SubMesh tsuba;
		tsuba.objectName = "acc_katana_tsuba";
		tsuba.materialName = "mat_gold";
		AppendTransformedMesh(tsuba, BuildCylinder(0.062f, 0.062f, 0.020f, 16), katanaXf * TRS(glm::vec3(0.0f, 0.115f, 0.0f)));
		asset.parts.push_back(std::move(tsuba));

		SubMesh blade;
		blade.objectName = "acc_katana_blade";
		blade.materialName = "mat_katana_steel";
		std::array<glm::vec3, 4> bladeCurve = {{
			{ 0.000f, 0.125f, 0.0f }, { 0.008f, 0.36f, 0.0f }, { 0.034f, 0.58f, 0.0f }, { 0.086f, 0.80f, 0.0f }
		}};
		AppendTransformedMesh(blade, BuildBezierTube(bladeCurve, 0.028f, 0.008f, 16, 10, true),
			katanaXf * TRS(glm::vec3(0.0f), glm::vec3(0.0f), glm::vec3(1.1f, 1.0f, 0.24f)));
		asset.parts.push_back(std::move(blade));
		break;
	}

	// 7. HEAVY ONSEN CAPI: Warna Marun #2 + Raksasa Chonky Diperbesar + Alis Menyatu + Taring + Kumis + Batu
	case CapyVariant::HeavyOnsen: {
		asset.modelName = "anime_capy_heavy_onsen";
		BuildAnimeCapyCore(asset, "mat_fur_maroon", "tex_capy_maroon.bmp", "tex_anime_eye_heavy.bmp",
			glm::vec3(1.34f, 1.28f, 1.42f), 1.26f, 1.12f, AnimeBrow::HeavyUnibrow, AnimeMouth::HeavyFangs, true);

		AddUniqueMaterial(asset, MakeMat("mat_towel", "tex_towel.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_stone", "tex_stone.bmp"));

		SubMesh mustache;
		mustache.objectName = "acc_heavy_mustache";
		mustache.materialName = "mat_white";
		// Kumis handlebar putih menempel rapi tepat di bawah lubang hidung Heavy Onsen (melengkung gagah!)
		std::array<glm::vec3, 4> stL = {{ {0.575f, 0.110f,  0.025f}, {0.585f, 0.088f,  0.140f}, {0.535f, 0.035f,  0.255f}, {0.465f, 0.082f,  0.325f} }};
		std::array<glm::vec3, 4> stR = {{ {0.575f, 0.110f, -0.025f}, {0.585f, 0.088f, -0.140f}, {0.535f, 0.035f, -0.255f}, {0.465f, 0.082f, -0.325f} }};
		AppendTransformedMesh(mustache, BuildBezierTube(stL, 0.040f, 0.012f, 14, 10, true), glm::mat4(1.0f));
		AppendTransformedMesh(mustache, BuildBezierTube(stR, 0.040f, 0.012f, 14, 10, true), glm::mat4(1.0f));
		asset.parts.push_back(std::move(mustache));

		SubMesh towel;
		towel.objectName = "acc_heavy_towel";
		towel.materialName = "mat_towel";
		// Handuk onsen lipat empuk & ringkas pas di antara telinga (bukan papan putih raksasa!)
		AppendTransformedMesh(towel, BuildEllipsoid(0.18f, 0.042f, 0.17f, 10, 16), TRS(glm::vec3(0.14f, 0.40f, 0.0f), glm::vec3(0, 0, -4)));
		asset.parts.push_back(std::move(towel));

		SubMesh stone;
		stone.objectName = "acc_onsen_stone";
		stone.materialName = "mat_stone";
		AppendTransformedMesh(stone, BuildEllipsoid(0.125f, 0.070f, 0.115f, 12, 16), TRS(glm::vec3(0.14f, 0.465f, 0.0f), glm::vec3(0, 0, -4)));
		asset.parts.push_back(std::move(stone));
		break;
	}
	}

	return asset;
}

std::vector<ModelAsset> BuildAllCapybarasAnimeW12() {
	std::vector<ModelAsset> out;
	const auto& roster = GetCapyAnimeW12Roster();
	out.reserve(roster.size());
	for (const auto& info : roster) {
		out.push_back(BuildCapybaraAnimeW12(info.variant));
	}
	return out;
}

namespace {
SubMesh BuildDisplacedOrganicEllipsoid(float rx, float ry, float rz, int stacks, int slices, float amp, float freq, float phase, bool flattenBottom) {
	SubMesh m = BuildEllipsoid(rx, ry, rz, stacks, slices);
	for (auto& v : m.vertices) {
		glm::vec3 d = glm::normalize(glm::vec3(v.pos.x / rx, v.pos.y / ry, v.pos.z / rz) + glm::vec3(1e-5f));
		float w = std::sin(d.x * freq + phase) * std::cos(d.y * (freq * 0.9f) - phase * 0.7f)
		        + 0.55f * std::sin((d.z * freq * 1.4f) + d.x * 2.1f + phase * 1.3f);
		float s = 1.0f + amp * w;
		v.pos.x *= s;
		v.pos.y *= s;
		v.pos.z *= s;
		if (flattenBottom && v.pos.y < -0.18f * ry) {
			v.pos.y = -0.18f * ry + (v.pos.y + 0.18f * ry) * 0.15f;
		}
	}
	// Hitung ulang normal halus berdasarkan segitiga
	for (auto& v : m.vertices) v.normal = glm::vec3(0.0f);
	for (size_t i = 0; i + 2 < m.indices.size(); i += 3) {
		auto& v0 = m.vertices[m.indices[i]];
		auto& v1 = m.vertices[m.indices[i + 1]];
		auto& v2 = m.vertices[m.indices[i + 2]];
		glm::vec3 fn = glm::cross(v1.pos - v0.pos, v2.pos - v0.pos);
		v0.normal += fn; v1.normal += fn; v2.normal += fn;
	}
	for (auto& v : m.vertices) {
		float len = glm::length(v.normal);
		v.normal = (len > 1e-6f) ? (v.normal / len) : glm::vec3(0, 1, 0);
	}
	return m;
}
} // namespace

std::vector<ModelAsset> BuildAllHomeKeyArtAssets() {
	std::vector<ModelAsset> out;

	// 1. BUKIT VOLKANIK-ONSEN ORGANIK TUNGGAL (pengganti silinder & lantai neon datar)
	{
		ModelAsset hill;
		hill.modelName = "home_stage_hill";
		AddUniqueMaterial(hill, MakeMat("mat_home_hill", "tex_home_hill.bmp", glm::vec3(1.0f), glm::vec3(0.0f), 10.0f));
		SubMesh dome = BuildDisplacedOrganicEllipsoid(4.85f, 1.55f, 2.75f, 22, 36, 0.055f, 4.8f, 0.6f, true);
		dome.objectName = "home_hill_mound";
		dome.materialName = "mat_home_hill";
		// Tambah beberapa tonjolan batu organik di kiri/kanan lereng bukit
		AppendTransformedMesh(dome, BuildDisplacedOrganicEllipsoid(1.15f, 0.55f, 0.95f, 10, 14, 0.12f, 5.2f, 1.7f, true),
			TRS(glm::vec3(-3.35f, 0.25f, 0.55f), glm::vec3(4, 18, -10)));
		AppendTransformedMesh(dome, BuildDisplacedOrganicEllipsoid(1.25f, 0.60f, 1.05f, 10, 14, 0.12f, 4.9f, 2.9f, true),
			TRS(glm::vec3(3.45f, 0.22f, 0.45f), glm::vec3(-5, -24, 12)));
		hill.parts.push_back(std::move(dome));
		out.push_back(std::move(hill));
	}

	// 2. BULAN YUZU EMAS RAKSASA (pojok kiri atas ala Angry Birds Space!)
	{
		ModelAsset moon;
		moon.modelName = "home_yuzu_moon";
		AddUniqueMaterial(moon, MakeMat("mat_yuzu_moon", "tex_home_yuzu_moon.bmp", glm::vec3(1.0f), glm::vec3(0.75f, 0.62f, 0.18f), 16.0f));
		AddUniqueMaterial(moon, MakeMat("mat_yuzu_leaf", "tex_yuzu_leaf.bmp", glm::vec3(1.0f), glm::vec3(0.08f, 0.22f, 0.05f), 20.0f));
		SubMesh orb = BuildDisplacedOrganicEllipsoid(1.75f, 1.65f, 1.65f, 18, 26, 0.032f, 5.5f, 0.3f, false);
		orb.objectName = "yuzu_moon_orb";
		orb.materialName = "mat_yuzu_moon";
		moon.parts.push_back(std::move(orb));

		SubMesh leaf;
		leaf.objectName = "yuzu_moon_leaf";
		leaf.materialName = "mat_yuzu_leaf";
		AppendTransformedMesh(leaf, BuildEllipsoid(0.65f, 0.16f, 0.28f, 8, 12), TRS(glm::vec3(1.38f, 1.18f, 0.2f), glm::vec3(10, -18, 28)));
		moon.parts.push_back(std::move(leaf));
		out.push_back(std::move(moon));
	}

	// 3. BATU ASTEROID / KARANG MALAM BERSEGI (bingkai langit kiri-kanan)
	{
		ModelAsset rock;
		rock.modelName = "home_rock_silhouette";
		AddUniqueMaterial(rock, MakeMat("mat_rock_dark", "tex_home_rock_dark.bmp", glm::vec3(1.0f), glm::vec3(0.02f, 0.03f, 0.08f), 12.0f));
		SubMesh crag = BuildDisplacedOrganicEllipsoid(0.82f, 0.72f, 0.68f, 12, 16, 0.16f, 4.4f, 2.2f, false);
		crag.objectName = "dark_crag_rock";
		crag.materialName = "mat_rock_dark";
		rock.parts.push_back(std::move(crag));
		out.push_back(std::move(rock));
	}

	// 4. KEY-ART CHILL CAPI ROAR (Merah Pekat Crimson + Jambul Runcing + Syal Berkibar!)
	{
		ModelAsset chill;
		chill.modelName = "home_capy_chill_roar";
		BuildAnimeCapyCore(chill, "mat_fur_crimson", "tex_capy_crimson.bmp", "tex_anime_eye_chill.bmp",
			glm::vec3(1.02f, 1.02f, 1.04f), 1.12f, 1.18f, AnimeBrow::AngryV, AnimeMouth::HeroRoar, true);

		AddUniqueMaterial(chill, MakeMat("mat_scarf_red", "tex_anime_scarf_red.bmp"));
		SubMesh scarf;
		scarf.objectName = "acc_hero_scarf";
		scarf.materialName = "mat_scarf_red";
		AppendTransformedMesh(scarf, BuildTorus(0.19f, 0.048f, 22, 10), TRS(glm::vec3(0.08f, 0.03f, 0.0f), glm::vec3(0, 0, -34)));
		std::array<glm::vec3, 4> t1 = {{ {0.02f,0.04f,0.12f}, {-0.14f,0.04f,0.18f}, {-0.30f,-0.02f,0.20f}, {-0.44f,0.02f,0.15f} }};
		AppendTransformedMesh(scarf, BuildBezierTube(t1, 0.048f, 0.016f), glm::mat4(1.0f));
		chill.parts.push_back(std::move(scarf));

		SubMesh tuft;
		tuft.objectName = "acc_chill_roar_tuft";
		tuft.materialName = "mat_fur_crimson";
		AppendTransformedMesh(tuft, BuildCone(0.046f, 0.125f, 10), TRS(glm::vec3(0.19f, 0.37f, 0.0f), glm::vec3(0, 0, 20)));
		AppendTransformedMesh(tuft, BuildCone(0.036f, 0.098f, 10), TRS(glm::vec3(0.15f, 0.36f, 0.038f), glm::vec3(12, 0, 34)));
		AppendTransformedMesh(tuft, BuildCone(0.036f, 0.098f, 10), TRS(glm::vec3(0.15f, 0.36f,-0.038f), glm::vec3(-12, 0, 34)));
		chill.parts.push_back(std::move(tuft));
		out.push_back(std::move(chill));
	}

	// 5. KEY-ART YUZU BOMB BLAZE (Kobaran api kompak menyala oranye-merah di atas Yuzu!)
	{
		ModelAsset bomb = BuildCapybaraAnimeW12(CapyVariant::YuzuBomb);
		bomb.modelName = "home_capy_bomb_blaze";
		AddUniqueMaterial(bomb, MakeMat("mat_home_flame", "tex_home_flame.bmp", glm::vec3(1.0f), glm::vec3(0.85f, 0.32f, 0.04f), 32.0f));
		SubMesh flame;
		flame.objectName = "acc_blazing_flame";
		flame.materialName = "mat_home_flame";
		std::array<glm::vec3, 4> fl1 = {{ {-0.01f,0.66f,0.02f}, {-0.05f,0.78f,0.03f}, {0.04f,0.92f,0.01f}, {0.11f,1.04f,-0.01f} }};
		std::array<glm::vec3, 4> fl2 = {{ {-0.02f,0.66f,0.04f}, {-0.10f,0.76f,0.08f}, {-0.07f,0.88f,0.06f}, {0.00f,0.96f,0.03f} }};
		std::array<glm::vec3, 4> fl3 = {{ { 0.02f,0.66f,-0.02f}, {0.08f,0.76f,-0.06f}, {0.12f,0.86f,-0.04f}, {0.17f,0.94f,-0.01f} }};
		AppendTransformedMesh(flame, BuildBezierTube(fl1, 0.088f, 0.008f, 16, 12, true), glm::mat4(1.0f));
		AppendTransformedMesh(flame, BuildBezierTube(fl2, 0.064f, 0.008f, 14, 10, true), glm::mat4(1.0f));
		AppendTransformedMesh(flame, BuildBezierTube(fl3, 0.060f, 0.008f, 14, 10, true), glm::mat4(1.0f));
		bomb.parts.push_back(std::move(flame));
		out.push_back(std::move(bomb));
	}

	// 6. KEY-ART DASH LEAP (Tubuh melesat aerodinamis + mulut teriak lebar + jejak kilat emas!)
	{
		ModelAsset dash;
		dash.modelName = "home_capy_dash_leap";
		BuildAnimeCapyCore(dash, "mat_fur_yellow", "tex_capy_yellow.bmp", "tex_anime_eye_dash.bmp",
			glm::vec3(1.26f, 0.84f, 0.84f), 1.04f, 1.20f, AnimeBrow::WildHigh, AnimeMouth::HeroRoar, false);

		AddUniqueMaterial(dash, MakeMat("mat_hair_blonde", "tex_hair_blonde.bmp"));
		SubMesh hair;
		hair.objectName = "acc_dash_hair";
		hair.materialName = "mat_hair_blonde";
		AppendTransformedMesh(hair, BuildCone(0.068f, 0.22f, 10), TRS(glm::vec3(0.14f, 0.35f, 0.0f), glm::vec3(0, 0, 34)));
		AppendTransformedMesh(hair, BuildCone(0.050f, 0.17f, 10), TRS(glm::vec3(0.05f, 0.32f, 0.06f), glm::vec3(14, 0, 50)));
		AppendTransformedMesh(hair, BuildCone(0.050f, 0.17f, 10), TRS(glm::vec3(0.05f, 0.32f,-0.06f), glm::vec3(-14,0, 50)));
		dash.parts.push_back(std::move(hair));

		AddUniqueMaterial(dash, MakeMat("mat_scarf_red", "tex_anime_scarf_red.bmp"));
		SubMesh band;
		band.objectName = "acc_dash_band_long";
		band.materialName = "mat_scarf_red";
		AppendTransformedMesh(band, BuildTorus(0.185f, 0.024f, 24, 10), TRS(glm::vec3(0.16f, 0.21f, 0.0f), glm::vec3(0, 0, -20)));
		std::array<glm::vec3, 4> t1 = {{ {0.02f,0.23f,0.03f}, {-0.24f,0.34f,0.12f}, {-0.54f,0.22f,0.18f}, {-0.84f,0.28f,0.14f} }};
		std::array<glm::vec3, 4> t2 = {{ {0.02f,0.23f,-0.03f}, {-0.22f,0.28f,-0.10f}, {-0.48f,0.16f,-0.15f}, {-0.76f,0.20f,-0.12f} }};
		AppendTransformedMesh(band, BuildBezierTube(t1, 0.028f, 0.008f), glm::mat4(1.0f));
		AppendTransformedMesh(band, BuildBezierTube(t2, 0.024f, 0.008f), glm::mat4(1.0f));
		dash.parts.push_back(std::move(band));

		AddUniqueMaterial(dash, MakeMat("mat_home_speed", "tex_home_speed.bmp", glm::vec3(1.0f), glm::vec3(1.05f, 0.72f, 0.12f), 40.0f));
		SubMesh trail;
		trail.objectName = "acc_dash_speed_trails";
		trail.materialName = "mat_home_speed";
		std::array<glm::vec3, 4> s1 = {{ {0.05f,0.18f,0.24f}, {-0.28f,0.20f,0.28f}, {-0.62f,0.16f,0.26f}, {-0.98f,0.18f,0.22f} }};
		std::array<glm::vec3, 4> s2 = {{ {0.05f,-0.06f,-0.24f}, {-0.28f,-0.05f,-0.28f}, {-0.60f,-0.08f,-0.24f}, {-0.94f,-0.06f,-0.20f} }};
		AppendTransformedMesh(trail, BuildBezierTube(s1, 0.042f, 0.006f, 16, 8, true), glm::mat4(1.0f));
		AppendTransformedMesh(trail, BuildBezierTube(s2, 0.038f, 0.006f, 16, 8, true), glm::mat4(1.0f));
		dash.parts.push_back(std::move(trail));
		out.push_back(std::move(dash));
	}

	// 7. KEY-ART KATANA SLASH (Tebasan sabit bercahaya cyan melengkung di bilah katana!)
	{
		ModelAsset kat = BuildCapybaraAnimeW12(CapyVariant::BambuSaber);
		kat.modelName = "home_capy_katana_slash";
		AddUniqueMaterial(kat, MakeMat("mat_home_slash", "tex_home_slash.bmp", glm::vec3(1.0f), glm::vec3(0.28f, 0.92f, 1.15f), 64.0f));
		SubMesh slash;
		slash.objectName = "acc_katana_energy_arc";
		slash.materialName = "mat_home_slash";
		// Sabit tebasan melengkung menyamping-maju keluar agar tidak memotong wajah Heavy Onsen
		std::array<glm::vec3, 4> arc = {{
			{ 0.28f, -0.06f, 0.42f },
			{ 0.58f,  0.04f, 0.50f },
			{ 0.66f,  0.28f, 0.42f },
			{ 0.36f,  0.48f, 0.26f }
		}};
		AppendTransformedMesh(slash, BuildBezierTube(arc, 0.052f, 0.008f, 18, 10, true),
			TRS(glm::vec3(0.0f), glm::vec3(0.0f), glm::vec3(1.0f, 1.0f, 0.42f)));
		kat.parts.push_back(std::move(slash));
		out.push_back(std::move(kat));
	}

	// 8. KETAPEL BAMBU UKIR 2.5D (prop_slingshot_bamboo.obj — persis seperti di Key-Art Home 2D!)
	{
		ModelAsset sling;
		sling.modelName = "prop_slingshot_bamboo";
		AddUniqueMaterial(sling, MakeMat("mat_bamboo", "tex_bamboo.bmp"));
		AddUniqueMaterial(sling, MakeMat("mat_wood", "tex_wood.bmp"));

		SubMesh woodPart;
		woodPart.objectName = "slingshot_bamboo_body";
		woodPart.materialName = "mat_bamboo";
		// Batang utama melengkung organik
		std::array<glm::vec3, 4> stem = {{ {0.0f,0.0f,0.0f}, {-0.04f,0.42f,0.0f}, {0.03f,0.82f,0.0f}, {0.0f,1.18f,0.0f} }};
		AppendTransformedMesh(woodPart, BuildBezierTube(stem, 0.175f, 0.145f, 14, 14, true), glm::mat4(1.0f));
		// Cabang garpu kiri (+Z) & kanan (-Z) melengkung alami seperti ketapel bambu di Key-Art 2D!
		std::array<glm::vec3, 4> fL = {{ {0.0f,1.08f,0.0f}, {-0.03f,1.42f,0.22f}, {0.02f,1.76f,0.38f}, {0.0f,2.04f,0.44f} }};
		std::array<glm::vec3, 4> fR = {{ {0.0f,1.08f,0.0f}, {-0.03f,1.42f,-0.22f}, {0.02f,1.76f,-0.38f}, {0.0f,2.04f,-0.44f} }};
		AppendTransformedMesh(woodPart, BuildBezierTube(fL, 0.125f, 0.105f, 14, 12, true), glm::mat4(1.0f));
		AppendTransformedMesh(woodPart, BuildBezierTube(fR, 0.125f, 0.105f, 14, 12, true), glm::mat4(1.0f));
		// Ruas cincin bambu khas
		for (float ry : { 0.42f, 0.86f }) {
			AppendTransformedMesh(woodPart, BuildTorus(0.165f, 0.024f, 18, 8), TRS(glm::vec3(0.0f, ry, 0.0f), glm::vec3(90, 0, 0)));
		}
		AppendTransformedMesh(woodPart, BuildTorus(0.115f, 0.022f, 16, 8), TRS(glm::vec3(0.0f, 1.94f,  0.42f), glm::vec3(75, 0, 0)));
		AppendTransformedMesh(woodPart, BuildTorus(0.115f, 0.022f, 16, 8), TRS(glm::vec3(0.0f, 1.94f, -0.42f), glm::vec3(105, 0, 0)));
		sling.parts.push_back(std::move(woodPart));

		// Ikatan tali kulit di pangkal garpu
		SubMesh wrap;
		wrap.objectName = "slingshot_rope_wrap";
		wrap.materialName = "mat_wood";
		AppendTransformedMesh(wrap, BuildTorus(0.16f, 0.045f, 18, 10), TRS(glm::vec3(0.0f, 1.08f, 0.0f), glm::vec3(90, 0, 0)));
		AppendTransformedMesh(wrap, BuildTorus(0.155f, 0.038f, 18, 10), TRS(glm::vec3(0.0f, 1.15f, 0.0f), glm::vec3(84, 0, 0)));
		sling.parts.push_back(std::move(wrap));
		out.push_back(std::move(sling));
	}

	// 9. MUSUH CROCODILE RAIDER 2.5D EKSPRESIF (enemy_croco_minion.obj — sculpt buaya penuh karakter!)
	{
		ModelAsset croco;
		croco.modelName = "enemy_croco_minion";
		AddUniqueMaterial(croco, MakeMat("mat_croco", "tex_croco_green.bmp"));
		AddUniqueMaterial(croco, MakeMat("mat_croco_dark", "tex_croco_scale_dark.bmp"));
		AddUniqueMaterial(croco, MakeMat("mat_croco_belly", "tex_croco_belly.bmp"));
		AddUniqueMaterial(croco, MakeMat("mat_croco_eye", "tex_croco_eye.bmp", glm::vec3(1.0f), glm::vec3(0.08f), 64.0f));
		AddUniqueMaterial(croco, MakeMat("mat_ink", "tex_anime_ink.bmp", glm::vec3(0.14f), glm::vec3(0.0f), 8.0f));
		AddUniqueMaterial(croco, MakeMat("mat_white", "tex_capy_eye_white.bmp"));
		AddUniqueMaterial(croco, MakeMat("mat_mouth_dark", "tex_mouth_dark.bmp"));
		AddUniqueMaterial(croco, MakeMat("mat_tongue", "tex_tongue_pink.bmp"));

		// A. Tubuh utama, kepala, moncong 2-rahang, tonjolan kelopak mata, ekor melengkung, & kaki pendek
		SubMesh body;
		body.objectName = "croco_body";
		body.materialName = "mat_croco";

		// Badan bulat-gempal reptil membungkuk nakal menyatu mulus dengan kepala (menghadap -X ke arah ketapel!)
		AppendTransformedMesh(body, BuildEllipsoid(0.30f, 0.255f, 0.275f, 18, 24), TRS(glm::vec3(0.03f, -0.055f, 0.0f), glm::vec3(0, 0, -6)));
		// Kepala reptil menyatu organik di depan atas badan (tanpa garis sambungan patah)
		AppendTransformedMesh(body, BuildEllipsoid(0.24f, 0.205f, 0.235f, 16, 22), TRS(glm::vec3(-0.095f, 0.075f, 0.0f), glm::vec3(0, 0, -4)));

		// Moncong ATAS panjang khas buaya (-X) dengan pangkal lebar & ujung bulat berhidung jendol!
		AppendTransformedMesh(body, BuildEllipsoid(0.24f, 0.082f, 0.172f, 12, 18), TRS(glm::vec3(-0.31f, 0.022f, 0.0f), glm::vec3(0, 0, -4)));
		AppendTransformedMesh(body, BuildEllipsoid(0.085f, 0.068f, 0.138f, 10, 14), TRS(glm::vec3(-0.485f, 0.022f, 0.0f)));
		// Dua punuk lubang hidung khas buaya di ujung moncong
		AppendTransformedMesh(body, BuildEllipsoid(0.044f, 0.036f, 0.038f, 8, 12), TRS(glm::vec3(-0.475f, 0.072f,  0.058f)));
		AppendTransformedMesh(body, BuildEllipsoid(0.044f, 0.036f, 0.038f, 8, 12), TRS(glm::vec3(-0.475f, 0.072f, -0.058f)));

		// Rahang BAWAH terpisah terbuka menyeringai agar gigi zig-zag terbaca tajam dari samping 2.5D!
		AppendTransformedMesh(body, BuildEllipsoid(0.205f, 0.052f, 0.154f, 12, 16), TRS(glm::vec3(-0.295f, -0.105f, 0.0f), glm::vec3(0, 0, 11)));

		// Dua kubah kelopak mata (brow turrets) menonjol di atas kepala khas buaya
		AppendTransformedMesh(body, BuildEllipsoid(0.092f, 0.088f, 0.086f, 12, 14), TRS(glm::vec3(-0.145f, 0.255f,  0.106f)));
		AppendTransformedMesh(body, BuildEllipsoid(0.092f, 0.088f, 0.086f, 12, 14), TRS(glm::vec3(-0.145f, 0.255f, -0.106f)));

		// Ekor buaya melengkung ke belakang (+X) -> siluet 100% langsung terbaca sebagai buaya!
		std::array<glm::vec3, 4> tailCurve = {{
			{ 0.23f, -0.14f, 0.00f },
			{ 0.40f, -0.17f, 0.00f },
			{ 0.51f, -0.08f, 0.00f },
			{ 0.54f,  0.06f, 0.00f }
		}};
		AppendTransformedMesh(body, BuildBezierTube(tailCurve, 0.118f, 0.026f, 14, 12, true), glm::mat4(1.0f));

		// Sepasang kaki pendek menapak di bawah (y bottom ~ -0.31) & tangan kecil jahil di sisi badan
		AppendTransformedMesh(body, BuildEllipsoid(0.095f, 0.055f, 0.072f, 10, 12), TRS(glm::vec3( 0.06f, -0.265f,  0.155f), glm::vec3(0,  14, 0)));
		AppendTransformedMesh(body, BuildEllipsoid(0.095f, 0.055f, 0.072f, 10, 12), TRS(glm::vec3( 0.06f, -0.265f, -0.155f), glm::vec3(0, -14, 0)));
		AppendTransformedMesh(body, BuildEllipsoid(0.072f, 0.048f, 0.056f, 10, 12), TRS(glm::vec3(-0.07f, -0.135f,  0.242f), glm::vec3(18,  22, -16)));
		AppendTransformedMesh(body, BuildEllipsoid(0.072f, 0.048f, 0.056f, 10, 12), TRS(glm::vec3(-0.07f, -0.135f, -0.242f), glm::vec3(-18, -22, -16)));
		croco.parts.push_back(std::move(body));

		// B. Sisik punggung zirah hijau-pinus gelap (osteoderms) + sirip ekor + punuk alis tegas
		SubMesh darkScales;
		darkScales.objectName = "croco_scales_dark";
		darkScales.materialName = "mat_croco_dark";
		// 4 duri osteoderm besar dari tengkuk ke punggung
		const std::array<glm::vec4, 4> backSpines = {{
			{ 0.03f,  0.225f, 0.056f, -18.0f },
			{ 0.14f,  0.190f, 0.062f, -34.0f },
			{ 0.24f,  0.120f, 0.058f, -52.0f },
			{ 0.30f,  0.025f, 0.048f, -72.0f }
		}};
		for (const auto& sp : backSpines) {
			AppendTransformedMesh(darkScales, BuildCone(sp.z, sp.z * 2.15f, 7),
				TRS(glm::vec3(sp.x, sp.y, 0.0f), glm::vec3(0, 0, sp.w)));
		}
		// 2 sirip osteoderm di atas lengkungan ekor
		AppendTransformedMesh(darkScales, BuildCone(0.038f, 0.088f, 6), TRS(glm::vec3(0.41f, -0.09f, 0.0f), glm::vec3(0, 0, -24)));
		AppendTransformedMesh(darkScales, BuildCone(0.028f, 0.072f, 6), TRS(glm::vec3(0.49f, -0.01f, 0.0f), glm::vec3(0, 0,  22)));
		// Punggung moncong bertekstur
		AppendTransformedMesh(darkScales, BuildEllipsoid(0.14f, 0.028f, 0.065f, 8, 12), TRS(glm::vec3(-0.31f, 0.092f, 0.0f), glm::vec3(0, 0, -5)));
		croco.parts.push_back(std::move(darkScales));

		// C. Perut krem-oker bergaris-garis + bagian bawah dagu
		SubMesh belly;
		belly.objectName = "croco_belly";
		belly.materialName = "mat_croco_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.24f, 0.19f, 0.225f, 12, 16), TRS(glm::vec3(-0.01f, -0.115f, 0.0f), glm::vec3(0, 0, 8)));
		AppendTransformedMesh(belly, BuildEllipsoid(0.18f, 0.038f, 0.132f, 10, 14), TRS(glm::vec3(-0.275f, -0.128f, 0.0f), glm::vec3(0, 0, 11)));
		croco.parts.push_back(std::move(belly));

		// D. Mata reptil kuning-amber besar menghadap ke ketapel (-X) DAN agak keluar ke kamera 2.5D (+Z)!
		SubMesh eyes;
		eyes.objectName = "croco_eyes";
		eyes.materialName = "mat_croco_eye";
		SubMesh eR = BuildAnimeEyeLens(0.076f, 0.082f, 0.074f, true);
		SubMesh eL = BuildAnimeEyeLens(0.076f, 0.082f, 0.074f, false);
		// rotY = -150 (+Z side) -> mengarah ke (-0.87, 0, +0.50): menatap ketapel sekaligus terbaca di kamera samping!
		AppendTransformedMesh(eyes, eR, TRS(glm::vec3(-0.195f, 0.252f,  0.118f), glm::vec3(0, -150, 0)));
		AppendTransformedMesh(eyes, eL, TRS(glm::vec3(-0.195f, 0.252f, -0.118f), glm::vec3(0,  150, 0)));
		croco.parts.push_back(std::move(eyes));

		// E. Alis licik V-curve Bezier + lubang hidung gelap
		SubMesh ink;
		ink.objectName = "croco_brows_nostrils";
		ink.materialName = "mat_ink";
		std::array<glm::vec3, 4> browR = {{
			{ -0.245f, 0.305f, 0.055f },
			{ -0.225f, 0.328f, 0.115f },
			{ -0.175f, 0.342f, 0.165f },
			{ -0.125f, 0.332f, 0.188f }
		}};
		std::array<glm::vec3, 4> browL = {{
			{ -0.245f, 0.305f, -0.055f },
			{ -0.225f, 0.328f, -0.115f },
			{ -0.175f, 0.342f, -0.165f },
			{ -0.125f, 0.332f, -0.188f }
		}};
		AppendTransformedMesh(ink, BuildBezierTube(browR, 0.020f, 0.015f, 10, 8, true), glm::mat4(1.0f));
		AppendTransformedMesh(ink, BuildBezierTube(browL, 0.020f, 0.015f, 10, 8, true), glm::mat4(1.0f));
		// Lubang hidung tajam di punuk moncong
		AppendTransformedMesh(ink, BuildEllipsoid(0.018f, 0.014f, 0.016f, 6, 8), TRS(glm::vec3(-0.508f, 0.078f,  0.060f)));
		AppendTransformedMesh(ink, BuildEllipsoid(0.018f, 0.014f, 0.016f, 6, 8), TRS(glm::vec3(-0.508f, 0.078f, -0.060f)));
		croco.parts.push_back(std::move(ink));

		// F. Rongga mulut merah tua dalam + lidah pink tersembunyi rapi di antara 2 rahang!
		SubMesh mouth;
		mouth.objectName = "croco_mouth";
		mouth.materialName = "mat_mouth_dark";
		AppendTransformedMesh(mouth, BuildEllipsoid(0.185f, 0.056f, 0.144f, 10, 14), TRS(glm::vec3(-0.295f, -0.045f, 0.0f), glm::vec3(0, 0, 3)));
		croco.parts.push_back(std::move(mouth));

		SubMesh tongue;
		tongue.objectName = "croco_tongue";
		tongue.materialName = "mat_tongue";
		AppendTransformedMesh(tongue, BuildEllipsoid(0.105f, 0.024f, 0.082f, 8, 12), TRS(glm::vec3(-0.275f, -0.076f, 0.0f), glm::vec3(0, 0, 8)));
		croco.parts.push_back(std::move(tongue));

		// G. Gigi taring zig-zag ikonik di sisi kiri/kanan moncong + taring depan + cakar kaki putih!
		SubMesh teeth;
		teeth.objectName = "croco_teeth_claws";
		teeth.materialName = "mat_white";
		// Taring atas sepanjang sisi rahang (+Z dan -Z) menunjuk ke bawah
		for (float side : { 1.0f, -1.0f }) {
			AppendTransformedMesh(teeth, BuildCone(0.022f, 0.058f, 7), TRS(glm::vec3(-0.23f, -0.018f, side * 0.146f), glm::vec3(0, 0, 180)));
			AppendTransformedMesh(teeth, BuildCone(0.024f, 0.064f, 7), TRS(glm::vec3(-0.33f, -0.022f, side * 0.148f), glm::vec3(0, 0, 180)));
			AppendTransformedMesh(teeth, BuildCone(0.022f, 0.060f, 7), TRS(glm::vec3(-0.43f, -0.024f, side * 0.125f), glm::vec3(0, 0, 180)));
			// Taring bawah menyembul ke atas (overbite buaya komik!)
			AppendTransformedMesh(teeth, BuildCone(0.020f, 0.054f, 7), TRS(glm::vec3(-0.28f, -0.078f, side * 0.136f), glm::vec3(0, 0, -8)));
			AppendTransformedMesh(teeth, BuildCone(0.023f, 0.062f, 7), TRS(glm::vec3(-0.38f, -0.082f, side * 0.132f), glm::vec3(0, 0, -10)));
			// Taring depan
			AppendTransformedMesh(teeth, BuildCone(0.019f, 0.050f, 7), TRS(glm::vec3(-0.505f, -0.022f, side * 0.052f), glm::vec3(0, 0, 180)));
			// 2 cakar kecil di tiap kaki
			AppendTransformedMesh(teeth, BuildCone(0.015f, 0.042f, 6), TRS(glm::vec3(-0.015f, -0.282f, side * 0.135f), glm::vec3(0, 0, 82)));
			AppendTransformedMesh(teeth, BuildCone(0.015f, 0.042f, 6), TRS(glm::vec3(-0.015f, -0.282f, side * 0.175f), glm::vec3(0, 0, 82)));
		}
		croco.parts.push_back(std::move(teeth));

		out.push_back(std::move(croco));
	}

	// 10. GERBANG TORII SUNSET ONSEN (prop_torii_gate.obj — latar ikonik World 1-2!)
	{
		ModelAsset torii;
		torii.modelName = "prop_torii_gate";
		AddUniqueMaterial(torii, MakeMat("mat_torii", "tex_torii_red.bmp"));
		AddUniqueMaterial(torii, MakeMat("mat_ink", "tex_anime_ink.bmp", glm::vec3(0.20f), glm::vec3(0.0f), 8.0f));

		SubMesh redBeam;
		redBeam.objectName = "torii_red_pillars";
		redBeam.materialName = "mat_torii";
		AppendTransformedMesh(redBeam, BuildCylinder(0.18f, 0.22f, 3.6f, 12), TRS(glm::vec3(-1.35f, 1.8f, 0.0f), glm::vec3(0, 0, -3)));
		AppendTransformedMesh(redBeam, BuildCylinder(0.18f, 0.22f, 3.6f, 12), TRS(glm::vec3( 1.35f, 1.8f, 0.0f), glm::vec3(0, 0,  3)));
		// Palang bawah (nuki) & palang atas (kasagi)
		AppendTransformedMesh(redBeam, BuildBox(3.55f, 0.24f, 0.26f), TRS(glm::vec3(0.0f, 2.75f, 0.0f)));
		AppendTransformedMesh(redBeam, BuildBox(4.15f, 0.28f, 0.36f), TRS(glm::vec3(0.0f, 3.45f, 0.0f)));
		AppendTransformedMesh(redBeam, BuildBox(0.32f, 0.62f, 0.28f), TRS(glm::vec3(0.0f, 3.10f, 0.0f)));
		torii.parts.push_back(std::move(redBeam));

		SubMesh cap;
		cap.objectName = "torii_dark_cap";
		cap.materialName = "mat_ink";
		std::array<glm::vec3, 4> topArc = {{ {-2.32f,0.14f,0.0f}, {-0.90f,0.0f,0.0f}, {0.90f,0.0f,0.0f}, {2.32f,0.14f,0.0f} }};
		AppendTransformedMesh(cap, BuildBezierTube(topArc, 0.14f, 0.14f, 16, 8, true),
			TRS(glm::vec3(0.0f, 3.66f, 0.0f), glm::vec3(0.0f), glm::vec3(1.0f, 0.72f, 1.3f)));
		AppendTransformedMesh(cap, BuildCylinder(0.26f, 0.30f, 0.42f, 12), TRS(glm::vec3(-1.42f, 0.21f, 0.0f)));
		AppendTransformedMesh(cap, BuildCylinder(0.26f, 0.30f, 0.42f, 12), TRS(glm::vec3( 1.42f, 0.21f, 0.0f)));
		torii.parts.push_back(std::move(cap));
		out.push_back(std::move(torii));
	}

	// 11. RUMPUN BAMBU ORGANIK BERDAUN (prop_bamboo_grove.obj — kurva Bezier + daun runcing)
	{
		ModelAsset grove;
		grove.modelName = "prop_bamboo_grove";
		AddUniqueMaterial(grove, MakeMat("mat_bamboo", "tex_bamboo.bmp"));
		AddUniqueMaterial(grove, MakeMat("mat_leaf", "tex_yuzu_leaf.bmp"));

		SubMesh stalks;
		stalks.objectName = "bamboo_curved_stalks";
		stalks.materialName = "mat_bamboo";
		std::array<glm::vec3, 4> s1 = {{ {0.0f,0.0f,0.0f}, {-0.08f,1.6f,0.02f}, {-0.22f,3.2f,-0.04f}, {-0.42f,5.0f,-0.08f} }};
		std::array<glm::vec3, 4> s2 = {{ {0.38f,0.0f,-0.12f}, {0.46f,1.4f,-0.08f}, {0.58f,2.8f,-0.02f}, {0.72f,4.3f,0.06f} }};
		std::array<glm::vec3, 4> s3 = {{ {-0.34f,0.0f,-0.25f}, {-0.40f,1.3f,-0.22f}, {-0.52f,2.6f,-0.16f}, {-0.68f,3.8f,-0.10f} }};
		AppendTransformedMesh(stalks, BuildBezierTube(s1, 0.13f, 0.075f, 18, 12, true), glm::mat4(1.0f));
		AppendTransformedMesh(stalks, BuildBezierTube(s2, 0.11f, 0.065f, 16, 10, true), glm::mat4(1.0f));
		AppendTransformedMesh(stalks, BuildBezierTube(s3, 0.10f, 0.060f, 16, 10, true), glm::mat4(1.0f));
		for (float ry : { 0.85f, 1.75f, 2.65f, 3.55f }) {
			AppendTransformedMesh(stalks, BuildTorus(0.115f, 0.018f, 14, 6), TRS(glm::vec3(-ry * 0.07f, ry, 0.0f), glm::vec3(90, 0, 5)));
		}
		grove.parts.push_back(std::move(stalks));

		SubMesh leaves;
		leaves.objectName = "bamboo_leaf_fans";
		leaves.materialName = "mat_leaf";
		SubMesh singleLeaf = BuildEllipsoid(0.38f, 0.045f, 0.095f, 6, 10);
		for (int i = 0; i < 12; ++i) {
			float y = 1.9f + (i % 4) * 0.72f;
			float side = (i % 2 == 0) ? 1.0f : -1.0f;
			float x = (i < 6 ? -0.15f : 0.45f) + side * 0.28f;
			float z = (i % 3 - 1) * 0.16f;
			AppendTransformedMesh(leaves, singleLeaf, TRS(glm::vec3(x, y, z), glm::vec3(side * 12.0f, side * 22.0f, -side * (16.0f + (i % 3) * 14.0f))));
		}
		grove.parts.push_back(std::move(leaves));
		out.push_back(std::move(grove));
	}

	// 12. RUMAH ONSEN KAYU JEPANG BERATAP GENTENG LENGKUNG (prop_onsen_house.obj)
	{
		ModelAsset house;
		house.modelName = "prop_onsen_house";
		AddUniqueMaterial(house, MakeMat("mat_wood", "tex_wood.bmp"));
		AddUniqueMaterial(house, MakeMat("mat_roof", "tex_roof_tile.bmp"));
		AddUniqueMaterial(house, MakeMat("mat_shoji", "tex_shoji_glow.bmp", glm::vec3(1.0f), glm::vec3(0.75f, 0.56f, 0.18f), 16.0f));
		AddUniqueMaterial(house, MakeMat("mat_stone", "tex_stone.bmp"));

		SubMesh base;
		base.objectName = "onsen_foundation";
		base.materialName = "mat_stone";
		AppendTransformedMesh(base, BuildBox(3.9f, 0.45f, 2.9f), TRS(glm::vec3(0.0f, 0.22f, 0.0f)));
		AppendTransformedMesh(base, BuildBox(1.2f, 0.22f, 0.65f), TRS(glm::vec3(0.0f, 0.11f, 1.65f)));
		house.parts.push_back(std::move(base));

		SubMesh timber;
		timber.objectName = "onsen_timber_body";
		timber.materialName = "mat_wood";
		AppendTransformedMesh(timber, BuildBox(3.3f, 2.0f, 2.3f), TRS(glm::vec3(0.0f, 1.45f, 0.0f)));
		// Pilar sudut & pagar beranda
		for (float px : { -1.78f, 1.78f }) {
			AppendTransformedMesh(timber, BuildCylinder(0.11f, 0.12f, 2.15f, 10), TRS(glm::vec3(px, 1.52f, 1.28f)));
		}
		AppendTransformedMesh(timber, BuildBox(3.75f, 0.14f, 0.12f), TRS(glm::vec3(0.0f, 0.96f, 1.28f)));
		house.parts.push_back(std::move(timber));

		SubMesh shoji;
		shoji.objectName = "onsen_shoji_window";
		shoji.materialName = "mat_shoji";
		AppendTransformedMesh(shoji, BuildBox(1.55f, 1.15f, 0.08f), TRS(glm::vec3(0.0f, 1.38f, 1.17f)));
		house.parts.push_back(std::move(shoji));

		SubMesh roof;
		roof.objectName = "onsen_tiled_roof";
		roof.materialName = "mat_roof";
		// Atap pelana genteng bertingkat dengan cucuran lebar khas onsen Jepang
		AppendTransformedMesh(roof, BuildBox(4.7f, 0.18f, 3.4f), TRS(glm::vec3(0.0f, 2.52f, 0.08f)));
		AppendTransformedMesh(roof, BuildBox(4.4f, 0.22f, 1.95f), TRS(glm::vec3(0.0f, 2.98f,  0.80f), glm::vec3( 28, 0, 0)));
		AppendTransformedMesh(roof, BuildBox(4.4f, 0.22f, 1.95f), TRS(glm::vec3(0.0f, 2.98f, -0.80f), glm::vec3(-28, 0, 0)));
		// Bubungan puncak melengkung tipis di atas atap
		std::array<glm::vec3, 4> ridge = {{ {-2.35f,3.52f,0.0f}, {-0.8f,3.40f,0.0f}, {0.8f,3.40f,0.0f}, {2.35f,3.52f,0.0f} }};
		AppendTransformedMesh(roof, BuildBezierTube(ridge, 0.14f, 0.14f, 16, 8, true), glm::mat4(1.0f));
		house.parts.push_back(std::move(roof));
		out.push_back(std::move(house));
	}

	// 13. AWAN HALUS BERGAYA ROVIO (prop_cloud_fluffy.obj)
	{
		ModelAsset cloud;
		cloud.modelName = "prop_cloud_fluffy";
		AddUniqueMaterial(cloud, MakeMat("mat_cloud", "tex_capy_belly.bmp", glm::vec3(1.0f, 0.96f, 0.90f), glm::vec3(0.18f, 0.14f, 0.10f), 8.0f));
		SubMesh puffs;
		puffs.objectName = "cloud_puffs";
		puffs.materialName = "mat_cloud";
		AppendTransformedMesh(puffs, BuildEllipsoid(1.15f, 0.42f, 0.36f, 12, 16), TRS(glm::vec3( 0.0f, -0.10f, 0.0f)));
		AppendTransformedMesh(puffs, BuildEllipsoid(0.62f, 0.56f, 0.34f, 12, 16), TRS(glm::vec3(-0.32f,  0.22f, 0.02f)));
		AppendTransformedMesh(puffs, BuildEllipsoid(0.52f, 0.46f, 0.32f, 12, 16), TRS(glm::vec3( 0.40f,  0.14f, 0.02f)));
		AppendTransformedMesh(puffs, BuildEllipsoid(0.42f, 0.34f, 0.28f, 10, 14), TRS(glm::vec3(-0.88f, -0.02f, 0.02f)));
		AppendTransformedMesh(puffs, BuildEllipsoid(0.40f, 0.32f, 0.28f, 10, 14), TRS(glm::vec3( 0.92f, -0.04f, 0.02f)));
		cloud.parts.push_back(std::move(puffs));
		out.push_back(std::move(cloud));
	}

	return out;
}
