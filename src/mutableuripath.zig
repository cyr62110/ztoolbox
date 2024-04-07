const std = @import("std");
const Allocator = std.mem.Allocator;

const ztoolbox = @import("./root.zig");
const MutableString = ztoolbox.string.MutableString;

/// A mutable Uri path with convenients method to manipulate the path.
pub const MutableUriPath = struct {
    const separator = "/";
    const PathSegmentArrayList = std.ArrayList([]u8);

    /// Allocator owning the memory of all components of the path.
    allocator: Allocator,
    /// Whether the path is absolute according to RFC3986.
    absolute: bool,
    /// Array list containing the sequence of segments constituing the path.
    /// Segments contained in this list are already escaped according to RFC3986.
    path_segments: PathSegmentArrayList,

    pub fn init(allocator: Allocator, absolute: bool) !MutableUriPath {
        return MutableUriPath{ .allocator = allocator, .absolute = absolute, .path_segments = PathSegmentArrayList.init(allocator) };
    }

    pub fn deinit(self: MutableUriPath) void {
        for (self.path_segments.items) |item| {
            self.allocator.free(item);
        }
        self.path_segments.deinit();
    }

    /// Append a slice as the last fragment of the path.
    /// Applies URI encoding and replaces all reserved characters with their respective %XX code.
    pub fn appendSlice(self: *MutableUriPath, segment: []const u8) !void {
        const encoded_segment = try std.Uri.escapeString(self.allocator, segment);
        try self.path_segments.append(encoded_segment);
    }

    /// Append the path to the provided mutable string.
    pub fn appendToMutableString(self: MutableUriPath, string: *ztoolbox.string.MutableString) !void {
        var i: usize = 0;
        while (i < self.path_segments.items.len) {
            if (self.absolute or i > 0) {
                try string.append(MutableUriPath.separator);
            }
            try string.append(self.path_segments.items[i]);
            i += 1;
        }
    }

    /// Return a slice containing the path.
    /// The memory is owned by the provided allocator.
    pub fn toOwnedSlice(self: MutableUriPath, allocator: Allocator) ![]const u8 {
        const size = self.sliceLen();
        if (size[1] == 1) {
            return error.Overflow;
        }

        var string = try ztoolbox.string.MutableString.init(allocator, .{ .capacity = size[0] });
        errdefer string.deinit();
        try self.appendToMutableString(string);
        return string.slice();
    }

    /// Compute the size of the slice required to contain all the segments of the path and all the separator.
    fn sliceLen(self: MutableUriPath) struct { usize, u1 } {
        var i: usize = 0;
        var size: struct { usize, u1 } = .{ 0, 0 };
        while (i < self.path_segments.items.len and size[1] == 0) {
            if (self.absolute or i > 0) {
                // Separator between segment.
                size = @addWithOverflow(size[0], 1);
            }
            size = @addWithOverflow(size[0], self.path_segments.items[i].len);
            i += 1;
        }
        return size;
    }
};

const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

test "appendSlice - Escape slice & append to fragments" {
    var path = try MutableUriPath.init(std.testing.allocator, true);
    defer path.deinit();
    try path.appendSlice("My slice");
    try expectEqualStrings("My%20slice", path.path_segments.getLast());
}

test "appendToMutableString - Absolute path" {
    var path = try MutableUriPath.init(std.testing.allocator, true);
    defer path.deinit();
    try path.appendSlice("Hello");
    try path.appendSlice("World");

    var string = try MutableString.init(std.testing.allocator, .{});
    defer string.deinit();

    try expectEqualStrings("/Hello/World", string.slice());
}

test "appendToMutableString - Relative path" {
    var path = try MutableUriPath.init(std.testing.allocator, false);
    defer path.deinit();
    try path.appendSlice("Hello");
    try path.appendSlice("World");

    var string = try MutableString.init(std.testing.allocator, .{});
    defer string.deinit();

    try expectEqualStrings("Hello/World", string.slice());
}

test "sliceLen - Absolute path" {
    var path = try MutableUriPath.init(std.testing.allocator, true);
    defer path.deinit();
    try path.appendSlice("Hello");
    try path.appendSlice("World");
    try expect(path.sliceLen()[0] == 12);
}

test "sliceLen - Relative path" {
    var path = try MutableUriPath.init(std.testing.allocator, false);
    defer path.deinit();
    try path.appendSlice("Hello");
    try path.appendSlice("World");
    try expect(path.sliceLen()[0] == 11);
}
