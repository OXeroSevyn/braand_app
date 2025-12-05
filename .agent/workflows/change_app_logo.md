---
description: How to change the app logo
---

# How to Change the App Logo

This workflow guides you through updating the application icon for both Android and iOS.

## Prerequisites
- A square image file (PNG recommended) for your logo.
- Minimum resolution: 1024x1024 pixels.

## Steps

1.  **Prepare your image:**
    - Rename your logo image to `icon.png`.
    - Ensure it is a high-quality square image.

2.  **Replace the existing icon:**
    - Go to the `assets` folder in your project root: `braand_app/assets/`.
    - Replace the existing `icon.png` with your new file.

3.  **Generate the icons:**
    - Open a terminal in the project directory.
    - Run the following command:
    ```bash
    dart run flutter_launcher_icons
    ```

4.  **Verify:**
    - Rebuild and run your app to see the new logo on your device or emulator.
    - Note: You might need to uninstall the app and reinstall it for the icon cache to clear on some devices.
