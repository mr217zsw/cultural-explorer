<template>
  <view v-if="region" class="page">
    <view class="heading"><text class="seal">{{ region.shortName }}</text><view><text class="name">{{ region.name }}</text><text>省会 {{ region.capital }} · {{ region.area }}</text></view></view>
    <text class="intro">{{ region.description }}</text>
    <view v-for="section in sections" :key="section.key" class="section"><text class="section-title">{{ section.title }}</text><text>{{ region[section.key] }}</text></view>
    <view v-if="region.mnemonic" class="mnemonic card"><text class="section-title">记忆口诀</text><text>{{ region.mnemonic }}</text></view>
    <view class="section"><text class="section-title">代表地标</text><view v-for="item in region.landmarks" :key="item.id" class="landmark"><text>◈ {{ item.name }}</text><text>{{ item.description }}</text></view></view>
    <button class="primary" @tap="quiz">开始闯关（{{ region.questionCount }}题）</button>
  </view>
</template>
<script setup>
import { ref } from 'vue'; import { onLoad } from '@dcloudio/uni-app'; import { request } from '../../api/index.js';
const region = ref(null); const sections=[{title:'地理',key:'geography'},{title:'历史',key:'history'},{title:'文化',key:'culture'}]; let id='';
onLoad(async options => { id=options.id; region.value=await request(`/regions/${id}`); uni.setNavigationBarTitle({title: region.value.name}); });
function quiz(){uni.navigateTo({url:`/pages/quiz/quiz?regionId=${id}&name=${encodeURIComponent(region.value.name)}`});}
</script>
<style scoped>
.heading{display:flex;align-items:center;margin:28rpx 0}.heading view{display:flex;flex-direction:column}.seal{font-size:80rpx;color:#8b1e2d;margin-right:28rpx}.name{font-size:44rpx;font-weight:800}.intro,.section text{line-height:1.8}.section{margin-top:38rpx;display:flex;flex-direction:column}.section-title{font-size:32rpx;font-weight:700;color:#8b1e2d;margin-bottom:12rpx}.mnemonic{margin-top:38rpx;padding:28rpx;display:flex;flex-direction:column;background:#fff0d5}.landmark{display:flex;flex-direction:column;margin:12rpx 0}.landmark text:last-child{color:#7d6d64;font-size:25rpx}.primary{margin-top:44rpx}
</style>

