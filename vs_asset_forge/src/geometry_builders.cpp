#include "geometry_builders.h"
#include <cmath>
#include <algorithm>

namespace {
constexpr float kPi = 3.14159265358979323846f;

inline float Bernstein3(int i, float t) {
	const float u = 1.0f - t;
	switch (i) {
		case 0: return u * u * u;
		case 1: return 3.0f * t * u * u;
		case 2: return 3.0f * t * t * u;
		case 3: return t * t * t;
		default: return 0.0f;
	}
}

inline float Bernstein3Deriv(int i, float t) {
	const float u = 1.0f - t;
	switch (i) {
		case 0: return -3.0f * u * u;
		case 1: return 3.0f * u * u - 6.0f * t * u;
		case 2: return 6.0f * t * u - 3.0f * t * t;
		case 3: return 3.0f * t * t;
		default: return 0.0f;
	}
}

inline glm::vec3 SafeNormalize(const glm::vec3& v, const glm::vec3& fallback) {
	float len = glm::length(v);
	return (len > 1e-5f) ? (v / len) : fallback;
}

void RecomputeMissingNormals(SubMesh& mesh) {
	std::vector<glm::vec3> accum(mesh.vertices.size(), glm::vec3(0.0f));
	for (size_t i = 0; i + 2 < mesh.indices.size(); i += 3) {
		uint32_t a = mesh.indices[i];
		uint32_t b = mesh.indices[i + 1];
		uint32_t c = mesh.indices[i + 2];
		glm::vec3 fn = glm::cross(mesh.vertices[b].pos - mesh.vertices[a].pos,
								  mesh.vertices[c].pos - mesh.vertices[a].pos);
		accum[a] += fn;
		accum[b] += fn;
		accum[c] += fn;
	}
	for (size_t i = 0; i < mesh.vertices.size(); ++i) {
		if (glm::length(mesh.vertices[i].normal) < 1e-4f) {
			mesh.vertices[i].normal = SafeNormalize(accum[i], glm::vec3(0.0f, 1.0f, 0.0f));
		}
	}
}
} // namespace

SubMesh BuildBicubicBezierPatch(
	const std::array<std::array<glm::vec3, 4>, 4>& controlPoints,
	int uSteps,
	int vSteps,
	bool flipWinding)
{
	SubMesh mesh;
	const int cols = uSteps + 1;
	const int rows = vSteps + 1;
	mesh.vertices.reserve(cols * rows);

	for (int iv = 0; iv <= vSteps; ++iv) {
		float v = static_cast<float>(iv) / static_cast<float>(vSteps);
		for (int iu = 0; iu <= uSteps; ++iu) {
			float u = static_cast<float>(iu) / static_cast<float>(uSteps);

			glm::vec3 pos(0.0f);
			glm::vec3 du(0.0f);
			glm::vec3 dv(0.0f);

			for (int i = 0; i < 4; ++i) {
				float bi = Bernstein3(i, u);
				float dbi = Bernstein3Deriv(i, u);
				for (int j = 0; j < 4; ++j) {
					float bj = Bernstein3(j, v);
					float dbj = Bernstein3Deriv(j, v);
					const glm::vec3& p = controlPoints[i][j];
					pos += (bi * bj) * p;
					du += (dbi * bj) * p;
					dv += (bi * dbj) * p;
				}
			}

			glm::vec3 n = glm::cross(du, dv);
			if (flipWinding) n = -n;
			float len = glm::length(n);

			Vertex vert;
			vert.pos = pos;
			vert.normal = (len > 1e-5f) ? (n / len) : glm::vec3(0.0f);
			vert.uv = glm::vec2(u, v);
			mesh.vertices.push_back(vert);
		}
	}

	for (int iv = 0; iv < vSteps; ++iv) {
		for (int iu = 0; iu < uSteps; ++iu) {
			uint32_t i0 = static_cast<uint32_t>(iv * cols + iu);
			uint32_t i1 = i0 + 1;
			uint32_t i2 = i0 + static_cast<uint32_t>(cols);
			uint32_t i3 = i2 + 1;
			if (!flipWinding) {
				mesh.indices.push_back(i0);
				mesh.indices.push_back(i1);
				mesh.indices.push_back(i2);
				mesh.indices.push_back(i1);
				mesh.indices.push_back(i3);
				mesh.indices.push_back(i2);
			} else {
				mesh.indices.push_back(i0);
				mesh.indices.push_back(i2);
				mesh.indices.push_back(i1);
				mesh.indices.push_back(i1);
				mesh.indices.push_back(i2);
				mesh.indices.push_back(i3);
			}
		}
	}

	RecomputeMissingNormals(mesh);
	return mesh;
}

