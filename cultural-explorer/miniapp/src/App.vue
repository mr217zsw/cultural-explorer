<script>
export default {
  onLaunch() { console.log('华夏文化探索启动'); },
  onError(e) {
    // Suppress uni-app H5 initialization timing errors
    if (typeof e === 'string' && (e.includes('getBoundingClientRect') || e.includes('Script error'))) return;
    console.error(e);
  },
};
</script>

<style>
html, body {
  background: #fffaf0;
  color: #2d2520;
  margin: 0;
  padding: 0;
  font-family: system-ui, -apple-system, 'PingFang SC', sans-serif;
  font-size: 16px;
  line-height: 1.6;
}
#app {
  background: #fffaf0;
  min-height: 100vh;
}
</style>
