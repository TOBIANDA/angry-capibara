#define _USE_MATH_DEFINES
#include <cmath>
#include <filesystem>
#include <iostream>
#include <map>
#include <string>
#include <vector>

#ifndef GLEW_STATIC
#define GLEW_STATIC
#endif
#include <GL/glew.h>
#include <GL/freeglut.h>

#include <cstring>
#include <fstream>
#include "bmp_generator.h"
#include "getBMP.h"
#include "mesh_exporter.h"
#include "models_capybara.h"
#include "models_capybara_anime.h"
#include "home2d_painter.h"

namespace fs = std::filesystem;

namespace {
std::string g_outputRoot = "../godot_project/assets/generated";
std::string g_snapshotPath;
std::vector<ModelAsset> g_modelsOriginal;
std::vector<ModelAsset> g_modelsAnime;
bool g_animeMode = true; // Default ke versi paralel Anime 2.5D agar langsung terlihat, tekan [A] untuk bandingkan
int g_currentIdx = 0;
bool g_showAll = true;

// Preview camera & interaction state
float g_rotX = 16.0f;
float g_rotY = -28.0f;
float g_rotZ = 0.0f;
float g_zoom = 5.35f;
bool g_wireframe = false;
bool g_useTexture = true;
bool g_autoSpin = false;

int g_lastMouseX = 0;
int g_lastMouseY = 0;
bool g_dragging = false;

std::map<std::string, GLuint> g_glTextures;

std::string ResolveDefaultOutputRoot() {
	if (fs::exists("../godot_project")) return "../godot_project/assets/generated";
	if (fs::exists("../../../godot_project")) return "../../../godot_project/assets/generated";
	return "../godot_project/assets/generated";
}

bool SaveFramebufferBMP(const std::string& path, int w, int h) {
	const int rowBytes = w * 3;
	const int padding = (rowBytes % 4) ? (4 - (rowBytes % 4)) : 0;
	const int stride = rowBytes + padding;
	std::vector<uint8_t> pixels(static_cast<size_t>(stride) * h, 0);

	glPixelStorei(GL_PACK_ALIGNMENT, 4);
	glFinish();
	glReadBuffer(GL_BACK);
	glReadPixels(0, 0, w, h, GL_BGR_EXT, GL_UNSIGNED_BYTE, pixels.data());

	uint32_t dataSize = static_cast<uint32_t>(stride * h);
	uint32_t fileSize = 54u + dataSize;
	uint8_t header[54] = {};
	header[0] = 'B'; header[1] = 'M';
	std::memcpy(&header[2], &fileSize, 4);
	uint32_t offset = 54u; std::memcpy(&header[10], &offset, 4);
	uint32_t dibSize = 40u; std::memcpy(&header[14], &dibSize, 4);
	std::memcpy(&header[18], &w, 4);
	std::memcpy(&header[22], &h, 4);
	uint16_t planes = 1; std::memcpy(&header[26], &planes, 2);
	uint16_t bpp = 24; std::memcpy(&header[28], &bpp, 2);
	std::memcpy(&header[34], &dataSize, 4);

	std::ofstream out(path, std::ios::binary);
	if (!out.is_open()) return false;
	out.write(reinterpret_cast<const char*>(header), 54);
	out.write(reinterpret_cast<const char*>(pixels.data()), dataSize);
	return out.good();
}

bool RunExportW12(const std::string& outRoot) {
	const std::string texDir = outRoot + "/textures";
	const std::string modelDir = outRoot + "/models";
	std::error_code ec;
	fs::create_directories(texDir, ec);
	fs::create_directories(modelDir, ec);
	if (ec) {
		std::cerr << "[ERROR] Failed creating output directories: " << ec.message() << "\n";
		return false;
	}

	std::cout << "[AssetForge] Generating 24-bit BMP textures -> " << texDir << "\n";
	if (!GenerateAllTexturesW12(texDir)) {
		std::cerr << "[ERROR] Texture generation failed.\n";
		return false;
	}

	auto exportList = [&](const std::vector<ModelAsset>& list) -> bool {
		for (const auto& asset : list) {
			if (!ExportModelToOBJ(asset, modelDir)) {
				std::cerr << "[ERROR] Failed exporting " << asset.modelName << ".obj\n";
				return false;
			}
			size_t totalVerts = 0, totalTris = 0;
			for (const auto& p : asset.parts) {
				totalVerts += p.vertices.size();
				totalTris += p.indices.size() / 3;
			}
			std::cout << "  -> Exported " << asset.modelName << ".obj ("
					  << asset.parts.size() << " parts, "
					  << totalVerts << " verts, "
					  << totalTris << " tris)\n";
		}
		return true;
	};

	if (!exportList(BuildAllCapybarasW12())) return false;
	if (!exportList(BuildAllCapybarasAnimeW12())) return false;
	if (!exportList(BuildAllHomeKeyArtAssets())) return false;
	if (!GenerateAllHome2DLayers(outRoot + "/home2d")) return false;
	return true;
}

void LoadTexturesFromList(const std::vector<ModelAsset>& models, const std::string& texDir) {
	for (const auto& model : models) {
		for (const auto& mat : model.materials) {
			if (mat.textureFile.empty() || g_glTextures.count(mat.textureFile)) continue;
			std::string fullPath = texDir + "/" + mat.textureFile;
			imageFile* img = getBMP(fullPath);
			if (!img) {
				std::cerr << "[WARN] Could not load BMP preview: " << fullPath << "\n";
				continue;
			}
			GLuint texId = 0;
			glGenTextures(1, &texId);
			glBindTexture(GL_TEXTURE_2D, texId);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, img->width, img->height, 0,
						 GL_RGBA, GL_UNSIGNED_BYTE, img->data);
			g_glTextures[mat.textureFile] = texId;
			delete[] img->data;
			delete img;
		}
	}
}

