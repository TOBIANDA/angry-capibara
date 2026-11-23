#pragma once

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <objidl.h>
#include <gdiplus.h>
#pragma comment(lib, "gdiplus.lib")

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <functional>
#include <iostream>
#include <string>
#include <vector>

namespace c2d {

struct Vec2 {
	float x = 0.0f;
	float y = 0.0f;
	Vec2() = default;
	Vec2(float x_, float y_) : x(x_), y(y_) {}
	Vec2 operator+(const Vec2& o) const { return { x + o.x, y + o.y }; }
	Vec2 operator-(const Vec2& o) const { return { x - o.x, y - o.y }; }
	Vec2 operator*(float s) const { return { x * s, y * s }; }
	Vec2 operator/(float s) const { return { x / s, y / s }; }
};

inline float dot(const Vec2& a, const Vec2& b) { return a.x * b.x + a.y * b.y; }
inline float length(const Vec2& v) { return std::sqrt(v.x * v.x + v.y * v.y); }
inline Vec2 normalize(const Vec2& v) {
	float l = length(v);
	return (l > 1e-6f) ? Vec2(v.x / l, v.y / l) : Vec2(0.0f, -1.0f);
}
inline Vec2 rotatePt(const Vec2& p, const Vec2& pivot, float rad) {
	float c = std::cos(rad), s = std::sin(rad);
	float dx = p.x - pivot.x, dy = p.y - pivot.y;
	return { pivot.x + dx * c - dy * s, pivot.y + dx * s + dy * c };
}
inline float clampf(float v, float lo, float hi) { return std::max(lo, std::min(hi, v)); }
inline float lerpf(float a, float b, float t) { return a + (b - a) * t; }
inline float smoothstep(float e0, float e1, float x) {
	float t = clampf((x - e0) / (e1 - e0), 0.0f, 1.0f);
	return t * t * (3.0f - 2.0f * t);
}

struct Color4 {
	float r = 0.0f, g = 0.0f, b = 0.0f, a = 1.0f;
	Color4() = default;
	Color4(float r_, float g_, float b_, float a_ = 1.0f) : r(r_), g(g_), b(b_), a(a_) {}
};

inline Color4 rgbHex(uint32_t hex, float a = 1.0f) {
	return Color4(
		((hex >> 16) & 0xFF) / 255.0f,
		((hex >> 8) & 0xFF) / 255.0f,
		(hex & 0xFF) / 255.0f,
		a);
}

inline Color4 lerpColor(const Color4& c0, const Color4& c1, float t) {
	t = clampf(t, 0.0f, 1.0f);
	return Color4(
		lerpf(c0.r, c1.r, t),
		lerpf(c0.g, c1.g, t),
		lerpf(c0.b, c1.b, t),
		lerpf(c0.a, c1.a, t));
}

inline Color4 mulColor(const Color4& c, float s) {
	return Color4(clampf(c.r * s, 0.0f, 1.0f), clampf(c.g * s, 0.0f, 1.0f), clampf(c.b * s, 0.0f, 1.0f), c.a);
}

inline Color4 addColor(const Color4& a, const Color4& b) {
	return Color4(clampf(a.r + b.r, 0.0f, 1.0f), clampf(a.g + b.g, 0.0f, 1.0f), clampf(a.b + b.b, 0.0f, 1.0f), clampf(a.a, 0.0f, 1.0f));
}

// Fast deterministic painterly hash & value noise
inline float hash21(int x, int y, int seed = 1337) {
	uint32_t n = static_cast<uint32_t>(x * 374761393 + y * 668265263 + seed * 1442695041);
	n = (n ^ (n >> 13)) * 1274126177u;
	return static_cast<float>((n ^ (n >> 16)) & 0x00FFFFFFu) / 16777215.0f;
}

inline float noise2D(float x, float y, int seed = 1337) {
	int ix = static_cast<int>(std::floor(x));
	int iy = static_cast<int>(std::floor(y));
	float fx = x - ix;
	float fy = y - iy;
	float ux = fx * fx * (3.0f - 2.0f * fx);
	float uy = fy * fy * (3.0f - 2.0f * fy);
	float a = hash21(ix, iy, seed);
	float b = hash21(ix + 1, iy, seed);
	float c = hash21(ix, iy + 1, seed);
	float d = hash21(ix + 1, iy + 1, seed);
	return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uy);
}

