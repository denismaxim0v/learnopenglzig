const std = @import("std");
const c = @import("c.zig");
const shader = @import("shader.zig");
const img = @import("image.zig");

const allocator = std.heap.c_allocator;
var window: *c.GLFWwindow = undefined;

const vertexShaderSource: []const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aColor;
    \\layout (location = 2) in vec2 aTexCoord;
    \\
    \\out vec3 ourColor;
    \\out vec2 TexCoord;
    \\
    \\void main()
    \\{
    \\	gl_Position = vec4(aPos, 1.0);
    \\	ourColor = aColor;
    \\	TexCoord = vec2(aTexCoord.x, aTexCoord.y);
    \\}
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

const textureShaderSource: []const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\in vec3 ourColor;
    \\in vec2 TexCoord;
    \\
    \\// texture sampler
    \\uniform sampler2D texture1;
    \\uniform sampler2D texture2;
    \\
    \\void main()
    \\{
    \\    FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
    \\}
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
    c.glfwSwapInterval(1);
    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
        @panic("failed to load");
    }
    const shaderProgram = try shader.ShaderProgram.create(
        allocator,
        vertexShaderSource,
        textureShaderSource,
    );

    // vertex data
    const vertices = [32]f32{
        0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, // top right
        0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, // bottom right
        -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, // bottom left
        -0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, // top left,
    };

    const indices = [6]c_uint{
        0, 1, 3,
        1, 2, 3,
    };

    var VBO: c_uint = undefined;
    var VAO: c_uint = undefined;
    var EBO: c_uint = undefined;

    c.glGenVertexArrays(1, &VAO);
    defer c.glDeleteVertexArrays(1, &VAO);
    c.glBindVertexArray(VAO);

    c.glGenBuffers(1, &VBO);
    defer c.glDeleteBuffers(1, &VBO);

    c.glGenBuffers(1, &EBO);
    defer c.glDeleteBuffers(1, &EBO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(c_uint), &indices, c.GL_STATIC_DRAW);

    // position
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    // color
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    // texture
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(6 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(2);

    var texture1: c_uint = undefined;
    c.glGenTextures(1, &texture1);
    c.glBindTexture(c.GL_TEXTURE_2D, texture1);

    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);

    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    var imageA_data = @embedFile("assets/container.jpg");
    var imageA = try img.Image.create(imageA_data);
    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_RGB,
        @intCast(imageA.width),
        @intCast(imageA.height),
        0,
        c.GL_RGB,
        c.GL_UNSIGNED_BYTE,
        imageA.raw,
    );
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
    c.stbi_image_free(imageA.raw);

    var texture2: c_uint = undefined;
    c.glGenTextures(1, &texture2);
    c.glBindTexture(c.GL_TEXTURE_2D, texture2);

    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);

    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    var imageB_data = @embedFile("assets/awesomeface.png");
    var imageB = try img.Image.create(imageB_data);
    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_RGBA,
        @intCast(imageB.width),
        @intCast(imageB.height),
        0,
        c.GL_RGBA,
        c.GL_UNSIGNED_BYTE,
        imageB.raw,
    );
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
    c.stbi_image_free(imageB.raw);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    c.glUseProgram(shaderProgram.program_id);
    c.glUniform1i(c.glGetUniformLocation(shaderProgram.program_id, "texture1"), 0);
    c.glUniform1i(c.glGetUniformLocation(shaderProgram.program_id, "texture2"), 1);

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        processInput(window);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(shaderProgram.program_id);
        c.glBindVertexArray(VAO);

        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2);

        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    c.glDeleteVertexArrays(1, &VAO);
    c.glDeleteBuffers(1, &VBO);
    c.glDeleteBuffers(1, &EBO);

    c.glfwTerminate();
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
