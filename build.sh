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
  out="tflint-ruleset-backend/tflint-ruleset-backend_${os}_${arch}"

  if [[ "$os" == "windows" ]]; then
    out="$out.exe"
  fi

  env GOOS=$os GOARCH=$arch go build -o "$out"

  zip "${out%.exe}.zip" "$out"
done