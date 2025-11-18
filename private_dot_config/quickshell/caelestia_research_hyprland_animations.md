# Hyprland Animations in Caelestia

## Overview
Caelestia's Hyprland configuration includes carefully tuned animations that provide smooth, responsive transitions throughout the desktop environment. The animations are defined in `animations.conf` with custom bezier curves for different interaction types.

## Bezier Curves
- **specialWorkSwitch**: Used for special workspace transitions (0.05, 0.7, 0.1, 1)
- **emphasizedAccel**: Fast acceleration for quick actions (0.3, 0, 0.8, 0.15)
- **emphasizedDecel**: Smooth deceleration for emphasis (0.05, 0.7, 0.1, 1)
- **standard**: Balanced curve for general animations (0.2, 0, 0, 1)

## Animation Types
- **layersIn/Out**: Layer transitions with slide effects
- **fadeLayers**: Opacity transitions for layers
- **windowsIn/Out/Move**: Window appearance, disappearance, and movement
- **workspaces**: Workspace switching animations
- **specialWorkspace**: Special workspace with vertical slide (15% offset)
- **fade/fadeDim/border**: General fading and border animations

## Performance Considerations
- Animations are enabled by default but can be disabled for performance
- Uses Hyprland's built-in animation system for hardware acceleration
- Curves are optimized to feel responsive without being jarring
- Special workspace animation provides visual feedback for toggles

## Integration with Shell
Animations work in concert with the Caelestia shell's special workspace toggles, providing smooth transitions when opening/closing system monitors, music controls, etc.