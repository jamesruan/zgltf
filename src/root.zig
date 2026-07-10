pub const types = @import("types.zig");
pub const parser = @import("parser.zig");
pub const errors = @import("error.zig");
pub const extensions = @import("extensions.zig");

pub const Gltf = types.Gltf;
pub const parse = parser.parse;
pub const parseGlb = parser.parseGlb;

test {
    _ = types;
    _ = parser;
    _ = errors;
    _ = extensions;
}
