shader_type spatial;

uniform bool highlight := false;
uniform vec4 highlight_color : source_color = vec4(1.0, 0.9, 0.3, 1.0);
uniform float strength := 0.6;

void fragment() {
	if (highlight) {
		ALBEDO = mix(ALBEDO, highlight_color.rgb, strength);
	}
}