inline float fbm2D(float x, float y, int octaves = 3, int seed = 1337) {
	float v = 0.0f, amp = 0.5f, freq = 1.0f, norm = 0.0f;
	for (int i = 0; i < octaves; ++i) {
		v += amp * noise2D(x * freq, y * freq, seed + i * 97);
		norm += amp;
		amp *= 0.5f;
		freq *= 2.07f;
	}
	return v / std::max(norm, 1e-5f);
}

// Directional painterly brushstroke / soft fur noise
inline float brushNoise(float x, float y, float angleRad, float scaleAlong, float scaleAcross, int seed = 42) {
	float c = std::cos(angleRad), s = std::sin(angleRad);
	float rx = (x * c + y * s) / std::max(scaleAlong, 1.0f);
	float ry = (-x * s + y * c) / std::max(scaleAcross, 1.0f);
	float n = fbm2D(rx, ry, 3, seed);
	return (n - 0.5f) * 2.0f; // [-1, 1]
}

// =========================================================================
// Analytic 2D Signed Distance Field Primitives
// =========================================================================

inline float smin(float a, float b, float k) {
	if (k <= 1e-4f) return std::min(a, b);
	float h = clampf(0.5f + 0.5f * (b - a) / k, 0.0f, 1.0f);
	return lerpf(b, a, h) - k * h * (1.0f - h);
}

inline float smax(float a, float b, float k) {
	return -smin(-a, -b, k);
}

inline float sdCircle(const Vec2& p, const Vec2& c, float r) {
	return length(p - c) - r;
}

inline float sdEllipse(const Vec2& p, const Vec2& c, float rx, float ry, float rotRad = 0.0f) {
	Vec2 q = p - c;
	if (std::fabs(rotRad) > 1e-5f) {
		float co = std::cos(-rotRad), si = std::sin(-rotRad);
		q = { q.x * co - q.y * si, q.x * si + q.y * co };
	}
	float ax = q.x / std::max(rx, 1e-4f);
	float ay = q.y / std::max(ry, 1e-4f);
	float k0 = std::sqrt(ax * ax + ay * ay);
	if (k0 < 1e-6f) return -std::min(rx, ry);
	float gx = q.x / (rx * rx);
	float gy = q.y / (ry * ry);
	float k1 = std::sqrt(gx * gx + gy * gy);
	return k0 * (k0 - 1.0f) / std::max(k1, 1e-6f);
}

inline float sdRoundBox(const Vec2& p, const Vec2& c, float hx, float hy, float r, float rotRad = 0.0f) {
	Vec2 q = p - c;
	if (std::fabs(rotRad) > 1e-5f) {
		float co = std::cos(-rotRad), si = std::sin(-rotRad);
		q = { q.x * co - q.y * si, q.x * si + q.y * co };
	}
	float qx = std::fabs(q.x) - (hx - r);
	float qy = std::fabs(q.y) - (hy - r);
	float ox = std::max(qx, 0.0f), oy = std::max(qy, 0.0f);
	return std::sqrt(ox * ox + oy * oy) + std::min(std::max(qx, qy), 0.0f) - r;
}

inline float sdCapsule(const Vec2& p, const Vec2& a, const Vec2& b, float r) {
	Vec2 pa = p - a, ba = b - a;
	float h = clampf(dot(pa, ba) / std::max(dot(ba, ba), 1e-6f), 0.0f, 1.0f);
	return length(pa - ba * h) - r;
}

inline float sdTaperedCapsule(const Vec2& p, const Vec2& a, const Vec2& b, float r0, float r1) {
	Vec2 pa = p - a, ba = b - a;
	float h = clampf(dot(pa, ba) / std::max(dot(ba, ba), 1e-6f), 0.0f, 1.0f);
	return length(pa - ba * h) - lerpf(r0, r1, h);
}

// Quadratic Bezier tapered stroke (ideal for angry brows, flames, leaves, tufts, katana slashes!)
inline float sdQuadBezierStroke(const Vec2& p, const Vec2& p0, const Vec2& p1, const Vec2& p2, float r0, float r1, int steps = 14) {
	float minD = 1e9f;
	Vec2 prev = p0;
	float prevR = r0;
	for (int i = 1; i <= steps; ++i) {
		float t = static_cast<float>(i) / static_cast<float>(steps);
		float u = 1.0f - t;
		Vec2 cur = p0 * (u * u) + p1 * (2.0f * u * t) + p2 * (t * t);
		float curR = lerpf(r0, r1, t);
		minD = std::min(minD, sdTaperedCapsule(p, prev, cur, prevR, curR));
		prev = cur;
		prevR = curR;
	}
	return minD;
}

