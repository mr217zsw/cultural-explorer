<template>
  <!-- 难度选择 -->
  <view v-if="!quizStarted" class="page difficulty-page">
    <text class="diff-title">选择难度</text>
    <text class="diff-sub">{{ regionName }}</text>
    <view class="diff-cards">
      <view class="diff-card" :class="{ active: difficulty === 1 }" @tap="difficulty = 1">
        <text class="diff-icon">🌿</text>
        <text class="diff-name">简单</text>
        <text class="diff-desc">答错不扣命 · 20秒/题</text>
      </view>
      <view class="diff-card" :class="{ active: difficulty === 2 }" @tap="difficulty = 2">
        <text class="diff-icon">⚡</text>
        <text class="diff-name">中等</text>
        <text class="diff-desc">3条命 · 15秒/题</text>
      </view>
      <view class="diff-card" :class="{ active: difficulty === 3 }" @tap="difficulty = 3">
        <text class="diff-icon">🔥</text>
        <text class="diff-name">困难</text>
        <text class="diff-desc">1条命 · 10秒/题</text>
      </view>
    </view>
    <button class="start-btn primary" @tap="startQuiz">开始闯关</button>
  </view>

  <!-- 答题中 -->
  <view v-else-if="current" class="page">
    <!-- 顶部状态栏 -->
    <view class="top-bar">
      <view class="lives">
        <text v-for="i in 3" :key="i" class="heart" :class="{ lost: i > lives }">❤️</text>
      </view>
      <view class="timer-box" :class="{ urgent: timeLeft <= 5 }">
        <text class="timer-icon">⏱</text>
        <text class="timer-num">{{ timeLeft }}s</text>
      </view>
      <view class="score-box">
        <text class="score-num">{{ totalScore }}</text>
        <text class="score-unit">分</text>
      </view>
      <view class="combo" v-if="combo > 1">
        <text class="combo-text">{{ combo }}连击</text>
      </view>
    </view>

    <!-- 进度条 -->
    <view class="progress-bar">
      <view class="progress-fill" :style="{ width: ((currentIndex + 1) / questions.length * 100) + '%' }" />
    </view>
    <view class="progress-info">
      <text>{{ currentIndex + 1 }} / {{ questions.length }}</text>
      <text class="type-tag">{{ typeLabel(current.type) }}</text>
    </view>

    <!-- 提示 -->
    <view v-if="hintText" class="hint-box">
      <text class="hint-label">💡</text>
      <text class="hint-text">{{ hintText }}</text>
      <text class="hint-close" @tap="hintText = ''">✕</text>
    </view>

    <!-- 题干 -->
    <view class="question">
      <text class="question-label">Q</text>
      <text class="question-text">{{ current.question }}</text>
    </view>

    <!-- 提示按钮 -->
    <view v-if="!showFeedback" class="hint-btn" @tap="getHint">
      <text class="hint-btn-icon">💡</text>
      <text class="hint-btn-text">获取提示 (-5积分)</text>
    </view>

    <!-- 选项 -->
    <view class="options" v-if="current.type === 'single' || current.type === 'truefalse' || !current.type">
      <view v-for="(option, i) in current.options" :key="i" class="option" :class="{ correct: lastAnswer?.isCorrect && lastAnsIdx === i, wrong: lastAnswer && !lastAnswer.isCorrect && lastAnsIdx === i }" @tap="!showFeedback && submit(i)">
        <text class="option-letter" :class="'letter-' + i">{{ letters[i] }}</text>
        <text class="option-text">{{ option }}</text>
        <text v-if="lastAnswer && lastAnsIdx === i" class="feedback-icon">{{ lastAnswer.isCorrect ? '✓' : '✗' }}</text>
      </view>
    </view>

    <!-- 多选题 -->
    <view class="options" v-else-if="current.type === 'multiple'">
      <view v-for="(option, i) in current.options" :key="i" class="option" :class="{ selected: multiSelected.includes(i) }" @tap="toggleMulti(i)">
        <text class="option-letter" :class="'letter-' + i">{{ letters[i] }}</text>
        <text class="option-text">{{ option }}</text>
        <text v-if="multiSelected.includes(i)" class="check-mark">✓</text>
      </view>
      <button class="submit-btn primary" @tap="submitMulti" :disabled="multiSelected.length < 2">确认提交</button>
    </view>

    <!-- 答题反馈 -->
    <view v-if="showFeedback" class="feedback">
      <text class="feedback-result" :class="{ correct: lastAnswer?.isCorrect, wrong: lastAnswer && !lastAnswer.isCorrect }">
        {{ lastAnswer?.isCorrect ? '✅ 回答正确！' : '❌ 回答错误' }}
      </text>
      <text v-if="lastAnswer && !lastAnswer.isCorrect" class="feedback-correct">
        正确答案：{{ correctInfo }}
      </text>
      <text v-if="lastExplanation" class="feedback-explain">{{ lastExplanation }}</text>
      <button class="next-btn primary" @tap="nextQuestion">{{ isLastQuestion ? '查看结果' : '下一题' }}</button>
    </view>
  </view>

  <!-- 结果页 -->
  <view v-else-if="quizFinished" class="page result-page">
    <text class="result-emoji">{{ grade === 'S' ? '👑' : grade === 'A' ? '🏆' : grade === 'B' ? '💪' : '📚' }}</text>
    <text class="result-grade grade" :class="'grade-' + grade">{{ grade }}</text>
    <text class="result-title">{{ grade === 'S' ? '完美通关！' : grade === 'A' ? '精彩表现！' : grade === 'B' ? '继续加油！' : '再接再厉！' }}</text>
    <view class="result-stats">
      <view class="result-item"><text class="rl">总得分</text><text class="rv">{{ finalScore }}</text></view>
      <view class="result-item"><text class="rl">正确率</text><text class="rv">{{ correctCount }}/{{ questions.length }}</text></view>
      <view class="result-item"><text class="rl">最大连击</text><text class="rv">{{ maxCombo }}</text></view>
    </view>
    <button class="back-btn primary" @tap="goBack">返回</button>
  </view>

  <!-- 加载 -->
  <view v-else class="page empty">加载中...</view>
