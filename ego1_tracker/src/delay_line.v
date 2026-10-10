`timescale 1ns / 1ps
//=============================================================================
// delay_line : 可参数化移位寄存器延迟线
//   以 de 为移位使能, 故延迟按"有效像素数"计, 与行缓存的行延迟严格一致,
//   用于把坐标/数据对齐到处理流水线之后。
//=============================================================================
module delay_line #(
    parameter WIDTH = 12,
    parameter DELAY = 644
) (
    input  wire clk,
    input  wire rst_n,
    input  wire de,               // 移位使能(有效像素指示)
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] sr [0:DELAY-1];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DELAY; i = i + 1) sr[i] <= {WIDTH{1'b0}};
        end else if (de) begin
            sr[0] <= din;
            for (i = 1; i < DELAY; i = i + 1) sr[i] <= sr[i-1];
        end
    end

    assign dout = sr[DELAY-1];
endmodule
