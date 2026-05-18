#!/usr/bin/env python3

import os
import sys
from glob import glob

import fontforge
import psMat


HEADER = """#!/usr/bin/env bash

### START-OF-CODEXBAR-PROVIDER-ICON-MAP
function __codexbar_icon_map() {
\tcase "$1" in
"""

FOOTER = """\t*)
\t\ticon_result="$(printf '%b' '\\uE000')"
\t\t;;
\tesac
}
### END-OF-CODEXBAR-PROVIDER-ICON-MAP
"""


def fit_glyph(glyph):
    glyph.unlinkRef()
    glyph.removeOverlap()
    glyph.correctDirection()

    xmin, ymin, xmax, ymax = glyph.boundingBox()
    width = xmax - xmin
    height = ymax - ymin
    if width <= 0 or height <= 0:
        return

    scale = min(920 / width, 920 / height)
    glyph.transform(psMat.translate(-xmin, -ymin))
    glyph.transform(psMat.scale(scale))

    xmin, ymin, xmax, ymax = glyph.boundingBox()
    width = xmax - xmin
    height = ymax - ymin
    glyph.transform(psMat.translate((1000 - width) / 2 - xmin, (900 - height) / 2 - ymin))
    glyph.width = 1000


def main():
    resource_dir = sys.argv[1]
    output_prefix = sys.argv[2]

    font = fontforge.font()
    font.encoding = "UnicodeFull"
    font.fontname = "CodexBarProviderIcons"
    font.familyname = "CodexBar Provider Icons"
    font.fullname = "CodexBar Provider Icons"
    font.ascent = 780
    font.descent = 220
    font.em = 1000

    glyph_map = []
    icon_paths = sorted(glob(os.path.join(resource_dir, "ProviderIcon-*.svg")))

    for index, path in enumerate(icon_paths):
        provider = os.path.basename(path).removeprefix("ProviderIcon-").removesuffix(".svg")
        codepoint = 0xE000 + index
        glyph = font.createChar(codepoint, f"codexbar-{provider}")
        glyph.importOutlines(path)
        fit_glyph(glyph)
        glyph_map.append((provider, codepoint))

    font.generate(f"{output_prefix}.ttf")

    with open(f"{output_prefix}.sh", "w", encoding="utf-8") as output:
        output.write(HEADER)
        for provider, codepoint in glyph_map:
            output.write(f'\t"{provider}")\n')
            output.write(f"\t\ticon_result=\"$(printf '%b' '\\u{codepoint:04X}')\"\n")
            output.write("\t\t;;\n")
        output.write(FOOTER)


if __name__ == "__main__":
    main()
