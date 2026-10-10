## 引脚约束 — EGO1 (Xilinx Artix-7 XC7A35T-1CSG324C)
#  本文件基于 EGO1 常见标准引脚整理。
#  注意: 请务必以你手上的板卡原理图 / 官方约束文件为准, 如有差异仅需改动对应 PACKAGE_PIN。

# ---------------- 100MHz 系统时钟 ----------------
set_property PACKAGE_PIN P17 [get_ports clk_100m]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100m]
create_clock -period 10.000 -name sys_clk [get_ports clk_100m]

# ---------------- 拨码开关 SW0/SW1 ----------------
set_property PACKAGE_PIN P5 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN P4 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]

# ---------------- VGA 行/场同步 (低有效) ----------------
set_property PACKAGE_PIN D7 [get_ports vga_hs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs]
set_property PACKAGE_PIN C4 [get_ports vga_vs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs]

# ---------------- VGA 红 (RGB444 高位在前) ----------------
set_property PACKAGE_PIN F5 [get_ports {vga_r[3]}]
set_property PACKAGE_PIN C6 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN C5 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN B7 [get_ports {vga_r[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[*]}]

# ---------------- VGA 绿 ----------------
set_property PACKAGE_PIN B6 [get_ports {vga_g[3]}]
set_property PACKAGE_PIN A6 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN A5 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN D8 [get_ports {vga_g[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[*]}]

# ---------------- VGA 蓝 ----------------
set_property PACKAGE_PIN C7 [get_ports {vga_b[3]}]
set_property PACKAGE_PIN E6 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN E5 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN E7 [get_ports {vga_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[*]}]

# ---------------- LED ----------------
set_property PACKAGE_PIN F6 [get_ports led_run]
set_property IOSTANDARD LVCMOS33 [get_ports led_run]
set_property PACKAGE_PIN G4 [get_ports led_target]
set_property IOSTANDARD LVCMOS33 [get_ports led_target]

# ---------------- 配置电压 ----------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
