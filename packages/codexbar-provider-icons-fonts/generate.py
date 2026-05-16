#!/usr/bin/env python3

import os
import sys

import fontforge
import psMat


PROVIDERS = [
    ("codex", "ProviderIcon-codex.svg"),
    ("claude", "ProviderIcon-claude.svg"),
    ("cursor", "ProviderIcon-cursor.svg"),
    ("opencode", "ProviderIcon-opencode.svg"),
    ("opencodego", "ProviderIcon-opencodego.svg"),
    ("alibaba", "ProviderIcon-alibaba.svg"),
    ("factory", "ProviderIcon-factory.svg"),
    ("gemini", "ProviderIcon-gemini.svg"),
    ("antigravity", "ProviderIcon-antigravity.svg"),
    ("copilot", "ProviderIcon-copilot.svg"),
    ("zai", "ProviderIcon-zai.svg"),
    ("minimax", "ProviderIcon-minimax.svg"),
    ("kimi", "ProviderIcon-kimi.svg"),
    ("kilo", "ProviderIcon-kilo.svg"),
    ("kiro", "ProviderIcon-kiro.svg"),
    ("vertexai", "ProviderIcon-vertexai.svg"),
    ("augment", "ProviderIcon-augment.svg"),
    ("jetbrains", "ProviderIcon-jetbrains.svg"),
    ("amp", "ProviderIcon-amp.svg"),
    ("ollama", "ProviderIcon-ollama.svg"),
    ("synthetic", "ProviderIcon-synthetic.svg"),
    ("warp", "ProviderIcon-warp.svg"),
    ("openrouter", "ProviderIcon-openrouter.svg"),
    ("windsurf", "ProviderIcon-windsurf.svg"),
    ("perplexity", "ProviderIcon-perplexity.svg"),
    ("abacus", "ProviderIcon-abacus.svg"),
    ("mistral", "ProviderIcon-mistral.svg"),
    ("deepseek", "ProviderIcon-deepseek.svg"),
    ("codebuff", "ProviderIcon-codebuff.svg"),
]


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

    for index, (provider, filename) in enumerate(PROVIDERS):
        path = os.path.join(resource_dir, filename)
        if not os.path.exists(path):
            continue

        codepoint = 0xE000 + index
        glyph = font.createChar(codepoint, f"codexbar-{provider}")
        glyph.importOutlines(path)
        fit_glyph(glyph)
        glyph_map.append((provider, codepoint))

    font.generate(f"{output_prefix}.ttf")

    with open(f"{output_prefix}.tsv", "w", encoding="utf-8") as output:
        for provider, codepoint in glyph_map:
            output.write(f"{provider}\t{codepoint:04X}\n")


if __name__ == "__main__":
    main()
