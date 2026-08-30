# Siaka Phones - Flutter Mobile Edition

An official **Flutter (Dart)** mobile implementation of **Siaka Phones**, matching all 14 screens, AMOLED Dark glassmorphic design system, and full state management for side-by-side comparison with the Web Edition.

---

## 📱 Comparison: Web vs. Flutter

| Feature / Aspect | Web Edition (`/`) | Flutter Edition (`/flutter_app`) |
| :--- | :--- | :--- |
| **Language & Engine** | HTML5, Modern CSS3, JavaScript | Dart 3, Flutter UI Framework (Skia / Impeller) |
| **Styling Paradigm** | CSS Custom Properties, Backdrop Filters | `AppTheme`, `AppColors`, Custom Widgets (`GlassContainer`, `NeonButton`) |
| **State Management** | Vanilla JS Event Listeners & LocalStorage | Reactive MVVM (`ChangeNotifier`, `ListenableBuilder`) |
| **Architecture** | Component HTML Pages & Modules | Clean Layered (Domain Models, Repositories, ViewModels, Views) |
| **Platforms Supported** | Any Web Browser, PWA, Mobile WebView | iOS (`.ipa`), Android (`.apk`), Web, Windows, macOS, Linux |
| **Build Requirement** | Zero build step (Instant reload) | `flutter run` / `flutter build` |

---

## 🏗 Project Architecture

```text
flutter_app/
├── pubspec.yaml
├── README.md
└── lib/
    ├── main.dart                          # Root app, Routing Hub & Dependency Container
    ├── data/
    │   ├── mock_data.dart                 # High-res device specs, images & pricing
    │   └── repositories/
    │       ├── product_repository.dart    # Device queries & catalog filtering
    │       ├── cart_repository.dart       # Reactive cart with ChangeNotifier
    │       ├── order_repository.dart      # Order creation & tracking numbers
    │       ├── repair_repository.dart     # Service booking & cost estimation
    │       ├── location_repository.dart   # Physical boutique directories
    │       └── user_repository.dart       # VIP profile & addresses
    ├── domain/
    │   └── models/
    │       ├── product.dart               # Product domain model
    │       ├── cart_item.dart             # Cart item model
    │       ├── order.dart                 # Order tracking model
    │       ├── repair_booking.dart        # Repair appointment model
    │       ├── trade_in_quote.dart        # Trade-in estimation model
    │       ├── store_location.dart        # Store location model
    │       ├── review.dart                # Verified review model
    │       └── user_profile.dart          # VIP user profile model
    └── ui/
        ├── core/
        │   ├── app_colors.dart            # AMOLED `#060814`, Cyan `#00F2FE`, Neon accents
        │   ├── app_theme.dart             # Material 3 dark theme definitions
        │   └── widgets/
        │       ├── glass_container.dart   # Glassmorphic card container
        │       ├── neon_button.dart       # Glowing gradient primary/secondary buttons
        │       ├── badge_chip.dart        # Filter & category pills
        │       ├── rating_stars.dart      # Golden 5-star rating widget
        │       └── bottom_nav_scaffold.dart # Persistent bottom navigation with cart badge
        └── features/
            ├── splash/                    # Animated splash screen
            ├── home/                      # Highlights, flash deals & categories
            ├── catalog/                   # Search, category filtering & product grid
            ├── product_detail/            # Storage/color selectors & specs accordion
            ├── cart/                      # Quantity adjustment & promo codes
            ├── checkout/                  # Shipping address & payment options
            ├── confirmation/              # Order tracker & digital receipt
            ├── profile/                   # VIP points, addresses & account menu
            ├── orders/                    # Past purchases & live shipment pills
            ├── repairs/                   # Symptom diagnostic & booking form
            ├── tradein/                   # Instant device condition valuation
            ├── support/                   # Interactive simulated AI concierge chat
            ├── locations/                 # Physical store finder & map overview
            └── reviews/                   # Customer review feed & review submission
```

---

## 🚀 How to Run the Flutter App

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and on your system `PATH`.

### Commands
```bash
# 1. Navigate into the Flutter app directory
cd flutter_app

# 2. Get dependencies
flutter pub get

# 3. Run on connected device, emulator, or Chrome
flutter run

# 4. Build Android APK
flutter build apk --release
```
