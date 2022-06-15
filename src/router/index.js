import Vue from 'vue'
import VueRouter from 'vue-router'

Vue.use(VueRouter)

const routes = [
  {
    path:'',
    redirect:'/space'
  },
  {
    path:'/space',
    component:() => import('../components/space.vue'),
  },
  {
    path:'/inside',
    component:() => import('../components/inside.vue'),
  },
]

const router = new VueRouter({
  routes,
  mode:'history'
})

export default router