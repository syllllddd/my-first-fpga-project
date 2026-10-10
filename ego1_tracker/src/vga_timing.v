`timescale 1ns / 1ps
//=============================================================================
// vga_timing : 640x480@60Hz 时序生成, 像素时钟 25.175MHz
//
//   行时序: 640 active + 16 front + 96 sync + 48 back = 800
//   场时序: 480 active + 10 front + 2  sync + 33 back = 525
//
//   hsync/vsync 输出为"高有效同步"(同步期间为高), 顶层再取反输出到 VGA 接口
//   de 为有效显示区标志, (x,y) 为有效区内像素坐标
//=============================================================================
module vga_timing (
    input  wire clk,
    input  wire rst_n,
    output reg  hsync,
    output reg  vsync,
    output reg  de,          // 有效显示区 (active)
    output reg  [9:0] x,     // 列坐标 0..639
    output reg  [8:0] y,     // 行坐标 0..479
    output reg  frame_start  // 场同步上升沿脉冲 (1 时钟周期)
);
    localparam H_ACTIVE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48;
    localparam H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK; // 800
    localparam V_ACTIVE = 480, V_FRONT = 10, V_SYNC = 2, V_BACK = 33;
    localparam V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK; // 525

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;
    reg       vsync_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 0; v_cnt <= 0; hsync <= 0; vsync <= 0;
            de <= 0; x <= 0; y <= 0; frame_start <= 0; vsync_d <= 0;
        end else begin
            // 行列计数
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1) v_cnt <= 0;
                else                       v_cnt <= v_cnt + 1;
            end else begin
                h_cnt <= h_cnt + 1;
            end

            // 同步信号 (高有效)
            hsync <= (h_cnt >= H_ACTIVE + H_FRONT) &&
                     (h_cnt <  H_ACTIVE + H_FRONT + H_SYNC);
            vsync <= (v_cnt >= V_ACTIVE + V_FRONT) &&
                     (v_cnt <  V_ACTIVE + V_FRONT + V_SYNC);

            // 有效区与像素坐标
            de <= (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
            if ((h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE)) begin
                x <= h_cnt[9:0];
                y <= v_cnt[8:0];
            end else begin
                x <= 0;
                y <= 0;
            end

            // 场同步上升沿 -> 帧起始脉冲
            vsync_d <= vsync;
            frame_start <= vsync && !vsync_d;
        end
    end
endmodule
