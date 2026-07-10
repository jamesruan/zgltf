const std = @import("std");
const JsonValue = std.json.Value;

pub fn getOpt(obj: anytype, key: []const u8) ?JsonValue {
    const v = obj.get(key) orelse return null;
    if (v == .null) return null;
    return v;
}

pub fn optF64(obj: anytype, key: []const u8) ?f64 {
    const v = getOpt(obj, key) orelse return null;
    return switch (v) {
        .float => |f| f,
        .integer => |ival| @floatFromInt(ival),
        else => return null,
    };
}

pub fn optU32(obj: anytype, key: []const u8) ?u32 {
    const v = getOpt(obj, key) orelse return null;
    if (v == .integer) {
        const i = v.integer;
        if (i >= 0 and i <= std.math.maxInt(u32)) return @intCast(i);
    }
    return null;
}

pub fn optU64(obj: anytype, key: []const u8) ?u64 {
    const v = getOpt(obj, key) orelse return null;
    if (v == .integer) {
        const i = v.integer;
        if (i >= 0) return @intCast(i);
    }
    return null;
}

pub fn optBool(obj: anytype, key: []const u8) ?bool {
    const v = getOpt(obj, key) orelse return null;
    if (v == .bool) return v.bool;
    return null;
}

pub fn optF64Fixed(comptime N: usize, obj: anytype, key: []const u8) ?[N]f64 {
    const v = getOpt(obj, key) orelse return null;
    const items = v.array.items;
    if (items.len != N) return null;
    var result: [N]f64 = undefined;
    for (items, 0..) |item, idx| {
        result[idx] = switch (item) {
            .float => |f| f,
            .integer => |ival| @floatFromInt(ival),
            else => return null,
        };
    }
    return result;
}
