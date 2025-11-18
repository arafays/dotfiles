# zen Integration with Caelestia

## Configuration Overview
Zen Browser (Firefox fork) uses extensive userChrome.css customization for Caelestia theming with animations and modern UI elements.

## Key Features
- **Color Variables**: CSS custom properties for consistent theming
- **Animations**: Smooth transitions for UI elements (0.15s ease)
- **Blur Effects**: Backdrop filters for modern glass-like appearance
- **URL Bar**: Center-aligned text when not focused, floating animations
- **Tab Styling**: Dimmed unloaded tabs, scale animations on interaction

## Animations
- Floating URL bar with scale and opacity transitions
- Button press animations (scale to 0.95)
- Smooth transitions for all interactive elements
- Tab scaling effects

## UI Customizations
- Custom color scheme using CSS variables
- Rounded corners on menus and panels
- Blur effects on popups and floating elements
- Modified search bar styling
- Custom toolbar and sidebar theming

## Integration Notes
The userChrome.css is highly customized for Zen's specific UI elements. It includes commented-out sections that can be enabled for additional effects. The styling uses Zen-specific CSS variables and classes.

## Installation
According to Caelestia docs, the userChrome.css should be symlinked to `~/.zen/<profile>/chrome/userChrome.css`.