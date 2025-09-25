# Design Document

## Overview

The Enhanced Game Mechanics system transforms the existing San Jii Metro weather radar visualization into a complete emergency meteorologist training simulation. The design builds upon the existing MapRadar.gd foundation while adding comprehensive game logic, authentic Doppler radar visualization, and interactive decision-making mechanics. The system will provide a realistic training environment where players analyze weather patterns and make critical emergency management decisions under time pressure.

## Architecture

### Core Components

#### 1. Game State Manager
- **GameController**: Central orchestrator managing game rounds, timing, and state transitions
- **ScenarioManager**: Handles weather scenario generation and management
- **ScoreManager**: Tracks player performance, career progression, and statistics
- **AudioManager**: Manages voice synthesis, sound effects, and atmospheric audio

#### 2. Enhanced Radar System
- **AuthenticRadarRenderer**: Replaces simple circle rendering with realistic Doppler radar visualization
- **WeatherPatternGenerator**: Creates authentic storm signatures and radar patterns
- **RadarDataProcessor**: Simulates real radar data processing and display

#### 3. Interactive UI System
- **DecisionInterface**: Manages the three-question decision-making process
- **TimerSystem**: Handles 90-second countdown and urgency indicators
- **FeedbackSystem**: Provides immediate response to player decisions
- **DebugInterface**: Provides debug mode with correct answer overlay

#### 4. Scenario System
- **WeatherScenarios**: Defines different storm types and their characteristics
- **ThreatAssessment**: Evaluates player decisions against actual weather conditions
- **ConsequenceEngine**: Determines outcomes and career impacts

## Components and Interfaces

### GameController Interface
```gdscript
class_name GameController extends Control

# Core game state
enum GameState { MENU, ROUND_ACTIVE, DECISION_PHASE, FEEDBACK, GAME_OVER }
var current_state: GameState
var current_round: int
var round_timer: float
var player_stats: PlayerStats

# Main game loop methods
func start_new_game()
func start_round()
func process_decisions()
func end_round()
func evaluate_performance()
```

### AuthenticRadarRenderer Interface
```gdscript
class_name AuthenticRadarRenderer extends Node2D

# Radar visualization methods
func render_precipitation_polygons(weather_data: Array)
func render_storm_signatures(storm_type: String, position: Vector2)
func render_velocity_data(velocity_field: Array)
func apply_dbz_color_scale(intensity: float) -> Color
func render_radar_artifacts(storm_data: StormData)
```

### DecisionInterface Interface
```gdscript
class_name DecisionInterface extends Control

# Decision tracking
var selected_areas: Array[String]
var selected_response: String
var selected_priority: String

# UI interaction methods
func present_impact_question()
func present_response_question()
func present_priority_question()
func validate_decisions() -> bool
func reset_selections()
```

## Data Models

### PlayerStats
```gdscript
class_name PlayerStats extends Resource

var accuracy_rate: float
var response_time_avg: float
var lives_saved: int
var economic_impact: int
var career_level: String
var successful_rounds: int
var total_rounds: int
var false_evacuations: int
var missed_threats: int
```

### WeatherScenario
```gdscript
class_name WeatherScenario extends Resource

var scenario_name: String
var storm_type: String
var affected_areas: Array[String]
var correct_response: String
var correct_priority: String
var storm_intensity: float
var movement_pattern: Vector2
var radar_signature: Dictionary
var threat_level: int
```

### StormData
```gdscript
class_name StormData extends Resource

var storm_cells: Array[StormCell]
var velocity_data: Array[Vector2]
var reflectivity_data: Array[float]
var storm_motion: Vector2
var rotation_signature: bool
var mesocyclone_present: bool
var hook_echo: bool
```

## Authentic Doppler Radar Visualization

### Primary Approach: Polygonal Storm Cells
The system will render weather echoes as irregular polygons that simulate real precipitation patterns:

#### Storm Cell Rendering
- **Supercells**: Hook-shaped polygons with mesocyclone signatures
- **Squall Lines**: Linear arrangements of connected storm cells
- **Scattered Storms**: Irregular circular to oval shapes
- **Hurricane Eyewall**: Circular wall with clear eye center

#### Color Scale Implementation
```gdscript
func get_dbz_color(reflectivity: float) -> Color:
    # Authentic NWS color scale
    if reflectivity < 5: return Color.TRANSPARENT
    elif reflectivity < 15: return Color(0.0, 0.9, 0.0, 0.7)  # Light green
    elif reflectivity < 25: return Color(0.0, 0.6, 0.0, 0.8)  # Green
    elif reflectivity < 35: return Color(1.0, 1.0, 0.0, 0.8)  # Yellow
    elif reflectivity < 45: return Color(1.0, 0.5, 0.0, 0.8)  # Orange
    elif reflectivity < 55: return Color(1.0, 0.0, 0.0, 0.9)  # Red
    else: return Color(1.0, 0.0, 1.0, 0.9)  # Magenta (extreme)
```

### Fallback Approach: Semi-Transparent Rectangles
If polygon rendering proves complex, the system will use semi-transparent rectangular storm cells:

