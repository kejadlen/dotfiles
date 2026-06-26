#!/usr/bin/env bash

# Measures library line coverage with grcov and fails below the
# threshold. Uses a separate CARGO_TARGET_DIR so instrumented and
# normal build artifacts never mix — mixing causes phantom uncovered
# lines. Override the gate with COVERAGE_THRESHOLD (defaults to 100).
#
# Scaffolded into a project as bin/coverage; the `coverage` justfile
# recipe runs it. See the rust skill's coverage.md and scaffolding.md.

set -euo pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

readonly THRESHOLD="${COVERAGE_THRESHOLD:-100}"
readonly TARGET_DIR="target/coverage"

main() {
    export RUSTFLAGS="-Cinstrument-coverage"
    export CARGO_TARGET_DIR="$TARGET_DIR"
    export LLVM_PROFILE_FILE="$TARGET_DIR/profraw/%p-%m.profraw"

    rm -rf "$TARGET_DIR"
    cargo test --workspace --quiet

    local report
    report=$(grcov "$TARGET_DIR/profraw" \
        --binary-path "./$TARGET_DIR/debug/" \
        --source-dir . \
        --output-types covdir \
        --ignore-not-existing \
        --keep-only 'src/**' \
        --ignore 'src/bin/**' \
        --excl-line 'cov-excl-line|unreachable!' \
        --excl-start 'cov-excl-start' \
        --excl-stop 'cov-excl-stop')

    # Per-file breakdown: walk the covdir tree, printing leaf files only.
    jq --raw-output '
        def files:
            to_entries[] | .value |
            if .children then .children | files
            else "\(.name): \(.coveragePercent)% (\(.linesCovered)/\(.linesTotal))"
            end;
        .children | files
    ' <<<"$report"

    local coverage
    coverage=$(jq '.coveragePercent' <<<"$report")
    echo ""
    echo "Total: ${coverage}%"

    if [[ "$(echo "$coverage < $THRESHOLD" | bc -l)" -eq 1 ]]; then
        echo "ERROR: coverage ${coverage}% is below ${THRESHOLD}%" >&2
        exit 1
    fi
}

main "$@"
