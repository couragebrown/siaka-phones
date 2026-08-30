/**
 * Siaka Phones - Assets, Icons, and Mock Catalog Data
 */

const AppIcons = {
  phoneLogo: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="2" width="14" height="20" rx="3" ry="3"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>`,
  home: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>`,
  search: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>`,
  heart: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>`,
  cart: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>`,
  user: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>`,
  bell: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>`,
  menu: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>`,
  camera: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>`,
  arrowLeft: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>`,
  arrowRight: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>`,
  share: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>`,
  truck: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="3" width="15" height="13" rx="1"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>`,
  shieldCheck: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><polyline points="9 12 11 14 15 10"/></svg>`,
  refresh: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>`,
  lock: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>`,
  trash: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>`,
  chevronRight: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>`,
  chevronDown: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>`,
  chevronUp: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="18 15 12 9 6 15"/></svg>`,
  check: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>`,
  creditCard: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>`,
  info: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>`,
  star: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>`,
  plus: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  minus: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  grid: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>`,
  package: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21"/><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>`,
  chip: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>`,
  battery: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="6" width="18" height="12" rx="2"/><line x1="23" y1="11" x2="23" y2="13"/></svg>`,
  display: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>`,
  signal: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><line x1="2" y1="20" x2="2" y2="20"/><line x1="7" y1="20" x2="7" y2="16"/><line x1="12" y1="20" x2="12" y2="12"/><line x1="17" y1="20" x2="17" y2="8"/><line x1="22" y1="20" x2="22" y2="4"/></svg>`
};

/* Brand Logos */
const BrandLogos = {
  apple: `<svg viewBox="0 0 170 170" width="22" height="22" fill="currentColor"><path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.7-3.04-7.6-7.7-11.7-13.97-6.09-9.35-10.74-20.15-13.96-32.41-3.23-12.26-4.84-23.77-4.84-34.53 0-14.9 3.63-27.18 10.89-36.85 7.26-9.66 16.48-14.65 27.67-14.97 4.79 0 10.22 1.34 16.29 4.01 6.07 2.68 9.99 4.07 11.75 4.19 1.55-.12 5.58-1.57 12.1-4.35 6.52-2.78 12.15-4.01 16.89-3.69 12.63.87 22.75 5.76 30.36 14.66-10.89 6.64-16.22 15.67-15.98 27.09.24 8.92 3.64 16.38 10.2 22.38 6.56 6 14.38 9.4 23.47 10.21-2.07 6.32-4.57 12.63-7.51 18.94zM119.22 31.85c0-7.29 2.59-14.28 7.77-20.97C132.17 4.19 138.83.6 146.97 0c.22 1.09.33 2.07.33 2.94 0 7.39-2.77 14.6-8.31 21.64-5.54 7.03-12.44 10.96-20.7 10.79.11-1.19.93-3.52-.93-3.52z"/></svg>`,
  samsung: `<div style="font-weight:900; font-size:12px; letter-spacing:1px; color:#1428A0; font-family:sans-serif;">SAMSUNG</div>`,
  google: `<svg viewBox="0 0 24 24" width="22" height="22"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/></svg>`,
  oneplus: `<div style="background:#EB0029; color:#FFF; font-weight:800; font-size:11px; padding:2px 4px; border-radius:3px; border:1px solid #EB0029;">1+</div>`,
  xiaomi: `<div style="background:#FF6900; color:#FFF; font-weight:800; font-size:11px; padding:2px 5px; border-radius:4px;">mi</div>`
};

