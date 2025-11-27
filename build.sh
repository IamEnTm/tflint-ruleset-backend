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
popd
