# 🏮 华夏文化探索 v4.0

多端联动的中国地理历史文化互动学习应用 — 读山河，知历史，见人文。

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v3.0 | 2026-07-21 | 第一版：基础功能 + 三端架构 |
| **v4.0** | **2026-07-23** | **第二版：内容深化 + 互动升级 + AI 视听到位** |

## 架构

```
┌──────────────┐  ┌─────────────────┐
│  Flutter App │  │  微信小程序 / H5  │
│  (app/)      │  │  (miniapp/)      │
└──────┬───────┘  └────────┬────────┘
       │                   │
       └───────────────────┼──────────────────┘
                           │  REST API
                   ┌───────┴────────┐
                   │  NestJS 后端    │
                   │  (backend/)    │
                   └───────┬────────┘
                           │
            ┌──────────────┼───────────────┐
            │              │               │
     ┌──────┴──────┐ ┌─────┴─────┐ ┌──────┴──────┐
     │  Supabase   │ │  Upstash  │ │ 通义万相/   │
     │  PostgreSQL │ │  Redis    │ │ DeepSeek AI │
     └─────────────┘ └───────────┘ └─────────────┘
                           │
                    ┌──────┴──────┐
                    │  CST 数据胶囊 │
                    │  (S3 存储)   │
                    └─────────────┘
```

## 技术栈

| 层 | 技术 | 说明 |
|---|------|------|
| 后端 | NestJS 10 + Prisma 6 + TypeScript | RESTful API，Port 3000 |
| 数据库 | PostgreSQL (Supabase) | 地区/用户/记录/题目/章节/时间轴/美食/非遗 |
| 缓存 | Upstash Redis | 闯关会话缓存，排行榜 |
| AI 内容 | DeepSeek API | 地区深度内容生成，答题提示 |
| AI 配图 | 通义万相 wanx-v1 | 34 地区封面图文生图 |
| AI 配音 | 通义万相 sambert-zhichu-v1 | 34 地区语音导览 TTS |
| 存储 | CST 数据胶囊 (S3 兼容) | 配图/配音永久存储 |
| Flutter | Flutter 3.44 + Material 3 | Android / iOS |
| 小程序 | uni-app 3 + Vue 3 | 微信小程序 + H5 |

## v4.0 功能清单

### 内容体系
- **34 地区深度内容** — 每地区 4-8 章节 + 8-24 条时间轴 + 4-6 位名人 + 3-8 道美食 + 3-5 项非遗
- **340 道题目** — 单选 / 多选 / 判断三种题型，覆盖地理/历史/文化

### 互动体验
- **闯关 V2** — 难度分级(1-3)、生命值(3条)、连击加分、S/A/B/C 评级、倒计时、AI 答题提示
- **勋章墙** — 10 种勋章（初出茅庐→华夏通），通关/签到自动发放
- **每日签到** — 连续签到阶梯奖励(3/5/7天)
- **AI 记忆口诀** — DeepSeek 生成趣味口诀辅助记忆

### 视听媒体
- **AI 配图** — 34 张封面图，通义万相生成，数据胶囊永久存储
- **AI 配音** — 34 个语音导览(1-2分钟)，sambert TTS 生成

### 多端适配
- **暗色模式** — Flutter ThemeMode.system + 小程序 prefers-color-scheme
- **分享成就** — 复制分享文案(两端均已实现)
- **管理后台** — `/api/admin/stats` 数据统计看板

## 快速启动

### 1. 后端

```bash
cd backend
npm install

# 配置 .env（数据库/AI/存储/Redis）
cp .env.example .env

# 初始化数据库
npx prisma generate
npx prisma db push

# 启动
npm run start:dev
```

API 地址：`http://localhost:3000/api`

### 2. 生成种子数据

```bash
# v4.0 内容生成（DeepSeek：34 地区 + 340 道题 → JSON）
npm run prisma:seed-v4:generate

# 入库（JSON → Supabase PostgreSQL）
npm run prisma:seed-v4:import

# 配图 + 配音（通义万相：34 张图 + 34 个配音 → 本地 public/）
npx tsx prisma/seed-v4-media.ts

# 上传到数据胶囊（本地 → CST S3 → DB URL 更新）
npx tsx prisma/seed-v4-upload.ts
```

### 3. Flutter App

