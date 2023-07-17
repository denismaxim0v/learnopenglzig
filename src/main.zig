const std = @import("std");
const c = @import("c.zig");

const allocator = std.heap.c_allocator;
var window: *c.GLFWwindow = undefined;

const vertexShaderSource: []const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aColor;
    \\out vec3 ourColor;
    \\void main()
    \\{
    \\   gl_Position = vec4(aPos, 1.0);
    \\   ourColor = aColor;
    \\};
;
const fragmentShaderSource: []const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\in vec3 ourColor;
    \\void main()
    \\{
    \\   FragColor = vec4(ourColor, 1.0f);
    \\};
;

pub fn main() !void {
    if (c.glfwInit() == c.GL_FALSE) @panic("GLFW init failure");
    defer c.glfwTerminate();

    window = c.glfwCreateWindow(800, 600, "LearnOpengl", null, null) orelse @panic("unable to create window");
    defer c.glfwDestroyWindow(window);

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
        @panic("failed to load");
    }

    var ok: c.GLint = undefined;
    var errorSize: c.GLint = undefined;

    // vertex shader
    const vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
    const vertexSourcePtr: ?[*]const u8 = vertexShaderSource.ptr;
    c.glShaderSource(vertexShader, 1, &vertexSourcePtr, null);
    c.glCompileShader(vertexShader);
    c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &ok);
    if (ok == 0) {
        c.glGetShaderiv(vertexShader, c.GL_INFO_LOG_LENGTH, &errorSize);
        const message = allocator.alloc(u8, @intCast(errorSize)) catch unreachable;
        c.glGetShaderInfoLog(vertexShader, errorSize, &errorSize, message.ptr);
        std.log.err("failed to compile shader {s}\n", .{message});
    }

    // fragment shader
    const fragmentShader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    const fragmentSourcePtr: ?[*]const u8 = fragmentShaderSource.ptr;
    c.glShaderSource(fragmentShader, 1, &fragmentSourcePtr, null);
    c.glCompileShader(fragmentShader);
    c.glGetShaderiv(fragmentShader, c.GL_COMPILE_STATUS, &ok);
    if (ok == 0) {
        c.glGetShaderiv(vertexShader, c.GL_INFO_LOG_LENGTH, &errorSize);
        const message = allocator.alloc(u8, @intCast(errorSize)) catch unreachable;
        c.glGetShaderInfoLog(vertexShader, errorSize, &errorSize, message.ptr);
        std.log.err("failed to compile shader {s}\n", .{message});
    }

    // shader program
    const shaderProgram: c_uint = c.glCreateProgram();
    defer c.glDeleteProgram(shaderProgram);
    c.glAttachShader(shaderProgram, vertexShader);
    c.glAttachShader(shaderProgram, fragmentShader);
    c.glLinkProgram(shaderProgram);
    c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, &ok);
    if (ok == 0) {
        c.glGetProgramiv(shaderProgram, c.GL_INFO_LOG_LENGTH, &errorSize);
        const message = allocator.alloc(u8, @intCast(errorSize)) catch unreachable;
        c.glGetProgramInfoLog(shaderProgram, errorSize, &errorSize, message.ptr);
        std.log.err("ERROR::PROGRAM::LINK_FAILED\n{s}\n", .{message});
    }

    // delete shaders
    c.glDeleteShader(vertexShader);
    c.glDeleteShader(fragmentShader);

    // vertex data
    const vertices = [18]f32{
        //x     y    z    r    g    b
        -0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
        0.5,  -0.5, 0.0, 0.0, 1.0, 0.0,
        0.0,  0.5,  0.0, 0.0, 0.0, 1.0,
    };

    var VBO: c_uint = undefined;
    var VAO: c_uint = undefined;

    c.glGenVertexArrays(1, &VAO);
    defer c.glDeleteVertexArrays(1, &VAO);
    c.glBindVertexArray(VAO);

    c.glGenBuffers(1, &VBO);
    defer c.glDeleteBuffers(1, &VBO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    // position
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    // color
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    c.glUseProgram(shaderProgram);

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        processInput(window);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glBindVertexArray(VAO);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}

fn processInput(win: *c.GLFWwindow) void {
    if (c.glfwGetKey(win, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(win, c.GL_TRUE);
    }
}

pub fn framebuffer_size_callback(win: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = win;
    c.glViewport(0, 0, width, height);
}
