variable "ZIG_VERSION" {
  default = "0.16.0"
}

group "default" {
  targets = ["zig"]
}

target "zig" {
  dockerfile = "Dockerfile"
  tags = [
    "ghcr.io/matt-allan/zig:${ZIG_VERSION}"
  ]
  args = {
    ZIG_VERSION = ZIG_VERSION
  }
  platforms = [
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v7"
  ]
  annotations = [
    "manifest:org.opencontainers.image.description=Zig toolchain"
  ]
}