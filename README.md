# Zig toolchain images

Scratch images with the zig toolchain installed.

You can use this to easily add zig to another image:

```dockerfile
FROM ghcr.io/matt-allan/zig:0.16.0 AS zig
FROM alpine:latest
COPY --from=zig /opt/zig /opt/zig
```

Or you can use it directly:

```
docker run -v "$(pwd):/work" ghcr.io/matt-allan/zig:0.16.0 init
```

The toolchain is downloaded from [community mirrors](https://ziglang.org/download/community-mirrors/) with signature verification.

## Building

If you have docker with buildkit enabled use bake:

```shell
docker buildx bake
```

Otherwise build manually:

```shell
docker build --build-arg ZIG_VERSION=0.16.0 --platform=linux/arm64 .
```