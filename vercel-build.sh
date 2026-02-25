#!/bin/bash

# 1. Download Flutter SDK
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Add to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# 3. Pre-cache and check
flutter precache
flutter doctor

# 4. Build
flutter build web --release --web-renderer html --base-href=/