</template>

<script setup>
import { ref, computed } from 'vue';
import { onLoad, onUnload } from '@dcloudio/uni-app';
import { ensureLogin, request } from '../../api/index.js';

const questions = ref([]);
const currentIndex = ref(0);
const difficulty = ref(1);
const quizStarted = ref(false);
const quizFinished = ref(false);
const lives = ref(3);
const combo = ref(0);
const maxCombo = ref(0);
const totalScore = ref(0);
const finalScore = ref(0);
const correctCount = ref(0);
const showFeedback = ref(false);
const lastAnswer = ref(null);
const lastAnsIdx = ref(-1);
const lastExplanation = ref('');
const correctInfo = ref('');
const multiSelected = ref([]);
const hintText = ref('');
const timeLeft = ref(30);
const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
let regionId = '';
let regionName = '';
let timerInterval = null;

const current = computed(() => questions.value[currentIndex.value]);
const isLastQuestion = computed(() => currentIndex.value >= questions.value.length - 1);
const grade = computed(() => {
  const rate = correctCount.value / Math.max(questions.value.length, 1);
  if (rate >= 0.95) return 'S';
  if (rate >= 0.85) return 'A';
  if (rate >= 0.70) return 'B';
  return 'C';
});

function startTimer(seconds) {
  clearTimer();
  timeLeft.value = seconds;
  timerInterval = setInterval(() => {
    timeLeft.value--;
    if (timeLeft.value <= 0) {
      clearTimer();
      autoSubmit();
    }
  }, 1000);
}

function clearTimer() {
  if (timerInterval) { clearInterval(timerInterval); timerInterval = null; }
  hintText.value = '';
}

