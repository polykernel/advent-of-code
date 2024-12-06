const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const State = enum {
        eol,
        value,
        post_value,

        literal_m,
        literal_mu,

        literal_d,
        literal_do,
        @"literal_do(",
        enable_mul,

        literal_don,
        @"literal_don'",
        @"literal_don't",
        @"literal_don't(",
        disable_mul,

        param_begin,
        param_end,

        number_one,
        number_one_1,
        number_one_2,
        comma,
        number_two,
        number_two_1,
        number_two_2,
    };

    var part1_ans: u64 = 0;
    var part2_ans: u64 = 0;

    var mul_enabled = true;

    var it = tokenizeAny(u8, data, "\r\n");
    while (it.next()) |line| {
        var cursor: usize = 0;
        var curr_state: State = .value;

        var number_one: u32 = undefined;
        var number_two: u32 = undefined;

        state_machine: while (true) {
            // print("{}\n", .{curr_state});
            switch (curr_state) {
                .eol => break :state_machine,
                .value => {
                    if (cursor < line.len) {
                        switch (line[cursor]) {
                            'm' => {
                                curr_state = .literal_m;
                            },
                            'd' => {
                                curr_state = .literal_d;
                            },
                            else => {},
                        }
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .literal_m => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == 'u') .literal_mu else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .literal_mu => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == 'l') .param_begin else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .literal_d => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == 'o') .literal_do else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .literal_do => {
                    if (cursor < line.len) {
                        switch (line[cursor]) {
                            '(' => {
                                curr_state = .@"literal_do(";
                            },
                            'n' => {
                                curr_state = .literal_don;
                            },
                            else => {},
                        }
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .@"literal_do(" => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == ')') .enable_mul else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .literal_don => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == '\'') .@"literal_don'" else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .@"literal_don'" => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == 't') .@"literal_don't" else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .@"literal_don't" => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == '(') .@"literal_don't(" else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .@"literal_don't(" => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == ')') .disable_mul else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .enable_mul => {
                    mul_enabled = true;
                    curr_state = .value;
                    continue :state_machine;
                },
                .disable_mul => {
                    mul_enabled = false;
                    curr_state = .value;
                    continue :state_machine;
                },
                .param_begin => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == '(') .number_one else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .number_one => {
                    if (cursor < line.len) {
                        switch (line[cursor]) {
                            '0' => {
                                curr_state = .comma;
                                number_one = 0;
                            },
                            '1'...'9' => {
                                curr_state = .number_one_1;
                                number_one = line[cursor] - '0';
                            },
                            else => {
                                curr_state = .value;
                            },
                        }
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .comma => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == ',') .number_two else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .number_one_1 => {
                    if (cursor < line.len) {
                        switch (line[cursor]) {
                            '0'...'9' => {
                                curr_state = .number_one_2;
                                number_one = 10 * number_one + (line[cursor] - '0');
                            },
                            ',' => {
                                curr_state = .number_two;
                            },
                            else => {
                                curr_state = .value;
                            },
                        }
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .number_one_2 => {
                    if (cursor < line.len) {
                        switch (line[cursor]) {
                            '0'...'9' => {
                                curr_state = .comma;
                                number_one = 10 * number_one + (line[cursor] - '0');
                            },
                            ',' => {
                                curr_state = .number_two;
                            },
                            else => {
                                curr_state = .value;
                            },
                        }
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .number_two => {
                    if (cursor < line.len) {
                        switch (line[cursor]) {
                            '0' => {
                                curr_state = .param_end;
                                number_two = 0;
                            },
                            '1'...'9' => {
                                curr_state = .number_two_1;
                                number_two = line[cursor] - '0';
                            },
                            else => {
                                curr_state = .value;
                            },
                        }
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .number_two_1 => {
                    if (cursor < line.len) {
                        switch (line[cursor]) {
                            '0'...'9' => {
                                curr_state = .number_two_2;
                                number_two = 10 * number_two + (line[cursor] - '0');
                            },
                            ')' => {
                                curr_state = .post_value;
                            },
                            else => {
                                curr_state = .value;
                            },
                        }
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .number_two_2 => {
                    if (cursor < line.len) {
                        switch (line[cursor]) {
                            '0'...'9' => {
                                curr_state = .param_end;
                                number_two = 10 * number_two + (line[cursor] - '0');
                            },
                            ')' => {
                                curr_state = .post_value;
                            },
                            else => {
                                curr_state = .value;
                            },
                        }
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .param_end => {
                    if (cursor < line.len) {
                        curr_state = if (line[cursor] == ')') .post_value else .value;
                        cursor += 1;
                    } else {
                        curr_state = .eol;
                    }
                    continue :state_machine;
                },
                .post_value => {
                    const result = number_one * number_two;
                    part1_ans += result;
                    if (mul_enabled) part2_ans += result;
                    curr_state = .value;
                    // print("Enabled: {}\n", .{mul_enabled});
                    // print("{d} x {d} = {d}\n", .{ number_one, number_two, result });
                    continue :state_machine;
                },
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
