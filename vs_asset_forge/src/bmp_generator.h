#pragma once

#include <string>

// Menghasilkan seluruh tekstur .bmp 24-bit uncompressed (kompatibel getBMP & Godot)
// ke direktori texDir. Mengembalikan true jika semua file berhasil ditulis.
bool GenerateAllTexturesW12(const std::string& texDir);
bool GenerateAnimeTexturesW12(const std::string& texDir);
