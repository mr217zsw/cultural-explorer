<template>
  <view class="page" v-if="current">
    <text class="progress">{{ index + 1 }} / {{ questions.length }}</text><progress :percent="(index + 1) / questions.length * 100" activeColor="#8b1e2d"/>
    <text class="question">{{ current.question }}</text>
    <view v-for="(option, optionIndex) in current.options" :key="option" class="option card" @tap="choose(optionIndex)">{{ option }}</view>
  </view>
</template>
<script setup>
import { computed, ref } from 'vue'; import { onLoad } from '@dcloudio/uni-app'; import { ensureLogin, request } from '../../api/index.js';
const questions=ref([]),index=ref(0),answers=ref([]),started=Date.now(); let regionId=''; const current=computed(()=>questions.value[index.value]);
onLoad(async options=>{regionId=options.regionId;await ensureLogin();const data=await request('/quiz/start',{method:'POST',data:{regionId}});questions.value=data.questions;uni.setNavigationBarTitle({title:`${decodeURIComponent(options.name)}闯关`});});
async function choose(selectedIndex){answers.value.push({questionId:current.value.id,selectedIndex});if(index.value+1<questions.value.length){index.value++;return;}const result=await request('/quiz/complete',{method:'POST',data:{regionId,answers:answers.value,timeSpent:Math.floor((Date.now()-started)/1000)}});uni.showModal({title:result.isCompleted?'闯关成功':'继续加油',content:`答对 ${result.correctCount}/${result.totalQuestions} 题，获得 ${result.reward.earnedScore} 积分`,showCancel:false,success:()=>uni.navigateBack()});}
</script>
<style scoped>
.progress{display:block;text-align:right;color:#8c7568;margin:20rpx 0}.question{display:block;font-size:40rpx;font-weight:700;line-height:1.5;margin:70rpx 0 46rpx}.option{padding:30rpx;margin-bottom:24rpx}.option:active{background:#f8e5df}
</style>