void LoadPreviewTextures(const std::string& texDir) {
	for (auto& kv : g_glTextures) {
		glDeleteTextures(1, &kv.second);
	}
	g_glTextures.clear();
	LoadTexturesFromList(g_modelsOriginal, texDir);
	LoadTexturesFromList(g_modelsAnime, texDir);
}

const MaterialDef* FindMaterial(const ModelAsset& asset, const std::string& name) {
	for (const auto& m : asset.materials) {
		if (m.name == name) return &m;
	}
	return nullptr;
}

void DrawBitmapText(float x, float y, const std::string& text) {
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	int w = glutGet(GLUT_WINDOW_WIDTH);
	int h = glutGet(GLUT_WINDOW_HEIGHT);
	gluOrtho2D(0, w, 0, h);
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();

	glDisable(GL_LIGHTING);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	glColor3f(0.95f, 0.96f, 0.98f);
	glRasterPos2f(x, y);
	for (char ch : text) {
		glutBitmapCharacter(GLUT_BITMAP_9_BY_15, ch);
	}
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_LIGHTING);

	glPopMatrix();
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
}

void DrawGridFloor() {
	glDisable(GL_LIGHTING);
	glDisable(GL_TEXTURE_2D);
	glColor3f(0.28f, 0.31f, 0.36f);
	glBegin(GL_LINES);
	for (int i = -4; i <= 4; ++i) {
		float v = i * 0.25f;
		glVertex3f(v, -0.38f, -1.0f);
		glVertex3f(v, -0.38f,  1.0f);
		glVertex3f(-1.0f, -0.38f, v);
		glVertex3f( 1.0f, -0.38f, v);
	}
	glEnd();
	glEnable(GL_LIGHTING);
}

void DrawModelAsset(const ModelAsset& asset) {
	// Pass 1 (Anime Ink Outline via Inverted Hull)
	if (g_animeMode && !g_wireframe) {
		glDisable(GL_LIGHTING);
		glDisable(GL_TEXTURE_2D);
		glCullFace(GL_FRONT);
		glColor3f(0.08f, 0.05f, 0.07f);
		const float outlineThickness = 0.011f;
		glBegin(GL_TRIANGLES);
		for (const auto& part : asset.parts) {
			for (size_t i = 0; i + 2 < part.indices.size(); i += 3) {
				for (int k = 0; k < 3; ++k) {
					const Vertex& v = part.vertices[part.indices[i + k]];
					glm::vec3 p = v.pos + v.normal * outlineThickness;
					glVertex3f(p.x, p.y, p.z);
				}
			}
		}
		glEnd();
		glCullFace(GL_BACK);
		glEnable(GL_LIGHTING);
	}

	glPolygonMode(GL_FRONT_AND_BACK, g_wireframe ? GL_LINE : GL_FILL);

	for (const auto& part : asset.parts) {
		const MaterialDef* mat = FindMaterial(asset, part.materialName);
		GLuint texId = 0;
		if (mat && g_useTexture && !g_wireframe && !mat->textureFile.empty()) {
			auto it = g_glTextures.find(mat->textureFile);
			if (it != g_glTextures.end()) texId = it->second;
		}

		if (texId != 0) {
			glEnable(GL_TEXTURE_2D);
			glBindTexture(GL_TEXTURE_2D, texId);
		} else {
			glDisable(GL_TEXTURE_2D);
		}

		float kd[4] = { 1, 1, 1, 1 };
		float ke[4] = { 0, 0, 0, 1 };
		if (mat) {
			kd[0] = mat->kd.r; kd[1] = mat->kd.g; kd[2] = mat->kd.b;
			ke[0] = mat->ke.r; ke[1] = mat->ke.g; ke[2] = mat->ke.b;
		}
		// Di mode anime, tambahkan sedikit self-lit fill agar bayangan lebih cerah seperti cel-shading
		if (g_animeMode) {
			ke[0] = std::max(ke[0], kd[0] * 0.25f);
			ke[1] = std::max(ke[1], kd[1] * 0.25f);
			ke[2] = std::max(ke[2], kd[2] * 0.25f);
		}
		glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, kd);
		glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, ke);

		glBegin(GL_TRIANGLES);
		for (size_t i = 0; i + 2 < part.indices.size(); i += 3) {
			for (int k = 0; k < 3; ++k) {
				const Vertex& v = part.vertices[part.indices[i + k]];
				glNormal3f(v.normal.x, v.normal.y, v.normal.z);
				glTexCoord2f(v.uv.x, v.uv.y);
				glVertex3f(v.pos.x, v.pos.y, v.pos.z);
			}
		}
		glEnd();
	}
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	glDisable(GL_TEXTURE_2D);
}

