<template>
  <view v-if="region" class="page">
    <!-- 封面图 -->
    <image v-if="region.heroImage || region.coverImage" class="cover" :src="region.heroImage || region.coverImage" mode="aspectFill" />

    <!-- 地区头部 -->
    <view class="heading">
      <text class="seal">{{ region.shortName || '华' }}</text>
      <view class="heading-info">
        <view class="name-row">
          <text class="name">{{ region.name }}</text>
          <text class="fav-btn" @tap="toggleFav">{{ isFav ? '❤️' : '🤍' }}</text>
        </view>
        <view class="meta-row">
          <text class="meta-item">📍 {{ region.capital || '-' }}</text>
          <text class="meta-divider">·</text>
          <text class="meta-item">🗺️ {{ region.area || '-' }}</text>
          <text v-if="region.region" class="meta-divider">·</text>
          <text v-if="region.region" class="meta-item">🧭 {{ region.region }}</text>
        </view>
        <view v-if="region.ancientName || region.foundingYear" class="meta-row" style="margin-top: 4rpx;">
          <text v-if="region.ancientName" class="meta-item">📜 古称 {{ region.ancientName }}</text>
          <text v-if="region.ancientName && region.foundingYear" class="meta-divider">·</text>
          <text v-if="region.foundingYear" class="meta-item">🏛️ 建制 {{ region.foundingYear }}</text>
        </view>
      </view>
    </view>

    <!-- 简介 -->
    <text class="intro">{{ region.description }}</text>

    <!-- 音频导览 -->
    <view v-if="region.audioGuide || region.audioShort" class="audio-bar" @tap="showAudioOptions">
      <text class="audio-icon">🎧</text>
      <view class="audio-info">
        <text class="audio-title">AI 语音导览</text>
        <text class="audio-desc">了解这片土地的故事</text>
      </view>
      <text class="audio-arrow">›</text>
    </view>

    <!-- 内容章节 -->
    <view v-if="chapters.length" class="section">
      <view class="section-header">
        <text class="section-icon">📖</text>
        <text class="section-title">内容章节</text>
      </view>
      <view v-for="ch in chapters" :key="ch.id" class="chapter-card">
        <view class="chapter-head">
          <text class="chapter-icon">{{ getChapterIcon(ch.title) }}</text>
          <view class="chapter-text">
            <text class="chapter-title">{{ ch.title }}</text>
            <text v-if="ch.subtitle" class="chapter-subtitle">{{ ch.subtitle }}</text>
          </view>
        </view>
        <text class="chapter-content">{{ ch.content }}</text>
      </view>
    </view>

    <!-- 历史时间轴 -->
    <view v-if="timeline.length" class="section">
      <view class="section-header">
        <text class="section-icon">⏳</text>
        <text class="section-title">历史时间轴</text>
      </view>
      <view class="timeline">
        <view v-for="(ev, i) in timeline" :key="ev.id" class="tl-item">
          <view class="tl-dot" :class="{ last: i === timeline.length - 1 }">
            <view class="dot" />
            <view v-if="i < timeline.length - 1" class="line" />
          </view>
          <view class="tl-card">
            <view class="tl-header">
              <text class="tl-year">{{ ev.year }}</text>
              <text v-if="ev.dynasty" class="tl-dynasty">{{ ev.dynasty }}</text>
            </view>
            <text class="tl-title">{{ ev.title }}</text>
            <text v-if="ev.description" class="tl-desc">{{ ev.description }}</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 名人 -->
    <view v-if="region.famousPeople && region.famousPeople.length" class="section">
      <view class="section-header">
        <text class="section-icon">⭐</text>
        <text class="section-title">人物·星光</text>
      </view>
      <scroll-view scroll-x class="people-scroll">
        <view v-for="p in region.famousPeople" :key="p.name" class="people-card">
          <text class="people-avatar">{{ (p.name || '?')[0] }}</text>
          <text class="people-name">{{ p.name }}</text>
          <text v-if="p.title" class="people-title">{{ p.title }}</text>
          <text v-if="p.dynasty" class="people-dynasty">{{ p.dynasty }}</text>
        </view>
      </scroll-view>
    </view>

    <!-- 美食 -->
    <view v-if="cuisines.length" class="section">
      <view class="section-header">
        <text class="section-icon">🍜</text>
        <text class="section-title">特色美食</text>
      </view>
      <view class="cuisine-grid">
        <view v-for="c in cuisines" :key="c.id" class="cuisine-item">
          <text class="cuisine-name">{{ c.name }}</text>
          <text v-if="c.category" class="cuisine-cat">{{ c.category }}</text>
          <text v-if="c.description" class="cuisine-desc">{{ c.description }}</text>
        </view>
      </view>
    </view>

    <!-- 非遗 -->
    <view v-if="heritages.length" class="section">
      <view class="section-header">
        <text class="section-icon">🏛️</text>
        <text class="section-title">非物质文化遗产</text>
      </view>
      <view v-for="h in heritages" :key="h.id" class="heritage-item">
        <text class="heritage-icon">{{ (h.name || '非')[0] }}</text>
        <view class="heritage-info">
          <view class="heritage-head">
            <text class="heritage-name">{{ h.name }}</text>
            <text v-if="h.level" class="heritage-level">{{ h.level }}</text>
          </view>
          <text v-if="h.description" class="heritage-desc">{{ h.description }}</text>
        </view>
      </view>
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

  <view v-else class="page empty">加载中...</view>
