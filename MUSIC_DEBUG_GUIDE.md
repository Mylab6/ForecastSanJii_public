# Music Debugging Guide

## Why Music Might Not Work

### 1. **Browser Autoplay Policy** (Most Common)
- Modern browsers block audio until user interaction
- **Solution**: Click the music button (🎵 Start Music) in the top-right corner

### 2. **File Format Issues**
- MP3 works but OGG Vorbis is recommended for web
- **Current files**: `Rolling Clouds.mp3`, `Moonlit sky.mp3`
- **Status**: Should work, but consider converting to .ogg

### 3. **Export Settings**
- Ensure Web export includes audio files
- **Status**: ✅ Files should be included automatically

## How to Test Music

### In Editor:
1. Run the game in Godot editor
2. Music should auto-play (no browser restrictions)

### In Web Build:
1. Export and run web build
2. **MUST click the music button first** - browsers require user interaction
3. Check browser console (F12) for errors

## Debugging Steps

### 1. Check if GlobalMusic is working:
```gdscript
# In any script:
var global_music = get_node_or_null("/root/GlobalMusic")
if global_music:
    print("GlobalMusic found: ", global_music)
    print("Music playing: ", global_music.is_playing())
else:
    print("ERROR: GlobalMusic not found!")
```

### 2. Manual music start:
```gdscript
# Force start music (call after user interaction):
if global_music and global_music.has_method("start_music"):
    global_music.start_music()
```

### 3. Check audio files:
```gdscript
# Verify files exist:
var files = ["Rolling Clouds.mp3", "Moonlit sky.mp3"]
for file in files:
    var path = "res://assets/audio/ws4kp-music/" + file
    print(file, " exists: ", ResourceLoader.exists(path))
```

## Browser Console Errors to Look For:
- `"The AudioContext was not allowed to start"`
- `"Autoplay policy"` 
- `"User activation is required"`

## Quick Fixes Applied:
- ✅ Enabled music looping
- ✅ Added auto-advance between tracks  
- ✅ Improved error handling
- ✅ Added music start validation

## If Music Still Doesn't Work:
1. **Convert MP3 to OGG**: Use Audacity or online converter
2. **Check browser permissions**: Some browsers block audio entirely
3. **Test in different browsers**: Chrome, Firefox, Safari behavior varies
4. **Use HTTPS**: Some browsers require secure context for audio

## Web Export Checklist:
- [ ] Music button clicked after page load
- [ ] Browser console shows no audio errors  
- [ ] Files exported correctly to build/
- [ ] HTTPS if testing cross-origin