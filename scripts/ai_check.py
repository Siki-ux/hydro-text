"""
AI-detection signal analyzer for LaTeX thesis chapters.

Checks for patterns that AI detectors flag:
1. Low sentence-length variance (AI writes uniform-length sentences)
2. Repetitive sentence starters (AI loves "The", "This", "It")
3. Overused filler/transition phrases typical of LLM output
4. Paragraph-level uniformity (all paragraphs similar length)
5. Passive voice density (AI overuses passive)
"""

import re
import os
import sys
from collections import Counter
from pathlib import Path

# ── Strip LaTeX commands to get plain text ──────────────────────
def strip_latex(text: str) -> str:
    # Remove comments
    text = re.sub(r'(?<!\\)%.*', '', text)
    # Remove common environments we don't want to analyze
    for env in ['tikzpicture', 'figure', 'table', 'longtable', 'lstlisting',
                'itemize', 'enumerate', 'description', 'tabularx']:
        text = re.sub(rf'\\begin\{{{env}\}}.*?\\end\{{{env}\}}', '', text, flags=re.DOTALL)
    # Remove \commands{...} but keep the content of text-like ones
    text = re.sub(r'\\(?:texttt|textbf|emph|textit)\{([^}]*)\}', r'\1', text)
    text = re.sub(r'\\(?:parencite|textcite|cite|ref|label|caption)\{[^}]*\}', '', text)
    # Remove remaining commands
    text = re.sub(r'\\[a-zA-Z]+\*?(?:\[[^\]]*\])?(?:\{[^}]*\})?', '', text)
    # Remove braces, ~, and LaTeX special chars
    text = re.sub(r'[{}~]', ' ', text)
    text = re.sub(r'\\[\\&%$#_]', '', text)
    # Collapse whitespace
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def get_sentences(text: str) -> list[str]:
    # Split on sentence-ending punctuation followed by space or end
    parts = re.split(r'(?<=[.!?])\s+', text)
    # Filter out very short fragments
    return [s.strip() for s in parts if len(s.strip().split()) >= 4]


def analyze_file(filepath: str) -> dict:
    with open(filepath, 'r', encoding='utf-8') as f:
        raw = f.read()

    plain = strip_latex(raw)
    sentences = get_sentences(plain)

    if len(sentences) < 5:
        return None

    # 1. Sentence length stats
    lengths = [len(s.split()) for s in sentences]
    avg_len = sum(lengths) / len(lengths)
    variance = sum((l - avg_len) ** 2 for l in lengths) / len(lengths)
    std_dev = variance ** 0.5
    coeff_var = std_dev / avg_len if avg_len > 0 else 0

    # 2. Sentence starters (first word)
    starters = [s.split()[0].strip('(').strip('"') for s in sentences if s.split()]
    starter_counts = Counter(starters)
    total_sentences = len(sentences)
    top_starters = starter_counts.most_common(8)

    # 3. AI filler phrases
    ai_phrases = [
        r'\bfurthermore\b', r'\bmoreover\b', r'\badditionally\b',
        r'\bit is worth noting\b', r'\bit is important to\b',
        r'\bin this context\b', r'\bplays a crucial\b',
        r'\bserves as a\b', r'\bensuring that\b',
        r'\bin order to\b', r'\bdue to the fact\b',
        r'\bas mentioned\b', r'\bit should be noted\b',
        r'\bthis approach\b', r'\bthis ensures\b',
        r'\beffectively\b', r'\bseamlessly\b', r'\bleverag',
        r'\bfacilitat', r'\butiliz', r'\brobust\b',
        r'\bcomprehensive\b', r'\bsignificantly\b',
        r'\bnotably\b', r'\bspecifically\b',
        r'\boverall\b', r'\bultimately\b',
    ]
    phrase_hits = {}
    lower_plain = plain.lower()
    for pat in ai_phrases:
        matches = re.findall(pat, lower_plain)
        if matches:
            phrase_hits[pat.replace(r'\b', '').strip()] = len(matches)

    # 4. Paragraph length uniformity
    paragraphs = [p.strip() for p in re.split(r'\n\s*\n', raw) if len(p.strip()) > 50]
    para_lengths = [len(strip_latex(p).split()) for p in paragraphs]
    if len(para_lengths) > 2:
        para_avg = sum(para_lengths) / len(para_lengths)
        para_std = (sum((l - para_avg) ** 2 for l in para_lengths) / len(para_lengths)) ** 0.5
        para_cv = para_std / para_avg if para_avg > 0 else 0
    else:
        para_cv = None

    # 5. Passive voice ratio (simple heuristic: "is/was/are/were/been/being + past participle")
    passive_pattern = r'\b(?:is|was|are|were|been|being)\s+\w+(?:ed|en|t)\b'
    passive_count = len(re.findall(passive_pattern, lower_plain))
    passive_ratio = passive_count / total_sentences if total_sentences > 0 else 0

    return {
        'file': os.path.basename(filepath),
        'sentences': total_sentences,
        'avg_sentence_length': round(avg_len, 1),
        'sentence_length_std': round(std_dev, 1),
        'sentence_length_cv': round(coeff_var, 2),
        'top_starters': top_starters,
        'ai_phrases': phrase_hits,
        'paragraph_cv': round(para_cv, 2) if para_cv is not None else None,
        'passive_ratio': round(passive_ratio, 2),
    }


