; SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
; STATE.scm - Current project state for vext
; Media type: application/vnd.state+scm

(state
  (metadata
    (version "1.0.0")
    (schema-version "1.0")
    (created "2025-01-01")
    (updated "2025-12-30")
    (project "vext")
    (repo "hyperpolymath/vext"))

  (project-context
    (name "vext")
    (tagline "High-performance IRC notification daemon for version control systems")
    (tech-stack
      (primary "Rust")
      (secondary "Deno" "ReScript")
      (config "Nickel" "TOML")
      (docs "AsciiDoc" "Markdown")))

  (current-position
    (phase "pre-release")
    (overall-completion 85)
    (components
      (vext-core
        (status "functional")
        (completion 90)
        (tests 22)
        (warnings 29))
      (vext-tools
        (status "needs-migration")
        (completion 70)
        (note "TypeScript→ReScript migration pending"))
      (documentation
        (status "complete")
        (completion 95))
      (ci-cd
        (status "needs-fixes")
        (completion 75)))
    (working-features
      "IRC connection pooling"
      "UDP notification listener"
      "Rate limiting"
      "TLS support"
      "Multi-channel broadcasting"
      "Git hook integration"))

  (route-to-mvp
    (milestone "1.0.0-rc1"
      (items
        (item "Convert vext-tools TypeScript to ReScript" pending)
        (item "Create Nickel configuration" pending)
        (item "Add man pages" pending)
        (item "Create .well-known directory" pending)
        (item "Fix Rust warnings" pending)))
    (milestone "1.0.0"
      (items
        (item "Release binaries" pending)
        (item "Publish to crates.io" pending)
        (item "Container image on GHCR" pending))))

  (blockers-and-issues
    (critical)
    (high
      (issue "TypeScript in vext-tools violates RSR language policy"))
    (medium
      (issue "29 Rust compiler warnings (unused code)")
      (issue "Missing SCM files")
      (issue "Missing .well-known directory"))
    (low
      (issue "No fuzzing integration")))

  (critical-next-actions
    (immediate
      "Create all 6 SCM files"
      "Create .well-known directory"
      "Convert TypeScript to ReScript")
    (this-week
      "Add man pages"
      "Create Nickel configuration"
      "Fix Rust warnings")
    (this-month
      "Release 1.0.0-rc1"
      "Set up fuzzing"))

  (session-history
    (snapshot "2025-12-30"
      (accomplishments
        "Ran full test suite (22 tests pass)"
        "Built release binary"
        "Deleted python-ci.yml workflow"
        "Fixed CodeQL configuration"
        "Identified all missing files"))))
