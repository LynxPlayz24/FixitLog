<h1 align="center">FixItLog 🔧</h1>

<p align="center">
  <strong>A comprehensive, privacy-first Flutter application for tracking vehicle, appliance, and home maintenance.</strong>
</p>

---

## 📖 Overview
FixItLog is a professional-grade maintenance logging app designed to help you keep track of all your equipment and tasks in one place. Whether you're maintaining your car, keeping an eye on your home appliances, or managing a fleet of bicycles, FixItLog provides a clean, intuitive, and robust system to ensure you never miss a maintenance interval again.

## ✨ Key Features
- **Dashboard & Equipment Tracking**: Organize all your items by category (Car, Motorcycle, Electronics, Home, etc.) and view upcoming or overdue maintenance at a glance.
- **Maintenance History Logging**: A strict, chronological log is kept every time you complete a task. This creates an immutable history record that is perfect for warranty claims or selling a vehicle.
- **Smart Reminders**: Fully integrated local notifications (`flutter_local_notifications`) alert you when a task is due. Reminders and sound preferences can be toggled in the settings.
- **Multi-Photo Documentation**: Add multiple photos to your equipment to keep a visual record of conditions or serial numbers.
- **Data Backup & Restore**: Completely offline and privacy-focused. Easily export your entire database (including photos and history) as a standard JSON file and share it to Google Drive, or import it back to restore your data on a new device.

## 🛠 Tech Stack
- **Framework**: [Flutter](https://flutter.dev/) (Dart 3+)
- **Storage**: `shared_preferences` (Local, completely offline data storage)
- **Notifications**: `flutter_local_notifications` & `timezone`
- **File Management**: `share_plus` & `file_picker`

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.7.2`
- Android Studio / Xcode

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/LynxPlayz24/FixitLog.git
   ```
2. Navigate to the project directory:
   ```bash
   cd FixitLog
   ```
3. Get the dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 📦 Releases
You can download the latest APK directly from the [Releases](https://github.com/LynxPlayz24/FixitLog/releases) page.

---
*Built with ❤️ using Flutter.*
