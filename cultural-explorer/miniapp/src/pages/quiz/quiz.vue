<template>
  <view class="page" v-if="current">
    <!-- 进度条 -->
    <view class="progress-bar">
      <view class="progress-fill" :style="{ width: ((index + 1) / questions.length * 100) + '%' }" />
    </view>
    <view class="progress-info">
      <text>{{ index + 1 }} / {{ questions.length }}</text>
    </view>

    <!-- 题干 -->
    <view class="question">
      <text class="question-label">Q</text>
      <text class="question-text">{{ current.question }}</text>
    </view>

    <!-- 选项 -->
    <view class="options">
      <view
        v-for="(option, optionIndex) in current.options"
        :key="option"
        class="option"
        @tap="choose(optionIndex)"
      >
        <text class="option-letter" :class="'letter-' + optionIndex">{{ letters[optionIndex] }}</text>
        <text class="option-text">{{ option }}</text>
      </view>
    </view>
  </view>
</template>

<script setup>
import { computed, ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { ensureLogin, request } from '../../api/index.js';

const questions = ref([]);
const index = ref(0);
const answers = ref([]);
const started = Date.now();
const letters = ['A', 'B', 'C', 'D'];
let regionId = '';

const current = computed(() => questions.value[index.value]);

onLoad(async (options) => {
  regionId = options.regionId;
  try {
    await ensureLogin();
    const data = await request('/quiz/start', { method: 'POST', data: { regionId } });
    questions.value = data.questions;
    uni.setNavigationBarTitle({ title: decodeURIComponent(options.name || '') + '闯关' });
  } catch (e) {
    uni.showToast({ title: '加载失败', icon: 'none' });
  }
});

async function choose(selectedIndex) {
  answers.value.push({ questionId: current.value.id, selectedIndex });

  if (index.value + 1 < questions.value.length) {
    index.value++;
    return;
  }

  try {
    const result = await request('/quiz/complete', {
      method: 'POST',
      data: {
        regionId,
        answers: answers.value,
        timeSpent: Math.floor((Date.now() - started) / 1000),
      },
    });

    uni.showModal({
      title: result.isCompleted ? '🏆 闯关成功！' : '💪 继续加油！',
      content: `答对 ${result.correctCount}/${result.totalQuestions} 题\n获得 ${result.reward?.earnedScore || 0} 积分`,
      showCancel: false,
      success: () => uni.navigateBack(),
    });
  } catch (e) {
    uni.showToast({ title: '提交失败', icon: 'none' });
  }
}
</script>

<style scoped>
.progress-bar {
  height: 6rpx;
  background: #f0e0d0;
  border-radius: 3rpx;
  margin: var(--space-lg) 0 var(--space-sm);
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--color-primary), var(--color-primary-light));
  border-radius: 3rpx;
  transition: width 0.3s ease;
}
.progress-info { text-align: right; }
.progress-info text { font-size: var(--font-sm); color: var(--color-text-secondary); }

.question {
  display: flex;
  gap: var(--space-md);
  margin: var(--space-2xl) 0 var(--space-xl);
  align-items: flex-start;
}
.question-label {
  font-size: var(--font-3xl);
  font-weight: 900;
  color: var(--color-primary);
  opacity: 0.15;
  line-height: 1;
}
.question-text {
  flex: 1;
  font-size: var(--font-xl);
  font-weight: 700;
  line-height: 1.5;
  color: var(--color-text);
}

.options { display: flex; flex-direction: column; gap: var(--space-md); }
.option {
  display: flex;
  align-items: center;
  padding: var(--space-lg);
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  gap: var(--space-lg);
  transition: transform 0.1s, background 0.15s;
}
.option:active { transform: scale(0.98); background: #fdf3f1; }

.option-letter {
  width: 48rpx;
  height: 48rpx;
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: var(--font-md);
  font-weight: 700;
  color: #fff;
  flex-shrink: 0;
}
.letter-0 { background: #e74c3c; }
.letter-1 { background: #3498db; }
.letter-2 { background: #2ecc71; }
.letter-3 { background: #e67e22; }

.option-text { flex: 1; font-size: var(--font-md); line-height: 1.5; }
</style>
