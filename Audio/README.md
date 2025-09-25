Audio utilities for ForecastSanJii

AudioManager.gd
- A tiny runtime audio manager that creates three AudioStreamPlayer nodes for music, SFX and alerts.
- Usage:
  - Add `Audio/AudioManager.gd` to a scene and call its methods, or add it as an Autoload (singleton) for global access.
  - Methods:
    - `play_music("res://path/to/music.ogg")`
    - `stop_music()`
    - `play_sfx("res://path/to/sfx.ogg")`
    - `play_alert("res://path/to/alert.ogg")`

Notes
- This is intentionally minimal. For web export, prefer OGG Vorbis streams.
- If you need positional 3D audio, replace AudioStreamPlayer with AudioStreamPlayer3D and pass positions.