void Display() {
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	gluLookAt(0.0, 0.25, g_zoom, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);

	glRotatef(g_rotX, 1.0f, 0.0f, 0.0f);
	glRotatef(g_rotY, 0.0f, 1.0f, 0.0f);
	glRotatef(g_rotZ, 0.0f, 0.0f, 1.0f);

	const auto& activeModels = g_animeMode ? g_modelsAnime : g_modelsOriginal;
	const auto& activeRoster = g_animeMode ? GetCapyAnimeW12Roster() : GetCapyW12Roster();

	if (!activeModels.empty()) {
		if (g_showAll) {
			const float positions[7][3] = {
				{ -1.25f,  0.60f, 0.0f },
				{  0.00f,  0.60f, 0.0f },
				{  1.25f,  0.60f, 0.0f },
				{ -1.65f, -0.60f, 0.0f },
				{ -0.55f, -0.60f, 0.0f },
				{  0.55f, -0.60f, 0.0f },
				{  1.65f, -0.60f, 0.0f }
			};
			for (size_t idx = 0; idx < activeModels.size() && idx < 7; ++idx) {
				glPushMatrix();
				glTranslatef(positions[idx][0], positions[idx][1], positions[idx][2]);
				DrawModelAsset(activeModels[idx]);
				glPopMatrix();
			}
			std::string hdr = g_animeMode
				? "[ANIME 2.5D + INK] Top: W1 (Chill, Dash, Mini) | Bottom: W2 (Yuzu Bomb, Blaster, Katana, Heavy)"
				: "[ANGRY BIRDS STYLE] Top: W1 (Chill, Dash, Mini) | Bottom: W2 (Yuzu Bomb, Blaster, Katana, Heavy)";
			DrawBitmapText(14.0f, static_cast<float>(glutGet(GLUT_WINDOW_HEIGHT) - 24), hdr);
		} else {
			DrawGridFloor();
			DrawModelAsset(activeModels[g_currentIdx]);
			const auto& info = activeRoster[g_currentIdx];
			std::string title = std::string(g_animeMode ? "[ANIME] " : "[ORIG] ")
				+ "[" + std::to_string(g_currentIdx + 1) + "/7] "
				+ std::string(info.displayName) + " (" + info.worldLabel + ")";
			DrawBitmapText(14.0f, static_cast<float>(glutGet(GLUT_WINDOW_HEIGHT) - 24), title);
		}
		DrawBitmapText(14.0f, 16.0f,
			"[A] Toggle Anime/Orig | [0] All | [1-7] Single | Drag/XYZ | Scroll | [W] Wire | [Space] Spin");
	}

	if (!g_snapshotPath.empty()) {
		int w = glutGet(GLUT_WINDOW_WIDTH);
		int h = glutGet(GLUT_WINDOW_HEIGHT);
		SaveFramebufferBMP(g_snapshotPath, w, h);
		g_snapshotPath.clear();
		glutSwapBuffers();
		exit(0);
	}

	glutSwapBuffers();
}

void Reshape(int w, int h) {
	if (h == 0) h = 1;
	glViewport(0, 0, w, h);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(42.0, static_cast<double>(w) / static_cast<double>(h), 0.1, 50.0);
	glMatrixMode(GL_MODELVIEW);
}

