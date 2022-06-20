<template>
  <space />
</template>

<script>
import space from "./components/space.vue";
export default {
  name: "App",
  components: {
    space,
  },
};
</script>

<style>
* {
  padding: 0;
  margin: 0;
}
:-webkit-scrollbar {
  width: 0 !important;
}
::-webkit-scrollbar {
  width: 0 !important;
  height: 0;
}
</style>
