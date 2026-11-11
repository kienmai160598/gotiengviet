#!/usr/bin/env bash
# Builds the Harper grammar checker (Rust) into an xcframework plus Swift bindings for the
# VietKeyGrammar package. Needs cargo; Apple Silicon Macs only for now.
set -euo pipefail
cd "$(dirname "$0")/../Grammar"
export PATH="$HOME/.cargo/bin:$PATH"

TARGET="aarch64-apple-darwin"
LIB="target/$TARGET/release/libvietkey_grammar.a"
GENERATED="target/uniffi"
FRAMEWORK="build/VietKeyGrammarFFI.xcframework"

cargo build --release --locked --target "$TARGET" --lib --bin uniffi-bindgen-swift

rm -rf "$GENERATED" "$FRAMEWORK"
mkdir -p "$GENERATED/headers" Sources/VietKeyGrammar
BINDGEN="target/$TARGET/release/uniffi-bindgen-swift"
"$BINDGEN" --swift-sources "$LIB" Sources/VietKeyGrammar
"$BINDGEN" --headers "$LIB" "$GENERATED/headers"
"$BINDGEN" --modulemap --module-name vietkey_grammarFFI \
  --modulemap-filename module.modulemap "$LIB" "$GENERATED/headers"

xcodebuild -create-xcframework -library "$LIB" -headers "$GENERATED/headers" -output "$FRAMEWORK" >/dev/null
echo "Built $FRAMEWORK"
