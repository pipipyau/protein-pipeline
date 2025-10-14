import os

if __name__ == "__main__":
    try:
        os.makedirs(os.path.join('data', "input", "ligand"), exist_ok=True)
        os.makedirs(os.path.join('data', "input", "receptor"), exist_ok=True)
        os.makedirs(os.path.join('data', "output", "alphafold3", "ligand"), exist_ok=True)
        os.makedirs(os.path.join('data', "output", "alphafold3", "receptor"), exist_ok=True)
        os.makedirs(os.path.join('data', "output", "megadock"), exist_ok=True)
        os.makedirs(os.path.join('data', "output", "prodigy"), exist_ok=True)
        print("Done.")

    except Exception as e:
        print(f"An error occurred: {e}")
