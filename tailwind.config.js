/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,jsx,ts,tsx}",
    "./components/**/*.{js,jsx,ts,tsx}",
  ],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        // Clarity brand colors (matching web app)
        obsidian: '#030303',
        charcoal: '#0a0a0a',
        ember: {
          DEFAULT: '#FFA500',
          dark: '#CC5500',
          light: '#FFD700',
        },
        wax: '#F5E6D3',
        ash: '#2a2a2a',
      },
      fontFamily: {
        // These map to the loaded fonts in _layout.tsx
        serif: ['PlayfairDisplay-Regular'],
        'serif-italic': ['PlayfairDisplay-Italic'],
        sans: ['Outfit-Regular'],
        'sans-light': ['Outfit-Light'],
        'sans-medium': ['Outfit-Medium'],
        'sans-semibold': ['Outfit-SemiBold'],
        mono: ['SpaceMono'],
      },
    },
  },
  plugins: [],
};
