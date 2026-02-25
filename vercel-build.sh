#!/bin/bash

# 1. Download Flutter SDK if not present
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Prepend to PATH to ensure we use our localized version
export PATH="$(pwd)/flutter/bin:$PATH"

# 3. Configure and Prepare
flutter config --enable-web
flutter precache --web
flutter pub get

# 4. Build 
# Note: Removed --web-renderer as it's not recognized by this version's CLI
flutter build web --release --base-href=/
