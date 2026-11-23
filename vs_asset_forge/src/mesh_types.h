#pragma once

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <string>
#include <vector>
#include <cstdint>

struct Vertex {
	glm::vec3 pos;
	glm::vec3 normal;
	glm::vec2 uv;
};

struct MaterialDef {
	std::string name;
	std::string textureFile; // e.g. "tex_capy_brown.bmp"
	glm::vec3 kd = glm::vec3(1.0f);
	glm::vec3 ks = glm::vec3(0.15f);
	glm::vec3 ke = glm::vec3(0.0f);
	float shininess = 24.0f;
};

struct SubMesh {
	std::string objectName;
	std::string materialName;
	std::vector<Vertex> vertices;
	std::vector<uint32_t> indices; // CCW triangles
};

struct ModelAsset {
	std::string modelName; // base filename without .obj
	std::vector<SubMesh> parts;
	std::vector<MaterialDef> materials;
};

inline void AppendTransformedMesh(
	SubMesh& dst,
	const SubMesh& src,
	const glm::mat4& transform)
{
	const uint32_t baseVertex = static_cast<uint32_t>(dst.vertices.size());
	const glm::mat3 normalMat = glm::transpose(glm::inverse(glm::mat3(transform)));

	dst.vertices.reserve(dst.vertices.size() + src.vertices.size());
	for (const auto& v : src.vertices) {
		Vertex out;
		out.pos = glm::vec3(transform * glm::vec4(v.pos, 1.0f));
		glm::vec3 n = normalMat * v.normal;
		float len = glm::length(n);
		out.normal = (len > 1e-6f) ? (n / len) : glm::vec3(0.0f, 1.0f, 0.0f);
		out.uv = v.uv;
		dst.vertices.push_back(out);
	}

	dst.indices.reserve(dst.indices.size() + src.indices.size());
	for (uint32_t idx : src.indices) {
		dst.indices.push_back(baseVertex + idx);
	}
}

inline void AddUniqueMaterial(ModelAsset& asset, const MaterialDef& mat)
{
	for (const auto& existing : asset.materials) {
		if (existing.name == mat.name) return;
	}
	asset.materials.push_back(mat);
}
