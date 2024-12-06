const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day02.txt");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var safe_count_1: usize = 0;
    var safe_count_2: usize = 0;

    var it = tokenizeAny(u8, data, "\r\n");
    while (it.next()) |line| {
        var line_it = tokenizeAny(u8, line, " ");
        var report = List(i32).init(gpa);
        defer report.deinit();

        while (line_it.next()) |tok| {
            const level = try parseInt(i32, tok, 10);
            try report.append(level);
        }

        // if (checkLevels(report.items)) {
        //     safe_count_1 += 1;
        //     safe_count_2 += 1;
        // } else {
        //     for (0..report.items.len) |i| {
        //         const new_report = try concat(gpa, i32, &[_][]const i32{ report.items[0..i], report.items[i + 1 ..] });
        //         defer gpa.free(new_report);

        //         if (checkLevels(new_report)) {
        //             safe_count_2 += 1;
        //             break;
        //         }
        //     }
        // }

        if (report.items.len < 2) {
            safe_count_1 += 1;
            safe_count_2 += 1;
            continue;
        }

        const is_asc = report.items[1] > report.items[0];

        var idx: usize = 0;
        while (idx < report.items.len - 1) : (idx += 1) {
            const diff = if (is_asc) report.items[idx + 1] - report.items[idx] else report.items[idx] - report.items[idx + 1];

            if (diff < 1 or diff > 3) break;
        } else {
            safe_count_1 += 1;
            safe_count_2 += 1;
            continue;
        }

        if (checkLevels(report.items[1..])) {
            safe_count_2 += 1;
            continue;
        }

        if (idx > 0) {
            const is_asc_new = if (idx > 1) is_asc else report.items[2] > report.items[0];
            const diff1 = if (is_asc_new) report.items[idx + 1] - report.items[idx - 1] else report.items[idx - 1] - report.items[idx + 1];
            if (diff1 >= 1 and diff1 <= 3) {
                var i = idx + 1;
                while (i < report.items.len - 1) : (i += 1) {
                    const diff = if (is_asc_new) report.items[i + 1] - report.items[i] else report.items[i] - report.items[i + 1];

                    if (diff < 1 or diff > 3) break;
                } else {
                    safe_count_2 += 1;
                    continue;
                }
            }
        } else {
            const is_asc_new = report.items[2] > report.items[1];
            var i = idx + 1;
            while (i < report.items.len - 1) : (i += 1) {
                const diff = if (is_asc_new) report.items[i + 1] - report.items[i] else report.items[i] - report.items[i + 1];

                if (diff < 1 or diff > 3) break;
            } else {
                safe_count_2 += 1;
                continue;
            }
        }

        if (idx < report.items.len - 2) {
            const is_asc_new = if (idx > 0) is_asc else report.items[2] > report.items[0];
            const diff1 = if (is_asc_new) report.items[idx + 2] - report.items[idx] else report.items[idx] - report.items[idx + 2];
            if (diff1 >= 1 and diff1 <= 3) {
                var i = idx + 2;
                while (i < report.items.len - 1) : (i += 1) {
                    const diff = if (is_asc_new) report.items[i + 1] - report.items[i] else report.items[i] - report.items[i + 1];

                    if (diff < 1 or diff > 3) break;
                } else {
                    safe_count_2 += 1;
                    continue;
                }
            }
        } else {
            safe_count_2 += 1;
            continue;
        }
    }

    try stdout.print("Part 1: {d}\n", .{safe_count_1});
    try stdout.print("Part 2: {d}\n", .{safe_count_2});
}

fn checkLevels(levels: []const i32) bool {
    if (levels.len < 2) return true;

    const is_asc = levels[1] > levels[0];
    return for (0..levels.len - 1) |i| {
        const diff = if (is_asc) levels[i + 1] - levels[i] else levels[i] - levels[i + 1];
        if (diff < 1 or diff > 3) break false;
    } else true;
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
const concat = std.mem.concat;

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