</template>

<script setup>
import { ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { request } from '../../api/index.js';

const region = ref(null);
const isFav = ref(false);
const chapters = ref([]);
const timeline = ref([]);
const cuisines = ref([]);
const heritages = ref([]);
let id = '';

const chapterIcons = { '印象': '🌄', '初见': '🌄', '地理': '🏔', '风物': '🏔', '历史': '🏯', '时光': '🏯', '文化': '🎭', '传承': '🎭', '人物': '⭐', '星光': '⭐', '探索': '📍', '足迹': '📍', '美食': '🍜' };

function getChapterIcon(title) {
  for (const [k, v] of Object.entries(chapterIcons)) {
    if (title.includes(k)) return v;
  }
  return '📄';
}

onLoad(async (options) => {
  id = options.id;
  try {
    const [r, ch, tl, cu, he] = await Promise.all([
      request('/regions/' + id),
      request('/regions/' + id + '/chapters').catch(() => []),
      request('/regions/' + id + '/timeline').catch(() => []),
      request('/regions/' + id + '/cuisine').catch(() => []),
      request('/regions/' + id + '/heritage').catch(() => []),
    ]);
    region.value = r;
    chapters.value = ch || [];
    timeline.value = tl || [];
    cuisines.value = cu || [];
    heritages.value = he || [];
    isFav.value = r?.isFavorited || false;
    uni.setNavigationBarTitle({ title: r?.name || '地区详情' });
  } catch (_) {}
});

async function toggleFav() {
  try {
    await request('/regions/' + id + '/favorite', { method: 'POST' });
    isFav.value = !isFav.value;
    uni.showToast({ title: isFav.value ? '已收藏' : '已取消', icon: 'none', duration: 1000 });
  } catch (_) {}
}

function showAudioOptions() {
  const items = [];
  if (region.value.audioShort) items.push('精华版 (1-2分钟)');
  if (region.value.audioGuide) items.push('完整版 (5-8分钟)');
  uni.showActionSheet({
    itemList: items,
    success: (res) => {
      const url = res.tapIndex === 0 ? region.value.audioShort : region.value.audioGuide;
      if (url) uni.showToast({ title: '音频播放功能开发中', icon: 'none' });
    },
  });
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
.meta-row { display: flex; align-items: center; gap: var(--space-sm); }
.meta-item { font-size: var(--font-sm); color: var(--color-text-secondary); }
.meta-divider { color: var(--color-text-secondary); opacity: 0.4; }

.intro { font-size: var(--font-md); line-height: var(--leading-relaxed); color: var(--color-text); margin-top: var(--space-lg); display: block; }

/* 音频 */
.audio-bar { display: flex; align-items: center; margin-top: var(--space-xl); padding: var(--space-lg); background: #fff; border-radius: var(--radius-lg); box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); gap: var(--space-md); }
.audio-bar:active { transform: scale(0.98); }
.audio-icon { font-size: 44rpx; }
.audio-info { flex: 1; display: flex; flex-direction: column; }
.audio-title { font-size: var(--font-md); font-weight: 700; }
.audio-desc { font-size: var(--font-sm); color: var(--color-text-secondary); }
.audio-arrow { font-size: 40rpx; color: var(--color-text-secondary); }

/* 章节 */
.section { margin-top: var(--space-2xl); display: flex; flex-direction: column; }
.section-header { display: flex; align-items: center; gap: var(--space-sm); margin-bottom: var(--space-md); }
.section-icon { font-size: var(--font-lg); }
.section-title { font-size: var(--font-lg); font-weight: 700; color: var(--color-primary); }

.chapter-card { background: #fff; border-radius: var(--radius-md); padding: var(--space-lg); margin-bottom: var(--space-sm); box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.04); }
.chapter-head { display: flex; align-items: flex-start; gap: var(--space-sm); margin-bottom: var(--space-sm); }
.chapter-icon { font-size: 36rpx; }
.chapter-text { flex: 1; display: flex; flex-direction: column; }
.chapter-title { font-size: var(--font-md); font-weight: 700; color: var(--color-primary); }
.chapter-subtitle { font-size: var(--font-xs); color: var(--color-text-secondary); }
.chapter-content { font-size: var(--font-sm); line-height: var(--leading-relaxed); color: var(--color-text); display: -webkit-box; -webkit-line-clamp: 5; -webkit-box-orient: vertical; overflow: hidden; }

/* 时间轴 */
.timeline { display: flex; flex-direction: column; }
.tl-item { display: flex; gap: var(--space-md); }
.tl-dot { display: flex; flex-direction: column; align-items: center; width: 24rpx; flex-shrink: 0; padding-top: 8rpx; }
.dot { width: 16rpx; height: 16rpx; border-radius: 50%; background: var(--color-primary); border: 3rpx solid #f5a623; }
.line { width: 2rpx; flex: 1; background: rgba(139,30,45,0.15); min-height: 40rpx; }
.tl-dot.last .dot { background: #f5a623; }
.tl-card { flex: 1; background: #fff; border-radius: var(--radius-md); padding: var(--space-md); margin-bottom: var(--space-md); box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.04); }
.tl-header { display: flex; align-items: center; gap: var(--space-sm); margin-bottom: 6rpx; }
.tl-year { background: var(--color-primary); color: #fff; font-size: 20rpx; padding: 2rpx 10rpx; border-radius: 6rpx; font-weight: 700; }
.tl-dynasty { font-size: 20rpx; color: var(--color-text-secondary); }
.tl-title { font-size: 28rpx; font-weight: 600; display: block; }
.tl-desc { font-size: 22rpx; color: var(--color-text-secondary); margin-top: 4rpx; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

/* 名人 */
.people-scroll { display: flex; flex-direction: row; white-space: nowrap; }
.people-card { display: inline-flex; flex-direction: column; align-items: center; background: #fff; border-radius: var(--radius-md); padding: var(--space-lg); margin-right: var(--space-md); width: 160rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.04); }
.people-avatar { width: 64rpx; height: 64rpx; border-radius: 50%; background: rgba(139,30,45,0.1); display: flex; align-items: center; justify-content: center; font-size: 32rpx; font-weight: 800; color: var(--color-primary); text-align: center; line-height: 64rpx; }
.people-name { font-size: 26rpx; font-weight: 700; margin-top: 8rpx; text-align: center; }
.people-title { font-size: 20rpx; color: #f5a623; text-align: center; }
.people-dynasty { font-size: 20rpx; color: var(--color-text-secondary); text-align: center; }

/* 美食 */
.cuisine-grid { display: flex; flex-wrap: wrap; gap: var(--space-sm); }
.cuisine-item { width: calc(50% - 8rpx); background: #fff; border-radius: var(--radius-md); padding: var(--space-md); box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.04); }
.cuisine-name { font-size: var(--font-sm); font-weight: 700; display: block; }
.cuisine-cat { font-size: 18rpx; color: #f5a623; background: rgba(245,166,35,0.1); padding: 1rpx 8rpx; border-radius: 6rpx; margin-left: 6rpx; }
.cuisine-desc { font-size: 20rpx; color: var(--color-text-secondary); margin-top: 4rpx; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

/* 非遗 */
.heritage-item { display: flex; gap: var(--space-md); background: #fff; border-radius: var(--radius-md); padding: var(--space-md); margin-bottom: var(--space-sm); box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.04); align-items: center; }
.heritage-icon { width: 60rpx; height: 60rpx; border-radius: var(--radius-sm); background: rgba(139,30,45,0.08); display: flex; align-items: center; justify-content: center; font-size: 28rpx; font-weight: 800; color: var(--color-primary); flex-shrink: 0; }
.heritage-info { flex: 1; }
.heritage-head { display: flex; align-items: center; gap: var(--space-sm); margin-bottom: 4rpx; }
.heritage-name { font-size: var(--font-sm); font-weight: 600; }
.heritage-level { font-size: 18rpx; color: #e67e22; background: #fff5f0; border: 1rpx solid #fdd5c0; padding: 1rpx 8rpx; border-radius: 6rpx; }
.heritage-desc { font-size: 22rpx; color: var(--color-text-secondary); display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

/* 口诀 */
.mnemonic { margin-top: var(--space-2xl); padding: var(--space-xl); background: var(--color-mnemonic-bg); border-radius: var(--radius-lg); display: flex; flex-direction: column; }
.mnemonic-text { font-size: var(--font-md); line-height: var(--leading-relaxed); margin-top: var(--space-md); }

/* 地标 */
.landmark { display: flex; flex-direction: column; padding: var(--space-lg); margin-bottom: var(--space-md); }
.landmark-name { font-size: var(--font-md); font-weight: 600; }
.landmark-desc { font-size: var(--font-sm); color: var(--color-text-secondary); margin-top: var(--space-xs); }

.quiz-btn { margin-top: var(--space-2xl); width: 100%; }
.quiz-btn-text { font-size: var(--font-lg); font-weight: 600; }

.empty { text-align: center; padding-top: 200rpx; color: #8c7568; }

.page { min-height: 100vh; padding: 24rpx; background: #fffaf0; padding-bottom: 48rpx; }
</style>
