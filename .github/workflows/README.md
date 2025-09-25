# Deploy to itch.io

This GitHub Actions workflow automatically builds and deploys your ForecastSanJii game to itch.io whenever you push to the main branch.

## Setup Instructions

### 1. Create itch.io API Key
1. Go to your [itch.io account settings](https://itch.io/user/settings/api-keys)
2. Generate a new API key
3. Copy the API key

### 2. Add Repository Secrets
In your GitHub repository, go to Settings → Secrets and variables → Actions and add:

- `BUTLER_API_KEY`: Your itch.io API key
- `ITCH_GAME_URL`: Your game's itch.io URL in the format `username/game-name` (e.g., `mylab6/forecast-sanjii`)

### 3. Configure Export Preset
Make sure your `export_presets.cfg` has a "Web" preset configured for HTML5 export.

## Workflow Triggers

- **Automatic**: Triggers on every push to the `main` branch
- **Manual**: Can be triggered manually from the Actions tab

## What it does

1. **Build**: Exports the game for HTML5 using Godot
2. **Package**: Zips all web files (HTML, JS, WASM, PCK)
3. **Deploy**: Uploads to itch.io using Butler

## Required Secrets

- `BUTLER_API_KEY`: Your itch.io API key for authentication
- `ITCH_GAME_URL`: Your game's itch.io URL (username/game-name format)

## File Structure

After running, the workflow creates:
```
build/
├── ForcastSanJii.html
├── ForcastSanJii.js
├── ForcastSanJii.wasm
├── ForcastSanJii.pck
└── forecast_sanjii_web.zip
```