function autoSubmit() {
  const q = current.value;
  if (q.type === 'multiple') {
    if (multiSelected.value.length >= 2) submitMulti();
    else { nextQuestion(); }
  } else {
    submit(-1);
  }
}

function typeLabel(type) {
  return type === 'multiple' ? '多选' : type === 'truefalse' ? '判断' : '单选';
}

onLoad(async (options) => {
  regionId = options.regionId;
  regionName = decodeURIComponent(options.name || '');
  uni.setNavigationBarTitle({ title: regionName + '闯关' });
});

onUnload(() => { clearTimer(); });

async function startQuiz() {
  try {
    await ensureLogin();
    const data = await request('/quiz/startV2', {
      method: 'POST',
      data: { regionId, difficulty: difficulty.value },
    });
    questions.value = data.questions;
    lives.value = data.lives;
    quizStarted.value = true;
    // Start timer for first question
    if (data.questions && data.questions.length) {
      startTimer(data.questions[0].timeLimit || 30);
    }
  } catch (e) {
    // 降级到 V1 API
    try {
      const data = await request('/quiz/start', { method: 'POST', data: { regionId } });
      questions.value = data.questions || data.data?.questions;
      lives.value = 3;
      quizStarted.value = true;
      startTimer(30);
    } catch (e2) {
      uni.showToast({ title: '加载失败', icon: 'none' });
    }
  }
}

async function submit(idx) {
  showFeedback.value = false;
  lastAnsIdx.value = idx;
  clearTimer();
  try {
    const result = await request('/quiz/submitV2', {
      method: 'POST',
      data: { questionId: current.value.id, answer: idx },
    });
    handleResult(result, idx);
  } catch (e) {
    finishQuizV1Fallback();
  }
}

function toggleMulti(i) {
  if (multiSelected.value.includes(i)) {
    multiSelected.value = multiSelected.value.filter(v => v !== i);
  } else {
    multiSelected.value.push(i);
  }
}

async function submitMulti() {
  showFeedback.value = false;
  clearTimer();
  try {
    const result = await request('/quiz/submitV2', {
      method: 'POST',
      data: { questionId: current.value.id, answer: multiSelected.value },
    });
    handleResult(result, -1);
    multiSelected.value = [];
  } catch (e) {
    uni.showToast({ title: '提交失败', icon: 'none' });
  }
}

async function getHint() {
  try {
    const result = await request('/quiz/hint', {
      method: 'POST',
      data: { questionId: current.value.id },
    });
    hintText.value = result.hint;
    uni.showToast({ title: `消耗 ${result.cost} 积分`, icon: 'none' });
  } catch (e) {
    uni.showToast({ title: e?.data?.message || '获取提示失败', icon: 'none' });
  }
}

function finishQuizV1Fallback() {
  if (isLastQuestion.value) {
    finishQuizV1({ reward: { earnedScore: totalScore.value }, correctCount: correctCount.value });
  } else {
    currentIndex.value++;
  }
}

function handleResult(result, idx) {
  if (result.isCorrect !== undefined) {
    lastAnswer.value = { isCorrect: result.isCorrect };
    totalScore.value = result.totalScore || totalScore.value;
    lives.value = result.lives ?? lives.value;
    combo.value = result.combo ?? combo.value;
    maxCombo.value = Math.max(maxCombo.value, result.combo || 0);
    if (result.isCorrect) correctCount.value++;
    if (result.correctAnswer !== undefined) correctInfo.value = Array.isArray(result.correctAnswer) ? result.correctAnswer.map(i => letters[i]).join(', ') : String.fromCharCode(65 + (result.correctAnswer || 0));
    lastExplanation.value = result.explanation || '';
    showFeedback.value = true;

    if (result.isGameOver) {
      finalScore.value = result.totalScore || totalScore.value;
      quizFinished.value = true;
    }
  }
}

