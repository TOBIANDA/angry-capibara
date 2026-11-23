#pragma once

#include "mesh_types.h"
#include <array>

// Evaluasi Bicubic Bezier Surface Patch (4x4 control points) di CPU
// Menghasilkan mesh CCW dengan normal analitik dS/du x dS/dv.
SubMesh BuildBicubicBezierPatch(
	const std::array<std::array<glm::vec3, 4>, 4>& controlPoints,
	int uSteps = 16,
	int vSteps = 16,
	bool flipWinding = false);

// Membentuk tubuh tertutup mulus dari patch atas-bawah atau kapsul bezier simetris.
SubMesh BuildBezierRevolvedProfile(
	const std::array<glm::vec2, 4>& profileRZ, // (radius, axial_coord) sepanjang kurva cubic bezier
	int axialSteps = 18,
	int radialSteps = 24);

// Tabung melengkung mengikuti Cubic Bezier 3D curve (untuk ekor pita, daun, gagang melengkung).
SubMesh BuildBezierTube(
	const std::array<glm::vec3, 4>& curvePoints,
	float rStart,
	float rEnd,
	int pathSteps = 14,
	int radialSteps = 10,
	bool capEnds = true);

// Primitif parametrik standar (CCW winding, UV bebas distorsi).
SubMesh BuildEllipsoid(float rx, float ry, float rz, int stacks = 16, int slices = 24);
SubMesh BuildCylinder(float rBottom, float rTop, float height, int slices = 20, bool capBottom = true, bool capTop = true);
SubMesh BuildBox(float sx, float sy, float sz);
SubMesh BuildCone(float radius, float height, int slices = 18, bool capBottom = true);
SubMesh BuildTorus(float majorR, float minorR, int majorSteps = 24, int minorSteps = 12);
