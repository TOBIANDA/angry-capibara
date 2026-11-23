#pragma once

#include "models_capybara.h"
#include <vector>

const std::vector<CapyInfo>& GetCapyAnimeW12Roster();
ModelAsset BuildCapybaraAnimeW12(CapyVariant variant);
std::vector<ModelAsset> BuildAllCapybarasAnimeW12();
std::vector<ModelAsset> BuildAllHomeKeyArtAssets();
