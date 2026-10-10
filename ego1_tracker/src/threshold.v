`timescale 1ns / 1ps
//=============================================================================
// threshold : 灰度二值化, gray > TH ? 1 : 0
//   输出 bin 与 de_out 均已打一拍, 二者严格对齐(供行缓存使用)
//=============================================================================
module threshold #(
    parameter TH = 128
) (
    input  wire clk,
    input  wire rst_n,
    input  wire de_in,
    input  wire [7:0] gray,
    output reg  bin,
    output reg  de_out   // 与 bin 对齐的 de (延迟 1 拍)
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin    <= 1'b0;
            de_out <= 1'b0;
        end else begin
            bin    <= de_in ? (gray > TH) : 1'b0;
            de_out <= de_in;
        end
    end
endmodule
