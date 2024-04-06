const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Options = struct {
    /// Initial capacity of the mutable string.
    capacity: usize = 0
};

/// A mutable string with convenients method to manipulate it.
pub const MutableString = struct {
    /// Allocator owning the buffer.
    allocator: Allocator,
    /// Buffer containing the string.
    /// The size of the buffer may be greater than the size of the actual string to avoid allocating memory
    /// every time the string is mutated.
    buffer: []u8,
    /// Actual length of the string contained in the buffer.
    len: usize,

    /// Initialize a mutable string
    pub fn init(allocator: Allocator, options: Options) !MutableString {
        return MutableString {
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

    /// Set the content of the string to the provided value.
    pub fn set(self: *MutableString, value: []const u8) !void {
        if (value.len > self.buffer.len) {
            const new_buffer = try self.allocator.dupe(u8, value);
            self.allocator.free(self.buffer);
            self.buffer = new_buffer;
            self.len = new_buffer.len;
        } else {
            std.mem.copy(u8, self.buffer, value);
            self.len = value.len;
        }
    }

    /// Resize the internal buffer to the provided size.
    pub fn resize(self: *MutableString, size: usize) !void {
        const old_buffer = self.buffer;
        const new_buffer = try self.allocator.alloc(u8, size);
        std.mem.copy(u8, new_buffer, old_buffer);
        self.allocator.free(old_buffer);
        self.buffer = new_buffer;
    }

    pub fn append() !void {

    }
};

const expectEqualStrings = std.testing.expectEqualStrings;

test "set - Set with content len > buffer len" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{});
    defer mutable_string.deinit();
    try mutable_string.set("Hello");
    try expectEqualStrings("Hello", mutable_string.slice());
}

test "set - Set with content len <= buffer len" {
    var mutable_string = try MutableString.init(std.testing.allocator, .{ .capacity = 10 });
    defer mutable_string.deinit();
    try mutable_string.set("Hello");
    try expectEqualStrings("Hello", mutable_string.slice());
}
