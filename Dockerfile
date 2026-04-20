FROM docker.io/library/alpine:3.23.4 AS fetch

RUN apk add --no-cache curl minisign xz

ARG ZIG_VERSION
ARG TARGETARCH

ADD https://ziglang.org/download/community-mirrors.txt /tmp/zig-mirrors.txt

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64)   arch=x86_64       ;; \
        arm64)   arch=aarch64      ;; \
        arm)     arch=arm          ;; \
        386)     arch=x86          ;; \
        riscv64) arch=riscv64      ;; \
        ppc64le) arch=powerpc64le  ;; \
        s390x)   arch=s390x        ;; \
        *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    tarball="zig-${arch}-linux-${ZIG_VERSION}.tar.xz"; \
    { shuf /tmp/zig-mirrors.txt; echo "https://ziglang.org/download/${ZIG_VERSION}"; } > /tmp/zig-try.txt; \
    while read -r mirror; do \
        echo "Trying ${mirror}"; \
        if curl -fsSL -o "/tmp/${tarball}" "${mirror}/${tarball}?source=zig-toolchain-docker" \
            && curl -fsSL -o "/tmp/${tarball}.minisig" "${mirror}/${tarball}.minisig?source=zig-toolchain-docker"; then \
            break; \
        fi; \
        rm -f "/tmp/${tarball}" "/tmp/${tarball}.minisig"; \
    done < /tmp/zig-try.txt; \
    test -s "/tmp/${tarball}"; \
    test -s "/tmp/${tarball}.minisig"

RUN set -eux; \
    tarball=$(basename /tmp/zig-*-linux-*.tar.xz); \
    minisign -Vm "/tmp/${tarball}" -x "/tmp/${tarball}.minisig" -P "RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U"; \
    grep -qE "^trusted comment:.*[[:space:]]file:${tarball}([[:space:]]|\$)" "/tmp/${tarball}.minisig"

RUN set -eux; \
    mkdir -p /opt/zig; \
    tar -xJf /tmp/zig-*-linux-*.tar.xz -C /opt/zig --strip-components=1; \
    rm -f /tmp/zig-*-linux-*.tar.xz /tmp/zig-*-linux-*.tar.xz.minisig \
          /tmp/zig-mirrors.txt /tmp/zig-try.txt

FROM scratch

COPY <<EOF /etc/group
_zig:x:65534:
EOF

COPY <<EOF /etc/passwd
_zig:x:65534:65534:zig:/dev/null:/etc
EOF

COPY --from=fetch /opt/zig /opt/zig

USER 65534:65534

WORKDIR /work

LABEL org.opencontainers.image.source=https://github.com/matt-allan/zig-toolchain
LABEL org.opencontainers.image.description="Zig toolchain"
LABEL org.opencontainers.image.licenses=MIT

ENTRYPOINT ["/opt/zig/zig"]