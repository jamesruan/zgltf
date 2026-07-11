const std = @import("std");
const types = @import("types.zig");
const jutils = @import("json_utils.zig");
const E = @import("error.zig");

const Gltf = types.Gltf;
const Asset = types.Asset;
const Accessor = types.Accessor;
const AccessorType = types.AccessorType;
const AccessorSparse = types.AccessorSparse;
const AccessorSparseIndices = types.AccessorSparseIndices;
const AccessorSparseValues = types.AccessorSparseValues;
const Animation = types.Animation;
const AnimationChannel = types.AnimationChannel;
const AnimationChannelTarget = types.AnimationChannelTarget;
const AnimationSampler = types.AnimationSampler;
const Buffer = types.Buffer;
const BufferView = types.BufferView;
const Camera = types.Camera;
const CameraOrthographic = types.CameraOrthographic;
const CameraPerspective = types.CameraPerspective;
const Image = types.Image;
const TextureInfo = types.TextureInfo;
const MaterialNormalTextureInfo = types.MaterialNormalTextureInfo;
const MaterialOcclusionTextureInfo = types.MaterialOcclusionTextureInfo;
const MaterialPbrMetallicRoughness = types.MaterialPbrMetallicRoughness;
const Material = types.Material;
const AlphaMode = types.AlphaMode;
const Mesh = types.Mesh;
const MeshPrimitive = types.MeshPrimitive;
const Attributes = types.Attributes;
const Node = types.Node;
const Sampler = types.Sampler;
const Scene = types.Scene;
const Skin = types.Skin;
const Texture = types.Texture;

const JsonValue = std.json.Value;

fn getReq(obj: anytype, key: []const u8) !JsonValue {
    const v = obj.get(key) orelse return E.ParseError.MissingField;
    if (v == .null) return E.ParseError.NullField;
    return v;
}

fn getOpt(obj: anytype, key: []const u8) ?JsonValue {
    return jutils.getOpt(obj, key);
}

fn optString(obj: anytype, key: []const u8) ?[]const u8 {
    const v = getOpt(obj, key) orelse return null;
    return v.string;
}

fn optF64(obj: anytype, key: []const u8) ?f64 {
    return jutils.optF64(obj, key);
}

fn optU32(obj: anytype, key: []const u8) ?u32 {
    return jutils.optU32(obj, key);
}

fn optU64(obj: anytype, key: []const u8) ?u64 {
    return jutils.optU64(obj, key);
}

fn optBool(obj: anytype, key: []const u8) ?bool {
    return jutils.optBool(obj, key);
}

fn getF64(val: JsonValue) !f64 {
    return switch (val) {
        .float => |f| f,
        .integer => |ival| @floatFromInt(ival),
        else => E.ParseError.InvalidType,
    };
}

fn getU32(val: JsonValue) !u32 {
    if (val == .integer) {
        const i = val.integer;
        if (i < 0) return E.ParseError.NegativeValue;
        return @intCast(i);
    }
    return E.ParseError.InvalidType;
}

fn getU64(val: JsonValue) !u64 {
    if (val == .integer) {
        const i = val.integer;
        if (i < 0) return E.ParseError.NegativeValue;
        return @intCast(i);
    }
    return E.ParseError.InvalidType;
}

fn optF64Array(allocator: std.mem.Allocator, obj: anytype, key: []const u8) !?[]f64 {
    const v = getOpt(obj, key) orelse return null;
    const items = v.array.items;
    const result = try allocator.alloc(f64, items.len);
    for (items, 0..) |item, idx| {
        result[idx] = try getF64(item);
    }
    return result;
}

fn optU32Array(allocator: std.mem.Allocator, obj: anytype, key: []const u8) !?[]u32 {
    const v = getOpt(obj, key) orelse return null;
    const items = v.array.items;
    const result = try allocator.alloc(u32, items.len);
    for (items, 0..) |item, idx| {
        result[idx] = try getU32(item);
    }
    return result;
}

fn optStringArray(allocator: std.mem.Allocator, obj: anytype, key: []const u8) !?[][]const u8 {
    const v = getOpt(obj, key) orelse return null;
    const items = v.array.items;
    const result = try allocator.alloc([]const u8, items.len);
    for (items, 0..) |item, idx| {
        result[idx] = item.string;
    }
    return result;
}

