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

	// 7. MULUT ANIME EKSPRESIF (pas di permukaan moncong kapibara ringkas 2.5D)
	const glm::vec3 mCenter = snoutPos + glm::vec3(0.0f, -0.042f * headScale, 0.0f);
	const float mx0 = 0.104f * headScale;
	const float mx1 = 0.096f * headScale;
	const float mx2 = 0.084f * headScale;
	SubMesh mouthCav;  mouthCav.objectName = "anime_mouth";  mouthCav.materialName = "mat_mouth_dark";
	SubMesh tonguePart; tonguePart.objectName = "anime_tongue"; tonguePart.materialName = "mat_tongue";
	SubMesh teethPart;  teethPart.objectName = "anime_teeth";  teethPart.materialName = "mat_white";

	switch (mouthStyle) {
	case AnimeMouth::GrumpySmirk: {
		// Garis bibir cemberut marah khas kapibara (garis tengah 'Y' + sudut turun tajam)
		std::array<glm::vec3, 4> cleft = {{
			mCenter + glm::vec3(mx0 + 0.008f,  0.032f * headScale, 0.0f),
			mCenter + glm::vec3(mx0 + 0.005f,  0.022f * headScale, 0.0f),
			mCenter + glm::vec3(mx0 + 0.002f,  0.012f * headScale, 0.0f),
			mCenter + glm::vec3(mx0,           0.004f * headScale, 0.0f)
		}};
		std::array<glm::vec3, 4> fL = {{
			mCenter + glm::vec3(mx0,  0.005f * headScale, 0.0f),
			mCenter + glm::vec3(mx1,  0.002f * headScale, 0.024f * headScale),
			mCenter + glm::vec3(mx2, -0.008f * headScale, 0.048f * headScale),
			mCenter + glm::vec3(mx2 - 0.010f * headScale, -0.020f * headScale, 0.068f * headScale)
		}};
		std::array<glm::vec3, 4> fR = {{
			mCenter + glm::vec3(mx0,  0.005f * headScale, 0.0f),
			mCenter + glm::vec3(mx1,  0.002f * headScale,-0.024f * headScale),
			mCenter + glm::vec3(mx2, -0.008f * headScale,-0.048f * headScale),
			mCenter + glm::vec3(mx2 - 0.010f * headScale, -0.020f * headScale,-0.068f * headScale)
		}};
		AppendTransformedMesh(mouthCav, BuildBezierTube(cleft, 0.009f * headScale, 0.009f * headScale), glm::mat4(1.0f));
		AppendTransformedMesh(mouthCav, BuildBezierTube(fL,    0.011f * headScale, 0.009f * headScale), glm::mat4(1.0f));
		AppendTransformedMesh(mouthCav, BuildBezierTube(fR,    0.011f * headScale, 0.009f * headScale), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::OpenShout: {
		// Mulut teriak anime rata mengikuti permukaan moncong (tidak menonjol keluar seperti balon)
		AppendTransformedMesh(mouthCav, BuildEllipsoid(0.022f * headScale, 0.038f * headScale, 0.056f * headScale, 10, 14),
			TRS(mCenter + glm::vec3(mx0 - 0.004f * headScale, -0.006f * headScale, 0.0f)));
		AppendTransformedMesh(tonguePart, BuildEllipsoid(0.014f * headScale, 0.018f * headScale, 0.036f * headScale, 8, 10),
			TRS(mCenter + glm::vec3(mx0 - 0.001f * headScale, -0.018f * headScale, 0.0f)));
		break;
	}
	case AnimeMouth::CatSmile: {
		// Bibir ':3' / omega kapibara mungil menempel halus di moncong
		std::array<glm::vec3, 4> wL = {{
			mCenter + glm::vec3(mx0, -0.002f * headScale, 0.0f),
			mCenter + glm::vec3(mx1, -0.014f * headScale, 0.020f * headScale),
			mCenter + glm::vec3(mx2, -0.012f * headScale, 0.042f * headScale),
			mCenter + glm::vec3(mx2 - 0.008f * headScale, 0.004f * headScale, 0.060f * headScale)
		}};
		std::array<glm::vec3, 4> wR = {{
			mCenter + glm::vec3(mx0, -0.002f * headScale, 0.0f),
			mCenter + glm::vec3(mx1, -0.014f * headScale,-0.020f * headScale),
			mCenter + glm::vec3(mx2, -0.012f * headScale,-0.042f * headScale),
			mCenter + glm::vec3(mx2 - 0.008f * headScale, 0.004f * headScale,-0.060f * headScale)
		}};
		AppendTransformedMesh(mouthCav, BuildBezierTube(wL, 0.010f * headScale, 0.008f * headScale), glm::mat4(1.0f));
		AppendTransformedMesh(mouthCav, BuildBezierTube(wR, 0.010f * headScale, 0.008f * headScale), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::FierceGrin: {
		// Garis mulut terkatup geram / dingin tanpa kotak gigi menonjol
		std::array<glm::vec3, 4> gL = {{
			mCenter + glm::vec3(mx0,  0.004f * headScale, 0.0f),
			mCenter + glm::vec3(mx1,  0.003f * headScale, 0.024f * headScale),
			mCenter + glm::vec3(mx2, -0.004f * headScale, 0.048f * headScale),
			mCenter + glm::vec3(mx2 - 0.010f * headScale, -0.012f * headScale, 0.066f * headScale)
		}};
		std::array<glm::vec3, 4> gR = {{
			mCenter + glm::vec3(mx0,  0.004f * headScale, 0.0f),
			mCenter + glm::vec3(mx1,  0.003f * headScale,-0.024f * headScale),
			mCenter + glm::vec3(mx2, -0.004f * headScale,-0.048f * headScale),
			mCenter + glm::vec3(mx2 - 0.010f * headScale, -0.012f * headScale,-0.066f * headScale)
		}};
		AppendTransformedMesh(mouthCav, BuildBezierTube(gL, 0.011f * headScale, 0.009f * headScale), glm::mat4(1.0f));
		AppendTransformedMesh(mouthCav, BuildBezierTube(gR, 0.011f * headScale, 0.009f * headScale), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::SmugSide: {
		// Senyum sinis asimetris menempel rapat di moncong (naik di satu sisi)
		std::array<glm::vec3, 4> sCurve = {{
			mCenter + glm::vec3(mx2 - 0.006f * headScale, -0.008f * headScale, -0.056f * headScale),
			mCenter + glm::vec3(mx1, -0.004f * headScale, -0.018f * headScale),
			mCenter + glm::vec3(mx1,  0.004f * headScale,  0.024f * headScale),
			mCenter + glm::vec3(mx2 - 0.006f * headScale,  0.018f * headScale,  0.064f * headScale)
		}};
		AppendTransformedMesh(mouthCav, BuildBezierTube(sCurve, 0.010f * headScale, 0.010f * headScale), glm::mat4(1.0f));
		break;
	}
	case AnimeMouth::HeavyFangs: {
		// Rahang bawah & taring besar khas Heavy Onsen ("yang merah besar")
		AppendTransformedMesh(mouthCav, BuildEllipsoid(0.032f * headScale, 0.036f * headScale, 0.092f * headScale, 10, 14),
			TRS(mCenter + glm::vec3(mx0 - 0.010f * headScale, -0.016f * headScale, 0.0f)));
		AppendTransformedMesh(teethPart, BuildCone(0.022f * headScale, 0.058f * headScale, 10),
			TRS(mCenter + glm::vec3(mx1 + 0.002f * headScale,  0.004f * headScale,  0.064f * headScale), glm::vec3(0, 0, -18)));
		AppendTransformedMesh(teethPart, BuildCone(0.022f * headScale, 0.058f * headScale, 10),
			TRS(mCenter + glm::vec3(mx1 + 0.002f * headScale,  0.004f * headScale, -0.064f * headScale), glm::vec3(0, 0, -18)));
		break;
	}
	case AnimeMouth::HeroRoar: {
		// Mulut menggeram/mengaum rata mengikuti kontur moncong (TIDAK menonjol keluar seperti bola!)
		// Rongga mulut gelap tipis menempel permukaan moncong + gigi taring geram tegas
		AppendTransformedMesh(mouthCav, BuildEllipsoid(0.014f * headScale, 0.042f * headScale, 0.078f * headScale, 12, 16),
			TRS(mCenter + glm::vec3(mx0 - 0.008f * headScale, -0.004f * headScale, 0.0f)));
		AppendTransformedMesh(tonguePart, BuildEllipsoid(0.011f * headScale, 0.018f * headScale, 0.050f * headScale, 10, 12),
			TRS(mCenter + glm::vec3(mx0 - 0.006f * headScale, -0.022f * headScale, 0.0f)));
		// Barisan gigi geram atas yang tegas + 2 taring sudut tajam
		AppendTransformedMesh(teethPart, BuildBox(0.010f * headScale, 0.014f * headScale, 0.092f * headScale),
			TRS(mCenter + glm::vec3(mx0 - 0.003f * headScale,  0.022f * headScale, 0.0f)));
		AppendTransformedMesh(teethPart, BuildCone(0.012f * headScale, 0.026f * headScale, 8),
			TRS(mCenter + glm::vec3(mx1 - 0.001f * headScale,  0.014f * headScale,  0.046f * headScale), glm::vec3(0, 0, 180)));
		AppendTransformedMesh(teethPart, BuildCone(0.012f * headScale, 0.026f * headScale, 8),
			TRS(mCenter + glm::vec3(mx1 - 0.001f * headScale,  0.014f * headScale, -0.046f * headScale), glm::vec3(0, 0, 180)));
		break;
	}
	}
	asset.parts.push_back(std::move(mouthCav));
	if (!tonguePart.vertices.empty()) asset.parts.push_back(std::move(tonguePart));
	if (!teethPart.vertices.empty()) asset.parts.push_back(std::move(teethPart));

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
	// 1. CHILL CAPI: Warna Merah #2 + Bentuk Kapibara Anime + Syal Merah + Urat Marah
	case CapyVariant::Chill: {
		asset.modelName = "anime_capy_chill";
		BuildAnimeCapyCore(asset, "mat_fur_red", "tex_capy_red.bmp", "tex_anime_eye_chill.bmp",
			glm::vec3(1.0f, 1.0f, 1.0f), 1.08f, 1.15f, AnimeBrow::AngryV, AnimeMouth::GrumpySmirk, true);

		AddUniqueMaterial(asset, MakeMat("mat_scarf_red", "tex_anime_scarf_red.bmp"));
		SubMesh scarf;
		scarf.objectName = "acc_anime_scarf";
		scarf.materialName = "mat_scarf_red";
		AppendTransformedMesh(scarf, BuildTorus(0.18f, 0.042f, 22, 10), TRS(glm::vec3(0.08f, 0.03f, 0.0f), glm::vec3(0, 0, -35)));
		std::array<glm::vec3, 4> tail = {{ {0.02f,0.06f,0.10f}, {-0.14f,0.11f,0.16f}, {-0.32f,0.05f,0.20f}, {-0.48f,0.10f,0.16f} }};
		AppendTransformedMesh(scarf, BuildBezierTube(tail, 0.048f, 0.022f), glm::mat4(1.0f));
		asset.parts.push_back(std::move(scarf));

		// Jambul bulu merah runcing kecil di puncak kepala (serasi dengan Key-Art 2D!)
		SubMesh tuft;
		tuft.objectName = "acc_chill_tuft";
		tuft.materialName = "mat_fur_red";
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

	// 4. YUZU BOMB CAPI: Kapibara Espresso Bulat Gemuk + Mata Oranye Garang + Jeruk Yuzu + Sumbu Api
	case CapyVariant::YuzuBomb: {
		asset.modelName = "anime_capy_yuzu_bomb";
		BuildAnimeCapyCore(asset, "mat_fur_espresso", "tex_anime_fur_espresso.bmp", "tex_anime_eye_bomb.bmp",
			glm::vec3(1.02f, 1.12f, 1.15f), 1.12f, 1.18f, AnimeBrow::FierceSlope, AnimeMouth::FierceGrin, true);

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
		std::array<glm::vec3, 4> stL = {{ {0.53f,0.06f,0.04f}, {0.54f,0.04f,0.16f}, {0.50f,-0.02f,0.28f}, {0.43f,0.02f,0.35f} }};
		std::array<glm::vec3, 4> stR = {{ {0.53f,0.06f,-0.04f}, {0.54f,0.04f,-0.16f}, {0.50f,-0.02f,-0.28f}, {0.43f,0.02f,-0.35f} }};
		AppendTransformedMesh(mustache, BuildBezierTube(stL, 0.038f, 0.012f), glm::mat4(1.0f));
		AppendTransformedMesh(mustache, BuildBezierTube(stR, 0.038f, 0.012f), glm::mat4(1.0f));
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

	// 4. KEY-ART CHILL CAPI ROAR (MC Merah mengaum gagah + syal berkibar panjang)
	{
		ModelAsset chill;
		chill.modelName = "home_capy_chill_roar";
		BuildAnimeCapyCore(chill, "mat_fur_red", "tex_capy_red.bmp", "tex_anime_eye_chill.bmp",
			glm::vec3(1.02f, 1.02f, 1.04f), 1.12f, 1.18f, AnimeBrow::AngryV, AnimeMouth::HeroRoar, true);

		AddUniqueMaterial(chill, MakeMat("mat_scarf_red", "tex_anime_scarf_red.bmp"));
		SubMesh scarf;
		scarf.objectName = "acc_hero_scarf";
		scarf.materialName = "mat_scarf_red";
		AppendTransformedMesh(scarf, BuildTorus(0.19f, 0.048f, 22, 10), TRS(glm::vec3(0.08f, 0.03f, 0.0f), glm::vec3(0, 0, -34)));
		// Ekor syal berkibar lembut ke belakang bawah punggung (tidak menutupi wajah teman di samping!)
		std::array<glm::vec3, 4> t1 = {{ {0.02f,0.04f,0.12f}, {-0.14f,0.04f,0.18f}, {-0.30f,-0.02f,0.20f}, {-0.44f,0.02f,0.15f} }};
		AppendTransformedMesh(scarf, BuildBezierTube(t1, 0.048f, 0.016f), glm::mat4(1.0f));
		chill.parts.push_back(std::move(scarf));
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

	// 9. MUSUH CROCO MINION 2.5D EKSPRESIF (enemy_croco_minion.obj — pengganti bola hijau polos!)
	{
		ModelAsset croco;
		croco.modelName = "enemy_croco_minion";
		AddUniqueMaterial(croco, MakeMat("mat_croco", "tex_croco_green.bmp"));
		AddUniqueMaterial(croco, MakeMat("mat_belly", "tex_capy_belly.bmp"));
		AddUniqueMaterial(croco, MakeMat("mat_croco_eye", "tex_croco_eye.bmp", glm::vec3(1.0f), glm::vec3(0.06f), 48.0f));
		AddUniqueMaterial(croco, MakeMat("mat_ink", "tex_anime_ink.bmp", glm::vec3(0.15f), glm::vec3(0.0f), 8.0f));
		AddUniqueMaterial(croco, MakeMat("mat_white", "tex_capy_eye_white.bmp"));
		AddUniqueMaterial(croco, MakeMat("mat_mouth_dark", "tex_mouth_dark.bmp"));

		SubMesh body;
		body.objectName = "croco_body";
		body.materialName = "mat_croco";
		// Badan bulat-gemuk komik ala babi Angry Birds, tapi versi buaya nakal bermoncong lebar!
		AppendTransformedMesh(body, BuildEllipsoid(0.35f, 0.31f, 0.34f, 14, 20), glm::mat4(1.0f));
		// Moncong buaya lebar mengarah ke -X (menghadap ketapel!)
		AppendTransformedMesh(body, BuildEllipsoid(0.20f, 0.11f, 0.22f, 10, 14), TRS(glm::vec3(-0.28f, -0.04f, 0.0f)));
		// Duri punggung buaya 3 buah
		for (int k = 0; k < 3; ++k) {
			AppendTransformedMesh(body, BuildCone(0.06f, 0.13f, 8), TRS(glm::vec3(0.05f + k * 0.11f, 0.30f - k * 0.04f, 0.0f), glm::vec3(0, 0, -24 - k * 14)));
		}
		croco.parts.push_back(std::move(body));

		SubMesh belly;
		belly.objectName = "croco_belly";
		belly.materialName = "mat_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.24f, 0.16f, 0.24f, 10, 14), TRS(glm::vec3(-0.08f, -0.17f, 0.0f)));
		croco.parts.push_back(std::move(belly));

		SubMesh eyes;
		eyes.objectName = "croco_eyes";
		eyes.materialName = "mat_croco_eye";
		SubMesh eR = BuildAnimeEyeLens(0.068f, 0.074f, 0.068f, true);
		SubMesh eL = BuildAnimeEyeLens(0.068f, 0.074f, 0.068f, false);
		AppendTransformedMesh(eyes, eR, TRS(glm::vec3(-0.22f, 0.16f,  0.12f), glm::vec3(0, 165, 0)));
		AppendTransformedMesh(eyes, eL, TRS(glm::vec3(-0.22f, 0.16f, -0.12f), glm::vec3(0,-165, 0)));
		croco.parts.push_back(std::move(eyes));

		SubMesh ink;
		ink.objectName = "croco_brows_snout";
		ink.materialName = "mat_ink";
		// Alis nakal miring & lubang hidung buaya
		AppendTransformedMesh(ink, BuildBox(0.04f, 0.028f, 0.12f), TRS(glm::vec3(-0.25f, 0.24f,  0.12f), glm::vec3( 20, 14, 0)));
		AppendTransformedMesh(ink, BuildBox(0.04f, 0.028f, 0.12f), TRS(glm::vec3(-0.25f, 0.24f, -0.12f), glm::vec3(-20,-14, 0)));
		AppendTransformedMesh(ink, BuildEllipsoid(0.018f, 0.018f, 0.018f, 6, 8), TRS(glm::vec3(-0.45f, 0.02f,  0.065f)));
		AppendTransformedMesh(ink, BuildEllipsoid(0.018f, 0.018f, 0.018f, 6, 8), TRS(glm::vec3(-0.45f, 0.02f, -0.065f)));
		croco.parts.push_back(std::move(ink));

		// Seringai buaya bergigi zig-zag!
		SubMesh mouth;
		mouth.objectName = "croco_mouth";
		mouth.materialName = "mat_mouth_dark";
		AppendTransformedMesh(mouth, BuildBox(0.04f, 0.032f, 0.26f), TRS(glm::vec3(-0.42f, -0.08f, 0.0f)));
		croco.parts.push_back(std::move(mouth));

		SubMesh teeth;
		teeth.objectName = "croco_teeth";
		teeth.materialName = "mat_white";
		for (float tz : { -0.09f, -0.03f, 0.03f, 0.09f }) {
			AppendTransformedMesh(teeth, BuildCone(0.018f, 0.044f, 6), TRS(glm::vec3(-0.43f, -0.065f, tz), glm::vec3(0, 0, 180)));
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

	return out;
}
