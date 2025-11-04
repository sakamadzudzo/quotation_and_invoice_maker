# Quotation & Invoice Maker - Detailed Design and Development Plan

## Overview
This document outlines the comprehensive plan for developing a Flutter-based mobile application for creating and managing quotations and invoices. The app will be 100% offline-capable with optional Google Drive backup, using Material Design with simple dark/light themes.

## Functional Requirements

### Core Features
1. **Company Management**
   - Create multiple companies with basic info (name, address, phone, email, bank details, terms, disclaimer, logo)
   - Store company logos locally

2. **Quotation Creation**
   - Enter product details: name, description, tax, tax name, quantity, unit price
   - Client information: name, address, phone, email, other details
   - Tax name management with predefined list + "other" option for custom tax names
   - Custom ordering of items
   - Generate quotation under selected company
   - Save generated quotations
   - Copy quotation to other companies

3. **Invoice Creation**
   - Same product/client entry as quotations
   - Convert quotation to invoice (company cannot be changed)
   - Track payments received
   - Edit invoices to add payments
   - Flexible printing options:
     - Each payment as separate invoice with its date
     - Entire invoice with chosen date between first/last payments

4. **Dashboard**
   - Tabs for quotations and invoices
   - List entries with sorting by: client name, company, total value, date created, date modified

### Technical Requirements
- Flutter framework
- Material Design UI with dark/light themes
- 100% offline capability
- Local data storage
- Optional Google Drive backup
- Simple black/white color scheme with accent colors

## Database Schema

### Tables

#### Companies
- id (Primary Key)
- name
- address
- phone
- email
- bank_details (JSON)
- terms
- disclaimer
- logo_path (file path to stored logo)
- created_at
- updated_at

#### Clients
- id (Primary Key)
- name
- address
- phone
- email
- other_info (JSON for additional fields)
- created_at
- updated_at

#### TaxNames
- id (Primary Key)
- name
- is_custom (boolean)
- created_at

#### Quotations
- id (Primary Key)
- company_id (Foreign Key)
- client_id (Foreign Key)
- items (JSON array of items with order)
- total_amount
- status (draft/active/archived)
- created_at
- updated_at

#### Invoices
- id (Primary Key)
- quotation_id (Foreign Key, nullable)
- company_id (Foreign Key)
- client_id (Foreign Key)
- items (JSON array)
- total_amount
- status (unpaid/partially_paid/paid)
- created_at
- updated_at

#### Payments
- id (Primary Key)
- invoice_id (Foreign Key)
- amount
- payment_date
- notes
- created_at

#### Items (Embedded in Quotations/Invoices)
- product_name
- description
- tax_id (Foreign Key to TaxNames)
- quantity
- unit_price
- line_total

## Data Storage Strategy

### Local Storage
- **Database**: SQLite via sqflite package
- **Files**: Company logos stored in app documents directory
- **Backup**: JSON export of all data for Google Drive sync

### Offline-First Approach
- All data stored locally first
- Sync to Google Drive as optional feature
- Conflict resolution for when device comes back online

### File Storage Structure
```
app_documents/
├── database/
│   └── app.db
├── logos/
│   ├── company_1.png
│   ├── company_2.jpg
│   └── ...
└── backups/
    ├── backup_2024_01_01.json
    └── ...
```

## UI/UX Structure

### Navigation
- Bottom navigation bar with Dashboard, Companies, Clients
- Drawer for settings and backup options

### Screens
1. **Dashboard**
   - Tab bar: Quotations | Invoices
   - List view with sorting options
   - FAB for creating new quotation/invoice

2. **Company Management**
   - List of companies
   - Add/Edit company form with logo upload

3. **Client Management**
   - List of clients
   - Add/Edit client form

4. **Quotation/Invoice Creation**
   - Multi-step form: Client selection → Item entry → Review
   - Dynamic item list with drag-to-reorder
   - Tax selection with custom tax dialog

