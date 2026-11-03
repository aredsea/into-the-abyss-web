shader_type canvas_item;
void fragment() {
 vec4 c=texture(TEXTURE,UV)*COLOR;
 float gray=dot(c.rgb,vec3(.299,.587,.114));
 COLOR=vec4(mix(vec3(.956,.937,.89),vec3(gray),.70),c.a*.78);
}