/* High Quality Phone Render SVGs */
const DeviceSVGs = {
  iphone15ProMax: `
    <svg viewBox="0 0 160 220" width="100%" height="100%" fill="none">
      <defs>
        <linearGradient id="ipFrame" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#4B5563"/>
          <stop offset="50%" stop-color="#9CA3AF"/>
          <stop offset="100%" stop-color="#374151"/>
        </linearGradient>
        <linearGradient id="ipScreen" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#1E293B"/>
          <stop offset="40%" stop-color="#0F172A"/>
          <stop offset="100%" stop-color="#0284C7"/>
        </linearGradient>
      </defs>
      <!-- Phone Body -->
      <rect x="30" y="10" width="100" height="200" rx="20" fill="url(#ipFrame)" stroke="#6B7280" stroke-width="2"/>
      <!-- Inner Screen -->
      <rect x="34" y="14" width="92" height="192" rx="16" fill="url(#ipScreen)"/>
      <!-- Dynamic Island -->
      <rect x="66" y="20" width="28" height="7" rx="3.5" fill="#000000"/>
      <!-- Wallpaper Wave -->
      <path d="M34 130 C60 90, 80 180, 126 120 L126 206 L34 206 Z" fill="rgba(56, 189, 248, 0.45)"/>
      <!-- Glass Glare -->
      <path d="M34 14 Q80 80 126 50" stroke="rgba(255,255,255,0.25)" stroke-width="2" fill="none"/>
    </svg>
  `,

  galaxyS24Ultra: `
    <svg viewBox="0 0 160 220" width="100%" height="100%" fill="none">
      <defs>
        <linearGradient id="s24Frame" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#334155"/>
          <stop offset="50%" stop-color="#64748B"/>
          <stop offset="100%" stop-color="#1E293B"/>
        </linearGradient>
        <linearGradient id="s24Screen" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#0F172A"/>
          <stop offset="50%" stop-color="#312E81"/>
          <stop offset="100%" stop-color="#1E1B4B"/>
        </linearGradient>
      </defs>
      <!-- S24 Sharp Body -->
      <rect x="32" y="12" width="96" height="196" rx="6" fill="url(#s24Frame)" stroke="#94A3B8" stroke-width="1.5"/>
      <rect x="35" y="15" width="90" height="190" rx="4" fill="url(#s24Screen)"/>
      <!-- Punch Hole Camera -->
      <circle cx="80" cy="22" r="3" fill="#000000"/>
      <!-- Modern Geometric Crystal Art -->
      <polygon points="40,160 80,70 120,180" fill="rgba(129, 140, 248, 0.35)"/>
      <!-- S-Pen next to phone -->
      <line x1="22" y1="40" x2="22" y2="180" stroke="#94A3B8" stroke-width="4" stroke-linecap="round"/>
      <polygon points="20,180 24,180 22,192" fill="#475569"/>
    </svg>
  `,

  pixel8Pro: `
    <svg viewBox="0 0 160 220" width="100%" height="100%" fill="none">
      <defs>
        <linearGradient id="pxFrame" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#64748B"/>
          <stop offset="100%" stop-color="#334155"/>
        </linearGradient>
        <linearGradient id="pxScreen" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#0369A1"/>
          <stop offset="50%" stop-color="#0284C7"/>
          <stop offset="100%" stop-color="#38BDF8"/>
        </linearGradient>
      </defs>
      <!-- Rounded Pixel 8 Pro Body -->
      <rect x="32" y="12" width="96" height="196" rx="22" fill="url(#pxFrame)" stroke="#94A3B8" stroke-width="1.5"/>
      <rect x="36" y="16" width="88" height="188" rx="18" fill="url(#pxScreen)"/>
      <circle cx="80" cy="24" r="3" fill="#000000"/>
      <!-- Pixel Mineral Wallpaper -->
      <circle cx="90" cy="110" r="38" fill="rgba(255,255,255,0.2)"/>
      <circle cx="60" cy="140" r="28" fill="rgba(14, 165, 233, 0.4)"/>
    </svg>
  `,

  heroDualPhones: `
    <svg viewBox="0 0 260 220" width="100%" height="100%" fill="none">
      <!-- Back Phone (iPhone Titanium Silver Back) -->
      <g transform="translate(10, 10)">
        <rect x="20" y="10" width="95" height="190" rx="20" fill="#E2E8F0" stroke="#CBD5E1" stroke-width="2"/>
        <!-- Triple Camera Module -->
        <rect x="28" y="18" width="42" height="42" rx="12" fill="#CBD5E1"/>
        <circle cx="40" cy="30" r="7" fill="#334155" stroke="#94A3B8" stroke-width="2"/>
        <circle cx="58" cy="30" r="7" fill="#334155" stroke="#94A3B8" stroke-width="2"/>
        <circle cx="49" cy="48" r="7" fill="#334155" stroke="#94A3B8" stroke-width="2"/>
        <!-- Apple Logo -->
        <path d="M68 95 c-1 2 -2 4 -3 6 c-2 3 -4 5 -6 5 c-2 0 -4 -1 -6 -1 c-2 0 -4 1 -6 1 c-2 0 -4 -2 -6 -5 c-3 -4 -4 -9 -4 -15 c0 -7 2 -12 6 -16 c3 -4 7 -6 12 -6 c3 0 5 1 7 2 c2 1 3 1 4 1 c1 0 3 -1 5 -1 c3 0 7 1 9 4 c-5 3 -7 7 -7 12 c0 4 1 7 4 9 z" fill="#94A3B8"/>
      </g>
      <!-- Front Phone (iPhone Titanium Blue Screen) -->
      <g transform="translate(105, 0)">
        <rect x="20" y="10" width="95" height="195" rx="20" fill="#334155" stroke="#64748B" stroke-width="2"/>
        <rect x="24" y="14" width="87" height="187" rx="16" fill="#0F172A"/>
        <rect x="52" y="19" width="30" height="7" rx="3.5" fill="#000000"/>
        <!-- Blue Wallpaper Sweep -->
        <path d="M24 120 C50 60, 70 170, 111 90 L111 201 L24 201 Z" fill="url(#ipScreenBlue)"/>
      </g>
      <defs>
        <linearGradient id="ipScreenBlue" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#0284C7"/>
          <stop offset="100%" stop-color="#38BDF8"/>
        </linearGradient>
      </defs>
    </svg>
  `,

  galaxyBuds2: `
    <svg viewBox="0 0 120 120" width="100%" height="100%" fill="none">
      <!-- Open Buds Case -->
      <rect x="18" y="24" width="84" height="72" rx="20" fill="#1E293B" stroke="#475569" stroke-width="2"/>
      <rect x="24" y="30" width="72" height="60" rx="16" fill="#0F172A"/>
      <!-- Two Earbuds -->
      <ellipse cx="44" cy="60" rx="14" ry="16" fill="#334155" stroke="#64748B" stroke-width="1.5"/>
      <ellipse cx="76" cy="60" rx="14" ry="16" fill="#334155" stroke="#64748B" stroke-width="1.5"/>
      <circle cx="44" cy="55" r="4" fill="#0284C7"/>
      <circle cx="76" cy="55" r="4" fill="#0284C7"/>
    </svg>
  `,

  spigenCase: `
    <svg viewBox="0 0 120 120" width="100%" height="100%" fill="none">
      <!-- Transparent Case Frame -->
      <rect x="22" y="10" width="76" height="100" rx="16" fill="rgba(241, 245, 249, 0.7)" stroke="#CBD5E1" stroke-width="2"/>
      <!-- Subtle Phone Silhouette Inside -->
      <rect x="28" y="16" width="64" height="88" rx="12" fill="#E2E8F0"/>
      <rect x="34" y="22" width="26" height="26" rx="8" fill="#CBD5E1"/>
      <circle cx="42" cy="30" r="4" fill="#64748B"/>
      <circle cx="52" cy="30" r="4" fill="#64748B"/>
      <circle cx="47" cy="40" r="4" fill="#64748B"/>
      <!-- Air Cushion Corner Bumper Marks -->
      <circle cx="26" cy="14" r="2" fill="#94A3B8"/>
      <circle cx="94" cy="14" r="2" fill="#94A3B8"/>
      <circle cx="26" cy="106" r="2" fill="#94A3B8"/>
      <circle cx="94" cy="106" r="2" fill="#94A3B8"/>
    </svg>
  `
};

