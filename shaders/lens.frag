#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform sampler2D u_image;
uniform float u_lensCenterX;
uniform float u_lensCenterY;
uniform float u_lensRadius;
uniform float u_distortion;
uniform float u_magnification;
uniform float u_aberration;

out vec4 fragColor;

void main() {
    vec2 pos = FlutterFragCoord().xy;
    vec2 centerPos = vec2(u_lensCenterX, u_lensCenterY);
    
    // Inside Lens
    vec2 p = pos - centerPos;
    
    // Normalize coordinates for spherical distortion
    float r = length(p) / u_lensRadius;
    
    // Smooth factor decreasing towards edge
    float bind = r * r * r;
    float distFactor = 1.0 + bind * u_distortion;
    
    // Apply magnification and distortion
    vec2 ouv = (p * distFactor) / u_magnification;
    
    // Sample with chromatic aberration
    vec2 redPos = centerPos + ouv * (1.0 - u_aberration);
    vec2 greenPos = centerPos + ouv;
    vec2 bluePos = centerPos + ouv * (1.0 + u_aberration);
    
    vec2 redUV = redPos / u_resolution;
    vec2 greenUV = greenPos / u_resolution;
    vec2 blueUV = bluePos / u_resolution;
    
    // Flip Y axis entirely
    redUV.y = 1.0 - redUV.y;
    greenUV.y = 1.0 - greenUV.y;
    blueUV.y = 1.0 - blueUV.y;
    
    float rCol = texture(u_image, redUV).r;
    float gCol = texture(u_image, greenUV).g;
    float bCol = texture(u_image, blueUV).b;
    float aCol = texture(u_image, greenUV).a;
    
    fragColor = vec4(rCol, gCol, bCol, aCol);
}
