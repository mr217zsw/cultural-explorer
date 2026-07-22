# 🏮 华夏文化探索

多端联动的中国地理历史文化互动学习应用 — 读山河，知历史，见人文。

## 架构

```
┌──────────────┐  ┌─────────────────┐  ┌──────────────┐
│  Flutter App │  │  微信小程序 / H5  │  │   Web 管理端  │
│  (app/)      │  │  (miniapp/)      │  │  (miniapp H5) │
└──────┬───────┘  └────────┬────────┘  └──────┬───────┘
       │                   │                  │
       └───────────────────┼──────────────────┘
                           │  REST API
                   ┌───────┴────────┐
                   │  NestJS 后端    │
                   │  (backend/)    │
                   └───────┬────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────┴──────┐ ┌─────┴─────┐ ┌─────┴─────┐
     │ PostgreSQL  │ │  Redis    │ │ DeepSeek  │
     │  (数据持久)  │ │ (缓存/排行)│ │ (AI口诀)  │
     └─────────────┘ └───────────┘ └───────────┘
```

## 技术栈

| 层 | 技术 | 说明 |
|---|------|------|
| 后端 | NestJS 10 + Prisma 6 + TypeScript | RESTful API，Port 3000 |
| 数据库 | PostgreSQL (Supabase) | 地区/用户/记录/题目 |
| 缓存 | Upstash Redis | 排行榜缓存，API 限流 |
| AI | DeepSeek API | 地区记忆口诀生成 |
| 存储 | CST 对象存储 (S3) | 图片/封面上传 |
| Flutter | Flutter 3.44 + Material 3 | Android / iOS / Web |
| 小程序 | uni-app 3 + Vue 3 + Pinia | 微信小程序 + H5 |

## 功能清单

- **地区探索** — 34 个省级行政区，搜索/浏览/收藏
- **文化闯关** — 地理/历史/文化分类答题，计分排行
- **AI 记忆口诀** — DeepSeek 生成趣味口诀辅助记忆
- **排行榜** — 全国总排行 + 单地区排行
- **个人中心** — 昵称/积分/通关统计/连胜
- **匿名登录** — JWT 鉴权，零门槛上手
- **多端统一** — Flutter / 微信小程序 / H5 三端共享 API

## 项目结构

```
cultural-explorer/
├── backend/                     # NestJS 后端 API
│   ├── src/
│   │   ├── auth/                # JWT 鉴权模块
│   │   ├── common/              # 公共模块（Redis、存储、拦截器）
│   │   ├── mnemonic/            # DeepSeek 口诀生成
│   │   ├── prisma/              # ORM 数据库服务
│   │   ├── quiz/                # 闯关答题模块
│   │   ├── regions/             # 地区资源模块
│   │   ├── upload/              # 文件上传（S3）
│   │   ├── users/               # 用户模块
│   │   ├── app.module.ts        # 根模块
│   │   └── main.ts              # 入口
│   ├── prisma/                  # Schema + 种子数据
│   └── package.json
│
├── app/                         # Flutter 客户端
│   ├── lib/
│   │   ├── config/              # API配置 + 设计主题
│   │   ├── models/              # 数据模型
│   │   ├── providers/           # Auth 状态管理
│   │   ├── screens/             # 页面（首页/详情/答题/排行/收藏/个人）
│   │   ├── services/            # API 服务层
│   │   └── main.dart            # 入口
│   └── pubspec.yaml
│
├── miniapp/                     # uni-app 小程序/H5
│   ├── src/
│   │   ├── api/                 # 接口封装
│   │   ├── pages/               # 页面组件
│   │   ├── store/               # Pinia 状态
│   │   ├── styles/              # CSS 变量
│   │   ├── App.vue              # 根组件
│   │   └── pages.json           # 路由配置
│   └── package.json
│
├── deploy/                      # 部署配置
│   ├── nginx.conf               # Nginx 反代
│   └── render.yaml              # Render.com 部署
│
├── docker-compose.yml           # 本地开发环境
└── README.md
```

## 快速启动

### 1. 后端

```bash
cd backend

# 安装依赖
npm install

# 配置环境变量（编辑 .env 填入真实配置）
cp .env.example .env

# 初始化数据库
npx prisma generate
npx prisma db push

# 可选：写入种子数据（10 个地区 + 题目）
npm run prisma:seed

# 启动（watch 模式）
npm run start:dev
```

API 地址：`http://localhost:3000/api`，健康检查：`/api/health`

### 2. Flutter App

```bash
cd app
flutter pub get

# 本地开发
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api

# Android 模拟器（宿主机映射）
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

### 3. 小程序 / H5

```bash
cd miniapp
npm install

