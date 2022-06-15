uniform float time;
varying vec2 vUv;
varying vec3 vPosition;
varying vec3 vColor;
varying float vOpacity;
uniform sampler2D texture1;
float PI = 3.141592653589793238;

attribute float opacity;
attribute float aScale;
void main(){
  vUv = uv;
  vOpacity = opacity;
  vColor = color;
  vec4 mvPosition = modelViewMatrix * vec4 (position,1.);
  gl_PointSize = aScale*100.0 *(1./-mvPosition.z);
  gl_Position = projectionMatrix * mvPosition;
}