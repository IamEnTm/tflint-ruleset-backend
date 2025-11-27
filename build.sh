#!/bin/bash
# Build script for tflint-ruleset-backend
# Automatically loads GPG_KEY_ID from .env if it exists

set -e  # Exit on error

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

  # Sign with batch mode to avoid interactive prompts
  # Note: TFLint requires binary format (not ASCII-armored) signatures
  if gpg --batch --yes --detach-sign --default-key "$GPG_KEY_ID" --output checksums.txt.sig checksums.txt 2>&1; then
    # Verify the signature file was created and is not empty
    if [ ! -f checksums.txt.sig ] || [ ! -s checksums.txt.sig ]; then
      echo "Error: Signature file was not created or is empty"
      exit 1
    fi

    # Verify it's a binary GPG signature file (not ASCII-armored)
    # Binary PGP signatures start with packet tags (0x88-0x8F for signature packets)
    # ASCII-armored signatures start with "-----BEGIN PGP SIGNATURE-----"
    if head -c 1 checksums.txt.sig | od -An -tx1 | grep -qE "8[89abcdef]"; then
      echo "✓ Signature file is in binary PGP format"
    elif grep -q "BEGIN PGP SIGNATURE" checksums.txt.sig 2>/dev/null; then
      echo "Error: Signature file is ASCII-armored, but TFLint requires binary format"
      echo "       Remove --armor flag from GPG command"
      exit 1
    else
      echo "Warning: Could not verify signature file format"
    fi

    # Verify the signature
    if gpg --verify checksums.txt.sig checksums.txt 2>&1; then
      echo "✓ Created and verified checksums.txt.sig"
    else
      echo "Warning: Signature created but verification failed"
      exit 1
    fi
  else
    echo "Error: Failed to sign checksums.txt"
    exit 1
  fi
else
  echo "Warning: GPG_KEY_ID not set. Skipping signature generation."
  echo "To sign releases, set GPG_KEY_ID environment variable and run:"
  echo "  export GPG_KEY_ID=your-key-id"
  echo "  ./build.sh"
fi
popd