# 启动 H5 开发服务器（Port 5174）
npm run dev:h5

# 编译微信小程序
npm run dev:mp-weixin
```

### 4. Docker Compose（全栈本地开发）

```bash
# 启动 PostgreSQL + API
docker compose up -d

# 初始化数据库
docker compose exec api npx prisma db push
docker compose exec api npm run prisma:seed
```

## 环境变量

后端 `.env` 文件：

| 变量 | 必填 | 说明 |
|------|------|------|
| `DATABASE_URL` | ✅ | PostgreSQL 连接串 |
| `DIRECT_URL` | ✅ | 直连地址（Prisma migration） |
| `JWT_SECRET` | ✅ | JWT 签名密钥 |
| `DEEPSEEK_API_KEY` | 可选 | DeepSeek API Key（为空时生成本地兜底口诀） |
| `UPSTASH_REDIS_REST_URL` | 可选 | Upstash Redis 地址 |
| `UPSTASH_REDIS_REST_TOKEN` | 可选 | Upstash Redis Token |
| `CST_ACCESS_KEY` | 可选 | 对象存储 Access Key |
| `CST_SECRET_KEY` | 可选 | 对象存储 Secret Key |
| `CST_ENDPOINT` | 可选 | S3 端点 |
| `CST_BUCKET` | 可选 | 存储桶名称 |
| `PORT` | 3000 | 服务端口 |

## API 概要

| 方法 | 路径 | 说明 | 鉴权 |
|------|------|------|------|
| `GET` | `/health` | 健康检查 | - |
| `POST` | `/auth/login` | 匿名登录 | - |
| `GET` | `/regions` | 地区列表+搜索 | 可选 |
| `GET` | `/regions/:id` | 地区详情 | 可选 |
| `POST` | `/regions/:id/favorite` | 收藏/取消 | ✅ |
| `POST` | `/quiz/start` | 开始闯关 | ✅ |
| `POST` | `/quiz/complete` | 提交答案 | ✅ |
| `GET` | `/quiz/records` | 答题记录 | ✅ |
| `GET` | `/quiz/ranking/:regionId` | 地区排行 | - |
| `GET` | `/user/profile` | 个人信息 | ✅ |
| `PUT` | `/user/profile` | 更新资料 | ✅ |
| `GET` | `/user/ranking` | 全国排行 | - |
| `GET` | `/user/stats` | 个人统计 | ✅ |
| `GET` | `/mnemonic/:regionId` | 获取口诀 | - |
| `POST` | `/mnemonic/:regionId/regenerate` | 重新生成 | ✅ |

## 设计系统

两个前端共享统一的视觉语言：

| Token | 值 | 说明 |
|-------|-----|------|
| `--color-primary` | `#8b1e2d` | 中国红主色 |
| `--color-bg` | `#fffaf0` | 暖米白背景 |
| `--color-text` | `#2d2520` | 深棕主文字 |
| `--color-text-secondary` | `#8c7568` | 灰棕辅助色 |
| `--color-accent` | `#f5a623` | 金橙强调色 |
| `--color-success` | `#66bb6a` | 通关绿 |
| `--radius-lg` | 20rpx | 卡片圆角 |
| `--radius-full` | 40rpx | 按钮全圆角 |

Flutter 端对应 `app/lib/config/app_theme.dart`，小程序端对应 `miniapp/src/styles/variables.css`。

## 部署

### Render.com

[deploy/render.yaml](deploy/render.yaml) 提供一键部署蓝本，使用 Docker 构建：

1. 在 Render 创建 Blueprint，关联仓库
2. 设置 `DATABASE_URL`、`JWT_SECRET`、`DEEPSEEK_API_KEY` 环境变量
3. 部署后 API 运营在 `https://<name>.onrender.com/api`

### 自托管（Docker + Nginx）

```bash
# 1. 启动服务
docker compose up -d

# 2. 构建前端静态文件
cd miniapp && npm run build:h5
cp -r dist/build/h5 /var/www/cultural-explorer-web/

# 3. 配置 Nginx（参考 deploy/nginx.conf）
```

## 开发说明

- 后端开发无需完整配置 DeepSeek / Redis / S3，缺失时自动降级
- 种子数据包含 10 个地区（北京、上海、广东、四川、陕西、西藏、云南、新疆、内蒙古、海南）
- Flutter 使用 Provider 做状态管理，Material 3 主题
- Miniapp 使用 Pinia 做状态管理，Vue 3 Composition API
- CSS 变量定义在 `miniapp/src/styles/variables.css`，与 Flutter 端 `app_theme.dart` 保持同步
