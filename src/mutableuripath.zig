const std = @import("std");
const Allocator = std.mem.Allocator;

/// A mutable Uri path with convenients method to manipulate the path.
/// The allocator owns the memory of all the components of the Path.
pub const MutableUriPath = struct {
    allocator: Allocator,
    separator: u8,
    path: ?[]u8 = null,

    
};