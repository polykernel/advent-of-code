const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    var freq = Map(u32, u32).init(gpa);
    defer freq.deinit();

    var loc_ids_1 = List(u32).init(gpa);
    defer loc_ids_1.deinit();
    var loc_ids_2 = List(u32).init(gpa);
    defer loc_ids_2.deinit();

    var it = tokenizeAny(u8, data, "\r\n");
    while (it.next()) |line| {
        var line_it = tokenizeAny(u8, line, " ");
        const loc_id_1 = try parseInt(u32, line_it.next().?, 10);
        const loc_id_2 = try parseInt(u32, line_it.next().?, 10);
        try loc_ids_1.append(loc_id_1);
        try loc_ids_2.append(loc_id_2);

        const result = try freq.getOrPut(loc_id_2);
        if (!result.found_existing) result.value_ptr.* = 1 else result.value_ptr.* += 1;
    }

    sort(u32, loc_ids_1.items, {}, asc(u32));
    sort(u32, loc_ids_2.items, {}, asc(u32));

    const total_dist = blk: {
        var total: usize = 0;
        for (loc_ids_1.items, loc_ids_2.items) |a, b| {
            total += @abs(@as(i32, @intCast(a)) - @as(i32, @intCast(b)));
        }
        break :blk total;
    };

    print("Part 1: {d}\n", .{total_dist});

    const sim_score = blk: {
        var score: usize = 0;
        for (loc_ids_1.items) |a| {
            if (freq.contains(a)) score += a * freq.get(a).?;
        }
        break :blk score;
    };

    print("Part 2: {d}\n", .{sim_score});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
