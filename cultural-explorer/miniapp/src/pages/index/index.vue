<template>
  <view class="page">
    <view class="hero"><text class="title">华夏文化探索</text><text class="subtitle">读山河 · 知历史 · 见人文</text></view>
    <view class="search card"><input v-model="keyword" confirm-type="search" placeholder="搜索省份或文化关键词" @confirm="load"/><text @tap="load">搜索</text></view>
    <view v-if="loading" class="empty">正在展开华夏画卷…</view>
    <view v-else class="grid">
      <view v-for="region in regions" :key="region.id" class="region card" @tap="open(region.id)">
        <text class="seal">{{ region.shortName || '华' }}</text><text class="name">{{ region.name }}</text><text class="capital">省会 {{ region.capital || '-' }}</text>
        <text v-if="region.userProgress?.isCompleted" class="done">已通关</text>
      </view>
    </view>
  </view>
</template>
<script setup>
import { ref, onMounted } from 'vue'; import { ensureLogin, request } from '../../api/index.js';
const regions = ref([]), keyword = ref(''), loading = ref(true);
async function load() { loading.value = true; try { await ensureLogin(); const data = await request(`/regions?limit=50&keyword=${encodeURIComponent(keyword.value)}`); regions.value = data.items; } catch (e) { uni.showToast({ title: e.message, icon: 'none' }); } finally { loading.value = false; } }
function open(id) { uni.navigateTo({ url: `/pages/detail/detail?id=${id}` }); }
onMounted(load);
</script>
<style scoped>
.hero { padding: 36rpx 6rpx 42rpx; display:flex; flex-direction:column; }.title{font-size:52rpx;font-weight:800;color:#8b1e2d}.subtitle{margin-top:10rpx;color:#8c7568;letter-spacing:6rpx}.search{display:flex;align-items:center;padding:22rpx 28rpx;margin-bottom:28rpx}.search input{flex:1}.search text{color:#8b1e2d;font-weight:600}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22rpx}.region{position:relative;min-height:210rpx;padding:28rpx;display:flex;flex-direction:column}.seal{font-size:52rpx;color:#b54a3a}.name{font-size:34rpx;font-weight:700;margin-top:auto}.capital{font-size:23rpx;color:#8c7568;margin-top:6rpx}.done{position:absolute;right:18rpx;top:18rpx;color:#277a4b;font-size:22rpx}.empty{text-align:center;padding:100rpx 0;color:#8c7568}
</style>

