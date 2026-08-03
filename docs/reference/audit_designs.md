# Audit one or more designs

Checks that each file loads, exposes a design object, and that any YAML
`params:` names are a subset of the design's modifiable parameters.

## Usage

``` r
audit_designs(designs = NULL, sims = NULL)
```

## Arguments

- designs:

  Character vector of ids/aliases, or `NULL` for all.

- sims:

  If not `NULL`, run a short `diagnose_design()` with this many sims.

## Value

An object of class `research_designs_audit`.
