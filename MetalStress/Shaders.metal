#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
    int pattern;
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
    out.uv = pos[vid] * 0.5 + 0.5;
    return out;
}

uint hash(uint x) {
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return x;
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = fract(sin(dot(i, float2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(i + float2(1.0, 0.0), float2(127.1, 311.7))) * 43758.5453);
    float c = fract(sin(dot(i + float2(0.0, 1.0), float2(127.1, 311.7))) * 43758.5453);
    float d = fract(sin(dot(i + float2(1.0, 1.0), float2(127.1, 311.7))) * 43758.5453);

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(float2 p) {
    float value = 0.0;
    float amp = 0.5;
    float2 shift = float2(100.0, 100.0);
    for (int i = 0; i < 5; ++i) {
        value += amp * noise(p);
        p = p * 2.03 + shift;
        amp *= 0.5;
    }
    return value;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &u [[buffer(0)]]) {

    float2 uv = in.uv;
    float t = u.time;
    int pattern = u.pattern;

    if (pattern == 0) {
        float2 p = uv * 8.0;
        return float4(fract(p.x + t * 2.0),
                      fract(p.y + t * 1.5),
                      fract(p.x + p.y + t * 3.0),
                      1.0);
    }

    if (pattern == 1) {
        float stripes = step(0.5, fract((uv.x + t * 0.75) * 40.0));
        float bands = step(0.5, fract((uv.y + t * 0.45) * 24.0));
        float c = abs(stripes - bands);
        return float4(c, c, c, 1.0);
    }

    if (pattern == 2) {
        float pulse = 0.5 + 0.5 * sin(t * 12.0);
        return float4(1.0, pulse * 0.15, pulse * 0.05, 1.0);
    }

    if (pattern == 3) {
        uint h = hash(uint(uv.x * 8000 + uv.y * 12000 + t * 6000));
        float r = (h >> 16) & 255;
        float g = (h >> 8) & 255;
        float b = h & 255;
        return float4(r/255.0, g/255.0, b/255.0, 1.0);
    }

    if (pattern == 4) {
        float2 p = (uv - 0.5) * 2.0;
        float r = length(p);
        float wave = sin(r * 28.0 - t * 18.0);
        float c = step(0.0, wave);
        return float4(c, c * 0.25, 1.0 - c, 1.0);
    }

    if (pattern == 5) {
        float2 p = uv * 8.0;
        float v = fbm(p + t * 1.8);
        return float4(v, v * 0.7, v * 0.2 + 0.1, 1.0);
    }

    if (pattern == 6) {
        float2 p = uv - 0.5;
        float angle = atan2(p.y, p.x) + t * 6.0;
        float rings = sin(length(p) * 60.0 - t * 20.0);
        float burst = step(0.0, sin(angle * 12.0) + rings);
        return float4(burst, 1.0 - burst * 0.4, burst * 0.15, 1.0);
    }

    if (pattern == 7) {
        float2 p = uv * 12.0;
        float v = fbm(p + float2(t * 3.0, -t * 2.0));
        v = smoothstep(0.2, 0.8, v);
        return float4(v * 0.2, v, 1.0 - v * 0.25, 1.0);
    }

    return float4(fract(t), fract(t * 0.5), fract(t * 0.25), 1.0);
}