5. **Quotation/Invoice Details**
   - View generated document
   - Edit options (for invoices: add payments)
   - Print/Share options

### Themes
- **Light Theme**: White background, black text, blue accents
- **Dark Theme**: Black background, white text, blue accents
- Simple color palette to maintain focus on content

## Flutter Architecture

### State Management
- **Provider** for app-wide state management
- **ChangeNotifier** for reactive UI updates
- Separate providers for:
  - Companies
  - Clients
  - Quotations
  - Invoices
  - Settings (theme, backup preferences)

### Project Structure
```
lib/
├── models/
│   ├── company.dart
│   ├── client.dart
│   ├── quotation.dart
│   ├── invoice.dart
│   └── ...
├── providers/
│   ├── company_provider.dart
│   ├── client_provider.dart
│   ├── quotation_provider.dart
│   └── ...
├── screens/
│   ├── dashboard_screen.dart
│   ├── company_list_screen.dart
│   ├── quotation_form_screen.dart
│   └── ...
├── widgets/
│   ├── company_card.dart
│   ├── item_input_widget.dart
│   ├── payment_tracker.dart
│   └── ...
├── services/
│   ├── database_service.dart
│   ├── file_service.dart
│   ├── backup_service.dart
│   └── ...
├── utils/
│   ├── constants.dart
│   ├── themes.dart
│   └── helpers.dart
└── main.dart
```

### Key Packages
- sqflite: SQLite database
- provider: State management
- path_provider: File system access
- image_picker: Logo selection
- pdf: PDF generation for printing
- google_sign_in & googleapis: Google Drive backup
- shared_preferences: App settings

## Development Phases

### Phase 1: Foundation (Week 1-2)
- Set up Flutter project
- Implement database schema
- Create basic models and providers
- Set up themes and navigation structure

### Phase 2: Core CRUD (Week 3-4)
- Company management (CRUD)
- Client management (CRUD)
- Basic quotation creation
- Dashboard with list views

### Phase 3: Advanced Features (Week 5-6)
- Invoice creation and conversion from quotations
- Payment tracking
- Tax name management
- Item ordering functionality

### Phase 4: Printing & Export (Week 7-8)
- PDF generation for quotations/invoices
- Flexible printing options for payments
- Print preview functionality

### Phase 5: Backup & Polish (Week 9-10)
- Google Drive integration
- Backup/restore functionality
- UI polish and testing
- Performance optimization

## Assumptions

1. **Platform**: Android first, iOS compatibility ensured
2. **Logo Formats**: Support PNG, JPG, JPEG formats
3. **Currency**: Single currency (user's local currency)
4. **Tax Calculation**: Simple percentage-based tax per item
5. **Printing**: Generate PDF for printing/sharing
6. **Backup**: Google Drive API for cloud backup
7. **Data Volume**: Assume reasonable data size (<100MB total)

## Potential Challenges

1. **Complex Invoice Printing Logic**
   - Handling multiple payment dates and partial invoices
   - PDF generation with proper formatting

2. **Offline-First Sync**
   - Conflict resolution for Google Drive sync
   - Handling large backup files

3. **File Management**
   - Efficient storage and retrieval of logos
   - Handling file permissions on different platforms

4. **UI Complexity**
   - Managing complex forms with dynamic item lists
   - Ensuring responsive design across screen sizes

5. **State Management**
   - Coordinating state between related entities (quotation → invoice → payments)

## Risk Mitigation

1. **Incremental Development**: Build core features first, add complexity gradually
2. **Modular Architecture**: Separate concerns for easier testing and maintenance
3. **Comprehensive Testing**: Unit tests for business logic, integration tests for workflows
4. **User Feedback**: Regular testing with sample data to validate UX
5. **Documentation**: Maintain clear documentation for complex features. Update "Changes tracker"

## Success Metrics

- All CRUD operations working smoothly
- Offline functionality fully operational
- PDF generation accurate and professional-looking
- Google Drive backup working reliably
- UI responsive and intuitive
- App stable with no crashes during normal usage