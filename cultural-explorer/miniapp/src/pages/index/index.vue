<template>
  <view class="page">
    <view class="hero">
      <text class="title">🏮 华夏文化探索</text>
      <text class="subtitle">读山河 · 知历史 · 见人文</text>
      <view class="nav-btns">
        <text class="nav-btn" @tap="goRanking">🏆 排行</text>
        <text class="nav-btn" @tap="goProfile">👤 我的</text>
      </view>
    </view>

    <view class="search card">
      <text class="search-icon">🔍</text>
      <input v-model="keyword" confirm-type="search" placeholder="搜索地区..." />
    </view>

    <view v-if="loading" class="empty">加载中...</view>

    <view v-else-if="regions.length === 0" class="empty">
      <text class="empty-icon">🗺️</text>
      <text>暂无地区数据</text>
    </view>

    <view v-else class="grid">
      <view v-for="region in regions" :key="region.id" class="region card" @tap="open(region.id)">
        <text class="seal">{{ region.shortName || '华' }}</text>
        <view class="region-body">
          <text class="name">{{ region.name }}</text>
          <view class="capital-row">
            <text class="pin">📍</text>
            <text class="capital">省会 {{ region.capital || '-' }}</text>
          </view>
        </view>
        <view v-if="region.userProgress && region.userProgress.isCompleted" class="done">
          <text class="done-badge">✓ 已通关</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref } from 'vue';
import { ensureLogin, request } from '../../api/index.js';

const regions = ref([]);
const keyword = ref('');
const loading = ref(true);

async function load() {
  loading.value = true;
  try {
    await ensureLogin();
    const data = await request('/regions?limit=50&keyword=' + encodeURIComponent(keyword.value));
    regions.value = data.items || [];
  } catch (e) {
    // silent fail, show empty
  }
  loading.value = false;
}

function open(id) {
  uni.navigateTo({ url: '/pages/detail/detail?id=' + id });
}
function goRanking() {
  uni.navigateTo({ url: '/pages/ranking/ranking' });
}
function goProfile() {
  uni.navigateTo({ url: '/pages/profile/profile' });
}

load();
</script>

<style scoped>
.page { min-height: 100vh; padding: 0 var(--space-lg) var(--space-xl); }

.hero { padding: var(--space-xl) 0 var(--space-lg); }
.title { font-size: var(--font-2xl); font-weight: 800; color: var(--color-primary); line-height: 1.2; }
.subtitle { font-size: var(--font-sm); color: var(--color-text-secondary); margin-top: var(--space-sm); display: block; letter-spacing: 6rpx; }
.nav-btns { margin-top: var(--space-lg); display: flex; gap: var(--space-md); }
.nav-btn {
  font-size: var(--font-sm);
  color: var(--color-primary);
  background: var(--color-primary);
  color: #fff;
  padding: var(--space-sm) var(--space-xl);
  border-radius: var(--radius-full);
  font-weight: 500;
  transition: opacity 0.2s;
}
.nav-btn:active { opacity: 0.85; }

.search { display: flex; align-items: center; padding: var(--space-md) var(--space-lg); margin-bottom: var(--space-lg); gap: var(--space-md); }
.search input { flex: 1; font-size: var(--font-md); }
.search-icon { font-size: 32rpx; opacity: 0.5; }

.empty { text-align: center; padding: 120rpx 0; }
.empty, .empty text { color: var(--color-text-secondary); font-size: var(--font-md); line-height: var(--leading-relaxed); }
.empty-icon { font-size: 56rpx; display: block; margin-bottom: var(--space-md); }

.grid { display: flex; flex-wrap: wrap; }
.region {
  width: calc(50% - 11rpx);
  min-height: 220rpx;
  padding: var(--space-xl);
  margin-right: 22rpx;
  margin-bottom: 22rpx;
  position: relative;
  display: flex;
  flex-direction: column;
  transition: transform 0.15s, box-shadow 0.15s;
}
.region:active { transform: scale(0.97); box-shadow: var(--shadow-card-hover); }
.region:nth-child(2n) { margin-right: 0; }

.seal { font-size: 52rpx; color: var(--color-primary-light); display: block; line-height: 1; }
.region-body { margin-top: auto; }
.name { font-size: var(--font-lg); font-weight: 700; display: block; margin-top: var(--space-sm); }
.capital-row { display: flex; align-items: center; gap: 4rpx; margin-top: var(--space-xs); }
.pin { font-size: var(--font-xs); }
.capital { font-size: var(--font-xs); color: var(--color-text-secondary); }

.done { position: absolute; right: 12rpx; top: 12rpx; }
.done-badge {
  font-size: 20rpx;
  color: #fff;
  background: var(--color-success);
  padding: 4rpx 12rpx;
  border-radius: var(--radius-sm);
  font-weight: 600;
}
</style>