// Variable-width 3-stop quadratic bezier (thin -> thick -> thin, great for leaves, flames, crescent slashes!)
inline float sdQuadBezierRibbon(const Vec2& p, const Vec2& p0, const Vec2& p1, const Vec2& p2, float rStart, float rMid, float rEnd, int steps = 16) {
	float minD = 1e9f;
	Vec2 prev = p0;
	float prevR = rStart;
	for (int i = 1; i <= steps; ++i) {
		float t = static_cast<float>(i) / static_cast<float>(steps);
		float u = 1.0f - t;
		Vec2 cur = p0 * (u * u) + p1 * (2.0f * u * t) + p2 * (t * t);
		float curR = (t < 0.5f) ? lerpf(rStart, rMid, t * 2.0f) : lerpf(rMid, rEnd, (t - 0.5f) * 2.0f);
		minD = std::min(minD, sdTaperedCapsule(p, prev, cur, prevR, curR));
		prev = cur;
		prevR = curR;
	}
	return minD;
}

// Exact signed distance to a closed 2D polygon (with optional corner rounding radius)
inline float sdPolygon(const Vec2& p, const std::vector<Vec2>& pts, float roundR = 0.0f) {
	const size_t N = pts.size();
	if (N < 3) return 1e9f;
	float d = dot(p - pts[0], p - pts[0]);
	float s = 1.0f;
	for (size_t i = 0, j = N - 1; i < N; j = i, ++i) {
		Vec2 e = pts[j] - pts[i];
		Vec2 w = p - pts[i];
		float h = clampf(dot(w, e) / std::max(dot(e, e), 1e-6f), 0.0f, 1.0f);
		Vec2 b = w - e * h;
		d = std::min(d, dot(b, b));
		bool c1 = p.y >= pts[i].y;
		bool c2 = p.y < pts[j].y;
		bool c3 = e.x * w.y > e.y * w.x;
		if ((c1 && c2 && c3) || (!c1 && !c2 && !c3)) s = -s;
	}
	return s * std::sqrt(d) - roundR;
}

// Helper to append quadratic Bezier curve points into a polygon contour
inline void AppendQuadBezierPts(std::vector<Vec2>& out, const Vec2& p0, const Vec2& p1, const Vec2& p2, int steps = 12) {
	for (int i = 1; i <= steps; ++i) {
		float t = static_cast<float>(i) / static_cast<float>(steps);
		float u = 1.0f - t;
		out.push_back(p0 * (u * u) + p1 * (2.0f * u * t) + p2 * (t * t));
	}
}

struct BBox {
	float x0 = 0, y0 = 0, x1 = 0, y1 = 0;
	BBox expanded(float pad) const { return { x0 - pad, y0 - pad, x1 + pad, y1 + pad }; }
};

struct VolumetricStyle {
	Color4 topCol;     // Sunlit upper highlight
	Color4 midCol;     // Rich core color
	Color4 botCol;     // Cool/deep shadow color
	Color4 rimCol;     // Warm sunset rim accent
	Vec2 lightDir = normalize(Vec2(-0.45f, -0.89f)); // From upper-left sun
	float rimWidth = 9.0f;
	float rimStrength = 0.55f;
	float specStrength = 0.22f;
	float aoDepth = 22.0f;
	float aoStrength = 0.32f;
	float brushAmp = 0.075f;
	float brushAngle = 0.35f;
	float brushAlong = 28.0f;
	float brushAcross = 7.0f;
	int seed = 101;
};

// =========================================================================
// Premultiplied-Alpha Float Canvas2D with Analytic SDF Rendering & GDI+ PNG
// =========================================================================
class Canvas2D {
public:
	int w = 0, h = 0;
	// Premultiplied RGBA float buffer
	std::vector<float> buf;

	Canvas2D(int width, int height) : w(width), h(height), buf(static_cast<size_t>(width) * height * 4, 0.0f) {}

