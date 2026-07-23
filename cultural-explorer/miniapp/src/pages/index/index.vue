<template>
  <view class="root-page">
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
      <input v-model="keyword" confirm-type="search" placeholder="搜索地区..." @confirm="onSearch" />
    </view>

    <view v-if="loading" class="empty">加载中...</view>
    <view v-else-if="error" class="empty">
      <text class="empty-icon">⚠️</text>
      <text>加载失败，请检查网络连接</text>
      <button class="retry-btn" @tap="fetchRegions">重试</button>
    </view>
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
            <text class="capital">{{ region.capital || '-' }}</text>
            <text class="stamp" v-if="region._count?.records">✅ {{ region._count.records }}人通关</text>
          </view>
          <text class="desc">{{ region.description?.slice(0, 60) || '' }}</text>
        </view>
        <text class="arrow">›</text>
      </view>
    </view>
    <view v-if="hasMore && !loading" class="load-more" @tap="loadMore">加载更多</view>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { request } from '../../api/index.js';

const regions = ref([]);
const keyword = ref('');
const page = ref(1);
const loading = ref(true);
const error = ref(false);
const hasMore = ref(false);

async function fetchRegions() {
  loading.value = true;
  error.value = false;
  try {
    const data = await request('/regions', { page: page.value, limit: 20, keyword: keyword.value });
    const items = data?.items || data?.data?.items || [];
    if (page.value === 1) regions.value = items;
    else regions.value = [...regions.value, ...items];
    hasMore.value = items.length >= 20;
  } catch (e) {
    if (page.value === 1) error.value = true;
    console.error('加载失败:', e);
  } finally {
    loading.value = false;
  }
}

function onSearch() { page.value = 1; fetchRegions(); }
async function loadMore() { page.value++; await fetchRegions(); }
function open(id) { uni.navigateTo({ url: `/pages/detail/detail?id=${id}` }); }
function goRanking() { uni.navigateTo({ url: '/pages/ranking/ranking' }); }
function goProfile() { uni.navigateTo({ url: '/pages/profile/profile' }); }

onMounted(fetchRegions);
</script>

<style scoped>
.root-page { min-height: 100vh; padding: 24rpx; background: #fffaf0; padding-bottom: 48rpx; }
.hero { margin: 48rpx 0 32rpx; display: flex; flex-direction: column; align-items: center; }
.title { font-size: 44rpx; font-weight: 900; color: #8b1e2d; }
.subtitle { margin-top: 8rpx; font-size: 26rpx; color: #8c7568; }
.nav-btns { margin-top: 20rpx; display: flex; gap: 32rpx; }
.nav-btn { font-size: 28rpx; color: #8b1e2d; font-weight: 600; padding: 8rpx 20rpx; border: 2rpx solid rgba(139,30,45,0.2); border-radius: 40rpx; }
.nav-btn:active { background: rgba(139,30,45,0.05); }
.search { display: flex; align-items: center; gap: 16rpx; padding: 20rpx 28rpx; margin-bottom: 24rpx; }
.search input { flex: 1; font-size: 28rpx; border: none; outline: none; background: transparent; }
.search-icon { font-size: 32rpx; }
.grid { display: flex; flex-direction: column; gap: 16rpx; }
.region { display: flex; align-items: center; gap: 20rpx; padding: 24rpx 28rpx; }
.seal { width: 80rpx; height: 80rpx; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #8b1e2d, #b54a3a); border-radius: 20rpx; color: #fff; font-size: 36rpx; font-weight: 800; flex-shrink: 0; }
.region-body { flex: 1; display: flex; flex-direction: column; gap: 4rpx; min-width: 0; }
.name { font-size: 32rpx; font-weight: 700; color: #2d2520; }
.capital-row { display: flex; align-items: center; gap: 8rpx; }
.pin { font-size: 22rpx; }
.capital { font-size: 22rpx; color: #8c7568; }
.stamp { margin-left: auto; font-size: 20rpx; color: #66bb6a; background: rgba(102,187,106,0.1); padding: 2rpx 12rpx; border-radius: 20rpx; }
.desc { margin-top: 4rpx; font-size: 22rpx; color: #8c7568; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.arrow { font-size: 36rpx; color: #d4c5b0; flex-shrink: 0; }
.empty { text-align: center; padding: 120rpx 0; color: #8c7568; display: flex; flex-direction: column; align-items: center; gap: 16rpx; font-size: 28rpx; }
.empty-icon { font-size: 64rpx; }
.retry-btn { margin-top: 16rpx; padding: 12rpx 32rpx; background: #8b1e2d; color: #fff; border-radius: 40rpx; font-size: 26rpx; border: none; }
.load-more { padding: 24rpx; text-align: center; color: #8b1e2d; font-size: 26rpx; }
</style>