```bash
cd app
flutter clean && flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

### 4. 小程序 / H5

```bash
cd miniapp
npm install
npm run dev:h5         # H5 (http://localhost:5174)
npm run dev:mp-weixin  # 微信小程序
```

## API 概要 (v4.0)

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET`  | `/health` | 健康检查 |
| `POST` | `/auth/login` | 匿名登录 |
| `GET`  | `/regions` | 地区列表(分页/搜索) |
| `GET`  | `/regions/:id` | 地区详情(v4.0 含完整字段) |
| `POST` | `/regions/:id/favorite` | 收藏/取消 |
| `GET`  | `/regions/:id/chapters` | 内容章节 |
| `GET`  | `/regions/:id/timeline` | 历史时间轴 |
| `GET`  | `/regions/:id/cuisine` | 特色美食 |
| `GET`  | `/regions/:id/heritage` | 非物质文化遗产 |
| `POST` | `/quiz/startV2` | 开始闯关(v4.0 难度选择) |
| `POST` | `/quiz/submitV2` | 提交答案(多题型) |
| `POST` | `/quiz/hint` | AI 答题提示(-5积分) |
| `POST` | `/checkin/daily` | 每日签到 |
| `GET`  | `/checkin/stats` | 签到统计 |
| `GET`  | `/badges` | 我的勋章 |
| `GET`  | `/badges/all` | 全部勋章及获取状态 |
| `POST` | `/audio/generate` | 生成 AI 配音 |
| `POST` | `/image/generate-cover` | 生成 AI 封面图 |
| `GET`  | `/admin/stats` | 管理后台数据统计 |

## 环境变量

| 变量 | 必填 | 说明 |
|------|:---:|------|
| `DATABASE_URL` | ✅ | Supabase PostgreSQL (pooler 6543) |
| `DIRECT_URL` | ✅ | Supabase 直连 (session 5432) |
| `JWT_SECRET` | ✅ | JWT 签名密钥 |
| `DEEPSEEK_API_KEY` | ✅ | DeepSeek API Key |
| `DASHSCOPE_API_KEY` | ✅ | 通义万相 API Key (配图/配音) |
| `CST_ACCESS_KEY` | 可选 | CST 数据胶囊 S3 Key |
| `CST_SECRET_KEY` | 可选 | CST 数据胶囊 S3 Secret |
| `CST_ENDPOINT` | 可选 | S3 端点 (s3.cstcloud.cn) |
| `CST_BUCKET` | 可选 | S3 桶名 |
| `UPSTASH_REDIS_REST_URL` | 可选 | Upstash Redis |
| `UPSTASH_REDIS_REST_TOKEN` | 可选 | Upstash Redis Token |
| `PORT` | 3000 | 服务端口 |

## 项目结构

```
cultural-explorer/
├── backend/                     # NestJS 后端
│   ├── src/
│   │   ├── admin/               # 管理后台统计
│   │   ├── auth/                # JWT 鉴权
│   │   ├── badge/               # 勋章系统
│   │   ├── chapter/             # 内容章节
│   │   ├── checkin/             # 每日签到
│   │   ├── common/              # Redis/Storage/拦截器
│   │   ├── content/             # DeepSeek 内容生成管线
│   │   ├── cuisine/             # 特色美食
│   │   ├── heritage/            # 非遗文化
│   │   ├── image-gen/           # 通义万相文生图
│   │   ├── mnemonic/            # AI 记忆口诀
│   │   ├── prisma/              # ORM
│   │   ├── quiz/                # 闯关 V2 (多题型)
│   │   ├── regions/             # 地区资源
│   │   ├── timeline/            # 历史时间轴
│   │   ├── tts/                 # AI 配音 TTS
│   │   ├── upload/              # S3 文件上传
│   │   └── users/               # 用户模块
│   └── prisma/
│       ├── schema.prisma        # 14 张表
│       ├── seed-v4-generate.ts  # AI 内容生成
│       ├── seed-v4-import.ts    # JSON → DB
│       ├── seed-v4-media.ts     # 配图+配音生成
│       └── seed-v4-upload.ts    # S3 上传
│
├── app/                         # Flutter 客户端
│   └── lib/
│       ├── config/              # API + 主题 (含 darkTheme)
│       ├── models/              # 数据模型
│       ├── screens/             # 页面(v4.0 升级)
│       │   ├── home/            # 首页
│       │   ├── region_detail/   # 沉浸式详情(章节+时间轴+名人+美食+非遗)
│       │   ├── quiz/            # 答题(多选+倒计时+提示)
│       │   ├── profile/         # 个人(签到+勋章墙+分享)
│       │   └── ...
│       └── services/            # API 服务层
│
├── miniapp/                     # uni-app 小程序/H5
│   └── src/
│       ├── pages/
│       │   ├── detail/          # 沉浸式详情(v4.0)
│       │   ├── quiz/            # 答题(多选+倒计时+提示)
│       │   ├── profile/         # 个人(签到+勋章+分享)
│       │   └── index/           # 首页
│       └── api/                 # 接口封装
│
├── docker-compose.yml
└── README.md
```

## 开发说明

- 后端缺失 AI/S3/Redis 配置时自动降级（兜底逻辑）
- Flutter 使用 Provider 状态管理，Material 3 主题，支持暗色模式（跟随系统）
- Miniapp 使用 Pinia 状态管理，Vue 3 Composition API，暗色模式 CSS 变量
- 种子数据通过 `prisma/seed-v4-*` 脚本链路生成（AI 内容 → JSON → DB → 媒体 → S3）
- 数据胶囊 Key 需要绑定 Rclone 应用（`customUserAgent: 'Rclone/v1.65.0'`）
