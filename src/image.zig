const c = @import("c.zig");

pub const Image = struct {
    width: u32,
    height: u32,
    raw: [*c]u8 = undefined,

    pub fn destroy(pi: *Image) void {
        c.stbi_image_free(pi.raw);
    }

    pub fn create(compressed_bytes: []const u8) !Image {
        var img: Image = undefined;

        var width: c_int = undefined;
        var height: c_int = undefined;
        var channels: c_int = undefined;

        if (c.stbi_info_from_memory(compressed_bytes.ptr, @intCast(compressed_bytes.len), &width, &height, &channels) == 0) {
            return error.NotPngFile;
        }

        if (width <= 0 or height <= 0) return error.NoPixels;
        img.width = @intCast(width);
        img.height = @intCast(height);

        if (c.stbi_is_16_bit_from_memory(compressed_bytes.ptr, @intCast(compressed_bytes.len)) != 0) {
            return error.InvalidFormat;
        }

        c.stbi_set_flip_vertically_on_load(1);
        const image_data = c.stbi_load_from_memory(
            compressed_bytes.ptr,
            @intCast(compressed_bytes.len),
            &width,
            &height,
            &channels,
            0,
        );

        if (image_data == null) return error.NoMem;

        img.raw = image_data;

        return img;
    }
};
