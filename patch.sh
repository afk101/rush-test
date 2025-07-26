#!/bin/bash

# 加载 .env 文件中的环境变量
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

# 检查 NPM_AUTH_TOKEN 是否已设置
if [ -z "$NPM_AUTH_TOKEN" ]; then
  echo "错误: NPM_AUTH_TOKEN 环境变量未设置"
  echo "请在 .env 文件中设置: NPM_AUTH_TOKEN=你的token"
  exit 1
fi

# 执行版本更新
rush version --bump

# 重新获取更新后的版本号（rush version --bump 会更新版本号）
NEW_VERSION=$(cat common/config/rush/version-policies.json | grep '"version"' | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')

# 构建项目
rush build

# 发布包
rush publish --force --apply --publish --target-branch main --include-all

echo -e "\033[31m新版本: $NEW_VERSION\033[0m"
echo -e "正在推送代码到远程仓库..."
git add .
git commit -m "release: publish $NEW_VERSION"
git push