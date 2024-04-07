const std = @import("std");
const Allocator = std.mem.Allocator;

/// A mutable UTF-8 string with convenients method to manipulate it.
pub const MutableString = struct {
    /// Allocator owning the buffer.
    allocator: Allocator,
    /// Buffer containing the string.
    /// The size of the buffer may be greater than the size of the actual string to avoid allocating memory
    /// every time the string is mutated.
    buffer: []u8,
    /// Actual length of the string contained in the buffer.
    len: usize,

    pub const Options = struct {
        /// Initial capacity of the mutable string.
        capacity: usize = 0,
    };

    /// Initialize a mutable string
    pub fn init(allocator: Allocator, options: Options) !MutableString {
        return MutableString{
            .allocator = allocator,
            .buffer = try allocator.alloc(u8, options.capacity),
            .len = 0,
        };
    }

    pub fn deinit(self: MutableString) void {
        self.allocator.free(self.buffer);
    }

    /// Return a slice containing the string.
    pub fn slice(self: *MutableString) []const u8 {
        var s: []u8 = "";
        s.ptr = self.buffer.ptr;
        s.len = self.len;
        return s;
    }

    /// Ensure the internal buffer has the capacity to contains a string of the provided size.
    /// If the actual buffer is too small, a new buffer will be allocated.
    /// The new buffer will either have the provided size or twice the capacity of the previous buffer depending
    /// on the biggest.
    fn growCapacityUpTo(self: *MutableString, size: usize) !void {
        if (size <= self.buffer.len) {
            return;
        }
        const new_capacity = @max(size, @mulWithOverflow(self.buffer.len, 2)[0]);
        const old_buffer = self.buffer;
        const new_buffer = try self.allocator.alloc(u8, new_capacity);
        std.mem.copy(u8, new_buffer, old_buffer);
        self.buffer = new_buffer;
        self.allocator.free(old_buffer);
    }

    /// Reduce the size of the buffer to exactly the size of the content.
    pub fn trimToSize(self: *MutableString) !void {
        const new_buffer = try self.allocator.alloc(u8, self.len);
        const old_buffer = self.buffer;
        const trimmed_source = self.buffer[0..self.len];
        std.mem.copy(u8, new_buffer, trimmed_source);
        self.buffer = new_buffer;
        self.allocator.free(old_buffer);
    }

    /// Copy the value to the buffer at index.
    pub fn set(self: *MutableString, index: usize, value: []const u8) !void {
        const required_capacity = @addWithOverflow(index, value.len);
        if (required_capacity[1] == 1) {
            return error.Overflow;
        }
        try self.growCapacityUpTo(required_capacity[0]);
        // Fill the void between previous len and index with zeroes.
        if (index > self.len) {
            for (self.len..index) |i| {
                self.buffer[i] = std.mem.zeroes(u8);
            }
        }
        const dest = self.buffer[index..self.buffer.len];
        std.mem.copy(u8, dest, value);
        self.len = @max(self.len, required_capacity[0]);
    }

    pub fn append(self: *MutableString, value: []const u8) !void {
        try self.set(self.len, value);
    }
};

const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualStrings = std.testing.expectEqualStrings;

test "growUpToCapacity - Do nothing if buffer is big enough" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{ .capacity = 10 });
    defer mutable_string.deinit();
    try mutable_string.growCapacityUpTo(10);
    try expect(mutable_string.buffer.len == 10);
}

test "growUpToCapacity - Double buffer size" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{ .capacity = 10 });
    defer mutable_string.deinit();
    try mutable_string.growCapacityUpTo(11);
    try expect(mutable_string.buffer.len == 20);
}

test "growUpToCapacity - Grow up to capacity" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{ .capacity = 10 });
    defer mutable_string.deinit();
    try mutable_string.growCapacityUpTo(50);
    try expect(mutable_string.buffer.len == 50);
}

test "set - Overflow when index is too big" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{});
    defer mutable_string.deinit();
    const result = mutable_string.set(std.math.maxInt(usize), "Hello");
    try expectError(error.Overflow, result);
}

test "set - Set with content len > buffer len" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{});
    defer mutable_string.deinit();
    try mutable_string.set(0, "Hello");
    try std.testing.expect(mutable_string.len == 5);
    try expectEqualStrings("Hello", mutable_string.slice());
}

test "set - Set with content len <= buffer len" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{ .capacity = 10 });
    defer mutable_string.deinit();
    try mutable_string.set(0, "Hello");
    try std.testing.expect(mutable_string.len == 5);
    try expectEqualStrings("Hello", mutable_string.slice());
}

test "set - Set with index > len generates 0 and index + content len > buffer len" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{});
    defer mutable_string.deinit();
    try mutable_string.set(2, "Hello");

    const expected = [_]u8{ 0, 0, 'H', 'e', 'l', 'l', 'o' };
    try expectEqualSlices(u8, &expected, mutable_string.slice());
}

test "set - Set with index > len generates 0 and index + content len < buffer len)" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{ .capacity = 10 });
    defer mutable_string.deinit();
    try mutable_string.set(2, "Hello");

    const expected = [_]u8{ 0, 0, 'H', 'e', 'l', 'l', 'o' };
    try expectEqualSlices(u8, &expected, mutable_string.slice());
}

test "append - Append text to the end" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{});
    defer mutable_string.deinit();
    try mutable_string.set(0, "Hello");
    try mutable_string.append(" World");
    try expectEqualStrings("Hello World", mutable_string.slice());
}
