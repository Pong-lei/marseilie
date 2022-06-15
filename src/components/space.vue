<template>
  <div id="space" ref="space">
    <div id="cont" ref="cont"></div>
  </div>
</template>

<script>
import * as THREE from "three";
import Dat from "dat.gui";
import { getDistance, getRhumbLineBearing } from "geolib";
// import gsap from "gsap";
import Stats from "stats.js";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { mergeBufferGeometries } from "three/examples/jsm/utils/BufferGeometryUtils.js";
// import { Water } from "three/examples/jsm/objects/Water";
import edingburgh from "../assets/edingbur.json";
// import edingburgh_water from "../assets/edingbur_water.json";

import vertex from "../shader/vertexParticles.glsl";
import fragment from "../shader/fargment.glsl";

export default {
  name: "space",
  data() {
    return {
      //debug
      time: null,
      stats: null,

      READY: false,

      raycaster: null,

      scene: null,
      camera: null,
      renderer: null,
      controls: null,
      center: [-3.190462, 55.9443966],

      BUILDING_MATERIAL: null,
      LINE_MATERIAL: null,
      DASH_LINE_MATERIAL: null,
      WATER_MATERIAL: null,
      WATER_NORMALE_MATERIAL: null,
      PARTICLE_MATERIAL: null,

      //mesh or lines
      particleLines: [],
      dash_lines: null,
      // Animated Line Length
      dash_lines_distance: [],
      lines_water: null,
      // Geometrys
      allBuildings: [],
      FianlyBuilding: null,
      particleGeometry: null,
      allLineGeometry: [],
      collider: [],

      all_lines_points: [],

      FLAG_LINE_ANI: true,

      // destory
      reqAninFrame: null,
      buildingColor: {
        color: "#fff000",
      },
    };
  },
  mounted() {
    this.Init();
    this.onWindowResize();
    window.addEventListener("resize", this.onWindowResize.bind(this));
    this.$refs.cont.addEventListener("click", this.goRouter);
  },
  methods: {
    goRouter(event) {
      let pointer = {};
      pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
      pointer.y = -(event.clientY / window.innerHeight) * 2 + 1;

      let hitted = this.Launch(pointer);
      // let dom = this.$refs.space;
      // gsap.to(dom, {
      //   duration: 2,
      //   scale: 0.1,
      //   onComplete: () => {

      //   },
      // });
      // this.$router.push({ path: "/inside" });
    },
    onWindowResize() {
      this.camera.aspect = window.innerWidth / window.innerHeight;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(window.innerWidth, window.innerHeight);
    },

    Init() {
      let cont = this.$refs.cont;

      this.raycaster = new THREE.Raycaster();
      //FPS checker
      this.stats = new Stats();
      this.gui = new Dat.GUI();
      document.body.appendChild(this.stats.dom);
      // scene
      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x2222222);

      //init group
      this.dash_lines = new THREE.Group();
      this.dash_lines.name = "AnimatedLine";

      // this.lines_water = new THREE.Group();
      // this.lines_water.name = "Water";

      this.$nextTick(() => {
        this.scene.add(this.dash_lines);
        // this.scene.add(this.lines_water);
      });

      // camera
      this.camera = new THREE.PerspectiveCamera(
        50,
        window.clientWith / window.clientHight,
        0.1,
        1000
      );
      // this.camera.position.set(10, 4, 0);
      this.camera.position.set(8, 4, -4);
      // this.camera.lookAt(new THREE.Vector3(10,10,10));

      // light
      let light0 = new THREE.AmbientLight(0xfafafa, 0.25);
      let light1 = new THREE.DirectionalLight(0xfafafa, 0.4);
      let light2 = new THREE.DirectionalLight(0xfafafa, 0.4);
      light1.position.set(200, 90, 40);
      light2.position.set(200, 90, -40);

      this.scene.add(light0);
      this.scene.add(light1);
      this.scene.add(light2);

      // renderer
      this.renderer = new THREE.WebGLRenderer({ antialias: true });
      this.renderer.setPixelRatio(window.devicePixelRatio);
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      // this.renderer.physicallyCorrectLights = true
      this.renderer.outputEncoding = THREE.sRGBEncoding;
      cont.appendChild(this.renderer.domElement);

      // controls map
      this.controls = new OrbitControls(this.camera, this.renderer.domElement);
      this.controls.enableDamping = true;
      this.controls.dampingFactor = 0.25;
      this.controls.screenSpacePanning = false;
      this.controls.maxDistance = 16;
      this.controls.update();

      // this.scene.add(new THREE.AxesHelper(5));
      // tick


// 55.943136 -3.187468
// 55.947075 -3.189286
// 55.945963 -3.194759
// 55.948234 -3.180448
// 55.943623 -3.1790222
// 55.940147, -3.1750203
// 55.939153, -3.1939592
      this.BUILDING_MATERIAL = new THREE.MeshPhongMaterial({
        color: 0xffad8f,
      });
      // this.gui.addColor(this.buildingColor, "color").onChange(() => {
      //   this.BUILDING_MATERIAL.color = new THREE.Color(
      //     this.buildingColor.color
      //   );
      // });
      // 路线的实线材质
      this.LINE_MATERIAL = new THREE.LineBasicMaterial({ color: 0x254360 });

      this.getCityJson();
      this.Tick();

      // 地图太小 没有水
      // this.LoadWaters();
      // setInterval(this.UpdateAnimatedLine, 3000);
    },
    Launch(mouse) {
      this.raycaster.setFromCamera(mouse, this.camera);
      let intersects = this.raycaster.intersectObjects(this.collider, true);
      if (intersects.length > 0) {
        return intersects[0].object;
      }
      return false;
    },
    Tick() {
      this.stats.begin();
      this.time++;
      this.renderer.render(this.scene, this.camera);
      this.UpdateAnimatedLine();
      // if (this.READY) {
      //   this.updateThings();
      // }

      this.stats.end();
      this.reqAninFrame = requestAnimationFrame(this.Tick.bind(this));
    },
    updateThings() {
      // 让粒子在线上运动。但是计算出来粒子的坐标在线上不是均匀分布，
      // 无法达到实际效果，如果线是svg图画就好了

      let j = 0;
      this.particleLines.forEach((line) => {
        line.currentPos += line.speed;
        line.currentPos = line.currentPos % line.number;
        for (let index = 0; index < 100; index++) {
          let i = (line.currentPos + index) % line.number;
          const p = line.points[i];
          // console.log(p);
          this.particleGeometry.attributes.position.set([p.x, p.y, p.z], j * 3);
          j++;
        }
      });
      this.particleGeometry.rotateX(Math.PI / 2);
      this.particleGeometry.rotateZ(Math.PI);
      this.particleGeometry.attributes.position.needsUpdate = true;
    },
    getCityJson() {
      let features = edingburgh.features;
      let particlePoints = [];

      const Line_geometrys = new THREE.BufferGeometry();

      for (let i = 0; i < features.length; i++) {
        let item = features[i];
        this.randomNumber++;
        // get position
        let info = item.properties;
        if (!info) return;
        if (info.building) {
          this.addBuilding(
            item.geometry.coordinates,
            info,
            info["building:levels"]
          );
        } else if (info.highway) {
          if (
            item.geometry.type == "LineString" &&
            info["highway"] !== "footway" &&
            info["highway"] !== "pedestrian"
          ) {
            this.addLineRoad(
              item.geometry.coordinates,
              Line_geometrys,
              particlePoints
            );
          }
        }
      }
      // this.particleGeometry = this.addOjects(particlePoints);
      // this.particleLines = particlePoints;
      let that = this;
      this.$nextTick(() => {
        this.FianlyBuilding = mergeBufferGeometries(that.allBuildings);
        let mesh = new THREE.Mesh(this.FianlyBuilding, that.BUILDING_MATERIAL);

        that.allBuildings.forEach((item) => {
          item.dispose();
        });
        Line_geometrys.dispose();
        that.scene.add(mesh);
      });
    },

    LoadWaters() {
      let elements = edingburgh_water.elements;
      let WaterNodes = [];
      for (let i = 0; i < elements.length; i++) {
        if (
          elements[i].tags?.natural === "water" &&
          elements[i].type === "way"
        ) {
          WaterNodes[WaterNodes.length] = elements[i].nodes;
        } else if (elements[i].type === "node") {
          let id = elements[i].id;
          for (let j = 0; j < WaterNodes.length; j++) {
            let index = WaterNodes[j].indexOf(id);
            if (index !== -1) {
              WaterNodes[j][index] = [elements[i].lon, elements[i].lat];
              if (index === 0) {
                WaterNodes[j][WaterNodes[j].length - 1] = [
                  elements[i].lon,
                  elements[i].lat,
                ];
              }
            }
          }
        }
      }
      this.addWater(WaterNodes);
    },
    addOjects(particlePoints) {
      this.PARTICLE_MATERIAL = new THREE.ShaderMaterial({
        // extensions: {
        //   derivatives: "#extension GL_OES_standard_derivatives:enable",
        // },
        vertexColors: true,
        side: THREE.DoubleSide,
        uniforms: {
          time: { value: 0 },
          resolution: { value: new THREE.Vector4() },
        },
        blending: THREE.AdditiveBlending,
        transparent: true,
        // depthTest: false,
        depthWrite: false,
        vertexShader: vertex,
        fragmentShader: fragment,
      });

      let position = [];
      let opacity = [];
      let aScale = [];
      // particlePoints.forEach((line) => {
      //   line.points.forEach((p) => {
      //     position.push(p.x, p.y, p.z);
      //     opacity.push(Math.random());
      //     aScale.push(Math.random());
      //   });
      // });
      let max = particlePoints.length * 100;
      for (let index = 0; index < max; index++) {
        // let i = (line.currentPos + index) % line.number;
        // const p = line.points[i];
        // console.log(p);
        position.push(Math.random() * 10, 0, Math.random());
        opacity.push(Math.random());
        aScale.push(Math.random());
      }

      let geometry = new THREE.BufferGeometry();

      geometry.setAttribute(
        "position",
        new THREE.BufferAttribute(new Float32Array(position), 3)
      );

      geometry.setAttribute(
        "opacity",
        new THREE.BufferAttribute(new Float32Array(opacity), 1)
      );
      geometry.setAttribute(
        "aScale",
        new THREE.BufferAttribute(new Float32Array(aScale), 1)
      );
      geometry.rotateX(Math.PI / 2);
      geometry.rotateZ(Math.PI);

      let plane = new THREE.Points(geometry, this.PARTICLE_MATERIAL);
      //tick to updata
      // this.particleLines = particlePoints;
      // this.particleGeometry = geometry;

      this.READY = true;
      this.scene.add(plane);
      return geometry;
    },
    addWater(data) {
      let shape;
      let geometry;
      this.WATER_MATERIAL = {
        textureWidth: 512,
        textureHeight: 512,
        waterNormals: new THREE.TextureLoader().load(
          require("../assets/waternormals.jpg"),
          (texture) => {
            texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
          }
        ),
        sunDirection: new THREE.Vector3(),
        sunColor: 0xffffff,
        waterColor: 0xa6c8fa,
        distortionScale: 3.7,
        fog: false,
      };
      for (let i = 0; i < data.length; i++) {
        let item = data[i];
        shape = this.getShape(item);
        geometry = this.getGeometry(shape, {
          curveSegment: 1,
          depth: 0.01,
          bevelEnabled: false,
        });
        geometry.rotateX(Math.PI / 2);
        geometry.rotateZ(Math.PI);
        let water = new Water(geometry, this.WATER_MATERIAL);
        water.scale.set(2, 2, 2);

        this.lines_water.add(water);
      }
    },
    computeLineDistances(geometry) {
      const _start = new THREE.Vector3();
      const _end = new THREE.Vector3();
      // we assume non-indexed geometry

      if (geometry.index === null) {
        const positionAttribute = geometry.attributes.position;
        const lineDistances = [0];

        for (let i = 1, l = positionAttribute.count; i < l; i++) {
          _start.fromBufferAttribute(positionAttribute, i - 1);
          _end.fromBufferAttribute(positionAttribute, i);

          lineDistances[i] = lineDistances[i - 1];
          lineDistances[i] += _start.distanceTo(_end);
        }

        geometry.setAttribute(
          "lineDistance",
          new THREE.Float32BufferAttribute(lineDistances, 1)
        );
      } else {
        console.warn(
          "THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry."
        );
      }
    },
    addLineRoad(data, SrcGeometry, particlePoints) {
      let points = [];
      let geometry = SrcGeometry.clone();

      // data.length=[N][2]
      for (let i = 0; i < data.length; i++) {
        if (data.length < 3) return;
        if (!data[0][1] || !data[0] || !data[1]) return;
        let elp = this.GPSRelativePositon([...data[i]], this.center);
        points.push(new THREE.Vector3(elp[0], elp[1], 0));
      }

      geometry.setFromPoints(points);
      geometry.rotateZ(Math.PI);
      geometry.rotateX(-Math.PI / 2);

      const splineObject = new THREE.Line(geometry, this.LINE_MATERIAL);
      this.scene.add(splineObject);

      this.computeLineDistances(geometry);

      let count = geometry.attributes.lineDistance.count;
      let totalLen = geometry.attributes.lineDistance.array[count - 1];
      // console.log(geometry);

      // 虚线动画
      if (totalLen > 0.8) {
        let aniline = this.addAnimatedLine(geometry, totalLen);
        this.dash_lines.add(aniline);
      }
      // let newPonits = [];
      // for (let index = 0; index < points1.length; index++) {
      //   let currentPoint = points1[index];
      //   newPonits.push(new THREE.Vector3(currentPoint.x, currentPoint.y, 0));
      // }

      // 对长度大于0.8的做动画，记录每条线上的点 -- 粒子动画
      // if (totalLen > 0.8) {
      //   particlePoints.push({
      //     len: totalLen,
      //     points: newPonits,
      //     number: 500,
      //     currentPos: 0,
      //     speed: 1,
      //   });
      // }
      geometry.dispose();
    },
    addAnimatedLine(geometry, len) {
      // 路线虚线材质

      let animatedLine = new THREE.Line(
        geometry,
        new THREE.LineDashedMaterial({
          color: 0x00ffff,
        })
      );
      animatedLine.material.dashSize = 0;
      animatedLine.material.gapSize = 1000;
      animatedLine.position.y = 0.5;
      animatedLine.material.transparent = true;

      this.dash_lines_distance.push(len);

      return animatedLine;
    },
    UpdateAnimatedLine() {
      if (this.dash_lines.children.length <= 0) return;
      for (let i = 0; i < this.dash_lines.children.length; i++) {
        let line = this.dash_lines.children[i];
        let dash = parseInt(line.material.dashSize);
        let length = parseInt(this.dash_lines_distance[i]);

        line.position.y = 0;
        if (dash > length) {
          //recover
          line.material.dashSize = 0;
          line.material.opacity = 1;
        } else {
          line.material.dashSize += 0.02;
          line.material.opacity =
            line.material.opacity > 0 ? line.material.opacity - 0.0002 : 0;
        }
      }
    },
    addBuilding(data, info, height = 1) {
      height = height ? height : 1;
      let shape;
      let geometry;
      let holes = [];
      //data = [n][n][2]
      for (let i = 0; i < data.length; i++) {
        let item = data[i];
        if (i === 0) {
          shape = this.getShape(item, info);
        } else {
          holes.push(this.getShape(item));
        }
      }

      for (let i = 0; i < holes.length; i++) {
        shape.holes.push(holes[i]);
      }
      geometry = this.getGeometry(shape, {
        curveSegment: 1,
        depth: 0.05 * height,
        bevelEnabled: false,
      });
      geometry.rotateX(Math.PI / 2);
      // geometry.geometry.y = -0.5;
      geometry.rotateZ(Math.PI);
      this.allBuildings.push(geometry);

      // helper
      let helper = this.getHelper(geometry);

      if (helper) {
        helper.name = info[`name`] ? info[`name`] : "Building";
        helper.info = info;
        this.collider.push(helper);
      }
    },
    getHelper(geometry) {
      if (!geometry.boundingBox) {
        geometry.computeBoundingBox();
      }
      let box3 = geometry.boundingBox;
      if (!isFinite(box3.max.x)) {
        return false;
      }
      let helper = new THREE.Box3Helper(box3, 0xffff00);
      helper.updateMatrixWorld();
      return helper;
    },
    getGeometry(shape, config) {
      let geometry = new THREE.ExtrudeGeometry(shape, config);
      // Used to click
      geometry.computeBoundingBox();
      return geometry;
    },
    getShape(points, info = {}) {
      let shape = new THREE.Shape();
      let itemCoordinate;
      for (let i = 0; i < points.length; i++) {
        itemCoordinate = this.GPSRelativePositon(points[i], this.center);
        if (i === 0) {
          shape.moveTo(itemCoordinate[0], itemCoordinate[1]);
        } else {
          shape.lineTo(itemCoordinate[0], itemCoordinate[1]);
        }
      }
      return shape;
    },
    GPSRelativePositon(position, centerPosition) {
      let dis = getDistance(position, centerPosition);

      let angle = getRhumbLineBearing(position, centerPosition);
      let x = centerPosition[0] + dis * Math.cos((angle * Math.PI) / 180);
      let y = centerPosition[1] + dis * Math.sin((angle * Math.PI) / 180);

      return [-x / 100, y / 100];
    },
  },

  beforeDestroy() {
    window.removeEventListener("resize", this.onWindowResize);
    this.$refs.cont.removeEventListener("click", this.goRouter);

    cancelAnimationFrame(this.reqAninFrame);

    this.scene.traverse((ch) => {
      ch.material?.dispose();
      ch.geometry?.dispose();
      // ch.dispose()
    });

    this.scene = null;
    this.camera = null;
    // this.labelRenderer = null;
    this.controls = null;

    this.renderer.dispose();
    this.renderer.forceContextLoss();
    console.log(this.renderer.info);
    this.renderer.domElement = null;
    this.renderer = null;
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped></style>
