<template>
  <view class="page">
    <!-- 用户信息卡片 -->
    <view class="hero">
      <view class="avatar">{{ (profile.nickname || '华')[0] }}</view>
      <text class="nickname">{{ profile.nickname || '匿名探索者' }}</text>
      <view v-if="!profile.nickname" class="hint" @tap="editNickname">
        <text>✏️ 点击设置昵称</text>
      </view>
    </view>

    <!-- 统计数据 -->
    <view class="stats">
      <view class="stat-item stat-score">
        <text class="stat-icon">⭐</text>
        <text class="stat-num">{{ profile.totalScore || 0 }}</text>
        <text class="stat-label">总积分</text>
      </view>
      <view class="stat-item stat-done">
        <text class="stat-icon">✅</text>
        <text class="stat-num">{{ profile.completedCount || 0 }}</text>
        <text class="stat-label">已通关</text>
      </view>
      <view class="stat-item stat-streak">
        <text class="stat-icon">🔥</text>
        <text class="stat-num">{{ profile.maxStreak || 0 }}</text>
        <text class="stat-label">最长连胜</text>
      </view>
    </view>

    <!-- 功能菜单 -->
    <view class="menu">
      <view class="menu-item" @tap="goFavorites">
        <text class="menu-icon">❤️</text>
        <text class="menu-text">我的收藏</text>
        <text class="arrow">›</text>
      </view>
      <view class="menu-item" @tap="editNickname">
        <text class="menu-icon">✏️</text>
        <text class="menu-text">修改昵称</text>
        <text class="arrow">›</text>
      </view>
      <view class="menu-item" @tap="shareApp">
        <text class="menu-icon">📤</text>
        <text class="menu-text">分享给好友</text>
        <text class="arrow">›</text>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { ensureLogin, userApi } from '../../api/index.js';

const profile = ref({ nickname: '', totalScore: 0, completedCount: 0, maxStreak: 0 });

onMounted(async () => {
  try {
    await ensureLogin();
    profile.value = await userApi.getProfile();
  } catch (_) {}
});

function editNickname() {
  uni.showModal({
    title: '设置昵称',
    editable: true,
    placeholderText: profile.value.nickname || '请输入昵称',
    success: async (res) => {
      if (res.confirm && res.content) {
        try {
          await userApi.updateProfile({ nickname: res.content.trim() });
          profile.value = await userApi.getProfile();
          uni.showToast({ title: '昵称已更新', icon: 'success' });
        } catch (e) {
          uni.showToast({ title: e.message, icon: 'none' });
        }
      }
    },
  });
}

function goFavorites() {
  uni.switchTab({ url: '/pages/index/index' });
  uni.showToast({ title: '在首页筛选收藏', icon: 'none' });
}

function shareApp() {
  uni.showToast({ title: '分享功能开发中', icon: 'none' });
}
</script>

<style scoped>
.page { min-height: 100vh; }

.hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 80rpx 0 var(--space-2xl);
  background: var(--gradient-hero);
}
.avatar {
  width: 128rpx;
  height: 128rpx;
  border-radius: 50%;
  background: rgba(255,255,255,0.18);
  border: 4rpx solid rgba(255,255,255,0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 56rpx;
  font-weight: 700;
  color: #fff;
  margin-bottom: var(--space-lg);
}
.nickname { font-size: var(--font-xl); font-weight: 700; color: #fff; }
.hint {
  margin-top: var(--space-sm);
  padding: var(--space-xs) var(--space-xl);
  background: rgba(255,255,255,0.15);
  border-radius: var(--radius-full);
}
.hint text { font-size: var(--font-sm); color: rgba(255,255,255,0.8); }

.stats { display: flex; margin: var(--space-xl) var(--space-lg); gap: var(--space-md); }
.stat-item {
  flex: 1;
  text-align: center;
  padding: var(--space-xl) 0;
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
}
.stat-icon { font-size: 28rpx; display: block; margin-bottom: var(--space-sm); }
.stat-num { font-size: var(--font-2xl); font-weight: 800; display: block; line-height: 1.2; }
.stat-score .stat-num { color: var(--color-accent); }
.stat-done .stat-num { color: var(--color-success); }
.stat-streak .stat-num { color: #3498db; }
.stat-label { font-size: var(--font-xs); color: var(--color-text-secondary); margin-top: var(--space-xs); display: block; }

.menu { margin: 0 var(--space-lg); }
.menu-item {
  display: flex;
  align-items: center;
  padding: var(--space-xl) var(--space-lg);
  background: var(--color-surface);
  border-radius: var(--radius-md);
  margin-bottom: var(--space-md);
  box-shadow: var(--shadow-card);
  gap: var(--space-md);
  transition: transform 0.1s;
}
.menu-item:active { transform: scale(0.98); }
.menu-icon { font-size: var(--font-lg); }
.menu-text { flex: 1; font-size: var(--font-md); font-weight: 500; }
.arrow { color: var(--color-text-secondary); font-size: var(--font-2xl); line-height: 1; }
</style>
