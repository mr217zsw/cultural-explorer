<script>export default { onLaunch() { console.log('华夏文化探索启动'); } };</script>

<style>
/* 全局设计变量 —— 华夏文化探索 */
:root {
  /* 调色板 */
  --color-primary: #8b1e2d;
  --color-primary-light: #b54a3a;
  --color-accent: #f5a623;
  --color-bg: #fffaf0;
  --color-surface: #ffffff;
  --color-text: #2d2520;
  --color-text-secondary: #8c7568;
  --color-success: #66bb6a;
  --color-mnemonic-bg: #fff0d5;
  --color-gold: #f5a623;
  --color-silver: #b0bec5;
  --color-bronze: #d4a574;

  /* 渐变 */
  --gradient-hero: linear-gradient(135deg, #8b1e2d, #b54a3a);

  /* 间距 */
  --space-xs: 4rpx;
  --space-sm: 8rpx;
  --space-md: 16rpx;
  --space-lg: 24rpx;
  --space-xl: 32rpx;
  --space-2xl: 48rpx;

  /* 圆角 */
  --radius-sm: 8rpx;
  --radius-md: 16rpx;
  --radius-lg: 20rpx;
  --radius-full: 40rpx;

  /* 阴影 */
  --shadow-card: 0 4rpx 20rpx rgba(80, 40, 20, 0.06);

  /* 字号 */
  --font-xs: 22rpx;
  --font-sm: 26rpx;
  --font-md: 30rpx;
  --font-lg: 36rpx;
  --font-xl: 44rpx;
  --font-2xl: 52rpx;
}

/* 强制浅色模式，避免浏览器自动暗黑化 */
html, body, page {
  background: #fffaf0 !important;
  color: #2d2520 !important;
  color-scheme: light !important;
  -webkit-color-scheme: light !important;
  font-family: system-ui, -apple-system, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
  font-size: 30rpx;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* 覆盖 uni-app 默认的 page 元素 */
#__app, .uni-page, uni-page, .uni-page-head {
  background: #fffaf0 !important;
  color: #2d2520 !important;
  color-scheme: light !important;
}

/* 工具类 */
.page {
  min-height: 100vh;
  padding: 24rpx;
  background: #fffaf0;
}

.card {
  background: #ffffff;
  border-radius: 20rpx;
  box-shadow: 0 4rpx 20rpx rgba(80, 40, 20, 0.06);
}

.primary {
  background: #8b1e2d;
  color: #ffffff !important;
  border-radius: 40rpx;
  padding: 16rpx 32rpx;
  font-size: 30rpx;
  font-weight: 600;
  text-align: center;
  border: none;
}

.primary::after { border: none; }
</style>