#### Rectangle-Based Storm Rendering
- **Variable sizes**: Different rectangle dimensions for storm intensity
- **Clustering**: Multiple overlapping rectangles for storm complexes
- **Rotation**: Rotated rectangles to simulate storm orientation
- **Transparency**: Alpha blending for realistic precipitation appearance

```gdscript
func render_storm_rectangles(storm_data: StormData):
    for cell in storm_data.storm_cells:
        var rect_size = Vector2(cell.width, cell.height)
        var rect_pos = cell.position - rect_size * 0.5
        var color = get_dbz_color(cell.reflectivity)
        
        # Rotate rectangle based on storm motion
        var transform = Transform2D()
        transform = transform.rotated(cell.rotation)
        transform.origin = cell.position
        
        draw_set_transform_matrix(transform)
        draw_rect(Rect2(-rect_size * 0.5, rect_size), color)
```

## Game Flow Design

### Round Structure
1. **Scenario Initialization** (5 seconds)
   - Load weather scenario
   - Generate authentic radar patterns
   - Initialize storm movement

2. **Analysis Phase** (90 seconds)
   - Display evolving radar data
   - Player observes storm development
   - Timer countdown with urgency indicators

3. **Decision Phase** (Within 90 seconds)
   - Present three-question interface
   - Validate selections
   - Confirm critical decisions (evacuation)

4. **Evaluation Phase** (10 seconds)
   - Assess player decisions
   - Calculate consequences
   - Provide immediate feedback

5. **Feedback Phase** (15 seconds)
   - Display results and reasoning
   - Update player statistics
   - Advance to next round or end game

### Decision Logic Flow
```
Impact Assessment → Response Selection → Priority Assignment
       ↓                    ↓                    ↓
Multiple Choice      Single Choice        Conditional Choice
(Areas affected)   (Action level)       (Based on response)
       ↓                    ↓                    ↓
Validation Check → Confirmation → Final Evaluation
```

## Debug Mode System

### Debug Interface Design
The debug mode provides training assistance by displaying correct answers during gameplay, helping users learn proper meteorological decision-making patterns.

#### Debug Mode Activation
- **Toggle Control**: Checkbox in main menu or settings panel
- **Persistent Setting**: Debug mode preference saved between sessions
- **Visual Indicator**: Clear indication when debug mode is active
- **Performance Impact**: Minimal overhead when disabled

#### Debug Information Display

##### 1. Area Impact Overlay
```gdscript
# Debug overlay for affected areas
func render_debug_areas(scenario: WeatherScenario):
    for area in scenario.correct_areas:
        var area_bounds = get_area_boundaries(area)
        draw_rect(area_bounds, Color.GREEN, false, 3.0)  # Green outline
        draw_text(area_bounds.position, area + " ✓", debug_font, Color.GREEN)
```

##### 2. Response Level Indicator
- **Correct Response**: Display optimal action level prominently
- **Color Coding**: 
  - Green for WEATHER ADVISORY
  - Yellow for SHELTER IN PLACE  
  - Red for EVACUATE NOW
- **Reasoning**: Brief explanation of why this response is correct

##### 3. Priority Level Guide
- **Conditional Display**: Show priority options based on selected response
- **Correct Highlight**: Emphasize the appropriate priority level
- **Context Information**: Explain priority level reasoning

#### Debug UI Layout
```gdscript
class_name DebugInterface extends Control

var debug_enabled: bool = false
var debug_panel: Panel
var area_overlay: Control
var response_indicator: Label
var priority_guide: VBoxContainer

func show_debug_info(scenario: WeatherScenario):
    if not debug_enabled:
        return
    
    # Show correct areas with green highlights
    highlight_correct_areas(scenario.correct_areas)
    
    # Display correct response with color coding
    response_indicator.text = "Correct Response: " + scenario.correct_response
    response_indicator.modulate = get_response_color(scenario.correct_response)
    
    # Show correct priority
    priority_guide.get_child(0).text = "Correct Priority: " + scenario.correct_priority
```

#### Debug Mode Features

##### Visual Indicators
- **Area Highlighting**: Green outlines around correct impact areas
- **Response Badges**: Color-coded badges showing correct response level
- **Priority Arrows**: Visual indicators pointing to correct priority selection
- **Storm Analysis**: Overlay showing key meteorological features

##### Information Panel
```
┌─ DEBUG MODE ACTIVE ─────────────────┐
│ Scenario: Hurricane Elena           │
│ ✓ Affected Areas: Puerto Shan,      │
│   Bahía Azul                        │
│ ✓ Correct Response: EVACUATE NOW    │
│ ✓ Correct Priority: HIGH            │
│ Storm Features: Eyewall, Cat 4      │
│ Threat Level: 5/5                   │
└─────────────────────────────────────┘
```

##### Interactive Hints
- **Hover Information**: Additional context when hovering over areas
- **Progressive Disclosure**: Reveal hints gradually if player struggles
- **Explanation Mode**: Detailed reasoning for each correct answer
- **Learning Objectives**: Show what meteorological concepts are being tested

#### Debug Mode Implementation

