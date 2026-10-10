`timescale 1ns / 1ps
//=============================================================================
// line_buffer_3x3 : 行缓存 Line Buffer + 移位寄存器 -> 输出 3x3 邻域窗口
//
//   仅缓存"两行"图像数据(1bit 二值图), 无需大容量全帧缓存, 即项目所述
//   "行缓存并行计算流水线" 的核心。
//
//   实现: 两片 640x1 分布式 RAM(LUTRAM, 异步读) 级联 + 三级列移位寄存器。
//   窗口中心 win[4] 对应当前输入像素的 (上一行, 左一列)。
//
//   win 位序: {r1_0,r1_1,r1_2, r2_0,r2_1,r2_2, r3_0,r3_1,r3_2}
//   其中 r1=当前行, r2=上一行, r3=上两行; _0/_1/_2 = 当前列/左一/左二。
//=============================================================================
module line_buffer_3x3 #(
    parameter WIDTH = 640
) (
    input  wire clk,
    input  wire rst_n,
    input  wire de_in,
    input  wire din,
    output wire [8:0] win
);
    (* ram_style = "distributed" *) reg lb1 [0:WIDTH-1]; // 上一行
    (* ram_style = "distributed" *) reg lb2 [0:WIDTH-1]; // 上两行

    reg [9:0] col;               // 行内列地址 0..WIDTH-1
    reg r1_0, r1_1, r1_2;        // 当前行 (底行)
    reg r2_0, r2_1, r2_2;        // 上一行 (中行)
    reg r3_0, r3_1, r3_2;        // 上两行 (顶行)

    wire lb1_rd = lb1[col];      // 异步读(读旧值, 读优先)
    wire lb2_rd = lb2[col];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col <= 0;
            r1_0 <= 0; r1_1 <= 0; r1_2 <= 0;
            r2_0 <= 0; r2_1 <= 0; r2_2 <= 0;
            r3_0 <= 0; r3_1 <= 0; r3_2 <= 0;
        end else if (de_in) begin
            col <= (col == WIDTH-1) ? 0 : col + 1;

            // 列移位寄存器
            r1_0 <= din;   r1_1 <= r1_0;   r1_2 <= r1_1;
            r2_0 <= lb1_rd; r2_1 <= r2_0;  r2_2 <= r2_1;
            r3_0 <= lb2_rd; r3_1 <= r3_0;  r3_2 <= r3_1;

            // 行缓存级联写入
            lb1[col] <= din;      // 当前像素写入 lb1
            lb2[col] <= lb1_rd;   // lb1 旧值移入 lb2
        end
    end

    // 3x3 窗口, 中心为 win[4]
    assign win = {r1_0, r1_1, r1_2, r2_0, r2_1, r2_2, r3_0, r3_1, r3_2};
endmodule
