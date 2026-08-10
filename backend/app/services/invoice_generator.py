import os
import datetime
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch, cm
from reportlab.lib.colors import HexColor

def generate_invoice(output_path: str, farmer_name: str, farmer_address: str, farmer_district: str, video_link: str, items: list = None) -> None:
    """
    Generates a beautifully formatted PDF invoice matching the requested design,
    with dynamic farmer details, items, and a clickable video proof link.
    """
    c = canvas.Canvas(output_path, pagesize=A4)
    width, height = A4
    
    # Colors matching the image
    dark_blue = HexColor("#0A4A6F")
    light_blue = HexColor("#EBF3FA")
    black = HexColor("#000000")
    white = HexColor("#FFFFFF")
    
    # 1. Top Header Banner
    c.setFillColor(dark_blue)
    c.rect(0, height - 2*inch, width, 2*inch, fill=1, stroke=0)
    
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 40)
    c.drawString(0.8*inch, height - 1.2*inch, "INVOICE")
    
    c.setFont("Helvetica-Bold", 12)
    c.drawRightString(width - 0.8*inch, height - 0.7*inch, "My Animal")
    c.setFont("Helvetica", 10)
    c.drawRightString(width - 0.8*inch, height - 0.95*inch, "Sector 132, Noida (default)")
    c.drawRightString(width - 0.8*inch, height - 1.2*inch, "Uttar Pradesh, 201304")
    c.drawRightString(width - 0.8*inch, height - 1.45*inch, "+91 1800-123-456")
    c.drawRightString(width - 0.8*inch, height - 1.7*inch, "support@myanimal.com")
    
    # 2. Invoice Details (Left)
    c.setFillColor(black)
    c.setFont("Helvetica-Bold", 10)
    base_y = height - 2.8*inch
    
    c.drawString(0.8*inch, base_y, "Invoice No.")
    c.setLineWidth(0.5)
    c.setStrokeColor(HexColor("#CCCCCC"))
    c.line(1.7*inch, base_y - 2, 3.5*inch, base_y - 2)
    # Generate random invoice no
    import random
    inv_no = str(random.randint(10000, 99999))
    c.setFont("Helvetica", 10)
    c.drawString(1.8*inch, base_y, inv_no)
    
    c.setFont("Helvetica-Bold", 10)
    c.drawString(0.8*inch, base_y - 0.3*inch, "Date of Issue")
    c.line(1.7*inch, base_y - 0.3*inch - 2, 3.5*inch, base_y - 0.3*inch - 2)
    c.setFont("Helvetica", 10)
    c.drawString(1.8*inch, base_y - 0.3*inch, datetime.date.today().strftime("%B %d, %Y"))
    
    # 3. Bill To (Right)
    c.setFont("Helvetica-Bold", 12)
    c.drawRightString(width - 0.8*inch, base_y + 0.3*inch, "Bill To")
    
    c.setFont("Helvetica", 10)
    c.drawRightString(width - 0.8*inch, base_y, farmer_name)
    c.drawRightString(width - 0.8*inch, base_y - 0.2*inch, f"{farmer_address}")
    c.drawRightString(width - 0.8*inch, base_y - 0.4*inch, f"{farmer_district}")
    
    # 4. Table Header
    table_y = base_y - 1.2*inch
    
    c.setStrokeColor(black)
    c.setLineWidth(1)
    c.line(0.8*inch, table_y, width - 0.8*inch, table_y)
    
    c.setFont("Helvetica-Bold", 11)
    c.drawString(0.9*inch, table_y - 0.25*inch, "Item")
    c.drawString(3.0*inch, table_y - 0.25*inch, "Subsidy Item")
    c.drawString(5.5*inch, table_y - 0.25*inch, "Quantity")
    
    c.line(0.8*inch, table_y - 0.4*inch, width - 0.8*inch, table_y - 0.4*inch)
    
    # 5. Table Rows
    if not items:
        items = [{"name": "Standard Subsidy Package", "quantity": 1, "unit": "unit"}]
        
    current_y = table_y - 0.4*inch
    row_height = 0.6*inch
    
    c.setStrokeColor(HexColor("#E0E0E0"))
    c.setLineWidth(0.5)
    
    for i, item in enumerate(items):
        if i % 2 == 0:
            c.setFillColor(light_blue)
            c.rect(0.8*inch, current_y - row_height, width - 1.6*inch, row_height, fill=1, stroke=0)
            
        c.setFillColor(black)
        c.setFont("Helvetica", 10)
        c.drawString(0.9*inch, current_y - 0.35*inch, str(i + 1))
        
        name = item.get("name", "Unknown Item")
        quantity = item.get("quantity", 0)
        unit = item.get("unit", "")
        
        c.drawString(3.0*inch, current_y - 0.35*inch, name)
        c.drawString(5.5*inch, current_y - 0.35*inch, f"{quantity} {unit}")
        
        # Vertical dividers
        c.line(0.8*inch, current_y, 0.8*inch, current_y - row_height)
        c.line(2.8*inch, current_y, 2.8*inch, current_y - row_height)
        c.line(5.3*inch, current_y, 5.3*inch, current_y - row_height)
        c.line(width - 0.8*inch, current_y, width - 0.8*inch, current_y - row_height)
        
        current_y -= row_height
        
    # Draw bottom border of table
    c.setStrokeColor(black)
    c.setLineWidth(1)
    c.line(0.8*inch, current_y, width - 0.8*inch, current_y)
    
    # 6. Video Link Section
    c.setFont("Helvetica-Bold", 12)
    c.drawString(0.8*inch, current_y - 0.6*inch, "Proof of Delivery Video:")
    
    c.setFont("Helvetica", 10)
    c.setFillColor(HexColor("#0000FF")) # Clickable blue
    c.linkURL(video_link, (0.8*inch, current_y - 0.95*inch, width - 0.8*inch, current_y - 0.75*inch), relative=0)
    c.drawString(0.8*inch, current_y - 0.9*inch, "Tap here to view the Delivery Proof Video")
    
    c.setFillColor(black)
    c.setFont("Helvetica", 8)
    c.drawString(0.8*inch, current_y - 1.1*inch, f"URL: {video_link}")
    
    # 7. Bottom Footer Banner
    c.setFillColor(dark_blue)
    c.rect(0, 0, width, 0.6*inch, fill=1, stroke=0)
    
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 11)
    c.drawCentredString(width / 2.0, 0.25*inch, "Thank you for your business!")
    
    # Save PDF
    c.save()
