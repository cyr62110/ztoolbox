//! Package containing utility functions to manipulate slice of UTF-8 characters.

const std = @import("std");

pub const MutableString = @import("./mutablestring.zig").MutableString;

/// Return true if the provided string is blank.
/// A blank string is empty or contains only space characters.
pub fn isBlank(string: []const u8) bool {
    for (string) |char| {
        if (char != ' ') {
            return false;
        }
    }
    return true;
}

/// Return the provided string if its content is not blank or null otherwise.
/// A blank string is empty or contains only space characters.
pub fn nullIfBlank(string: ?[]const u8) ?[]const u8 {
    if (string) |non_null_string| {
        if (!isBlank(non_null_string)) {
            return non_null_string;
        }
    }
    return null;
}

test "isBlank" {
    try std.testing.expect(isBlank("") == true);
    try std.testing.expect(isBlank("      ") == true);
    try std.testing.expect(isBlank("test") == false);
    try std.testing.expect(isBlank("   test    ") == false);
}

test "nullIfBlank" {
    try std.testing.expect(nullIfBlank(null) == null);
    try std.testing.expect(nullIfBlank("") == null);
    try std.testing.expect(nullIfBlank("      ") == null);
    try std.testing.expectEqualSlices(u8, "test", nullIfBlank("test").?);
}
