# lidawake · 合盖不休眠

合盖后屏幕关掉，系统保持醒着，本机 agent（Cursor、Claude Code 等）可以继续跑。

## 痛点

跑本机 vibe coding / 本地 agent 时，合上盖子 Mac 一睡，任务就断。很多人只能开着盖子撑着——费电、占地方。其实只要：合盖灭屏，但别让系统休眠。

底层用的是 macOS 自带的 `pmset -a disablesleep`，本仓库把它收成两种入口：Alfred workflow，以及命令行 `lidawake`。

## 你需要什么

- 一台 Mac
- Alfred（用 workflow），或终端（用 CLI）——二选一即可

## Alfred workflow

文件：[`alfred/合盖不休眠-pmset.alfredworkflow`](alfred/合盖不休眠-pmset.alfredworkflow)

双击安装到 Alfred 后，敲：

| 关键词 | 作用 |
|--------|------|
| `lidawake on` | 开启合盖不休眠，并启动合盖灭屏监视 |
| `lidawake off` | 关闭，恢复合盖会休眠 |
| `lidawake` | 查看状态 |

开的时候可能先灭一下屏，属正常。合上盖子后屏幕应灭，系统保持醒着。

**开关时系统会要一次管理员密码。** 这是默认、也更安全的用法。

## CLI（不用 Alfred）

源码在 [`cli/`](cli/)。安装：

```bash
cd cli
chmod +x install.sh bin/*
./install.sh
```

默认装到 `/usr/local/bin/lidawake`；没有写权限则装到 `~/.local/bin`（请确认该目录在 `PATH` 里）。

用法：

```bash
lidawake on       # 开启
lidawake off      # 关闭（用完务必关）
lidawake status   # 状态（也可直接 lidawake）
```

行为与 Alfred 版同一套。**`on` / `off` 需要管理员权限**（会弹系统密码框；若本机已自行配置过窄范围免密 sudo，则可静默执行）。

## 用完务必 off

`disablesleep` 开着时，机器不会按平时习惯睡。长期挂着伤电池，也容易误判合盖行为。**任务跑完立刻 `lidawake off`。**

不确定有没有关？再敲一次 `lidawake` / `lidawake status`。

## 许可说明

个人工具，按需使用。改系统睡眠行为有风险，请自行判断散热与电量。
