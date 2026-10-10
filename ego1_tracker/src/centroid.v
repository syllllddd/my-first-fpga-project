`timescale 1ns / 1ps
//=============================================================================
// centroid : 质心提取
//   逐像素累积 sum_x, sum_y, count (目标像素), 于下一帧起始时用除法器求
//   cx = sum_x / count, cy = sum_y / count。
//   输入 x/y/de 需已与 bin 对齐(即已过延迟线), sof = 本帧第一个有效像素。
//=============================================================================
module centroid (
    input  wire clk,
    input  wire rst_n,
    input  wire de,
    input  wire bin,
    input  wire [9:0] x,
    input  wire [8:0] y,
    output reg  [9:0] cx,
    output reg  [8:0] cy,
    output reg  valid    // 1=检测到目标(上一帧), 0=无目标
);
    reg [31:0] sum_x, sum_y, count;
    reg [31:0] cnt_latch;        // 上帧像素数(用于 valid 判断)
    wire [31:0] qx, qy;
    wire dx_done, dy_done;

    // 帧起始(延迟域): 本帧第一个有效像素
    wire sof = de && (x == 10'd0) && (y == 9'd0);
    // 仅当上一帧存在目标时才启动除法(避免除零)
    wire start_div = sof && (count != 32'd0);

    divider #(.N(32)) u_div_x (
        .clk(clk), .rst_n(rst_n), .start(start_div),
        .dividend(sum_x), .divisor(count), .quotient(qx), .done(dx_done)
    );
    divider #(.N(32)) u_div_y (
        .clk(clk), .rst_n(rst_n), .start(start_div),
        .dividend(sum_y), .divisor(count), .quotient(qy), .done(dy_done)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_x <= 0; sum_y <= 0; count <= 0; cnt_latch <= 0;
            cx <= 0; cy <= 0; valid <= 0;
        end else begin
            // 帧起始: 锁存上帧像素数, 清零并累加本帧第一个像素
            if (sof) begin
                cnt_latch <= count;
                sum_x <= bin ? {22'b0, x} : 32'b0;
                sum_y <= bin ? {23'b0, y} : 32'b0;
                count <= bin ? 32'd1    : 32'd0;
                if (count == 32'd0) valid <= 1'b0;  // 上帧无目标
            end else if (de && bin) begin
                sum_x <= sum_x + {22'b0, x};
                sum_y <= sum_y + {23'b0, y};
                count <= count + 1;
            end
            // 除法完成 -> 更新质心
            if (dx_done && dy_done) begin
                cx    <= qx[9:0];
                cy    <= qy[8:0];
                valid <= (cnt_latch != 32'd0);
            end
        end
    end
endmodule
