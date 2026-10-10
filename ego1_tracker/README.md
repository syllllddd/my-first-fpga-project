# 面向高速工业视觉的边缘端超低延迟动态追踪系统 — EGO1 基础版

基于 **AMD/Xilinx Artix-7 (EGO1, XC7A35T-1CSG324C)** 的纯 RTL 实现，在 PL 层以**行缓存 (Line Buffer) 并行计算流水线**完成图像处理，无需大容量全帧缓存。

本版本使用**内部测试图案 → VGA 显示**，打通并演示项目描述中的全部基础功能模块：

> 图像采集(测试图案) → 色彩转换(灰度/YCbCr 亮度) → 二值化 → 3×3 行缓存 → 形态学滤波(腐蚀/膨胀) → 质心提取 → 十字准星叠加 → VGA 输出

---

## 1. 目录结构

```
ego1_tracker/
├── src/
│   ├── clk_gen.v          # MMCM: 100MHz -> 25.175MHz 像素时钟 (纯原语, 无IP)
│   ├── vga_timing.v       # 640x480@60Hz 时序生成
│   ├── test_pattern.v     # 内部测试图案(运动方块+噪点)
│   ├── rgb2gray.v         # RGB444 -> 灰度(亮度 Y)
│   ├── threshold.v        # 灰度二值化
│   ├── line_buffer_3x3.v  # 行缓存 + 3x3 邻域窗口 (核心)
│   ├── morph_filter.v     # 3x3 形态学滤波(腐蚀/膨胀)
│   ├── delay_line.v       # 流水线对齐延迟线
│   ├── centroid.v         # 质心提取(累加 + 除法器)
│   ├── divider.v          # 无符号恢复余数除法器
│   ├── overlay.v          # 十字准星/二值视图叠加
│   ├── core.v             # 核心处理链路(不含时钟, 便于仿真)
│   └── top.v              # 顶层(时钟 + 核心链路)
├── constr/
│   └── ego1.xdc           # 引脚约束
├── sim/
│   └── tb_core.v          # 核心链路仿真
└── README.md
```

## 2. 数据通路与架构

```
             ┌─────────────── 25.175MHz (MMCM from 100MHz) ───────────────┐
             │                                                            │
 vga_timing ─┐                                                            │
             │  x,y,de                                                    │
 test_pattern ─> rgb(12) ─> rgb2gray ─> gray(8) ─> threshold ─> bin(1)    │
             │                                              │             │
             │                            ┌─────────────────▼──┐          │
             │                            │  line_buffer_3x3   │ 2 行缓存 │
             │                            │  (1bit, 640x2 RAM) │ + 移位寄存器│
             │                            └─────────┬──────────┘          │
             │                                      │ win(9)              │
             │                            ┌─────────▼──────────┐          │
             │                            │   morph_filter      │ 腐蚀/膨胀│
             │                            └─────────┬──────────┘          │
             │                                      │ mbin(1)             │
             │   delay_line(x,y,de,rgb) ── 对齐 644 有效像素 ──┐            │
             │                                      │          │          │
             │                            ┌─────────▼──────────▼─┐        │
             │                            │  centroid (质心)      │        │
             │                            │  sum_x,sum_y,count    │        │
             │                            │  + divider(32bit)     │        │
             │                            └─────────┬────────────┘        │
             │                                      │ cx,cy,valid         │
             │                            ┌─────────▼──────────┐          │
             │                            │   overlay (叠加)    │          │
             │                            └─────────┬──────────┘          │
             └──────────────────────────────────────┴─────────────────────┘
                                                    vga_r/g/b + hsync/vsync
```

### 关键设计点

- **行缓存 Line Buffer**：只缓存 2 行 1bit 数据（640×2 分布式 RAM），配合列移位寄存器输出 3×3 邻域，**无需全帧缓存**，正是“行缓存并行计算流水线”的核心。
- **流水线对齐**：处理链总延迟 `PIPE = 640 + 4 = 644` 个有效像素（二值化 +1、行缓存 +640+3 的数据龄、形态学 +1）。`delay_line` 以 `de`（有效像素）为移位使能，把坐标/原图延迟同样拍数，保证质心坐标与图像严格对齐。
- **质心提取**：逐像素累加 `sum_x / sum_y / count`，帧末用纯 RTL 恢复余数除法器求 `cx = sum_x/count`、`cy = sum_y/count`，无浮点/IP 核。
- **单时钟域**：全部逻辑跑在 25.175MHz 像素时钟，无跨时钟域问题（MMCM 仅用于产生像素时钟）。

