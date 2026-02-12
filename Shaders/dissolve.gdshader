shader_type canvas_item;

uniform sampler2D dissolve_texture : hint_default_white, repeat_enable;
uniform bool repeat_texture = true;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform float dissolve_value : hint_range(0.0, 1.0) = 0.0;
uniform float burn_size : hint_range(0.0, 0.4) = 0.1;
uniform vec4 burn_color : source_color = vec4(0.0, 0.6, 1.0, 1.0);

// Flicker Controls
uniform float flicker_speed : hint_range(0.0, 50.0) = 20.0;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float transparency_softness : hint_range(0.01, 0.5) = 0.05;

float random(float x) {
    return fract(sin(x) * 43758.5453123);
}

void fragment() {
    vec4 main_texture = texture(TEXTURE, UV);
    
    // UV Handling
    vec2 target_uv = UV * uv_scale;
    target_uv = repeat_texture ? fract(target_uv) : clamp(target_uv, vec2(0.0), vec2(1.0));
    
    float noise_value = texture(dissolve_texture, target_uv).r;
    
    // --- THE TEXTURE-AWARE FLICKER ---
    // Create a stepped random value (0.0 to 1.0)
    float flick = random(floor(TIME * flicker_speed));
    
    // We apply the flicker to the threshold calculation.
    // This makes the 'cut-off' point jump back and forth across the noise map.
    float base_threshold = (dissolve_value * (1.0 + transparency_softness + burn_size)) - (transparency_softness);
    
    // The flicker 'intensity' determines how far the threshold can jump.
    // We multiply by dissolve_value so it doesn't flicker when fully visible (0.0).
    float flickering_threshold = base_threshold + (flick * flicker_intensity * dissolve_value);

    // 1. Calculate Alpha Mask (How much is dissolved)
    float alpha_mask = smoothstep(flickering_threshold, flickering_threshold + transparency_softness, noise_value);
    
    // 2. Final Alpha
    // We still respect the original sprite/panel alpha
    float final_alpha = main_texture.a * alpha_mask;

    // 3. Edge/Burn Logic (Following the flickering edge)
    float edge_mask = smoothstep(flickering_threshold + burn_size, flickering_threshold, noise_value);
    edge_mask *= alpha_mask;

    // Add a bit of 'over-exposure' to the burn for that neon Marathon look
    vec3 final_color = mix(main_texture.rgb, burn_color.rgb * 3.0, edge_mask);
    
    COLOR = vec4(final_color, final_alpha);
}