const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day07.txt");

const stdout = std.io.getStdOut().writer();

const Operations = enum { add, mul, concat };

pub fn main() !void {
    var part1_ans: u64 = 0;
    var part2_ans: u64 = 0;

    const pow10 = blk: {
        var result = [_]u64{1} ** 20;
        for (1..20) |i| {
            result[i] = result[i - 1] * 10;
        }
        break :blk result;
    };

    var stack1 = List(Pair(u64, usize)).init(gpa);
    defer stack1.deinit();

    var stack2 = List(Pair(u64, usize)).init(gpa);
    defer stack2.deinit();

    var it = tokenizeAny(u8, data, "\r\n");
    while (it.next()) |line| {
        const colon_idx = indexOfSca(u8, line, ':').?;
        const test_value = try parseUnsigned(u64, line[0..colon_idx], 10);

        var operands = List(u64).init(gpa);
        defer operands.deinit();

        var pow10_opds = List(u64).init(gpa);
        defer pow10_opds.deinit();

        var operand_it = tokenizeSca(u8, line[colon_idx + 1 ..], ' ');
        while (operand_it.next()) |opd| {
            const operand = try parseUnsigned(u64, opd, 10);
            try pow10_opds.append(pow10[opd.len]);
            try operands.append(operand);
        }

        assert(operands.items.len >= 2);

        var part1_sat: bool = false;

        try stack1.append(.{ operands.items[0], 1 });
        defer stack1.clearRetainingCapacity();

        while (stack1.items.len > 0) {
            const v, const idx = stack1.pop();

            if (idx == operands.items.len) {
                if (v == test_value) {
                    part1_sat = true;
                    break;
                }
            } else {
                if (v + operands.items[idx] <= test_value) try stack1.append(.{ v + operands.items[idx], idx + 1 });
                if (v * operands.items[idx] <= test_value) try stack1.append(.{ v * operands.items[idx], idx + 1 });
            }
        }

        if (part1_sat) {
            part1_ans += test_value;
            part2_ans += test_value;
            continue;
        }

        try stack2.append(.{ operands.items[0], 1 });
        defer stack2.clearRetainingCapacity();

        while (stack2.items.len > 0) {
            const v, const idx = stack2.pop();

            if (idx == operands.items.len) {
                if (v == test_value) {
                    part2_ans += test_value;
                    break;
                }
            } else {
                if (v + operands.items[idx] <= test_value) try stack2.append(.{ v + operands.items[idx], idx + 1 });
                if (v * operands.items[idx] <= test_value) try stack2.append(.{ v * operands.items[idx], idx + 1 });

                if (v * pow10_opds.items[idx] + operands.items[idx] <= test_value) try stack2.append(.{ v * pow10_opds.items[idx] + operands.items[idx], idx + 1 });
            }
        }
    }

    try stdout.print("Part 1: {d}\n", .{part1_ans});
    try stdout.print("Part 2: {d}\n", .{part2_ans});
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOfSca = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOf;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

const Pair = util.Pair;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
