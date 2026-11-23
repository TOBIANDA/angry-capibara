#include "models_capybara.h"
#include "geometry_builders.h"
#include <glm/gtc/matrix_transform.hpp>

namespace {
enum class BodySilhouette {
	UprightPear,     // Chill (Red-style upright chunky)
	TriangleWedge,   // Dash (Chuck-style sleek forward wedge)
	ChibiSlim,       // Mini (Stella/Blues big-head slim)
	GiantSphere,     // Yuzu Bomb (Bomb-style bowling ball)
	LeanBarrel,      // Seed-Blaster (tall barrel chest)
	HeroicRonin,     // Bambu-Katana (athletic upright)
	MassiveBoulder   // Heavy Onsen (Terence wide tank)
};

enum class BrowStyle {
	AngryV,          // Red-style sharp V unibrow
	ExcitedHigh,     // Chuck-style raised wild brows
	CuteHappy,       // Stella/Blues soft arched + lashes
	BombArchedRed,   // Bomb-style dark sockets + thick arched red brows
	CockyAsymmetric, // Cowboy smirk one-up one-down
	SharpFocused,    // Katana warrior sharp brows
	TerenceScowl     // Massive flat heavy scowl
};

enum class MouthStyle {
	GrumpySmirk,
	OpenShout,
	CuteSmile,
	ToothyGrimace,
	LopsidedGrin,
	UnderbiteFangs
};

struct FaceConfig {
	glm::vec3 eyeAnchor;   // Base position on head (+X forward, +Y up)
	float eyeSpacingZ;
	float eyeScale;
	glm::vec3 snoutPos;
	glm::vec3 snoutScale;
	BrowStyle brow;
	MouthStyle mouth;
	bool eyeSockets = false;
	bool eyelashes = false;
};

MaterialDef MakeMat(const std::string& name, const std::string& tex,
					glm::vec3 kd = glm::vec3(1.0f),
					glm::vec3 ke = glm::vec3(0.0f),
					float shine = 28.0f) {
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

SubMesh BuildBodySilhouetteMesh(BodySilhouette sil) {
	SubMesh part;

	switch (sil) {
	case BodySilhouette::UprightPear: {
		// Red-style: badan pir tegak kokoh, dada agak membusung ke depan
		std::array<glm::vec2, 4> prof = {{
			{ 0.00f, -0.34f }, { 0.34f, -0.24f }, { 0.27f, 0.22f }, { 0.00f, 0.38f }
		}};
		SubMesh body = BuildBezierRevolvedProfile(prof, 22, 24);
		AppendTransformedMesh(part, body, TRS(glm::vec3(0.0f, 0.02f, 0.0f), glm::vec3(0, 0, 82.0f), glm::vec3(1.0f, 1.06f, 0.96f)));
		// Telinga capibara bulat di samping atas
		SubMesh ear = BuildEllipsoid(0.055f, 0.072f, 0.036f, 10, 12);
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.04f, 0.35f,  0.17f), glm::vec3(-18, 0, 18)));
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.04f, 0.35f, -0.17f), glm::vec3( 18, 0, 18)));
		// Kaki depan-belakang
		SubMesh leg = BuildEllipsoid(0.072f, 0.075f, 0.068f, 10, 12);
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.12f, -0.29f,  0.13f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.12f, -0.29f, -0.13f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.12f, -0.29f,  0.13f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.12f, -0.29f, -0.13f)));
		break;
	}

	case BodySilhouette::TriangleWedge: {
		// Chuck-style: siluet segitiga/baji ramping condong ke depan (+X)
		std::array<glm::vec2, 4> prof = {{
			{ 0.00f, -0.32f }, { 0.38f, -0.24f }, { 0.16f, 0.24f }, { 0.00f, 0.44f }
		}};
		SubMesh body = BuildBezierRevolvedProfile(prof, 22, 24);
		AppendTransformedMesh(part, body, TRS(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0, 0, 68.0f), glm::vec3(1.0f, 1.05f, 0.88f)));
		SubMesh ear = BuildEllipsoid(0.048f, 0.068f, 0.032f, 10, 12);
		AppendTransformedMesh(part, ear, TRS(glm::vec3(0.02f, 0.32f,  0.13f), glm::vec3(-20, 0, -15)));
		AppendTransformedMesh(part, ear, TRS(glm::vec3(0.02f, 0.32f, -0.13f), glm::vec3( 20, 0, -15)));
		SubMesh leg = BuildEllipsoid(0.075f, 0.065f, 0.058f, 10, 12);
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.12f, -0.29f,  0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.15f, -0.29f,  0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.12f, -0.29f, -0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.15f, -0.29f, -0.12f)));
		break;
	}

	case BodySilhouette::ChibiSlim: {
		// Mini/Stella style: badan mungil ramping + kepala bulat besar (proporsi chibi)
		SubMesh torso = BuildEllipsoid(0.16f, 0.19f, 0.15f, 14, 18);
		AppendTransformedMesh(part, torso, TRS(glm::vec3(-0.02f, -0.10f, 0.0f), glm::vec3(0, 0, -8)));
		SubMesh head = BuildEllipsoid(0.20f, 0.19f, 0.19f, 14, 20);
		AppendTransformedMesh(part, head, TRS(glm::vec3(0.05f, 0.14f, 0.0f)));
		SubMesh ear = BuildEllipsoid(0.050f, 0.065f, 0.030f, 10, 12);
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.04f, 0.30f,  0.14f), glm::vec3(-22, 0, 18)));
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.04f, 0.30f, -0.14f), glm::vec3( 22, 0, 18)));
		SubMesh leg = BuildEllipsoid(0.050f, 0.055f, 0.048f, 8, 10);
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.07f, -0.27f,  0.08f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.07f, -0.27f, -0.08f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.08f, -0.27f,  0.08f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.08f, -0.27f, -0.08f)));
		break;
	}

	case BodySilhouette::GiantSphere: {
		// Bomb-style: bola besar super bundar dan berat
		SubMesh sphere = BuildEllipsoid(0.37f, 0.36f, 0.35f, 18, 26);
		AppendTransformedMesh(part, sphere, glm::mat4(1.0f));
		SubMesh ear = BuildEllipsoid(0.055f, 0.065f, 0.036f, 10, 12);
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.02f, 0.33f,  0.19f), glm::vec3(-24, 0, 15)));
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.02f, 0.33f, -0.19f), glm::vec3( 24, 0, 15)));
		SubMesh leg = BuildEllipsoid(0.075f, 0.065f, 0.068f, 10, 12);
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.13f, -0.34f,  0.14f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.13f, -0.34f, -0.14f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.13f, -0.34f,  0.14f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.13f, -0.34f, -0.14f)));
		break;
	}

	case BodySilhouette::LeanBarrel: {
		// Siluet tong tinggi agak ramping tegak (Cowboy)
		std::array<glm::vec2, 4> prof = {{
			{ 0.00f, -0.36f }, { 0.30f, -0.24f }, { 0.29f, 0.24f }, { 0.00f, 0.37f }
		}};
		SubMesh body = BuildBezierRevolvedProfile(prof, 22, 24);
		AppendTransformedMesh(part, body, TRS(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0, 0, 88.0f), glm::vec3(1.0f, 0.96f, 0.96f)));
		SubMesh ear = BuildEllipsoid(0.050f, 0.068f, 0.032f, 10, 12);
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.02f, 0.30f,  0.18f), glm::vec3(-20, 0, 15)));
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.02f, 0.30f, -0.18f), glm::vec3( 20, 0, 15)));
		SubMesh leg = BuildEllipsoid(0.068f, 0.078f, 0.062f, 10, 12);
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.10f, -0.31f,  0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.10f, -0.31f, -0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.12f, -0.31f,  0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.12f, -0.31f, -0.12f)));
		break;
	}

	case BodySilhouette::HeroicRonin: {
		// Badan pir atletis sedikit lebih condong siap menyerang
		std::array<glm::vec2, 4> prof = {{
			{ 0.00f, -0.33f }, { 0.33f, -0.20f }, { 0.25f, 0.20f }, { 0.00f, 0.36f }
		}};
		SubMesh body = BuildBezierRevolvedProfile(prof, 22, 24);
		AppendTransformedMesh(part, body, TRS(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0, 0, 76.0f), glm::vec3(1.02f, 1.0f, 0.96f)));
		SubMesh ear = BuildEllipsoid(0.052f, 0.068f, 0.034f, 10, 12);
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.03f, 0.32f,  0.16f), glm::vec3(-18, 0, 15)));
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.03f, 0.32f, -0.16f), glm::vec3( 18, 0, 15)));
		SubMesh leg = BuildEllipsoid(0.068f, 0.075f, 0.062f, 10, 12);
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.12f, -0.29f,  0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.12f, -0.29f, -0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.12f, -0.29f,  0.12f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.12f, -0.29f, -0.12f)));
		break;
	}

	case BodySilhouette::MassiveBoulder: {
		// Terence-style: bongkahan bulat-kotak raksasa super lebar & berat!
		std::array<glm::vec2, 4> prof = {{
			{ 0.00f, -0.42f }, { 0.50f, -0.34f }, { 0.48f, 0.26f }, { 0.00f, 0.42f }
		}};
		SubMesh body = BuildBezierRevolvedProfile(prof, 22, 24);
		AppendTransformedMesh(part, body, TRS(glm::vec3(0.0f, 0.02f, 0.0f), glm::vec3(0, 0, 86.0f), glm::vec3(1.06f, 1.02f, 1.08f)));
		SubMesh ear = BuildEllipsoid(0.068f, 0.085f, 0.045f, 10, 12);
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.04f, 0.40f,  0.24f), glm::vec3(-22, 0, 16)));
		AppendTransformedMesh(part, ear, TRS(glm::vec3(-0.04f, 0.40f, -0.24f), glm::vec3( 22, 0, 16)));
		SubMesh leg = BuildEllipsoid(0.095f, 0.085f, 0.085f, 10, 12);
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.18f, -0.38f,  0.20f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3( 0.18f, -0.38f, -0.20f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.18f, -0.38f,  0.20f)));
		AppendTransformedMesh(part, leg, TRS(glm::vec3(-0.18f, -0.38f, -0.20f)));
		break;
	}
	}

	return part;
}

