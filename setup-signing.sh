#!/bin/bash
# Script to set up PGP signing for tflint plugin releases

set -e

echo "Setting up PGP signing for tflint-ruleset-backend"
echo ""

# Check if gpg is installed
if ! command -v gpg &> /dev/null; then
  echo "Error: gpg is not installed. Please install GnuPG first:"
  echo "  macOS: brew install gnupg"
  echo "  Linux: sudo apt-get install gnupg (or equivalent)"
  exit 1
fi

# Check if key already exists
if [ -f "public_key.asc" ]; then
  echo "public_key.asc already exists. Do you want to overwrite it? (y/N)"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "Step 1: Generate a new PGP key pair"
echo "-----------------------------------"
echo "You will be prompted to enter:"
echo "  - Key type: RSA and RSA (default)"
echo "  - Key size: 4096 (recommended)"
echo "  - Expiration: Your choice (0 = no expiration)"
echo "  - Name: Your name or organization"
echo "  - Email: Your email address"
echo "  - Comment: Optional comment"
echo ""
echo "Press Enter to continue..."
read -r

gpg --full-generate-key

# Get the key ID of the newly created key
KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep -A 1 "^sec" | tail -1 | awk '{print $1}' | cut -d'/' -f2)

if [ -z "$KEY_ID" ]; then
  echo "Error: Could not determine key ID. Please check your GPG keys manually."
  exit 1
fi

echo ""
echo "Generated key ID: $KEY_ID"
echo ""

# Export public key
echo "Step 2: Exporting public key to public_key.asc"
echo "----------------------------------------------"
gpg --armor --export "$KEY_ID" > public_key.asc
echo "Public key exported to public_key.asc"
echo ""

# Display the public key
echo "Your public key:"
echo "=================="
cat public_key.asc
echo "=================="
echo ""

# Create .env file with key ID
if [ -f ".env" ]; then
  echo ".env file already exists. Do you want to add GPG_KEY_ID to it? (y/N)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    if grep -q "GPG_KEY_ID" .env; then
      sed -i.bak "s/^GPG_KEY_ID=.*/GPG_KEY_ID=$KEY_ID/" .env
    else
      echo "GPG_KEY_ID=$KEY_ID" >> .env
    fi
    echo "Updated .env with GPG_KEY_ID=$KEY_ID"
  fi
else
  echo "GPG_KEY_ID=$KEY_ID" > .env
  echo "Created .env file with GPG_KEY_ID=$KEY_ID"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Add public_key.asc to your repository (or publish it separately)"
echo "2. When building releases, set GPG_KEY_ID environment variable:"
echo "   export GPG_KEY_ID=$KEY_ID"
echo "   ./build.sh"
echo "3. Include checksums.txt.sig in your releases"
echo "4. Share your public key with users so they can add it to their .tflint.hcl:"
echo ""
echo "   plugin \"backend\" {"
echo "     enabled = true"
echo "     version = \"0.1.0\""
echo "     source  = \"github.com/IamEnTm/tflint-ruleset-backend\""
echo ""
echo "     signing_key = <<-KEY"
echo "     $(cat public_key.asc | sed 's/^/     /')"
echo "     KEY"
echo "   }"
echo ""

