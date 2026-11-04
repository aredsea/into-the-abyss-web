shader_type canvas_item;
uniform vec4 tint:source_color;
void fragment(){COLOR=vec4(tint.rgb,texture(TEXTURE,UV).a*tint.a);}
