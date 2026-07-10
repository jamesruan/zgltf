const std = @import("std");
const zgltf = @import("zgltf");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena;
    const allocator = arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(allocator);

    if (args.len < 2) {
        var buf: [256]u8 = undefined;
        var w: std.Io.File.Writer = .init(.stderr(), init.io, &buf);
        try w.interface.writeAll("Usage: zgltf <file.gltf>\n");
        try w.interface.flush();
        std.process.exit(1);
    }

    const file_path = args[1];
    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(io, file_path, .{ .mode = .read_only });
    defer file.close(io);

    const stat = try file.stat(io);
    var mmap = try file.createMemoryMap(io, .{ .len = stat.size });
    defer mmap.destroy(io);

    const source = mmap.memory;
    var gltf = try zgltf.parse(allocator, source);
    defer gltf.deinit();

    var buf: [4096]u8 = undefined;
    var w: std.Io.File.Writer = .init(.stdout(), io, &buf);
    const out = &w.interface;

    try out.print("glTF version: {s}\n", .{gltf.asset.version});
    if (gltf.asset.generator) |g| try out.print("generator: {s}\n", .{g});
    if (gltf.asset.copyright) |c| try out.print("copyright: {s}\n", .{c});
    try out.print("---\n", .{});

    if (gltf.scenes) |x| try out.print("scenes: {d}\n", .{x.len});
    if (gltf.nodes) |x| try out.print("nodes: {d}\n", .{x.len});
    if (gltf.meshes) |x| try out.print("meshes: {d}\n", .{x.len});
    if (gltf.accessors) |x| try out.print("accessors: {d}\n", .{x.len});
    if (gltf.buffer_views) |x| try out.print("bufferViews: {d}\n", .{x.len});
    if (gltf.buffers) |x| try out.print("buffers: {d}\n", .{x.len});
    if (gltf.materials) |x| try out.print("materials: {d}\n", .{x.len});
    if (gltf.textures) |x| try out.print("textures: {d}\n", .{x.len});
    if (gltf.images) |x| try out.print("images: {d}\n", .{x.len});
    if (gltf.samplers) |x| try out.print("samplers: {d}\n", .{x.len});
    if (gltf.animations) |x| try out.print("animations: {d}\n", .{x.len});
    if (gltf.skins) |x| try out.print("skins: {d}\n", .{x.len});
    if (gltf.cameras) |x| try out.print("cameras: {d}\n", .{x.len});
    if (gltf.scene) |scene_idx| try out.print("default scene: {d}\n", .{scene_idx});

    try out.flush();
}