void BuildExpressiveFace(
	ModelAsset& asset,
	const FaceConfig& cfg,
	const std::string& browMatName,
	const std::string& browTexFile)
{
	AddUniqueMaterial(asset, MakeMat("mat_snout", "tex_capy_snout.bmp"));
	AddUniqueMaterial(asset, MakeMat("mat_cheek", "tex_capy_cheek.bmp"));
	AddUniqueMaterial(asset, MakeMat("mat_eye_white", "tex_capy_eye_white.bmp", glm::vec3(1.0f), glm::vec3(0.10f), 48.0f));
	AddUniqueMaterial(asset, MakeMat("mat_eye", "tex_capy_eye.bmp", glm::vec3(1.0f), glm::vec3(0.0f), 96.0f));
	AddUniqueMaterial(asset, MakeMat("mat_mouth_dark", "tex_mouth_dark.bmp"));
	AddUniqueMaterial(asset, MakeMat("mat_tongue", "tex_tongue_pink.bmp"));
	AddUniqueMaterial(asset, MakeMat(browMatName, browTexFile));

	// 1. Moncong khas capibara
	SubMesh snoutPart;
	snoutPart.objectName = "face_snout";
	snoutPart.materialName = "mat_snout";
	AppendTransformedMesh(snoutPart, BuildEllipsoid(cfg.snoutScale.x, cfg.snoutScale.y, cfg.snoutScale.z, 12, 16),
		TRS(cfg.snoutPos, glm::vec3(0, 0, -6.0f)));
	asset.parts.push_back(std::move(snoutPart));

	// 2. Pipi merona
	SubMesh cheekPart;
	cheekPart.objectName = "face_cheeks";
	cheekPart.materialName = "mat_cheek";
	SubMesh blush = BuildEllipsoid(0.044f, 0.032f, 0.022f, 8, 10);
	AppendTransformedMesh(cheekPart, blush, TRS(cfg.eyeAnchor + glm::vec3(0.00f, -0.095f,  cfg.eyeSpacingZ + 0.07f), glm::vec3(0, 26, 0)));
	AppendTransformedMesh(cheekPart, blush, TRS(cfg.eyeAnchor + glm::vec3(0.00f, -0.095f, -cfg.eyeSpacingZ - 0.07f), glm::vec3(0,-26, 0)));
	asset.parts.push_back(std::move(cheekPart));

	// 3. Lingkar mata gelap ala Bomb (opsional)
	if (cfg.eyeSockets) {
		AddUniqueMaterial(asset, MakeMat("mat_socket", "tex_eye_socket.bmp"));
		SubMesh sock;
		sock.objectName = "face_eye_sockets";
		sock.materialName = "mat_socket";
		SubMesh ring = BuildEllipsoid(0.068f * cfg.eyeScale, 0.074f * cfg.eyeScale, 0.074f * cfg.eyeScale, 10, 14);
		AppendTransformedMesh(sock, ring, TRS(cfg.eyeAnchor + glm::vec3(-0.015f, -0.008f,  cfg.eyeSpacingZ)));
		AppendTransformedMesh(sock, ring, TRS(cfg.eyeAnchor + glm::vec3(-0.015f, -0.008f, -cfg.eyeSpacingZ)));
		asset.parts.push_back(std::move(sock));
	}

	// 4. Sklera Mata Putih BESAR menghadap ke depan (+X) sehingga kedua mata selalu terlihat!
	SubMesh scleraPart;
	scleraPart.objectName = "face_sclera";
	scleraPart.materialName = "mat_eye_white";
	SubMesh sclera = BuildEllipsoid(0.048f * cfg.eyeScale, 0.056f * cfg.eyeScale, 0.052f * cfg.eyeScale, 12, 16);
	AppendTransformedMesh(scleraPart, sclera, TRS(cfg.eyeAnchor + glm::vec3(0.0f, 0.0f,  cfg.eyeSpacingZ)));
	AppendTransformedMesh(scleraPart, sclera, TRS(cfg.eyeAnchor + glm::vec3(0.0f, 0.0f, -cfg.eyeSpacingZ)));
	asset.parts.push_back(std::move(scleraPart));

	// 5. Pupil + Hidung + Bulu Mata
	SubMesh eyePart;
	eyePart.objectName = "face_pupils_and_nostrils";
	eyePart.materialName = "mat_eye";
	SubMesh pupil = BuildEllipsoid(0.026f * cfg.eyeScale, 0.032f * cfg.eyeScale, 0.030f * cfg.eyeScale, 10, 12);
	AppendTransformedMesh(eyePart, pupil, TRS(cfg.eyeAnchor + glm::vec3(0.034f * cfg.eyeScale, -0.004f,  cfg.eyeSpacingZ - 0.006f)));
	AppendTransformedMesh(eyePart, pupil, TRS(cfg.eyeAnchor + glm::vec3(0.034f * cfg.eyeScale, -0.004f, -cfg.eyeSpacingZ + 0.006f)));

	// Lubang hidung di moncong depan
	SubMesh nostril = BuildEllipsoid(0.016f, 0.018f, 0.014f, 6, 8);
	AppendTransformedMesh(eyePart, nostril, TRS(cfg.snoutPos + glm::vec3(cfg.snoutScale.x * 0.90f, cfg.snoutScale.y * 0.25f,  0.045f)));
	AppendTransformedMesh(eyePart, nostril, TRS(cfg.snoutPos + glm::vec3(cfg.snoutScale.x * 0.90f, cfg.snoutScale.y * 0.25f, -0.045f)));

	if (cfg.eyelashes) {
		SubMesh lash = BuildBox(0.022f, 0.012f, 0.045f);
		AppendTransformedMesh(eyePart, lash, TRS(cfg.eyeAnchor + glm::vec3(0.01f, 0.045f * cfg.eyeScale,  cfg.eyeSpacingZ + 0.045f), glm::vec3(0, 0, 28)));
		AppendTransformedMesh(eyePart, lash, TRS(cfg.eyeAnchor + glm::vec3(0.01f, 0.045f * cfg.eyeScale, -cfg.eyeSpacingZ - 0.045f), glm::vec3(0, 0, 28)));
	}
	asset.parts.push_back(std::move(eyePart));

	// 6. Alis Tebal Ekspresif
	SubMesh browPart;
	browPart.objectName = "face_eyebrows";
	browPart.materialName = browMatName;
	const glm::vec3 browBase = cfg.eyeAnchor + glm::vec3(0.026f * cfg.eyeScale, 0.060f * cfg.eyeScale, 0.0f);

	switch (cfg.brow) {
	case BrowStyle::AngryV: {
		SubMesh bar = BuildBox(0.045f, 0.036f, 0.125f);
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.005f,  cfg.eyeSpacingZ + 0.01f), glm::vec3( 26.0f, 12.0f, 0.0f)));
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.005f, -cfg.eyeSpacingZ - 0.01f), glm::vec3(-26.0f,-12.0f, 0.0f)));
		break;
	}
	case BrowStyle::ExcitedHigh: {
		SubMesh bar = BuildBox(0.036f, 0.030f, 0.11f);
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.030f,  cfg.eyeSpacingZ + 0.01f), glm::vec3(-18.0f, 12.0f, 0.0f)));
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.030f, -cfg.eyeSpacingZ - 0.01f), glm::vec3( 18.0f,-12.0f, 0.0f)));
		break;
	}
	case BrowStyle::CuteHappy: {
		SubMesh bar = BuildBox(0.028f, 0.018f, 0.085f);
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.018f,  cfg.eyeSpacingZ), glm::vec3(-12.0f, 10.0f, 0.0f)));
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.018f, -cfg.eyeSpacingZ), glm::vec3( 12.0f,-10.0f, 0.0f)));
		break;
	}
	case BrowStyle::BombArchedRed: {
		// Alis tebal Bomb (melengkung turun sedih/tegang di sisi luar, tebal di dalam)
		SubMesh bar = BuildBox(0.048f, 0.038f, 0.125f);
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0.01f, 0.012f,  cfg.eyeSpacingZ + 0.015f), glm::vec3(-16.0f, 14.0f, 0.0f)));
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0.01f, 0.012f, -cfg.eyeSpacingZ - 0.015f), glm::vec3( 16.0f,-14.0f, 0.0f)));
		break;
	}
	case BrowStyle::CockyAsymmetric: {
		SubMesh bar = BuildBox(0.038f, 0.028f, 0.11f);
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.024f,  cfg.eyeSpacingZ), glm::vec3(-15.0f, 10.0f, 0.0f)));
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.002f, -cfg.eyeSpacingZ), glm::vec3(-20.0f,-10.0f, 0.0f)));
		break;
	}
	case BrowStyle::SharpFocused: {
		SubMesh bar = BuildBox(0.040f, 0.028f, 0.115f);
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.008f,  cfg.eyeSpacingZ + 0.01f), glm::vec3( 20.0f, 12.0f, 0.0f)));
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(0, 0.008f, -cfg.eyeSpacingZ - 0.01f), glm::vec3(-20.0f,-12.0f, 0.0f)));
		break;
	}
	case BrowStyle::TerenceScowl: {
		// Alis raksasa menyatu menempel di kening (unibrow garang Terence)
		SubMesh bar = BuildBox(0.052f, 0.052f, 0.31f);
		AppendTransformedMesh(browPart, bar, TRS(browBase + glm::vec3(-0.022f, -0.018f, 0.0f), glm::vec3(0, 0, -14.0f)));
		break;
	}
	}
	asset.parts.push_back(std::move(browPart));

	// 7. Mulut Ekspresif 3D (Senyum, Teriak, Gigi, Lidah)
	const glm::vec3 mouthPos = cfg.snoutPos + glm::vec3(cfg.snoutScale.x * 0.68f, -cfg.snoutScale.y * 0.42f, 0.0f);
	SubMesh mouthCav;
	mouthCav.objectName = "face_mouth";
	mouthCav.materialName = "mat_mouth_dark";

	SubMesh tonguePart;
	tonguePart.objectName = "face_tongue";
	tonguePart.materialName = "mat_tongue";

	SubMesh teethPart;
	teethPart.objectName = "face_teeth";
	teethPart.materialName = "mat_eye_white";

	switch (cfg.mouth) {
	case MouthStyle::GrumpySmirk: {
		// Garis mulut melengkung turun + 1 taring kecil imut
		AppendTransformedMesh(mouthCav, BuildBox(0.04f, 0.022f, 0.12f), TRS(mouthPos, glm::vec3(10, 0, 0)));
		AppendTransformedMesh(teethPart, BuildCone(0.016f, 0.032f, 8), TRS(mouthPos + glm::vec3(0.015f, 0.014f, 0.035f), glm::vec3(0, 0, 180)));
		break;
	}
	case MouthStyle::OpenShout: {
		// Mulut menganga lebar ala Chuck!
		AppendTransformedMesh(mouthCav, BuildEllipsoid(0.055f, 0.072f, 0.088f, 10, 14), TRS(mouthPos + glm::vec3(0.01f, -0.02f, 0.0f)));
		AppendTransformedMesh(tonguePart, BuildEllipsoid(0.042f, 0.032f, 0.055f, 8, 10), TRS(mouthPos + glm::vec3(0.028f, -0.055f, 0.0f)));
		AppendTransformedMesh(teethPart, BuildBox(0.028f, 0.022f, 0.095f), TRS(mouthPos + glm::vec3(0.032f, 0.035f, 0.0f)));
		break;
	}
	case MouthStyle::CuteSmile: {
		// Senyum lebar ':D' imut
		AppendTransformedMesh(mouthCav, BuildEllipsoid(0.038f, 0.042f, 0.068f, 8, 12), TRS(mouthPos + glm::vec3(0.01f, -0.01f, 0.0f)));
		AppendTransformedMesh(tonguePart, BuildEllipsoid(0.028f, 0.022f, 0.042f, 8, 10), TRS(mouthPos + glm::vec3(0.022f, -0.032f, 0.0f)));
		break;
	}
	case MouthStyle::ToothyGrimace: {
		// Menyeringai tegang dengan deretan gigi putih
		AppendTransformedMesh(mouthCav, BuildBox(0.045f, 0.042f, 0.145f), TRS(mouthPos));
		AppendTransformedMesh(teethPart, BuildBox(0.035f, 0.028f, 0.130f), TRS(mouthPos + glm::vec3(0.012f, 0.0f, 0.0f)));
		break;
	}
	case MouthStyle::LopsidedGrin: {
		// Senyum miring percaya diri
		AppendTransformedMesh(mouthCav, BuildBox(0.040f, 0.030f, 0.125f), TRS(mouthPos, glm::vec3(-14, 0, 0)));
		AppendTransformedMesh(teethPart, BuildBox(0.032f, 0.022f, 0.060f), TRS(mouthPos + glm::vec3(0.012f, 0.008f, 0.025f), glm::vec3(-14, 0, 0)));
		break;
	}
	case MouthStyle::UnderbiteFangs: {
		// Mulut cemberut besar + 2 taring bawah mencuat ke atas
		AppendTransformedMesh(mouthCav, BuildBox(0.055f, 0.038f, 0.21f), TRS(mouthPos));
		AppendTransformedMesh(teethPart, BuildCone(0.022f, 0.055f, 8), TRS(mouthPos + glm::vec3(0.022f, 0.030f,  0.065f)));
		AppendTransformedMesh(teethPart, BuildCone(0.022f, 0.055f, 8), TRS(mouthPos + glm::vec3(0.022f, 0.030f, -0.065f)));
		break;
	}
	}

	asset.parts.push_back(std::move(mouthCav));
	if (!tonguePart.vertices.empty()) asset.parts.push_back(std::move(tonguePart));
	if (!teethPart.vertices.empty()) asset.parts.push_back(std::move(teethPart));
}

