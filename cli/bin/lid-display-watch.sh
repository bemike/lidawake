#!/bin/bash
# lid-display-watch.sh — lidawake 的灭屏监视 + 进程管理（CLI / Alfred / 打包副本共用，三处必须一致）
# 无参数  : 运行监视循环（SleepDisabled=1 期间，合盖则灭屏，系统保持醒着）
# launch  : 脱离终端启动监视（已在跑则什么都不做）；成功返回 0
# stop    : 停掉所有监视进程并清理 pid 文件
# status  : 输出一行状态（运行时间固定为「X时X分X秒」）
# pids    : 列出监视进程 pid
# 注意：不使用 TMPDIR；pid 文件固定在 ~/.local/state/lidawake，终端/Alfred 环境不同也一致。
# 注意：bash 3.2 下 $var 后面紧跟中文标点会吞字节（乱码），变量一律写 ${var}。
LOG="$HOME/Library/Logs/lidawake.log"
STATE_DIR="$HOME/.local/state/lidawake"
PIDFILE="$STATE_DIR/watch.pid"
SELF="$(cd -P "$(dirname "$0")" && pwd)/$(basename "$0")"

log() { echo "$(date '+%F %T') [pid $$] $*" >> "$LOG"; }

# 只匹配「/bin/bash <路径>/lid-display-watch.sh」这种无参数的监视进程：
# 不会匹配 bash -c "…lid-display-watch.sh…"、本脚本的子命令、编辑器/tail 等；
# 也排除 $(...) 产生的同名子 shell（父进程也匹配的不算）。
find_pids() {
  /bin/ps -axo pid=,ppid=,command= 2>/dev/null | /usr/bin/awk -v me="$$" '
    {
      if ($3 !~ /(^|\/)bash$/ || $4 ~ /^-/ || $0 !~ /\/lid-display-watch\.sh[ ]*$/) next
      if ($1 == me) next
      p[++n] = $1; pp[$1] = $2
    }
    END { for (i = 1; i <= n; i++) if (!(pp[p[i]] in pp)) print p[i] }'
}

# ps etime 格式 [[DD-]HH:]MM:SS -> X时X分X秒（一小时以上同格式，天数折进小时）
fmt_etime() {
  echo "$1" | /usr/bin/awk '{
    e = $0; d = 0; h = 0
    if (index(e, "-")) { split(e, a, "-"); d = a[1]; e = a[2] }
    n = split(e, t, ":")
    if (n == 3) { h = t[1]; m = t[2]; s = t[3] } else { m = t[1]; s = t[2] }
    printf "%d时%d分%d秒", d * 24 + h, m, s
  }'
}

cmd_stop() {
  local pids i
  pids=$(find_pids)
  if [ -n "$pids" ]; then
    kill $pids 2>/dev/null || true
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
      [ -z "$(find_pids)" ] && break
      /bin/sleep 0.2
    done
    pids=$(find_pids)
    if [ -n "$pids" ]; then kill -9 $pids 2>/dev/null || true; fi
  fi
  rm -f "$PIDFILE" /tmp/lidawake-display-watch.pid /tmp/lidawake-display-watch.start
  if [ -n "${TMPDIR:-}" ]; then rm -f "${TMPDIR%/}/lidawake-display-watch.pid" "${TMPDIR%/}/lidawake-display-watch.start"; fi
  return 0
}

cmd_launch() {
  local i
  [ -x "$SELF" ] || return 1
  if [ -n "$(find_pids)" ]; then return 0; fi
  /usr/bin/perl -MPOSIX -e 'POSIX::setsid(); exec { $ARGV[0] } @ARGV' "$SELF" </dev/null >/dev/null 2>&1 &
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25; do
    /bin/sleep 0.2
    if [ -n "$(find_pids)" ] && [ -s "$PIDFILE" ]; then return 0; fi
  done
  return 1
}

