<template>
  <view class="page">
    <!-- 用户头部 -->
    <view class="hero">
      <view class="avatar">{{ (profile.nickname || '华')[0] }}</view>
      <text class="nickname">{{ profile.nickname || '匿名探索者' }}</text>
      <view class="hint-row" v-if="!profile.nickname" @tap="editNickname">
        <text>✏️ 点击设置昵称</text>
      </view>
    </view>

    <!-- 签到卡片 -->
    <view class="checkin-card" @tap="doCheckin">
      <view class="checkin-left">
        <text class="checkin-icon">📅</text>
        <view>
          <text class="checkin-title">每日签到</text>
          <text class="checkin-desc" v-if="checkinStats">
            已连续签到 {{ checkinStats.currentStreak }} 天
          </text>
        </view>
      </view>
      <view class="checkin-btn" :class="{ done: checkedToday }">
        {{ checkedToday ? '已签到' : '签到 +10' }}
      </view>
    </view>

    <!-- 统计数据 -->
    <view class="stats">
      <view class="stat-item">
        <text class="stat-icon">⭐</text>
        <text class="stat-num gold">{{ profile.totalScore || 0 }}</text>
        <text class="stat-label">总积分</text>
      </view>
      <view class="stat-item">
        <text class="stat-icon">✅</text>
        <text class="stat-num green">{{ profile.completedCount || 0 }}</text>
        <text class="stat-label">已通关</text>
      </view>
      <view class="stat-item">
        <text class="stat-icon">🔥</text>
        <text class="stat-num blue">{{ profile.maxStreak || 0 }}</text>
        <text class="stat-label">连胜</text>
      </view>
    </view>

    <!-- 勋章墙 -->
    <view class="badge-section">
      <view class="section-header">
        <text class="section-title">🏅 勋章墙</text>
        <text class="section-more" @tap="showAllBadges">查看全部 ›</text>
      </view>
      <view class="badge-row">
        <view v-for="b in displayBadges" :key="b.id" class="badge-item" :class="{ locked: !b.earned }">
          <text class="badge-icon">{{ b.earned ? b.icon : '🔒' }}</text>
          <text class="badge-name">{{ b.earned ? b.name : '未解锁' }}</text>
        </view>
      </view>
    </view>

    <!-- 功能菜单 -->
    <view class="menu">
      <view class="menu-item" @tap="goFavorites">
        <text class="menu-icon">❤️</text>
        <text class="menu-text">我的收藏</text>
        <text class="arrow">›</text>
      </view>
      <view class="menu-item" @tap="goRanking">
        <text class="menu-icon">🏆</text>
        <text class="menu-text">全国排行榜</text>
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
import { ref, computed, onMounted } from 'vue';
import { ensureLogin, request, userApi } from '../../api/index.js';

const profile = ref({ nickname: '', totalScore: 0, completedCount: 0, maxStreak: 0 });
const badges = ref([]);
const checkinStats = ref(null);
const checkedToday = ref(false);
const showBadges = ref(false);

const displayBadges = computed(() => {
  const all = badges.value;
  return showBadges.value ? all : (all.slice(0, 5));
});

onMounted(async () => {
  try {
    await ensureLogin();
    profile.value = await userApi.getProfile();
    try { badges.value = await request('/badges/all'); } catch (_) {}
    try { checkinStats.value = await request('/checkin/stats'); checkedToday.value = isToday(checkinStats.value?.lastCheckinDate); } catch (_) {}
  } catch (_) {}
});

function isToday(date) {
  if (!date) return false;
  const d = new Date(date);
  const now = new Date();
  return d.toDateString() === now.toDateString();
}

async function doCheckin() {
  if (checkedToday.value) { uni.showToast({ title: '今日已签到', icon: 'none' }); return; }
  try {
    const result = await request('/checkin/daily', { method: 'POST' });
    checkedToday.value = true;
    checkinStats.value = { currentStreak: result.streak, total: (checkinStats.value?.total || 0) + 1 };
    uni.showToast({ title: `签到成功! +${result.reward}积分`, icon: 'success' });
    profile.value = await userApi.getProfile();
  } catch (e) {
    uni.showToast({ title: e?.data?.message || '签到失败', icon: 'none' });
  }
}

function showAllBadges() { showBadges.value = !showBadges.value; }

