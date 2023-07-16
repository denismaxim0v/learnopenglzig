const std = @import("std");
const c = @import("c.zig");

var window: *c.GLFWwindow = undefined;

pub fn main() !void {
    if (c.glfwInit() == c.GL_FALSE) @panic("GLFW init failure");
    defer c.glfwTerminate();

    window = c.glfwCreateWindow(800, 600, "LearnOpengl", null, null) orelse @panic("unable to create window");
    defer c.glfwDestroyWindow(window);

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 8);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_RESIZABLE, c.GL_FALSE);
    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress)) == 0) {
        @panic("failed to load");
    }

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        // input
        processInput(window);

        c.glClearColor(0.1, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

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