fn optF64Fixed(comptime N: usize, obj: anytype, key: []const u8) ?[N]f64 {
    return jutils.optF64Fixed(N, obj, key);
}

fn optExtras(obj: anytype, key: []const u8) ?JsonValue {
    return getOpt(obj, key);
}

fn parseArray(allocator: std.mem.Allocator, comptime T: type, val: JsonValue, comptime parseFn: anytype) ![]T {
    const items = val.array.items;
    const result = try allocator.alloc(T, items.len);
    for (items, 0..) |item, idx| {
        result[idx] = try parseFn(allocator, item);
    }
    return result;
}

fn parseAsset(allocator: std.mem.Allocator, val: JsonValue) !Asset {
    _ = allocator;
    const obj = val.object;
    return Asset{
        .version = (try getReq(obj, "version")).string,
        .copyright = optString(obj, "copyright"),
        .generator = optString(obj, "generator"),
        .min_version = optString(obj, "minVersion"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAccessorSparseIndices(allocator: std.mem.Allocator, val: JsonValue) !AccessorSparseIndices {
    _ = allocator;
    const obj = val.object;
    return AccessorSparseIndices{
        .buffer_view = try getU32(try getReq(obj, "bufferView")),
        .byte_offset = optU64(obj, "byteOffset") orelse 0,
        .component_type = @enumFromInt(try getU32(try getReq(obj, "componentType"))),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAccessorSparseValues(allocator: std.mem.Allocator, val: JsonValue) !AccessorSparseValues {
    _ = allocator;
    const obj = val.object;
    return AccessorSparseValues{
        .buffer_view = try getU32(try getReq(obj, "bufferView")),
        .byte_offset = optU64(obj, "byteOffset") orelse 0,
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAccessorSparse(allocator: std.mem.Allocator, val: JsonValue) !AccessorSparse {
    const obj = val.object;
    return AccessorSparse{
        .count = try getU64(try getReq(obj, "count")),
        .indices = try parseAccessorSparseIndices(allocator, try getReq(obj, "indices")),
        .values = try parseAccessorSparseValues(allocator, try getReq(obj, "values")),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAccessor(allocator: std.mem.Allocator, val: JsonValue) !Accessor {
    const obj = val.object;
    return Accessor{
        .buffer_view = optU32(obj, "bufferView"),
        .byte_offset = optU64(obj, "byteOffset") orelse 0,
        .component_type = @enumFromInt(try getU32(try getReq(obj, "componentType"))),
        .count = try getU64(try getReq(obj, "count")),
        .max = try optF64Array(allocator, obj, "max"),
        .min = try optF64Array(allocator, obj, "min"),
        .normalized = optBool(obj, "normalized") orelse false,
        .sparse = if (getOpt(obj, "sparse")) |v| try parseAccessorSparse(allocator, v) else null,
        .type = std.meta.stringToEnum(AccessorType, (try getReq(obj, "type")).string).?,
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAnimationChannelTarget(allocator: std.mem.Allocator, val: JsonValue) !AnimationChannelTarget {
    _ = allocator;
    const obj = val.object;
    return AnimationChannelTarget{
        .node = optU32(obj, "node"),
        .path = (try getReq(obj, "path")).string,
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAnimationChannel(allocator: std.mem.Allocator, val: JsonValue) !AnimationChannel {
    const obj = val.object;
    return AnimationChannel{
        .sampler = try getU32(try getReq(obj, "sampler")),
        .target = try parseAnimationChannelTarget(allocator, try getReq(obj, "target")),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAnimationSampler(allocator: std.mem.Allocator, val: JsonValue) !AnimationSampler {
    _ = allocator;
    const obj = val.object;
    return AnimationSampler{
        .input = try getU32(try getReq(obj, "input")),
        .interpolation = optString(obj, "interpolation") orelse "LINEAR",
        .output = try getU32(try getReq(obj, "output")),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAnimation(allocator: std.mem.Allocator, val: JsonValue) !Animation {
    const obj = val.object;

    const channels_val = try getReq(obj, "channels");
    const channels = try parseArray(allocator, AnimationChannel, channels_val, parseAnimationChannel);

    const samplers_val = try getReq(obj, "samplers");
    const samplers = try parseArray(allocator, AnimationSampler, samplers_val, parseAnimationSampler);

    return Animation{
        .channels = channels,
        .samplers = samplers,
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseBuffer(allocator: std.mem.Allocator, val: JsonValue) !Buffer {
    _ = allocator;
    const obj = val.object;
    return Buffer{
        .uri = optString(obj, "uri"),
        .byte_length = try getU64(try getReq(obj, "byteLength")),
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseBufferView(allocator: std.mem.Allocator, val: JsonValue) !BufferView {
    _ = allocator;
    const obj = val.object;
    return BufferView{
        .buffer = try getU32(try getReq(obj, "buffer")),
        .byte_offset = optU64(obj, "byteOffset") orelse 0,
        .byte_length = try getU64(try getReq(obj, "byteLength")),
        .byte_stride = optU64(obj, "byteStride"),
        .target = if (optU32(obj, "target")) |t| @enumFromInt(t) else null,
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseCameraOrthographic(allocator: std.mem.Allocator, val: JsonValue) !CameraOrthographic {
    _ = allocator;
    const obj = val.object;
    return CameraOrthographic{
        .xmag = try getF64(try getReq(obj, "xmag")),
        .ymag = try getF64(try getReq(obj, "ymag")),
        .zfar = try getF64(try getReq(obj, "zfar")),
        .znear = try getF64(try getReq(obj, "znear")),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseCameraPerspective(allocator: std.mem.Allocator, val: JsonValue) !CameraPerspective {
    _ = allocator;
    const obj = val.object;
    return CameraPerspective{
        .aspect_ratio = optF64(obj, "aspectRatio"),
        .yfov = try getF64(try getReq(obj, "yfov")),
        .zfar = optF64(obj, "zfar"),
        .znear = try getF64(try getReq(obj, "znear")),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseCamera(allocator: std.mem.Allocator, val: JsonValue) !Camera {
    const obj = val.object;
    return Camera{
        .orthographic = if (getOpt(obj, "orthographic")) |v| try parseCameraOrthographic(allocator, v) else null,
        .perspective = if (getOpt(obj, "perspective")) |v| try parseCameraPerspective(allocator, v) else null,
        .type = (try getReq(obj, "type")).string,
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseImage(allocator: std.mem.Allocator, val: JsonValue) !Image {
    _ = allocator;
    const obj = val.object;
    return Image{
        .uri = optString(obj, "uri"),
        .mime_type = optString(obj, "mimeType"),
        .buffer_view = optU32(obj, "bufferView"),
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseTextureInfo(allocator: std.mem.Allocator, val: JsonValue) !TextureInfo {
    _ = allocator;
    const obj = val.object;
    return TextureInfo{
        .index = try getU32(try getReq(obj, "index")),
        .tex_coord = optU32(obj, "texCoord") orelse 0,
        .extras = optExtras(obj, "extras"),
        .extensions = optExtras(obj, "extensions"),
    };
}

fn parseMaterialNormalTextureInfo(allocator: std.mem.Allocator, val: JsonValue) !MaterialNormalTextureInfo {
    _ = allocator;
    const obj = val.object;
    return MaterialNormalTextureInfo{
        .index = try getU32(try getReq(obj, "index")),
        .tex_coord = optU32(obj, "texCoord") orelse 0,
        .scale = optF64(obj, "scale") orelse 1.0,
        .extras = optExtras(obj, "extras"),
    };
}

fn parseMaterialOcclusionTextureInfo(allocator: std.mem.Allocator, val: JsonValue) !MaterialOcclusionTextureInfo {
    _ = allocator;
    const obj = val.object;
    return MaterialOcclusionTextureInfo{
        .index = try getU32(try getReq(obj, "index")),
        .tex_coord = optU32(obj, "texCoord") orelse 0,
        .strength = optF64(obj, "strength") orelse 1.0,
        .extras = optExtras(obj, "extras"),
    };
}

fn parseMaterialPbrMetallicRoughness(allocator: std.mem.Allocator, val: JsonValue) !MaterialPbrMetallicRoughness {
    const obj = val.object;
    return MaterialPbrMetallicRoughness{
        .base_color_factor = optF64Fixed(4, obj, "baseColorFactor") orelse .{ 1.0, 1.0, 1.0, 1.0 },
        .base_color_texture = if (getOpt(obj, "baseColorTexture")) |v| try parseTextureInfo(allocator, v) else null,
        .metallic_factor = optF64(obj, "metallicFactor") orelse 1.0,
        .roughness_factor = optF64(obj, "roughnessFactor") orelse 1.0,
        .metallic_roughness_texture = if (getOpt(obj, "metallicRoughnessTexture")) |v| try parseTextureInfo(allocator, v) else null,
        .extras = optExtras(obj, "extras"),
    };
}

fn parseMaterial(allocator: std.mem.Allocator, val: JsonValue) !Material {
    const obj = val.object;
    const alpha_mode_str = optString(obj, "alphaMode") orelse "OPAQUE";
    return Material{
        .alpha_cutoff = optF64(obj, "alphaCutoff") orelse 0.5,
        .alpha_mode = std.meta.stringToEnum(AlphaMode, alpha_mode_str) orelse .OPAQUE,
        .double_sided = optBool(obj, "doubleSided") orelse false,
        .emissive_factor = optF64Fixed(3, obj, "emissiveFactor") orelse .{ 0.0, 0.0, 0.0 },
        .emissive_texture = if (getOpt(obj, "emissiveTexture")) |v| try parseTextureInfo(allocator, v) else null,
        .name = optString(obj, "name"),
        .normal_texture = if (getOpt(obj, "normalTexture")) |v| try parseMaterialNormalTextureInfo(allocator, v) else null,
        .occlusion_texture = if (getOpt(obj, "occlusionTexture")) |v| try parseMaterialOcclusionTextureInfo(allocator, v) else null,
        .pbr_metallic_roughness = if (getOpt(obj, "pbrMetallicRoughness")) |v| try parseMaterialPbrMetallicRoughness(allocator, v) else null,
        .extras = optExtras(obj, "extras"),
    };
}

fn parseAttributes(allocator: std.mem.Allocator, val: JsonValue) !Attributes {
    var map = Attributes.init(allocator);
    const obj = val.object;
    var it = obj.iterator();
    while (it.next()) |entry| {
        try map.put(entry.key_ptr.*, @intCast(entry.value_ptr.*.integer));
    }
    return map;
}

fn parseMeshPrimitive(allocator: std.mem.Allocator, val: JsonValue) !MeshPrimitive {
    const obj = val.object;

    const attrs_val = try getReq(obj, "attributes");
    const attrs = try parseAttributes(allocator, attrs_val);

    const targets = if (getOpt(obj, "targets")) |v| blk: {
        const arr = try allocator.alloc(Attributes, v.array.items.len);
        for (v.array.items, 0..) |item, idx| {
            arr[idx] = try parseAttributes(allocator, item);
        }
        break :blk arr;
    } else null;

    return MeshPrimitive{
        .attributes = attrs,
        .indices = optU32(obj, "indices"),
        .material = optU32(obj, "material"),
        .mode = optU32(obj, "mode") orelse 4,
        .targets = targets,
        .extras = optExtras(obj, "extras"),
    };
}

fn parseMesh(allocator: std.mem.Allocator, val: JsonValue) !Mesh {
    const obj = val.object;

    const prims_val = try getReq(obj, "primitives");
    const primitives = try parseArray(allocator, MeshPrimitive, prims_val, parseMeshPrimitive);

    return Mesh{
        .primitives = primitives,
        .weights = try optF64Array(allocator, obj, "weights"),
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseNode(allocator: std.mem.Allocator, val: JsonValue) !Node {
    const obj = val.object;
    return Node{
        .camera = optU32(obj, "camera"),
        .children = try optU32Array(allocator, obj, "children"),
        .matrix = optF64Fixed(16, obj, "matrix"),
        .mesh = optU32(obj, "mesh"),
        .rotation = optF64Fixed(4, obj, "rotation"),
        .scale = optF64Fixed(3, obj, "scale"),
        .translation = optF64Fixed(3, obj, "translation"),
        .skin = optU32(obj, "skin"),
        .weights = try optF64Array(allocator, obj, "weights"),
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseSampler(allocator: std.mem.Allocator, val: JsonValue) !Sampler {
    _ = allocator;
    const obj = val.object;
    return Sampler{
        .mag_filter = if (optU32(obj, "magFilter")) |v| @enumFromInt(v) else null,
        .min_filter = if (optU32(obj, "minFilter")) |v| @enumFromInt(v) else null,
        .wrap_s = if (optU32(obj, "wrapS")) |v| @enumFromInt(v) else .repeat,
        .wrap_t = if (optU32(obj, "wrapT")) |v| @enumFromInt(v) else .repeat,
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseScene(allocator: std.mem.Allocator, val: JsonValue) !Scene {
    const obj = val.object;
    return Scene{
        .nodes = try optU32Array(allocator, obj, "nodes"),
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseSkin(allocator: std.mem.Allocator, val: JsonValue) !Skin {
    const obj = val.object;

    const joints_val = try getReq(obj, "joints");
    const joints_arr = joints_val.array.items;
    const joints = try allocator.alloc(u32, joints_arr.len);
    for (joints_arr, 0..) |item, idx| {
        joints[idx] = try getU32(item);
    }

    return Skin{
        .inverse_bind_matrices = optU32(obj, "inverseBindMatrices"),
        .skeleton = optU32(obj, "skeleton"),
        .joints = joints,
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseTexture(allocator: std.mem.Allocator, val: JsonValue) !Texture {
    _ = allocator;
    const obj = val.object;
    return Texture{
        .sampler = optU32(obj, "sampler"),
        .source = optU32(obj, "source"),
        .name = optString(obj, "name"),
        .extras = optExtras(obj, "extras"),
    };
}

fn parseGlbHeader(source: []const u8) !u32 {
    const endian = .little;

    if (source.len < 12) return E.ParseError.InvalidGlb;
    if (std.mem.readInt(u32, source[0..4], endian) != 0x46546C67) return E.ParseError.InvalidGlbMagic;
    if (std.mem.readInt(u32, source[4..8], endian) != 2) return E.ParseError.UnsupportedGlbVersion;

    const length = std.mem.readInt(u32, source[8..12], endian);
    if (source.len < length) return E.ParseError.TruncatedGlb;
    return length;
}

pub fn parseGlb(allocator: std.mem.Allocator, source: []const u8) !Gltf {
    const endian = .little;
    const length = try parseGlbHeader(source);

    var offset: usize = 12;
    var json_data: ?[]const u8 = null;
    var bin_data: ?[]const u8 = null;

    while (offset < length) {
        if (offset + 8 > length) return E.ParseError.TruncatedGlbChunk;
        const chunk_len = std.mem.readInt(u32, source[offset..][0..4], endian);
        const chunk_type = std.mem.readInt(u32, source[offset + 4 ..][0..4], endian);
        offset += 8;

        if (offset + chunk_len > length) return E.ParseError.TruncatedGlbChunk;
        const chunk_data = source[offset..][0..chunk_len];
        offset += chunk_len;

        offset += (4 - (chunk_len % 4)) % 4;

        switch (chunk_type) {
            0x4E4F534A => {
                if (json_data != null) return E.ParseError.MultipleJsonChunks;
                json_data = chunk_data;
            },
            0x004E4942 => {
                if (bin_data != null) return E.ParseError.MultipleBinChunks;
                bin_data = chunk_data;
            },
            else => {},
        }
    }

    const json = json_data orelse return E.ParseError.MissingJsonChunk;

    var result = try parse(allocator, json);

    if (bin_data) |bin| {
        result.bin = try result.arena.allocator().dupe(u8, bin);
    }

    return result;
}

pub fn parse(allocator: std.mem.Allocator, source: []const u8) !Gltf {
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();
    const al = arena.allocator();

    const parsed = try std.json.parseFromSlice(std.json.Value, al, source, .{});
    const root = parsed.value;
    const obj = root.object;

    return Gltf{
        .arena = arena,
        .asset = try parseAsset(al, try getReq(obj, "asset")),
        .accessors = if (getOpt(obj, "accessors")) |v| try parseArray(al, Accessor, v, parseAccessor) else null,
        .animations = if (getOpt(obj, "animations")) |v| try parseArray(al, Animation, v, parseAnimation) else null,
        .buffers = if (getOpt(obj, "buffers")) |v| try parseArray(al, Buffer, v, parseBuffer) else null,
        .buffer_views = if (getOpt(obj, "bufferViews")) |v| try parseArray(al, BufferView, v, parseBufferView) else null,
        .cameras = if (getOpt(obj, "cameras")) |v| try parseArray(al, Camera, v, parseCamera) else null,
        .extensions = optExtras(obj, "extensions"),
        .extensions_required = try optStringArray(al, obj, "extensionsRequired"),
        .extensions_used = try optStringArray(al, obj, "extensionsUsed"),
        .extras = optExtras(obj, "extras"),
        .images = if (getOpt(obj, "images")) |v| try parseArray(al, Image, v, parseImage) else null,
        .materials = if (getOpt(obj, "materials")) |v| try parseArray(al, Material, v, parseMaterial) else null,
        .meshes = if (getOpt(obj, "meshes")) |v| try parseArray(al, Mesh, v, parseMesh) else null,
        .nodes = if (getOpt(obj, "nodes")) |v| try parseArray(al, Node, v, parseNode) else null,
        .samplers = if (getOpt(obj, "samplers")) |v| try parseArray(al, Sampler, v, parseSampler) else null,
        .scene = optU32(obj, "scene"),
        .scenes = if (getOpt(obj, "scenes")) |v| try parseArray(al, Scene, v, parseScene) else null,
        .skins = if (getOpt(obj, "skins")) |v| try parseArray(al, Skin, v, parseSkin) else null,
        .textures = if (getOpt(obj, "textures")) |v| try parseArray(al, Texture, v, parseTexture) else null,
    };
}

test "parse minimal glTF" {
    const src = "{\"asset\":{\"version\":\"2.0\"}}";
    var gltf = try parse(std.testing.allocator, src);
    defer gltf.deinit();
    try std.testing.expectEqualStrings("2.0", gltf.asset.version);
    try std.testing.expect(gltf.bin == null);
}

test "parse fails on missing asset" {
    try std.testing.expectError(E.ParseError.MissingField, parse(std.testing.allocator, "{}"));
}

test "parse fails on null asset" {
    try std.testing.expectError(E.ParseError.NullField, parse(std.testing.allocator, "{\"asset\":null}"));
}

test "parse full glTF with all component types" {
    const src =
        \\{
        \\  "asset": { "version": "2.0", "generator": "gen", "copyright": "(c)", "minVersion": "2.0" },
        \\  "accessors": [{ "bufferView": 0, "byteOffset": 0, "componentType": 5126, "count": 3, "type": "VEC3", "max": [1.0], "min": [0.0] }],
        \\  "animations": [{ "channels": [{ "sampler": 0, "target": { "node": 0, "path": "translation" } }], "samplers": [{ "input": 0, "output": 1 }] }],
        \\  "buffers": [{ "uri": "data.bin", "byteLength": 100 }],
        \\  "bufferViews": [{ "buffer": 0, "byteLength": 100 }],
        \\  "cameras": [{ "type": "orthographic", "orthographic": { "xmag": 1.0, "ymag": 1.0, "zfar": 10.0, "znear": 0.1 } }],
        \\  "images": [{ "uri": "tex.png", "mimeType": "image/png" }],
        \\  "materials": [{ "pbrMetallicRoughness": {}, "alphaMode": "BLEND", "doubleSided": true }],
        \\  "meshes": [{ "primitives": [{ "attributes": { "POSITION": 0 } }] }],
        \\  "nodes": [{ "mesh": 0, "children": [1, 2] }],
        \\  "samplers": [{ "magFilter": 9729, "minFilter": 9987, "wrapS": 33071, "wrapT": 33648 }],
        \\  "scenes": [{ "nodes": [0] }],
        \\  "scene": 0,
        \\  "skins": [{ "joints": [0, 1, 2, 3] }],
        \\  "textures": [{ "sampler": 0, "source": 0 }],
        \\  "extensionsUsed": ["ext1"],
        \\  "extensionsRequired": ["ext2"]
        \\}
    ;
    var gltf = try parse(std.testing.allocator, src);
    defer gltf.deinit();
    try std.testing.expect(gltf.accessors.?.len == 1);
    try std.testing.expect(gltf.accessors.?[0].component_type == .float);
    try std.testing.expect(gltf.animations.?.len == 1);
    try std.testing.expect(gltf.buffers.?.len == 1);
    try std.testing.expect(gltf.buffers.?[0].byte_length == 100);
    try std.testing.expect(gltf.buffer_views.?.len == 1);
    try std.testing.expect(gltf.cameras.?.len == 1);
    try std.testing.expect(gltf.images.?.len == 1);
    try std.testing.expect(gltf.materials.?.len == 1);
    try std.testing.expect(gltf.meshes.?.len == 1);
    try std.testing.expect(gltf.nodes.?.len == 1);
    try std.testing.expect(gltf.samplers.?.len == 1);
    try std.testing.expect(gltf.scenes.?.len == 1);
    try std.testing.expect(gltf.scene.? == 0);
    try std.testing.expect(gltf.skins.?.len == 1);
    try std.testing.expect(gltf.textures.?.len == 1);
    try std.testing.expect(gltf.extensions_used.?.len == 1);
    try std.testing.expect(gltf.extensions_required.?.len == 1);
    try std.testing.expectEqualStrings("2.0", gltf.asset.min_version.?);
    try std.testing.expectEqualStrings("gen", gltf.asset.generator.?);
    try std.testing.expectEqualStrings("(c)", gltf.asset.copyright.?);
}

test "parse no optional fields returns null slices" {
    const src = "{\"asset\":{\"version\":\"2.0\"}}";
    var gltf = try parse(std.testing.allocator, src);
    defer gltf.deinit();
    try std.testing.expect(gltf.accessors == null);
    try std.testing.expect(gltf.animations == null);
    try std.testing.expect(gltf.buffers == null);
    try std.testing.expect(gltf.buffer_views == null);
    try std.testing.expect(gltf.cameras == null);
    try std.testing.expect(gltf.images == null);
    try std.testing.expect(gltf.materials == null);
    try std.testing.expect(gltf.meshes == null);
    try std.testing.expect(gltf.nodes == null);
    try std.testing.expect(gltf.samplers == null);
    try std.testing.expect(gltf.scenes == null);
    try std.testing.expect(gltf.skins == null);
    try std.testing.expect(gltf.textures == null);
    try std.testing.expect(gltf.scene == null);
    try std.testing.expect(gltf.extensions_used == null);
    try std.testing.expect(gltf.extensions_required == null);
}

test "parseGlb minimal valid JSON only" {
    const json = "{\"asset\":{\"version\":\"2.0\"}}";
    const jlen: u32 = @intCast(json.len);
    const pad: u32 = (4 - (jlen % 4)) % 4;
    const total: u32 = 12 + 8 + jlen + pad;
    var buf: [128]u8 = undefined;
    var pos: usize = 0;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x46546C67, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 2, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], total, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen + pad;
    var gltf = try parseGlb(std.testing.allocator, buf[0..pos]);
    defer gltf.deinit();
    try std.testing.expectEqualStrings("2.0", gltf.asset.version);
    try std.testing.expect(gltf.bin == null);
}

test "parseGlb with BIN chunk" {
    const json = "{\"asset\":{\"version\":\"2.0\"}}";
    const bin_data = "\x00\x01\x02\x03";
    const jlen: u32 = @intCast(json.len);
    const blen: u32 = @intCast(bin_data.len);
    const jpad: u32 = (4 - (jlen % 4)) % 4;
    const bpad: u32 = (4 - (blen % 4)) % 4;
    const total: u32 = 12 + 8 + jlen + jpad + 8 + blen + bpad;
    var buf: [256]u8 = undefined;
    var pos: usize = 0;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x46546C67, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 2, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], total, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen + jpad;
    std.mem.writeInt(u32, buf[pos..][0..4], blen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x004E4942, .little);
    pos += 4;
    @memcpy(buf[pos..][0..bin_data.len], bin_data);
    pos += blen + bpad;
    var gltf = try parseGlb(std.testing.allocator, buf[0..pos]);
    defer gltf.deinit();
    try std.testing.expect(gltf.bin != null);
    try std.testing.expectEqualSlices(u8, bin_data, gltf.bin.?);
}

test "parseGlb with chunk padding" {
    const json = "{\"asset\":{\"version\":\"2.0\"}}";
    const jlen: u32 = @intCast(json.len);
    const pad: u32 = (4 - (jlen % 4)) % 4;
    const total: u32 = 12 + 8 + jlen + pad;
    var buf: [128]u8 = undefined;
    var pos: usize = 0;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x46546C67, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 2, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], total, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen;
    var i: usize = 0;
    while (i < pad) : (i += 1) {
        buf[pos + i] = 0xFF;
    }
    pos += pad;
    var gltf = try parseGlb(std.testing.allocator, buf[0..pos]);
    defer gltf.deinit();
    try std.testing.expectEqualStrings("2.0", gltf.asset.version);
}

test "parseGlb invalid magic" {
    const json = "{}";
    const jlen: u32 = @intCast(json.len);
    const pad: u32 = (4 - (jlen % 4)) % 4;
    const total: u32 = 12 + 8 + jlen + pad;
    var buf: [128]u8 = undefined;
    var pos: usize = 0;
    std.mem.writeInt(u32, buf[pos..][0..4], 0, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 2, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], total, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen + pad;
    try std.testing.expectError(E.ParseError.InvalidGlbMagic, parseGlb(std.testing.allocator, buf[0..pos]));
}

test "parseGlb unsupported version" {
    const json = "{}";
    const jlen: u32 = @intCast(json.len);
    const pad: u32 = (4 - (jlen % 4)) % 4;
    const total: u32 = 12 + 8 + jlen + pad;
    var buf: [128]u8 = undefined;
    var pos: usize = 0;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x46546C67, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 1, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], total, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen + pad;
    try std.testing.expectError(E.ParseError.UnsupportedGlbVersion, parseGlb(std.testing.allocator, buf[0..pos]));
}

test "parseGlb missing JSON chunk" {
    var buf: [12]u8 = undefined;
    std.mem.writeInt(u32, buf[0..4], 0x46546C67, .little);
    std.mem.writeInt(u32, buf[4..8], 2, .little);
    std.mem.writeInt(u32, buf[8..12], 12, .little);
    try std.testing.expectError(E.ParseError.MissingJsonChunk, parseGlb(std.testing.allocator, &buf));
}

test "parseGlb truncated header" {
    try std.testing.expectError(E.ParseError.InvalidGlb, parseGlb(std.testing.allocator, &[_]u8{0} ** 4));
}

test "parseGlb truncated chunk" {
    const json = "{}";
    const jlen: u32 = @intCast(json.len);
    const pad: u32 = (4 - (jlen % 4)) % 4;
    var buf: [128]u8 = undefined;
    var pos: usize = 0;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x46546C67, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 2, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 1000, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen + pad;
    try std.testing.expectError(E.ParseError.TruncatedGlb, parseGlb(std.testing.allocator, buf[0..pos]));
}

test "parseGlb multiple JSON chunks" {
    const json = "{}";
    const jlen: u32 = @intCast(json.len);
    const pad: u32 = (4 - (jlen % 4)) % 4;
    const chunk_total: u32 = 8 + jlen + pad;
    const total: u32 = 12 + 2 * chunk_total;
    var buf: [256]u8 = undefined;
    var pos: usize = 0;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x46546C67, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 2, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], total, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen + pad;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen + pad;
    try std.testing.expectError(E.ParseError.MultipleJsonChunks, parseGlb(std.testing.allocator, buf[0..pos]));
}

test "parseGlb multiple BIN chunks" {
    const json = "{\"asset\":{\"version\":\"2.0\"}}";
    const jlen: u32 = @intCast(json.len);
    const jpad: u32 = (4 - (jlen % 4)) % 4;
    const blen: u32 = 4;
    const bpad: u32 = 0;
    const total: u32 = 12 + 8 + jlen + jpad + 8 + blen + bpad + 8 + blen + bpad;
    var buf: [512]u8 = undefined;
    var pos: usize = 0;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x46546C67, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 2, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], total, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], jlen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x4E4F534A, .little);
    pos += 4;
    @memcpy(buf[pos..][0..json.len], json);
    pos += jlen + jpad;
    std.mem.writeInt(u32, buf[pos..][0..4], blen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x004E4942, .little);
    pos += 4;
    pos += blen + bpad;
    std.mem.writeInt(u32, buf[pos..][0..4], blen, .little);
    pos += 4;
    std.mem.writeInt(u32, buf[pos..][0..4], 0x004E4942, .little);
    pos += 4;
    pos += blen + bpad;
    try std.testing.expectError(E.ParseError.MultipleBinChunks, parseGlb(std.testing.allocator, buf[0..pos]));
}
