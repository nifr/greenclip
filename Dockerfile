FROM alpine:3.16 as builder
ARG TARGETARCH

RUN apk --no-cache add ca-certificates xz make git curl gcc g++ llvm13 llvm13-dev musl-dev gmp-dev numa-dev zlib-dev pcre-dev libx11-dev libxcb-dev libxrandr-dev libx11-static libxcb-static libxrandr libxscrnsaver-dev
RUN  apk --no-cache add --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/community --repository http://dl-cdn.alpinelinux.org/alpine/v3.17/main llvm14 ghc

RUN  curl -sSL https://github.com/commercialhaskell/stack/releases/download/v2.13.1/stack-2.13.1-linux-$(case "${TARGETARCH}" in 'amd64') echo -n  'x86_64';; 'arm64') echo -n 'aarch64';;  esac).tar.gz \
| tar xvz && \
mv stack*/stack /usr/bin

COPY stack.yaml /mnt
COPY *.cabal /mnt
WORKDIR /mnt
#     sed -i 's/lts-20.0/lts-19.33/g' stack.yaml && \

# -system-ghc and --no-install-ghc
RUN rm -rf ~/.stack &&  \
    stack config set system-ghc --global true && \
    stack install --ghc-options="-fPIC -fllvm" --only-dependencies

COPY . /mnt

# Hack as no Xss static lib on alpine, we don't need it
RUN ar cru /usr/lib/libXss.a ; ar cru /usr/lib/libXrandr.a
RUN echo '  ld-options: -static -Wl,--unresolved-symbols=ignore-all' >> greenclip.cabal ; \
    stack config set system-ghc --global true && \
    stack install  --ghc-options="-fPIC -fllvm"
#RUN upx --ultra-brute /root/.local/bin/greenclip



FROM alpine:3.16 as runner

WORKDIR /root
COPY --from=builder /root/.local/bin/greenclip .
RUN chmod +x ./greenclip

CMD ["./greenclip"]

