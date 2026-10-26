# lidawake

合盖不休眠 CLI：合盖后屏幕关闭，系统保持醒着，本机 agent 可继续跑。

## 需要

- macOS
- 管理员权限（`on` / `off` 时系统会要密码）

## 安装

```bash
chmod +x install.sh bin/*
./install.sh
```

默认装到 `/usr/local/bin/lidawake`；没有写权限则装到 `~/.local/bin`。

## 用法

```bash
lidawake on       # 开启
lidawake off      # 关闭（用完务必关）
lidawake status   # 状态（或直接 lidawake）
```

## 说明

- 底层是 `pmset -a disablesleep`
- `on` 会启动合盖灭屏监视；开的时候可能先灭一下屏
- 用完请 `lidawake off`，长期开着伤电池、也容易误判合盖行为
