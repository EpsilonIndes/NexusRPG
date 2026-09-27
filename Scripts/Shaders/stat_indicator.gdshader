shader_type canvas_item;

uniform bool is_debuff = false;

void fragment() {
	// Swap green and red while preserving the original alpha and shading.
	if (is_debuff) {
		COLOR.rgb = COLOR.grb;
	}
}
