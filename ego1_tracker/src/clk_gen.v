`timescale 1ns / 1ps
//=============================================================================
// clk_gen : 100MHz -> 25.175MHz 像素时钟 (MMCME2_BASE 原语, 纯RTL, 无IP核)
//
//   VCO   = 100MHz * 10.07 = 1007MHz (Artix-7 VCO 合法区间 600~1200MHz)
//   CLKOUT0 = 1007MHz / 40 = 25.175MHz  <- 640x480@60Hz VGA 标准像素时钟
//
//   locked 作为系统上电复位源 (MMCM 锁定后解除复位)
//=============================================================================
module clk_gen (
    input  wire clk_in,     // 板载 100MHz 时钟
    output wire clk_pix,    // 25.175MHz 像素时钟
    output wire locked      // MMCM 锁定指示 (高有效)
);
    wire clkfb_out;         // MMCM 反馈输出
    wire clkfb_in;          // 经 BUFG 的反馈时钟
    wire clkout0;

    // 反馈时钟经 BUFG, 改善抖动
    BUFG u_fb_bufg (.I(clkfb_out), .O(clkfb_in));

    MMCME2_BASE #(
        .CLKIN1_PERIOD    (10.0),   // 100MHz
        .CLKFBOUT_MULT_F  (10.07),  // VCO = 100 * 10.07 = 1007MHz
        .DIVCLK_DIVIDE    (1),
        .CLKOUT0_DIVIDE_F (40.0)    // 1007 / 40 = 25.175MHz
    ) u_mmcm (
        .CLKIN1   (clk_in),
        .CLKFBIN  (clkfb_in),
        .CLKFBOUT (clkfb_out),
        .CLKFBOUTB(),
        .CLKOUT0  (clkout0),
        .CLKOUT0B (),
        .CLKOUT1  (),
        .CLKOUT1B (),
        .CLKOUT2  (),
        .CLKOUT2B (),
        .CLKOUT3  (),
        .CLKOUT3B (),
        .CLKOUT4  (),
        .CLKOUT5  (),
        .CLKOUT6  (),
        .LOCKED   (locked),
        .PWRDWN   (1'b0),
        .RST      (1'b0)
    );

    // 像素时钟全局缓冲
    BUFG u_pix_bufg (.I(clkout0), .O(clk_pix));
endmodule
