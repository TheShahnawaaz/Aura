"use client";

import React, { useRef, useMemo } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import * as THREE from "three";

function AuroraParticles({ count = 800 }: { count?: number }) {
  const mesh = useRef<THREE.Points>(null);
  const materialRef = useRef<THREE.ShaderMaterial>(null);

  const [positions, sizes, colors] = useMemo(() => {
    const pos = new Float32Array(count * 3);
    const sz = new Float32Array(count);
    const col = new Float32Array(count * 3);

    const colorPalette = [
      new THREE.Color("#00E5FF"),
      new THREE.Color("#38BDF8"),
      new THREE.Color("#A855F7"),
      new THREE.Color("#2563EB"),
      new THREE.Color("#FB7185"),
    ];

    for (let i = 0; i < count; i++) {
      pos[i * 3] = (Math.random() - 0.5) * 20;
      pos[i * 3 + 1] = (Math.random() - 0.5) * 12;
      pos[i * 3 + 2] = (Math.random() - 0.5) * 8 - 2;
      sz[i] = Math.random() * 3 + 0.5;

      const color = colorPalette[Math.floor(Math.random() * colorPalette.length)];
      col[i * 3] = color.r;
      col[i * 3 + 1] = color.g;
      col[i * 3 + 2] = color.b;
    }

    return [pos, sz, col];
  }, [count]);

  const shaderMaterial = useMemo(
    () =>
      new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uPixelRatio: { value: typeof window !== "undefined" ? Math.min(window.devicePixelRatio, 2) : 1 },
        },
        vertexShader: `
          uniform float uTime;
          uniform float uPixelRatio;
          attribute float aSize;
          attribute vec3 aColor;
          varying vec3 vColor;
          varying float vAlpha;

          void main() {
            vColor = aColor;
            
            vec3 pos = position;
            pos.y += sin(uTime * 0.3 + position.x * 0.5) * 0.4;
            pos.x += cos(uTime * 0.2 + position.y * 0.3) * 0.3;
            pos.z += sin(uTime * 0.15 + position.x * 0.2 + position.y * 0.3) * 0.2;
            
            vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
            gl_PointSize = aSize * uPixelRatio * (80.0 / -mvPosition.z);
            gl_Position = projectionMatrix * mvPosition;
            
            float depth = smoothstep(-8.0, -1.0, mvPosition.z);
            vAlpha = depth * 0.6;
          }
        `,
        fragmentShader: `
          varying vec3 vColor;
          varying float vAlpha;

          void main() {
            float d = length(gl_PointCoord - vec2(0.5));
            if (d > 0.5) discard;
            
            float glow = 1.0 - smoothstep(0.0, 0.5, d);
            glow = pow(glow, 2.0);
            
            gl_FragColor = vec4(vColor, glow * vAlpha);
          }
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
      }),
    []
  );

  useFrame((state) => {
    if (materialRef.current) {
      materialRef.current.uniforms.uTime.value = state.clock.elapsedTime;
    }
    if (mesh.current) {
      mesh.current.rotation.y = state.clock.elapsedTime * 0.02;
      mesh.current.rotation.x = Math.sin(state.clock.elapsedTime * 0.1) * 0.05;
    }
  });

  return (
    <points ref={mesh}>
      <bufferGeometry>
        <bufferAttribute
          attach="attributes-position"
          count={count}
          array={positions}
          itemSize={3}
        />
        <bufferAttribute
          attach="attributes-aSize"
          count={count}
          array={sizes}
          itemSize={1}
        />
        <bufferAttribute
          attach="attributes-aColor"
          count={count}
          array={colors}
          itemSize={3}
        />
      </bufferGeometry>
      <primitive object={shaderMaterial} ref={materialRef} attach="material" />
    </points>
  );
}

function AuroraMesh() {
  const meshRef = useRef<THREE.Mesh>(null);

  const material = useMemo(
    () =>
      new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `
          uniform float uTime;
          varying vec2 vUv;

          vec3 palette(float t) {
            vec3 a = vec3(0.0, 0.05, 0.1);
            vec3 b = vec3(0.0, 0.3, 0.5);
            vec3 c = vec3(0.0, 0.9, 1.0);
            vec3 d = vec3(0.66, 0.33, 0.0);
            return a + b * cos(6.28318 * (c * t + d));
          }

          void main() {
            vec2 uv = vUv;
            
            float wave1 = sin(uv.x * 3.0 + uTime * 0.4) * 0.1;
            float wave2 = sin(uv.x * 5.0 - uTime * 0.3 + 1.5) * 0.06;
            float wave3 = cos(uv.x * 2.0 + uTime * 0.2 + 3.0) * 0.08;
            
            float y = uv.y + wave1 + wave2 + wave3;
            
            float band = smoothstep(0.3, 0.5, y) * smoothstep(0.8, 0.55, y);
            
            vec3 col = palette(uv.x + uTime * 0.05);
            col = mix(col, vec3(0.66, 0.33, 0.97), sin(uv.x * 4.0 + uTime * 0.3) * 0.3 + 0.3);
            
            float alpha = band * 0.15;
            
            gl_FragColor = vec4(col, alpha);
          }
        `,
        transparent: true,
        side: THREE.DoubleSide,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
      }),
    []
  );

  useFrame((state) => {
    if (meshRef.current) {
      (meshRef.current.material as THREE.ShaderMaterial).uniforms.uTime.value =
        state.clock.elapsedTime;
    }
  });

  return (
    <mesh ref={meshRef} position={[0, 1, -4]} scale={[15, 6, 1]}>
      <planeGeometry args={[1, 1, 64, 64]} />
      <primitive object={material} attach="material" />
    </mesh>
  );
}

export function AuroraBackground() {
  return (
    <div className="absolute inset-0 -z-10 opacity-70">
      <Canvas
        camera={{ position: [0, 0, 5], fov: 60 }}
        gl={{
          antialias: false,
          alpha: true,
          powerPreference: "default",
        }}
        dpr={[1, 1.5]}
        style={{ background: "transparent" }}
      >
        <AuroraMesh />
        <AuroraParticles count={600} />
      </Canvas>
    </div>
  );
}
