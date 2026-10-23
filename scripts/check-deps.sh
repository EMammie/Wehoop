#!/usr/bin/env bash
# Enforces the module dependency rules of docs/M5-PLAN.md on WehoopKit.
#
#   Feature* -> Domain, DesignSystem          (never Data, never another Feature)
#   Data -> Domain, Contracts, LiveEngine (+ external packages, e.g. supabase-swift)
#   LiveEngine -> Domain, Contracts
#   TestSupport -> Domain, Contracts, LiveEngine
#   Domain, Contracts, DesignSystem -> nothing in the package
#   Feature test targets: never Data, never another Feature.
#
# Checks both the declared target dependencies (`swift package dump-package`) and the
# `import` lines in each target's sources, because SwiftPM can let an undeclared
# sibling module import compile by accident.
#
# Usage: scripts/check-deps.sh [path/to/WehoopKit]   (exit 1 on any violation)
set -euo pipefail

pkg="${1:-$(cd "$(dirname "$0")/.." && pwd)/WehoopKit}"
json="$(swift package --package-path "$pkg" dump-package)"

python3 -I - "$pkg" "$json" <<'PY'
import json, pathlib, re, sys

pkg = pathlib.Path(sys.argv[1])
manifest = json.loads(sys.argv[2])
targets = {t["name"]: t for t in manifest["targets"]}
local = {name for name, t in targets.items() if t["type"] != "test"}
features = {name for name in local if name.startswith("Feature")}

allowed = {
    "Domain": set(),
    "Contracts": set(),
    "DesignSystem": set(),
    "LiveEngine": {"Domain", "Contracts"},
    "Data": {"Domain", "Contracts", "LiveEngine"},
    "TestSupport": {"Domain", "Contracts", "LiveEngine"},
}
for feature in features:
    allowed[feature] = {"Domain", "DesignSystem"}

def local_deps(target):
    deps = set()
    for dep in target.get("dependencies", []):
        for kind in ("byName", "target"):
            if kind in dep and dep[kind][0] in local:
                deps.add(dep[kind][0])
        # "product" deps are external packages; only Data may have them.
        if "product" in dep and target["name"] != "Data" and target["type"] != "test":
            deps.add(f"external:{dep['product'][0]}")
    return deps

def imports(target):
    root = pkg / (target.get("path") or f"{'Tests' if target['type'] == 'test' else 'Sources'}/{target['name']}")
    found = set()
    for swift in root.rglob("*.swift"):
        for line in swift.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*(?:@\w+(?:\(\w+\))?\s+)*(?:public |internal |package |private |fileprivate )?import\s+(?:\w+\s+)?(\w+)", line)
            if m and m.group(1) in local:
                found.add(m.group(1))
    return found

violations = []
for name, target in sorted(targets.items()):
    declared = local_deps(target)
    used = imports(target)
    if target["type"] == "test":
        if name.startswith("Feature"):
            own = name.removesuffix("Tests")
            for dep in sorted((declared | used) - {own}):
                if dep == "Data" or dep in features:
                    violations.append(f"{name} depends on {dep} (Feature tests: never Data, never another Feature)")
        continue
    if name not in allowed:
        violations.append(f"{name} has no dependency rule; add it to scripts/check-deps.sh and docs/M5-PLAN.md")
        continue
    for dep in sorted(declared - allowed[name]):
        violations.append(f"{name} declares a dependency on {dep}; allowed: {sorted(allowed[name]) or 'nothing'}")
    for dep in sorted(used - allowed[name] - {name}):
        violations.append(f"{name} imports {dep}; allowed: {sorted(allowed[name]) or 'nothing'}")

if violations:
    print("check-deps: FAIL")
    for v in violations:
        print(f"  - {v}")
    sys.exit(1)
print(f"check-deps: OK ({len(local)} modules, {len(features)} features, {len(targets) - len(local)} test targets)")
PY
