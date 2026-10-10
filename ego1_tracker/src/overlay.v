`timescale 1ns / 1ps
//=============================================================================
// overlay : 叠加层
//   在显示画面上叠加红色十字准星(目标质心); 可选显示原图或二值化处理结果。
//   输入 x/y/de/rgb 均已过延迟线, 与 bin_in 对齐。
//=============================================================================
module overlay (
    input  wire clk,
    input  wire rst_n,
    input  wire de,
    input  wire [9:0] x,
    input  wire [8:0] y,
    input  wire [11:0] rgb_in,   // 延迟后的原图
    input  wire bin_in,          // 形态学滤波后的二值图(已对齐)
    input  wire [9:0] cx,
    input  wire [8:0] cy,
    input  wire valid,
    input  wire disp_mode,       // 0=原图, 1=二值化视图
    output reg  [11:0] rgb_out
);
    localparam CROSS = 16;       // 十字臂长(像素)

    // 饱和边界, 避免无符号减法下溢
    wire [9:0] xmin = (cx >= CROSS)          ? (cx - CROSS) : 10'd0;
    wire [9:0] xmax = (cx <= 639 - CROSS)    ? (cx + CROSS) : 10'd639;
    wire [8:0] ymin = (cy >= CROSS)          ? (cy - CROSS) : 9'd0;
    wire [8:0] ymax = (cy <= 479 - CROSS)    ? (cy + CROSS) : 9'd479;

    wire on_h = (y == cy) && (x >= xmin) && (x <= xmax);
    wire on_v = (x == cx) && (y >= ymin) && (y <= ymax);
    wire on_cross = valid && (on_h || on_v);

    wire [11:0] base = disp_mode ? (bin_in ? 12'hFFF : 12'h000) : rgb_in;

    always @(*) begin
        if (de && on_cross) rgb_out = 12'hF00;   // 红色十字
        else                rgb_out = base;
    end
endmodule