## 3. 上板步骤（Vivado 2020.x+）

1. **新建工程**：Vivado → Create Project → 器件选 `xc7a35tcsg324-1`（Part 直接搜 `xc7a35t`）。
2. **添加源文件**：Add Sources → Add Files → 选择 `src/` 下全部 `.v`，并勾选 `top.v` 为顶层（或 Add Sources 时勾选 Copy sources into project）。
3. **添加约束**：Add Constraints → Add Files → 选择 `constr/ego1.xdc`。
4. **综合**：Run Synthesis（应无错误）。
5. **实现**：Run Implementation → Generate Bitstream。
6. **下载**：Open Hardware Manager → 连接板卡 → Program Device。

> 若引脚与你的板卡不符（不同批次 EGO1 引脚可能有差异），仅需在 `ego1.xdc` 中修改对应 `PACKAGE_PIN`。

## 4. 操作说明

| 拨码开关 | 功能 |
|---|---|
| `sw[0]` | `0` = 腐蚀（默认，滤除孤立噪点后跟踪）; `1` = 膨胀 |
| `sw[1]` | `0` = 显示原图 + 红色十字准星（默认）; `1` = 显示二值化/形态学结果 + 准星 |

- **预期现象**：黑底上一个白色方块左右弹跳，红色十字准星稳定锁定方块质心（约滞后 1 帧，方块每帧移动 4 像素）。`led_target` 点亮表示检测到目标，`led_run` 以约 0.75Hz 闪烁表示系统运行。
- **噪点验证**：测试图案自带 6 个单像素白噪点，`sw[0]=0`（腐蚀）时噪点被滤除，准星不受影响；切到 `sw[1]=1` 可直观看到二值化/形态学图像。

## 5. 仿真验证（可选）

```bash
# 用 iverilog（或 Vivado xsim 建 sim 工程运行 tb_core）
iverilog -o tb.out src/clk_gen.v src/vga_timing.v src/test_pattern.v src/rgb2gray.v \
  src/threshold.v src/line_buffer_3x3.v src/morph_filter.v src/delay_line.v \
  src/divider.v src/centroid.v src/overlay.v src/core.v sim/tb_core.v
vvp tb.out
```

预期：仿真打印的质心初始约为 `(320, 220)`，随后每帧 x 坐标 ±4 变化。

## 6. 扩展方向（对接真实相机 / 更高阶功能）

- **真实采集**：将 `test_pattern` 替换为 OV5640/OV7670 的 DVP 采集模块（SCCB 配置 + 8bit 数据 + pclk/href/vsync），像素时钟改为摄像头 pclk。
- **开/闭运算**：级联两级 `line_buffer_3x3 + morph_filter`（腐蚀→膨胀 = 开运算；膨胀→腐蚀 = 闭运算），进一步去噪/填洞。
- **完整 YCbCr**：在 `rgb2gray` 基础上并行输出 Cb/Cr 分量。
- **多目标/面积**：在 `centroid` 基础上增加连通域标记或多质心输出。
- **HDMI 输出**：VGA 基础上增加 TMDS 编码/串行化（或用 HDMI IP）。
- **资源优化**：`delay_line` 为移位寄存器（约 2 万 FF）；如需省资源可改为“1 行 BRAM 行缓存 + 少量寄存器”实现同样 644 拍对齐。

## 7. 引脚对照（供核对）

| 信号 | 引脚 | 信号 | 引脚 |
|---|---|---|---|
| clk_100m | P17 | vga_r[3:0] | F5,C6,C5,B7 |
| sw[0] | P5 | vga_g[3:0] | B6,A6,A5,D8 |
| sw[1] | P4 | vga_b[3:0] | C7,E6,E5,E7 |
| vga_hs | D7 | led_run | F6 |
| vga_vs | C4 | led_target | G4 |

> 引脚基于 EGO1 常见标准整理，**请以板卡原理图为准**。
