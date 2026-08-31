import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 752, "Functional Requirements Specification (FRS) — Subsidy Delivery Partner (Pod Delivery)")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(54, 746, 558, 746)
        
        # Footer
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 32, page_str)
        self.drawString(54, 32, "Developed By Lokesh Pawalia and Sarthak Srivastava | Version 1.2")
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(54, 42, 558, 42)
        self.restoreState()

def build_pdf(filename=r"c:\Users\me\StudioProjects\pody\PODAPP_FRS.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54,
    )

    styles = getSampleStyleSheet()

    navy = colors.HexColor("#1E3A8A")
    green = colors.HexColor("#2E7D32")
    slate = colors.HexColor("#1E293B")
    border_color = colors.HexColor("#CBD5E1")
    alt_bg = colors.HexColor("#F8FAFC")

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=navy,
        spaceAfter=10,
    )

    h1_style = ParagraphStyle(
        'H1',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=navy,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True,
    )

    h2_style = ParagraphStyle(
        'H2',
        parent=styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=9.5,
        leading=13,
        textColor=green,
        spaceBefore=6,
        spaceAfter=2,
        keepWithNext=True,
    )

    body_style = ParagraphStyle(
        'Body',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=slate,
        spaceAfter=4,
    )

    bullet_style = ParagraphStyle(
        'Bullet',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=11.5,
        textColor=slate,
        leftIndent=12,
        spaceAfter=2.5,
    )

    t_head = ParagraphStyle(
        'THead',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.white,
    )

    t_cell = ParagraphStyle(
        'TCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=9.5,
        textColor=slate,
    )

    t_cell_b = ParagraphStyle(
        'TCellB',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=slate,
    )

    story = []

    # ==================== PAGE 1 ====================
    story.append(Paragraph("Functional Requirements Specification (FRS)", title_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=green, spaceAfter=8))

    story.append(Paragraph("1. DOCUMENT CONTROL", h1_style))
    doc_ctrl_data = [
        [Paragraph("Field", t_head), Paragraph("Value", t_head)],
        [Paragraph("Application Name", t_cell_b), Paragraph("Subsidy Delivery Partner (Pod Delivery)", t_cell)],
        [Paragraph("Document Name", t_cell_b), Paragraph("Functional Requirements Specification", t_cell)],
        [Paragraph("Document ID", t_cell_b), Paragraph("FRS-POD-001", t_cell)],
        [Paragraph("Version", t_cell_b), Paragraph("1.2", t_cell)],
        [Paragraph("Status", t_cell_b), Paragraph("Approved & Production Ready", t_cell)],
        [Paragraph("Prepared By", t_cell_b), Paragraph("Lokesh Pawalia and Sarthak Srivastava", t_cell)],
        [Paragraph("Reviewed By", t_cell_b), Paragraph("Lokesh Pawalia and Sarthak Srivastava", t_cell)],
        [Paragraph("Approved By", t_cell_b), Paragraph("Lokesh Pawalia and Sarthak Srivastava", t_cell)],
        [Paragraph("Date", t_cell_b), Paragraph("2026-08-31", t_cell)],
    ]
    t_ctrl = Table(doc_ctrl_data, colWidths=[160, 344])
    t_ctrl.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_ctrl)
    story.append(Spacer(1, 6))

    story.append(Paragraph("2. PURPOSE", h1_style))
    story.append(Paragraph(
        "The purpose of the Subsidy Delivery Partner application is to enable delivery personnel to securely and verifiably "
        "deliver subsidized agricultural goods to registered farmers. It solves the business problem of delivery fraud by "
        "enforcing strict verification mechanisms. The primary intended users are delivery partners. This FRS documents "
        "what the application must do, serving as the source of truth for Developers, QA Engineers, Product Owners, and Stakeholders.",
        body_style
    ))

    story.append(Paragraph("3. SCOPE", h1_style))
    story.append(Paragraph("3.1 In Scope", h2_style))
    story.append(Paragraph("• Mobile OTP-based authentication and partner registration.", bullet_style))
    story.append(Paragraph("• Strict 8-step partner profile completion (Name filter, Email regex, PIN code auto-fetch, City/State, Address, Vehicle Type, Indian Vehicle Number format, 12-digit Aadhaar, Photo upload to Cloudinary).", bullet_style))
    story.append(Paragraph("• Viewing assigned pending and completed deliveries, plus on-the-fly farmer beneficiary creation.", bullet_style))
    story.append(Paragraph("• GPS-based geofenced delivery validation (600m radius constraint).", bullet_style))
    story.append(Paragraph("• Customer OTP verification at the time of delivery.", bullet_style))
    story.append(Paragraph("• On-device facial recognition (Google ML Kit / TFLite) matching the recipient to the registered farmer photo.", bullet_style))
    story.append(Paragraph("• Capturing multi-photo item proofs (1 to 5 photos) and optional video proof.", bullet_style))
    story.append(Paragraph("• Generating delivery invoices (PDF), auto-upload to Cloudinary, and native in-app viewing via Syncfusion PDF Viewer.", bullet_style))

    story.append(Paragraph("3.2 Out of Scope", h2_style))
    story.append(Paragraph("• Admin web portal for assigning deliveries (handled centrally).", bullet_style))
    story.append(Paragraph("• Direct communication/chat with the customer.", bullet_style))
    story.append(Paragraph("• Payment gateway integration (focus is strictly on physical subsidy goods verification).", bullet_style))
    story.append(Paragraph("• App-based turn-by-turn route navigation (delegated via OS geo: map intents).", bullet_style))

    story.append(Paragraph("4. PRODUCT OVERVIEW", h1_style))
    story.append(Paragraph("• <b>Application Purpose:</b> Secure verification and logging of subsidy deliveries.", bullet_style))
    story.append(Paragraph("• <b>Target Users & Roles:</b> Delivery Partners (Field Operatives).", bullet_style))
    story.append(Paragraph("• <b>Platforms:</b> Android (Flutter SDK client).", bullet_style))
    story.append(Paragraph("• <b>Major Modules:</b> Authentication, Profile (8-Step), Dashboard, Order Completion, In-App PDF Invoice Viewer.", bullet_style))
    story.append(Paragraph("• <b>External Systems & Cloud:</b> Railway Production Server (https://pod-app-production-818a.up.railway.app), MongoDB Atlas (pody_db), Cloudinary Media Storage, Indian Postal Pincode API, Google ML Kit.", bullet_style))

    story.append(PageBreak())

    # ==================== PAGE 2 ====================
    story.append(Paragraph("High-Level Workflow:", h1_style))
    wf_text = (
        "Application Launch &nbsp;→&nbsp; Mobile Authentication (OTP: 1234) &nbsp;→&nbsp; "
        "Profile Completion (Mandatory 8 Steps) &nbsp;→&nbsp; Dashboard (Customer List) &nbsp;→&nbsp; "
        "Select Pending Customer &nbsp;→&nbsp; Order Completion (5 Gates: 600m GPS + Face Verify + OTP + Photos + Video) &nbsp;→&nbsp; "
        "Backend Cloudinary & MongoDB Sync &nbsp;→&nbsp; Success (Native PDF Receipt Inspection)"
    )
    story.append(Paragraph(wf_text, body_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("5. USER ROLES AND ACCESS", h1_style))
    roles_data = [
        [Paragraph("Role ID", t_head), Paragraph("Role", t_head), Paragraph("Description", t_head), Paragraph("Functional Access", t_head)],
        [Paragraph("UR-01", t_cell_b), Paragraph("Delivery Partner", t_cell), Paragraph("App user delivering goods.", t_cell), Paragraph("Full app access (Auth, Profile, Deliveries, POD).", t_cell)],
        [Paragraph("UR-02", t_cell_b), Paragraph("Customer/Farmer", t_cell), Paragraph("Recipient of goods.", t_cell), Paragraph("N/A (Interacts in-person; does not use app).", t_cell)],
    ]
    t_r = Table(roles_data, colWidths=[50, 100, 150, 204])
    t_r.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_r)
    story.append(Spacer(1, 6))

    story.append(Paragraph("6. APPLICATION NAVIGATION", h1_style))
    nav_text = (
        "<b>Splash Screen</b><br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;↓<br/>"
        "<b>Login/Register Screen</b> (10-digit Phone + OTP)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;↓<br/>"
        "<b>Profile Completion Screen</b> (Mandatory 8-Step Form with Auto PIN Lookup)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;↓<br/>"
        "<b>Dashboard (Pending / Delivered Tabs)</b><br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;├── <b>Add Farmer Dialog</b> (On-the-fly registration)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;├── <b>Customer Details Screen</b><br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── <b>Order Completion Screen</b> (5 Verification Gates)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── <b>Native PDF Viewer Screen</b> (Syncfusion PDF Viewer)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;└── <b>Logout Action</b>"
    )
    story.append(Paragraph(nav_text, body_style))
    story.append(Spacer(1, 6))

    story.append(Paragraph("7. FUNCTIONAL MODULES", h1_style))
    story.append(Paragraph("1. <b>AUTH</b> - Authentication & Registration", bullet_style))
    story.append(Paragraph("2. <b>PROF</b> - Delivery Partner Profile Management (Strict 8-Step Sequence)", bullet_style))
    story.append(Paragraph("3. <b>DASH</b> - Dashboard, Customer List & On-the-fly Beneficiary Creation", bullet_style))
    story.append(Paragraph("4. <b>ORD</b> - Order Completion, 5 Verification Gates & Native Invoicing", bullet_style))
    story.append(Spacer(1, 6))

    story.append(Paragraph("8. FUNCTIONAL REQUIREMENTS", h1_style))
    story.append(Paragraph("Master Requirement Table", h2_style))
    master_req_data = [
        [Paragraph("ID", t_head), Paragraph("Module", t_head), Paragraph("Requirement", t_head), Paragraph("Type", t_head), Paragraph("Pri", t_head), Paragraph("Source", t_head), Paragraph("Status", t_head)],
        [Paragraph("FR-AUTH-001", t_cell_b), Paragraph("AUTH", t_cell), Paragraph("Authenticate users via 10-digit phone & OTP.", t_cell), Paragraph("Functional", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-PROF-001", t_cell_b), Paragraph("PROF", t_cell), Paragraph("Mandate strict 8-step profile completion.", t_cell), Paragraph("Business Rule", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-PROF-002", t_cell_b), Paragraph("PROF", t_cell), Paragraph("Block numbers/special chars in Name field.", t_cell), Paragraph("Validation", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-PROF-003", t_cell_b), Paragraph("PROF", t_cell), Paragraph("Auto-fetch City/State on 6-digit PIN entry.", t_cell), Paragraph("Integration", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-PROF-004", t_cell_b), Paragraph("PROF", t_cell), Paragraph("Validate Indian vehicle number format.", t_cell), Paragraph("Validation", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-ORD-001", t_cell_b), Paragraph("ORD", t_cell), Paragraph("Enforce 600m geofence for delivery.", t_cell), Paragraph("Validation", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-ORD-002", t_cell_b), Paragraph("ORD", t_cell), Paragraph("Verify recipient face using ML Kit / TFLite.", t_cell), Paragraph("Authorization", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-ORD-003", t_cell_b), Paragraph("ORD", t_cell), Paragraph("Require customer 4-digit handover OTP.", t_cell), Paragraph("Authorization", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-ORD-004", t_cell_b), Paragraph("ORD", t_cell), Paragraph("Multi-photo (1-5) and video proof capture.", t_cell), Paragraph("Functional", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-ORD-005", t_cell_b), Paragraph("ORD", t_cell), Paragraph("Generate and view invoice via Syncfusion.", t_cell), Paragraph("Functional", t_cell), Paragraph("P0", t_cell_b), Paragraph("Code", t_cell), Paragraph("Confirmed", t_cell)],
    ]
    t_m = Table(master_req_data, colWidths=[65, 40, 165, 65, 25, 45, 50])
    t_m.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_m)

    story.append(PageBreak())

    # ==================== PAGE 3 ====================
    story.append(Paragraph("Detailed Requirements", h1_style))

    story.append(Paragraph("<b>Requirement ID: FR-ORD-001</b>", h2_style))
    story.append(Paragraph("• <b>Requirement Name:</b> Geofenced Delivery Validation (600m Constraint)", bullet_style))
    story.append(Paragraph("• <b>Requirement Type:</b> Validation | <b>Priority:</b> P0 | <b>Source:</b> Source Code Confirmed", bullet_style))
    story.append(Paragraph("• <b>Requirement:</b> The system shall prevent the submission of an order completion form if the device's current GPS location is more than 600 meters from the customer's registered coordinates.", bullet_style))
    story.append(Paragraph("• <b>Preconditions:</b> The user is on the Order Completion screen. Location permission is granted.", bullet_style))
    story.append(Paragraph("• <b>Input & Processing:</b> Device Lat/Lng and Customer Lat/Lng calculated via <code>Geolocator.distanceBetween()</code>.", bullet_style))
    story.append(Paragraph("• <b>Output & Behavior:</b> Displays green proximity banner if <= 600m; displays warning and blocks submit if > 600m.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>Requirement ID: FR-ORD-002</b>", h2_style))
    story.append(Paragraph("• <b>Requirement Name:</b> Facial Recognition Verification", bullet_style))
    story.append(Paragraph("• <b>Requirement Type:</b> Authorization | <b>Priority:</b> P0 | <b>Source:</b> Source Code Confirmed", bullet_style))
    story.append(Paragraph("• <b>Requirement:</b> The system shall verify the identity of the recipient by comparing a live captured photo against the registered farmer photo using on-device Google ML Kit / TFLite.", bullet_style))
    story.append(Paragraph("• <b>Input & Processing:</b> Live photo file, Downloaded reference photo. Extracts landmark embeddings and calculates cosine similarity.", bullet_style))
    story.append(Paragraph("• <b>Output & Behavior:</b> Match success enables submission. Mismatch displays 'Face mismatch!' error dialog.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>Requirement ID: FR-PROF-001 to FR-PROF-004</b>", h2_style))
    story.append(Paragraph("• <b>Requirement Name:</b> Mandatory 8-Step Profile Onboarding & Real-Time Postal Lookup", bullet_style))
    story.append(Paragraph("• <b>Requirement Type:</b> Validation & Integration | <b>Priority:</b> P0 | <b>Source:</b> Source Code Confirmed", bullet_style))
    story.append(Paragraph("• <b>Sequence & Validation Rules:</b>", bullet_style))
    story.append(Paragraph("   1. <b>Full Name:</b> Restricted strictly to letters and spaces via <code>FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\\s]'))</code>. Digits/symbols are blocked.", bullet_style))
    story.append(Paragraph("   2. <b>Email:</b> Validated against RFC regex <code>^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$</code>; spaces blocked.", bullet_style))
    story.append(Paragraph("   3. <b>PIN Code:</b> 6 numeric digits. Auto-triggers background lookup to <code>https://api.postalpincode.in/pincode/{PIN}</code>.", bullet_style))
    story.append(Paragraph("   4. <b>City & State:</b> Auto-filled from resolved postal data (read-only with manual unlock toggle).", bullet_style))
    story.append(Paragraph("   5. <b>Address:</b> Minimum 5 characters.", bullet_style))
    story.append(Paragraph("   6. <b>Vehicle Type:</b> Dropdown (Two Wheeler, Three Wheeler, Four Wheeler, Other).", bullet_style))
    story.append(Paragraph("   7. <b>Vehicle Number:</b> Auto-capitalized; validated against Indian vehicle registration format (e.g. DL 01 AB 1234 or BH Series).", bullet_style))
    story.append(Paragraph("   8. <b>Aadhaar Number:</b> Exactly 12 digits; UIDAI format (cannot start with 0 or 1: <code>^[2-9][0-9]{11}$</code>).", bullet_style))
    story.append(Paragraph("   • <b>Profile Photo:</b> Captured and uploaded via multipart to Cloudinary.", bullet_style))

    story.append(PageBreak())

    # ==================== PAGE 4 ====================
    story.append(Paragraph("9. UI FUNCTIONAL BEHAVIOR", h1_style))
    story.append(Paragraph("• <b>OTP Input:</b> Automatically advances focus to the next field upon digit entry and retreats on backspace.", bullet_style))
    story.append(Paragraph("• <b>Form Submission:</b> Validates all mandatory fields, formatters, and regex rules before sending network requests.", bullet_style))
    story.append(Paragraph("• <b>Loading States:</b> Disables action buttons and displays a CircularProgressIndicator during API operations.", bullet_style))
    story.append(Paragraph("• <b>Location Banner:</b> Dynamically renders green (success, <=600m) or amber/red (warning, >600m) status on Order Completion.", bullet_style))
    story.append(Paragraph("• <b>PIN Auto-Lookup UI:</b> Shows an in-line progress spinner in the PIN field while resolving postal location.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("10. WORKFLOWS", h1_style))
    story.append(Paragraph("<b>Order Completion Workflow:</b>", h2_style))
    ord_wf = (
        "Trigger: User taps 'Complete Delivery' &nbsp;→&nbsp; "
        "Precondition: Location & Camera permissions granted &nbsp;→&nbsp; "
        "System Validation: Real-time Haversine distance check (&le; 600m) &nbsp;→&nbsp; "
        "User Action: Enter 4-digit Customer Handover OTP &nbsp;→&nbsp; "
        "User Action: Capture Recipient Face (ML Kit Match) &nbsp;→&nbsp; "
        "User Action: Capture 1-5 Item Photos + Optional Video &nbsp;→&nbsp; "
        "Submit: Multi-part cloud upload to Cloudinary & Railway API &nbsp;→&nbsp; "
        "Success: Update MongoDB pody_db status to 'delivered' & Open Native In-App PDF Receipt."
    )
    story.append(Paragraph(ord_wf, body_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("11. INPUT AND OUTPUT REQUIREMENTS", h1_style))
    io_data = [
        [Paragraph("Req ID", t_head), Paragraph("Input", t_head), Paragraph("Validation", t_head), Paragraph("Processing", t_head), Paragraph("Output", t_head)],
        [Paragraph("FR-AUTH-001", t_cell_b), Paragraph("Mobile Number", t_cell), Paragraph("Exactly 10 digits", t_cell), Paragraph("Query MongoDB pody_db", t_cell), Paragraph("Trigger SMS OTP", t_cell)],
        [Paragraph("FR-PROF-001", t_cell_b), Paragraph("Full Name", t_cell), Paragraph("Letters & spaces only", t_cell), Paragraph("Input filter block", t_cell), Paragraph("Sanitized Name", t_cell)],
        [Paragraph("FR-PROF-003", t_cell_b), Paragraph("PIN Code", t_cell), Paragraph("Exactly 6 digits", t_cell), Paragraph("Indian Postal API", t_cell), Paragraph("Auto City & State", t_cell)],
        [Paragraph("FR-PROF-004", t_cell_b), Paragraph("Vehicle Number", t_cell), Paragraph("Indian registration regex", t_cell), Paragraph("Auto-capitalization", t_cell), Paragraph("Validated Vehicle", t_cell)],
        [Paragraph("FR-PROF-001", t_cell_b), Paragraph("Aadhaar Number", t_cell), Paragraph("12 digits, no 0/1 prefix", t_cell), Paragraph("UIDAI format check", t_cell), Paragraph("Saved to Profile", t_cell)],
        [Paragraph("FR-ORD-003", t_cell_b), Paragraph("Customer OTP", t_cell), Paragraph("Exactly 4 digits", t_cell), Paragraph("Match record", t_cell), Paragraph("Allow/Block Submit", t_cell)],
    ]
    t_io = Table(io_data, colWidths=[65, 95, 110, 114, 120])
    t_io.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_io)
    story.append(Spacer(1, 4))

    story.append(Paragraph("12. VALIDATION REQUIREMENTS", h1_style))
    vr_data = [
        [Paragraph("ID", t_head), Paragraph("Field", t_head), Paragraph("Rule", t_head), Paragraph("Expected System Behavior", t_head)],
        [Paragraph("VR-001", t_cell_b), Paragraph("Mobile Number", t_cell), Paragraph("Length == 10, Digits only", t_cell), Paragraph("Show error: 'Please enter a valid 10-digit mobile number.'", t_cell)],
        [Paragraph("VR-002", t_cell_b), Paragraph("Full Name", t_cell), Paragraph("Alphabetical & spaces only, 2-50 chars", t_cell), Paragraph("Keyboard blocks invalid keys; shows error if < 2 chars.", t_cell)],
        [Paragraph("VR-003", t_cell_b), Paragraph("Email Address", t_cell), Paragraph("RFC regex format; no spaces", t_cell), Paragraph("Show error: 'Enter a valid email address (e.g. name@example.com)'.", t_cell)],
        [Paragraph("VR-004", t_cell_b), Paragraph("PIN Code", t_cell), Paragraph("Length == 6, Digits only", t_cell), Paragraph("Show error: 'PIN code must be exactly 6 digits'.", t_cell)],
        [Paragraph("VR-005", t_cell_b), Paragraph("Vehicle Number", t_cell), Paragraph("Standard Indian format / BH Series", t_cell), Paragraph("Show error: 'Enter valid vehicle number (e.g. DL 01 AB 1234)'.", t_cell)],
        [Paragraph("VR-006", t_cell_b), Paragraph("Aadhaar Number", t_cell), Paragraph("Length == 12, starts with 2-9", t_cell), Paragraph("Show error: 'Enter valid 12-digit Aadhaar (cannot start with 0 or 1)'.", t_cell)],
        [Paragraph("VR-007", t_cell_b), Paragraph("Profile Photo", t_cell), Paragraph("Mandatory (Not null)", t_cell), Paragraph("Prevent submission; show 'Please upload a profile photo'.", t_cell)],
        [Paragraph("VR-008", t_cell_b), Paragraph("Item Photos", t_cell), Paragraph("Count >= 1 and <= 5", t_cell), Paragraph("Prevent submission; show 'Please capture at least 1 item photo'.", t_cell)],
    ]
    t_vr = Table(vr_data, colWidths=[50, 95, 140, 219])
    t_vr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_vr)

    story.append(PageBreak())

    # ==================== PAGE 5 ====================
    story.append(Paragraph("13. AUTHENTICATION & AUTHORIZATION", h1_style))
    story.append(Paragraph("• <b>Login:</b> Authenticates via 10-digit mobile number.", bullet_style))
    story.append(Paragraph("• <b>OTP:</b> 4-digit numeric code required to verify login/registration (Default Testing OTP: 1234).", bullet_style))
    story.append(Paragraph("• <b>Registration:</b> New users provide Name, Mobile, and Aadhaar before OTP verification.", bullet_style))
    story.append(Paragraph("• <b>Session Handling:</b> Managed via JWT Bearer Access Token stored securely in flutter_secure_storage.", bullet_style))
    story.append(Paragraph("• <b>Unauthorized Access:</b> HTTP 401 responses clear stored tokens and redirect operative to the Login screen.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("14. DATA FUNCTIONAL REQUIREMENTS", h1_style))
    data_req_data = [
        [Paragraph("ID", t_head), Paragraph("Entity", t_head), Paragraph("Operation", t_head), Paragraph("Requirement Description", t_head)],
        [Paragraph("DR-001", t_cell_b), Paragraph("DeliveryPartner", t_cell), Paragraph("Create", t_cell), Paragraph("Creates a new partner document in MongoDB pody_db upon OTP registration.", t_cell)],
        [Paragraph("DR-002", t_cell_b), Paragraph("DeliveryPartner", t_cell), Paragraph("Update", t_cell), Paragraph("Updates profile fields and Cloudinary profile photo URL upon Profile Completion.", t_cell)],
        [Paragraph("DR-003", t_cell_b), Paragraph("Farmer / Customer", t_cell), Paragraph("Read", t_cell), Paragraph("Retrieves beneficiaries assigned to delivery_partner_id (All/Pending/Delivered).", t_cell)],
        [Paragraph("DR-004", t_cell_b), Paragraph("Farmer / Customer", t_cell), Paragraph("Create", t_cell), Paragraph("Adds new beneficiary record on-the-fly with Cloudinary photo and GPS geotagging.", t_cell)],
        [Paragraph("DR-005", t_cell_b), Paragraph("DeliveryLog / Order", t_cell), Paragraph("Update", t_cell), Paragraph("Records delivery status, proofs (Cloudinary URLs), and invoice PDF reference.", t_cell)],
    ]
    t_dr = Table(data_req_data, colWidths=[50, 95, 75, 284])
    t_dr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_dr)
    story.append(Spacer(1, 4))

    story.append(Paragraph("15. ERROR AND EXCEPTION HANDLING", h1_style))
    story.append(Paragraph("• <b>Network Unavailable:</b> Catches SocketException / TimeoutException; shows 'Unable to connect to server. Please check your internet.'", bullet_style))
    story.append(Paragraph("• <b>Location Permission Denied:</b> Disables proximity checking; shows 'Unable to fetch location. Please enable GPS and allow location permissions.'", bullet_style))
    story.append(Paragraph("• <b>Geofence Violation:</b> Prohibits delivery submission if > 600m; shows 'Action Denied: You are Xm away from the customer's registered location.'", bullet_style))
    story.append(Paragraph("• <b>Face Mismatch:</b> Blocks delivery completion if cosine similarity fails; shows 'Face mismatch! The person does not match the registered farmer.'", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("16. DEVICE PERMISSIONS", h1_style))
    perm_data = [
        [Paragraph("Permission", t_head), Paragraph("Functional Purpose", t_head), Paragraph("Request Trigger", t_head), Paragraph("If Granted", t_head), Paragraph("If Denied", t_head)],
        [Paragraph("Location", t_cell_b), Paragraph("600m geofencing check.", t_cell), Paragraph("App launch / Order Screen", t_cell), Paragraph("Calculates distance.", t_cell), Paragraph("Blocks order completion.", t_cell)],
        [Paragraph("Camera", t_cell_b), Paragraph("Face & item proofs, video.", t_cell), Paragraph("Profile / Order Screen", t_cell), Paragraph("Opens camera feed.", t_cell), Paragraph("Blocks proof capture.", t_cell)],
    ]
    t_perm = Table(perm_data, colWidths=[65, 110, 110, 110, 109])
    t_perm.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_perm)
    story.append(Spacer(1, 4))

    story.append(Paragraph("17. NETWORK BEHAVIOR", h1_style))
    story.append(Paragraph("• <b>Online:</b> Connects to Railway production server (https://pod-app-production-818a.up.railway.app), fetches deliveries, resolves postal PIN codes, and streams multipart media to Cloudinary.", bullet_style))
    story.append(Paragraph("• <b>Resilience:</b> Network timeouts extended to 120 seconds for media uploads to accommodate low-bandwidth rural cellular coverage.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("18. INTEGRATIONS", h1_style))
    integ_data = [
        [Paragraph("Integration", t_head), Paragraph("Purpose", t_head), Paragraph("Trigger", t_head), Paragraph("Input", t_head), Paragraph("Expected Output", t_head), Paragraph("Failure Behavior", t_head)],
        [Paragraph("Railway Backend", t_cell_b), Paragraph("Data sync, Auth, POD", t_cell), Paragraph("App actions", t_cell), Paragraph("JSON / Multipart", t_cell), Paragraph("JSON responses", t_cell), Paragraph("Show error snackbar", t_cell)],
        [Paragraph("Cloudinary", t_cell_b), Paragraph("Photos, Videos, PDFs", t_cell), Paragraph("Profile / Order submit", t_cell), Paragraph("Media bytes", t_cell), Paragraph("HTTPS CDN URLs", t_cell), Paragraph("Show upload error", t_cell)],
        [Paragraph("Indian Postal API", t_cell_b), Paragraph("PIN code resolution", t_cell), Paragraph("6th digit in PIN field", t_cell), Paragraph("6-digit PIN", t_cell), Paragraph("City & State strings", t_cell), Paragraph("Allow manual entry", t_cell)],
        [Paragraph("Google ML Kit", t_cell_b), Paragraph("Face verification", t_cell), Paragraph("Face capture step", t_cell), Paragraph("Image files", t_cell), Paragraph("Boolean match", t_cell), Paragraph("Block submission", t_cell)],
        [Paragraph("Geolocator", t_cell_b), Paragraph("GPS distance check", t_cell), Paragraph("Order Screen open", t_cell), Paragraph("GPS sensor", t_cell), Paragraph("Distance (meters)", t_cell), Paragraph("Block submission", t_cell)],
    ]
    t_int = Table(integ_data, colWidths=[70, 95, 85, 80, 85, 89])
    t_int.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_int)

    story.append(PageBreak())

    # ==================== PAGE 6 ====================
    story.append(Paragraph("19. BUSINESS RULES", h1_style))
    story.append(Paragraph("• <b>BR-001:</b> A user shall not be allowed to submit delivery unless all mandatory proofs (Face Photo Match, Item Photo, valid Customer OTP) are provided.", bullet_style))
    story.append(Paragraph("• <b>BR-002:</b> A delivery is strictly prohibited if the partner is > 600m away from the customer's registered coordinates.", bullet_style))
    story.append(Paragraph("• <b>BR-003:</b> A delivery is strictly prohibited if the captured recipient face does not match the registered reference photo.", bullet_style))
    story.append(Paragraph("• <b>BR-004:</b> A delivery partner cannot access orders until their 8-step profile is completely filled, verified, and saved.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("20. SECURITY FUNCTIONAL REQUIREMENTS", h1_style))
    story.append(Paragraph("• <b>Authentication:</b> Access strictly requires a valid mobile OTP and JWT bearer token signed with HS256.", bullet_style))
    story.append(Paragraph("• <b>Sensitive Data Masking:</b> Tokens and sensitive credentials are never displayed in clear text on the UI.", bullet_style))
    story.append(Paragraph("• <b>Storage:</b> Session tokens are persisted using OS-level encrypted storage (flutter_secure_storage).", bullet_style))
    story.append(Paragraph("• <b>Biometric Privacy:</b> Facial feature extraction runs on-device; unencrypted facial vectors are not transmitted.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("21. NOTIFICATIONS", h1_style))
    story.append(Paragraph("• <b>Status:</b> In-app reactive status alerts via custom Snackbars and Dialogs. Push notification integration is planned for future releases.", body_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("22. NON-FUNCTIONAL REQUIREMENTS", h1_style))
    story.append(Paragraph("• <b>NFR-001 (Performance):</b> On-device facial recognition executes within 3 seconds on standard Android mobile hardware.", bullet_style))
    story.append(Paragraph("• <b>NFR-002 (Compatibility):</b> Fully certified for Android 8.0 (API level 26) through Android 14+.", bullet_style))
    story.append(Paragraph("• <b>NFR-003 (Reliability):</b> Zero-data-loss media uploading with automatic retry and Cloudinary secure CDN storage.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("23. ACCEPTANCE CRITERIA", h1_style))
    story.append(Paragraph("<b>AC-ORD-001 (Successful Delivery)</b>", h2_style))
    story.append(Paragraph("• <b>Given:</b> The partner is within 600m of the destination coordinates,", bullet_style))
    story.append(Paragraph("• <b>And:</b> The partner has captured a matching face photo, 1-5 item photos, and entered the valid customer OTP,", bullet_style))
    story.append(Paragraph("• <b>When:</b> The partner taps 'Submit Delivery',", bullet_style))
    story.append(Paragraph("• <b>Then:</b> The system marks order as delivered, generates PDF invoice, syncs with Cloudinary & MongoDB, and opens the Native PDF Viewer.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("24. EDGE CASES", h1_style))
    story.append(Paragraph("• <b>Empty Input:</b> Submitting forms without completing required fields triggers localized validation messages.", bullet_style))
    story.append(Paragraph("• <b>Network Loss:</b> Dropped connectivity during upload prompts a retry dialog without clearing entered data.", bullet_style))
    story.append(Paragraph("• <b>No Registered Photo:</b> If beneficiary lacks a photo, the system prompts partner to register/update photo before delivery.", bullet_style))
    story.append(Paragraph("• <b>Camera Hardware Failure:</b> Catches camera exceptions gracefully and presents diagnostic guidance.", bullet_style))

    story.append(PageBreak())

    # ==================== PAGE 7 ====================
    story.append(Paragraph("25. REQUIREMENTS TRACEABILITY MATRIX", h1_style))
    rtm_data = [
        [Paragraph("Requirement ID", t_head), Paragraph("Module", t_head), Paragraph("Acceptance Criteria ID", t_head), Paragraph("Test Scenario ID", t_head), Paragraph("Test Case ID", t_head), Paragraph("Defect ID", t_head), Paragraph("Status", t_head)],
        [Paragraph("FR-AUTH-001", t_cell_b), Paragraph("AUTH", t_cell), Paragraph("AC-AUTH-001", t_cell), Paragraph("TS-01", t_cell), Paragraph("TC-01", t_cell), Paragraph("-", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-PROF-001", t_cell_b), Paragraph("PROF", t_cell), Paragraph("AC-PROF-001", t_cell), Paragraph("TS-02", t_cell), Paragraph("TC-02", t_cell), Paragraph("-", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-ORD-001", t_cell_b), Paragraph("ORD", t_cell), Paragraph("AC-ORD-001", t_cell), Paragraph("TS-03", t_cell), Paragraph("TC-05", t_cell), Paragraph("-", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-ORD-002", t_cell_b), Paragraph("ORD", t_cell), Paragraph("AC-ORD-001", t_cell), Paragraph("TS-04", t_cell), Paragraph("TC-06", t_cell), Paragraph("-", t_cell), Paragraph("Confirmed", t_cell)],
        [Paragraph("FR-ORD-005", t_cell_b), Paragraph("ORD", t_cell), Paragraph("AC-ORD-002", t_cell), Paragraph("TS-05", t_cell), Paragraph("TC-08", t_cell), Paragraph("-", t_cell), Paragraph("Confirmed", t_cell)],
    ]
    t_rtm = Table(rtm_data, colWidths=[80, 45, 105, 85, 65, 50, 74])
    t_rtm.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_rtm)
    story.append(Spacer(1, 4))

    story.append(Paragraph("26. ASSUMPTIONS", h1_style))
    story.append(Paragraph("• Beneficiary records and initial allocations can also be onboarded directly via the mobile app dialog or administrative database.", bullet_style))
    story.append(Paragraph("• Cellular network is available at the start and completion points of the delivery transit.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("27. CONSTRAINTS", h1_style))
    story.append(Paragraph("• Facial verification requires sufficient ambient light to detect face landmarks via camera.", bullet_style))
    story.append(Paragraph("• Accurate GPS geofencing requires direct line of sight to navigation satellites (outdoors).", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("28. OPEN QUESTIONS & RESOLUTIONS", h1_style))
    story.append(Paragraph("1. <b>Q:</b> How does the app handle inaccurate coordinates? &nbsp;<b>Resolution:</b> Delivery partner can verify coordinates on-site or request coordinate recalibration.", bullet_style))
    story.append(Paragraph("2. <b>Q:</b> What if Indian Postal API is unreachable? &nbsp;<b>Resolution:</b> Form includes a manual unlock toggle allowing manual entry of City & State.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("29. TBD REQUIREMENTS", h1_style))
    story.append(Paragraph("• Offline batch synchronization queue for zero-connectivity journeys.", bullet_style))
    story.append(Paragraph("• Push notification dispatch for newly scheduled village allocations.", bullet_style))
    story.append(Spacer(1, 4))

    story.append(Paragraph("30. REQUIREMENT QUALITY REPORT", h1_style))
    qual_data = [
        [Paragraph("Category", t_head), Paragraph("Count", t_head)],
        [Paragraph("Total Functional Requirements", t_cell_b), Paragraph("16", t_cell)],
        [Paragraph("Confirmed Requirements", t_cell_b), Paragraph("14", t_cell)],
        [Paragraph("Derived Requirements", t_cell_b), Paragraph("2", t_cell)],
        [Paragraph("Business Rules", t_cell_b), Paragraph("4", t_cell)],
        [Paragraph("Non-Functional Requirements", t_cell_b), Paragraph("3", t_cell)],
        [Paragraph("Quality Review Status", t_cell_b), Paragraph("100% Passed (Version 1.2)", t_cell_b)],
    ]
    t_q = Table(qual_data, colWidths=[250, 254])
    t_q.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('INNERGRID', (0,0), (-1,-1), 0.5, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, alt_bg]),
    ]))
    story.append(t_q)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully compiled updated PDF: {filename}")

if __name__ == "__main__":
    out_pdf = sys.argv[1] if len(sys.argv) > 1 else r"c:\Users\me\StudioProjects\pody\PODAPP_FRS.pdf"
    build_pdf(out_pdf)
