const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api';

export async function ensureLogin() {
  if (uni.getStorageSync('token')) return;
  let deviceId = uni.getStorageSync('deviceId');
  if (!deviceId) { deviceId = `uni-${Date.now()}-${Math.random().toString(16).slice(2)}`; uni.setStorageSync('deviceId', deviceId); }
  const data = await request('/auth/anonymous', { method: 'POST', data: { deviceId }, anonymous: true });
  uni.setStorageSync('token', data.token);
}

export function request(path, options = {}) {
  return new Promise((resolve, reject) => uni.request({
    url: `${BASE_URL}${path}`,
    method: options.method || 'GET', data: options.data,
    header: { 'Content-Type': 'application/json', ...(!options.anonymous && uni.getStorageSync('token') ? { Authorization: `Bearer ${uni.getStorageSync('token')}` } : {}) },
    success(response) { if (response.statusCode >= 200 && response.statusCode < 300) resolve(response.data.data); else reject(new Error(response.data?.message || '请求失败')); },
    fail: reject,
  }));
}

