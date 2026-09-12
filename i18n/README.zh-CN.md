<div align="center">

# ⚡ JA IQ5 Reflash

**工业级高通骁龙芯片多端口固件刷机与救砖工具**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20x64-0078D6?logo=windows&logoColor=white)](https://microsoft.com)
[![Release](https://img.shields.io/badge/Release-v1.2.1-00C853?logo=github)](https://github.com/jatechvn/JA_IQ5_Flash/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<p align="center">
  <a href="../README.md">🇺🇸 English</a> • <a href="README.vi.md">🇻🇳 Tiếng Việt</a> • <b>🇨🇳 中文</b>
</p>

*基于 Flutter & Dart 打造的工业级 Windows 桌面端应用，专为高通 IQ5 设备量身定制，支持最多 8 台设备在 EDL (9008) 模式下并发刷机、ADB/Fastboot 智能调度与现代化 Bento 毛玻璃界面。*

</div>

---

## 📑 目录

- [概览](#-概览)
- [核心特性](#-核心特性)
- [硬件配置分级架构 (Hardware Tier)](#-硬件配置分级架构-hardware-tier)
- [目录结构与技术架构](#-目录结构与技术架构)
- [快速入门指南](#-快速入门指南)
  - [方式 A: 运行独立免安装包 (推荐)](#方式-a-运行独立免安装包-推荐)
  - [方式 B: 从源码编译](#方式-b-从源码编译)
- [系统配置与个性化选项](#-系统配置与个性化选项)
- [版本变更历史 (Changelog)](#-版本变更历史-changelog)
- [开源协议与作者](#-开源协议与作者)

---

## 🌟 概览

**JA IQ5 Reflash** 是一款专为高通骁龙（Qualcomm Snapdragon，尤其是 IQ5 系列）硬件设备打造的专业级固件刷写与紧急救砖工具。适用于工厂生产线、产测工程师以及售后维修人员，支持通过高通紧急下载模式 (EDL 9008) 同时为 **8 台设备** 并发刷写完整固件。

本工具具备全自动 3 阶段工作流 (Fastboot → ADB → EDL → Flash → Reboot)、独立的双列监控布局、流光环绕选卡动画、防溢出回弹跑马灯路径框，以及基于硬件配置智能调整的 GPU 渲染优化体系，在保障极致可靠性的同时带来现代化的人机交互体验。

---

## 🚀 核心特性

### ⚡ 多设备并行 EDL 刷机 (最高 8 个 COM 端口)
- 支持同时管理并在独立 COM 端口 (USB\VID_05C6&PID_9008) 上并行刷写多达 **8 台高通设备**。
- 内置 h_loader.exe 与 Sahara Protocol 驱动引擎，实时解析 stdout 输出流，精确展示每台设备的百分比进度与分区传输速率。
- 完整支持高通标准三件套分区刷写：awprogram_unsparse0.xml、patch0.xml 和 prog_firehose_ddr.elf。

### 📱 独立双列双工作流布局 (Two-Column Layout)
- **左列 (EDL 9008 专区)**: 刷机优先级核心区域，直观显示每台设备的刷机进度条、实时传输速率、分区名称及单个设备的中止/重启操作。
- **右列 (ADB / Fastboot 专区)**: 实时捕获已连接的 Android 设备，智能识别设备型号与授权状态，并提供一键将所有设备重启至 EDL 模式的快捷按钮。

### 💾 3 插槽智能固件选择器与流光环绕光效 (RotatingGlowBorder)
- 预设 3 个独立固件插槽，支持快捷无缝切换：
  - **插槽 1**: 原厂官方固件 (FACTORY ROM • 天蓝色)
  - **插槽 2**: 客户定制固件 (USER ROM • 翡翠绿)
  - **插槽 3**: 工程测试与校准固件 (DIAG / TEST • 琥珀金)
- **彗星流光环绕动画**: 选中的插槽卡片边缘被动态循环旋转的高亮光束环绕，形成强烈的视觉聚焦。
- **自适应主题卡片表面**: 浅色模式采用高对比度乳白磨砂玻璃表面 (符合 WCAG AAA 无障碍标准)；深色模式采用赛博朋克深灰色发光玻璃。

### 🔄 非对称回弹跑马灯路径输入框 (GlassBouncePathField)
- 彻底解决超长目录路径在紧凑界面下被截断或溢出的问题。
- **非对称 Ping-Pong 跑马灯**: 在起始位置停留 1.4 秒方便辨认盘符，以 40 px/s 速度平滑右移以完整展示深层目录，在终点位置停留 1.4 秒方便看清目标文件夹，随后平稳折返。
- **瞬时焦点切换**: 鼠标点击即可平滑切换为标准 TextField，支持直接键盘输入、光标选择与 Ctrl+V 剪贴板快速粘贴。

### 🎛️ 硬件感知性能分析分级 (Hardware Tier Profiling)
- 自动检测 CPU 逻辑核心数量与 Windows 系统版本，智能匹配最佳渲染级别：
  - **Ultra 极致模式 (120 FPS)**: 启用双通道背景高斯模糊、动态 Mesh Orbs 发光光球与高帧率流光循环，专为高性能台式机设计。
  - **Balanced 均衡模式 (60 FPS)**: 为主流办公笔记本电脑优化，保持流畅的毛玻璃质感。
  - **Lite 轻量模式 (零延迟)**: 自动跳过 BackdropFilter 卷积渲染，关闭动态光球，改用半透明亚克力卡片，保障虚拟机与低配电脑极速响应。
- 支持通过顶部栏按钮或设置弹窗进行一键循环切换。

### 🎨 Windows 11 Fluent 毛玻璃与实时 4 轴滑块调节
- 实时调节卡片模糊度 (Card Blur)、卡片不透明度 (Card Opacity)、弹窗模糊度 (Dialog Blur) 与弹窗不透明度 (Dialog Opacity)。
- 采用 Skia/Impeller GPU 栅格化纹理缓存 (RepaintBoundary)，单帧渲染耗时低至 0.1ms。

### 🛡️ 硬件机器码绑定 (HMAC-SHA256) 与局域网自动同步
- 基于计算机唯一硬件机器码 (HWID) 进行加密授权验证。
- 支持在局域网内通过指定共享文件路径自动检索并激活许可证。

### 🌐 实时三语国际化 (EN / VI / CN)
- 无需重启应用，即可通过右上角国旗图标实时切换界面语言：
  - 🇺🇸 英语 (English)
  - 🇻🇳 越南语 (Tiếng Việt)
  - 🇨🇳 简体中文

---

## 📊 硬件分级架构对照表

| 指标 / 参数 | 🚀 Ultra 极致档 | ⚖️ Balanced 均衡档 | 🍃 Lite 轻量档 |
| :--- | :--- | :--- | :--- |
| **推荐硬件环境** | $\ge 8$ CPU 核心 / 独立显卡 | 4 – 7 CPU 核心 / 笔记本 | $< 4$ CPU 核心 / 虚拟机 |
| **卡片背景模糊度** | 20.0 px (双通道模糊) | 14.0 px (单通道模糊) | 0.0 px (跳过模糊通道) |
| **卡片不透明度** | 25% 磨砂玻璃 | 32% 半透明玻璃 | 78% 高对比度亚克力 |
| **背景动态发光球** | 启用 (显存纹理缓存) | 启用 (显存纹理缓存) | 完全禁用 (0% 资源消耗) |
| **流光旋转光效** | 120 FPS / 60 FPS | 60 FPS | 静态边缘 / 节能模式 |

---

## ⚡ 快速入门指南

### 方式 A: 运行独立免安装包 (推荐)
1. 从 [Releases](https://github.com/jatechvn/JA_IQ5_Flash/releases) 页面下载最新发布包 `JA_IQ5_Flash_v1.2.1_Windows_x64.zip`。
2. 解压到任意本地目录（例如 `D:\Tools\JA_IQ5_Flash\`）。
3. 双击运行 `ja_iq5_flash.exe`。
4. 确保 Windows 系统已正确安装高通 QDLoader 9008 驱动以及 Android USB 驱动。

### 方式 B: 从源码编译
运行环境要求:
- Flutter SDK $\ge 3.22.0$ (Dart $\ge 3.4.0$)
- Visual Studio 2022 并勾选“使用 C++ 的桌面开发”工作负载
- Windows 10/11 x64 操作系统

```bash
# 1. 克隆代码仓库
git clone https://github.com/jatechvn/JA_IQ5_Flash.git
cd JA_IQ5_Flash

# 2. 拉取 Flutter 依赖包
flutter pub get

# 3. 运行自动化测试套件
flutter test

# 4. 一键编译与打包 Release 版本
build.bat
```

编译出的独立可执行程序和打包 ZIP 文件将自动生成于 `dist/` 目录下。

---

## 📜 版本变更历史 (Changelog)

完整历史记录请参阅 [CHANGELOG.md](../CHANGELOG.md)。

- **v1.2.1 (2026-09-12)**:
  - Bento 卡片模糊度与不透明度滑块实现实时无缝响应预览（遵循 MES Tool 架构标准）。
  - 接入全局 `ChangeNotifierProvider` 架构，全面采用 `context.watch<AppTheme>()`。
  - 模糊度为 0 px 时自动跳过 GPU `BackdropFilter` 渲染管线（低配 Lite 节能模式）。
  - 为 ROM 插槽与双列容器提供智能动态半透明度比例缩放。
  - 设置弹窗提供完备的取消回退（Cancel Rollback）及向 `config.ini` 持久化机制。
  - 新增第 5 项 Bento 毛玻璃用户指南说明，支持英、越、中三语。
  - 全套 43 项自动化单元与 UI 测试 100% 通过。
- **v1.2.0 (2026-09-12)**:
  - 引入专用的独立双列布局，分别呈现 EDL 9008 与 ADB/Fastboot 设备队列。
  - 搭载 3 插槽固件选择器与全动态彗星流光外框 (RotatingGlowBorder)。
  - 采用非对称回弹跑马灯路径输入框 (GlassBouncePathField)。
  - 深度集成硬件配置自动分析与分级系统 (Ultra, Balanced, Lite)。
  - 针对浅色明亮模式进行高对比度重构，卡片与文字对比度达到 WCAG AAA 标杆。
  - 优化 GPU 栅格化缓存，保证复杂毛玻璃动效稳定运行于 120 FPS。

---

## 📄 开源协议与作者

- **作者**: JATech VN / John Alaa
- **官网**: [https://jatechvn.github.io/](https://jatechvn.github.io/)
- **GitHub 仓库**: [https://github.com/jatechvn/JA_IQ5_Flash](https://github.com/jatechvn/JA_IQ5_Flash)
- **开源许可证**: 本项目采用 [MIT License](../LICENSE) 开源协议。
