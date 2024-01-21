#!/usr/bin/env bash

declare -ra apk_dependencies=(
  ca-certificates
  curl
  tar
  xz
  git
  make
  # gcompat
  # gcc
  # g++
  # libstdc++
  musl-dev
  gmp-dev
  zlib-dev
  pcre-dev
  libx11-dev
  libxcb-dev
  libxrandr
  libxrandr-dev
  libx11-static
  libxcb-static
  libxscrnsaver
  libxscrnsaver-dev
  libxinerama
  libxinerama-dev
  llvm14
  llvm14-dev
  # ghc
)
apk --no-cache add \
  --repository http://dl-cdn.alpinelinux.org/alpine/v3.19/community \
  --repository http://dl-cdn.alpinelinux.org/alpine/v3.19/main \
  "${apk_dependencies[@]}"

# install stack
readonly stack_version='2.13.1'
readonly stack_architecture="$(case "${TARGETARCH}" in 'amd64') echo -n  'x86_64';; 'arm64') echo -n 'aarch64';;  esac)"
curl -sSL \
  "https://github.com/commercialhaskell/stack/releases/download/v${stack_version}/stack-${stack_version}-linux-${stack_architecture}.tar.gz" \
| tar \
  -f- \
  -xz \
  -C /usr/local/bin/ \
  --strip-components=1 \
  "stack-${stack_version}-linux-${stack_architecture}/stack"
chmod +x /usr/local/bin/stack

# This is a dirty hack
ar cr /usr/lib/libXss.a
ar cr /usr/lib/libXrandr.a

# build the binary
stack build \
  --allow-different-user \
  --copy-bins \
  --local-bin-path='./dist' \
  --skip-ghc-check \
  --system-ghc \
  --no-install-ghc \
  --ghc-options='-O2 -static -optc-static -optl-static -optl-pthread -fPIC -fllvm -split-sections'

# output binary ELF information
file ./dist/greenclip
ldd ./dist/greenclip || true