	void Clear(const Color4& c = Color4(0, 0, 0, 0)) {
		float pr = c.r * c.a, pg = c.g * c.a, pb = c.b * c.a, pa = c.a;
		for (int i = 0; i < w * h; ++i) {
			buf[i * 4 + 0] = pr;
			buf[i * 4 + 1] = pg;
			buf[i * 4 + 2] = pb;
			buf[i * 4 + 3] = pa;
		}
	}

	// Porter-Duff Source-Over (premultiplied)
	inline void BlendPixelOver(int x, int y, const Color4& src) {
		if (x < 0 || x >= w || y < 0 || y >= h || src.a <= 1e-5f) return;
		size_t idx = (static_cast<size_t>(y) * w + x) * 4;
		float sa = clampf(src.a, 0.0f, 1.0f);
		float inv = 1.0f - sa;
		buf[idx + 0] = src.r * sa + buf[idx + 0] * inv;
		buf[idx + 1] = src.g * sa + buf[idx + 1] * inv;
		buf[idx + 2] = src.b * sa + buf[idx + 2] * inv;
		buf[idx + 3] = sa + buf[idx + 3] * inv;
	}

	// Additive glow blend
	inline void BlendPixelAdd(int x, int y, const Color4& src) {
		if (x < 0 || x >= w || y < 0 || y >= h || src.a <= 1e-5f) return;
		size_t idx = (static_cast<size_t>(y) * w + x) * 4;
		float sa = clampf(src.a, 0.0f, 1.0f);
		buf[idx + 0] = std::min(1.0f, buf[idx + 0] + src.r * sa);
		buf[idx + 1] = std::min(1.0f, buf[idx + 1] + src.g * sa);
		buf[idx + 2] = std::min(1.0f, buf[idx + 2] + src.b * sa);
		buf[idx + 3] = std::min(1.0f, buf[idx + 3] + sa * 0.65f);
	}

	// Fill any SDF with custom per-pixel shader callback
	void FillSDF(
		const BBox& box,
		const std::function<float(const Vec2&)>& sdf,
		const std::function<Color4(const Vec2&, float)>& shader,
		float feather = 1.35f,
		bool additive = false) {
		int ix0 = std::max(0, static_cast<int>(std::floor(box.x0 - feather - 2.0f)));
		int iy0 = std::max(0, static_cast<int>(std::floor(box.y0 - feather - 2.0f)));
		int ix1 = std::min(w - 1, static_cast<int>(std::ceil(box.x1 + feather + 2.0f)));
		int iy1 = std::min(h - 1, static_cast<int>(std::ceil(box.y1 + feather + 2.0f)));

		for (int y = iy0; y <= iy1; ++y) {
			for (int x = ix0; x <= ix1; ++x) {
				Vec2 p(x + 0.5f, y + 0.5f);
				float d = sdf(p);
				if (d > feather) continue;
				float cov = clampf(0.5f - d / feather, 0.0f, 1.0f);
				if (cov <= 1e-4f) continue;
				Color4 c = shader(p, d);
				c.a *= cov;
				if (additive) BlendPixelAdd(x, y, c);
				else BlendPixelOver(x, y, c);
			}
		}
	}

	// Soft drop shadow / contact occlusion under an SDF shape
	void PaintDropShadow(
		const BBox& box,
		const std::function<float(const Vec2&)>& sdf,
		const Vec2& offset,
		float blurRadius,
		const Color4& shadowCol) {
		float pad = blurRadius * 2.5f + std::max(std::fabs(offset.x), std::fabs(offset.y)) + 4.0f;
		int ix0 = std::max(0, static_cast<int>(std::floor(box.x0 - pad)));
		int iy0 = std::max(0, static_cast<int>(std::floor(box.y0 - pad)));
		int ix1 = std::min(w - 1, static_cast<int>(std::ceil(box.x1 + pad)));
		int iy1 = std::min(h - 1, static_cast<int>(std::ceil(box.y1 + pad)));

		for (int y = iy0; y <= iy1; ++y) {
			for (int x = ix0; x <= ix1; ++x) {
				Vec2 p(x + 0.5f - offset.x, y + 0.5f - offset.y);
				float d = sdf(p);
				if (d > blurRadius * 2.6f) continue;
				float falloff = (d <= 0.0f) ? 1.0f : std::exp(-(d * d) / std::max(blurRadius * blurRadius * 0.85f, 1.0f));
				if (falloff <= 0.003f) continue;
				Color4 c = shadowCol;
				c.a *= falloff;
				BlendPixelOver(x, y, c);
			}
		}
	}

