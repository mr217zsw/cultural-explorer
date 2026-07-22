# 华夏文化探索

依据《华夏文化探索 - 完整技术文档 v3.0》搭建的多端 MVP 单仓库。

## 目录

- `backend/`：NestJS + Prisma + PostgreSQL API
- `app/`：Flutter（Android / iOS / Web）客户端
- `miniapp/`：UniApp + Vue 3 微信小程序
- `deploy/`：Docker Compose 与 Nginx 示例

## 快速启动后端

```bash
cd backend
cp .env.example .env
npm install
npx prisma generate
npx prisma db push
npm run prisma:seed
npm run start:dev
```

默认 API 地址为 `http://localhost:3000/api`，健康检查为 `/api/health`。

开发阶段可以不配置 DeepSeek。未配置 `DEEPSEEK_API_KEY` 时，口诀服务会根据地区资料生成本地兜底口诀。Redis 和对象存储同样是可选增强项。

## 启动 Flutter

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

Android 模拟器访问宿主机时，请将地址改为 `http://10.0.2.2:3000/api`。

## 启动小程序/H5

```bash
cd miniapp
npm install
npm run dev:h5
# 或 npm run dev:mp-weixin
```

## 当前实现

- 地区列表、搜索、随机推荐、详情、地标和题目
- 匿名登录、JWT 鉴权、用户资料、统计与排行榜
- 开始闯关、单题校验、完成闯关、记录与地区排行
- 收藏/取消收藏
- DeepSeek 口诀生成、数据库缓存、重新生成与分享文案
- 北京、上海、广东、四川、陕西、西藏、云南、新疆、内蒙古、海南 10 个地区种子数据
- Flutter 地区列表/详情/答题基础流程
- UniApp 地区列表/详情/答题基础流程

