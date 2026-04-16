"""
Generate plain text from LaTeX thesis chapters for GPTZero analysis.
Strips all LaTeX markup and outputs clean prose, split by chapter.
"""

import re
import os
from pathlib import Path

CHAPTER_DIR = Path(__file__).resolve().parent.parent / "dp-text" / "chapters"
OUTPUT_FILE = Path(__file__).resolve().parent.parent / "dp-text" / "thesis_plaintext.txt"

CHAPTERS = [
    "01-introduction.tex",
    "02-background.tex",
    "03-requirements.tex",
    "04-architecture.tex",
    "05-implementation.tex",
    "06-testing.tex",
    "07-conclusion.tex",
]


def strip_latex(text: str) -> str:
    # Remove comments
    text = re.sub(r'(?<!\\)%.*', '', text)
    # Remove environments we don't want (tables, figures, code, lists)
    for env in ['tikzpicture', 'figure', 'table', 'longtable', 'lstlisting',
                'tabularx', 'landscape']:
        text = re.sub(rf'\\begin\{{{env}\}}.*?\\end\{{{env}\}}', '', text, flags=re.DOTALL)
    # Remove itemize/enumerate/description but keep item text
    for env in ['itemize', 'enumerate', 'description']:
        text = re.sub(rf'\\begin\{{{env}\}}', '', text)
        text = re.sub(rf'\\end\{{{env}\}}', '', text)
    text = re.sub(r'\\item\[([^\]]*)\]', r'\1: ', text)
    text = re.sub(r'\\item', '', text)
    # Keep content of text-like commands
    text = re.sub(r'\\(?:texttt|textbf|emph|textit|textsc)\{([^}]*)\}', r'\1', text)
    # Remove citation/ref/label commands
    text = re.sub(r'\\(?:parencite|textcite|cite|ref|label|caption|footnote)\{[^}]*\}', '', text)
    # Remove section/chapter commands but keep titles
    text = re.sub(r'\\(?:chapter|section|subsection|subsubsection|paragraph)\*?\{([^}]*)\}', r'\n\n\1\n\n', text)
    # Remove remaining commands
    text = re.sub(r'\\[a-zA-Z]+\*?(?:\[[^\]]*\])?(?:\{[^}]*\})?', '', text)
    # Remove braces and LaTeX special chars
    text = re.sub(r'[{}]', '', text)
    text = re.sub(r'~', ' ', text)
    text = re.sub(r'\\[\\&%$#_]', '', text)
    text = re.sub(r'\$[^$]*\$', '', text)
    # Remove --- and -- (em/en dashes) → proper dashes
    text = text.replace('---', '\u2014')
    text = text.replace('--', '\u2013')
    # Collapse multiple spaces (but keep newlines)
    text = re.sub(r'[^\S\n]+', ' ', text)
    # Collapse multiple blank lines
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()


def main():
    parts = []
    for fname in CHAPTERS:
        fpath = CHAPTER_DIR / fname
        if not fpath.exists():
            print(f"Warning: {fname} not found, skipping")
            continue
        raw = fpath.read_text(encoding='utf-8')
        clean = strip_latex(raw)
        # Add chapter separator
        parts.append(f"{'='*60}")
        parts.append(f"  {fname.replace('.tex', '').upper()}")
        parts.append(f"{'='*60}")
        parts.append(clean)
        parts.append("")

    output = "\n".join(parts)
    OUTPUT_FILE.write_text(output, encoding='utf-8')
    print(f"Written {len(output)} characters to {OUTPUT_FILE}")
    print(f"Word count: {len(output.split())}")


if __name__ == "__main__":
    main()
