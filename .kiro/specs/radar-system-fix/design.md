# Design Document

## Overview

The radar system fix will consolidate the multiple existing radar implementations into a single, working radar display. The design focuses on simplicity and reliability, using Godot's built-in 2D drawing capabilities rather than complex shader-based approaches that may be causing issues.

## Architecture

### Core Components

1. **SimpleRadar** - Main radar display component (simplified and fixed)
2. **WeatherDataGenerator** - Generates realistic weather patterns
3. **RadarRenderer** - Handles all drawing operations
4. **GameIntegration** - Connects radar to main game systems

### Component Relationships

```
SimpleWeatherGame
    └── MapRadar (simplified)
        ├── WeatherDataGenerator
        ├── RadarRenderer
        └── UI Components
```

## Components and Interfaces

### MapRadar (Simplified)

**Purpose:** Main radar control that orchestrates weather display and user interface

**Key Methods:**
- `_ready()` - Initialize radar components
- `_process(delta)` - Update sweep angle and weather
- `_draw()` - Coordinate all rendering
- `generate_weather()` - Create new weather patterns
- `update_weather_motion(delta)` - Move weather systems

**Properties:**
- `sweep_angle: float` - Current radar sweep position
- `sweep_speed: float` - Rotation speed of radar beam
- `weather_echoes: Array` - Current weather data points
- `radar_center: Vector2` - Center point of radar display
- `radar_radius: float` - Maximum radar range

### WeatherDataGenerator

**Purpose:** Creates realistic weather patterns for display

**Key Methods:**
- `generate_scattered_storms(center, count, intensity)` - Create scattered thunderstorms
- `generate_supercell(center, intensity)` - Create rotating supercell
- `generate_hurricane(center, intensity, eye_size)` - Create hurricane pattern
- `update_storm_motion(delta)` - Move weather systems over time

**Data Structure:**
```gdscript
WeatherEcho = {
    "position": Vector2,      # Relative position (0-1)
    "intensity": float,       # 0-1 intensity value
    "size": float,           # Echo size multiplier
    "type": String,          # "convective", "stratiform", etc.
    "age": float             # Time since creation
}
```

### RadarRenderer

**Purpose:** Handles all radar drawing operations using Godot's 2D canvas

**Key Methods:**
- `draw_radar_background(center, radius)` - Draw radar scope and grid
- `draw_range_rings(center, radius, count)` - Draw distance markers
- `draw_weather_echoes(echoes, center, radius)` - Draw weather returns
- `draw_sweep_beam(center, radius, angle)` - Draw rotating beam
- `draw_radar_info(position)` - Draw text overlays

**Color Scheme:**
- Background: Dark blue/black
- Grid: Green (traditional radar green)
- Weather: Green → Yellow → Orange → Red (by intensity)
- Sweep beam: Bright green with fading trail

## Data Models

### Weather Echo Structure
```gdscript
class WeatherEcho:
    var position: Vector2     # Normalized coordinates (0-1)
    var intensity: float      # Reflectivity (0-1)
    var size: float          # Size multiplier
    var velocity: Vector2    # Movement vector
    var type: String         # Storm type
    var age: float           # Time alive
    var fade_rate: float     # How quickly it fades
```

### Radar Configuration
```gdscript
class RadarConfig:
    var sweep_speed: float = 1.0        # Rotations per second
    var range_rings: int = 5            # Number of range circles
    var beam_width: float = 2.0         # Beam width in degrees
    var echo_persistence: float = 3.0   # How long echoes remain visible
    var weather_update_rate: float = 5.0 # Seconds between weather updates
```

## Error Handling

### Texture Loading Failures
- **Issue:** Map textures fail to load
- **Solution:** Provide fallback solid color background
- **Implementation:** Check texture validity before use, use ColorRect as backup

### Performance Degradation
- **Issue:** Too many weather echoes cause frame drops
- **Solution:** Limit maximum echo count and use culling
- **Implementation:** Cap echoes at 100, remove oldest when limit exceeded

### Shader Compilation Errors
- **Issue:** Complex shaders fail on some systems
- **Solution:** Use only built-in Godot 2D drawing functions
- **Implementation:** Remove all custom shader dependencies

## Testing Strategy

### Unit Testing
- Test weather generation algorithms for realistic patterns
- Test echo aging and removal systems
- Test coordinate transformations between screen and radar space

### Integration Testing
- Test radar display with various weather scenarios
- Test performance with maximum echo counts
- Test radar display at different screen resolutions

### Visual Testing
- Verify radar colors match meteorological standards
- Verify sweep beam animation is smooth
- Verify weather echoes appear and fade correctly
- Verify text overlays are readable and positioned correctly

### Performance Testing
- Measure frame rate with maximum weather activity
- Test memory usage over extended periods
- Verify smooth operation on lower-end hardware

## Implementation Notes

### Simplification Strategy
The current codebase has multiple radar implementations (SimpleRadar, DopplerRadar, ProfessionalRadar, AuthenticRadarRenderer) that create complexity and potential conflicts. The fix will:

1. Use only the SimpleRadar as the base, but fix its issues
2. Remove dependencies on complex shader systems
3. Simplify weather data to basic echo points
4. Use Godot's built-in drawing functions exclusively

### Performance Optimizations
- Limit weather echoes to 100 maximum
- Use simple circular drawing instead of complex textures
- Update weather patterns every 5 seconds instead of every frame
- Cull echoes outside the visible radar range

### Compatibility Considerations
- Avoid custom shaders that may not work on all systems
- Use only standard Godot 4.x drawing functions
- Ensure the system works with GL Compatibility renderer
- Test on both desktop and web export targets