function nextQuestion() {
  showFeedback.value = false;
  lastAnswer.value = null;
  if (isLastQuestion.value || lives.value <= 0) {
    finalScore.value = totalScore.value;
    quizFinished.value = true;
    clearTimer();
  } else {
    currentIndex.value++;
    // Start timer for next question
    const nextQ = questions.value[currentIndex.value];
    startTimer(nextQ?.timeLimit || 30);
  }
}

function finishQuizV1(result) {
  clearTimer();
  finalScore.value = result.reward?.earnedScore || 0;
  correctCount.value = result.correctCount || 0;
  quizFinished.value = true;
}

function goBack() { uni.navigateBack(); }
</script>

<style scoped>
/* 难度选择 */
.difficulty-page { display: flex; flex-direction: column; align-items: center; padding-top: 80rpx; }
.diff-title { font-size: 48rpx; font-weight: 800; color: #8b1e2d; }
.diff-sub { font-size: 28rpx; color: #8c7568; margin: 12rpx 0 48rpx; }
.diff-cards { display: flex; gap: 20rpx; width: 100%; padding: 0 24rpx; box-sizing: border-box; }
.diff-card { flex: 1; padding: 36rpx 16rpx; background: #fff; border-radius: 20rpx; text-align: center; border: 3rpx solid transparent; box-shadow: 0 4rpx 20rpx rgba(80,40,20,0.06); transition: border 0.2s; }
.diff-card.active { border-color: #8b1e2d; background: #fff5f5; }
.diff-icon { font-size: 44rpx; display: block; }
.diff-name { font-size: 30rpx; font-weight: 700; display: block; margin: 12rpx 0 8rpx; }
.diff-desc { font-size: 20rpx; color: #8c7568; display: block; }
.start-btn { margin-top: 56rpx; width: 400rpx; font-size: 34rpx; }

/* 顶部状态栏 */
.top-bar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12rpx; }
.lives { display: flex; gap: 4rpx; }
.heart { font-size: 32rpx; transition: opacity 0.3s; }
.heart.lost { opacity: 0.2; }
.timer-box { display: flex; align-items: center; gap: 2rpx; padding: 4rpx 14rpx; border-radius: 40rpx; background: rgba(139,30,45,0.08); }
.timer-box.urgent { background: #e74c3c; }
.timer-icon { font-size: 22rpx; }
.timer-num { font-size: 24rpx; font-weight: 800; color: #8b1e2d; }
.timer-box.urgent .timer-num { color: #fff; }
.timer-box.urgent .timer-icon { filter: brightness(10); }
.score-box { background: #f5a623; color: #fff; padding: 6rpx 20rpx; border-radius: 40rpx; display: flex; align-items: center; gap: 2rpx; }
.score-num { font-size: 28rpx; font-weight: 800; }
.score-unit { font-size: 20rpx; opacity: 0.8; }
.combo { background: #e74c3c; color: #fff; padding: 6rpx 16rpx; border-radius: 40rpx; }
.combo-text { font-size: 22rpx; font-weight: 700; }

/* 进度条 */
.progress-bar { height: 6rpx; background: #f0e0d0; border-radius: 3rpx; margin: 12rpx 0 8rpx; overflow: hidden; }
.progress-fill { height: 100%; background: linear-gradient(90deg, #8b1e2d, #b54a3a); border-radius: 3rpx; transition: width 0.3s ease; }
.progress-info { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24rpx; }
.progress-info text:first-child { font-size: 24rpx; color: #8c7568; }
.type-tag { font-size: 20rpx; color: #fff; background: #8b1e2d; padding: 2rpx 12rpx; border-radius: 12rpx; }

/* 题干 */
.question { display: flex; gap: 16rpx; margin-bottom: 28rpx; align-items: flex-start; }
.question-label { font-size: 56rpx; font-weight: 900; color: #8b1e2d; opacity: 0.15; line-height: 1; }
.question-text { flex: 1; font-size: 38rpx; font-weight: 700; line-height: 1.45; color: #2d2520; }

/* 选项 */
.options { display: flex; flex-direction: column; gap: 16rpx; }
.option { display: flex; align-items: center; padding: 24rpx; background: #fff; border-radius: 16rpx; box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.04); gap: 16rpx; border: 2rpx solid transparent; transition: all 0.15s; }
.option:active { transform: scale(0.98); }
.option.selected { border-color: #8b1e2d; background: #fff5f5; }
.option.correct { border-color: #66bb6a; background: #f0faf1; }
.option.wrong { border-color: #e74c3c; background: #fef0ef; }
.option-letter { width: 40rpx; height: 40rpx; border-radius: 8rpx; display: flex; align-items: center; justify-content: center; font-size: 24rpx; font-weight: 700; color: #fff; flex-shrink: 0; }
.letter-0 { background: #e74c3c; } .letter-1 { background: #3498db; }
.letter-2 { background: #2ecc71; } .letter-3 { background: #e67e22; }
.letter-4 { background: #9b59b6; } .letter-5 { background: #1abc9c; }
.option-text { flex: 1; font-size: 28rpx; line-height: 1.5; }
.feedback-icon { font-size: 32rpx; font-weight: 800; }
.check-mark { font-size: 28rpx; color: #8b1e2d; font-weight: 800; }
.submit-btn { margin-top: 24rpx; }

/* 反馈 */
.feedback { margin-top: 32rpx; text-align: center; }
.feedback-result { font-size: 36rpx; font-weight: 800; display: block; margin-bottom: 8rpx; }
.feedback-result.correct { color: #66bb6a; } .feedback-result.wrong { color: #e74c3c; }
.feedback-correct { font-size: 26rpx; color: #66bb6a; display: block; margin-bottom: 8rpx; }
.feedback-explain { font-size: 24rpx; color: #8c7568; line-height: 1.6; display: block; margin-bottom: 24rpx; padding: 16rpx; background: #f9f9f9; border-radius: 12rpx; }
.next-btn { font-size: 30rpx; }

/* 结果页 */
.result-page { display: flex; flex-direction: column; align-items: center; padding-top: 80rpx; }
.result-emoji { font-size: 80rpx; }
.result-grade { font-size: 96rpx; font-weight: 900; margin: 8rpx 0; }
.grade-S { color: #f5a623; } .grade-A { color: #66bb6a; } .grade-B { color: #3498db; } .grade-C { color: #8c7568; }
.result-title { font-size: 32rpx; font-weight: 700; color: #2d2520; margin-bottom: 40rpx; }
.result-stats { width: 100%; background: #fff; border-radius: 20rpx; padding: 24rpx; box-shadow: 0 4rpx 20rpx rgba(80,40,20,0.06); margin-bottom: 40rpx; }
.result-item { display: flex; justify-content: space-between; padding: 16rpx 0; border-bottom: 1rpx solid #f0f0f0; }
.result-item:last-child { border-bottom: none; }
.rl { font-size: 28rpx; color: #8c7568; } .rv { font-size: 28rpx; font-weight: 700; color: #2d2520; }
.back-btn { width: 400rpx; font-size: 32rpx; }

.empty { text-align: center; padding-top: 200rpx; color: #8c7568; }

/* 提示 */
.hint-box { margin-bottom: 16rpx; padding: 16rpx 20rpx; background: #fff3cd; border-radius: 12rpx; display: flex; align-items: flex-start; gap: 8rpx; }
.hint-label { font-size: 28rpx; flex-shrink: 0; }
.hint-text { flex: 1; font-size: 24rpx; color: #856404; line-height: 1.5; }
.hint-close { font-size: 28rpx; color: #856404; padding: 0 4rpx; flex-shrink: 0; }
.hint-btn { display: flex; align-items: center; justify-content: center; gap: 6rpx; margin-top: 16rpx; padding: 12rpx; }
.hint-btn-icon { font-size: 24rpx; }
.hint-btn-text { font-size: 24rpx; color: #f5a623; }

.page { min-height: 100vh; padding: 24rpx; background: #fffaf0; }
</style>
