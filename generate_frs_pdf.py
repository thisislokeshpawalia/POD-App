import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
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
            self.drawString(54, 750, "POD App v1.2 — Functional Requirements Specification (FRS)")
            self.setStrokeColor(colors.HexColor("#E2E8F0"))
            self.setLineWidth(0.5)
            self.line(54, 744, 558, 744)
        
        # Footer
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 36, page_str)
        self.drawString(54, 36, "Developed By Lokesh Pawalia & Sarthak Srivastava | Confidential & Proprietary")
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(54, 46, 558, 46)
        self.restoreState()

def build_pdf(filename="FRS_POD_App_v1.2.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54,
    )

    styles = getSampleStyleSheet()

    # Custom styles
    primary_color = colors.HexColor("#1E3A8A")  # Deep Navy Blue
    accent_color = colors.HexColor("#2E7D32")   # Forest Green
    text_color = colors.HexColor("#1E293B")     # Dark Slate
    muted_color = colors.HexColor("#64748B")    # Slate Muted

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=primary_color,
        spaceAfter=6,
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=12,
        leading=16,
        textColor=accent_color,
        spaceAfter=14,
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=primary_color,
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True,
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=accent_color,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True,
    )

    body_style = ParagraphStyle(
        'DocBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=14,
        textColor=text_color,
        spaceAfter=6,
    )

    bullet_style = ParagraphStyle(
        'DocBullet',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13.5,
        textColor=text_color,
        leftIndent=14,
        spaceAfter=4,
    )

    table_cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=11,
        textColor=text_color,
    )

    table_cell_bold = ParagraphStyle(
        'TableCellBold',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=text_color,
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.white,
    )

    meta_label_style = ParagraphStyle(
        'MetaLabel',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=12,
        textColor=primary_color,
    )

    meta_val_style = ParagraphStyle(
        'MetaVal',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=12,
        textColor=text_color,
    )

    story = []

    # Title block
    story.append(Spacer(1, 10))
    story.append(Paragraph("Functional Requirements Specification (FRS)", title_style))
    story.append(Paragraph("Project: Proof of Delivery (POD) Application — Version 1.2", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=accent_color, spaceAfter=14))

    # Metadata table
    meta_data = [
        [Paragraph("Application Name:", meta_label_style), Paragraph("Proof of Delivery (POD) App", meta_val_style),
         Paragraph("Version:", meta_label_style), Paragraph("1.2", meta_val_style)],
        [Paragraph("Developed By:", meta_label_style), Paragraph("Lokesh Pawalia & Sarthak Srivastava", meta_val_style),
         Paragraph("Date:", meta_label_style), Paragraph("August 31, 2026", meta_val_style)],
        [Paragraph("Frontend Tech:", meta_label_style), Paragraph("Flutter SDK (Dart / Android)", meta_val_style),
         Paragraph("Backend Tech:", meta_label_style), Paragraph("FastAPI (Python 3.11) + MongoDB", meta_val_style)],
        [Paragraph("Cloud Hosting:", meta_label_style), Paragraph("Railway Production Cloud", meta_val_style),
         Paragraph("Media CDN:", meta_label_style), Paragraph("Cloudinary Digital Asset Management", meta_val_style)],
    ]
    meta_table = Table(meta_data, colWidths=[100, 160, 90, 154])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 14))

    # Section 1: Executive Summary
    story.append(Paragraph("1. Executive Summary & Objectives", h1_style))
    story.append(Paragraph(
        "The <b>Proof of Delivery (POD) App (Version 1.2)</b> is an enterprise-grade mobile and cloud verification ecosystem designed to track, manage, and cryptographically audit the physical distribution of government and organizational subsidies to beneficiaries (farmers).",
        body_style
    ))
    story.append(Paragraph(
        "The system completely prevents distribution fraud, identity impersonation, and phantom beneficiary leakage by enforcing an unalterable multi-stage handover protocol: biometric face verification, real-time OTP matching, multi-angle photographic and videographic proofs, GPS timestamping, and immediate digital invoice reconciliation.",
        body_style
    ))

    # Section 2: User Hierarchy & System Roles
    story.append(Paragraph("2. User Hierarchy & Roles", h1_style))
    story.append(Paragraph("<b>• Delivery Partner (Field Agent):</b> Operative responsible for physical transit, client credential validation, biometric facial capture, and digital proof submission.", bullet_style))
    story.append(Paragraph("<b>• Beneficiary (Farmer):</b> Authorized recipient of subsidized equipment or goods, verified through registered credentials and OTP verification.", bullet_style))
    story.append(Paragraph("<b>• Central Administrator:</b> Administrative stakeholder monitoring live distribution audit logs, partner allocation, and Cloudinary media inspection.", bullet_style))

    # Section 3: Functional Requirements by Module
    story.append(Spacer(1, 6))
    story.append(Paragraph("3. Functional Requirements by Module", h1_style))

    # Module 1
    story.append(Paragraph("Module 1: Partner Authentication & Identity Onboarding", h2_style))
    story.append(Paragraph("<b>FR-1.1 Mobile Number & OTP Verification:</b> The system authenticates field operatives through a 10-digit mobile number and numeric One-Time Password verification (<code>POST /auth/send-otp</code> and <code>POST /auth/verify-otp</code>).", bullet_style))
    story.append(Paragraph("<b>FR-1.2 Mandatory 8-Step Profile Completion Sequence:</b> Newly registered partners must complete an 8-field structured profile enforcing strict real-time data integrity before accessing delivery orders:", bullet_style))
    
    # 8 steps
    steps = [
        ("1. Full Name", "Restricted strictly to alphabetic characters and spaces via software keyboard filter (<code>FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\\s]'))</code>). Numbers and special characters are physically prevented. Length: 2 to 50 characters."),
        ("2. Email Address", "Enforces RFC-compliant email formatting (<code>^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$</code>). Whitespace characters are blocked."),
        ("3. PIN Code", "Exactly 6 numeric digits. Triggers an automated asynchronous background lookup to the Indian Postal API (<code>https://api.postalpincode.in/pincode/{PINCODE}</code>) upon entry of the 6th digit."),
        ("4. City & State", "Automatically populated from the resolved PIN code data. Configured as read-only to eliminate manual entry mistakes, with an edit-toggle for edge-case overrides."),
        ("5. Address", "Physical street/residential address with a mandatory minimum 5-character threshold."),
        ("6. Vehicle Type", "Selection dropdown: Two Wheeler, Three Wheeler, Four Wheeler, or Other (defaults to Two Wheeler)."),
        ("7. Vehicle Number", "Automatic uppercase transformation (<code>UpperCaseTextFormatter</code>). Validated against Indian Motor Vehicle standards (e.g. DL 01 AB 1234, UP 16 CP 6755, or Bharat Series)."),
        ("8. Aadhaar Number", "Exactly 12 numeric digits. Follows UIDAI specifications prohibiting prefixes starting with 0 or 1 (<code>^[2-9][0-9]{11}$</code>)."),
    ]
    for step_title, step_desc in steps:
        story.append(Paragraph(f"&nbsp;&nbsp;&nbsp;&nbsp;<b>{step_title}:</b> {step_desc}", bullet_style))
    story.append(Paragraph("<b>FR-1.3 Profile Photo Cloud Sync:</b> Delivery partners must upload a valid facial profile photo, transmitted as <code>multipart/form-data</code> to <code>PATCH /auth/profile</code> and hosted securely on Cloudinary.", bullet_style))

    # Module 2
    story.append(Spacer(1, 6))
    story.append(Paragraph("Module 2: Beneficiary & Delivery Management", h2_style))
    story.append(Paragraph("<b>FR-2.1 Scoped Beneficiary Allocation:</b> Operatives only view records assigned to their unique partner identifier (<code>delivery_partner_id</code>), categorized dynamically as All, Pending, or Delivered.", bullet_style))
    story.append(Paragraph("<b>FR-2.2 On-Demand Beneficiary Creation:</b> Field operatives can onboard new farmers with detailed metadata (Name, Village, District, PIN, GPS coordinates, itemized goods, and reference photograph).", bullet_style))
    story.append(Paragraph("<b>FR-2.3 Direct Calling & Route Navigation:</b> Beneficiary cards integrate direct system telephony (<code>tel:</code>) and geospatial navigation (<code>geo:</code>) to facilitate field operations.", bullet_style))

    # Module 3
    story.append(Spacer(1, 6))
    story.append(Paragraph("Module 3: Multi-Stage Proof of Delivery (POD) Protocol", h2_style))
    story.append(Paragraph("To eliminate proxy collections, delivery completion requires passing five consecutive verification gates:", body_style))
    
    gates = [
        ("Gate 1: Beneficiary OTP Handover", "Recipient provides the unique 4-digit SMS handover code generated for their subsidy parcel."),
        ("Gate 2: On-Device Facial Biometrics", "Google ML Kit executes local landmark detection and facial matching against the beneficiary's registered reference image without sending unencrypted biometric data over the wire."),
        ("Gate 3: Multi-Angle Photographic Proof", "Operative captures 1 to 5 high-resolution photos documenting the recipient receiving the subsidy goods in their physical context."),
        ("Gate 4: Video Handover Audit", "Live video recording (up to 30 seconds) documenting physical item transfer and audible confirmation."),
        ("Gate 5: Geotagging & Geofencing Stamp", "Device GPS coordinates are stamped with exact date/time and embedded into the immutable audit record."),
    ]
    for gate_title, gate_desc in gates:
        story.append(Paragraph(f"<b>• {gate_title}:</b> {gate_desc}", bullet_style))

    # Module 4
    story.append(Spacer(1, 6))
    story.append(Paragraph("Module 4: Automated Invoicing & PDF Inspection", h2_style))
    story.append(Paragraph("<b>FR-4.1 Automated Digital Invoice:</b> Immediately upon delivery clearance, the system compiles a tamper-evident PDF invoice containing tracking IDs, items disbursed, partner details, recipient signature/photo, and GPS timestamps.", bullet_style))
    story.append(Paragraph("<b>FR-4.2 Cloud Upload & In-App Native Inspection:</b> Invoices are synchronized to Cloudinary (<code>POD-App/invoices</code>) and displayed natively within the application via Syncfusion PDF Viewer with pan, zoom, and local download capabilities.", bullet_style))

    # Section 4: API Specification Table
    story.append(Spacer(1, 8))
    story.append(Paragraph("4. Backend API Specification Matrix", h1_style))
    
    api_data = [
        [Paragraph("Method", table_header_style), Paragraph("Endpoint", table_header_style), Paragraph("Description", table_header_style), Paragraph("Payload", table_header_style), Paragraph("Auth", table_header_style)],
        [Paragraph("POST", table_cell_bold), Paragraph("/auth/check-phone", table_cell_style), Paragraph("Check if phone exists", table_cell_style), Paragraph("JSON", table_cell_style), Paragraph("Public", table_cell_style)],
        [Paragraph("POST", table_cell_bold), Paragraph("/auth/send-otp", table_cell_style), Paragraph("Dispatch SMS OTP", table_cell_style), Paragraph("JSON", table_cell_style), Paragraph("Public", table_cell_style)],
        [Paragraph("POST", table_cell_bold), Paragraph("/auth/verify-otp", table_cell_style), Paragraph("Verify partner OTP", table_cell_style), Paragraph("JSON", table_cell_style), Paragraph("Public", table_cell_style)],
        [Paragraph("POST", table_cell_bold), Paragraph("/auth/login-or-register", table_cell_style), Paragraph("Generate JWT session", table_cell_style), Paragraph("JSON", table_cell_style), Paragraph("Public", table_cell_style)],
        [Paragraph("PATCH", table_cell_bold), Paragraph("/auth/profile", table_cell_style), Paragraph("Update profile & image", table_cell_style), Paragraph("Multipart / JSON", table_cell_style), Paragraph("Bearer", table_cell_style)],
        [Paragraph("GET", table_cell_bold), Paragraph("/auth/me", table_cell_style), Paragraph("Current partner record", table_cell_style), Paragraph("None", table_cell_style), Paragraph("Bearer", table_cell_style)],
        [Paragraph("GET", table_cell_bold), Paragraph("/farmers", table_cell_style), Paragraph("List assigned deliveries", table_cell_style), Paragraph("Query Params", table_cell_style), Paragraph("Bearer", table_cell_style)],
        [Paragraph("POST", table_cell_bold), Paragraph("/farmers", table_cell_style), Paragraph("Register new farmer", table_cell_style), Paragraph("Multipart (Form+Img)", table_cell_style), Paragraph("Bearer", table_cell_style)],
        [Paragraph("POST", table_cell_bold), Paragraph("/farmers/{id}/upload_proof", table_cell_style), Paragraph("Submit POD proofs & invoice", table_cell_style), Paragraph("Multipart Data", table_cell_style), Paragraph("Bearer", table_cell_style)],
    ]
    api_table = Table(api_data, colWidths=[48, 140, 144, 112, 60])
    api_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(api_table)

    # Section 5: Non-Functional Requirements & Sign-off
    story.append(Spacer(1, 10))
    story.append(Paragraph("5. Non-Functional Requirements (NFR)", h1_style))
    story.append(Paragraph("<b>• Performance:</b> Sub-second REST latency under standard 4G/LTE; streaming multipart upload resilience with 120s timeout for remote field conditions.", bullet_style))
    story.append(Paragraph("<b>• Security & Compliance:</b> Passlib Bcrypt salt-hashing, standard HS256 JWT bearer authentication, and Aadhaar UIDAI non-prefix validation.", bullet_style))
    story.append(Paragraph("<b>• High Availability:</b> Railway high-concurrency Uvicorn engine backed by MongoDB Atlas cluster failover and Cloudinary redundant media storage.", bullet_style))

    # Approvals Table
    story.append(Spacer(1, 10))
    story.append(Paragraph("6. Document Approvals & Sign-Off", h1_style))
    appr_data = [
        [Paragraph("Role", table_header_style), Paragraph("Name", table_header_style), Paragraph("Status", table_header_style), Paragraph("Sign-Off Date", table_header_style)],
        [Paragraph("Lead Developer", table_cell_bold), Paragraph("Lokesh Pawalia", table_cell_style), Paragraph("Approved", table_cell_bold), Paragraph("August 31, 2026", table_cell_style)],
        [Paragraph("Lead Developer", table_cell_bold), Paragraph("Sarthak Srivastava", table_cell_style), Paragraph("Approved", table_cell_bold), Paragraph("August 31, 2026", table_cell_style)],
        [Paragraph("Release Version", table_cell_bold), Paragraph("POD App Version 1.2", table_cell_style), Paragraph("Production Ready", table_cell_bold), Paragraph("August 31, 2026", table_cell_style)],
    ]
    appr_table = Table(appr_data, colWidths=[120, 150, 114, 120])
    appr_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(appr_table)

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF built successfully: {filename}")

if __name__ == "__main__":
    out_file = sys.argv[1] if len(sys.argv) > 1 else "FRS_POD_App_v1.2.pdf"
    build_pdf(out_file)
