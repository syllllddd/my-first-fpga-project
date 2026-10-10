`timescale 1ns / 1ps
//=============================================================================
// core : 核心处理链路 (不含时钟生成, 便于仿真)
//
//   测试图案 -> 灰度(色彩转换) -> 二值化 -> 3x3 行缓存 -> 形态学滤波
//            -> 质心提取 -> 十字叠加 -> VGA 输出
//
//   时钟: 25.175MHz 像素时钟; 复位: rst_n(低有效, 顶层接 MMCM locked)
//=============================================================================
module core (
    input  wire clk,            // 25.175MHz 像素时钟
    input  wire rst_n,          // 低有效复位
    input  wire [1:0] sw,       // sw[0]: 0=腐蚀 1=膨胀 ; sw[1]: 0=原图 1=二值视图
    output wire hsync,          // 高有效(内部), 顶层取反后输出到 VGA
    output wire vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire led_run,        // 心跳灯
    output wire led_target      // 目标锁定指示
);
    localparam WIDTH = 640;
    localparam PIPE  = WIDTH + 4;   // 流水线总延迟(有效像素) = 644
    // PIPE = threshold(1) + line_buffer(640+3 的数据龄) 的推导见 README

    // ---- VGA 时序 ----
    wire hsync_w, vsync_w, de, frame_start;
    wire [9:0] x;
    wire [8:0] y;
    vga_timing u_vt (
        .clk(clk), .rst_n(rst_n),
        .hsync(hsync_w), .vsync(vsync_w), .de(de),
        .x(x), .y(y), .frame_start(frame_start)
    );

    // ---- 测试图案 ----
    wire [11:0] rgb;
    test_pattern u_tp (
        .clk(clk), .rst_n(rst_n), .frame_start(frame_start),
        .x(x), .y(y), .de(de), .noise_en(1'b1), .rgb(rgb)
    );

    // ---- 灰度(色彩转换) ----
    wire [7:0] gray;
    rgb2gray u_g (.r(rgb[11:8]), .g(rgb[7:4]), .b(rgb[3:0]), .gray(gray));

    // ---- 二值化 ----
    wire bin, de1;
    threshold #(.TH(128)) u_th (
        .clk(clk), .rst_n(rst_n), .de_in(de),
        .gray(gray), .bin(bin), .de_out(de1)
    );

    // ---- 3x3 行缓存 ----
    wire [8:0] win;
    line_buffer_3x3 #(.WIDTH(WIDTH)) u_lb (
        .clk(clk), .rst_n(rst_n), .de_in(de1), .din(bin), .win(win)
    );

    // ---- 形态学滤波 ----
    wire mbin;
    morph_filter u_mf (
        .clk(clk), .rst_n(rst_n), .win(win), .op(sw[0]), .mbin(mbin)
    );

    // ---- 延迟线: 使 x/y/de/rgb 与 mbin 对齐 ----
    wire [11:0] rgb_d;
    wire [9:0]  xd;
    wire [8:0]  yd;
    wire        de_d;
    delay_line #(.WIDTH(12), .DELAY(PIPE)) u_d_rgb (.clk(clk), .rst_n(rst_n), .de(de), .din(rgb), .dout(rgb_d));
    delay_line #(.WIDTH(10), .DELAY(PIPE)) u_d_x   (.clk(clk), .rst_n(rst_n), .de(de), .din(x),   .dout(xd));
    delay_line #(.WIDTH(9),  .DELAY(PIPE)) u_d_y   (.clk(clk), .rst_n(rst_n), .de(de), .din(y),   .dout(yd));
    delay_line #(.WIDTH(1),  .DELAY(PIPE)) u_d_de  (.clk(clk), .rst_n(rst_n), .de(de), .din(de),  .dout(de_d));

    // ---- 质心提取 ----
    wire [9:0] cx;
    wire [8:0] cy;
    wire       valid;
    centroid u_cen (
        .clk(clk), .rst_n(rst_n), .de(de_d), .bin(mbin),
        .x(xd), .y(yd), .cx(cx), .cy(cy), .valid(valid)
    );

    // ---- 叠加 ----
    wire [11:0] rgb_out;
    overlay u_ov (
        .clk(clk), .rst_n(rst_n), .de(de_d), .x(xd), .y(yd),
        .rgb_in(rgb_d), .bin_in(mbin), .cx(cx), .cy(cy),
        .valid(valid), .disp_mode(sw[1]), .rgb_out(rgb_out)
    );

    // ---- 输出 ----
    assign hsync = hsync_w;
    assign vsync = vsync_w;
    assign vga_r = rgb_out[11:8];
    assign vga_g = rgb_out[7:4];
    assign vga_b = rgb_out[3:0];

    // ---- LED ----
    reg [24:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 0;
        else        cnt <= cnt + 1;
    end
    assign led_run    = cnt[24];   // ~0.75Hz 心跳
    assign led_target = valid;     // 检测到目标点亮
endmodule
