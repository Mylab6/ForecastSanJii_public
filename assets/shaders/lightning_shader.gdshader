shader_type canvas_item;

// Web-optimized lightning shader for San Jii Metro radar
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec2 lightning_start = vec2(0.3, 0.2);
uniform vec2 lightning_end = vec2(0.7, 0.8);
uniform float flash_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float bolt_width : hint_range(0.001, 0.02) = 0.005;

// Simple random function for web compatibility
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Generate lightning bolt path
float lightning_bolt(vec2 uv) {
    vec2 direction = lightning_end - lightning_start;
    float bolt_length = length(direction);
    vec2 normalized_dir = normalize(direction);
    
    // Project UV onto lightning direction
    vec2 to_point = uv - lightning_start;
    float along_bolt = dot(to_point, normalized_dir);
    float cross_bolt = abs(dot(to_point, vec2(-normalized_dir.y, normalized_dir.x)));
    
    // Check if we're within the bolt bounds
    if (along_bolt < 0.0 || along_bolt > bolt_length) {
        return 0.0;
    }
    
    // Add jagged edges with noise
    float progress = along_bolt / bolt_length;
    float jag_offset = (random(vec2(progress * 20.0, time)) - 0.5) * 0.02;
    cross_bolt += jag_offset;
    
    // Create main bolt
    float bolt = 1.0 - smoothstep(0.0, bolt_width, cross_bolt);
    
    // Add secondary branches
    float branch_chance = random(vec2(progress * 15.0, floor(time * 10.0)));
    if (branch_chance > 0.7) {
        vec2 branch_dir = vec2(normalized_dir.y, -normalized_dir.x) * (random(vec2(progress, time)) - 0.5) * 0.1;
        vec2 branch_point = lightning_start + normalized_dir * along_bolt;
        float branch_dist = length(uv - branch_point - branch_dir);
        bolt = max(bolt, 1.0 - smoothstep(0.0, bolt_width * 0.5, branch_dist));
    }
    
    return bolt;
}

void fragment() {
    vec2 uv = UV;
    
    // Create pulsing lightning effect
    float pulse = sin(time * 20.0) * 0.5 + 0.5;
    float flash = flash_intensity * pulse;
    
    // Generate lightning bolt
    float bolt = lightning_bolt(uv);
    
    // Lightning color - bright white/blue
    vec3 lightning_color = vec3(1.0, 1.0, 0.9) * flash;
    
    // Add glow effect
    float glow_distance = 0.02;
    if (bolt < 0.1) {
        // Sample nearby pixels for glow
        float glow = 0.0;
        for (float x = -1.0; x <= 1.0; x += 1.0) {
            for (float y = -1.0; y <= 1.0; y += 1.0) {
                vec2 offset = vec2(x, y) * glow_distance;
                glow += lightning_bolt(uv + offset);
            }
        }
        glow /= 9.0;
        bolt = max(bolt, glow * 0.3);
    }
    
    // Final color with proper alpha
    float alpha = bolt * flash;
    COLOR = vec4(lightning_color * bolt, alpha);
}
