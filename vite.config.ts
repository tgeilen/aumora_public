import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react({
      jsxRuntime: 'classic',
      jsxImportSource: undefined
    })
  ],
  server: {
    host: '0.0.0.0',
    port: 3036
  }
}) 