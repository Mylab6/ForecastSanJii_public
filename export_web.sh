#!/bin/bash

# Simple export script for ForecastSanJii web build
# This bypasses the Godot editor and uses command-line export

echo "Starting ForecastSanJii web export..."

# Create build directory
mkdir -p build

# Export using Godot headless
echo "Exporting web build..."
godot --headless --export-release "Web" build/ForcastSanJii.html

# Check if export was successful
if [ $? -eq 0 ]; then
    echo "Export successful!"

    # Move files if they were created in root
    if [ -f "ForcastSanJii.html" ]; then
        echo "Moving export files to build directory..."
        mv ForcastSanJii.* build/ 2>/dev/null || true
    fi

    # List the build files
    echo "Build files created:"
    ls -la build/

    # Create zip for distribution
    echo "Creating zip archive..."
    cd build/
    zip forecast_sanjii_web.zip ForcastSanJii.html ForcastSanJii.js ForcastSanJii.wasm ForcastSanJii.pck
    echo "Zip created: forecast_sanjii_web.zip"

else
    echo "Export failed!"
    exit 1
fi

echo "Export process complete!"