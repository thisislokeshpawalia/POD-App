# Functional Requirements Specification (FRS)

## Project: Proof of Delivery (POD) App
**Document Version:** 1.2  
**Date:** August 31, 2026  
**Developed By:** Lokesh Pawalia and Sarthak Srivastava  
**Application Platform:** Android (Flutter Client) & Cloud REST API (FastAPI + MongoDB)  

---

## 1. Executive Summary & Purpose

The **Proof of Delivery (POD) App** is an enterprise-grade mobile and cloud ecosystem engineered to track, manage, and cryptographically verify the distribution of government and organizational subsidies to beneficiaries (farmers). 

The primary objective of Version 1.2 is to eliminate supply-chain leakages, identity impersonation, and fraudulent delivery claims by enforcing strict delivery partner identity validation, local biometric (facial) comparison, GPS geofencing, multi-angle photographic and videographic proof, and automated digital invoice reconciliation.

---

## 2. Project Metadata & Authorship

* **Application Name:** Proof of Delivery (POD) App
* **System Version:** 1.2
* **Lead Developers:** Lokesh Pawalia & Sarthak Srivastava
* **Deployment Target:** Android Mobile Client & Cloud Railway Production Environment
* **Database Management System:** MongoDB Atlas (`pody_db`)
* **Media & Digital Asset CDN:** Cloudinary Cloud Media Services

---

## 3. Technology Stack & Architecture

### 3.1 Mobile Frontend (Flutter)
* **Framework:** Flutter SDK (Dart)
* **State Management:** Provider Architecture (`AuthProvider`, `FarmerProvider`)
* **Local Computer Vision & AI:** Google ML Kit Face Detection (`google_mlkit_face_detection`) & TFLite
* **PDF & Invoice Management:** Syncfusion Flutter PDF Viewer (`syncfusion_flutter_pdfviewer`)
* **Hardware Integrations:** Camera, Image Picker (`image_picker`), Geolocation (`geolocator`), Permissions API (`permission_handler`)
* **Networking & REST Client:** HTTP Client with persistent Bearer JWT authentication and multipart streaming

### 3.2 Cloud Backend (FastAPI & MongoDB)
* **API Framework:** FastAPI (Python 3.11 asynchronous ASGI framework)
* **Server Runtime:** Uvicorn production server hosted on Railway Cloud Platform
* **Database:** MongoDB Atlas with replica set high availability
* **Asset Storage:** Cloudinary REST API for secure video, photo, and invoice PDF distribution
* **Security & Auth:** OAuth2 password bearer tokens with HS256 JWT signature and passlib/bcrypt password hashing

---

## 4. System Roles & User Hierarchy

1. **Delivery Partner (Agent):** The field operative responsible for transporting items, verifying beneficiary credentials, executing on-site facial matching, and capturing delivery proofs.
2. **Beneficiary (Farmer):** The end recipient of subsidized goods entitled to receive deliveries upon providing valid OTP and identity verification.
3. **Backend / System Administrator:** Central administrative authority managing partners, monitoring real-time delivery logs, inspecting media proofs, and maintaining system integrity.

---

## 5. Functional Requirements by Module

### 5.1 Module 1: Partner Authentication & Identity Onboarding

#### FR-1.1: Mobile Number Validation & Check
* The system shall require a valid 10-digit Indian mobile number for partner entry.
* The API endpoint `POST /auth/check-phone` shall determine if the delivery partner has an active profile.

#### FR-1.2: Two-Factor OTP Verification
* The system shall dispatch and verify a numeric One-Time Password (OTP) via `POST /auth/send-otp` and `POST /auth/verify-otp`.
* Default verification code `1234` is provisioned for development and field acceptance testing.

#### FR-1.3: Mandatory Profile Completion Sequence (Strict 8-Step Form)
Upon initial authentication or if key partner details are unpopulated, the app shall redirect the user to the Profile Completion view. The form must follow this exact strict sequence and validation hierarchy:

1. **Full Name:**
   * **Rule:** Must contain strictly alphabetical characters and spaces (`^[a-zA-Z\s]+$`).
   * **Input Restriction:** Configured with `FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))`. Any attempt to enter digits, symbols, or special characters is physically prevented by the software keyboard.
   * **Length:** Minimum 2 characters, maximum 50 characters.

