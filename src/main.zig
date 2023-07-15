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

    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress)) == 0) {
        @panic("shit");
    }

    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClearColor(0.1, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
