import { defineStore } from 'pinia';
import { regionApi } from '../api/index.js';

export const useRegionStore = defineStore('region', {
  state: () => ({
    regions: [],
    loading: false,
    keyword: '',
  }),
  actions: {
    async loadRegions(keyword = '') {
      this.keyword = keyword;
      this.loading = true;
      try {
        const data = await regionApi.getList({ keyword });
        this.regions = data.items || [];
      } catch (_) {
        this.regions = [];
      }
      this.loading = false;
    },
  },
});