void Keyboard(unsigned char key, int, int) {
	if (key == '0') {
		g_showAll = true;
		g_zoom = 5.35f;
		g_rotX = 16.0f; g_rotY = -28.0f; g_rotZ = 0.0f;
	} else if (key >= '1' && key <= '7') {
		g_showAll = false;
		g_currentIdx = key - '1';
		g_zoom = 2.2f;
	} else if (key == '[' || key == '{') {
		g_showAll = false;
		g_currentIdx = (g_currentIdx + 6) % 7;
	} else if (key == ']' || key == '}') {
		g_showAll = false;
		g_currentIdx = (g_currentIdx + 1) % 7;
	} else if (key == 'a' || key == 'A') {
		g_animeMode = !g_animeMode;
	} else if (key == 'x') g_rotX += 5.0f;
	else if (key == 'X') g_rotX -= 5.0f;
	else if (key == 'y') g_rotY += 5.0f;
	else if (key == 'Y') g_rotY -= 5.0f;
	else if (key == 'z') g_rotZ += 5.0f;
	else if (key == 'Z') g_rotZ -= 5.0f;
	else if (key == 'w' || key == 'W') g_wireframe = !g_wireframe;
	else if (key == 't' || key == 'T') g_useTexture = !g_useTexture;
	else if (key == ' ') g_autoSpin = !g_autoSpin;
	else if (key == 'r' || key == 'R') { g_rotX = 16.0f; g_rotY = -28.0f; g_rotZ = 0.0f; g_zoom = g_showAll ? 5.35f : 2.2f; }
	else if (key == 'e' || key == 'E') { RunExportW12(g_outputRoot); }
	else if (key == 27) exit(0);
	glutPostRedisplay();
}

void Mouse(int button, int state, int x, int y) {
	if (button == GLUT_LEFT_BUTTON) {
		g_dragging = (state == GLUT_DOWN);
		g_lastMouseX = x;
		g_lastMouseY = y;
	} else if (button == 3 && state == GLUT_DOWN) {
		g_zoom = std::max(1.0f, g_zoom - 0.18f);
		glutPostRedisplay();
	} else if (button == 4 && state == GLUT_DOWN) {
		g_zoom = std::min(6.0f, g_zoom + 0.18f);
		glutPostRedisplay();
	}
}

void Motion(int x, int y) {
	if (!g_dragging) return;
	g_rotY += (x - g_lastMouseX) * 0.6f;
	g_rotX += (y - g_lastMouseY) * 0.6f;
	g_lastMouseX = x;
	g_lastMouseY = y;
	glutPostRedisplay();
}

void Timer(int) {
	if (g_autoSpin) {
		g_rotY += 1.0f;
		glutPostRedisplay();
	}
	glutTimerFunc(16, Timer, 0);
}

void InitGL() {
	glClearColor(0.14f, 0.16f, 0.20f, 1.0f);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_NORMALIZE);

	float lightPos[4] = { 2.5f, 3.5f, 3.0f, 0.0f };
	float ambient[4]  = { 0.35f, 0.35f, 0.38f, 1.0f };
	float diffuse[4]  = { 0.95f, 0.95f, 0.92f, 1.0f };
	glLightfv(GL_LIGHT0, GL_POSITION, lightPos);
	glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
}
} // namespace

int main(int argc, char** argv) {
	bool exportOnly = false;
	bool exportHome2DOnly = false;
	bool customOut = false;
	for (int i = 1; i < argc; ++i) {
		std::string arg = argv[i];
		if (arg == "--export-w12" || arg == "--export-all") {
			exportOnly = true;
		} else if (arg == "--export-home-2d") {
			exportHome2DOnly = true;
		} else if (arg == "--out" && i + 1 < argc) {
			g_outputRoot = argv[++i];
			customOut = true;
		} else if (arg == "--snapshot" && i + 1 < argc) {
			g_snapshotPath = argv[++i];
		} else if (arg == "--orig") {
			g_animeMode = false;
		} else if (arg == "--anime") {
			g_animeMode = true;
		} else if (arg == "--single" && i + 1 < argc) {
			int idx = std::stoi(argv[++i]) - 1;
			if (idx >= 0 && idx < 7) {
				g_showAll = false;
				g_currentIdx = idx;
				g_zoom = 2.0f;
			}
		}
	}
	if (!customOut) {
		g_outputRoot = ResolveDefaultOutputRoot();
	}

	if (exportHome2DOnly) {
		return GenerateAllHome2DLayers(g_outputRoot + "/home2d") ? 0 : 1;
	}
	if (exportOnly) {
		return RunExportW12(g_outputRoot) ? 0 : 1;
	}

	// Ensure assets exist before opening interactive previewer
	RunExportW12(g_outputRoot);
	g_modelsOriginal = BuildAllCapybarasW12();
	g_modelsAnime = BuildAllCapybarasAnimeW12();

	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
	glutInitWindowSize(900, 700);
	glutCreateWindow("Angry Capibara - Visual Studio OpenGL Asset Forge (W1 & W2)");
	glewInit();
	InitGL();
	LoadPreviewTextures(g_outputRoot + "/textures");

	glutDisplayFunc(Display);
	glutReshapeFunc(Reshape);
	glutKeyboardFunc(Keyboard);
	glutMouseFunc(Mouse);
	glutMotionFunc(Motion);
	glutTimerFunc(16, Timer, 0);
	glutMainLoop();
	return 0;
}
