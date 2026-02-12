shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float block_size : hint_range(1.0, 100.0) = 20.0;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // 1. Create Blocky Coordinates
    // This "snaps" the screen into a grid based on block_size
    vec2 block_uv = floor(uv * block_size) / block_size;
    float glitch_threshold = 1.0 - glitch_intensity;
    
    // 2. Rectangular Shift
    // We use the blocky UV and time to decide if a whole row/block shifts
    float noise_val = random(vec2(block_uv.y, floor(TIME * 10.0)));
    float shift = 0.0;
    
    if (noise_val > glitch_threshold) {
        // Shift is also blocky and succinct
        shift = (random(vec2(floor(TIME * 20.0))) - 0.5) * 0.1;
    }
    
    // 3. Succinct Chromatic Aberration
    // Only apply color split when there is an active shift/glitch
    float r = texture(SCREEN_TEXTURE, vec2(uv.x + shift, uv.y)).r;
    float g = texture(SCREEN_TEXTURE, vec2(uv.x + shift * 0.5, uv.y)).g;
    float b = texture(SCREEN_TEXTURE, vec2(uv.x, uv.y)).b;
    
    vec3 color = vec3(r, g, b);
    
    // 4. Blocky "Static" Overlay (Optional)
    if (noise_val > glitch_threshold + 0.15) {
        color.rgb += (random(uv + TIME) - 0.5) * 0.2;
    }

    COLOR = vec4(color, 1.0);
}