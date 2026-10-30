shader_type canvas_item;
// Deterministic print treatment on battlefield art only, beneath all UI text.
void fragment() {
    vec4 c=texture(TEXTURE,UV);
    float l=dot(c.rgb,vec3(.299,.587,.114));
    c.rgb=mix(vec3(l),c.rgb,.77);
    vec2 pixel=floor(UV/TEXTURE_PIXEL_SIZE);
    float grain=fract(sin(dot(pixel,vec2(12.9898,78.233)))*43758.5453);
    float dotmask=step(length(mod(FRAGCOORD.xy,vec2(6.0))-vec2(3.0)),.7);
    c.rgb=clamp(c.rgb+(grain-.5)*.07-dotmask*.05,0.0,1.0);
    COLOR=c;
}
