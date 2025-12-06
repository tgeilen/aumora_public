/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/javascript/frontend/**/*.{js,ts,jsx,tsx}",
    "./app/views/**/*.html.erb"
  ],
  theme: {
    extend: {
      colors: {
        forest: {
          50: '#f2f7f4',
          100: '#e3efe8',
          200: '#c7e0d3',
          300: '#9cc7b5',
          400: '#6ba88f',
          500: '#2c7c57',  // primary forest green
          600: '#216543',
          700: '#1c5237',
          800: '#1a442f',
          900: '#17392a',
          950: '#0c2018',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
} 