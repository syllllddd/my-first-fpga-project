`timescale 1ns / 1ps
//=============================================================================
// top : 顶层 (100MHz -> 像素时钟 + 核心处理链路)
//=============================================================================
module top (
    input  wire clk_100m,      // 板载 100MHz 时钟
    input  wire [1:0] sw,      // 拨码开关
    output wire vga_hs,        // 低有效(直接接 VGA 接口)
    output wire vga_vs,        // 低有效
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire led_run,
    output wire led_target
);
    wire clk_pix, locked;
    clk_gen u_cg (.clk_in(clk_100m), .clk_pix(clk_pix), .locked(locked));

    wire hsync, vsync;
    core u_core (
        .clk(clk_pix), .rst_n(locked), .sw(sw),
        .hsync(hsync), .vsync(vsync),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .led_run(led_run), .led_target(led_target)
    );

    // VGA 同步为低有效
    assign vga_hs = ~hsync;
    assign vga_vs = ~vsync;
endmodule