2. **Email Address:**
   * **Rule:** Must be a valid RFC-compliant email address (`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`).
   * **Input Restriction:** Spaces are strictly blocked via `FilteringTextInputFormatter.deny(RegExp(r'\s'))`.

3. **PIN Code (Postal Index Number):**
   * **Rule:** Must be exactly 6 numeric digits (`digitsOnly`, length 6).
   * **Automated Geo-Lookup:** Upon entering the 6th digit, the client shall automatically trigger a background lookup to the Indian Postal API (`https://api.postalpincode.in/pincode/{PINCODE}`).
   * **UI Feedback:** Displays a real-time activity spinner during network resolution and updates helper status upon success.

4. **City & State (Auto-Populated):**
   * **Rule:** City (District) and State fields are automatically filled using the resolved Postal API response.
   * **Behavior:** Fields are configured as `readOnly` by default to eliminate manual typing errors. A manual override toggle is available to handle edge cases or postal server downtime.

5. **Address:**
   * **Rule:** Field operative must supply physical residential or operational address (House/Flat No., Street, Locality). Minimum length of 5 characters.

6. **Vehicle Type:**
   * **Rule:** Selected via structured dropdown: `Two Wheeler`, `Three Wheeler`, `Four Wheeler`, or `Other`. Defaults to `Two Wheeler`.

7. **Vehicle Number:**
   * **Rule:** Must strictly conform to Indian Motor Vehicle Registration standards:
     * State code (2 letters)
     * District RTO code (1-2 digits)
     * Optional series code (1-3 letters)
     * Unique 4-digit number (`0001` - `9999`)
     * Or Bharat Series format (`YY BH #### XX`)
   * **Normalization:** All user inputs are automatically converted to uppercase via `UpperCaseTextFormatter`.

8. **Aadhaar Number:**
   * **Rule:** Must consist of exactly 12 numeric digits (`digitsOnly`).
   * **Specification:** According to UIDAI standards, the first digit cannot be `0` or `1` (Regex: `^[2-9][0-9]{11}$`).

#### FR-1.4: Profile Photo & Cloud Synchronization
* The partner must capture or upload an official photo.
* The client sends profile data via `multipart/form-data` to `PATCH /auth/profile`.
* The server stores the image in Cloudinary under `POD-App/proofs` and records the secure HTTPS URL in MongoDB.

---

### 5.2 Module 2: Farmer & Beneficiary Management

#### FR-2.1: Scoped Beneficiary Allocation
* When a delivery partner logs in, `GET /farmers` retrieves records assigned to that operative's unique partner ID (`delivery_partner_id`).
* Farmers can be filtered dynamically by delivery status: `All`, `Pending`, or `Delivered`.

#### FR-2.2: Beneficiary Registration & Management
* Partners and supervisors can register new farmers on-the-fly via the Farmer Management dialog.
* Collects: Farmer Name, Mobile Number, Village, District, PIN Code, Geolocation (Latitude/Longitude), Assigned Subsidy Items (Item Name, Quantity, Unit), and Profile Reference Photo.
* Uploaded beneficiary profile photos are automatically hosted on Cloudinary for subsequent facial comparison.

#### FR-2.3: Beneficiary Navigation & Communication
* The Beneficiary Detail view provides direct telephony calling via `tel:` intent and mapping redirection via `geo:` coordinate intent.

---

### 5.3 Module 3: Proof of Delivery (POD) & Multi-Factor Verification

Delivery completion requires passing five progressive verification gates to guarantee physical goods handover:

```
+-------------------------------------------------------------------------+
|                  FIVE-STAGE DELIVERY VERIFICATION WORKFLOW               |
+-------------------------------------------------------------------------+
|                                                                         |
|  [Gate 1: Beneficiary OTP]                                              |
|      |--> Beneficiary provides unique 4-digit SMS OTP                    |
|      v                                                                  |
|  [Gate 2: On-Device Facial Verification]                                |
|      |--> Live camera capture analyzed by Google ML Kit                 |
|      |--> Evaluates landmark embeddings against registered photo        |
|      v                                                                  |
|  [Gate 3: Multi-Angle Photographic Proof]                               |
|      |--> Capture 1 to 5 delivery photos (goods handover, surroundings) |
|      v                                                                  |
|  [Gate 4: Video Proof Recording]                                        |
|      |--> Up to 30-second live video documenting physical distribution  |
|      v                                                                  |
|  [Gate 5: Geolocation & Geofencing Stamp]                               |
|      |--> High-accuracy GPS timestamping embedded with delivery audit   |
|                                                                         |
+-------------------------------------------------------------------------+
```

