#pragma once

#include <string>

// Visual Studio C++ 2D Vector & SDF Painterly Layer Generator
// Merender seluruh layer latar, properti, dan 7 karakter kapibara 2D lineless
// ala Rovio Angry Birds 2 dengan anti-aliasing analitik SDF & sapuan kuas prosedural
// menjadi file PNG 32-bit RGBA transparan untuk Home Screen 2D berlapis (parallax).
bool GenerateAllHome2DLayers(const std::string& outDir);
