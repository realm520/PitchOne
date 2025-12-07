import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['esm', 'cjs'],
  dts: true, // 启用类型定义生成
  clean: true,
  external: ['react'],
  treeshake: false, // 禁用 tree-shaking 以保留 use client
  splitting: false,
  sourcemap: true,
  esbuildOptions(options) {
    options.jsx = 'automatic';
    options.banner = {
      js: '"use client";',
    };
  },
});
