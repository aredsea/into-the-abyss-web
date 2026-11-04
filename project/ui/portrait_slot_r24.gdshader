shader_type canvas_item;
uniform bool white_backing=false;
uniform bool knocked_out=false;
void fragment(){
 vec4 sample_color=texture(TEXTURE,UV);
 if(white_backing){sample_color.rgb*=vec3(.93333,.90196,.83922);}
 COLOR.rgb=sample_color.rgb;
 if(knocked_out){float gray=dot(sample_color.rgb,vec3(.299,.587,.114));COLOR.rgb=mix(vec3(.956,.937,.89),vec3(gray),.70);COLOR.a*=.78;}
 COLOR.a*=1.0-smoothstep(.66,.99,UV.y);
}