SubMesh BuildLeafDoublePatch(float scale) {
	std::array<std::array<glm::vec3, 4>, 4> cp;
	for (int i = 0; i < 4; ++i) {
		float u = static_cast<float>(i) / 3.0f;
		float x = (u - 0.1f) * 0.18f * scale;
		float arch = std::sin(u * 3.14159f) * 0.048f * scale;
		float halfW = std::sin(u * 3.14159f) * 0.068f * scale + 0.005f;
		for (int j = 0; j < 4; ++j) {
			float v = (static_cast<float>(j) / 3.0f) * 2.0f - 1.0f;
			float cup = (1.0f - v * v) * -0.014f * scale;
			cp[i][j] = glm::vec3(x, arch + cup, v * halfW);
		}
	}
	SubMesh out = BuildBicubicBezierPatch(cp, 10, 8, false);
	SubMesh back = BuildBicubicBezierPatch(cp, 10, 8, true);
	AppendTransformedMesh(out, back, TRS(glm::vec3(0.0f, -0.003f, 0.0f)));
	return out;
}
} // namespace

const std::vector<CapyInfo>& GetCapyW12Roster() {
	static const std::vector<CapyInfo> roster = {
		{ CapyVariant::Chill,       "capy_chill",        "Chill Capi",         "World 1 (1-1)" },
		{ CapyVariant::Dash,        "capy_dash",         "Dash Capi",          "World 1 (1-6)" },
		{ CapyVariant::Mini,        "capy_mini",         "Trio Mini-Capi",     "World 1 (1-11)" },
		{ CapyVariant::YuzuBomb,    "capy_yuzu_bomb",    "Yuzu Bomb Capi",     "World 2 (2-1)" },
		{ CapyVariant::SeedBlaster, "capy_seed_blaster", "Seed-Blaster Capi",  "World 2 (2-6)" },
		{ CapyVariant::BambuSaber,  "capy_bambu_saber",  "Bambu-Katana Capi",  "World 2 (2-11)" },
		{ CapyVariant::HeavyOnsen,  "capy_heavy_onsen",  "Heavy Onsen Capi",   "World 2 (2-16)" }
	};
	return roster;
}

