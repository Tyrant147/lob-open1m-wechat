#!/usr/bin/env bash
# 一次性发布到 GitHub Pages（公开仓库）
# 用法：
#   export GH_USER=你的GitHub用户名
#   export GIT_AUTHOR_NAME='你的名字'
#   export GIT_AUTHOR_EMAIL='你的邮箱'   # 建议用 GitHub 绑定邮箱
#   ./deploy-github-pages.sh
set -euo pipefail
cd "$(dirname "$0")"

: "${GH_USER:?请先 export GH_USER=你的GitHub用户名}"
: "${GIT_AUTHOR_NAME:?请先 export GIT_AUTHOR_NAME='你的名字'}"
: "${GIT_AUTHOR_EMAIL:?请先 export GIT_AUTHOR_EMAIL='你的邮箱'}"

export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

REPO_NAME="${REPO_NAME:-lob-open1m-wechat}"
SITE_URL="https://${GH_USER}.github.io/${REPO_NAME}/"

if ! command -v gh >/dev/null 2>&1; then
  echo "未找到 gh，正在用 Homebrew 安装…"
  brew install gh
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "请登录 GitHub（浏览器会弹出）："
  gh auth login -h github.com -p https -w
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -b main
fi

# 只跟踪站点相关文件；CSV/log 已被 .gitignore 排除
git add .gitignore index.html \
  case_open1m_000001_lob15_anim.html case_open1m_000001_lob15_data.js \
  case_open1m_603778_lob15_anim.html case_open1m_603778_lob15_data.js \
  公众号_开盘一分钟看懂沪深撮合.md \
  开盘一分钟盘口重建详解.md \
  沪深股票Level2字段对照.md \
  deploy-github-pages.sh

if git diff --cached --quiet; then
  echo "没有新的暂存变更。"
else
  git commit -m "Publish WeChat LOB open-1m demos for GitHub Pages."
fi

# 创建公开仓库（已存在则跳过）
if ! gh repo view "${GH_USER}/${REPO_NAME}" >/dev/null 2>&1; then
  gh repo create "${REPO_NAME}" --public --source=. --remote=origin --push
else
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/${GH_USER}/${REPO_NAME}.git"
  fi
  git push -u origin HEAD:main
fi

# 打开 Pages：从 main 分支根目录发布
gh api -X POST "repos/${GH_USER}/${REPO_NAME}/pages" \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/ \
  >/dev/null 2>&1 || \
gh api -X PUT "repos/${GH_USER}/${REPO_NAME}/pages" \
  -f build_type=legacy \
  -f source[branch]=main \
  -f source[path]=/ \
  >/dev/null 2>&1 || true

echo
echo "完成。约 1–2 分钟后打开："
echo "  ${SITE_URL}"
echo "公众号「阅读原文」填这个地址即可。"
echo
echo "若打不开：仓库 Settings → Pages → Build and deployment"
echo "  Source = Deploy from a branch"
echo "  Branch = main / (root)"
