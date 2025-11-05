# Quotation & Invoice Maker

A fast, offline-capable invoicing and quotation tool built with Flutter (Dart) and SQLite. Designed for individuals, freelancers, SMEs, and tuckshops who need a simple, dependable solution for everyday business paperwork.

## 📋 Overview

Quotation & Invoice Maker is a lightweight, offline-first tool designed for individuals, freelancers, SMEs, and tuckshops who need a simple and reliable way to generate quotations and invoices. It focuses on speed, simplicity, and ease of use—no sign-ups, no subscriptions, no internet required.

Users can manage multiple companies and clients, create quotations, convert them into invoices, track payments, and print clean, professional PDFs. Built with Flutter and SQLite, the tool runs smoothly on mobile and desktop, storing all data locally for full control and privacy.

## ✨ Key Features

### Core Functionality
- **Company Management**: Create multiple companies with logos, bank details, terms, and disclaimers
- **Client Management**: Store client information with custom fields
- **Quotation Creation**: Build quotations with products, taxes, and custom ordering
- **Invoice Generation**: Convert quotations to invoices or create invoices from scratch
- **Payment Tracking**: Record partial payments and track invoice status
- **PDF Printing**: Generate professional PDFs with flexible printing options

### Technical Features
- **100% Offline**: Works without internet connection
- **Local Storage**: SQLite database with file storage for logos
- **Material Design**: Clean UI with light/dark theme support
- **Cross-Platform**: Android, iOS, and desktop support
- **Optional Backup**: Google Drive integration for data safety

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd quotation_invoice_maker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter (Dart)
- **UI Framework**: Material Design 3
- **Database**: SQLite (via sqflite)
- **State Management**: Provider pattern
- **File Storage**: Local file system

### Project Structure
```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic & database
├── utils/           # Constants & themes
└── widgets/         # Reusable UI components
```

### Database Schema
- **Companies**: Business profiles with logos and details
- **Clients**: Customer information
- **Quotations**: Draft/active/archived quotes
- **Invoices**: Bills with payment tracking
- **Payments**: Transaction records
- **TaxNames**: Predefined and custom tax rates

![Entity relationship/database schema diagram](<Data Model.png> "Entity relationship/database schema diagram")

## 📱 Usage Flow

1. **Setup**: Create your company profile and add clients
2. **Create**: Build quotations with products and pricing
3. **Convert**: Transform approved quotations into invoices
4. **Track**: Record payments and monitor balances
5. **Print**: Generate professional PDFs for sharing

## 🎯 Problem Solved

Many small businesses need quotations and invoices, but existing tools are either too complex, require accounts, or need internet access. This solution provides the essential features only—nothing more, nothing less.

**Use Case Example**: A freelancer can create a quotation in under a minute, convert it to an invoice after client approval, add partial payments, and print a PDF—without needing internet or a complex accounting system.

## 🔧 Development

### Building for Production
```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build linux    # Linux
flutter build windows  # Windows
```

### Testing
```bash
flutter test
```

## 📦 Dependencies

Key packages used:
- `sqflite`: SQLite database
- `provider`: State management
- `path_provider`: File system access
- `image_picker`: Logo selection
- `pdf`: PDF generation
- `printing`: Print functionality
- `google_sign_in`: Cloud backup
- `shared_preferences`: Settings storage

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙋 Support

For questions or issues, please open an issue on GitHub or contact the development team.

---

**Tagline**: "Fast, offline, and simple invoicing for individuals and freelancers."
