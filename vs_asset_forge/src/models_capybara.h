#pragma once

#include "mesh_types.h"
#include <vector>

enum class CapyVariant {
	Chill = 0,       // W1 (1-1)
	Dash,            // W1 (1-6)
	Mini,            // W1 (1-11)
	YuzuBomb,        // W2 (2-1)
	SeedBlaster,     // W2 (2-6)
	BambuSaber,      // W2 (2-11)
	HeavyOnsen       // W2 (2-16)
};

struct CapyInfo {
	CapyVariant variant;
	const char* id;
	const char* displayName;
	const char* worldLabel;
};

const std::vector<CapyInfo>& GetCapyW12Roster();
ModelAsset BuildCapybaraW12(CapyVariant variant);
std::vector<ModelAsset> BuildAllCapybarasW12();
