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

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &u [[buffer(0)]]) {

    float2 uv = in.uv;
    float t = u.time;
    int pattern = u.pattern;

    if (pattern == 0) {
        return float4(fract(uv.x + t),
                      fract(uv.y + t),
                      fract(uv.x + uv.y + t),
                      1.0);
    }

    if (pattern == 1) {
        float c = step(0.5, fract(uv.x * 10) + fract(uv.y * 10));
        return float4(c, c, c, 1.0);
    }

    if (pattern == 2) {
        return float4(1.0, 0.0, 0.0, 1.0);
    }

    if (pattern == 3) {
        uint h = hash(uint(uv.x * 1000 + uv.y * 10000 + t * 100));
        float r = (h >> 16) & 255;
        float g = (h >> 8) & 255;
        float b = h & 255;
        return float4(r/255.0, g/255.0, b/255.0, 1.0);
    }

    if (pattern == 4) {
        float2 p = fract(uv + t);
        float c = step(0.5, sin(p.x * 10.0 + t) * sin(p.y * 10.0 + t));
        return float4(c, c, c, 1.0);
    }

    return float4(fract(t), fract(t * 0.5), fract(t * 0.25), 1.0);
}
