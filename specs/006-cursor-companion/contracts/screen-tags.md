# Contract: Screen tags in model replies

Tags are appended at the very end of a reply, never spoken, never stored in chat text.

```
[POINT:x,y:label:screen N]                 (existing, v0.1)
[DRAW:circle:x,y,r:screen N]
[DRAW:arrow:x1,y1,x2,y2:screen N]
[DRAW:box:x,y,w,h:screen N]
[DRAW:underline:x1,y,x2:screen N]
```

- Numbers are integers or decimals in screenshot pixels. `:screen N` is optional (default 1).
- Case-insensitive. Whitespace around separators is allowed.
- Invalid tags are dropped silently. Valid ones are kept.

## Prompt addition (appended to the assistant system prompt)

"Drawing: when showing is clearer than telling, you may add up to 3 drawings after the optional POINT tag:
[DRAW:circle:x,y,r:screen N], [DRAW:arrow:x1,y1,x2,y2:screen N], [DRAW:box:x,y,w,h:screen N],
[DRAW:underline:x1,y,x2:screen N]. Same pixel coordinates as POINT. Never mention drawings in your words."

## Router addition

Pointing-model phrases add: "circle", "draw", "highlight", "underline", "encierra", "dibuja", "subraya", "resalta".
