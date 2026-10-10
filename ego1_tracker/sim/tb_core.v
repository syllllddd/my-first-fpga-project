`timescale 1ns / 1ps
//=============================================================================
// tb_core : 核心链路仿真测试 (用 Vivado xsim / iverilog / verilator 均可)
//   验证: 质心应约为目标方块中心, 初始 (320, 220), 每帧水平移动 4 像素。
//   运行命令示例 (iverilog):
//     iverilog -o tb.out src/*.v sim/tb_core.v && vvp tb.out
//=============================================================================
module tb_core;

    reg        clk = 0;
    reg        rst_n = 0;
    reg  [1:0] sw = 2'b00;   // 腐蚀 + 原图显示

    wire hsync, vsync;
    wire [3:0] vga_r, vga_g, vga_b;
    wire led_run, led_target;

    core uut (
        .clk(clk), .rst_n(rst_n), .sw(sw),
        .hsync(hsync), .vsync(vsync),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .led_run(led_run), .led_target(led_target)
    );

    // 40ns 周期 ≈ 25MHz (仿真用整数周期即可, 不影响功能)
    always #20 clk = ~clk;

    // 复位
    initial begin
        rst_n = 0;
        #300 rst_n = 1;
    end

    // 层级引用观察质心结果
    wire [9:0] cx = uut.u_cen.cx;
    wire [8:0] cy = uut.u_cen.cy;
    wire       valid = uut.u_cen.valid;

    always @(posedge clk) begin
        if (valid)
            $display("t=%0t ns : centroid = (%0d, %0d)", $time, cx, cy);
    end

    // 跑 3 帧 (3 * 800 * 525 = 1,260,000 周期) 后结束
    initial begin
        #(3*800*525*40) $display("simulation finished");
        #100 $finish;
    end
endmodule
