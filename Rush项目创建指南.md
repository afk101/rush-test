# Rush 项目创建指南

## 什么是 Rush？

Rush 是微软开发的一个可扩展的 monorepo 管理工具，专门用于管理包含多个 npm 包的大型代码库。它提供了统一的构建、测试、发布流程，并能有效管理项目间的依赖关系。

## 前置条件

在开始之前，请确保你的系统已安装：

- **Node.js**: 版本有要求
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

## 第五步：配置 rush.json(默认会自动生成一份配置)

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
    // 这里build是必须的，因为rush build会执行所有包里面的build命令，如果不需要构建(例如单纯的js包)，就可以写exit 0
    "build": "exit 0",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "description": "工具函数库"
}
```

### 7.4 创建入口文件，对应main字段
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
      // 对应package.json中的
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

## 版本管理策略选择

Rush 支持两种版本管理策略，你可以根据项目需求选择：

### 策略一：独立版本管理（默认）

每个包独立管理版本号：
```
my-utils: 1.0.0
my-app: 2.1.0
my-tools: 0.5.0
```

**适用场景**:
- 包功能差异较大
- 包的发布周期不同
- 需要精细化的版本控制

**使用方式**: 使用 `rush change` 单独管理每个包的变更

### 策略二：统一版本管理（lockstep）

所有包共享同一版本号：
```
my-utils: 1.0.0
my-app: 1.0.0
my-tools: 1.0.0
```

**适用场景**:
- 包之间联系紧密
- 希望简化版本管理
- 统一发布周期

**配置步骤**:

#### 1. 配置版本策略
编辑 `common/config/rush/version-policies.json`:
```json
[
  {
    "definitionName": "lockStepVersion",
    "policyName": "MyProject",
    "version": "1.0.0",
    "nextBump": "patch",
    // 所有的变更日志都会写入 packages/app/CHANGELOG.md
    "mainProject": "my-app"
  }
]
```

#### 2. 在 rush.json 中应用策略
```json
{
  "projects": [
    {
      "packageName": "my-utils",
      "projectFolder": "packages/utils",
      "versionPolicyName": "MyProject",
      "shouldPublish": true
    },
    {
      "packageName": "my-app",
      "projectFolder": "packages/app",
      "versionPolicyName": "MyProject",
      // 配合rush publish 的--include-all使用，这个参数会包括所有配置了shouldPublish的包
      "shouldPublish": true
    }
  ]
}
```

## Rush Publish 包发布配置

### 什么是 rush publish？

将你的包发布到npm。

### 为什么需要 rush publish？（解决什么问题）

**问题场景**：
- 你有 10 个包要发布到 npm
- 手动发布：需要进入每个包目录，运行 `npm publish`，重复 10 次
- 容易出错：忘记某个包、版本号不一致、发布顺序错误（可能有依赖关系）

**Rush publish 的解决方案**：
- 一个命令发布所有包
- 自动处理依赖顺序
- 确保版本一致性
- 提供发布前检查

### 基础配置步骤

#### 第一步：配置包的发布属性

**如何选择**：
- 如果使用统一版本管理（lockstep）→ 使用 `versionPolicyName` 配合 rush version --bump
- 如果使用独立版本管理 使用rush change，然后修改type


#### 第二步：配置 npm 认证

```bash
# 登录到 npm（只需要做一次）
npm login

# 验证登录状态
npm whoami
```


#### 第三步：基本发布流程  
common/config/rush/.npmrc-publish中将  
```json
# Provide an authentication token for the above registry URL:  
//registry.npmjs.org/:_authToken=${NPM_AUTH_TOKEN}  
```
最后一行这个的注释打开，即删除//registry.npmjs.org/:_authToken=${NPM_AUTH_TOKEN}最前面的#号  
意思是每次publish是需要你的身份令牌的  
如何查看自己的身份令牌？  
```bash
 cat ~/.npmrc
```
结果：  
```bash
home=https://www.npmjs.org
registry=https://registry.npmjs.org/
@q:registry=https://registry.qnpm.qihoo.net
//registry.qnpm.qihoo.net/:_authToken=xxx
//registry.npmjs.org/:_authToken=xxx
```
上面的xxx就是  
执行终端需要设置
```bash
 export NPM_AUTH_TOKEN=xxx
