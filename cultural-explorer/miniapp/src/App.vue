<script>export default { onLaunch() { console.log('华夏文化探索启动'); } };</script>
<style>
@import './styles/variables.css';

page {
  background: var(--color-bg);
  color: var(--color-text);
  font-family: system-ui, -apple-system, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', sans-serif;
  font-size: var(--font-md);
  line-height: var(--leading-normal);
  -webkit-font-smoothing: antialiased;
}

.page {
  min-height: 100vh;
  padding: var(--space-lg);
}

.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
}

.primary {
  background: var(--color-primary);
  color: #fff;
  border-radius: var(--radius-full);
  padding: var(--space-md) var(--space-xl);
  font-size: var(--font-md);
  font-weight: 600;
  text-align: center;
  border: none;
}

.primary::after { border: none; }
</style>

