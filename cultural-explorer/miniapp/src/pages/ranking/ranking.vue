<template>
  <view class="page">
    <!-- 加载/空状态 -->
    <view v-if="loading" class="empty">
      <text class="empty-icon">⏳</text>
      <text>加载排行榜中...</text>
    </view>

    <view v-else-if="users.length === 0" class="empty">
      <text class="empty-icon">🏆</text>
      <text>暂无排名数据</text>
    </view>

    <view v-else class="rank-list">
      <view
        v-for="(user, i) in users"
        :key="user.id || i"
        class="rank-item"
        :class="{ 'top-3': i < 3 }"
      >
        <view class="rank-num" :class="'rank-' + (i + 1)">
          <text v-if="i === 0">🥇</text>
          <text v-else-if="i === 1">🥈</text>
          <text v-else-if="i === 2">🥉</text>
          <text v-else>{{ i + 1 }}</text>
        </view>

        <view class="rank-avatar">{{ (user.nickname || '匿')[0] }}</view>

        <view class="rank-info">
          <text class="rank-name">{{ user.nickname || '匿名探索者' }}</text>
          <text class="rank-desc">已通关 {{ user.completedCount || 0 }} 地区</text>
        </view>

        <view class="rank-score">
          <text class="score-num">{{ user.totalScore || 0 }}</text>
          <text class="score-label">分</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { ensureLogin, userApi } from '../../api/index.js';

const users = ref([]);
const loading = ref(true);

onMounted(async () => {
  try {
    await ensureLogin();
    users.value = await userApi.getRanking(50);
  } catch (_) {
  } finally {
    loading.value = false;
  }
});
</script>

<style scoped>
.page { min-height: 100vh; padding: var(--space-lg); }

.empty { text-align: center; padding: 120rpx 0; color: var(--color-text-secondary); }
.empty-icon { font-size: 56rpx; display: block; margin-bottom: var(--space-md); }
.empty text { font-size: var(--font-md); }

.rank-list { display: flex; flex-direction: column; gap: var(--space-md); }

.rank-item {
  display: flex;
  align-items: center;
  background: var(--color-surface);
  border-radius: var(--radius-md);
  padding: var(--space-lg);
  box-shadow: var(--shadow-card);
  transition: transform 0.15s;
}
.rank-item:active { transform: scale(0.98); }

.top-3 {
  border: 2rpx solid var(--color-accent);
  box-shadow: 0 4rpx 20rpx rgba(245, 166, 35, 0.12);
}

.rank-num {
  width: 56rpx;
  height: 56rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: var(--font-sm);
  background: #f0f0f0;
  color: #888;
  margin-right: var(--space-lg);
  flex-shrink: 0;
}
.rank-1 { background: var(--color-gold); }
.rank-2 { background: var(--color-silver); }
.rank-3 { background: var(--color-bronze); }

.rank-avatar {
  width: 72rpx;
  height: 72rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-primary), var(--color-primary-light));
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: var(--font-lg);
  font-weight: 700;
  margin-right: var(--space-lg);
  flex-shrink: 0;
}

.rank-info { flex: 1; display: flex; flex-direction: column; min-width: 0; }
.rank-name { font-size: var(--font-md); font-weight: 600; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.rank-desc { font-size: var(--font-xs); color: var(--color-text-secondary); margin-top: 4rpx; }

.rank-score { text-align: right; flex-shrink: 0; }
.score-num { font-size: var(--font-xl); font-weight: 800; color: var(--color-accent); }
.score-label { font-size: var(--font-xs); color: var(--color-text-secondary); margin-left: 4rpx; }
</style>
