const c = @import("c.zig");
const std = @import("std");
const mem = std.mem;

const ShaderError = error{
    CompilationError,
    LinkError,
};

pub const ShaderProgram = struct {
    program_id: c.GLuint,
    vertex: Shader,
    fragment: Shader,

    pub fn create(
        allocator: mem.Allocator,
        vertexSource: []const u8,
        fragmentSource: []const u8,
    ) !ShaderProgram {
        var sp: ShaderProgram = undefined;
        sp.vertex = try Shader.initShader(allocator, vertexSource, c.GL_VERTEX_SHADER);
        sp.fragment = try Shader.initShader(allocator, fragmentSource, c.GL_FRAGMENT_SHADER);

        sp.program_id = c.glCreateProgram();
        c.glAttachShader(sp.program_id, sp.vertex.id);
        c.glAttachShader(sp.program_id, sp.fragment.id);
        c.glLinkProgram(sp.program_id);

        var ok: c.GLint = undefined;
        c.glGetProgramiv(sp.program_id, c.GL_LINK_STATUS, &ok);
        if (ok != 0) return sp;

        var errorSize: c.GLint = undefined;
        c.glGetProgramiv(sp.program_id, c.GL_INFO_LOG_LENGTH, &errorSize);

        const message = allocator.alloc(u8, @intCast(errorSize)) catch unreachable;
        c.glGetProgramInfoLog(sp.program_id, errorSize, &errorSize, message.ptr);
        std.log.err("failed to link program {s}\n", .{message});
        return ShaderError.LinkError;
    }
};

const Shader = struct {
    id: c.GLuint,

    pub fn initShader(
        allocator: mem.Allocator,
        source: []const u8,
        kind: c.GLenum,
    ) !Shader {
        const shader_id = c.glCreateShader(kind);
        const source_ptr: ?[*]const u8 = source.ptr;
        const source_len: c.GLint = @intCast(source.len);

        c.glShaderSource(shader_id, 1, &source_ptr, &source_len);
        c.glCompileShader(shader_id);

        var ok: c.GLint = undefined;
        c.glGetShaderiv(shader_id, c.GL_COMPILE_STATUS, &ok);
        if (ok != 0) return Shader{ .id = shader_id };

        var errorSize: c.GLint = undefined;
        c.glGetShaderiv(shader_id, c.GL_INFO_LOG_LENGTH, &errorSize);

        const message = allocator.alloc(u8, @intCast(errorSize)) catch unreachable;
        c.glGetShaderInfoLog(shader_id, errorSize, &errorSize, message.ptr);
        std.log.err("failed to compile shader {s}\n", .{message});
        return ShaderError.CompilationError;
    }
};
