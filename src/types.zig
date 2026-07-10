const std = @import("std");
const extensions = @import("extensions.zig");

pub const Extras = std.json.Value;

pub const Asset = struct {
    version: []const u8,
    copyright: ?[]const u8 = null,
    generator: ?[]const u8 = null,
    min_version: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const AccessorType = enum {
    SCALAR,
    VEC2,
    VEC3,
    VEC4,
    MAT2,
    MAT3,
    MAT4,
};

pub const ComponentType = enum(u32) {
    byte = 5120,
    unsigned_byte = 5121,
    short = 5122,
    unsigned_short = 5123,
    unsigned_int = 5125,
    float = 5126,
};

pub const AccessorSparseIndices = struct {
    buffer_view: u32,
    byte_offset: u64 = 0,
    component_type: ComponentType,
    extras: ?Extras = null,
};

pub const AccessorSparseValues = struct {
    buffer_view: u32,
    byte_offset: u64 = 0,
    extras: ?Extras = null,
};

pub const AccessorSparse = struct {
    count: u64,
    indices: AccessorSparseIndices,
    values: AccessorSparseValues,
    extras: ?Extras = null,
};

pub const Accessor = struct {
    buffer_view: ?u32 = null,
    byte_offset: u64 = 0,
    component_type: ComponentType,
    count: u64,
    max: ?[]f64 = null,
    min: ?[]f64 = null,
    normalized: bool = false,
    sparse: ?AccessorSparse = null,
    type: AccessorType,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const AnimationChannelTarget = struct {
    node: ?u32 = null,
    path: []const u8,
    extras: ?Extras = null,
};

pub const AnimationChannel = struct {
    sampler: u32,
    target: AnimationChannelTarget,
    extras: ?Extras = null,
};

pub const AnimationSampler = struct {
    input: u32,
    interpolation: []const u8 = "LINEAR",
    output: u32,
    extras: ?Extras = null,
};

pub const Animation = struct {
    channels: []AnimationChannel,
    samplers: []AnimationSampler,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const Buffer = struct {
    uri: ?[]const u8 = null,
    byte_length: u64,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const BufferViewTarget = enum(u32) {
    array_buffer = 34962,
    element_array_buffer = 34963,
};

pub const BufferView = struct {
    buffer: u32,
    byte_offset: u64 = 0,
    byte_length: u64,
    byte_stride: ?u64 = null,
    target: ?BufferViewTarget = null,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const CameraOrthographic = struct {
    xmag: f64,
    ymag: f64,
    zfar: f64,
    znear: f64,
    extras: ?Extras = null,
};

pub const CameraPerspective = struct {
    aspect_ratio: ?f64 = null,
    yfov: f64,
    zfar: ?f64 = null,
    znear: f64,
    extras: ?Extras = null,
};

pub const Camera = struct {
    orthographic: ?CameraOrthographic = null,
    perspective: ?CameraPerspective = null,
    type: []const u8,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const Image = struct {
    uri: ?[]const u8 = null,
    mime_type: ?[]const u8 = null,
    buffer_view: ?u32 = null,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const TextureInfo = struct {
    index: u32,
    tex_coord: u32 = 0,
    texture_transform: ?extensions.TextureTransform = null,
    extras: ?Extras = null,
};

pub const MaterialNormalTextureInfo = struct {
    index: u32,
    tex_coord: u32 = 0,
    scale: f64 = 1.0,
    texture_transform: ?extensions.TextureTransform = null,
    extras: ?Extras = null,
};

pub const MaterialOcclusionTextureInfo = struct {
    index: u32,
    tex_coord: u32 = 0,
    strength: f64 = 1.0,
    texture_transform: ?extensions.TextureTransform = null,
    extras: ?Extras = null,
};

pub const MaterialPbrMetallicRoughness = struct {
    base_color_factor: [4]f64 = .{ 1.0, 1.0, 1.0, 1.0 },
    base_color_texture: ?TextureInfo = null,
    metallic_factor: f64 = 1.0,
    roughness_factor: f64 = 1.0,
    metallic_roughness_texture: ?TextureInfo = null,
    extras: ?Extras = null,
};

pub const AlphaMode = enum {
    OPAQUE,
    MASK,
    BLEND,
};

pub const Material = struct {
    alpha_cutoff: f64 = 0.5,
    alpha_mode: AlphaMode = .OPAQUE,
    double_sided: bool = false,
    emissive_factor: [3]f64 = .{ 0.0, 0.0, 0.0 },
    emissive_texture: ?TextureInfo = null,
    name: ?[]const u8 = null,
    normal_texture: ?MaterialNormalTextureInfo = null,
    occlusion_texture: ?MaterialOcclusionTextureInfo = null,
    pbr_metallic_roughness: ?MaterialPbrMetallicRoughness = null,
    extras: ?Extras = null,
};

pub const MeshPrimitive = struct {
    attributes: Attributes,
    indices: ?u32 = null,
    material: ?u32 = null,
    mode: u32 = 4,
    targets: ?[]Attributes = null,
    extras: ?Extras = null,
};

pub const Attributes = std.StringHashMap(u32);

pub const Mesh = struct {
    primitives: []MeshPrimitive,
    weights: ?[]f64 = null,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const Node = struct {
    camera: ?u32 = null,
    children: ?[]u32 = null,
    matrix: ?[16]f64 = null,
    mesh: ?u32 = null,
    rotation: ?[4]f64 = null,
    scale: ?[3]f64 = null,
    translation: ?[3]f64 = null,
    skin: ?u32 = null,
    weights: ?[]f64 = null,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const SamplerMagFilter = enum(u32) {
    nearest = 9728,
    linear = 9729,
};

pub const SamplerMinFilter = enum(u32) {
    nearest = 9728,
    linear = 9729,
    nearest_mipmap_nearest = 9984,
    linear_mipmap_nearest = 9985,
    nearest_mipmap_linear = 9986,
    linear_mipmap_linear = 9987,
};

pub const SamplerWrap = enum(u32) {
    clamp_to_edge = 33071,
    mirrored_repeat = 33648,
    repeat = 10497,
};

pub const Sampler = struct {
    mag_filter: ?SamplerMagFilter = null,
    min_filter: ?SamplerMinFilter = null,
    wrap_s: SamplerWrap = .repeat,
    wrap_t: SamplerWrap = .repeat,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const Scene = struct {
    nodes: ?[]u32 = null,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const Skin = struct {
    inverse_bind_matrices: ?u32 = null,
    skeleton: ?u32 = null,
    joints: []u32,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const Texture = struct {
    sampler: ?u32 = null,
    source: ?u32 = null,
    name: ?[]const u8 = null,
    extras: ?Extras = null,
};

pub const Gltf = struct {
    arena: std.heap.ArenaAllocator,

    asset: Asset,
    accessors: ?[]Accessor = null,
    animations: ?[]Animation = null,
    buffers: ?[]Buffer = null,
    buffer_views: ?[]BufferView = null,
    cameras: ?[]Camera = null,
    extensions: ?Extras = null,
    extensions_required: ?[][]const u8 = null,
    extensions_used: ?[][]const u8 = null,
    images: ?[]Image = null,
    materials: ?[]Material = null,
    meshes: ?[]Mesh = null,
    nodes: ?[]Node = null,
    samplers: ?[]Sampler = null,
    scene: ?u32 = null,
    scenes: ?[]Scene = null,
    skins: ?[]Skin = null,
    textures: ?[]Texture = null,

    // only when paring GLB with binary chunk
    bin: ?[]u8 = null,

    pub fn deinit(self: *Gltf) void {
        self.arena.deinit();
    }
};
