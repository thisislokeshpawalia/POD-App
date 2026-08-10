import os
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch

def generate_invoice(output_path: str, farmer_name: str, farmer_address: str, farmer_district: str, video_link: str) -> None:
    """
    Generates a PDF invoice with the hardcoded From address, the dynamic To address,
    and a clickable link to the uploaded video.
    """
    c = canvas.Canvas(output_path, pagesize=A4)
    width, height = A4

    # Header
    c.setFont("Helvetica-Bold", 20)
    c.drawString(1 * inch, height - 1 * inch, "Delivery Invoice")

    # From Address (Hardcoded as requested)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(1 * inch, height - 1.5 * inch, "From:")
    c.setFont("Helvetica", 12)
    c.drawString(1 * inch, height - 1.7 * inch, "My Animal")
    c.drawString(1 * inch, height - 1.9 * inch, "Sector 132, Noida (default)")

    # To Address (Auto-detected from farmer)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(4 * inch, height - 1.5 * inch, "To:")
    c.setFont("Helvetica", 12)
    c.drawString(4 * inch, height - 1.7 * inch, farmer_name)
    
    # Split address if it's too long (basic handling)
    address_line = f"{farmer_address}, {farmer_district}"
    if len(address_line) > 40:
        c.drawString(4 * inch, height - 1.9 * inch, address_line[:40])
        c.drawString(4 * inch, height - 2.1 * inch, address_line[40:])
    else:
        c.drawString(4 * inch, height - 1.9 * inch, address_line)

    # Line Separator
    c.line(1 * inch, height - 2.5 * inch, 7 * inch, height - 2.5 * inch)
    
    # Body Title
    c.setFont("Helvetica-Bold", 14)
    c.drawString(1 * inch, height - 3 * inch, "Delivery Specifics")

    c.setFont("Helvetica", 12)
    c.drawString(1 * inch, height - 3.4 * inch, "The items for this delivery have been fulfilled successfully.")

    # Video Link
    c.setFont("Helvetica-Bold", 12)
    c.drawString(1 * inch, height - 4 * inch, "Proof of Delivery Video:")
    
    c.setFont("Helvetica", 12)
    c.setFillColorRGB(0, 0, 1)  # Blue color for link
    # Adding a hyperlink annotation so it's clickable
    c.linkURL(video_link, (1 * inch, height - 4.4 * inch, 7 * inch, height - 4.1 * inch), relative=0)
    c.drawString(1 * inch, height - 4.3 * inch, "Click here to view the Delivery Video")

    c.setFillColorRGB(0, 0, 0) # Reset to black
    c.setFont("Helvetica", 10)
    c.drawString(1 * inch, height - 4.6 * inch, f"(Direct link: {video_link})")

    # Save PDF
    c.save()
