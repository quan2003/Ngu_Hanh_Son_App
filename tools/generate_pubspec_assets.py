#!/usr/bin/env python3
"""
Generate pubspec.yaml asset entries for all tile directories
"""

import os
import json


def generate_asset_entries():
    tiles_dir = os.path.join("assets", "maps", "tiles")

    print("# Generated tile asset entries")
    print("    - assets/maps/tiles/index.json")

    # Walk through zoom levels
    for zoom in range(12, 17):
        zoom_dir = os.path.join(tiles_dir, str(zoom))
        if not os.path.exists(zoom_dir):
            continue

        # Get all x directories
        x_dirs = sorted(
            [
                d
                for d in os.listdir(zoom_dir)
                if os.path.isdir(os.path.join(zoom_dir, d))
            ]
        )

        if x_dirs:
            print(f"    # Zoom {zoom}")
            for x in x_dirs:
                print(f"    - assets/maps/tiles/{zoom}/{x}/")


if __name__ == "__main__":
    generate_asset_entries()