#### FR-3.1: Beneficiary OTP Verification
* Handover begins with verification of the beneficiary's unique delivery OTP.

#### FR-3.2: On-Device Facial Verification
* To operate in remote rural areas with intermittent connectivity, facial comparison executes on the client device.
* Google ML Kit Face Detection detects facial landmarks in the live camera feed and matches them against the beneficiary's registered reference image.
* Verification fails if face is obscured, mismatched, or if confidence threshold is unmet.

#### FR-3.3: Photographic & Videographic Audit Proof
* The operative captures physical delivery photos (handover of subsidy package, goods inspection).
* The operative records a live video audit showing the recipient and goods.

#### FR-3.4: Geolocation Geotagging
* Operative’s precise GPS coordinates are fetched using device location services and permanently tied to the delivery audit log.

---

### 5.4 Module 4: Digital Invoicing & Native Document Inspection

#### FR-4.1: Automated PDF Invoice Generation
* Upon successful delivery verification, the system generates a tamper-evident digital Delivery Invoice PDF containing:
  * Official Header & Serial Tracking Number
  * Delivery Partner Details & Beneficiary Information
  * Itemized Breakdown of Disbursed Subsidy Goods
  * Delivery Completion Timestamp and Geolocation Stamp
  * Status Badge: `DELIVERED & VERIFIED`

#### FR-4.2: Cloud Storage & In-App Native Inspection
* The generated PDF is uploaded automatically to Cloudinary (`POD-App/invoices`).
* The delivery partner can inspect invoices in-app using Syncfusion PDF Viewer (`PdfViewerScreen`) with native pan, zoom, and text rendering.
* Invoices can be saved to local storage or shared via external system intents.

---

## 6. Non-Functional Requirements (NFR)

### 6.1 Performance & Throughput
* API endpoints shall respond within 500ms under standard network conditions.
* Media uploads (images and videos) utilize asynchronous streaming multipart protocols with a 120-second timeout to handle low-bandwidth rural networks.

### 6.2 Security & Data Protection
* Passwords hashed using standard Bcrypt key derivation functions.
* Cloud endpoints enforce Bearer Token Authorization headers; unauthorized requests return `401 Unauthorized`.
* Indian Aadhaar numbers are validated on input to prevent storage of malformed identity numbers.

### 6.3 Usability & Reliability
* Interface follows Material 3 design principles with high-contrast accessibility themes.
* Offline recovery: Form components retain operational state during network dips, and PIN code auto-population includes manual override.

---

## 7. API Specification Matrix

| HTTP Method | Endpoint | Description | Request Type | Auth Required |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/auth/check-phone` | Check if partner phone exists | JSON | No |
| `POST` | `/auth/send-otp` | Dispatch authentication OTP | JSON | No |
| `POST` | `/auth/verify-otp` | Verify authentication OTP | JSON | No |
| `POST` | `/auth/login-or-register` | Create partner session or account | JSON | No |
| `PATCH` | `/auth/profile` | Update partner profile & photo | Multipart / JSON | Yes (Bearer) |
| `GET` | `/auth/me` | Retrieve active partner details | None | Yes (Bearer) |
| `GET` | `/farmers` | List partner-assigned beneficiaries | Query Params | Yes (Bearer) |
| `POST` | `/farmers` | Register new beneficiary | Multipart (Form+Photo) | Yes (Bearer) |
| `GET` | `/farmers/{id}` | Retrieve beneficiary details | Path Param | Yes (Bearer) |
| `PATCH` | `/farmers/{id}` | Update beneficiary details | JSON | Yes (Bearer) |
| `POST` | `/farmers/{id}/upload_proof` | Submit POD (video, photos, PDF) | Multipart Form Data | Yes (Bearer) |
| `DELETE` | `/farmers/{id}` | Delete beneficiary record | Path Param | Yes (Bearer) |

---

## 8. Document Sign-Off & Approvals

| Role | Name | Signature / Status | Date |
| :--- | :--- | :--- | :--- |
| Lead Developer | Lokesh Pawalia | Approved | August 31, 2026 |
| Lead Developer | Sarthak Srivastava | Approved | August 31, 2026 |
| System Version | Version 1.2 | Complete & Released | August 31, 2026 |

*End of Functional Requirements Specification (FRS) - POD App v1.2*
