const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day04.txt");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const part1_pattern1 = 'X' << 24 | 'M' << 16 | 'A' << 8 | 'S';
    const part1_pattern2 = 'S' << 24 | 'A' << 16 | 'M' << 8 | 'X';

    const part2_pattern1 = 'M' << 16 | 'A' << 8 | 'S';
    const part2_pattern2 = 'S' << 16 | 'A' << 8 | 'M';

    var grid = List([]const u8).init(gpa);
    defer grid.deinit();

    var it = tokenizeAny(u8, data, "\r\n");
    while (it.next()) |line| {
        try grid.append(line);
    }

    var xmas_count1: usize = 0;
    var xmas_count2: usize = 0;

    const image = try grid.toOwnedSlice();
    defer gpa.free(image);

    const m = image.len;
    const n = image[0].len;

    var marked_image = try gpa.alloc([]u32, m);
    defer {
        for (marked_image) |mrow| {
            gpa.free(mrow);
        }
        gpa.free(marked_image);
    }

    for (marked_image) |*mrow| {
        mrow.* = try gpa.alloc(u32, n);
        @memset(mrow.*, 0);
    }

    {
        var i: usize = 0;
        while (i < m) : (i += 1) {
            var j: usize = 0;
            var key: u32 = 0;
            while (j < n and j < 3) : (j += 1) {
                key = key << 8 | image[i][j];
            }
            while (j < n) : (j += 1) {
                key = key << 8 | image[i][j];
                if (key == part1_pattern1 or key == part1_pattern2) {
                    xmas_count1 += 1;
                }
            }
        }
    }

    {
        var j: usize = 0;
        while (j < n) : (j += 1) {
            var i: usize = 0;
            var key: u32 = 0;
            while (i < m and i < 3) : (i += 1) {
                key = key << 8 | image[i][j];
            }
            while (i < m) : (i += 1) {
                key = key << 8 | image[i][j];
                if (key == part1_pattern1 or key == part1_pattern2) {
                    xmas_count1 += 1;
                }
            }
        }
    }

    {
        var k: usize = 0;
        while (k < m + n - 1) : (k += 1) {
            var i: usize = if (k < m) k else m - 1;
            var j: usize = if (k < m) 0 else k - m + 1;
            const nsteps: usize = if (k < @min(m, n)) k + 1 else k + 1 - (2 * k - (n - 1 + m - 1));
            var v: usize = 0;
            var key1: u32 = 0;
            var key2: u24 = 0;
            while (v < nsteps and v < 3) : ({
                i -|= 1;
                j += 1;
                v += 1;
            }) {
                key1 = key1 << 8 | image[i][j];
                key2 = key2 << 8 | image[i][j];
            }
            if (key2 == part2_pattern1 or key2 == part2_pattern2) {
                marked_image[i + 2][j - 2] += 1;
            }
            while (v < nsteps) : ({
                i -|= 1;
                j += 1;
                v += 1;
            }) {
                key1 = key1 << 8 | image[i][j];
                key2 = key2 << 8 | image[i][j];
                if (key1 == part1_pattern1 or key1 == part1_pattern2) {
                    xmas_count1 += 1;
                }
                if (key2 == part2_pattern1 or key2 == part2_pattern2) {
                    marked_image[i + 1][j - 1] += 1;
                }
            }
        }
    }

    {
        var k: usize = 0;
        while (k < m + n - 1) : (k += 1) {
            var i: usize = if (k < m) k else m - 1;
            var j: usize = if (k < m) n - 1 else n - 1 - (k - m + 1);
            const nsteps: usize = if (k < @min(m, n)) k + 1 else k + 1 - (2 * k - (n - 1 + m - 1));
            var v: usize = 0;
            var key1: u32 = 0;
            var key2: u24 = 0;
            while (v < nsteps and v < 3) : ({
                i -|= 1;
                j -|= 1;
                v += 1;
            }) {
                key1 = key1 << 8 | image[i][j];
                key2 = key2 << 8 | image[i][j];
            }
            if (key2 == part2_pattern1 or key2 == part2_pattern2) {
                marked_image[i + 2][j + 2] += 1;
            }
            while (v < nsteps) : ({
                i -|= 1;
                j -|= 1;
                v += 1;
            }) {
                key1 = key1 << 8 | image[i][j];
                key2 = key2 << 8 | image[i][j];
                if (key1 == part1_pattern1 or key1 == part1_pattern2) {
                    xmas_count1 += 1;
                }
                if (key2 == part2_pattern1 or key2 == part2_pattern2) {
                    marked_image[i + 1][j + 1] += 1;
                }
            }
        }
    }

    for (marked_image) |mrow| {
        for (mrow) |val| {
            if (val == 2) {
                xmas_count2 += 1;
            }
        }
    }

    try stdout.print("Part 1: {d}\n", .{xmas_count1});
    try stdout.print("Part 2: {d}\n", .{xmas_count2});
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