cmd_status() {
  local val pids n pid pf et up line
  val=$(/usr/bin/pmset -g 2>/dev/null | /usr/bin/awk '/SleepDisabled/{print $2; exit}')
  pids=$(find_pids)
  n=0; pid=""
  if [ -n "$pids" ]; then
    n=$(echo "$pids" | /usr/bin/wc -l | /usr/bin/tr -d ' ')
    pid=$(echo "$pids" | /usr/bin/head -n 1)
    pf=$(cat "$PIDFILE" 2>/dev/null || true)
    if [ -n "$pf" ] && echo "$pids" | /usr/bin/grep -qx "$pf"; then pid="$pf"; fi
  fi
  up="未知"
  if [ -n "$pid" ]; then
    et=$(/bin/ps -o etime= -p "$pid" 2>/dev/null | /usr/bin/tr -d ' ')
    if [ -n "$et" ]; then up=$(fmt_etime "$et"); fi
  fi
  if [ "$val" = "1" ]; then
    if [ -n "$pid" ]; then
      line="已开：合盖不休眠，监视已运行 ${up}"
    else
      line="已开，但监视没在跑，合盖不会灭屏"
    fi
  elif [ "$val" = "0" ]; then
    if [ -n "$pid" ]; then
      line="已关，但监视还在跑，请再 off 一次"
    else
      line="已关：合盖会休眠"
    fi
  else
    line="状态未知（SleepDisabled=${val:-空}）"
  fi
  if [ "$n" -gt 1 ]; then line="${line}；有${n}个监视进程"; fi
  echo "$line"
}

run_watch() {
  local old closed state sd reason
  mkdir -p "$STATE_DIR" "$(dirname "$LOG")" 2>/dev/null || true

  # keep only the last 500 log lines
  if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 500 ]; then
    tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  fi

  # 单实例：noclobber 原子创建 pid 文件；已有且是活着的监视进程就退出
  if ! ( set -C; echo $$ > "$PIDFILE" ) 2>/dev/null; then
    old=$(cat "$PIDFILE" 2>/dev/null || true)
    if [ -n "$old" ] && find_pids | /usr/bin/grep -qx "$old"; then
      log "already running (pid ${old}), exit"
      exit 0
    fi
    rm -f "$PIDFILE"
    if ! ( set -C; echo $$ > "$PIDFILE" ) 2>/dev/null; then
      log "cannot create pidfile, exit"
      exit 1
    fi
  fi

  log "start (ppid=${PPID})"
  reason="unknown"
  on_exit() {
    log "exit: ${reason}"
    if [ "$(cat "$PIDFILE" 2>/dev/null)" = "$$" ]; then rm -f "$PIDFILE"; fi
  }
  trap 'reason="SIGTERM"; exit 0' TERM
  trap 'reason="SIGINT"; exit 0' INT
  trap 'reason="SIGHUP (terminal/session closed)"; exit 0' HUP
  trap on_exit EXIT

  closed=0
  while true; do
    state=$(ioreg -r -k AppleClamshellState -d 4 2>/dev/null | awk -F'= ' '/"AppleClamshellState"/{gsub(/[ ;]/,"",$2); print $2; exit}')
    if [ "$state" = "Yes" ]; then
      if [ "$closed" != "1" ]; then
        /usr/bin/pmset displaysleepnow >/dev/null 2>&1 || true
        closed=1
        log "lid closed -> display sleep"
      fi
    else
      if [ "$closed" = "1" ]; then log "lid opened"; fi
      closed=0
    fi
    sd=$(/usr/bin/pmset -g 2>/dev/null | awk '/SleepDisabled/{print $2; exit}')
    if [ "$sd" = "0" ]; then
      reason="SleepDisabled=0 (turned off)"
      exit 0
    fi
    # sleep 放后台再 wait：收到 TERM 立刻响应，不用等满 2 秒
    /bin/sleep 2 &
    wait $!
  done
}

case "${1:-run}" in
  run) run_watch ;;
  launch) cmd_launch ;;
  stop) cmd_stop ;;
  status) cmd_status ;;
  pids) find_pids ;;
  *) echo "用法: lid-display-watch.sh [launch|stop|status|pids]" >&2; exit 2 ;;
esac