SubMesh BuildBezierRevolvedProfile(
	const std::array<glm::vec2, 4>& profileRX,
	int axialSteps,
	int radialSteps)
{
	SubMesh mesh;
	const int cols = radialSteps + 1;
	mesh.vertices.reserve((axialSteps + 1) * cols);

	for (int ia = 0; ia <= axialSteps; ++ia) {
		float t = static_cast<float>(ia) / static_cast<float>(axialSteps);
		float r = 0.0f, x = 0.0f;
		float dr = 0.0f, dx = 0.0f;

		for (int k = 0; k < 4; ++k) {
			float b = Bernstein3(k, t);
			float db = Bernstein3Deriv(k, t);
			r += b * profileRX[k].x;
			x += b * profileRX[k].y;
			dr += db * profileRX[k].x;
			dx += db * profileRX[k].y;
		}
		r = std::max(0.0f, r);

		for (int ir = 0; ir <= radialSteps; ++ir) {
			float u = static_cast<float>(ir) / static_cast<float>(radialSteps);
			float phi = u * 2.0f * kPi;
			float c = std::cos(phi);
			float s = std::sin(phi);

			Vertex v;
			v.pos = glm::vec3(x, r * c, r * s);
			glm::vec3 dPhi(0.0f, -r * s, r * c);
			glm::vec3 dT(dx, dr * c, dr * s);
			glm::vec3 n = glm::cross(dPhi, dT);
			if (r < 1e-4f) {
				v.normal = glm::vec3((dx >= 0.0f && ia > axialSteps / 2) ? 1.0f : -1.0f, 0.0f, 0.0f);
			} else {
				v.normal = SafeNormalize(n, glm::vec3(0.0f, c, s));
			}
			v.uv = glm::vec2(t, u);
			mesh.vertices.push_back(v);
		}
	}

	for (int ia = 0; ia < axialSteps; ++ia) {
		for (int ir = 0; ir < radialSteps; ++ir) {
			uint32_t i0 = static_cast<uint32_t>(ia * cols + ir);
			uint32_t i1 = i0 + 1;
			uint32_t i2 = i0 + static_cast<uint32_t>(cols);
			uint32_t i3 = i2 + 1;
			mesh.indices.push_back(i0);
			mesh.indices.push_back(i1);
			mesh.indices.push_back(i2);
			mesh.indices.push_back(i1);
			mesh.indices.push_back(i3);
			mesh.indices.push_back(i2);
		}
	}

	return mesh;
}

