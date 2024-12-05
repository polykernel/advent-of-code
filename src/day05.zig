const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const RingBuffer = std.RingBuffer;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day05.txt");

pub fn main() !void {
    const max_page = 256;
    const inf = 0x3f3f3f3f;

    var part1_ans: u64 = 0;
    var part2_ans: u64 = 0;

    var dag: [max_page]List(u8) = .{List(u8).init(gpa)} ** max_page;
    defer {
        for (dag) |adj_list| {
            adj_list.deinit();
        }
    }

    var it = splitAny(u8, data, "\r\n");
    while (it.next()) |line| {
        // we reached the end of the rules section
        if (line.len == 0) break;

        var line_it = tokenizeSca(u8, line, '|');
        const page1 = try parseUnsigned(u8, line_it.next().?, 10);
        const page2 = try parseUnsigned(u8, line_it.next().?, 10);

        try dag[page1].append(page2);
    }

    // read queries
    while (it.next()) |query| {
        // we reached the end of the query section
        if (query.len == 0) break;

        var query_it = tokenizeSca(u8, query, ',');

        var page_list = List(u8).init(gpa);
        defer page_list.deinit();

        var index: [max_page]usize = .{inf} ** max_page;

        {
            var i: usize = 0;
            while (query_it.next()) |page_str| {
                const page = try parseUnsigned(u8, page_str, 10);
                try page_list.append(page);
                index[page] = i;
                i += 1;
            }
        }

        {
            const n = page_list.items.len;
            assert(n % 2 == 1);

            outer: for (page_list.items) |u| {
                for (dag[u].items) |v| {
                    if (index[v] < index[u]) break :outer;
                }
            } else {
                const middle_entry = page_list.items[n / 2];
                part1_ans += middle_entry;
                continue;
            }

            var new_page_list = try gpa.dupe(u8, page_list.items);
            defer gpa.free(new_page_list);

            // fix incorrect ordering
            var count = n;
            while (count > 0) : (count -= 1) {
                const u = page_list.items[count - 1];
                var min_idx = index[u];

                for (dag[u].items) |v| {
                    if (index[v] < min_idx) min_idx = index[v];
                }

                if (min_idx < index[u]) {
                    var j: usize = index[u];
                    while (j > min_idx) : (j -= 1) {
                        index[new_page_list[j - 1]] += 1;
                        new_page_list[j] = new_page_list[j - 1];
                    }
                    index[u] = min_idx;
                    new_page_list[min_idx] = u;
                }
            }

            // check topological ordering
            for (new_page_list, 0..) |u, k| {
                assert(index[u] == k);
                for (dag[u].items) |v| {
                    assert(index[v] > index[u]);
                }
            }

            const middle_entry = new_page_list[n / 2];
            part2_ans += middle_entry;
        }
    }

    print("Part 1: {d}\n", .{part1_ans});
    print("Part 2: {d}\n", .{part2_ans});
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
const parseUnsigned = std.fmt.parseUnsigned;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
