# Rush 项目创建指南

## 什么是 Rush？

Rush 是微软开发的一个可扩展的 monorepo 管理工具，专门用于管理包含多个 npm 包的大型代码库。它提供了统一的构建、测试、发布流程，并能有效管理项目间的依赖关系。

## 前置条件

在开始之前，请确保你的系统已安装：

- **Node.js**: 版本 >= 18.20.3 < 19.0.0 或 >= 20.14.0 < 21.0.0
- **Git**: 用于版本控制
- **npm**: Node.js 自带的包管理器

## 第一步：全局安装 Rush

```bash
npm install -g @microsoft/rush
```

验证安装：
```bash
rush --version
```

## 第二步：创建项目根目录

```bash
mkdir my-rush-project
cd my-rush-project
```

## 第三步：初始化 Git 仓库

```bash
git init
```

## 第四步：初始化 Rush 配置

```bash
rush init
```

这个命令会创建以下文件和目录结构：
```
my-rush-project/
├── common/
│   ├── config/
│   │   └── rush/
│   ├── scripts/
│   └── temp/
├── rush.json
└── .gitignore
```

## 第五步：配置 rush.json

编辑 `rush.json` 文件，主要配置以下几个关键字段：

### 5.1 设置 Rush 版本
```json
{
  "rushVersion": "5.157.0"
}
```

### 5.2 选择包管理器
```json
{
  "pnpmVersion": "8.15.8"
}
```
> 推荐使用 pnpm，它比 npm 和 yarn 更快且更节省磁盘空间

### 5.3 设置 Node.js 版本要求
```json
{
  "nodeSupportedVersionRange": ">=18.20.3 <19.0.0 || >=20.14.0 <21.0.0"
}
```

## 第六步：创建项目目录结构

创建 packages 目录来存放各个子项目：

```bash
mkdir packages
```

## 第七步：创建第一个工具包项目

### 7.1 创建 utils 项目
```bash
mkdir packages/utils
cd packages/utils
```

### 7.2 初始化 package.json
```bash
npm init -y
```

### 7.3 编辑 package.json
```json
{
  "name": "my-utils",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    // 这里build是必须的，因为rush build会执行所有包里面的build命令，如果不需要构建，就可以写exit 0
    "build": "exit 0",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "description": "工具函数库"
}
```

### 7.4 创建入口文件
```bash
echo "module.exports = { hello: () => 'Hello from utils!' };" > index.js
```

## 第八步：创建应用项目

### 8.1 创建 app 项目
```bash
cd ../../
mkdir packages/app
cd packages/app
```

### 8.2 初始化 package.json
```bash
npm init -y
```

### 8.3 编辑 package.json（注意依赖配置）
```json
{
  "name": "my-app",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    // 这里build是必须的，因为rush build会执行所有包里面的build命令，如果不需要构建，就可以写exit 0
    "build": "exit 0",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    // 依赖 utils 包，开启workspace:*，表示依赖的是本地的包
    "my-utils": "workspace:*"
  },
  "author": "",
  "license": "ISC",
  "description": "主应用程序"
}
```

> **重要**: 使用 `workspace:*` 来引用 monorepo 内的其他包

### 8.4 创建入口文件
```bash
echo "const utils = require('my-utils'); console.log(utils.hello());" > index.js
```

## 第九步：在 rush.json 中注册项目

回到项目根目录，编辑 `rush.json` 文件，在 `projects` 数组中添加项目：

```json
{
  "projects": [
    {
      "packageName": "my-utils",
      "projectFolder": "packages/utils"
    },
    {
      "packageName": "my-app", 
      "projectFolder": "packages/app"
    }
  ]
}
```

## 第十步：安装依赖

```bash
cd ../../
rush update
```

这个命令会：
- 安装所有项目的依赖
- 创建符号链接连接 monorepo 内的项目
- 生成 pnpm-lock.yaml 文件

## 第十一步：构建项目

```bash
rush build
```

## 第十二步：验证项目

测试 app 项目：
```bash
cd packages/app
node index.js
```

应该输出：`Hello from utils!`


## 常用 Rush 命令

### 项目管理
- `rush update` - 安装/更新所有依赖
- `rush install` - 安装依赖（不更新版本）
- `rush build` - 构建所有项目
- `rush rebuild` - 清理并重新构建
- `rush test` - 运行所有测试

### rush install vs rush update 的区别

#### rush install
- **用途**: 根据现有的 lock 文件安装依赖，不会更新包版本
- **场景**:
  - 克隆项目后的首次安装
  - CI/CD 环境中的依赖安装
  - 确保团队成员使用相同版本的依赖
- **特点**:
  - 速度更快
  - 保持版本一致性
  - 不会修改 lock 文件

#### rush update
- **用途**: 重新解析依赖并更新到 package.json 允许的最新版本
- **场景**:
  - 添加新的依赖包后
  - 想要更新依赖到最新兼容版本
  - package.json 发生变化后
- **特点**:
  - 会更新 lock 文件
  - 可能会安装新版本的依赖
  - 耗时相对较长

**推荐使用原则**:
- 日常开发: 使用 `rush install`
- 添加新依赖或更新依赖: 使用 `rush update`
- 生产环境部署: 使用 `rush install` 确保版本一致

### 选择性操作
- `rush build --to my-app` - 构建 my-app 及其依赖
- `rush build --from my-utils` - 构建 my-utils 及依赖它的项目
- `rush build --only my-app` - 只构建 my-app

### 项目信息
- `rush list` - 列出所有项目
- `rush list --json` - 以 JSON 格式输出项目信息  
```json
{
  "projects": [
    {
      "name": "my-app",
      "version": "1.0.0",
      "path": "packages/app",
      "fullPath": "/Users/qihoo/Documents/A_Code/CeShi/Rush/packages/app",
      "shouldPublish": false,
      "tags": []
    },
    {
      "name": "my-utils",
      "version": "1.0.0",
      "path": "packages/utils",
      "fullPath": "/Users/qihoo/Documents/A_Code/CeShi/Rush/packages/utils",
      "shouldPublish": false,
      "tags": []
    }
  ]
}
```

## 最佳实践

1. **项目命名**: 使用有意义的包名，建议加上组织前缀
2. **版本管理**: 使用 `workspace:*` 引用内部包
3. **构建脚本**: 确保每个项目都有 `build` 脚本
4. **依赖管理**: 定期运行 `rush update` 保持依赖同步
5. **Git 提交**: 提交前运行 `rush build` 确保所有项目都能正常构建

## 下一步

- 学习使用 `rush change` 管理变更日志
- 配置 `rush publish` 进行包发布
- 设置 CI/CD 流水线
- 探索 Rush 的高级功能如子空间（subspaces）

这样，你就成功创建了一个基本的 Rush monorepo 项目！
