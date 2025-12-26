// Source: https://github.com/jyn514/dotfiles/blob/master/config/glide.ts

function shorten_unique_prefixes(haystack) {
  // first, construct a set of duplicates
  const seen = new Set();
  const duplicates = new Set();
  for (let t of haystack) {
    if (seen.has(t)) {
      duplicates.add(t);
    } else {
      seen.add(t);
    }
  }

  // shorten each word
  return haystack.map((needle, pos) => {
    if (duplicates.has(needle)) return needle;
    // while all words have the same character at position i, increment i
    for (let i = 1; i <= needle.length; i++) {
      const prefix = needle.slice(0, i);
      const is_unique = haystack.every((w, j) => pos === j || !w.startsWith(prefix));
      if (is_unique) {
        return prefix;
      }
    }
    // no unique prefix
    return needle;
  });
}

function strip(text) {
  // strip numbers, non-ascii text, and annoying-to-type characters
  return text.replace(/[0-9]+/g, '').replace(/[^a-zA-Z0-9-]/g, '').toLowerCase();
}

function labels(texts) {
  // now shorten as much as we can without losing info
  const haystack = shorten_unique_prefixes(texts);

  let nums_used = 0;
  const result = new Array(haystack.length);

  // trim prefixes longer than 3 characters by using letters that occur later in the label.
  // also, try to replace the last letter of duplicates.
  // note that that can only help if the original text was > 3 characters.
  const used = new Set();
  outer: for (const [index, prefix] of haystack.entries()) {
    if (prefix === "") {
      result[index] = String(nums_used++);
    } else if (prefix.length > 3 || used.has(prefix)) {
      const base = prefix.substring(0, 2);
      // try each character after the 3rd in turn.
      // consider the original text, not the shortened prefix.
      for (const c of texts[index].substring(2)) {
        const candidate = base + c;
        if (!used.has(candidate)) {
          result[index] = candidate;
          used.add(candidate);
          continue outer;
        }
      }
      // we couldn't shorten it. use a number.
      result[index] = String(nums_used++);
    } else {
      // already short enough, use it as-is.
      result[index] = prefix;
      used.add(prefix);
    }
  }

  // try one last time to shorten prefixes—if we gave up earlier, we might have freed up a spot.
  return shorten_unique_prefixes(result);
}

glide.o.hint_label_generator = async ({ content }) => {
  const texts = await content.map(element => [element.textContent, element.ariaLabel]);
  const haystack = texts.map(([text, label]) => strip(text) || strip(label || ""));
  return labels(haystack);
};
