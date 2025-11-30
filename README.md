# TFLint Backend Ruleset

A TFLint plugin that provides rules for validating Terraform backend configurations. This ruleset helps ensure proper backend configuration practices, such as enforcing native S3 locking and preventing deprecated locking mechanisms.

## Requirements

- TFLint v0.46+
- Go v1.25

## Installation

You can install the plugin with `tflint --init`. Declare a config in `.tflint.hcl` as follows:

```hcl
plugin "backend" {
  enabled = true

  version = "0.4.0"
  source  = "github.com/IamEnTm/tflint-ruleset-backend"

  signing_key = <<-KEY
   -----BEGIN PGP PUBLIC KEY BLOCK-----
   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
   PdA=
   =TL9a
   -----END PGP PUBLIC KEY BLOCK-----
  KEY
}
```

**Note:** The `signing_key` is required to verify the authenticity of the plugin. You can find the public key in the `public_key.asc` file included with each release, or in the repository root.

### Troubleshooting

If you encounter the error `Failed to check checksums.txt signature: openpgp: invalid argument: no armored data found`:

1. **Verify the signature file exists**: Ensure `checksums.txt.sig` is included in the release and is not empty.

2. **Check file encoding**: The signature file must use Unix line endings (LF). If you're manually creating releases, ensure the file isn't corrupted during upload.

3. **Regenerate the signature**: If the signature file is corrupted, rebuild the release:
   ```bash
   export GPG_KEY_ID=your-key-id
   ./build.sh
   ```

4. **Verify locally**: You can verify the signature manually:
   ```bash
   gpg --verify checksums.txt.sig checksums.txt
   ```

## Rules

|Name|Description|Severity|Enabled|Link|
| --- | --- | --- | --- | --- |
|backend_s3_lockfile|Ensures S3 backend uses native S3 locking (use_lockfile = true) and prevents use of deprecated DynamoDB locking|ERROR|✔|||

## Building the plugin

Clone the repository locally and run the following command:

```
$ make
```

You can easily install the built plugin with the following:

```
$ make install
```

### Building signed releases

To build signed releases for distribution:

1. **Set up PGP signing** (first time only):
   ```bash
   chmod +x setup-signing.sh
   ./setup-signing.sh
   ```
   This will:
   - Generate a PGP key pair
   - Export the public key to `public_key.asc`
   - Set up the `GPG_KEY_ID` environment variable

2. **Build and sign releases**:
   ```bash
   export GPG_KEY_ID=your-key-id  # Or use the .env file created by setup-signing.sh
   ./build.sh
   ```
   
   This will:
   - Build binaries for all platforms
   - Generate `checksums.txt` with SHA256 hashes
   - Sign `checksums.txt` to create `checksums.txt.sig`

3. **Include in releases**:
   When creating a GitHub release, include:
   - All `tflint-ruleset-backend_*.zip` files
   - `checksums.txt`
   - `checksums.txt.sig`
   - `public_key.asc`

### Running the plugin locally

You can run the built plugin like the following:

```
$ cat << EOS > .tflint.hcl
plugin "backend" {
  enabled = true
}
EOS
$ tflint
```
