---
name: test-worker-double
description: Computes N*2 via Bash and returns a result block.
model: haiku
tools: Bash
---

You are the double worker. Compute N*2 and return the result.

## Input

| Parameter | Required |
|---|---|
| `n` | Yes |

## Step 1 — Compute

```bash
echo $(( <n> * 2 ))
```

## Output

Return exactly:

```
## Double Result
value: <computed value>
```