/* Catalog Products */
const ProductsData = [
  {
    id: "iphone-15-pro-max",
    name: "iPhone 15 Pro Max",
    brand: "Apple",
    price: "$1,099",
    rawPrice: 1099,
    rating: 4.8,
    reviews: 245,
    tag: "New",
    svg: DeviceSVGs.iphone15ProMax,
    colors: [
      { name: "Natural Titanium", hex: "#B8B5AF" },
      { name: "Black Titanium", hex: "#3B3C3E" },
      { name: "White Titanium", hex: "#E3E4E5" },
      { name: "Blue Titanium", hex: "#2F3B4B" }
    ],
    storages: ["128GB", "256GB", "512GB", "1TB"],
    highlights: [
      { icon: AppIcons.display, text: "6.7-inch Super Retina XDR display with ProMotion" },
      { icon: AppIcons.chip, text: "A17 Pro chip with 6-core GPU" },
      { icon: AppIcons.camera, text: "Pro camera system with 48MP Main | 12MP Ultra Wide | 12MP Telephoto" },
      { icon: AppIcons.battery, text: "Up to 29 hours video playback" },
      { icon: AppIcons.signal, text: "5G Connectivity" }
    ]
  },
  {
    id: "galaxy-s24-ultra",
    name: "Galaxy S24 Ultra",
    brand: "Samsung",
    price: "$1,099",
    rawPrice: 1099,
    rating: 4.7,
    reviews: 189,
    tag: "New",
    svg: DeviceSVGs.galaxyS24Ultra,
    colors: [
      { name: "Titanium Gray", hex: "#7E7E7E" },
      { name: "Titanium Black", hex: "#222222" },
      { name: "Titanium Violet", hex: "#5C5671" },
      { name: "Titanium Yellow", hex: "#E8DFBC" }
    ],
    storages: ["256GB", "512GB", "1TB"],
    highlights: [
      { icon: AppIcons.display, text: "6.8-inch Dynamic AMOLED 2X with Gorilla Armor" },
      { icon: AppIcons.chip, text: "Snapdragon 8 Gen 3 for Galaxy with Galaxy AI" },
      { icon: AppIcons.camera, text: "200MP Quad Telephoto Camera with 100x Space Zoom" },
      { icon: AppIcons.battery, text: "5,000mAh Battery with 45W Fast Charging" },
      { icon: AppIcons.signal, text: "Built-in S-Pen & 5G Ultra Wideband" }
    ]
  },
  {
    id: "google-pixel-8-pro",
    name: "Google Pixel 8 Pro",
    brand: "Google",
    price: "$899",
    rawPrice: 899,
    rating: 4.6,
    reviews: 156,
    tag: "New",
    svg: DeviceSVGs.pixel8Pro,
    colors: [
      { name: "Bay Blue", hex: "#8EB4E3" },
      { name: "Obsidian", hex: "#2B2C2D" },
      { name: "Porcelain", hex: "#F3F0EC" }
    ],
    storages: ["128GB", "256GB", "512GB"],
    highlights: [
      { icon: AppIcons.display, text: "6.7-inch Super Actua display (1-120Hz)" },
      { icon: AppIcons.chip, text: "Google Tensor G3 & Titan M2 security coprocessor" },
      { icon: AppIcons.camera, text: "50MP Main + 48MP Ultrawide + 48MP 5x Telephoto with Best Take" },
      { icon: AppIcons.battery, text: "5,050mAh Beyond 24-hour battery life" },
      { icon: AppIcons.signal, text: "7 years of OS & security updates" }
    ]
  }
];
