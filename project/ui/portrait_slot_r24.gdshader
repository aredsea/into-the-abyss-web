shader_type canvas_item;
uniform bool knocked_out=false;
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	COLOR.rgb=c.rgb;
	if(knocked_out){float g=dot(c.rgb,vec3(.299,.587,.114));COLOR.rgb=vec3(g)*.8;}
}