##### Settings Integration
```gdscript
# In GameController or SettingsManager
var debug_mode_enabled: bool = false

func toggle_debug_mode():
    debug_mode_enabled = !debug_mode_enabled
    if debug_interface:
        debug_interface.set_debug_enabled(debug_mode_enabled)
    
    # Save preference
    save_debug_preference()

func save_debug_preference():
    var config = ConfigFile.new()
    config.set_value("debug", "enabled", debug_mode_enabled)
    config.save("user://debug_settings.cfg")
```

##### Conditional Rendering
```gdscript
func _draw():
    # Normal radar rendering
    render_storm_data()
    render_geographic_features()
    
    # Debug overlay (only if enabled)
    if debug_mode_enabled and current_scenario:
        render_debug_overlay(current_scenario)

func render_debug_overlay(scenario: WeatherScenario):
    # Highlight correct areas
    for area_name in scenario.correct_areas:
        var area_polygon = get_area_polygon(area_name)
        draw_colored_polygon(area_polygon, Color(0, 1, 0, 0.3))  # Semi-transparent green
        draw_polyline(area_polygon, Color.GREEN, 2.0)  # Green border
    
    # Show correct response indicator
    var response_pos = Vector2(20, 50)
    var response_text = "✓ " + scenario.correct_response
    var response_color = get_response_debug_color(scenario.correct_response)
    draw_string(debug_font, response_pos, response_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, response_color)
```

#### Educational Integration

##### Learning Mode
- **Explanation Tooltips**: Detailed reasoning for each correct answer
- **Meteorological Context**: Connect decisions to weather science principles
- **Pattern Recognition**: Highlight key radar signatures that inform decisions
- **Best Practices**: Show professional meteorologist decision-making process

##### Training Progression
- **Gradual Reduction**: Automatically reduce debug assistance as player improves
- **Confidence Building**: Allow players to verify their instincts
- **Skill Assessment**: Track improvement when debug mode is disabled
- **Certification Path**: Prepare players for debug-free professional scenarios

#### Debug Mode Constraints

##### Performance Considerations
- **Lazy Loading**: Only compute debug information when mode is active
- **Efficient Rendering**: Minimize additional draw calls
- **Memory Usage**: Avoid storing debug data when disabled
- **Frame Rate**: Maintain 60 FPS even with debug overlays

##### User Experience
- **Non-Intrusive**: Debug information should not obstruct normal gameplay
- **Clear Distinction**: Obvious visual separation between game and debug elements
- **Easy Toggle**: Quick access to enable/disable during gameplay
- **Accessibility**: Debug text readable with various color vision conditions

## Error Handling

### Radar Rendering Fallbacks
1. **Primary**: Authentic polygon storm cells
2. **Secondary**: Semi-transparent rectangles
3. **Tertiary**: Enhanced circle rendering (current system)
4. **Emergency**: Simple colored circles

### Game State Recovery
- **Timer Expiration**: Auto-submit current selections
- **Invalid Selections**: Prompt for correction with time penalty
- **System Errors**: Graceful degradation to previous working state
- **Audio Failures**: Continue with visual-only feedback

### Performance Optimization
- **Radar Rendering**: LOD system for complex storm patterns
- **Audio Processing**: Async voice synthesis with fallback text
- **Memory Management**: Efficient storm data caching and cleanup

## Testing Strategy

### Unit Testing
- **GameController**: State transitions and round management
- **AuthenticRadarRenderer**: Color scale accuracy and polygon generation
- **DecisionInterface**: Input validation and UI state management
- **ScenarioManager**: Weather pattern generation and threat assessment

### Integration Testing
- **Complete Game Rounds**: End-to-end gameplay flow
- **Radar-UI Integration**: Synchronized display and interaction
- **Audio-Visual Sync**: Voice acting timing with visual events
- **Performance Testing**: Frame rate stability during complex weather

### User Experience Testing
- **Decision Timing**: 90-second pressure testing
- **Radar Interpretation**: Accuracy of weather pattern recognition
- **Career Progression**: Balanced difficulty and advancement
- **Accessibility**: Color-blind friendly radar displays

### Meteorological Accuracy Testing
- **Storm Signatures**: Validation against real radar patterns
- **Geographic Realism**: Storm positioning and movement patterns
- **Threat Assessment**: Correlation between radar data and correct decisions
- **Educational Value**: Alignment with professional meteorological training

## Performance Considerations

### Rendering Optimization
- **Storm Cell Batching**: Group similar cells for efficient rendering
- **Viewport Culling**: Only render visible storm elements
- **Texture Atlasing**: Combine storm pattern textures
- **Shader Optimization**: Efficient color blending and transparency

### Memory Management
- **Storm Data Pooling**: Reuse storm cell objects
- **Audio Streaming**: Load voice clips on-demand
- **Texture Compression**: Optimize radar background images
- **Garbage Collection**: Minimize allocations during gameplay

### Real-time Performance
- **60 FPS Target**: Maintain smooth radar sweep animation
- **Input Responsiveness**: Sub-100ms UI interaction latency
- **Timer Accuracy**: Precise 90-second countdown
- **Audio Latency**: Synchronized voice feedback with actions