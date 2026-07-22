#!/usr/bin/env bash
# 把 ls-pipeline（/ls:* 半自动 AI 循环开发流水线）安装进目标项目，适配所选 AI 编码客户端。
# 用法：
#   ./install.sh <target-project-dir> [--client <name>] [--force]
#   client ∈ claude | codex | opencode | trae | qoder | grok（缺省交互选择）
# 两种 profile（详见 README「维护者参考」）：native(claude) / agents-md(其余)。
# 工具链配置 seed 到项目根 ls-pipeline.config.md（不覆盖已存在）。
set -euo pipefail

TARGET=""; CLIENT=""; FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --client) CLIENT="${2:-}"; shift 2;;
    --force)  FORCE=1; shift;;
    *)        TARGET="$1"; shift;;
  esac
done

[[ -z "$TARGET" ]] && { echo "用法: ./install.sh <target-project-dir> [--client <name>] [--force]" >&2; exit 1; }
[[ -d "$TARGET" ]] || { echo "目标目录不存在: $TARGET" >&2; exit 1; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$REPO/assets/.claude"
DOCS="$REPO/docs"
TMPL="$REPO/templates"
TARGET="$(cd "$TARGET" && pwd)"
[[ -d "$TARGET/.git" ]] || echo "[!] 目标不是 git 仓库（未找到 .git）。分支/归档依赖 git，建议先 git init。" >&2

# ---- 选择客户端 ----
ORDER=(claude codex opencode trae qoder grok)
if [[ -z "$CLIENT" ]]; then
  echo "选择目标 AI 编码客户端："
  for i in "${!ORDER[@]}"; do echo "  $((i+1))) ${ORDER[$i]}"; done
  read -r -p "输入序号 (1-${#ORDER[@]})，默认 1=claude: " sel
  if [[ -z "$sel" ]]; then CLIENT=claude
  else CLIENT="${ORDER[$((sel-1))]:-}"; [[ -z "$CLIENT" ]] && { echo "无效选择: $sel" >&2; exit 1; }; fi
fi

# ---- 客户端映射表（本表即运行时事实来源；说明与扩展见 README「维护者参考」）----
# 字段: profile|entry|cmddir|cmdflatten|rulesdir
case "$CLIENT" in
  claude)   PROFILE=native;    ENTRY=CLAUDE.md; CMDDIR=".claude/commands"; CMDFLATTEN=0; RULESDIR=".claude/rules/common"; SKILLSDIR=".claude/skills";;
  opencode) PROFILE=agents-md; ENTRY=AGENTS.md; CMDDIR=".opencode/command"; CMDFLATTEN=1; RULESDIR="";                    SKILLSDIR="";;
  trae)     PROFILE=agents-md; ENTRY=AGENTS.md; CMDDIR="";                  CMDFLATTEN=0; RULESDIR=".trae/rules";          SKILLSDIR="";;
  codex|qoder|grok) PROFILE=agents-md; ENTRY=AGENTS.md; CMDDIR=""; CMDFLATTEN=0; RULESDIR=""; SKILLSDIR="";;
  *) echo "未知客户端: $CLIENT" >&2; exit 1;;
esac
echo ""; echo "客户端: $CLIENT  (profile=$PROFILE, 入口=$ENTRY)"

copied=0; skipped=0
copy_file() { # $1 src  $2 dst
  mkdir -p "$(dirname "$2")"
  if [[ -e "$2" && "$FORCE" -ne 1 ]]; then skipped=$((skipped+1)); echo "  skip (exists): ${2#$TARGET/}";
  else cp "$1" "$2"; copied=$((copied+1)); echo "  copy: ${2#$TARGET/}"; fi
}
patch_entry() { # $1 path  $2 blockfile
  local path="$1" block; block="$(cat "$2")"
  if [[ -f "$path" ]] && grep -q 'ls-pipeline:begin' "$path"; then
    # 删除旧标记块后追加新块（保留其余内容）
    local tmp; tmp="$(mktemp)"
    awk 'BEGIN{skip=0} /ls-pipeline:begin/{skip=1} skip==0{print} /ls-pipeline:end/{skip=0}' "$path" > "$tmp"
    printf '%s\n\n%s\n' "$(sed -e 's/[[:space:]]*$//' "$tmp")" "$block" > "$path"
    rm -f "$tmp"; echo "  update: $(basename "$path")（ls-pipeline 区块已更新，其余保留）"
  elif [[ -s "$path" ]]; then
    printf '%s\n\n%s\n' "$(cat "$path")" "$block" > "$path"; echo "  append: $(basename "$path")（追加 ls-pipeline 区块）"
  else
    printf '%s\n' "$block" > "$path"; echo "  create: $(basename "$path")"
  fi
}