	// Signature Rovio Angry Birds 2 Lineless Volumetric Painterly Fill
	void PaintVolumetricSDF(
		const BBox& box,
		const std::function<float(const Vec2&)>& sdf,
		const VolumetricStyle& st,
		float feather = 1.35f) {
		float bw = std::max(box.x1 - box.x0, 1.0f);
		float bh = std::max(box.y1 - box.y0, 1.0f);
		Vec2 center((box.x0 + box.x1) * 0.5f, (box.y0 + box.y1) * 0.5f);

		FillSDF(box, sdf, [&](const Vec2& p, float d) -> Color4 {
			// Normalized local coordinates [-1, 1]
			float nx = (p.x - center.x) / (bw * 0.5f);
			float ny = (p.y - center.y) / (bh * 0.5f);

			// Directional lighting gradient across the form
			float gProj = clampf(0.5f + (nx * (-st.lightDir.x) + ny * (-st.lightDir.y)) * 0.58f, 0.0f, 1.0f);
			// Reverse sign so pixels in direction of lightDir get brighter!
			float litT = clampf(0.5f + (nx * st.lightDir.x + ny * st.lightDir.y) * 0.62f, 0.0f, 1.0f);
			(void)gProj;

			// 3-stop rich painterly tone (never muddy grey!)
			Color4 col = (litT >= 0.5f)
				? lerpColor(st.midCol, st.topCol, (litT - 0.5f) * 2.0f)
				: lerpColor(st.botCol, st.midCol, litT * 2.0f);

			// Tactile directional fur / gouache brushwork
			if (st.brushAmp > 1e-4f) {
				float bn = brushNoise(p.x, p.y, st.brushAngle, st.brushAlong, st.brushAcross, st.seed);
				col = mulColor(col, 1.0f + bn * st.brushAmp);
			}

			// Compute analytic SDF normal near the boundary for crisp lineless rim & underside AO
			float edgeBand = std::max(st.rimWidth, st.aoDepth) + 3.0f;
			if (-d < edgeBand) {
				const float eps = 1.6f;
				float dx = sdf(Vec2(p.x + eps, p.y)) - sdf(Vec2(p.x - eps, p.y));
				float dy = sdf(Vec2(p.x, p.y + eps)) - sdf(Vec2(p.x, p.y - eps));
				Vec2 nrm = normalize(Vec2(dx, dy));
				float ndl = dot(nrm, st.lightDir);

				// Warm sunset rim crescent on sunlit edge
				if (st.rimStrength > 1e-4f && -d < st.rimWidth * 1.4f) {
					float edgeMask = 1.0f - smoothstep(0.0f, st.rimWidth, -d);
					float dirMask = smoothstep(-0.05f, 0.72f, ndl);
					float rim = edgeMask * dirMask * st.rimStrength;
					Color4 tintedRim = lerpColor(mulColor(col, 1.35f), st.rimCol, 0.55f);
					col = lerpColor(col, tintedRim, clampf(rim, 0.0f, 0.85f));
				}

				// Soft ambient occlusion darkening along lower shadow edge
				if (st.aoStrength > 1e-4f && -d < st.aoDepth) {
					float aoEdge = 1.0f - smoothstep(0.0f, st.aoDepth, -d);
					float shadowDir = smoothstep(-0.05f, 0.80f, -ndl);
					col = lerpColor(col, mulColor(st.botCol, 0.78f), aoEdge * shadowDir * st.aoStrength);
				}
			}

			// Subtle upper-left painterly specular dome glow
			if (st.specStrength > 1e-4f) {
				Vec2 sp = Vec2(nx - st.lightDir.x * 0.42f, ny - st.lightDir.y * 0.42f);
				float spec = std::exp(-dot(sp, sp) * 4.5f) * st.specStrength;
				Color4 specCol = lerpColor(st.topCol, Color4(1.0f, 0.98f, 0.90f, 1.0f), 0.55f);
				col = lerpColor(col, specCol, clampf(spec, 0.0f, 0.65f));
			}

			col.a = st.midCol.a;
			return col;
		}, feather, false);
	}

