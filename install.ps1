<#
.SYNOPSIS
  把 ls-pipeline（/ls:* 半自动 AI 循环开发流水线）安装进目标项目，适配所选 AI 编码客户端。
.DESCRIPTION
  两种 profile（见 clients/registry.md）：
    - native（claude）：装进 .claude/{commands,skills,rules}，写 CLAUDE.md 指针。
    - agents-md（其余）：写项目根 AGENTS.md（跨工具标准）+ 中性 bundle .ai/ls-pipeline/{commands,rules,skills,docs}；
      部分客户端另补装原生目录（opencode→.opencode/command，trae→.trae/rules）。
  所有 profile 都把工具链配置 seed 到项目根 ls-pipeline.config.md（不覆盖已存在）。
.PARAMETER Target
  目标项目根目录（应是 git 仓库）。
.PARAMETER Client
  编码客户端：claude | codex | opencode | trae | qoder | grok。缺省则交互选择。
.PARAMETER Force
  覆盖目标已存在的资产文件（入口文件按标记块幂等更新；config 永不覆盖）。
.EXAMPLE
  .\install.ps1 -Target C:\path\to\project -Client claude
  .\install.ps1 -Target C:\path\to\project            # 交互选择客户端
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string] $Target,
  [ValidateSet('claude','codex','opencode','trae','qoder','grok')] [string] $Client,
  [switch] $Force
)

$ErrorActionPreference = "Stop"
$repo   = $PSScriptRoot
$assets = Join-Path $repo "assets\.claude"
$docs   = Join-Path $repo "docs"
$tmpl   = Join-Path $repo "templates"

# ---- 客户端注册表（单一事实来源镜像自 clients/registry.md）----
$Clients = @{
  claude   = @{ Profile='native';    Entry='CLAUDE.md'; CmdDir='.claude/commands'; CmdFlatten=$false; RulesDir='.claude/rules/common'; SkillsDir='.claude/skills' }
  opencode = @{ Profile='agents-md'; Entry='AGENTS.md'; CmdDir='.opencode/command'; CmdFlatten=$true;  RulesDir='';                    SkillsDir='' }
  trae     = @{ Profile='agents-md'; Entry='AGENTS.md'; CmdDir='';                  CmdFlatten=$false; RulesDir='.trae/rules';         SkillsDir='' }
  codex    = @{ Profile='agents-md'; Entry='AGENTS.md'; CmdDir='';                  CmdFlatten=$false; RulesDir='';                    SkillsDir='' }
  qoder    = @{ Profile='agents-md'; Entry='AGENTS.md'; CmdDir='';                  CmdFlatten=$false; RulesDir='';                    SkillsDir='' }
  grok     = @{ Profile='agents-md'; Entry='AGENTS.md'; CmdDir='';                  CmdFlatten=$false; RulesDir='';                    SkillsDir='' }
}

# ---- helpers ----
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Read-Text([string]$p) { if (Test-Path $p) { [System.IO.File]::ReadAllText($p) } else { "" } }
function Write-Text([string]$p, [string]$c) {
  $dir = Split-Path $p -Parent; if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($p, $c, $utf8)
}
function Copy-File([string]$src, [string]$dst) {
  $dir = Split-Path $dst -Parent; New-Item -ItemType Directory -Force -Path $dir | Out-Null
  if ((Test-Path $dst) -and (-not $Force)) { $script:skipped++; Write-Host "  skip (exists): $($dst.Substring($TargetRoot.Length+1))" -ForegroundColor DarkGray }
  else { Copy-Item $src $dst -Force; $script:copied++; Write-Host "  copy: $($dst.Substring($TargetRoot.Length+1))" -ForegroundColor Green }
}
# 幂等地把标记块写入/更新入口文件（CLAUDE.md / AGENTS.md），保留用户其余内容
function Patch-Entry([string]$path, [string]$block) {
  $existing = Read-Text $path
  $beginRe = '(?s)<!-- ls-pipeline:begin.*?<!-- ls-pipeline:end -->'
  if ($existing -match $beginRe) {
    # 用 MatchEvaluator 回调替换，避免 $block 中的 $ 被当作替换模式转义
    $new = [System.Text.RegularExpressions.Regex]::Replace($existing, $beginRe, { param($m) $block })
    Write-Text $path $new
    Write-Host "  update: $((Split-Path $path -Leaf))（ls-pipeline 区块已更新，其余内容保留）" -ForegroundColor Cyan
  } elseif ($existing.Trim().Length -gt 0) {
    Write-Text $path ($existing.TrimEnd() + "`r`n`r`n" + $block + "`r`n")
    Write-Host "  append: $((Split-Path $path -Leaf))（追加 ls-pipeline 区块）" -ForegroundColor Cyan
  } else {
    Write-Text $path ($block + "`r`n")
    Write-Host "  create: $((Split-Path $path -Leaf))" -ForegroundColor Green
  }
}

# ---- 1. 校验目标 ----
if (-not (Test-Path $Target -PathType Container)) { throw "目标目录不存在: $Target" }
$TargetRoot = (Resolve-Path $Target).Path
if (-not (Test-Path (Join-Path $TargetRoot ".git"))) {
  Write-Warning "目标不是 git 仓库（未找到 .git）。流水线的分支/归档依赖 git，建议先 git init。"
}

