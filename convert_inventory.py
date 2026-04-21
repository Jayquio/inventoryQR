import zipfile
import xml.etree.ElementTree as ET
import csv
import os

def convert_xlsx_to_csv(xlsx_path):
    try:
        with zipfile.ZipFile(xlsx_path, 'r') as zip_ref:
            # Extract shared strings
            shared_strings = []
            if 'xl/sharedStrings.xml' in zip_ref.namelist():
                with zip_ref.open('xl/sharedStrings.xml') as f:
                    tree = ET.parse(f)
                    for t in tree.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t'):
                        shared_strings.append(t.text if t.text else '')

            # Iterate through all sheets
            for sheet_name in [n for n in zip_ref.namelist() if n.startswith('xl/worksheets/sheet') and n.endswith('.xml')]:
                sheet_num = sheet_name.split('sheet')[-1].split('.xml')[0]
                csv_path = f'LABORATORY_INVENTORY_sheet{sheet_num}.csv'
                
                sheet_data = {}
                with zip_ref.open(sheet_name) as f:
                    tree = ET.parse(f)
                    root = tree.getroot()
                    ns = {'ns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
                    for row in root.findall('.//ns:row', ns):
                        r_idx = row.get('r')
                        if not r_idx: continue
                        row_idx = int(r_idx)
                        sheet_data[row_idx] = {}
                        for cell in row.findall('ns:c', ns):
                            r = cell.get('r') # e.g., A1
                            t = cell.get('t') # type
                            v = cell.find('ns:v', ns)
                            if v is not None:
                                val = v.text
                                if t == 's': # shared string
                                    val = shared_strings[int(val)]
                                # Basic column index extraction
                                col_str = ''.join([c for c in r if c.isalpha()])
                                col_idx = 0
                                for char in col_str:
                                    col_idx = col_idx * 26 + (ord(char.upper()) - ord('A') + 1)
                                sheet_data[row_idx][col_idx] = val

                if not sheet_data:
                    print(f"Skipping empty sheet {sheet_name}")
                    continue

                rows = sheet_data.keys()
                if not rows:
                    continue
                max_row = max(rows)
                
                all_cols = []
                for r_data in sheet_data.values():
                    all_cols.extend(r_data.keys())
                if not all_cols:
                    continue
                max_col = max(all_cols)

                with open(csv_path, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.writer(f)
                    for r in range(1, max_row + 1):
                        row_vals = []
                        row_dict = sheet_data.get(r, {})
                        for c in range(1, max_col + 1):
                            row_vals.append(row_dict.get(c, ''))
                        writer.writerow(row_vals)
                print(f"Successfully converted {sheet_name} to {csv_path}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    xlsx_file = r'c:\3rd Year\SEM 2\SIA 2\QR CODE INVENTORY MANAGEMENT SYSTEM\inventoryQR\LABORATORY - INVENTORY.xlsx'
    convert_xlsx_to_csv(xlsx_file)
