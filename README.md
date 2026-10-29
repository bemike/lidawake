# lidawake · 合盖不休眠

合盖也能让 agent 继续跑：合盖后屏幕关掉，系统保持醒着，本机 Cursor、Claude Code 等本地 agent 可以接着干。

## 痛点

跑 vibe coding / 本机 agent 时，最烦一件事：合上盖子，电脑一睡，任务就断。很多人只能开着盖子撑着——费电、占地方，想出门也不踏实。

其实你要的很简单：合盖后屏幕关掉，系统别睡，后台继续跑。macOS 自带的 `pmset` 就能做到。本仓库把它收成开、关、查状态三步——有 Alfred 用 workflow，没有也可以用命令行。

## 你需要什么

- 一台 Mac
- Alfred（用 workflow），或终端（用 CLI）——二选一即可

## Alfred workflow

文件：[`alfred/合盖不休眠-pmset.alfredworkflow`](alfred/%E5%90%88%E7%9B%96%E4%B8%8D%E4%BC%91%E7%9C%A0-pmset.alfredworkflow)（当前打包版本 **1.2.0**，与本机正在用的安装版一致）

双击装进 Alfred 后，敲：

| 关键词 | 作用 |
|--------|------|
| `lidawake on` | 开启：`disablesleep 1` + 合盖灭屏监视 |
| `lidawake off` | 关闭：恢复合盖会休眠，并停掉灭屏监视 |
| `lidawake` | 查状态：SleepDisabled 与灭屏监视是否在跑 |

`on` 只开启功能，不会马上灭屏，屏幕照常可用；真正合上盖子时才会灭屏，系统保持醒着，agent 接着干。

状态是一行短句，监视运行时间固定显示为「X时X分X秒」，例如：`已开：合盖不休眠，监视已运行 0时2分4秒`。

### 关于管理员权限（1.1.1）

本仓库这份 workflow 走的是**窄范围免密 sudo**：`on` / `off` 调用

`sudo -n /usr/bin/pmset -a disablesleep 0|1`

需要本机事先放行（仅这两条命令），例如 `/etc/sudoers.d/bemike-lidawake`。未配置时开启会失败并提示检查该文件。

对外给别人装、或你不想改 sudoers 时，更稳妥的做法是改回「弹一次系统管理员密码」的写法（`osascript … with administrator privileges`）。免密只适合自己清楚风险之后使用：同一用户下的进程也能改这两项。

## CLI（不用 Alfred）

源码在 [`cli/`](cli/)，也可直接下 [`lidawake-cli.tar.gz`](lidawake-cli.tar.gz)。

安装：

```bash
cd cli
# 或：tar -xzf lidawake-cli.tar.gz && cd lidawake-cli
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

行为与 Alfred 版同一套：还是 `pmset disablesleep`，加上合盖灭屏监视。CLI 会优先尝试免密 sudo；不行再弹系统管理员密码框。

监视进程的启动、停止、状态都收在 `lid-display-watch.sh` 里，CLI 与 Alfred 共用同一份逻辑，也可以直接调用：`lid-display-watch.sh launch|stop|status|pids`。pid 文件固定在 `~/.local/state/lidawake/watch.pid`，不依赖 `TMPDIR`；重复 `on` 只会保留一个监视进程。

## 用完务必 off

`disablesleep` 开着时，机器不会按平时习惯睡。长期挂着伤电池，也容易误判合盖行为——下次合盖发现还在发热，多半是忘了关。

**任务跑完，立刻 `lidawake off`。** 不确定有没有关？Alfred 再敲一次 `lidawake`，或终端里 `lidawake` / `lidawake status`。

## 小结

合盖 → 灭屏 → 系统醒着 → agent 继续跑。用完 off。

依赖就是 macOS 的 `pmset`；Alfred 或 CLI，只是少打几行命令。装好后先 `lidawake on` 试一次合盖，确认灭屏且任务还在；再 `lidawake off`，确认合盖又会正常休眠。两头都通了，就可以放心用。

## 更新记录

### v1.2.0

- `on` 不再主动灭屏，只在合盖时才灭屏，开启后可继续正常操作。
- 修复 Alfred 通知偶发乱码：macOS 自带 bash 3.2 下，`$变量` 后面紧跟全角标点会吞掉首字节，现统一写成 `${变量}`。
- pid 文件固定到 `~/.local/state/lidawake/`，终端与 Alfred 的环境不同也能互相停掉监视。
- 监视进程精确匹配，不再用 `pkill -f` 误杀同名命令行；加单实例保护，重复开启不会叠加多个监视。
- `stop` 会等监视进程真正退出；`on` 会确认监视已经起来才提示成功；`off` 失败时保留监视。
- 运行时间统一为「X时X分X秒」；Alfred 状态保持短、纯一行。
- 启动、停止、状态逻辑收进 `lid-display-watch.sh`，CLI 与 Alfred 共用，三处不再各改各的。
