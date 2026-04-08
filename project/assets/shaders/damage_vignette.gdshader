shader_type canvas_item;
// ═══════════════════════════════════════
//  damage_vignette.gdshader
//  RE9 Requiem style damage feedback:
//  • Red vignette around screen edges
//  • Pulses with heartbeat when low health
//  • Chromatic aberration when near death
// ═══════════════════════════════════════

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform vec4  vignette_color : source_color = vec4(0.8, 0.0, 0.0, 1.0);
uniform bool  chromatic_aberration = false;

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);
	float dist = length(uv - center);

	// Soft vignette falloff — edges are more red
	float vign = smoothstep(0.35, 0.85, dist);

	// Pulse effect (heartbeat sync)
	float pulse = 1.0 + sin(TIME * pulse_speed * 6.28318) * 0.15;
	vign *= pulse;

	// Chromatic aberration near death (RE9: screen distorts when critical)
	vec4 col = vec4(0.0);
	if (chromatic_aberration && intensity > 0.7) {
		float aberr = (intensity - 0.7) * 0.02;
		col.r = texture(TEXTURE, uv + vec2(aberr, 0.0)).r;
		col.g = texture(TEXTURE, uv).g;
		col.b = texture(TEXTURE, uv - vec2(aberr, 0.0)).b;
		col.a = 1.0;
	} else {
		col = texture(TEXTURE, uv);
	}

	// Final: red vignette overlay
	COLOR = mix(col, vignette_color, vign * intensity);
	COLOR.a = vign * intensity * 0.85;
}