SubMesh BuildBezierTube(
	const std::array<glm::vec3, 4>& curvePoints,
	float rStart,
	float rEnd,
	int pathSteps,
	int radialSteps,
	bool capEnds)
{
	SubMesh mesh;
	const int cols = radialSteps + 1;

	glm::vec3 prevUp(0.0f, 1.0f, 0.0f);
	for (int ip = 0; ip <= pathSteps; ++ip) {
		float t = static_cast<float>(ip) / static_cast<float>(pathSteps);
		glm::vec3 pos(0.0f);
		glm::vec3 tan(0.0f);
		for (int k = 0; k < 4; ++k) {
			pos += Bernstein3(k, t) * curvePoints[k];
			tan += Bernstein3Deriv(k, t) * curvePoints[k];
		}
		tan = SafeNormalize(tan, glm::vec3(1.0f, 0.0f, 0.0f));
		if (std::abs(glm::dot(tan, prevUp)) > 0.95f) {
			prevUp = glm::vec3(0.0f, 0.0f, 1.0f);
		}
		glm::vec3 binorm = SafeNormalize(glm::cross(tan, prevUp), glm::vec3(0.0f, 0.0f, 1.0f));
		glm::vec3 norm = SafeNormalize(glm::cross(binorm, tan), glm::vec3(0.0f, 1.0f, 0.0f));
		prevUp = norm;

		float r = rStart + (rEnd - rStart) * t;
		for (int ir = 0; ir <= radialSteps; ++ir) {
			float u = static_cast<float>(ir) / static_cast<float>(radialSteps);
			float phi = u * 2.0f * kPi;
			glm::vec3 radialDir = std::cos(phi) * norm + std::sin(phi) * binorm;

			Vertex v;
			v.pos = pos + r * radialDir;
			v.normal = SafeNormalize(radialDir, norm);
			v.uv = glm::vec2(t, u);
			mesh.vertices.push_back(v);
		}
	}

	for (int ip = 0; ip < pathSteps; ++ip) {
		for (int ir = 0; ir < radialSteps; ++ir) {
			uint32_t i0 = static_cast<uint32_t>(ip * cols + ir);
			uint32_t i1 = i0 + 1;
			uint32_t i2 = i0 + static_cast<uint32_t>(cols);
			uint32_t i3 = i2 + 1;
			mesh.indices.push_back(i0);
			mesh.indices.push_back(i1);
			mesh.indices.push_back(i2);
			mesh.indices.push_back(i1);
			mesh.indices.push_back(i3);
			mesh.indices.push_back(i2);
		}
	}

	if (capEnds && pathSteps >= 1) {
		// Start cap
		glm::vec3 p0 = curvePoints[0];
		glm::vec3 t0 = SafeNormalize(curvePoints[1] - curvePoints[0], glm::vec3(1.0f, 0.0f, 0.0f));
		uint32_t centerStart = static_cast<uint32_t>(mesh.vertices.size());
		mesh.vertices.push_back({ p0, -t0, glm::vec2(0.5f, 0.5f) });
		for (int ir = 0; ir < radialSteps; ++ir) {
			mesh.indices.push_back(centerStart);
			mesh.indices.push_back(static_cast<uint32_t>(ir + 1));
			mesh.indices.push_back(static_cast<uint32_t>(ir));
		}

		// End cap
		glm::vec3 pEnd = curvePoints[3];
		glm::vec3 tEnd = SafeNormalize(curvePoints[3] - curvePoints[2], glm::vec3(1.0f, 0.0f, 0.0f));
		uint32_t centerEnd = static_cast<uint32_t>(mesh.vertices.size());
		mesh.vertices.push_back({ pEnd, tEnd, glm::vec2(0.5f, 0.5f) });
		uint32_t rowBase = static_cast<uint32_t>(pathSteps * cols);
		for (int ir = 0; ir < radialSteps; ++ir) {
			mesh.indices.push_back(centerEnd);
			mesh.indices.push_back(rowBase + static_cast<uint32_t>(ir));
			mesh.indices.push_back(rowBase + static_cast<uint32_t>(ir + 1));
		}
	}

	return mesh;
}

SubMesh BuildEllipsoid(float rx, float ry, float rz, int stacks, int slices) {
	SubMesh mesh;
	const int cols = slices + 1;
	mesh.vertices.reserve((stacks + 1) * cols);

	for (int i = 0; i <= stacks; ++i) {
		float v = static_cast<float>(i) / static_cast<float>(stacks);
		float theta = v * kPi;
		float sinT = std::sin(theta);
		float cosT = std::cos(theta);

		for (int j = 0; j <= slices; ++j) {
			float u = static_cast<float>(j) / static_cast<float>(slices);
			float phi = u * 2.0f * kPi;
			float cosP = std::cos(phi);
			float sinP = std::sin(phi);

			glm::vec3 pos(rx * sinT * cosP, ry * cosT, rz * sinT * sinP);
			glm::vec3 n = SafeNormalize(
				glm::vec3((sinT * cosP) / std::max(rx, 1e-4f),
						  cosT / std::max(ry, 1e-4f),
						  (sinT * sinP) / std::max(rz, 1e-4f)),
				glm::vec3(0.0f, cosT >= 0.0f ? 1.0f : -1.0f, 0.0f));

			mesh.vertices.push_back({ pos, n, glm::vec2(u, 1.0f - v) });
		}
	}

	for (int i = 0; i < stacks; ++i) {
		for (int j = 0; j < slices; ++j) {
			uint32_t i0 = static_cast<uint32_t>(i * cols + j);
			uint32_t i1 = i0 + static_cast<uint32_t>(cols);
			uint32_t i2 = i0 + 1;
			uint32_t i3 = i1 + 1;

			mesh.indices.push_back(i0);
			mesh.indices.push_back(i2);
			mesh.indices.push_back(i1);

			mesh.indices.push_back(i2);
			mesh.indices.push_back(i3);
			mesh.indices.push_back(i1);
		}
	}

	return mesh;
}

