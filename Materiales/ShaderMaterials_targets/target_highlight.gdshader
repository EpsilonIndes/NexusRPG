shader_type spatial;
render_mode unshaded, cull_back;

uniform bool highlight = false;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.2, 1.0);
uniform float outline_size = 0.04;

void vertex() {
	if (highlight) {
		VERTEX += NORMAL * outline_size;
	}
}

void fragment() {
	if (!highlight) {
		discard;
	}
	ALBEDO = outline_color.rgb;
}
