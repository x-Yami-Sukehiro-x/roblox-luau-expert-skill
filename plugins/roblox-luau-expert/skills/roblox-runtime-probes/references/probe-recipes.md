# Probe recipes and reports

Build each probe against facts in the user's source. These are procedures and
limits, not fabricated paths to paste into a game.

## Exact property reset

Use when the instance, property and unexpected reset are already known.

1. Resolve the exact established target once. Record class, path, initial value
   and current character identity when relevant. An absent target is a useful
   result; do not wait forever or search every similarly named object.
2. Connect only that property's change signal. Capture elapsed time and the new
   value for at most fifty records or ten seconds. If a record cap is reached,
   stop the observation and mark it truncated.
3. Ask the user to perform one normal action, such as entering sprint. Do not
   write the property to provoke a response in a read-only probe.
4. Stop if the target is destroyed or replaced. Release the signal and deadline
   task when stopped, and make repeated stop calls harmless.
5. Report the changes and phase. A change signal identifies that a value changed,
   not the script, network source or callback that wrote it. Timing correlation
   can motivate the next source read but does not prove writer identity.

If the event fires too quickly, an aggregate count plus a capped sample is enough.
Writing thousands of lines or scheduling a task for every change can cause the
very stutter under investigation.

## Two equal slots in an identified closure

Use only after the closure itself is uniquely established.

- Read the upvalues before and after one normal action whose source explains a
  distinguishing transition. Keep the function reference within this probe run;
  do not turn a temporary printed address into a persistent identifier.
- Record index, primitive type, capped primitive value, and only relevant raw
  table keys. Use identity comparison locally for table/function relationships;
  use report-local candidate labels for presentation. Labels are not selectors.
- A slot staying equal in both snapshots remains unresolved. Do not write to it
  as a second experiment. A changed slot can be a timestamp, cached result or
  incidental state; match the observed transition with source usage.

If the function cannot be identified, inspect all source-backed candidates first.
`filtergc(..., true)` hides alternatives and cannot establish uniqueness. Asking
for all results and printing ten of a hundred is also not proof of uniqueness;
report both counts and the truncation.

## A missing module or script

Prefer the exact path referenced by the source and the expected loading phase.
Check whether that object exists and whether the available source capture
includes it. A script visible in one VM may be absent from another VM's runtime
enumeration; a missing result does not prove the module is server-side.

Do not load a module to see its return value. Request its source or inspect an
already established live return table. Do not trigger a teleport or enter a new
area automatically to load content as part of a read-only probe; name the normal
player action that would provide a meaningful second observation.

## A remote call with a missing argument

Read the exact caller before instrumenting. If source cannot be recovered and
normal-call observation is necessary, define this contract before writing:

| Item | Required decision |
|---|---|
| Target | One established remote/function identity, not every name containing a word |
| Window | One normal user action, maximum records and duration |
| Record | Method, receiver identity, exact argument count, type/shape and needed primitive fields |
| Forwarding | Preserve nil holes, trailing nil and multiple returns; observation must not alter them |
| Scope | No replay, extra invocation, argument modification or automatic retry |
| Cleanup | Remove only owned instrumentation; disclose an inert hook left installed |

Use `table.pack` and its `n` for a recorded variable-argument list. Do not use
`#arguments` to infer its full length. Avoid serializing arbitrary tables or
yielding from the intercepted call to produce a report; copy only capped,
whitelisted primitives needed to understand this contract.

One recorded call establishes that invocation. It does not prove every mode has
the same shape, that the request was accepted, or that replay is safe. Match it
to a result path separately.

## No location is known

Start with the static dump index. If that finds no mechanism, choose one
discovery surface supported by the question: objects under a likely service,
script metadata or source-backed GC filters. Do not combine every surface into
one enormous report by default.

For Instance traversal, visit children incrementally with an explicit depth and
visited-node cap; check the deadline between operations. One native child-list
or GC enumeration call can still take time and allocate memory before the next
check. State this limitation rather than describing the whole scan as bounded
by the script's loop timer. Omit automatic decompilation; if metadata finds a
relevant script, decompile only that named script in a separate stage.

## Report enough to interpret an empty result

```text
Question: Does the known sprint attribute change during normal sprint?
Context: experience/place identifiers; active phase; probe revision
Target: established path, class and exact attribute name
Capabilities: available; unavailable functions used by no completed section
Bounds: 10 seconds, 50 records, 32 KiB output
Observed: initial value; elapsed time and changed value for each retained record
Coverage: elapsed time; records observed/retained; target present throughout?
End: completed | target replaced | stopped | error | truncated (which cap)
Unresolved: writer identity; server ownership
```

Replace this example question with the actual one. Avoid absolute timestamps
unless needed to correlate reports. Include the exact relevant error on failure
but do not print entire script environments or sensitive table contents.

## Check a generated probe before sending it

Use the normal file/compiler checks, then exercise report limits and cleanup in
mocks when available: no matches, one match, excess matches, unavailable API,
destroyed target, timeout, rerun and stop twice. Include a table whose
`__tostring` and `__index` raise errors to verify the serializer reads raw fields.
Assert zero game mutations and zero outgoing remote calls. A mock cannot prove
native scan cost, executor compatibility or live hook behavior; name these unrun.
