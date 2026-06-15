import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/health': 'http://localhost:8765',
      '/api': 'http://localhost:8765',
      '/agent': 'http://localhost:8765',
      '/memory': 'http://localhost:8765',
      '/execute': 'http://localhost:8765',
      '/cognee': 'http://localhost:8765',
      '/graphiti': 'http://localhost:8765',
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
  }
})
