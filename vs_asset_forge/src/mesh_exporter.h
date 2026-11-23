#pragma once

#include "mesh_types.h"
#include <string>

// Menulis file Wavefront .obj dan .mtl ke modelDir (mis. "../godot_project/assets/generated/models")
// dengan path tekstur relatif "../textures/<textureFile>".
bool ExportModelToOBJ(const ModelAsset& asset, const std::string& modelDir);
