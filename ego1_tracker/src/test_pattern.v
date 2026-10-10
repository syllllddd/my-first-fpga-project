`timescale 1ns / 1ps
//=============================================================================
// test_pattern : 内部测试图案
//   黑底 + 白色运动方块(左右弹跳) + 若干单像素噪点
//   用于验证: 灰度 -> 二值化 -> 3x3 形态学(腐蚀去噪) -> 质心跟踪 全链路
//=============================================================================
module test_pattern (
    input  wire clk,
    input  wire rst_n,
    input  wire frame_start, // 每帧起始脉冲
    input  wire [9:0] x,
    input  wire [8:0] y,
    input  wire de,
    input  wire noise_en,    // 噪点使能
    output reg  [11:0] rgb   // {R[3:0], G[3:0], B[3:0]}
);
    localparam OBJ_W = 40;
    localparam OBJ_H = 40;
    localparam OBJ_Y = 200;        // 目标方块上边沿(固定, 仅水平移动)
    localparam STEP  = 4;          // 每帧水平移动像素数
    localparam X_MAX = 640 - OBJ_W; // 600

    reg [9:0] obj_x;               // 目标左边缘
    reg       dir;                 // 1=向右, 0=向左

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            obj_x <= 10'd300;
            dir   <= 1'b1;
        end else if (frame_start) begin
            if (dir) begin
                if (obj_x + STEP > X_MAX) begin
                    obj_x <= X_MAX;
                    dir   <= 1'b0;
                end else begin
                    obj_x <= obj_x + STEP;
                end
            end else begin
                if (obj_x < STEP) begin
                    obj_x <= 10'd0;
                    dir   <= 1'b1;
                end else begin
                    obj_x <= obj_x - STEP;
                end
            end
        end
    end

    // 目标方块区域
    wire in_obj = (x >= obj_x) && (x < obj_x + OBJ_W) &&
                  (y >= OBJ_Y) && (y < OBJ_Y + OBJ_H);

    // 若干固定单像素噪点 (会被 3x3 腐蚀滤除)
    wire speck = (x == 10'd100 && y == 9'd100) ||
                 (x == 10'd150 && y == 9'd300) ||
                 (x == 10'd300 && y == 9'd80 ) ||
                 (x == 10'd500 && y == 9'd250) ||
                 (x == 10'd400 && y == 9'd400) ||
                 (x == 10'd80  && y == 9'd450);

    always @(*) begin
        if (de && (in_obj || (noise_en && speck)))
            rgb = 12'hFFF;          // 白
        else
            rgb = 12'h000;          // 黑
    end
endmodule
