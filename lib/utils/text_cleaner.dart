class TextCleaner {
  /// Main entry point — call this on every AI explanation response
  static String clean(String raw) {
    String text = raw;

    // ── STEP 1: Remove LaTeX environments first ─────────────────────────
    text = text.replaceAll(RegExp(r'\\begin\{[^}]+\}'), '');
    text = text.replaceAll(RegExp(r'\\end\{[^}]+\}'), '');

    // ── STEP 2: Replace LaTeX symbols with plain Unicode/text ───────────
    // DO THIS before any * removal — \times → * would cause $1 corruption
    text = text.replaceAll(r'\bar{x}', 'x̄');
    text = text.replaceAll(r'\bar{X}', 'X̄');
    text = text.replaceAll(r'\bar{x}_i', 'x̄ᵢ');
    text = text.replaceAll(r'\mu', 'μ');
    text = text.replaceAll(r'\sigma', 'σ');
    text = text.replaceAll(r'\alpha', 'α');
    text = text.replaceAll(r'\beta', 'β');
    text = text.replaceAll(r'\pi', 'π');
    text = text.replaceAll(r'\sum', 'Σ');
    text = text.replaceAll(r'\prod', 'Π');
    text = text.replaceAll(r'\sqrt', 'sqrt');
    text = text.replaceAll(r'\frac', '/');

    // CRITICAL: \times → "×" NOT "*"  (avoids $1 corruption in bold regex)
    text = text.replaceAll(r'\times', '×');
    text = text.replaceAll(r'\cdot', '·');
    text = text.replaceAll(r'\leq', '≤');
    text = text.replaceAll(r'\geq', '≥');
    text = text.replaceAll(r'\neq', '≠');
    text = text.replaceAll(r'\approx', '≈');
    text = text.replaceAll(r'\infty', '∞');
    text = text.replaceAll(r'\pm', '±');
    text = text.replaceAll(r'\div', '÷');
    text = text.replaceAll(r'\ldots', '...');
    text = text.replaceAll(r'\text', '');
    text = text.replaceAll(r'\,', ' ');
    text = text.replaceAll(r'\.', '.');

    // ── STEP 3: Subscripts  n_i → nᵢ ───────────────────────────────────
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z])_\{([^}]+)\}'),
          (m) => '${m[1]}${_subscript(m[2]!)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z])_([0-9a-zA-Z])'),
          (m) => '${m[1]}${_subscript(m[2]!)}',
    );

    // ── STEP 4: Superscripts  x^2 → x² ─────────────────────────────────
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9])\^\{([^}]+)\}'),
          (m) => '${m[1]}${_superscript(m[2]!)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9])\^([0-9])'),
          (m) => '${m[1]}${_superscript(m[2]!)}',
    );

    // ── STEP 5: Remove remaining LaTeX curly braces ──────────────────────
    // Repeatedly remove until no more nested braces
    for (int i = 0; i < 3; i++) {
      text = text.replaceAllMapped(
        RegExp(r'\{([^{}]*)\}'),
            (m) => m[1] ?? '',
      );
    }

    // Remove any remaining backslash commands
    text = text.replaceAll(RegExp(r'\\[a-zA-Z]+\*?'), '');
    text = text.replaceAll(r'\\', '');

    // ── STEP 6: Fix $1 artifacts (safety net) ───────────────────────────
    // If $1 $2 etc still appear, replace with ×
    text = text.replaceAll(RegExp(r'\s\$\d\s'), ' × ');
    text = text.replaceAll(RegExp(r'\$\d'), '');

    // ── STEP 7: Markdown headings → UPPERCASE ───────────────────────────
    text = text.replaceAllMapped(
      RegExp(r'^#{1,3}\s+(.+)$', multiLine: true),
          (m) => '\n${m[1]!.toUpperCase()}\n',
    );

    // ── STEP 8: Bold/italic — AFTER all * replacements above ────────────
    // Safe now because × is already replaced (not *)
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*\n]+)\*\*'),
          (m) => m[1]!,
    );
    text = text.replaceAllMapped(
      RegExp(r'\*([^*\n]+)\*'),
          (m) => m[1]!,
    );

    // ── STEP 9: Cleanup whitespace ───────────────────────────────────────
    text = text.replaceAll(RegExp(r'  +'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.trim();

    return text;
  }

  static String _subscript(String s) {
    const sub = {
      '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
      '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
      'i': 'ᵢ', 'j': 'ⱼ', 'k': 'ₖ', 'n': 'ₙ', 'm': 'ₘ',
    };
    return s.split('').map((c) => sub[c] ?? c).join();
  }

  static String _superscript(String s) {
    const sup = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
      '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
      'n': 'ⁿ', 'i': 'ⁱ',
    };
    return s.split('').map((c) => sup[c] ?? c).join();
  }
}