shader_type canvas_item;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float gray=dot(c.rgb,vec3(.299,.587,.114));
 COLOR.rgb=vec3(gray)*vec3(.93333,.90196,.83922);
}