SubMesh BuildCylinder(float rBottom, float rTop, float height, int slices, bool capBottom, bool capTop) {
	SubMesh mesh;
	const float halfH = height * 0.5f;
	const float slope = (rBottom - rTop) / std::max(height, 1e-4f);

	// Side ring bottom (0..slices) and top (slices+1 .. 2*slices+1)
	for (int row = 0; row < 2; ++row) {
		float y = (row == 0) ? -halfH : halfH;
		float r = (row == 0) ? rBottom : rTop;
		float v = (row == 0) ? 0.0f : 1.0f;

		for (int j = 0; j <= slices; ++j) {
			float u = static_cast<float>(j) / static_cast<float>(slices);
			float phi = u * 2.0f * kPi;
			float c = std::cos(phi);
			float s = std::sin(phi);
			glm::vec3 pos(r * c, y, r * s);
			glm::vec3 n = SafeNormalize(glm::vec3(c, slope, s), glm::vec3(0.0f, 1.0f, 0.0f));
			mesh.vertices.push_back({ pos, n, glm::vec2(u, v) });
		}
	}

	const int cols = slices + 1;
	for (int j = 0; j < slices; ++j) {
		uint32_t b0 = static_cast<uint32_t>(j);
		uint32_t b1 = b0 + 1;
		uint32_t t0 = b0 + static_cast<uint32_t>(cols);
		uint32_t t1 = t0 + 1;

		mesh.indices.push_back(b0);
		mesh.indices.push_back(t0);
		mesh.indices.push_back(b1);

		mesh.indices.push_back(t0);
		mesh.indices.push_back(t1);
		mesh.indices.push_back(b1);
	}

	if (capTop && rTop > 1e-5f) {
		uint32_t centerIdx = static_cast<uint32_t>(mesh.vertices.size());
		mesh.vertices.push_back({ glm::vec3(0.0f, halfH, 0.0f), glm::vec3(0.0f, 1.0f, 0.0f), glm::vec2(0.5f, 0.5f) });
		uint32_t ringStart = static_cast<uint32_t>(mesh.vertices.size());
		for (int j = 0; j <= slices; ++j) {
			float phi = (static_cast<float>(j) / static_cast<float>(slices)) * 2.0f * kPi;
			float c = std::cos(phi), s = std::sin(phi);
			mesh.vertices.push_back({
				glm::vec3(rTop * c, halfH, rTop * s),
				glm::vec3(0.0f, 1.0f, 0.0f),
				glm::vec2(0.5f + 0.5f * c, 0.5f + 0.5f * s)
			});
		}
		for (int j = 0; j < slices; ++j) {
			mesh.indices.push_back(centerIdx);
			mesh.indices.push_back(ringStart + static_cast<uint32_t>(j + 1));
			mesh.indices.push_back(ringStart + static_cast<uint32_t>(j));
		}
	}

	if (capBottom && rBottom > 1e-5f) {
		uint32_t centerIdx = static_cast<uint32_t>(mesh.vertices.size());
		mesh.vertices.push_back({ glm::vec3(0.0f, -halfH, 0.0f), glm::vec3(0.0f, -1.0f, 0.0f), glm::vec2(0.5f, 0.5f) });
		uint32_t ringStart = static_cast<uint32_t>(mesh.vertices.size());
		for (int j = 0; j <= slices; ++j) {
			float phi = (static_cast<float>(j) / static_cast<float>(slices)) * 2.0f * kPi;
			float c = std::cos(phi), s = std::sin(phi);
			mesh.vertices.push_back({
				glm::vec3(rBottom * c, -halfH, rBottom * s),
				glm::vec3(0.0f, -1.0f, 0.0f),
				glm::vec2(0.5f + 0.5f * c, 0.5f + 0.5f * s)
			});
		}
		for (int j = 0; j < slices; ++j) {
			mesh.indices.push_back(centerIdx);
			mesh.indices.push_back(ringStart + static_cast<uint32_t>(j));
			mesh.indices.push_back(ringStart + static_cast<uint32_t>(j + 1));
		}
	}

	return mesh;
}

