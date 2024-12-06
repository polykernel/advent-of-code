const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const IntegerBitSet = std.bit_set.IntegerBitSet;
const Str = []const u8;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_impl.allocator();

// Add utility functions here
pub fn Pair(T1: type, T2: type) type {
    return std.meta.Tuple(&.{ T1, T2 });
}

pub fn findLastSet(comptime StaticBitSetType: type, bit_set: StaticBitSetType) ?usize {
    const is_array_bit_set = comptime startsWith(u8, @typeName(StaticBitSetType), "bit_set.ArrayBitSet");
    const is_int_bit_set = comptime startsWith(u8, @typeName(StaticBitSetType), "bit_set.IntegerBitSet");
    if (is_int_bit_set) {
        const mask = bit_set.mask;
        if (mask == 0) return null;
        return StaticBitSetType.bit_length - 1 - @clz(mask);
    } else if (is_array_bit_set) {
        var offset: usize = 0;
        const bit_size = @bitSizeOf(StaticBitSetType.MaskInt);
        const mask = blk: {
            var i = bit_set.masks.len;
            while (i > 0) : (i -= 1) {
                const m = bit_set.masks[i - 1];
                if (m != 0) break :blk m;
                offset += bit_size;
            } else return null;
        };
        const idx = offset + @clz(mask);
        return StaticBitSetType.bit_length - 1 - idx;
    } else {
        @compileError("Unimplemented");
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
const startsWith = std.mem.startsWith;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;