```
也可以写一个脚本，自动设置  
`单独发包`：  
git add .  
git commit -m 'xxx'  
rush change  
rush build  
rush publish --force --apply --publish --target-branch main  

`统一管理包版本`：  
rush version --bump  
rush build  
git add .  
git commit -m 'xxx'  
rush publish --force --apply --publish --target-branch main --include-all  

对rush version --bump的介绍：  
# 这个指令会参照common/config/rush/version-policies.json的配置  
# 例如如下  
```json
{
    "definitionName": "lockStepVersion",
    "policyName": "MyProject",
    "version": "1.0.6",
    "nextBump": "patch"
    }
```
原本是这样的，执行命令`rush version --bump`之后，version会改变，具体如何改根据nextBump来决定，同时会修改所有包的package.json的版本号统一为这个version，如果不指定"mainProject": "@gdluckk/my-app"这个，所有的包都会生成一份CHANGELOG.md和CHANGELOG.json文件。如果指定了主要的项目，那么这两个文件只会在指定的包内部生成  



### 常见问题和解决方案

#### 问题1：发布失败 - 权限不足
```bash
# 解决方案：检查 npm 登录状态
npm whoami
npm login
```

### 私有包发布配置

私有包发布是指将包发布到企业内部的 npm registry，而不是公共的 npmjs.org。这在企业环境中非常常见，用于保护代码隐私和控制包的访问权限。

#### 配置步骤

##### 第一步：配置私有 registry

**方法一：全局配置（推荐用于开发环境）**
查看Qnpm的配置方式    
[Qnpm](https://coding.qihoo.net/qnpm)

**方法二：项目级配置（推荐用于生产环境）**

在项目根目录创建 `.npmrc` 文件：
```bash
# .npmrc
@q:registry=https://registry.qnpm.qihoo.net
registry=https://registry.npmjs.org

legacy-peer-deps=true
```

##### 第二步：配置

**获取认证 Token**  
确保登录到了Qnpm（一次性）  
```bash
qnpm login  
# 访问下面链接获取密码  
https://qnpm.qihoo.net/password/
```

**配置 Rush 发布认证**

编辑 `common/config/rush/.npmrc-publish` 文件：
```bash
# 私有 registry 配置
registry=https://registry.qnpm.qihoo.net/
//registry.qnpm.qihoo.net/:_authToken=${QNPM_AUTH_TOKEN}
```
这里定义了环境变量QNPM_AUTH_TOKEN  
在.env文件中写入这个变量以及你的token（如何获取token上面有写）

**设置环境变量**
```bash
# 方法一：临时设置
export QNPM_AUTH_TOKEN=your-private-token-here

# 方法二：写入 shell 配置文件（推荐）
echo 'export QNPM_AUTH_TOKEN=your-private-token-here' >> ~/.zshrc
source ~/.zshrc

# 方法三：使用 .env 文件（团队协作推荐）
echo 'QNPM_AUTH_TOKEN=your-private-token-here' > .env
```

##### 第三步：配置包的发布属性

**修改 package.json 添加私有源信息**
```json
{
  "name": "@q/my-utils",
  "version": "1.0.0",
  "publishConfig": {
    "access": "public",
    // 私有源
    "registry":"https://registry.qnpm.qihoo.net"
  },
  // 维护者信息
  "maintainers":[
    {
      "email": "chenguangdi@360.cn",
      "name": "chenguangdi"
    }
  ]
}
```

**在 rush.json 中配置发布属性**
```json
{
  "projects": [
    {
      "packageName": "@q/my-utils",
      "projectFolder": "packages/utils",
      "shouldPublish": true,
      "versionPolicyName": "MyProject"
    }
  ]
}
```  
发布命令还是之前的

### 管理多个common/config/rush/version-policies.json  
```json
{
    "definitionName": "lockStepVersion",
    "policyName": "MyProject",
    "version": "1.0.30",
    "nextBump": "patch"
  },
  {
    "definitionName": "lockStepVersion",
    "policyName": "MyProject-MyProject-prerelease",
    "version": "1.0.32-0",
    "nextBump": "prerelease"
  }
```
这里新展示一个prerelease的nextBump  
执行rush version --bump --version-policy MyProject-prerelease  
可以只改MyProject-prerelease的version，能够做到1.0.32-0  1.0.32-1 ……这种版本效果  
--version-policy的意思是只改对应policyName的version  
记得rush.json中versionPolicyName做对应的更改，否则rush version --bump --version-policy MyProject-prerelease指令应用不对包的package.json的version