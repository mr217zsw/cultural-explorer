import { defineStore } from 'pinia';
import { ensureLogin, userApi } from '../api/index.js';

export const useUserStore = defineStore('user', {
  state: () => ({
    profile: null,
    loading: false,
  }),
  getters: {
    isLoggedIn: (state) => !!state.profile,
    totalScore: (state) => state.profile?.totalScore || 0,
    completedCount: (state) => state.profile?.completedCount || 0,
  },
  actions: {
    async init() {
      this.loading = true;
      try {
        await ensureLogin();
        this.profile = await userApi.getProfile();
      } catch (_) {
        this.profile = null;
      }
      this.loading = false;
    },
    async refresh() {
      try {
        this.profile = await userApi.getProfile();
      } catch (_) {}
    },
    async updateProfile(data) {
      try {
        await userApi.updateProfile(data);
        await this.refresh();
        return true;
      } catch (_) {
        return false;
      }
    },
  },
});