	// Composite another Canvas2D onto this one (optional helper for preview sheet)
	void Blit(const Canvas2D& src, int dstX, int dstY) {
		for (int y = 0; y < src.h; ++y) {
			int ty = dstY + y;
			if (ty < 0 || ty >= h) continue;
			for (int x = 0; x < src.w; ++x) {
				int tx = dstX + x;
				if (tx < 0 || tx >= w) continue;
				size_t si = (static_cast<size_t>(y) * src.w + x) * 4;
				float sa = src.buf[si + 3];
				if (sa <= 1e-5f) continue;
				size_t di = (static_cast<size_t>(ty) * w + tx) * 4;
				float inv = 1.0f - sa;
				buf[di + 0] = src.buf[si + 0] + buf[di + 0] * inv;
				buf[di + 1] = src.buf[si + 1] + buf[di + 1] * inv;
				buf[di + 2] = src.buf[si + 2] + buf[di + 2] * inv;
				buf[di + 3] = sa + buf[di + 3] * inv;
			}
		}
	}

	// Save as true 32-bit RGBA compressed PNG via Windows GDI+
	bool SavePNG(const std::string& path) const {
		static bool gdiInit = false;
		static ULONG_PTR gdiToken = 0;
		if (!gdiInit) {
			Gdiplus::GdiplusStartupInput si;
			if (Gdiplus::GdiplusStartup(&gdiToken, &si, nullptr) == Gdiplus::Ok) {
				gdiInit = true;
			}
		}

		// Find PNG encoder CLSID
		CLSID pngClsid{};
		UINT num = 0, size = 0;
		Gdiplus::GetImageEncodersSize(&num, &size);
		if (size == 0) return false;
		std::vector<uint8_t> encBuf(size);
		auto* encoders = reinterpret_cast<Gdiplus::ImageCodecInfo*>(encBuf.data());
		Gdiplus::GetImageEncoders(num, size, encoders);
		bool found = false;
		for (UINT i = 0; i < num; ++i) {
			if (wcscmp(encoders[i].MimeType, L"image/png") == 0) {
				pngClsid = encoders[i].Clsid;
				found = true;
				break;
			}
		}
		if (!found) return false;

		Gdiplus::Bitmap bmp(w, h, PixelFormat32bppARGB);
		Gdiplus::BitmapData bd{};
		Gdiplus::Rect rect(0, 0, w, h);
		if (bmp.LockBits(&rect, Gdiplus::ImageLockModeWrite, PixelFormat32bppARGB, &bd) != Gdiplus::Ok) {
			return false;
		}
		for (int y = 0; y < h; ++y) {
			uint8_t* dst = static_cast<uint8_t*>(bd.Scan0) + y * bd.Stride;
			for (int x = 0; x < w; ++x) {
				size_t idx = (static_cast<size_t>(y) * w + x) * 4;
				float a = clampf(buf[idx + 3], 0.0f, 1.0f);
				float r = 0.0f, g = 0.0f, b = 0.0f;
				if (a > 1e-4f) {
					r = clampf(buf[idx + 0] / a, 0.0f, 1.0f);
					g = clampf(buf[idx + 1] / a, 0.0f, 1.0f);
					b = clampf(buf[idx + 2] / a, 0.0f, 1.0f);
				}
				// GDI+ ARGB memory order on little-endian: B, G, R, A
				dst[x * 4 + 0] = static_cast<uint8_t>(std::round(b * 255.0f));
				dst[x * 4 + 1] = static_cast<uint8_t>(std::round(g * 255.0f));
				dst[x * 4 + 2] = static_cast<uint8_t>(std::round(r * 255.0f));
				dst[x * 4 + 3] = static_cast<uint8_t>(std::round(a * 255.0f));
			}
		}
		bmp.UnlockBits(&bd);

		// Convert UTF-8 path to wide string
		int wlen = MultiByteToWideChar(CP_UTF8, 0, path.c_str(), -1, nullptr, 0);
		std::wstring wpath(static_cast<size_t>(std::max(wlen - 1, 0)), L'\0');
		if (wlen > 1) MultiByteToWideChar(CP_UTF8, 0, path.c_str(), -1, &wpath[0], wlen);

		Gdiplus::Status st = bmp.Save(wpath.c_str(), &pngClsid, nullptr);
		return st == Gdiplus::Ok;
	}
};

} // namespace c2d
