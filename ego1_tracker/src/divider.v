`timescale 1ns / 1ps
//=============================================================================
// divider : 无符号"恢复余数"除法器 (N 位)
//   quotient = dividend / divisor, 每 bit 一个时钟, 共 N 个时钟完成。
//   质心 cx = sum_x / count 即用此模块实现, 无浮点/IP 核, 纯 RTL。
//=============================================================================
module divider #(
    parameter N = 32
) (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire [N-1:0] dividend,
    input  wire [N-1:0] divisor,
    output reg  [N-1:0] quotient,
    output reg  done
);
    reg [N-1:0] acc, den, num;
    reg [5:0]   cnt;   // 最多 N(=32) 次迭代, 6bit 足够
    reg         busy;

    // 恢复余数法单步: acc = (acc<<1 | num的MSB); 若 >= den 则减并商位为1
    wire [N-1:0] shift_val = {acc[N-2:0], num[N-1]};
    wire         ge        = (shift_val >= den);
    wire [N-1:0] nxt_acc   = ge ? (shift_val - den) : shift_val;
    wire [N-1:0] nxt_quo   = {quotient[N-2:0], ge};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 0; den <= 0; num <= 0; cnt <= 0;
            quotient <= 0; done <= 0; busy <= 0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                if (divisor == 0) begin      // 除零保护
                    quotient <= 0;
                    done     <= 1'b1;
                    busy     <= 1'b0;
                end else begin
                    acc      <= 0;
                    den      <= divisor;
                    num      <= dividend;
                    quotient <= 0;
                    cnt      <= 0;
                    busy     <= 1'b1;
                end
            end else if (busy) begin
                if (cnt < N) begin
                    acc      <= nxt_acc;
                    num      <= {num[N-2:0], 1'b0};
                    quotient <= nxt_quo;
                    cnt      <= cnt + 1;
                end else begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end
endmodule
