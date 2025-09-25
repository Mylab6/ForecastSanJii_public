shader_type canvas_item;

// Web-optimized precipitation shader for San Jii Metro radar
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec2 storm_center = vec2(0.5, 0.5);
uniform float storm_type : hint_range(0.0, 3.0) = 0.0; // 0=convective, 1=hurricane, 2=frontal, 3=sea_breeze
uniform vec4 base_color : hint_color = vec4(0.0, 1.0, 0.0, 0.8);

// Web-compatible noise function (simplified for performance)
float simple_noise(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

// Multi-octave noise for realistic precipitation shapes
float fractal_noise(vec2 pos, int octaves) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += simple_noise(pos * frequency) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// Create realistic precipitation patterns
float precipitation_pattern(vec2 uv) {
    vec2 centered_uv = uv - storm_center;
    float distance_from_center = length(centered_uv);
    
    // Base shape with noise distortion
    float base_noise = fractal_noise(uv * 8.0 + time * 0.1, 3);
    float shape = 1.0 - smoothstep(0.2, 0.8, distance_from_center + base_noise * 0.3);
    
    // Storm-type specific modifications
    if (storm_type < 0.5) {
        // Convective - chaotic, bumpy
        float chaos = fractal_noise(uv * 15.0 + time * 0.2, 4);
        shape *= (0.7 + chaos * 0.6);
    } else if (storm_type < 1.5) {
        // Hurricane - spiral pattern
        float angle = atan(centered_uv.y, centered_uv.x);
        float spiral = sin(angle * 3.0 + distance_from_center * 10.0 + time * 0.5);
        shape *= (0.8 + spiral * 0.4);
    } else if (storm_type < 2.5) {
        // Frontal - linear features
        float linear = sin(uv.x * 10.0 + time * 0.3);
        shape *= (0.9 + linear * 0.2);
    } else {
        // Sea breeze - gentle waves
        float waves = sin(uv.x * 6.0 + time * 0.4) * sin(uv.y * 4.0 + time * 0.3);
        shape *= (0.8 + waves * 0.3);
    }
    
    // Add fine detail
    float detail = fractal_noise(uv * 25.0 + time * 0.15, 2);
    shape += detail * 0.1;
    
    return clamp(shape * intensity, 0.0, 1.0);
}

void fragment() {
    vec2 uv = UV;
    
    // Calculate precipitation intensity at this pixel
    float precip = precipitation_pattern(uv);
    
    // Create gradient effect based on intensity
    vec3 color = base_color.rgb;
    
    // Intensity-based color variation (green to red scale)
    if (precip > 0.7) {
        color = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (precip - 0.7) / 0.3); // Yellow to red
    } else if (precip > 0.4) {
        color = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (precip - 0.4) / 0.3); // Green to yellow
    } else {
        color = mix(vec3(0.0, 0.5, 0.0), vec3(0.0, 1.0, 0.0), precip / 0.4); // Dark green to green
    }
    
    // Apply precipitation mask with soft edges
    float alpha = smoothstep(0.1, 0.3, precip) * base_color.a;
    
    COLOR = vec4(color, alpha);
}
