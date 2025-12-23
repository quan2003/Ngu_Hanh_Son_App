#!/usr/bin/env python3
"""Analyze GeoJSON layers and properties."""

import json
from collections import Counter

# Load GeoJSON
with open("assets/maps/nhs.geojson", "r", encoding="utf-8") as f:
    data = json.load(f)

print(f"Total features: {len(data['features'])}")
print("\n" + "=" * 80)

# Count layers
layers = Counter([f["properties"].get("Layer", "None") for f in data["features"]])
print("\nAvailable layers (top 30):")
for layer, count in sorted(layers.items(), key=lambda x: x[1], reverse=True)[:30]:
    print(f"  {layer:40} {count:8,} features")

# Check for boundary/ward data
print("\n" + "=" * 80)
print("\nLayers that might contain ward boundaries:")
boundary_keywords = ["ranh", "gioi", "boundary", "ward", "phuong", "admin"]
for layer in layers.keys():
    if any(kw in layer.lower() for kw in boundary_keywords):
        print(f"  {layer}: {layers[layer]} features")

# Check all unique property keys
all_keys = set()
for f in data["features"][:1000]:
    all_keys.update(f["properties"].keys())

print("\n" + "=" * 80)
print("\nAll property keys found:")
for key in sorted(all_keys):
    print(f"  - {key}")
