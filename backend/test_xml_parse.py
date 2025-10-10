import xml.etree.ElementTree as ET

tree = ET.parse("data/iliad_grc.xml")
root = tree.getroot()

ns = {"tei": "http://www.tei-c.org/ns/1.0"}
books = root.findall('.//tei:div[@subtype="Book"]', ns)
print(f"Found {len(books)} books")

if books:
    lines = books[0].findall(".//tei:l", ns)
    print(f"Found {len(lines)} lines in book 1")
    print("First 5 lines:")
    for line in lines[:5]:
        text = "".join(line.itertext()).strip()
        print(f"  {line.get('n')}: {len(text)} chars")
