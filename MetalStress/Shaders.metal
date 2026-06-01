#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
    int   pattern;
    float2 resolution;
};

struct VertexOut {
    float4 pos [[position]];
    float2 uv;
};

vertex VertexOut vertex_main(uint vid [[vertex_id]]) {
    float2 pos[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    VertexOut out;
    out.pos = float4(pos[vid], 0.0, 1.0);
    out.uv  = pos[vid] * 0.5 + 0.5;
    return out;
}

// ── Helpers ────────────────────────────────────────────────────────────────

uint hash(uint x) {
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    return x;
}

float hash_f(float2 p) {
    uint h = hash(uint(p.x * 1000.0 + p.y * 10000.0));
    return float(h & 0xFFFF) / 65535.0;
}

float2 hash2(float2 p) {
    float2 q = float2(dot(p, float2(127.1, 311.7)),
                      dot(p, float2(269.5, 183.3)));
    return fract(sin(q) * 43758.5453);
}

// Value noise
float vnoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash_f(i);
    float b = hash_f(i + float2(1,0));
    float c = hash_f(i + float2(0,1));
    float d = hash_f(i + float2(1,1));
    return mix(mix(a,b,f.x), mix(c,d,f.x), f.y);
}

// FBM – 8 octaves (expensive on purpose)
float fbm(float2 p) {
    float v = 0.0, a = 0.5;
    float2x2 rot = float2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 8; i++) {
        v += a * vnoise(p);
        p  = rot * p * 2.1;
        a *= 0.5;
    }
    return v;
}

// Smooth minimum
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

// SDF scene for raymarching
float scene(float3 p, float t) {
    float sphere1 = length(p - float3(sin(t)*0.6, cos(t*0.7)*0.4, 0.0)) - 0.35;
    float sphere2 = length(p - float3(cos(t*1.3)*0.5, sin(t*0.9)*0.5, sin(t*0.4)*0.3)) - 0.25;
    float sphere3 = length(p - float3(0.0, sin(t*1.1)*0.3, cos(t)*0.5)) - 0.20;
    float torus   = length(float2(length(p.xz) - 0.5, p.y)) - 0.15;
    float box     = length(max(abs(p + float3(sin(t*0.5)*0.4, 0, 0)) - 0.2, 0.0));
    return smin(smin(smin(sphere1, sphere2, 0.2), smin(sphere3, torus, 0.15), 0.1), box, 0.12);
}

float3 normal(float3 p, float t) {
    float e = 0.001;
    return normalize(float3(
        scene(p+float3(e,0,0),t) - scene(p-float3(e,0,0),t),
        scene(p+float3(0,e,0),t) - scene(p-float3(0,e,0),t),
        scene(p+float3(0,0,e),t) - scene(p-float3(0,0,e),t)));
}

// Mandelbrot – 256 iterations
float mandelbrot(float2 c) {
    float2 z = 0.0;
    for (int i = 0; i < 256; i++) {
        z = float2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        if (dot(z,z) > 4.0) return float(i) / 256.0;
    }
    return 0.0;
}

// Julia – 256 iterations
float julia(float2 z, float2 c) {
    for (int i = 0; i < 256; i++) {
        z = float2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        if (dot(z,z) > 4.0) return float(i) / 256.0;
    }
    return 0.0;
}

// Voronoi
float voronoi(float2 p) {
    float2 i = floor(p);
    float  md = 8.0;
    for (int y = -2; y <= 2; y++)
    for (int x = -2; x <= 2; x++) {
        float2 n = i + float2(x,y);
        float2 d = hash2(n) + float2(n) - p;
        md = min(md, dot(d,d));
    }
    return sqrt(md);
}

// ── Patterns ───────────────────────────────────────────────────────────────

