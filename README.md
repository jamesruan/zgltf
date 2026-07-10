# zgltf

A glTF 2.0 library in Zig.

## Usage

```zig
const zgltf = @import("zgltf");

// Parse a .gltf JSON string
var doc = try zgltf.parse(allocator, source);
defer doc.deinit();

// Parse a .glb binary buffer
var doc = try zgltf.parseGlb(allocator, buffer);
defer doc.deinit();
```

## API

| Export | Description |
|---|---|
| `zgltf.parse(allocator, source)` | Parse a `.gltf` JSON string |
| `zgltf.parseGlb(allocator, source)` | Parse a `.glb` byte slice |
| `zgltf.Gltf` | Top-level glTF container struct |
| `zgltf.types` | All glTF 2.0 data types |
| `zgltf.extensions` | Extension types and parsers |
| `zgltf.errors` | Parse error definitions |

## Supported Features

All core glTF 2.0 features: accessors, animations, buffers/views, cameras, images, materials (PBR, normal/occlusion/emissive textures, alpha modes), meshes (morph targets), nodes (TRS + matrix), samplers, scenes, skins, textures, extras, and `extensionsUsed`/`extensionsRequired` metadata. Full GLB binary format support (header, JSON chunk, BIN chunk).

### Extensions

- **`KHR_texture_transform`** — Parsed on all texture info types (`TextureInfo`, `MaterialNormalTextureInfo`, `MaterialOcclusionTextureInfo`). Exposed as `zgltf.extensions.TextureTransform` with `offset`, `rotation`, `scale`, and `tex_coord` fields.

## Build

```
zig build test    # run tests
zig build         # build CLI
zig build run -- <file.gltf>  # run CLI
```

Minimum Zig version: `0.16.0`
