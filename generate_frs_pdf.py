import os
import sys
import shutil
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
            self.drawString(54, 752, "Subsidy Delivery Partner (Pod Delivery) v1.2 — Functional Requirements Specification")
            self.setStrokeColor(colors.HexColor("#E2E8F0"))
            self.setLineWidth(0.5)
            self.line(54, 746, 558, 746)
        
        # Footer
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 34, page_str)
        self.drawString(54, 34, "Developed By Lokesh Pawalia & Sarthak Srivastava | Official Release Document")
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(54, 44, 558, 44)
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

    primary_color = colors.HexColor("#1E3A8A")  # Deep Navy Blue
    accent_color = colors.HexColor("#2E7D32")   # Forest Green
    text_color = colors.HexColor("#1E293B")     # Dark Slate

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=primary_color,
        spaceAfter=4,
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=accent_color,
        spaceAfter=12,
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=primary_color,
        spaceBefore=12,
        spaceAfter=5,
        keepWithNext=True,
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=accent_color,
        spaceBefore=8,
        spaceAfter=3,
        keepWithNext=True,
    )

    body_style = ParagraphStyle(
        'DocBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12.5,
        textColor=text_color,
        spaceAfter=5,
    )

    bullet_style = ParagraphStyle(
        'DocBullet',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=text_color,
        leftIndent=12,
        spaceAfter=3,
    )

    table_cell = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=10,
        textColor=text_color,
    )

    table_cell_bold = ParagraphStyle(
        'TableCellBold',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=10,
        textColor=text_color,
    )

    table_header = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10.5,
        textColor=colors.white,
    )

    story = []

    # Title
    story.append(Paragraph("Functional Requirements Specification (FRS)", title_style))
    story.append(Paragraph("Subsidy Delivery Partner (Pod Delivery App) — Version 1.2", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=accent_color, spaceAfter=10))

    # 1. Document Control
    story.append(Paragraph("1. Document Control", h1_style))
    doc_control_data = [
        [Paragraph("Application Name", table_cell_bold), Paragraph("Subsidy Delivery Partner (Pod Delivery)", table_cell)],
        [Paragraph("Document Version", table_cell_bold), Paragraph("1.2", table_cell)],
        [Paragraph("Prepared / Developed By", table_cell_bold), Paragraph("Lokesh Pawalia and Sarthak Srivastava", table_cell)],
        [Paragraph("Prepared Date", table_cell_bold), Paragraph("August 31, 2026", table_cell)],
        [Paragraph("Reviewed & Approved By", table_cell_bold), Paragraph("Lokesh Pawalia & Sarthak Srivastava", table_cell)],
        [Paragraph("Document Status", table_cell_bold), Paragraph("Approved & Production Ready", table_cell)],
        [Paragraph("Live Cloud Backend", table_cell_bold), Paragraph("Railway Production: https://pod-app-production-818a.up.railway.app", table_cell)],
        [Paragraph("Database & Storage", table_cell_bold), Paragraph("MongoDB Atlas (pody_db) | Cloudinary Media CDN", table_cell)],
    ]
    t_ctrl = Table(doc_control_data, colWidths=[150, 354])
    t_ctrl.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_ctrl)
    story.append(Spacer(1, 8))

    # 2. Purpose & Scope
    story.append(Paragraph("2. Purpose & System Scope", h1_style))
    story.append(Paragraph(
        "<b>Purpose:</b> This specification defines the functional requirements for the Subsidy Delivery Partner (Pod Delivery) mobile platform and its cloud backend. Version 1.2 enforces tamper-proof delivery tracking, preventing subsidy diversion and identity impersonation through multi-factor validation.",
        body_style
    ))
    story.append(Paragraph("<b>In Scope:</b> Partner authentication, mandatory 8-step profile onboarding with automatic postal PIN lookup, 600m geofence validation, on-device Google ML Kit facial verification, multi-angle item proof capture, video audit recording, automated PDF invoicing, and native in-app inspection.", body_style))
    story.append(Paragraph("<b>Out of Scope:</b> Direct public farmer login portal and commercial payment gateway processing (focus is strictly on physical subsidy handover verification).", body_style))

    # 3. User Roles
    story.append(Paragraph("3. User Roles & Hierarchy", h1_style))
    roles_data = [
        [Paragraph("Role ID", table_header), Paragraph("User Role", table_header), Paragraph("Description", table_header), Paragraph("System Permissions", table_header)],
        [Paragraph("UR-01", table_cell_bold), Paragraph("Delivery Partner", table_cell), Paragraph("Primary field operative delivering subsidy packages.", table_cell), Paragraph("Login, complete profile, view assigned deliveries, execute POD verification gates.", table_cell)],
        [Paragraph("UR-02", table_cell_bold), Paragraph("Beneficiary (Farmer)", table_cell), Paragraph("Registered recipient entitled to subsidy items.", table_cell), Paragraph("Provides delivery OTP, physical face match, receives subsidized items.", table_cell)],
        [Paragraph("UR-03", table_cell_bold), Paragraph("System Administrator", table_cell), Paragraph("Central supervisor monitoring operations and audit logs.", table_cell), Paragraph("Inspect MongoDB (pody_db), review Cloudinary media proofs, view delivery logs.", table_cell)],
    ]
    t_roles = Table(roles_data, colWidths=[50, 100, 180, 174])
    t_roles.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(t_roles)
    story.append(Spacer(1, 8))

    # 4. Functional Requirements Matrix
    story.append(Paragraph("4. Functional Requirements Matrix", h1_style))

    # Profile Module (8-step form)
    story.append(Paragraph("4.1 Partner Authentication & Strict 8-Step Profile Onboarding", h2_style))
    prof_data = [
        [Paragraph("Req ID", table_header), Paragraph("Field / Step", table_header), Paragraph("Validation & Software Behavior Rule", table_header), Paragraph("Priority", table_header)],
        [Paragraph("FR-PROF-01", table_cell_bold), Paragraph("1. Full Name", table_cell_bold), Paragraph("Alphabetical and space characters only via FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\\s]')). Digits & special characters are blocked. Length: 2-50 chars.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("FR-PROF-02", table_cell_bold), Paragraph("2. Email Address", table_cell_bold), Paragraph("Validates RFC email regex ^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$. Whitespace characters are blocked.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("FR-PROF-03", table_cell_bold), Paragraph("3. PIN Code", table_cell_bold), Paragraph("6 numeric digits. Entering the 6th digit auto-triggers an asynchronous lookup to the Indian Postal API (https://api.postalpincode.in/pincode/{PIN}).", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("FR-PROF-04", table_cell_bold), Paragraph("4. City & State", table_cell_bold), Paragraph("Automatically populated from resolved PIN code. Fields are read-only with a manual edit/unlock toggle for offline overrides.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("FR-PROF-05", table_cell_bold), Paragraph("5. Address", table_cell_bold), Paragraph("Detailed street / locality address. Mandatory minimum length of 5 characters.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("FR-PROF-06", table_cell_bold), Paragraph("6. Vehicle Type", table_cell_bold), Paragraph("Structured selection dropdown: Two Wheeler, Three Wheeler, Four Wheeler, or Other.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("FR-PROF-07", table_cell_bold), Paragraph("7. Vehicle Number", table_cell_bold), Paragraph("Auto-capitalized (UpperCaseTextFormatter). Enforces Indian registration format (e.g. DL 01 AB 1234 or BH Series).", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("FR-PROF-08", table_cell_bold), Paragraph("8. Aadhaar Number", table_cell_bold), Paragraph("Exactly 12 numeric digits adhering to UIDAI specification (cannot start with 0 or 1: ^[2-9][0-9]{11}$).", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("FR-PROF-09", table_cell_bold), Paragraph("Profile Photo", table_cell_bold), Paragraph("Mandatory facial photo capture; streamed via multipart/form-data to PATCH /auth/profile and Cloudinary.", table_cell), Paragraph("P0", table_cell_bold)],
    ]
    t_prof = Table(prof_data, colWidths=[64, 96, 304, 40])
    t_prof.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(t_prof)
    story.append(Spacer(1, 6))

    # Order Completion Module
    story.append(Paragraph("4.2 Order Completion & 5 Verification Gates", h2_style))
    ord_data = [
        [Paragraph("Gate", table_header), Paragraph("Verification Stage", table_header), Paragraph("Technical Mechanism & Enforcement", table_header), Paragraph("Priority", table_header)],
        [Paragraph("Gate 1", table_cell_bold), Paragraph("600m Geofencing", table_cell), Paragraph("Haversine distance calculation using GPS coordinates. Blocks submission if operative is >600m away.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("Gate 2", table_cell_bold), Paragraph("Beneficiary OTP", table_cell), Paragraph("Recipient enters unique 4-digit SMS delivery OTP. Handover cannot proceed without valid match.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("Gate 3", table_cell_bold), Paragraph("On-Device Face Match", table_cell), Paragraph("Google ML Kit detects facial landmarks from live camera and compares with registered farmer photo.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("Gate 4", table_cell_bold), Paragraph("Photo & Video Proof", table_cell), Paragraph("Operative captures 1 to 5 delivery item photos and an optional 30-second live handover video audit.", table_cell), Paragraph("P0", table_cell_bold)],
        [Paragraph("Gate 5", table_cell_bold), Paragraph("PDF Invoicing & Sync", table_cell), Paragraph("Generates PDF invoice, uploads to Cloudinary (POD-App/invoices), marks order delivered in MongoDB.", table_cell), Paragraph("P0", table_cell_bold)],
    ]
    t_ord = Table(ord_data, colWidths=[50, 110, 304, 40])
    t_ord.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(t_ord)
    story.append(Spacer(1, 8))

    # 5. API Specification Table
    story.append(Paragraph("5. Cloud Backend API Specification Matrix", h1_style))
    story.append(Paragraph("<b>Base URL:</b> https://pod-app-production-818a.up.railway.app | <b>Framework:</b> FastAPI + MongoDB", body_style))
    api_data = [
        [Paragraph("Method", table_header), Paragraph("Endpoint", table_header), Paragraph("Purpose", table_header), Paragraph("Payload", table_header), Paragraph("Auth", table_header)],
        [Paragraph("POST", table_cell_bold), Paragraph("/auth/check-phone", table_cell), Paragraph("Check if partner phone exists", table_cell), Paragraph("JSON", table_cell), Paragraph("Public", table_cell)],
        [Paragraph("POST", table_cell_bold), Paragraph("/auth/send-otp", table_cell), Paragraph("Dispatch SMS OTP to mobile", table_cell), Paragraph("JSON", table_cell), Paragraph("Public", table_cell)],
        [Paragraph("POST", table_cell_bold), Paragraph("/auth/verify-otp", table_cell), Paragraph("Verify 4-digit mobile OTP", table_cell), Paragraph("JSON", table_cell), Paragraph("Public", table_cell)],
        [Paragraph("POST", table_cell_bold), Paragraph("/auth/login-or-register", table_cell), Paragraph("Issue JWT bearer access token", table_cell), Paragraph("JSON", table_cell), Paragraph("Public", table_cell)],
        [Paragraph("PATCH", table_cell_bold), Paragraph("/auth/profile", table_cell), Paragraph("Update 8-step profile & photo", table_cell), Paragraph("Multipart", table_cell), Paragraph("Bearer", table_cell)],
        [Paragraph("GET", table_cell_bold), Paragraph("/auth/me", table_cell), Paragraph("Fetch authenticated partner info", table_cell), Paragraph("None", table_cell), Paragraph("Bearer", table_cell)],
        [Paragraph("GET", table_cell_bold), Paragraph("/farmers", table_cell), Paragraph("List assigned deliveries", table_cell), Paragraph("Query Params", table_cell), Paragraph("Bearer", table_cell)],
        [Paragraph("POST", table_cell_bold), Paragraph("/farmers", table_cell), Paragraph("Register new farmer beneficiary", table_cell), Paragraph("Multipart", table_cell), Paragraph("Bearer", table_cell)],
        [Paragraph("POST", table_cell_bold), Paragraph("/farmers/{id}/upload_proof", table_cell), Paragraph("Submit POD proofs, video & invoice", table_cell), Paragraph("Multipart", table_cell), Paragraph("Bearer", table_cell)],
    ]
    t_api = Table(api_data, colWidths=[48, 140, 156, 100, 60])
    t_api.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(t_api)
    story.append(Spacer(1, 8))

    # 6. Approvals & Sign-off
    story.append(Paragraph("6. Document Approvals & Sign-Off", h1_style))
    appr_data = [
        [Paragraph("Project Role", table_header), Paragraph("Name", table_header), Paragraph("Sign-Off Status", table_header), Paragraph("Approval Date", table_header)],
        [Paragraph("Lead Developer & Architect", table_cell_bold), Paragraph("Lokesh Pawalia", table_cell), Paragraph("Approved & Verified", table_cell_bold), Paragraph("August 31, 2026", table_cell)],
        [Paragraph("Lead Developer & Backend Specialist", table_cell_bold), Paragraph("Sarthak Srivastava", table_cell), Paragraph("Approved & Verified", table_cell_bold), Paragraph("August 31, 2026", table_cell)],
        [Paragraph("Release Engineering", table_cell_bold), Paragraph("Version 1.2 Production Release", table_cell), Paragraph("Production Ready", table_cell_bold), Paragraph("August 31, 2026", table_cell)],
    ]
    t_appr = Table(appr_data, colWidths=[140, 140, 124, 100])
    t_appr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    story.append(t_appr)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF built successfully: {filename}")
    
    # Also copy to Downloads
    dl_pdf = os.path.join(r"C:\Users\me\Downloads", filename)
    try:
        shutil.copyfile(filename, dl_pdf)
        print(f"Copied PDF to: {dl_pdf}")
    except Exception as e:
        print(f"Could not copy PDF to Downloads: {e}")

if __name__ == "__main__":
    out_file = sys.argv[1] if len(sys.argv) > 1 else "FRS_POD_App_v1.2.pdf"
    build_pdf(out_file)
