/**
 * Siaka Phones - Navigation Router & App Controller
 */

class SiakaApp {
  constructor() {
    this.currentScreen = 'home';
    this.cartCount = 3;
    this.screens = [
      'onboarding',
      'login',
      'home',
      'search',
      'categories',
      'product-details',
      'wishlist',
      'cart',
      'shipping',
      'payment',
      'review-order',
      'order-confirmation',
      'order-tracking',
      'profile'
    ];

    this.navTabMap = {
      'home': 'nav-home',
      'search': 'nav-search',
      'categories': 'nav-search',
      'wishlist': 'nav-wishlist',
      'cart': 'nav-cart',
      'shipping': 'nav-cart',
      'payment': 'nav-cart',
      'review-order': 'nav-cart',
      'profile': 'nav-profile'
    };

    this.init();
  }

  init() {
    this.setupEventListeners();
    this.setupDropdownSwitcher();
    this.updateClock();
    
    // Default to 'home' or URL hash if provided
    const hash = window.location.hash.replace('#', '');
    if (hash && this.screens.includes(hash)) {
      this.navigateTo(hash);
    } else {
      this.navigateTo('home');
    }
  }

  setupEventListeners() {
    // Global Navigation Click Delegator
    document.addEventListener('click', (e) => {
      const navTarget = e.target.closest('[data-navigate]');
      if (navTarget) {
        e.preventDefault();
        const targetScreen = navTarget.getAttribute('data-navigate');
        this.navigateTo(targetScreen);
      }

      // Storage pill selection
      const storageBtn = e.target.closest('.storage-pill-btn');
      if (storageBtn) {
        document.querySelectorAll('.storage-pill-btn').forEach(btn => btn.classList.remove('active'));
        storageBtn.classList.add('active');
      }

      // Color swatch selection
      const colorSwatch = e.target.closest('.color-swatch-item');
      if (colorSwatch) {
        document.querySelectorAll('.color-swatch-item').forEach(btn => btn.classList.remove('active'));
        colorSwatch.classList.add('active');
        const colorName = colorSwatch.getAttribute('data-color-name');
        const labelEl = document.getElementById('selected-color-label');
        if (labelEl && colorName) {
          labelEl.textContent = colorName;
        }
      }

      // Thumbnail selection
      const thumbItem = e.target.closest('.thumb-item');
      if (thumbItem && !thumbItem.classList.contains('thumb-more')) {
        document.querySelectorAll('.thumb-item').forEach(item => item.classList.remove('active'));
        thumbItem.classList.add('active');
      }

      // Wishlist Heart Toggle
      const wishlistBtn = e.target.closest('.product-card-wishlist, .icon-btn-wishlist');
      if (wishlistBtn) {
        e.stopPropagation();
        wishlistBtn.classList.toggle('active');
      }

      // Radio Selection Card (Shipping address & methods)
      const selectCard = e.target.closest('.selection-card');
      if (selectCard) {
        const group = selectCard.closest('.selection-group');
        if (group) {
          group.querySelectorAll('.selection-card').forEach(card => card.classList.remove('selected'));
          selectCard.classList.add('selected');
        }
      }

      // Payment Accordion Toggle
      const paymentHeader = e.target.closest('.payment-header');
      if (paymentHeader) {
        const card = paymentHeader.closest('.payment-accordion-card');
        const parent = card.closest('.payment-accordion-group');
        if (parent) {
          parent.querySelectorAll('.payment-accordion-card').forEach(c => {
            if (c !== card) {
              c.classList.remove('selected');
              const body = c.querySelector('.payment-body-form');
              if (body) body.style.display = 'none';
              const chevron = c.querySelector('.payment-chevron');
              if (chevron) chevron.innerHTML = AppIcons.chevronDown;
            }
          });
        }
        card.classList.toggle('selected');
        const body = card.querySelector('.payment-body-form');
        const chevron = card.querySelector('.payment-chevron');
        if (body) {
          const isSelected = card.classList.contains('selected');
          body.style.display = isSelected ? 'block' : 'none';
          if (chevron) {
            chevron.innerHTML = isSelected ? AppIcons.chevronUp : AppIcons.chevronDown;
          }
        }
      }

      // Search Chips Toggle
      const searchChip = e.target.closest('.search-chip');
      if (searchChip) {
        document.querySelectorAll('.search-chip').forEach(c => c.classList.remove('active'));
        searchChip.classList.add('active');
      }

      // Auth Tabs Toggle (Login vs Sign Up)
      const authTab = e.target.closest('.auth-tab-btn');
      if (authTab) {
        document.querySelectorAll('.auth-tab-btn').forEach(t => t.classList.remove('active'));
        authTab.classList.add('active');
      }
    });

    // View Toggle Button (Mobile Mockup vs Fullscreen)
    const viewToggleBtn = document.getElementById('view-toggle-btn');
    const previewWrapper = document.getElementById('preview-wrapper');
    if (viewToggleBtn && previewWrapper) {
      viewToggleBtn.addEventListener('click', () => {
        previewWrapper.classList.toggle('fullscreen-mode');
        const isFull = previewWrapper.classList.contains('fullscreen-mode');
        viewToggleBtn.innerHTML = isFull
          ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="3"/></svg> Phone Frame`
          : `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"/></svg> Full Width`;
      });
    }
  }

  setupDropdownSwitcher() {
    const pageSelect = document.getElementById('page-jump-select');
    if (pageSelect) {
      pageSelect.addEventListener('change', (e) => {
        this.navigateTo(e.target.value);
      });
    }
  }

  navigateTo(screenId) {
    if (!this.screens.includes(screenId)) return;
    this.currentScreen = screenId;
    window.location.hash = screenId;

    // Switch active screen page
    document.querySelectorAll('.screen-page').forEach(screen => {
      screen.classList.remove('active');
    });

    const targetEl = document.getElementById(`page-${screenId}`);
    if (targetEl) {
      targetEl.classList.add('active');
    }

    // Scroll container to top
    const viewport = document.getElementById('app-viewport');
    if (viewport) {
      viewport.scrollTop = 0;
    }

    // Update Bottom Nav Visibility & Active State
    const bottomNav = document.getElementById('bottom-nav-bar');
    const noNavScreens = ['onboarding', 'login', 'order-confirmation'];

    if (bottomNav) {
      if (noNavScreens.includes(screenId)) {
        bottomNav.style.display = 'none';
      } else {
        bottomNav.style.display = 'flex';
      }

      // Highlight corresponding bottom nav tab
      const activeNavId = this.navTabMap[screenId] || 'nav-home';
      document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
      });
      const activeTabEl = document.getElementById(activeNavId);
      if (activeTabEl) {
        activeTabEl.classList.add('active');
      }
    }

    // Sync Page Dropdown Switcher
    const pageSelect = document.getElementById('page-jump-select');
    if (pageSelect) {
      pageSelect.value = screenId;
    }
  }

  updateClock() {
    const clockEls = document.querySelectorAll('.status-time');
    const now = new Date();
    let hours = now.getHours();
    let minutes = now.getMinutes();
    hours = hours % 12;
    hours = hours ? hours : 12;
    minutes = minutes < 10 ? '0' + minutes : minutes;
    const timeStr = `${hours}:${minutes}`;
    clockEls.forEach(el => el.textContent = '9:41'); // Keep the classic Apple screenshot time or current
  }
}

// Instantiate on DOM Ready
document.addEventListener('DOMContentLoaded', () => {
  window.app = new SiakaApp();
});
