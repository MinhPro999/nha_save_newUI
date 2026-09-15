#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_image="${1:-${project_root}/assets/images/app_logo.png}"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required (missing 'magick' command)." >&2
  exit 1
fi

if [[ ! -f "${source_image}" ]]; then
  echo "Logo source not found: ${source_image}" >&2
  exit 1
fi

images_dir="${project_root}/assets/images"
android_res="${project_root}/android/app/src/main/res"
ios_icons="${project_root}/ios/Runner/Assets.xcassets/AppIcon.appiconset"
web_dir="${project_root}/web"

render_transparent() {
  local canvas_size="$1"
  local artwork_size="$2"
  local output_path="$3"
  magick "${source_image}" -trim +repage \
    -resize "${artwork_size}x${artwork_size}" \
    -gravity center -background none \
    -extent "${canvas_size}x${canvas_size}" \
    -strip "${output_path}"
}

render_opaque() {
  local canvas_size="$1"
  local artwork_size="$2"
  local output_path="$3"
  magick "${source_image}" -trim +repage \
    -resize "${artwork_size}x${artwork_size}" \
    -gravity center -background white \
    -extent "${canvas_size}x${canvas_size}" \
    -alpha remove -alpha off -strip "${output_path}"
}

# Project assets: a transparent in-app logo, an opaque launcher source, and
# splash variants with platform-safe padding.
render_transparent 1024 940 "${images_dir}/app_logo.png"
render_opaque 1024 860 "${images_dir}/app_launcher_icon.png"
render_transparent 512 400 "${images_dir}/splash_logo.png"
render_transparent 960 600 "${images_dir}/splash_logo_android12.png"

# Android legacy launcher icons.
render_opaque 48 40 "${android_res}/mipmap-mdpi/ic_launcher.png"
render_opaque 72 60 "${android_res}/mipmap-hdpi/ic_launcher.png"
render_opaque 96 80 "${android_res}/mipmap-xhdpi/ic_launcher.png"
render_opaque 144 120 "${android_res}/mipmap-xxhdpi/ic_launcher.png"
render_opaque 192 160 "${android_res}/mipmap-xxxhdpi/ic_launcher.png"

# Android adaptive foreground: all artwork stays inside the 66dp safe zone.
render_transparent 432 252 "${android_res}/drawable/ic_launcher_foreground.png"

# iOS icons must be opaque. Generate every size declared by Contents.json.
ios_sizes=(20 40 60 29 58 87 40 80 120 120 180 76 152 167 1024)
ios_files=(
  Icon-App-20x20@1x.png Icon-App-20x20@2x.png Icon-App-20x20@3x.png
  Icon-App-29x29@1x.png Icon-App-29x29@2x.png Icon-App-29x29@3x.png
  Icon-App-40x40@1x.png Icon-App-40x40@2x.png Icon-App-40x40@3x.png
  Icon-App-60x60@2x.png Icon-App-60x60@3x.png
  Icon-App-76x76@1x.png Icon-App-76x76@2x.png
  Icon-App-83.5x83.5@2x.png Icon-App-1024x1024@1x.png
)
for index in "${!ios_sizes[@]}"; do
  size="${ios_sizes[$index]}"
  artwork_size=$((size * 84 / 100))
  render_opaque "${size}" "${artwork_size}" "${ios_icons}/${ios_files[$index]}"
done

# Web/PWA icons, including mask-safe variants.
render_opaque 192 160 "${web_dir}/icons/Icon-192.png"
render_opaque 512 430 "${web_dir}/icons/Icon-512.png"
render_opaque 192 116 "${web_dir}/icons/Icon-maskable-192.png"
render_opaque 512 308 "${web_dir}/icons/Icon-maskable-512.png"
render_opaque 16 14 "${web_dir}/favicon.png"

echo "Generated Android, iOS, web, in-app, and splash assets from ${source_image}"
