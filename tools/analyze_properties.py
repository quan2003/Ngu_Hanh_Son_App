#!/usr/bin/env python3
"""Analyze GeoJSON properties to understand the data structure."""

import json
from collections import Counter

print("Loading GeoJSON file...")
with open("assets/maps/nhs.geojson", "r", encoding="utf-8") as f:
    data = json.load(f)

print(f"\nTotal features: {len(data['features'])}")

# Analyze properties
all_layers = []
sample_features = {}

for i, feature in enumerate(data["features"][:1000]):  # Sample first 1000
    props = feature["properties"]
    layer = props.get("Layer", "Unknown")
    all_layers.append(layer)

    if layer not in sample_features:
        sample_features[layer] = props

print(f"\n{'='*80}")
print("LAYER DISTRIBUTION (first 1000 features):")
print(f"{'='*80}")
layer_counts = Counter(all_layers)
for layer, count in layer_counts.most_common():
    print(f"{layer:40} : {count:5} features")

print(f"\n{'='*80}")
print("SAMPLE PROPERTIES BY LAYER:")
print(f"{'='*80}")
for layer, props in list(sample_features.items())[:10]:
    print(f"\nLayer: {layer}")
    print(f"Properties: {props}")
    print("-" * 80)