function editNickname() {
  uni.showModal({
    title: '设置昵称', editable: true,
    placeholderText: profile.value.nickname || '请输入昵称',
    success: async (res) => {
      if (res.confirm && res.content) {
        await userApi.updateProfile({ nickname: res.content.trim() });
        profile.value = await userApi.getProfile();
        uni.showToast({ title: '昵称已更新', icon: 'success' });
      }
    },
  });
}

function goFavorites() {
  uni.switchTab({ url: '/pages/index/index' });
  uni.showToast({ title: '在首页筛选收藏', icon: 'none' });
}

function goRanking() {
  uni.navigateTo({ url: '/pages/ranking/ranking' });
}

function shareApp() {
  const earnedCount = badges.value.filter(b => b.earned).length;
  const shareText = `🏯 我在「华夏文化探索」中游览了 ${profile.value.completedCount || 0}/34 个地区，获得了 ${profile.value.totalScore || 0} 积分和 ${earnedCount} 枚徽章！\n快来一起探索中华文化吧！`;
  uni.setClipboardData({
    data: shareText,
    success: () => {
      uni.showToast({ title: '分享文案已复制！', icon: 'success' });
    },
  });
}
</script>

<style scoped>
.page { min-height: 100vh; }

.hero { display: flex; flex-direction: column; align-items: center; padding: 80rpx 0 48rpx; background: linear-gradient(135deg, #8b1e2d, #b54a3a); }
.avatar { width: 128rpx; height: 128rpx; border-radius: 50%; background: rgba(255,255,255,0.18); border: 4rpx solid rgba(255,255,255,0.3); display: flex; align-items: center; justify-content: center; font-size: 56rpx; font-weight: 700; color: #fff; margin-bottom: 16rpx; }
.nickname { font-size: 44rpx; font-weight: 700; color: #fff; }
.hint-row { margin-top: 8rpx; padding: 4rpx 24rpx; background: rgba(255,255,255,0.15); border-radius: 40rpx; }
.hint-row text { font-size: 24rpx; color: rgba(255,255,255,0.8); }

/* 签到 */
.checkin-card { margin: 24rpx; display: flex; align-items: center; justify-content: space-between; background: #fff; border-radius: 20rpx; padding: 28rpx; box-shadow: 0 4rpx 20rpx rgba(80,40,20,0.06); }
.checkin-left { display: flex; align-items: center; gap: 16rpx; }
.checkin-icon { font-size: 48rpx; }
.checkin-title { font-size: 30rpx; font-weight: 700; display: block; }
.checkin-desc { font-size: 22rpx; color: #8c7568; margin-top: 4rpx; display: block; }
.checkin-btn { padding: 12rpx 28rpx; background: #f5a623; color: #fff; border-radius: 40rpx; font-size: 26rpx; font-weight: 600; }
.checkin-btn.done { background: #e0e0e0; color: #999; }

/* 统计 */
.stats { display: flex; margin: 0 24rpx; gap: 16rpx; }
.stat-item { flex: 1; text-align: center; padding: 24rpx 0; background: #fff; border-radius: 16rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); }
.stat-icon { font-size: 28rpx; display: block; margin-bottom: 6rpx; }
.stat-num { font-size: 44rpx; font-weight: 800; display: block; }
.stat-num.gold { color: #f5a623; } .stat-num.green { color: #66bb6a; } .stat-num.blue { color: #3498db; }
.stat-label { font-size: 22rpx; color: #8c7568; margin-top: 4rpx; display: block; }

/* 勋章 */
.badge-section { margin: 32rpx 24rpx 0; }
.section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16rpx; }
.section-title { font-size: 30rpx; font-weight: 700; }
.section-more { font-size: 24rpx; color: #8b1e2d; }
.badge-row { display: flex; gap: 16rpx; flex-wrap: wrap; }
.badge-item { display: flex; flex-direction: column; align-items: center; padding: 16rpx; background: #fff; border-radius: 12rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.04); min-width: 100rpx; }
.badge-item.locked { opacity: 0.4; }
.badge-icon { font-size: 36rpx; }
.badge-name { font-size: 20rpx; color: #8c7568; margin-top: 4rpx; }

/* 菜单 */
.menu { margin: 32rpx 24rpx; }
.menu-item { display: flex; align-items: center; padding: 28rpx; background: #fff; border-radius: 16rpx; margin-bottom: 12rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); gap: 16rpx; }
.menu-item:active { transform: scale(0.98); }
.menu-icon { font-size: 32rpx; }
.menu-text { flex: 1; font-size: 30rpx; font-weight: 500; }
.arrow { color: #8c7568; font-size: 40rpx; line-height: 1; }
</style>