fragment float4 fragment_main(VertexOut     in  [[stage_in]],
                              constant Uniforms &u [[buffer(0)]]) {
    float2 uv  = in.uv;
    float2 ndc = uv * 2.0 - 1.0;
    float  t   = u.time;
    float  ar  = u.resolution.x / max(u.resolution.y, 1.0);
    float2 asp = float2(ndc.x * ar, ndc.y);

    switch (u.pattern) {

    // 0 – FBM Cloud (8-octave, most expensive)
    case 0: {
        float2 p = asp * 2.0;
        float  f = fbm(p + float2(t * 0.3, t * 0.2));
        float  g = fbm(p + float2(f, f) + float2(-t*0.1, t*0.15));
        float  h2 = fbm(p + float2(g*1.5, -g) + float2(t*0.05, -t*0.08));
        float3 col = mix(float3(0.1,0.2,0.8), float3(1.0,0.9,0.5), h2);
        col = mix(col, float3(1.0), smoothstep(0.6, 0.9, g));
        return float4(col, 1.0);
    }

    // 1 – Raymarched SDF scene
    case 1: {
        float3 ro = float3(0.0, 0.0, 2.5);
        float3 rd = normalize(float3(asp * 0.8, -1.0));
        float  d  = 0.0;
        float3 p3 = ro;
        bool   hit = false;
        for (int i = 0; i < 96; i++) {
            float s = scene(p3, t);
            if (s < 0.001) { hit = true; break; }
            if (d > 6.0) break;
            d  += s;
            p3  = ro + rd * d;
        }
        float3 col = float3(0.02, 0.02, 0.05);
        if (hit) {
            float3 n3  = normal(p3, t);
            float3 lig = normalize(float3(sin(t)*2.0, cos(t*0.7)*1.5, 2.0));
            float  dif = max(dot(n3, lig), 0.0);
            float  spe = pow(max(dot(reflect(-lig, n3), -rd), 0.0), 32.0);
            float3 base = float3(0.5 + 0.5*sin(d*3.0 + t),
                                 0.5 + 0.5*cos(d*2.5 - t*0.7),
                                 0.5 + 0.5*sin(d*4.0 + t*1.3));
            col = base * dif + spe * 0.8 + float3(0.05) * (1.0 - dif);
        }
        return float4(col, 1.0);
    }

    // 2 – Mandelbrot zoom
    case 2: {
        float zoom  = exp(-fmod(t * 0.3, 6.0));
        float2 center = float2(-0.7269, 0.1889);
        float2 c = asp * zoom + center;
        float  m = mandelbrot(c);
        float3 col = m == 0.0
            ? float3(0.0)
            : float3(0.5 + 0.5*sin(m*12.0 + t),
                     0.5 + 0.5*sin(m*8.0  + t + 2.1),
                     0.5 + 0.5*sin(m*15.0 + t + 4.2));
        return float4(col, 1.0);
    }

    // 3 – Julia set animated
    case 3: {
        float2 c2 = float2(0.355 + sin(t*0.23)*0.1,
                           0.355 + cos(t*0.17)*0.1);
        float  j  = julia(asp * 1.5, c2);
        float3 col = j == 0.0
            ? float3(0.0)
            : float3(0.5 + 0.5*cos(j*10.0 + t*1.5),
                     0.5 + 0.5*sin(j*7.0  - t),
                     0.5 + 0.5*cos(j*13.0 + t*0.7));
        return float4(col, 1.0);
    }

    // 4 – Voronoi + FBM composite
    case 4: {
        float2 p4 = asp * 3.0 + float2(t * 0.4, t * 0.25);
        float  v  = voronoi(p4);
        float  f4 = fbm(p4 * 0.5 + t * 0.1);
        float  c4 = smoothstep(0.0, 1.0, v * f4 * 2.0);
        float3 col = float3(c4 * sin(t + v*5.0) * 0.5 + 0.5,
                            c4 * cos(t*0.7 - v*3.0) * 0.5 + 0.5,
                            f4);
        return float4(col, 1.0);
    }

    // 5 – Full stress: FBM + Voronoi + sin web
    default: {
        float2 p5 = asp * 2.5;
        float  f5 = fbm(p5 + t * 0.15);
        float  v5 = voronoi(p5 * 2.0 + f5 * 2.0 + t * 0.2);
        float  w  = sin(asp.x * 8.0 + t) * sin(asp.y * 8.0 + t * 1.1)
                  * sin((asp.x + asp.y) * 6.0 - t * 0.9);
        float3 col = float3(
            0.5 + 0.5*sin(f5*6.0 + v5*4.0 + w + t),
            0.5 + 0.5*cos(f5*5.0 - v5*3.0 + w*1.2 - t*0.8),
            0.5 + 0.5*sin(f5*7.0 + v5*5.0 - w*0.8 + t*1.3));
        return float4(col, 1.0);
    }
    }
}