SubMesh BuildBox(float sx, float sy, float sz) {
	SubMesh mesh;
	const float hx = sx * 0.5f, hy = sy * 0.5f, hz = sz * 0.5f;

	struct FaceDef {
		glm::vec3 n;
		glm::vec3 p[4];
	};

	const FaceDef faces[6] = {
		{ {  0,  0,  1 }, { {-hx,-hy, hz}, { hx,-hy, hz}, { hx, hy, hz}, {-hx, hy, hz} } },
		{ {  0,  0, -1 }, { { hx,-hy,-hz}, {-hx,-hy,-hz}, {-hx, hy,-hz}, { hx, hy,-hz} } },
		{ {  1,  0,  0 }, { { hx,-hy, hz}, { hx,-hy,-hz}, { hx, hy,-hz}, { hx, hy, hz} } },
		{ { -1,  0,  0 }, { {-hx,-hy,-hz}, {-hx,-hy, hz}, {-hx, hy, hz}, {-hx, hy,-hz} } },
		{ {  0,  1,  0 }, { {-hx, hy, hz}, { hx, hy, hz}, { hx, hy,-hz}, {-hx, hy,-hz} } },
		{ {  0, -1,  0 }, { {-hx,-hy,-hz}, { hx,-hy,-hz}, { hx,-hy, hz}, {-hx,-hy, hz} } }
	};

	const glm::vec2 uvs[4] = { {0, 0}, {1, 0}, {1, 1}, {0, 1} };
	for (const auto& f : faces) {
		uint32_t base = static_cast<uint32_t>(mesh.vertices.size());
		for (int k = 0; k < 4; ++k) {
			mesh.vertices.push_back({ f.p[k], f.n, uvs[k] });
		}
		mesh.indices.push_back(base + 0);
		mesh.indices.push_back(base + 1);
		mesh.indices.push_back(base + 2);
		mesh.indices.push_back(base + 0);
		mesh.indices.push_back(base + 2);
		mesh.indices.push_back(base + 3);
	}

	return mesh;
}

SubMesh BuildCone(float radius, float height, int slices, bool capBottom) {
	return BuildCylinder(radius, 0.0f, height, slices, capBottom, false);
}

SubMesh BuildTorus(float majorR, float minorR, int majorSteps, int minorSteps) {
	SubMesh mesh;
	const int cols = minorSteps + 1;
	mesh.vertices.reserve((majorSteps + 1) * cols);

	for (int i = 0; i <= majorSteps; ++i) {
		float u = static_cast<float>(i) / static_cast<float>(majorSteps);
		float theta = u * 2.0f * kPi;
		float ct = std::cos(theta), st = std::sin(theta);

		for (int j = 0; j <= minorSteps; ++j) {
			float v = static_cast<float>(j) / static_cast<float>(minorSteps);
			float phi = v * 2.0f * kPi;
			float cp = std::cos(phi), sp = std::sin(phi);

			float r = majorR + minorR * cp;
			glm::vec3 pos(r * ct, minorR * sp, r * st);
			glm::vec3 n = SafeNormalize(glm::vec3(cp * ct, sp, cp * st), glm::vec3(0.0f, 1.0f, 0.0f));
			mesh.vertices.push_back({ pos, n, glm::vec2(u, v) });
		}
	}

	for (int i = 0; i < majorSteps; ++i) {
		for (int j = 0; j < minorSteps; ++j) {
			uint32_t i0 = static_cast<uint32_t>(i * cols + j);
			uint32_t i1 = i0 + 1;
			uint32_t i2 = i0 + static_cast<uint32_t>(cols);
			uint32_t i3 = i2 + 1;

			mesh.indices.push_back(i0);
			mesh.indices.push_back(i1);
			mesh.indices.push_back(i2);

			mesh.indices.push_back(i1);
			mesh.indices.push_back(i3);
			mesh.indices.push_back(i2);
		}
	}

	return mesh;
}
