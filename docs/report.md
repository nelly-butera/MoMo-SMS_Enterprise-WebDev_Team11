# REST API Security & DSA Report

## 1. Introduction to API Security
Write 150 to 250 words describing API security in the context of your project. Include:
- What data is protected
- How your API authenticates requests
- Why you chose this approach for the assignment

## 2. Endpoint Documentation Summary
Summarize your implemented endpoints in your own words. You can reference `docs/api_docs.md`, but rewrite the summary to reflect your actual API behavior and error handling.

## 3. DSA Comparison Results
Paste your real timing output here after running:
`python dsa/search_compare.py`
```
DSA Comparison (10000 repeats)
Linear search: [value]
Dictionary lookup: [value]
Speedup: [value]
```

## 3.1 Reflection on DSA
Explain, in your own words, why dictionary lookup outperforms linear search for your data. Mention:
- Time complexity differences
- How performance changes as records grow
- One other data structure you would consider and why

## 4. Reflection: Basic Auth Limitations & Stronger Alternatives
Discuss:
- Two or more limitations of Basic Auth
- At least one stronger alternative (JWT, OAuth2, mTLS)
- What you would choose for production and why
