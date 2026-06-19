#!/usr/bin/env python3
import os
import sys
import json
import csv

REGISTRY_PATH = "/zeroclaw-data/datasets/datasets_registry.json"
DATASETS_DIR = "/zeroclaw-data/datasets"

def print_help():
    print("Usage: inspect_datasets.py <action> [dataset_id]")
    print("Actions:")
    print("  list             List all registered datasets")
    print("  profile <id>     Show metadata and profile statistics for a dataset")
    sys.exit(1)

def load_registry():
    if not os.path.exists(REGISTRY_PATH):
        print(f"Error: Registry file not found at {REGISTRY_PATH}")
        sys.exit(1)
    try:
        with open(REGISTRY_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading registry: {e}")
        sys.exit(1)

def handle_list():
    registry = load_registry()
    print("\n=== REGISTERED BIOLOGGER DATASETS ===")
    print(f"{'Dataset ID':<22} | {'Species':<20} | {'Location':<12} | {'Duration':<10} | {'Records':<10}")
    print("-" * 85)
    for entry in registry:
        ds_id = entry.get("id", "N/A")
        species = entry.get("species", "N/A")
        loc = entry.get("location", "N/A")
        duration = entry.get("duration", "N/A")
        records = entry.get("records", "N/A")
        print(f"{ds_id:<22} | {species:<20} | {loc:<12} | {duration:<10} | {records:<10}")
    print(f"\nTotal: {len(registry)} datasets registered.\n")

def handle_profile(dataset_id):
    registry = load_registry()
    target_entry = None
    for entry in registry:
        if entry.get("id") == dataset_id:
            target_entry = entry
            break
    
    if not target_entry:
        print(f"Error: Dataset ID '{dataset_id}' not found in registry.")
        sys.exit(1)

    print(f"\n=== DATASET REGISTRY METADATA: {dataset_id} ===")
    for key, value in target_entry.items():
        print(f"  {key:<15}: {value}")

    # Search for matching CSV file
    csv_filename = f"{dataset_id}-standard.csv"
    csv_path = os.path.join(DATASETS_DIR, csv_filename)

    if not os.path.exists(csv_path):
        # Try finding swordfish or whale shark subdirectories
        found = False
        for root, dirs, files in os.walk(DATASETS_DIR):
            for file in files:
                if file.endswith("-standard.csv") and dataset_id in file:
                    csv_path = os.path.join(root, file)
                    found = True
                    break
            if found:
                break
        
        if not found:
            print(f"\nWarning: CSV telemetry file '{csv_filename}' not found in {DATASETS_DIR}.")
            print("Profile metrics calculation skipped.")
            sys.exit(0)

    print(f"\n=== CSV PROFILE & STATISTICS ===")
    print(f"  File Path      : {csv_path}")
    print(f"  File Size (MB) : {os.path.getsize(csv_path) / (1024 * 1024):.2f}")

    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            headers = next(reader)
            print(f"  Columns        : {', '.join(headers)}")

            # Read a chunk for statistics
            depths = []
            temps = []
            sample_rows = []
            row_count = 0
            max_limit = 20000  # Scan up to 20,000 rows to keep response fast

            depth_idx = headers.index("depth_m") if "depth_m" in headers else -1
            temp_idx = headers.index("temperature_c") if "temperature_c" in headers else -1

            for row in reader:
                row_count += 1
                if row_count <= 5:
                    sample_rows.append(row)
                
                if row_count <= max_limit:
                    if depth_idx != -1 and len(row) > depth_idx:
                        try:
                            depths.append(float(row[depth_idx]))
                        except ValueError:
                            pass
                    if temp_idx != -1 and len(row) > temp_idx:
                        try:
                            temps.append(float(row[temp_idx]))
                        except ValueError:
                            pass

            print(f"\n--- Statistics (scanned first {min(row_count, max_limit)} records) ---")
            if depths:
                print(f"  Depth (m)      : Min={min(depths):.2f}, Max={max(depths):.2f}, Mean={sum(depths)/len(depths):.2f}")
            if temps:
                print(f"  Temp (°C)      : Min={min(temps):.2f}, Max={max(temps):.2f}, Mean={sum(temps)/len(temps):.2f}")

            print("\n--- Data Sample (first 5 records) ---")
            print(" | ".join(headers))
            print("-" * 80)
            for row in sample_rows:
                print(" | ".join(row))

    except Exception as e:
        print(f"Error profiling CSV file: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print_help()
    
    action = sys.argv[1].lower()
    if action == "list":
        handle_list()
    elif action == "profile":
        if len(sys.argv) < 3:
            print("Error: dataset_id is required for action 'profile'")
            print_help()
        handle_profile(sys.argv[2])
    else:
        print(f"Error: Unknown action '{action}'")
        print_help()
