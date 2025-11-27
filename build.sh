#!/bin/bash
# Build script for tflint-ruleset-backend
# Automatically loads GPG_KEY_ID from .env if it exists

# Load .env file if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

platforms=(
  "linux/amd64"
  "linux/arm64"
  "darwin/amd64"
  "darwin/arm64"
  "windows/amd64"
)

for platform in "${platforms[@]}"; do
  os=${platform%/*}
  arch=${platform#*/}
  out="dist/tflint-ruleset-backend"

  if [[ "$os" == "windows" ]]; then
    out="$out.exe"
  fi

  env GOOS=$os GOARCH=$arch go build -o "$out"

  zip -j "dist/tflint-ruleset-backend_${os}_${arch}.zip" "$out"
  rm "$out"
done

pushd dist
ls tflint-ruleset-backend_*.zip
sha256sum tflint-ruleset-backend_*.zip > checksums.txt

# Sign the checksums file if GPG key is configured
if [ -n "$GPG_KEY_ID" ]; then
  echo "Signing checksums.txt with GPG key: $GPG_KEY_ID"
  gpg --armor --detach-sign --default-key "$GPG_KEY_ID" --output checksums.txt.sig checksums.txt
  echo "Created checksums.txt.sig"
else
  echo "Warning: GPG_KEY_ID not set. Skipping signature generation."
  echo "To sign releases, set GPG_KEY_ID environment variable and run:"
  echo "  export GPG_KEY_ID=your-key-id"
  echo "  ./build.sh"
fi
popd
