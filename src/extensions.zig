const std = @import("std");
const JsonValue = std.json.Value;
const json = @import("json_utils.zig");

pub const TextureTransform = struct {
    offset: [2]f64 = .{ 0.0, 0.0 },
    rotation: f64 = 0.0,
    scale: [2]f64 = .{ 1.0, 1.0 },
    tex_coord: ?u32 = null,

    pub fn fromExtensions(extensions_val: ?JsonValue) ?TextureTransform {
        const exts = extensions_val orelse return null;
        if (exts != .object) return null;
        const khr = exts.object.get("KHR_texture_transform") orelse return null;
        return parseTextureTransform(khr);
    }
};

pub fn parseTextureTransform(val: JsonValue) TextureTransform {
    const obj = val.object;
    return TextureTransform{
        .offset = json.optF64Fixed(2, obj, "offset") orelse .{ 0.0, 0.0 },
        .rotation = json.optF64(obj, "rotation") orelse 0.0,
        .scale = json.optF64Fixed(2, obj, "scale") orelse .{ 1.0, 1.0 },
        .tex_coord = json.optU32(obj, "texCoord"),
    };
}

test "parse KHR_texture_transform" {
    const src =
        \\{
        \\  "offset": [0, 1],
        \\  "rotation": 1.57079632679,
        \\  "scale": [0.5, 0.5]
        \\}
    ;
    const parsed = try std.json.parseFromSlice(JsonValue, std.testing.allocator, src, .{});
    defer parsed.deinit();
    const tt = parseTextureTransform(parsed.value);
    try std.testing.expectEqual(@as(f64, 0.0), tt.offset[0]);
    try std.testing.expectEqual(@as(f64, 1.0), tt.offset[1]);
    try std.testing.expectEqual(@as(f64, 1.57079632679), tt.rotation);
    try std.testing.expectEqual(@as(f64, 0.5), tt.scale[0]);
    try std.testing.expectEqual(@as(f64, 0.5), tt.scale[1]);
    try std.testing.expect(tt.tex_coord == null);
}

test "parse KHR_texture_transform defaults" {
    const src = "{}";
    const parsed = try std.json.parseFromSlice(JsonValue, std.testing.allocator, src, .{});
    defer parsed.deinit();
    const tt = parseTextureTransform(parsed.value);
    try std.testing.expectEqual(@as(f64, 0.0), tt.offset[0]);
    try std.testing.expectEqual(@as(f64, 0.0), tt.offset[1]);
    try std.testing.expectEqual(@as(f64, 0.0), tt.rotation);
    try std.testing.expectEqual(@as(f64, 1.0), tt.scale[0]);
    try std.testing.expectEqual(@as(f64, 1.0), tt.scale[1]);
    try std.testing.expect(tt.tex_coord == null);
}

test "parse KHR_texture_transform with texCoord" {
    const src =
        \\{
        \\  "texCoord": 3
        \\}
    ;
    const parsed = try std.json.parseFromSlice(JsonValue, std.testing.allocator, src, .{});
    defer parsed.deinit();
    const tt = parseTextureTransform(parsed.value);
    try std.testing.expectEqual(@as(u32, 3), tt.tex_coord.?);
}
