import React from 'react'
import { createRoot } from 'react-dom/client'
import './custom-bootstrap.scss'
import './index.css'
import App from './App'

console.log('main.tsx is executing!')

const rootElement = document.getElementById('root')
console.log('Root element found:', rootElement)

if (rootElement) {
  const root = createRoot(rootElement)
  console.log('Creating React root and rendering App...')
  
  root.render(
    // <React.StrictMode>
      <App />
    // </React.StrictMode>
  )
} else {
  console.error('Root element not found!')
}