# ---- 安装资产 ----
if [[ "$PROFILE" == "native" ]]; then
  while IFS= read -r -d '' f; do
    rel="${f#$ASSETS/}"; copy_file "$f" "$TARGET/.claude/$rel"
  done < <(find "$ASSETS" -type f -print0)
else
  BUNDLE="$TARGET/.ai/ls-pipeline"
  mkdir -p "$BUNDLE"
  cp -R "$ASSETS/commands" "$BUNDLE/commands"
  cp -R "$ASSETS/rules"    "$BUNDLE/rules"
  cp -R "$ASSETS/skills"   "$BUNDLE/skills"
  cp -R "$DOCS"            "$BUNDLE/docs"
  echo "  bundle: .ai/ls-pipeline/{commands,rules,skills,docs}"; copied=$((copied+1))
  if [[ -n "$CMDDIR" ]]; then
    for grp in ls opsx; do
      for f in "$ASSETS/commands/$grp"/*.md; do
        [[ -e "$f" ]] || continue
        if [[ "$CMDFLATTEN" -eq 1 ]]; then name="$grp-$(basename "$f")"; else name="$(basename "$f")"; fi
        copy_file "$f" "$TARGET/$CMDDIR/$name"
      done
    done
  fi
  if [[ -n "$RULESDIR" ]]; then
    for f in "$ASSETS/rules/common"/*.md; do copy_file "$f" "$TARGET/$RULESDIR/$(basename "$f")"; done
  fi
fi

# ---- 入口文件 ----
if [[ "$ENTRY" == "CLAUDE.md" ]]; then patch_entry "$TARGET/CLAUDE.md" "$TMPL/CLAUDE.md"; else patch_entry "$TARGET/AGENTS.md" "$TMPL/AGENTS.md"; fi

# ---- seed 根配置 ----
dest_config="$TARGET/ls-pipeline.config.md"
if [[ -e "$dest_config" ]]; then echo "  keep (exists): ls-pipeline.config.md（保留你已填的配置）";
else cp "$TMPL/ls-pipeline.config.md" "$dest_config"; echo "  seed: ls-pipeline.config.md（模板，请填写）"; fi

echo ""; echo "安装完成：copied=$copied, skipped=$skipped"

# ---- openspec 检测 ----
echo ""
if command -v openspec >/dev/null 2>&1; then echo "[✓] 检测到 openspec CLI"; else echo "[!] 未检测到 openspec CLI —— spec/归档层需要它：npm i -g openspec"; fi

# ---- 后续步骤 ----
echo ""; echo "后续三步："
echo "  1) 编辑 $dest_config —— 填 build / unit-test / integration-test 等（参考 docs/examples/config.*.md）"
echo "  2) 项目根初始化 openspec：openspec init"
if [[ "$PROFILE" == "native" ]]; then
  echo "  3) 开跑：/ls:dev <需求>   或   /ls:clarify <需求>"
elif [[ -n "$CMDDIR" && "$CMDFLATTEN" -eq 1 ]]; then
  echo "  3) 开跑：原生斜杠命令为 /ls-dev、/ls-clarify …（已装进 $CMDDIR）；或让 AI 按 AGENTS.md 执行 /ls:dev"
else
  echo "  3) 开跑：让 AI 读 AGENTS.md 并执行 —— 说 “/ls:dev <需求>” 或 “按 ls-pipeline 开始做 <需求>”"
fi
