<template>
  <div>
    hellow
    <button @click="back" style="margin: 200px">goback</button>
  </div>
</template>

<script>
export default {
  methods: {
    back() {
      this.$router.push({ path: "/space" });
    },
  },
  beforeDestroy() {
    console.log("inside destory");
  },
};
</script>

<style></style>
