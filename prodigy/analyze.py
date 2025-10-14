import pandas as pd
import re

DATA_FILE_PATH="output/prodigy_results.txt"
EXPORT_CSV_PATH="output/affinity.csv"


patterns = {
    "pdb_name": r"Processing structure ([^\s]+)",
    "inter_contacts": r"intermolecular contacts: (\d+)",
    "charged_charged": r"charged-charged contacts: ([\d.]+)",
    "charged_polar": r"charged-polar contacts: ([\d.]+)",
    "charged_apolar": r"charged-apolar contacts: ([\d.]+)",
    "polar_polar": r"polar-polar contacts: ([\d.]+)",
    "apolar_polar": r"apolar-polar contacts: ([\d.]+)",
    "apolar_apolar": r"apolar-apolar contacts: ([\d.]+)",
    "apolar_nis": r"apolar NIS residues: ([\d.]+)",
    "charged_nis": r"charged NIS residues: ([\d.]+)",
    "binding_affinity": r"Predicted binding affinity.*?:\s+(-?[\d.]+)",
    "dissociation_constant": r"dissociation constant.*?:\s+([\deE\.-]+)"
}

metric_patterns = {
    "pdb_name": "File",
    "inter_contacts": "No. of intermolecular contacts",
    "charged_charged": "No. of charged-charged contacts",
    "charged_polar": "No. of charged-polar contacts",
    "charged_apolar": "No. of charged-apolar contacts",
    "polar_polar": "No. of polar-polar contacts",
    "apolar_polar": "No. of apolar-polar contacts",
    "apolar_apolar": "No. of apolar-apolar contacts",
    "apolar_nis": "Percentage of apolar NIS residues",
    "charged_nis": "Percentage of charged NIS residues",
    "binding_affinity": "Predicted binding affinity (kcal.mol-1)",
    "dissociation_constant": "Predicted dissociation constant (M) at 25.0˚C"
}

with open(DATA_FILE_PATH, "r") as f:
    content = f.read()

blocks = content.strip().split("##########################################")
data = []

for block in blocks[1:]:
    # block = "[+] [+] Processing structure " + block
    entry = {}
    for key, pattern in patterns.items():
        match = re.search(pattern, block)
        entry[key] = match.group(1) if match else None
    data.append(entry)
df = pd.DataFrame(data)
for col in df.columns:
    if col != "pdb_name":
        df[col] = pd.to_numeric(df[col])
df.to_csv(EXPORT_CSV_PATH)
print(f"Results saved in {EXPORT_CSV_PATH}")
