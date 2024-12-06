const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const ArrayBitSet = std.bit_set.ArrayBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day06.txt");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const max_size = 256;

    var part1_ans: u64 = 0;
    var part2_ans: u64 = 0;

    var grid: [max_size][max_size]u8 = .{.{0} ** max_size} ** max_size;

    var visited: [max_size][max_size]bool = .{.{false} ** max_size} ** max_size;

    // should really use a RB tree and lower_bound but dimension of grid is
    // small enough we can get away with a bitset
    var row_obs: [max_size]ArrayBitSet(u64, max_size) = .{ArrayBitSet(u64, max_size).initEmpty()} ** max_size;
    var col_obs: [max_size]ArrayBitSet(u64, max_size) = .{ArrayBitSet(u64, max_size).initEmpty()} ** max_size;

    var obs_coords = List(Coord).init(gpa);
    defer obs_coords.deinit();

    var curr_pos: Coord = undefined;

    var i: usize = 0;
    var j: usize = undefined;
    var it = tokenizeAny(u8, data, "\r\n");
    while (it.next()) |line| : (i += 1) {
        j = 0;
        while (j < line.len) : (j += 1) {
            switch (line[j]) {
                '^' => {
                    curr_pos[0] = i + 1;
                    curr_pos[1] = j + 1;
                },
                '#' => {
                    row_obs[i + 1].set(j + 1);
                    col_obs[j + 1].set(i + 1);
                },
                else => {},
            }
        }

        @memcpy(grid[i + 1][1 .. j + 1], line);
    }

    var dir: Direction = .north;

    var vst_tp = Map(Tuple(&.{ usize, usize, Direction }), void).init(gpa);
    defer vst_tp.deinit();

    while (grid[curr_pos[0]][curr_pos[1]] != 0 and !vst_tp.contains(curr_pos ++ .{dir})) {
        if (!visited[curr_pos[0]][curr_pos[1]]) {
            visited[curr_pos[0]][curr_pos[1]] = true;
            part1_ans += 1;
        }

        const new_pos: Coord = switch (dir) {
            .east => .{ curr_pos[0], curr_pos[1] + 1 },
            .west => .{ curr_pos[0], curr_pos[1] - 1 },
            .south => .{ curr_pos[0] + 1, curr_pos[1] },
            .north => .{ curr_pos[0] - 1, curr_pos[1] },
        };

        switch (grid[new_pos[0]][new_pos[1]]) {
            '#' => {
                try vst_tp.put(curr_pos ++ .{dir}, {});
                dir = @enumFromInt((@as(u32, @intFromEnum(dir)) + 1) % 4);
            },
            '.' => {
                row_obs[new_pos[0]].set(new_pos[1]);
                col_obs[new_pos[1]].set(new_pos[0]);

                var next_pos: Coord = curr_pos;

                var sim_vst_tp = Map(Tuple(&.{ usize, usize, Direction }), void).init(gpa);
                defer sim_vst_tp.deinit();

                var sim_dir: Direction = dir;

                const is_cycle = blk: {
                    while (!sim_vst_tp.contains(next_pos ++ .{sim_dir})) {
                        try sim_vst_tp.put(next_pos ++ .{sim_dir}, {});
                        switch (sim_dir) {
                            .east => {
                                var temp_bs = row_obs[next_pos[0]];
                                temp_bs.setRangeValue(.{ .start = 0, .end = next_pos[1] }, false);
                                if (temp_bs.findFirstSet()) |next_idx| {
                                    next_pos[1] = next_idx - 1;
                                } else {
                                    break :blk false;
                                }
                            },
                            .south => {
                                var temp_bs = col_obs[next_pos[1]];
                                temp_bs.setRangeValue(.{ .start = 0, .end = next_pos[0] }, false);
                                if (temp_bs.findFirstSet()) |next_idx| {
                                    next_pos[0] = next_idx - 1;
                                } else {
                                    break :blk false;
                                }
                            },
                            .west => {
                                var temp_bs = row_obs[next_pos[0]];
                                temp_bs.setRangeValue(.{ .start = next_pos[1], .end = max_size }, false);
                                if (util.findLastSet(@TypeOf(temp_bs), temp_bs)) |prev_idx| {
                                    next_pos[1] = prev_idx + 1;
                                } else {
                                    break :blk false;
                                }
                            },
                            .north => {
                                var temp_bs = col_obs[next_pos[1]];
                                temp_bs.setRangeValue(.{ .start = next_pos[0], .end = max_size }, false);
                                if (util.findLastSet(@TypeOf(temp_bs), temp_bs)) |prev_idx| {
                                    next_pos[0] = prev_idx + 1;
                                } else {
                                    break :blk false;
                                }
                            },
                        }

                        sim_dir = @enumFromInt((@as(u32, @intFromEnum(sim_dir)) + 1) % 4);
                    } else {
                        break :blk true;
                    }
                };

                if (is_cycle) {
                    try obs_coords.append(new_pos);
                    part2_ans += 1;
                }

                // we have to mark the cell as checked so future attempts
                // skip this cell
                grid[new_pos[0]][new_pos[1]] = 'V';

                row_obs[new_pos[0]].unset(new_pos[1]);
                col_obs[new_pos[1]].unset(new_pos[0]);

                curr_pos = new_pos;
            },
            else => {
                curr_pos = new_pos;
            },
        }
    }

    try stdout.print("Part 1: {d}\n", .{part1_ans});
    try stdout.print("Part 2: {d}\n", .{part2_ans});
}

fn printTour(grid: [256][256]u8, m: usize, n: usize, start: Coord, start_dir: Direction) !void {
    var sim_grid = grid;

    var curr_pos = start;
    var dir = start_dir;

    const max_iter = m * n * 4;
    var iter_count: usize = 0;

    while (grid[curr_pos[0]][curr_pos[1]] != 0 and iter_count < max_iter) : (iter_count += 1) {
        sim_grid[curr_pos[0]][curr_pos[1]] = 'X';
        const new_pos: Coord = switch (dir) {
            .east => .{ curr_pos[0], curr_pos[1] + 1 },
            .west => .{ curr_pos[0], curr_pos[1] - 1 },
            .south => .{ curr_pos[0] + 1, curr_pos[1] },
            .north => .{ curr_pos[0] - 1, curr_pos[1] },
        };

        switch (grid[new_pos[0]][new_pos[1]]) {
            '#' => {
                dir = @enumFromInt((@as(u32, @intFromEnum(dir)) + 1) % 4);
            },
            else => {
                curr_pos = new_pos;
            },
        }
    }

    sim_grid[start[0]][start[1]] = '^';

    for (sim_grid[1 .. m + 1]) |row| {
        print("{s}\n", .{row[1 .. n + 1]});
    }
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
const Tuple = std.meta.Tuple;

const Pair = util.Pair;
const Coord = Pair(usize, usize);

const Direction = enum { north, east, south, west };

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