ModelAsset BuildCapybaraW12(CapyVariant variant) {
	ModelAsset asset;

	switch (variant) {
	// 1. CHILL CAPI (Red Upright Pear + Alis V Garang + Kacamata Bertengger di Dahi + Jambul + Daun)
	case CapyVariant::Chill: {
		asset.modelName = "capy_chill";
		AddUniqueMaterial(asset, MakeMat("mat_fur_red", "tex_capy_red.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_belly", "tex_capy_belly.bmp"));

		SubMesh body = BuildBodySilhouetteMesh(BodySilhouette::UprightPear);
		body.objectName = "capy_body";
		body.materialName = "mat_fur_red";
		asset.parts.push_back(std::move(body));

		SubMesh belly;
		belly.objectName = "capy_belly";
		belly.materialName = "mat_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.18f, 0.21f, 0.23f, 12, 16), TRS(glm::vec3(0.13f, -0.09f, 0.0f)));
		asset.parts.push_back(std::move(belly));

		FaceConfig face;
		face.eyeAnchor = glm::vec3(0.23f, 0.14f, 0.0f);
		face.eyeSpacingZ = 0.088f;
		face.eyeScale = 1.18f;
		face.snoutPos = glm::vec3(0.28f, 0.02f, 0.0f);
		face.snoutScale = glm::vec3(0.105f, 0.095f, 0.125f);
		face.brow = BrowStyle::AngryV;
		face.mouth = MouthStyle::GrumpySmirk;
		BuildExpressiveFace(asset, face, "mat_brow_black", "tex_capy_eye.bmp");

		// Jambul merah di puncak + Kacamata santai bertengger di dahi (tidak menutupi mata!)
		SubMesh crest;
		crest.objectName = "acc_chill_crest";
		crest.materialName = "mat_fur_red";
		AppendTransformedMesh(crest, BuildCone(0.055f, 0.16f, 10), TRS(glm::vec3(-0.02f, 0.43f, 0.0f), glm::vec3(0, 0, 22)));
		AppendTransformedMesh(crest, BuildCone(0.042f, 0.12f, 10), TRS(glm::vec3(-0.09f, 0.40f, 0.0f), glm::vec3(0, 0, 42)));
		asset.parts.push_back(std::move(crest));

		AddUniqueMaterial(asset, MakeMat("mat_shades", "tex_shades_black.bmp", glm::vec3(1.0f), glm::vec3(0.05f), 96.0f));
		SubMesh shades;
		shades.objectName = "acc_chill_shades_forehead";
		shades.materialName = "mat_shades";
		AppendTransformedMesh(shades, BuildBox(0.032f, 0.055f, 0.095f), TRS(glm::vec3(0.20f, 0.285f,  0.095f), glm::vec3(0, 14, 30)));
		AppendTransformedMesh(shades, BuildBox(0.032f, 0.055f, 0.095f), TRS(glm::vec3(0.20f, 0.285f, -0.095f), glm::vec3(0,-14, 30)));
		AppendTransformedMesh(shades, BuildBox(0.022f, 0.018f, 0.06f),  TRS(glm::vec3(0.21f, 0.285f,  0.0f), glm::vec3(0, 0, 30)));
		asset.parts.push_back(std::move(shades));

		AddUniqueMaterial(asset, MakeMat("mat_leaf", "tex_yuzu_leaf.bmp"));
		SubMesh leaf;
		leaf.objectName = "acc_chill_leaf";
		leaf.materialName = "mat_leaf";
		AppendTransformedMesh(leaf, BuildLeafDoublePatch(1.05f), TRS(glm::vec3(0.06f, 0.39f, 0.04f), glm::vec3(18, 10, 15)));
		asset.parts.push_back(std::move(leaf));
		break;
	}

	// 2. DASH CAPI (Chuck-style Triangular Wedge + Mulut Teriak Lebar + Rambut Runcing + Goggles + Ikat Kepala)
	case CapyVariant::Dash: {
		asset.modelName = "capy_dash";
		AddUniqueMaterial(asset, MakeMat("mat_fur_yellow", "tex_capy_yellow.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_belly", "tex_capy_belly.bmp"));

		SubMesh body = BuildBodySilhouetteMesh(BodySilhouette::TriangleWedge);
		body.objectName = "capy_body";
		body.materialName = "mat_fur_yellow";
		asset.parts.push_back(std::move(body));

		SubMesh belly;
		belly.objectName = "capy_belly";
		belly.materialName = "mat_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.18f, 0.20f, 0.20f, 12, 16), TRS(glm::vec3(0.15f, -0.10f, 0.0f), glm::vec3(0, 0, -18)));
		asset.parts.push_back(std::move(belly));

		FaceConfig face;
		face.eyeAnchor = glm::vec3(0.20f, 0.14f, 0.0f);
		face.eyeSpacingZ = 0.082f;
		face.eyeScale = 1.15f;
		face.snoutPos = glm::vec3(0.29f, 0.02f, 0.0f);
		face.snoutScale = glm::vec3(0.115f, 0.092f, 0.115f);
		face.brow = BrowStyle::ExcitedHigh;
		face.mouth = MouthStyle::OpenShout;
		BuildExpressiveFace(asset, face, "mat_brow_brown", "tex_capy_snout.bmp");

		// Rambut runcing besar di puncak lancip
		SubMesh hair;
		hair.objectName = "acc_dash_spiky_hair";
		hair.materialName = "mat_fur_yellow";
		AppendTransformedMesh(hair, BuildCone(0.060f, 0.20f, 10), TRS(glm::vec3(0.12f, 0.44f,  0.00f), glm::vec3(0, 0, 24)));
		AppendTransformedMesh(hair, BuildCone(0.048f, 0.16f, 10), TRS(glm::vec3(0.04f, 0.40f,  0.05f), glm::vec3(12, 0, 44)));
		AppendTransformedMesh(hair, BuildCone(0.048f, 0.16f, 10), TRS(glm::vec3(0.04f, 0.40f, -0.05f), glm::vec3(-12, 0, 44)));
		asset.parts.push_back(std::move(hair));

		AddUniqueMaterial(asset, MakeMat("mat_red", "tex_accent_red.bmp"));
		SubMesh band;
		band.objectName = "acc_dash_headband";
		band.materialName = "mat_red";
		AppendTransformedMesh(band, BuildTorus(0.135f, 0.022f, 24, 10), TRS(glm::vec3(0.12f, 0.25f, 0.0f), glm::vec3(0, 0, -24), glm::vec3(1.05f, 1.0f, 0.96f)));
		std::array<glm::vec3, 4> t1 = {{ {0.01f,0.24f,0.03f}, {-0.14f,0.32f,0.09f}, {-0.28f,0.24f,0.14f}, {-0.42f,0.28f,0.11f} }};
		std::array<glm::vec3, 4> t2 = {{ {0.01f,0.24f,-0.03f}, {-0.14f,0.27f,-0.09f}, {-0.28f,0.19f,-0.12f}, {-0.40f,0.21f,-0.10f} }};
		AppendTransformedMesh(band, BuildBezierTube(t1, 0.022f, 0.008f), glm::mat4(1.0f));
		AppendTransformedMesh(band, BuildBezierTube(t2, 0.022f, 0.008f), glm::mat4(1.0f));
		asset.parts.push_back(std::move(band));

		AddUniqueMaterial(asset, MakeMat("mat_visor", "tex_visor_orange.bmp", glm::vec3(1.0f), glm::vec3(0.15f, 0.06f, 0.0f), 96.0f));
		SubMesh gog;
		gog.objectName = "acc_dash_goggles";
		gog.materialName = "mat_visor";
		AppendTransformedMesh(gog, BuildCylinder(0.046f, 0.046f, 0.036f, 14), TRS(glm::vec3(0.20f, 0.295f,  0.068f), glm::vec3(0, 16, -65)));
		AppendTransformedMesh(gog, BuildCylinder(0.046f, 0.046f, 0.036f, 14), TRS(glm::vec3(0.20f, 0.295f, -0.068f), glm::vec3(0,-16, -65)));
		asset.parts.push_back(std::move(gog));
		break;
	}

	// 3. TRIO MINI-CAPI (Chibi Kepala Besar + Mata Berkilau Berbulu Mata + Senyum Imut + Topi Baling-Baling)
	case CapyVariant::Mini: {
		asset.modelName = "capy_mini";
		AddUniqueMaterial(asset, MakeMat("mat_fur_sky", "tex_capy_sky.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_belly", "tex_capy_belly.bmp"));

		SubMesh body = BuildBodySilhouetteMesh(BodySilhouette::ChibiSlim);
		body.objectName = "capy_body";
		body.materialName = "mat_fur_sky";
		asset.parts.push_back(std::move(body));

		SubMesh belly;
		belly.objectName = "capy_belly";
		belly.materialName = "mat_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.11f, 0.14f, 0.12f, 10, 14), TRS(glm::vec3(0.05f, -0.11f, 0.0f)));
		asset.parts.push_back(std::move(belly));

		FaceConfig face;
		face.eyeAnchor = glm::vec3(0.19f, 0.17f, 0.0f);
		face.eyeSpacingZ = 0.075f;
		face.eyeScale = 1.15f;
		face.snoutPos = glm::vec3(0.21f, 0.07f, 0.0f);
		face.snoutScale = glm::vec3(0.075f, 0.068f, 0.088f);
		face.brow = BrowStyle::CuteHappy;
		face.mouth = MouthStyle::CuteSmile;
		face.eyelashes = true;
		BuildExpressiveFace(asset, face, "mat_brow_blue", "tex_accent_blue.bmp");

		AddUniqueMaterial(asset, MakeMat("mat_red", "tex_accent_red.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_gold", "tex_accent_gold.bmp"));
		SubMesh cap;
		cap.objectName = "acc_mini_prop_cap";
		cap.materialName = "mat_red";
		AppendTransformedMesh(cap, BuildEllipsoid(0.12f, 0.07f, 0.12f, 10, 14), TRS(glm::vec3(0.04f, 0.31f, 0.0f)));
		asset.parts.push_back(std::move(cap));

		SubMesh prop;
		prop.objectName = "acc_mini_propeller";
		prop.materialName = "mat_gold";
		AppendTransformedMesh(prop, BuildCylinder(0.015f, 0.015f, 0.05f, 10), TRS(glm::vec3(0.04f, 0.38f, 0.0f)));
		AppendTransformedMesh(prop, BuildBox(0.24f, 0.015f, 0.040f), TRS(glm::vec3(0.04f, 0.405f, 0.0f), glm::vec3(0, 25, 0)));
		AppendTransformedMesh(prop, BuildBox(0.040f, 0.015f, 0.24f), TRS(glm::vec3(0.04f, 0.405f, 0.0f), glm::vec3(0, 25, 0)));
		asset.parts.push_back(std::move(prop));
		break;
	}

	// 4. YUZU BOMB CAPI (Bomb-style Bola Besar + Lingkar Mata Abu + Alis Merah Tebal + Yuzu & Sumbu Api)
	case CapyVariant::YuzuBomb: {
		asset.modelName = "capy_yuzu_bomb";
		AddUniqueMaterial(asset, MakeMat("mat_fur_obsidian", "tex_capy_obsidian.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_belly", "tex_capy_belly.bmp"));

		SubMesh body = BuildBodySilhouetteMesh(BodySilhouette::GiantSphere);
		body.objectName = "capy_body";
		body.materialName = "mat_fur_obsidian";
		asset.parts.push_back(std::move(body));

		SubMesh belly;
		belly.objectName = "capy_belly";
		belly.materialName = "mat_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.22f, 0.22f, 0.26f, 12, 16), TRS(glm::vec3(0.16f, -0.12f, 0.0f)));
		asset.parts.push_back(std::move(belly));

		FaceConfig face;
		face.eyeAnchor = glm::vec3(0.32f, 0.12f, 0.0f);
		face.eyeSpacingZ = 0.095f;
		face.eyeScale = 1.22f;
		face.snoutPos = glm::vec3(0.37f, -0.02f, 0.0f);
		face.snoutScale = glm::vec3(0.105f, 0.095f, 0.130f);
		face.brow = BrowStyle::BombArchedRed;
		face.mouth = MouthStyle::ToothyGrimace;
		face.eyeSockets = true;
		BuildExpressiveFace(asset, face, "mat_brow_red", "tex_accent_red.bmp");

		AddUniqueMaterial(asset, MakeMat("mat_yuzu", "tex_yuzu.bmp", glm::vec3(1.0f), glm::vec3(0.35f, 0.18f, 0.0f), 40.0f));
		AddUniqueMaterial(asset, MakeMat("mat_spark", "tex_fuse_spark.bmp", glm::vec3(1.0f), glm::vec3(0.85f, 0.45f, 0.05f), 64.0f));
		AddUniqueMaterial(asset, MakeMat("mat_wood", "tex_wood.bmp"));

		SubMesh yuzuPart;
		yuzuPart.objectName = "acc_yuzu_bomb_fruit";
		yuzuPart.materialName = "mat_yuzu";
		std::array<glm::vec2, 4> yuzuProfile = {{
			{ 0.00f, -0.12f }, { 0.16f, -0.09f }, { 0.15f, 0.09f }, { 0.00f, 0.13f }
		}};
		AppendTransformedMesh(yuzuPart, BuildBezierRevolvedProfile(yuzuProfile, 16, 18),
			TRS(glm::vec3(0.02f, 0.45f, 0.0f), glm::vec3(0, 0, 90)));
		asset.parts.push_back(std::move(yuzuPart));

		SubMesh fusePart;
		fusePart.objectName = "acc_yuzu_fuse";
		fusePart.materialName = "mat_wood";
		std::array<glm::vec3, 4> fuseCurve = {{
			{ 0.02f, 0.56f, 0.0f }, { 0.01f, 0.66f, 0.03f }, { -0.07f, 0.71f, 0.05f }, { -0.13f, 0.67f, 0.02f }
		}};
		AppendTransformedMesh(fusePart, BuildBezierTube(fuseCurve, 0.022f, 0.014f), glm::mat4(1.0f));
		asset.parts.push_back(std::move(fusePart));

		SubMesh sparkPart;
		sparkPart.objectName = "acc_yuzu_spark";
		sparkPart.materialName = "mat_spark";
		AppendTransformedMesh(sparkPart, BuildEllipsoid(0.060f, 0.060f, 0.060f, 8, 10), TRS(glm::vec3(-0.13f, 0.67f, 0.02f)));
		AppendTransformedMesh(sparkPart, BuildCone(0.028f, 0.10f, 8), TRS(glm::vec3(-0.13f, 0.74f, 0.02f)));
		AppendTransformedMesh(sparkPart, BuildCone(0.028f, 0.10f, 8), TRS(glm::vec3(-0.19f, 0.68f, 0.02f), glm::vec3(0, 0, 75)));
		asset.parts.push_back(std::move(sparkPart));
		break;
	}

	// 5. SEED-BLASTER CAPI (Siluet Tong Tinggi + Senyum Miring + Visor Oranye + Topi Koboi + Double Blaster)
	case CapyVariant::SeedBlaster: {
		asset.modelName = "capy_seed_blaster";
		AddUniqueMaterial(asset, MakeMat("mat_fur_caramel", "tex_capy_caramel.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_belly", "tex_capy_belly.bmp"));

		SubMesh body = BuildBodySilhouetteMesh(BodySilhouette::LeanBarrel);
		body.objectName = "capy_body";
		body.materialName = "mat_fur_caramel";
		asset.parts.push_back(std::move(body));

		SubMesh belly;
		belly.objectName = "capy_belly";
		belly.materialName = "mat_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.16f, 0.22f, 0.19f, 12, 16), TRS(glm::vec3(0.13f, -0.09f, 0.0f)));
		asset.parts.push_back(std::move(belly));

		FaceConfig face;
		face.eyeAnchor = glm::vec3(0.24f, 0.14f, 0.0f);
		face.eyeSpacingZ = 0.084f;
		face.eyeScale = 1.10f;
		face.snoutPos = glm::vec3(0.29f, 0.02f, 0.0f);
		face.snoutScale = glm::vec3(0.10f, 0.09f, 0.12f);
		face.brow = BrowStyle::CockyAsymmetric;
		face.mouth = MouthStyle::LopsidedGrin;
		BuildExpressiveFace(asset, face, "mat_brow_brown", "tex_capy_snout.bmp");

		AddUniqueMaterial(asset, MakeMat("mat_wood", "tex_wood.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_gold", "tex_accent_gold.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_stone", "tex_stone.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_visor", "tex_visor_orange.bmp", glm::vec3(1.0f), glm::vec3(0.22f, 0.08f, 0.0f), 96.0f));

		SubMesh hatPart;
		hatPart.objectName = "acc_adventurer_hat";
		hatPart.materialName = "mat_wood";
		AppendTransformedMesh(hatPart, BuildCylinder(0.32f, 0.31f, 0.028f, 20), TRS(glm::vec3(0.03f, 0.34f, 0.0f), glm::vec3(0, 0, -6)));
		AppendTransformedMesh(hatPart, BuildCylinder(0.17f, 0.12f, 0.15f, 18),  TRS(glm::vec3(0.03f, 0.42f, 0.0f), glm::vec3(0, 0, -6)));
		asset.parts.push_back(std::move(hatPart));

		SubMesh goldPart;
		goldPart.objectName = "acc_blaster_gold";
		goldPart.materialName = "mat_gold";
		AppendTransformedMesh(goldPart, BuildCylinder(0.173f, 0.165f, 0.034f, 18), TRS(glm::vec3(0.03f, 0.365f, 0.0f), glm::vec3(0, 0, -6)));
		AppendTransformedMesh(goldPart, BuildTorus(0.29f, 0.022f, 24, 10), TRS(glm::vec3(0.0f, -0.02f, 0.0f), glm::vec3(0, 0, 38), glm::vec3(1.0f, 1.0f, 1.0f)));
		asset.parts.push_back(std::move(goldPart));

		SubMesh visorPart;
		visorPart.objectName = "acc_targeting_visor";
		visorPart.materialName = "mat_visor";
		AppendTransformedMesh(visorPart, BuildBox(0.022f, 0.068f, 0.095f), TRS(glm::vec3(0.285f, 0.145f, 0.088f), glm::vec3(0, 14, 0)));
		asset.parts.push_back(std::move(visorPart));

		SubMesh blasterPart;
		blasterPart.objectName = "acc_seed_blaster";
		blasterPart.materialName = "mat_stone";
		AppendTransformedMesh(blasterPart, BuildCylinder(0.032f, 0.038f, 0.38f, 14), TRS(glm::vec3(0.18f, -0.02f, 0.32f), glm::vec3(0, 0, -90)));
		AppendTransformedMesh(blasterPart, BuildCylinder(0.032f, 0.038f, 0.34f, 14), TRS(glm::vec3(0.16f, -0.08f, 0.32f), glm::vec3(0, 0, -90)));
		AppendTransformedMesh(blasterPart, BuildBox(0.14f, 0.10f, 0.085f),            TRS(glm::vec3(0.04f, -0.05f, 0.31f)));
		asset.parts.push_back(std::move(blasterPart));
		break;
	}

	// 6. BAMBU-KATANA CAPI (Atletis Ronin + Rambut Pirang + Pedang KATANA Lengkung Baja & Pelindung Emas!)
	case CapyVariant::BambuSaber: {
		asset.modelName = "capy_bambu_saber";
		AddUniqueMaterial(asset, MakeMat("mat_fur_jedi", "tex_capy_jedi.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_belly", "tex_capy_belly.bmp"));

		SubMesh body = BuildBodySilhouetteMesh(BodySilhouette::HeroicRonin);
		body.objectName = "capy_body";
		body.materialName = "mat_fur_jedi";
		asset.parts.push_back(std::move(body));

		SubMesh belly;
		belly.objectName = "capy_belly";
		belly.materialName = "mat_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.16f, 0.20f, 0.20f, 12, 16), TRS(glm::vec3(0.14f, -0.09f, 0.0f), glm::vec3(0, 0, -10)));
		asset.parts.push_back(std::move(belly));

		FaceConfig face;
		face.eyeAnchor = glm::vec3(0.22f, 0.14f, 0.0f);
		face.eyeSpacingZ = 0.082f;
		face.eyeScale = 1.15f;
		face.snoutPos = glm::vec3(0.28f, 0.02f, 0.0f);
		face.snoutScale = glm::vec3(0.10f, 0.088f, 0.115f);
		face.brow = BrowStyle::SharpFocused;
		face.mouth = MouthStyle::LopsidedGrin;
		BuildExpressiveFace(asset, face, "mat_brow_brown", "tex_capy_snout.bmp");

		// Rambut pirang berponi + ikat kepala bambu hijau
		AddUniqueMaterial(asset, MakeMat("mat_hair_blonde", "tex_hair_blonde.bmp"));
		SubMesh hairPart;
		hairPart.objectName = "acc_ronin_hair";
		hairPart.materialName = "mat_hair_blonde";
		std::array<glm::vec3, 4> bang1 = {{ {0.02f,0.34f,0.0f}, {0.14f,0.38f,0.06f}, {0.22f,0.30f,0.12f}, {0.26f,0.23f,0.15f} }};
		std::array<glm::vec3, 4> bang2 = {{ {0.02f,0.34f,0.0f}, {0.14f,0.38f,-0.06f}, {0.22f,0.30f,-0.12f}, {0.26f,0.23f,-0.15f} }};
		AppendTransformedMesh(hairPart, BuildEllipsoid(0.15f, 0.07f, 0.17f, 10, 14), TRS(glm::vec3(0.05f, 0.34f, 0.0f), glm::vec3(0, 0, -10)));
		AppendTransformedMesh(hairPart, BuildBezierTube(bang1, 0.044f, 0.015f), glm::mat4(1.0f));
		AppendTransformedMesh(hairPart, BuildBezierTube(bang2, 0.044f, 0.015f), glm::mat4(1.0f));
		asset.parts.push_back(std::move(hairPart));

		// KATANA Lengkung Jepang (Gagang Tsuka hijau-gelap + Tsuba emas + Bilah Baja melengkung Bezier)
		AddUniqueMaterial(asset, MakeMat("mat_bamboo", "tex_bamboo.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_gold", "tex_accent_gold.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_katana_steel", "tex_katana_steel.bmp", glm::vec3(1.0f), glm::vec3(0.08f), 110.0f));

		const glm::mat4 katanaXf = TRS(glm::vec3(0.18f, -0.02f, 0.33f), glm::vec3(0.0f, 0.0f, -32.0f));

		SubMesh hiltPart;
		hiltPart.objectName = "acc_katana_tsuka";
		hiltPart.materialName = "mat_bamboo";
		AppendTransformedMesh(hiltPart, BuildCylinder(0.026f, 0.028f, 0.22f, 12), katanaXf);
		asset.parts.push_back(std::move(hiltPart));

		SubMesh tsubaPart;
		tsubaPart.objectName = "acc_katana_tsuba";
		tsubaPart.materialName = "mat_gold";
		AppendTransformedMesh(tsubaPart, BuildCylinder(0.062f, 0.062f, 0.020f, 16), katanaXf * TRS(glm::vec3(0.0f, 0.115f, 0.0f)));
		asset.parts.push_back(std::move(tsubaPart));

		// Bilah baja Katana melengkung halus (Bezier Tube dipipihkan di sumbu Z)
		SubMesh bladePart;
		bladePart.objectName = "acc_katana_blade";
		bladePart.materialName = "mat_katana_steel";
		std::array<glm::vec3, 4> bladeCurve = {{
			{ 0.000f, 0.125f, 0.0f },
			{ 0.008f, 0.350f, 0.0f },
			{ 0.032f, 0.570f, 0.0f },
			{ 0.082f, 0.780f, 0.0f }
		}};
		SubMesh curvedBlade = BuildBezierTube(bladeCurve, 0.028f, 0.008f, 16, 10, true);
		AppendTransformedMesh(bladePart, curvedBlade, katanaXf * TRS(glm::vec3(0.0f), glm::vec3(0.0f), glm::vec3(1.1f, 1.0f, 0.24f)));
		asset.parts.push_back(std::move(bladePart));
		break;
	}

	// 7. HEAVY ONSEN CAPI (Terence-style Bongkahan Raksasa Lebar + Alis Menyatu Garang + Taring + Kumis + Batu Onsen)
	case CapyVariant::HeavyOnsen: {
		asset.modelName = "capy_heavy_onsen";
		AddUniqueMaterial(asset, MakeMat("mat_fur_maroon", "tex_capy_maroon.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_belly", "tex_capy_belly.bmp"));

		SubMesh body = BuildBodySilhouetteMesh(BodySilhouette::MassiveBoulder);
		body.objectName = "capy_body";
		body.materialName = "mat_fur_maroon";
		asset.parts.push_back(std::move(body));

		SubMesh belly;
		belly.objectName = "capy_belly";
		belly.materialName = "mat_belly";
		AppendTransformedMesh(belly, BuildEllipsoid(0.28f, 0.25f, 0.34f, 12, 16), TRS(glm::vec3(0.22f, -0.14f, 0.0f)));
		asset.parts.push_back(std::move(belly));

		FaceConfig face;
		face.eyeAnchor = glm::vec3(0.41f, 0.13f, 0.0f);
		face.eyeSpacingZ = 0.108f;
		face.eyeScale = 1.05f;
		face.snoutPos = glm::vec3(0.46f, -0.02f, 0.0f);
		face.snoutScale = glm::vec3(0.135f, 0.115f, 0.165f);
		face.brow = BrowStyle::TerenceScowl;
		face.mouth = MouthStyle::UnderbiteFangs;
		BuildExpressiveFace(asset, face, "mat_brow_dark", "tex_capy_obsidian.bmp");

		AddUniqueMaterial(asset, MakeMat("mat_towel", "tex_towel.bmp"));
		AddUniqueMaterial(asset, MakeMat("mat_stone", "tex_stone.bmp"));

		SubMesh stachePart;
		stachePart.objectName = "acc_heavy_mustache_towel";
		stachePart.materialName = "mat_towel";
		std::array<glm::vec3, 4> stacheL = {{ {0.50f,0.01f,0.03f}, {0.52f,-0.01f,0.14f}, {0.48f,-0.06f,0.24f}, {0.42f,-0.03f,0.30f} }};
		std::array<glm::vec3, 4> stacheR = {{ {0.50f,0.01f,-0.03f}, {0.52f,-0.01f,-0.14f}, {0.48f,-0.06f,-0.24f}, {0.42f,-0.03f,-0.30f} }};
		AppendTransformedMesh(stachePart, BuildBezierTube(stacheL, 0.032f, 0.010f), glm::mat4(1.0f));
		AppendTransformedMesh(stachePart, BuildBezierTube(stacheR, 0.032f, 0.010f), glm::mat4(1.0f));
		AppendTransformedMesh(stachePart, BuildBox(0.42f, 0.08f, 0.40f), TRS(glm::vec3(-0.08f, 0.45f, 0.0f), glm::vec3(0, 0, 6)));
		asset.parts.push_back(std::move(stachePart));

		SubMesh stonePart;
		stonePart.objectName = "acc_onsen_stone";
		stonePart.materialName = "mat_stone";
		AppendTransformedMesh(stonePart, BuildEllipsoid(0.21f, 0.13f, 0.19f, 12, 16), TRS(glm::vec3(-0.09f, 0.57f, 0.0f), glm::vec3(0, 0, 6)));
		asset.parts.push_back(std::move(stonePart));
		break;
	}
	}

	return asset;
}

std::vector<ModelAsset> BuildAllCapybarasW12() {
	std::vector<ModelAsset> out;
	const auto& roster = GetCapyW12Roster();
	out.reserve(roster.size());
	for (const auto& info : roster) {
		out.push_back(BuildCapybaraW12(info.variant));
	}
	return out;
}
