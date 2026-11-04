shader_type canvas_item;
render_mode blend_mul;
uniform bool knocked_out=false;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float fade=1.0-smoothstep(.66,.99,UV.y);
 if(knocked_out){float gray=dot(c.rgb,vec3(.299,.587,.114));c.rgb=mix(vec3(.956,.937,.89),vec3(gray),.70);c.a*=.78;}
 COLOR=vec4(mix(vec3(1.0),c.rgb,c.a*fade),1.0);
}
