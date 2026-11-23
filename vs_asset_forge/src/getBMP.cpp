#include "getBMP.h"
#include <fstream>

imageFile* getBMP(std::string fileName)
{
	int offset = 0, w = 0, h = 0;

	std::ifstream inFile(fileName.c_str(), std::ios::binary);
	if (!inFile.is_open()) return nullptr;

	inFile.seekg(10);
	inFile.read(reinterpret_cast<char*>(&offset), 4);

	inFile.seekg(18);
	inFile.read(reinterpret_cast<char*>(&w), 4);
	inFile.read(reinterpret_cast<char*>(&h), 4);

	if (w <= 0 || h <= 0) {
		inFile.close();
		return nullptr;
	}

	int padding = (3 * w) % 4 ? 4 - (3 * w) % 4 : 0;
	int stride = 3 * w + padding;

	unsigned char* raw = new unsigned char[stride * h];
	inFile.seekg(offset);
	inFile.read(reinterpret_cast<char*>(raw), static_cast<std::streamsize>(stride) * h);
	inFile.close();

	imageFile* outRGBA = new imageFile;
	outRGBA->width = w;
	outRGBA->height = h;
	outRGBA->data = new unsigned char[4 * w * h];

	for (int j = 0; j < h; ++j) {
		for (int i = 0; i < w; ++i) {
			int src = j * stride + i * 3;
			int dst = (j * w + i) * 4;
			outRGBA->data[dst + 0] = raw[src + 2];
			outRGBA->data[dst + 1] = raw[src + 1];
			outRGBA->data[dst + 2] = raw[src + 0];
			outRGBA->data[dst + 3] = 0xFF;
		}
	}

	delete[] raw;
	return outRGBA;
}
