# Subsidy Delivery Partner (Pod Delivery)

A secure, mobile-first Flutter application designed for delivery partners to manage and verify subsidy deliveries.

## 🚀 Features

*   **Secure Authentication**: OTP-based login with profile completion and session management.
*   **On-Device Face Verification**: Incorporates TensorFlow Lite and Google ML Kit for robust, offline facial recognition to verify recipients.
*   **Location Tracking**: Real-time geolocation and geocoding to track deliveries and ensure they happen at the correct locations.
*   **Digital Receipts (PDF)**: Automatically generates and allows viewing of PDF receipts upon successful delivery.
*   **Secure Storage**: Safely stores sensitive information like auth tokens using `flutter_secure_storage`.
*   **Offline Support**: Caches necessary data to ensure delivery partners can operate even in low connectivity areas.

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **State Management**: `provider`
*   **Machine Learning / Computer Vision**:
    *   `tflite_flutter`
    *   `google_mlkit_face_detection`
    *   `image`
*   **Location Services**:
    *   `geolocator`
    *   `geocoding`
*   **Utilities**:
    *   `http` for API communication
    *   `pdf` & `open_filex` for receipt generation
    *   `image_picker` for camera integration
    *   `permission_handler` for managing device permissions

## 📦 Getting Started

### Prerequisites

*   Flutter SDK (v3.8.1 or higher)
*   Dart SDK
*   Android Studio / Xcode for emulators and building

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/your-username/pod_delivery.git
    cd pod_delivery
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the application**
    ```bash
    flutter run
    ```

## 🔐 Permissions Required

The application requires the following permissions to function correctly:
*   **Camera**: Used for facial recognition and taking pictures of deliveries.
*   **Location**: Required to verify the geographical location of the delivery partner during the transaction.

## 📁 Project Structure

```text
lib/
├── api/             # API service and network calls
├── models/          # Data models and serialization
├── providers/       # State management (AuthProvider, FarmerProvider)
├── repositories/    # Data layer handling API and local storage
├── screens/         # UI Screens (Login, Customer List, Splash)
├── services/        # Business logic (Auth, Face Recognition, Farmer)
└── main.dart        # Entry point of the application
```

## 🤝 Contributing

Contributions, issues and feature requests are welcome. Feel free to check [issues page](https://github.com/your-username/pod_delivery/issues) if you want to contribute.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