def print_report(result: dict):
    f = result['file']
    print(f"\n{'='*60}")
    print(f"  {f}")
    print(f"{'='*60}")
    print(f"  Sentences: {result['sentences']}")
    print(f"  Avg sentence length: {result['avg_sentence_length']} words")
    print(f"  Sentence length std dev: {result['sentence_length_std']}")

    # CV check
    cv = result['sentence_length_cv']
    flag = " ⚠️  LOW VARIANCE (AI signal)" if cv < 0.35 else " ✓"
    print(f"  Sentence length CV: {cv}{flag}")
    print(f"    (Human writing typically 0.40–0.70; AI tends < 0.35)")

    # Passive
    pr = result['passive_ratio']
    flag = " ⚠️  HIGH (AI signal)" if pr > 0.60 else " ✓"
    print(f"  Passive voice ratio: {pr}{flag}")

    # Paragraph uniformity
    if result['paragraph_cv'] is not None:
        pcv = result['paragraph_cv']
        flag = " ⚠️  UNIFORM PARAGRAPHS" if pcv < 0.30 else " ✓"
        print(f"  Paragraph length CV: {pcv}{flag}")

    # Starters
    print(f"\n  Top sentence starters:")
    for word, count in result['top_starters']:
        pct = round(100 * count / result['sentences'], 1)
        flag = " ⚠️" if pct > 20 else ""
        print(f"    {word:15s}  {count:3d} ({pct}%){flag}")

    # AI phrases
    if result['ai_phrases']:
        print(f"\n  ⚠️  AI-typical phrases found:")
        for phrase, count in sorted(result['ai_phrases'].items(), key=lambda x: -x[1]):
            print(f"    \"{phrase}\"  ×{count}")
    else:
        print(f"\n  ✓ No common AI filler phrases detected")


def main():
    chapters_dir = Path(__file__).parent.parent / 'dp-text' / 'chapters'
    if not chapters_dir.exists():
        print(f"Error: {chapters_dir} not found")
        sys.exit(1)

    files = sorted(chapters_dir.glob('*.tex'))
    issues_total = 0

    for f in files:
        result = analyze_file(str(f))
        if result:
            print_report(result)
            if result['sentence_length_cv'] < 0.35:
                issues_total += 1
            if result['ai_phrases']:
                issues_total += len(result['ai_phrases'])

    print(f"\n{'='*60}")
    if issues_total == 0:
        print("  ✓ No major AI-detection signals found.")
    else:
        print(f"  {issues_total} potential issue(s) to review.")
    print(f"{'='*60}")


if __name__ == '__main__':
    main()