# ---- 2. 选择客户端 ----
if (-not $Client) {
  Write-Host "选择目标 AI 编码客户端：" -ForegroundColor Cyan
  $order = @('claude','codex','opencode','trae','qoder','grok')
  for ($i=0; $i -lt $order.Count; $i++) { Write-Host ("  {0}) {1}" -f ($i+1), $order[$i]) }
  $sel = Read-Host "输入序号 (1-$($order.Count))，默认 1=claude"
  if ([string]::IsNullOrWhiteSpace($sel)) { $Client = 'claude' }
  else { $idx = [int]$sel - 1; if ($idx -lt 0 -or $idx -ge $order.Count) { throw "无效选择: $sel" } $Client = $order[$idx] }
}
$cfg = $Clients[$Client]
Write-Host "`n客户端: $Client  (profile=$($cfg.Profile), 入口=$($cfg.Entry))" -ForegroundColor Cyan

$script:copied = 0; $script:skipped = 0

# ---- 3. 安装资产 ----
if ($cfg.Profile -eq 'native') {
  # Claude：原生 .claude 布局
  Get-ChildItem -Recurse -File $assets | ForEach-Object {
    $rel = $_.FullName.Substring($assets.Length).TrimStart('\','/')
    Copy-File $_.FullName (Join-Path (Join-Path $TargetRoot ".claude") $rel)
  }
} else {
  # 通用：中性 bundle .ai/ls-pipeline/{commands,rules,skills,docs}
  $bundle = Join-Path $TargetRoot ".ai\ls-pipeline"
  Copy-Item (Join-Path $assets "commands") (Join-Path $bundle "commands") -Recurse -Force
  Copy-Item (Join-Path $assets "rules")    (Join-Path $bundle "rules")    -Recurse -Force
  Copy-Item (Join-Path $assets "skills")   (Join-Path $bundle "skills")   -Recurse -Force
  Copy-Item $docs                          (Join-Path $bundle "docs")     -Recurse -Force
  Write-Host "  bundle: .ai\ls-pipeline\{commands,rules,skills,docs}" -ForegroundColor Green
  $script:copied++

  # 原生 bonus：命令目录（扁平化）
  if ($cfg.CmdDir) {
    foreach ($grp in 'ls','opsx') {
      Get-ChildItem -File (Join-Path $assets "commands\$grp") | ForEach-Object {
        $name = if ($cfg.CmdFlatten) { "$grp-$($_.Name)" } else { $_.Name }
        Copy-File $_.FullName (Join-Path (Join-Path $TargetRoot $cfg.CmdDir) $name)
      }
    }
  }
  # 原生 bonus：规则目录（如 trae/.trae/rules）
  if ($cfg.RulesDir) {
    Get-ChildItem -File (Join-Path $assets "rules\common") | ForEach-Object {
      Copy-File $_.FullName (Join-Path (Join-Path $TargetRoot $cfg.RulesDir) $_.Name)
    }
  }
}

# ---- 4. 入口文件（CLAUDE.md / AGENTS.md）----
$entryTmpl = if ($cfg.Entry -eq 'CLAUDE.md') { Join-Path $tmpl "CLAUDE.md" } else { Join-Path $tmpl "AGENTS.md" }
$block = (Read-Text $entryTmpl).TrimEnd()
Patch-Entry (Join-Path $TargetRoot $cfg.Entry) $block

# ---- 5. seed 根配置（永不覆盖）----
$destConfig = Join-Path $TargetRoot "ls-pipeline.config.md"
if (Test-Path $destConfig) { Write-Host "  keep (exists): ls-pipeline.config.md（保留你已填的配置）" -ForegroundColor DarkGray }
else { Copy-Item (Join-Path $tmpl "ls-pipeline.config.md") $destConfig -Force; Write-Host "  seed: ls-pipeline.config.md（模板，请填写）" -ForegroundColor Yellow }

Write-Host "`n安装完成：copied=$script:copied, skipped=$script:skipped" -ForegroundColor Cyan

# ---- 6. openspec CLI 检测 ----
$hasOpenspec = $null -ne (Get-Command openspec -ErrorAction SilentlyContinue)
if ($hasOpenspec) { Write-Host "[✓] 检测到 openspec CLI" -ForegroundColor Green }
else { Write-Host "[!] 未检测到 openspec CLI —— spec/归档层需要它：npm i -g openspec" -ForegroundColor Yellow }

# ---- 7. 后续步骤 ----
Write-Host "`n后续三步：" -ForegroundColor Cyan
Write-Host "  1) 编辑 $destConfig —— 填 build / unit-test / integration-test 等（参考 docs/examples/config.*.md）"
Write-Host "  2) 项目根初始化 openspec：openspec init"
if ($cfg.Profile -eq 'native') {
  Write-Host "  3) 开跑：/ls:dev <需求>   或   /ls:clarify <需求>"
} elseif ($cfg.CmdDir -and $cfg.CmdFlatten) {
  Write-Host "  3) 开跑：原生斜杠命令为 /ls-dev、/ls-clarify …（已装进 $($cfg.CmdDir)）；或直接让 AI 按 AGENTS.md 执行 /ls:dev"
} else {
  Write-Host "  3) 开跑：让 AI 读 AGENTS.md 并执行 —— 说 「/ls:dev 需求」 或 「按 ls-pipeline 开始做 需求」"
}
