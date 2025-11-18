# Quickshell Animations Configuration

## Overview
Quickshell uses QML's built-in animation framework for smooth UI transitions, following Caelestia-inspired design patterns with consistent timing and easing.

## Animation Framework
- **QML Behaviors**: Automatic animations triggered by property changes
- **Animation Types**: ColorAnimation for color transitions, NumberAnimation for numeric properties
- **Duration**: 150 milliseconds for all animations
- **Easing**: InOutQuad for smooth acceleration/deceleration

## Interactive Animations
- **Scale Effects**: Elements scale to 0.95 when pressed, returning to 1.0 on release
- **Color Transitions**: Smooth color changes for state indicators (active/inactive, connected/disconnected)
- **Trigger Events**: Mouse press events and state property changes

## Implementation Components
- **WorkspaceIndicator**: Scale and color animations for workspace switching
- **SpotifyIndicator**: Scale animation for media controls, color changes for playback state
- **NotificationIndicator**: Scale animation for notification actions, color changes for notification count
- **NetworkIndicator**: Color animations for connection state changes

## Animation Properties
- Scale animations use NumberAnimation with InOutQuad easing
- Color animations use ColorAnimation with InOutQuad easing
- All animations have 150ms duration for consistent feel
- Animations are bound to mouse interaction states and data model changes

## Performance Considerations
- Animations are lightweight and GPU-accelerated through QML
- Minimal animation count prevents performance impact
- Animations only trigger on user interaction or state changes</content>
<parameter name="filePath">/home/arafays/.config/quickshell/caelestia_research_animations.md