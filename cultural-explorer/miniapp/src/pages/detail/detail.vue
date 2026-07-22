<template>
  <view v-if="region" class="page">
    <!-- 封面图 -->
    <image v-if="region.coverImage" class="cover" :src="region.coverImage" mode="aspectFill" />

    <!-- 地区头部 -->
    <view class="heading">
      <text class="seal">{{ region.shortName || '华' }}</text>
      <view class="heading-info">
        <view class="name-row">
          <text class="name">{{ region.name }}</text>
          <text class="fav-btn" @tap="toggleFav">{{ isFav ? '❤️' : '🤍' }}</text>
        </view>
        <view class="meta-row">
          <text class="meta-item">📍 省会 {{ region.capital || '-' }}</text>
          <text class="meta-divider">·</text>
          <text class="meta-item">🗺️ {{ region.area || '-' }}</text>
        </view>
      </view>
    </view>

    <!-- 简介 -->
    <text class="intro">{{ region.description }}</text>

    <!-- 分类内容 -->
    <view v-for="section in sections" :key="section.key" class="section">
      <view class="section-header">
        <text class="section-icon">{{ section.icon }}</text>
        <text class="section-title">{{ section.title }}</text>
      </view>
      <text class="section-text">{{ region[section.key] }}</text>
    </view>

    <!-- 记忆口诀 -->
    <view v-if="region.mnemonic" class="mnemonic">
      <view class="section-header">
        <text class="section-icon">🤖</text>
        <text class="section-title">AI 记忆口诀</text>
      </view>
      <text class="mnemonic-text">{{ region.mnemonic }}</text>
    </view>

    <!-- 地标 -->
    <view v-if="region.landmarks && region.landmarks.length" class="section">
      <view class="section-header">
        <text class="section-icon">📍</text>
        <text class="section-title">代表地标</text>
      </view>
      <view v-for="item in region.landmarks" :key="item.id" class="landmark card">
        <text class="landmark-name">{{ item.name }}</text>
        <text v-if="item.description" class="landmark-desc">{{ item.description }}</text>
      </view>
    </view>

    <!-- 开始闯关 -->
    <button class="quiz-btn primary" @tap="quiz">
      <text class="quiz-btn-text">开始闯关（{{ region.questionCount || 0 }}题）</text>
    </button>
  </view>
</template>

<script setup>
import { ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { request } from '../../api/index.js';

const region = ref(null);
const isFav = ref(false);
const sections = [
  { icon: '🏔', title: '地理', key: 'geography' },
  { icon: '🏯', title: '历史', key: 'history' },
  { icon: '🎭', title: '文化', key: 'culture' },
];
let id = '';

onLoad(async (options) => {
  id = options.id;
  try {
    region.value = await request('/regions/' + id);
    isFav.value = region.value?.isFavorited || false;
    uni.setNavigationBarTitle({ title: region.value?.name || '地区详情' });
  } catch (_) {}
});

async function toggleFav() {
  try {
    await request('/regions/' + id + '/favorite', { method: 'POST' });
    isFav.value = !isFav.value;
    uni.showToast({ title: isFav.value ? '已收藏' : '已取消', icon: 'none', duration: 1000 });
  } catch (_) {}
}

function quiz() {
  uni.navigateTo({ url: '/pages/quiz/quiz?regionId=' + id + '&name=' + encodeURIComponent(region.value.name) });
}
</script>

<style scoped>
.cover { width: 100%; height: 400rpx; border-radius: var(--radius-lg); margin-bottom: var(--space-lg); }

.heading { display: flex; align-items: center; margin: var(--space-lg) 0; gap: var(--space-lg); }
.heading-info { display: flex; flex-direction: column; flex: 1; }
.name-row { display: flex; align-items: center; }
.seal { font-size: 80rpx; color: var(--color-primary); line-height: 1; }
.name { font-size: var(--font-2xl); font-weight: 800; flex: 1; }
.fav-btn { font-size: 44rpx; padding: var(--space-sm); }
.meta-row { display: flex; align-items: center; gap: var(--space-sm); margin-top: var(--space-xs); }
.meta-item { font-size: var(--font-sm); color: var(--color-text-secondary); }
.meta-divider { color: var(--color-text-secondary); opacity: 0.4; }

.intro { font-size: var(--font-md); line-height: var(--leading-relaxed); color: var(--color-text); margin-top: var(--space-lg); display: block; }

.section { margin-top: var(--space-2xl); display: flex; flex-direction: column; }
.section-header { display: flex; align-items: center; gap: var(--space-sm); margin-bottom: var(--space-md); }
.section-icon { font-size: var(--font-lg); }
.section-title { font-size: var(--font-lg); font-weight: 700; color: var(--color-primary); }
.section-text { font-size: var(--font-md); line-height: var(--leading-relaxed); color: var(--color-text); }

.mnemonic {
  margin-top: var(--space-2xl);
  padding: var(--space-xl);
  background: var(--color-mnemonic-bg);
  border-radius: var(--radius-lg);
  display: flex;
  flex-direction: column;
}
.mnemonic-text { font-size: var(--font-md); line-height: var(--leading-relaxed); margin-top: var(--space-md); }

.landmark {
  display: flex;
  flex-direction: column;
  padding: var(--space-lg);
  margin-bottom: var(--space-md);
}
.landmark-name { font-size: var(--font-md); font-weight: 600; }
.landmark-desc { font-size: var(--font-sm); color: var(--color-text-secondary); margin-top: var(--space-xs); }

.quiz-btn { margin-top: var(--space-2xl); width: 100%; }
.quiz-btn-text { font-size: var(--font-lg); font-weight: 600; }
</style>
