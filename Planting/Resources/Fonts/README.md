# Pretendard font files

PRODUCT_SPEC.md §20.2 requires Pretendard as the default product font
(non-negotiable #11). These files are not bundled here — add them yourself:

1. Download from https://github.com/orioncactus/pretendard (SIL OFL 1.1 license)
2. Place these three files in this folder:
   - `Pretendard-Regular.otf` (weight 400 — body text)
   - `Pretendard-Medium.otf` (weight 500 — emphasis)
   - `Pretendard-SemiBold.otf` (weight 600 — section headings)
3. `project.yml` already registers them under `UIAppFonts`; run
   `xcodegen generate` again after adding the files.

Until these are added, `PlantingFont` (Core/DesignSystem/PlantingFont.swift)
silently falls back to the system font — nothing will crash, but the
typography won't match spec.
