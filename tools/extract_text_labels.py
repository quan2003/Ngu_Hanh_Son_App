#!/usr/bin/env python3
"""Extract text labels and their locations from GeoJSON exported from DWG."""

import json
from collections import defaultdict

print("Loading GeoJSON file...")
with open("assets/maps/nhs.geojson", "r", encoding="utf-8") as f:
    data = json.load(f)

print(f"\nTotal features: {len(data['features'])}")

# Find features with Text property
text_features = []
layer_texts = defaultdict(list)

for feature in data["features"]:
    props = feature["properties"]
    text_value = props.get("Text")
    layer = props.get("Layer", "Unknown")

    if text_value:
        # Get coordinates (usually point for text)
        coords = feature["geometry"]["coordinates"]

        text_features.append(
            {"text": text_value, "layer": layer, "coords": coords, "properties": props}
        )

        layer_texts[layer].append(text_value)

print(f"\n{'='*80}")
print(f"FOUND {len(text_features)} TEXT FEATURES")
print(f"{'='*80}")

# Group by layer
print("\nText labels by layer:")
print("-" * 80)
for layer, texts in sorted(layer_texts.items()):
    print(f"\n{layer} ({len(texts)} labels):")
    unique_texts = sorted(set(texts))
    for text in unique_texts[:20]:  # Show first 20 unique
        print(f"  - {text}")
    if len(unique_texts) > 20:
        print(f"  ... and {len(unique_texts) - 20} more")

# Save detailed text features to JSON
output_file = "tools/text_labels.json"
with open(output_file, "w", encoding="utf-8") as f:
    json.dump(text_features, f, ensure_ascii=False, indent=2)

print(f"\n{'='*80}")
print(f"Detailed text features saved to: {output_file}")
print(f"{'='*80}")

# Analyze patterns
print("\nPattern analysis:")
print("-" * 80)

# Find "TỔ" patterns
to_labels = [
    t for t in text_features if "TỔ" in t["text"].upper() or "TO" in t["text"].upper()
]
print(f"Tổ dân phố labels: {len(to_labels)}")
if to_labels:
    print("Examples:")
    for t in to_labels[:10]:
        print(f"  - {t['text']} at {t['coords']}")

# Find "CHI BỘ" or "CB" patterns
cb_labels = [
    t
    for t in text_features
    if "CHI BỘ" in t["text"].upper() or "CB" in t["text"].upper()
]
print(f"\nChi bộ labels: {len(cb_labels)}")
if cb_labels:
    print("Examples:")
    for t in cb_labels[:10]:
        print(f"  - {t['text']} at {t['coords']}")

print("\n" + "=" * 80)
print("Next steps:")
print("1. Review tools/text_labels.json for all text labels")
print("2. Identify which layers contain administrative boundaries")
print("3. Create mapping between text labels and polygons")
print("=" * 80)
