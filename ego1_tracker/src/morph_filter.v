`timescale 1ns / 1ps
//=============================================================================
// morph_filter : 3x3 二值形态学滤波
//   op = 0 : 腐蚀 (9 邻域全为 1 才保留, 可滤除孤立噪点)
//   op = 1 : 膨胀 (9 邻域任一为 1 即保留, 可填补空洞)
//=============================================================================
module morph_filter (
    input  wire clk,
    input  wire rst_n,
    input  wire [8:0] win,
    input  wire op,       // 0=腐蚀(默认), 1=膨胀
    output reg  mbin
);
    wire all_ones = &win;   // 9 邻域全 1
    wire any_one  = |win;   // 9 邻域任一为 1

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mbin <= 1'b0;
        else        mbin <= op ? any_one : all_ones;
    end
endmodule
