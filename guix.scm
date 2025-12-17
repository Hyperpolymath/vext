;; vext - Guix Package Definition
;; SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
;; Run: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system cargo)
             ((guix licenses) #:prefix license:)
             (gnu packages base)
             (gnu packages crates-io)
             (gnu packages tls)
             (gnu packages pkg-config))

(define-public vext
  (package
    (name "vext")
    (version "1.0.0")
    (source (local-file "." "vext-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs
       (("rust-tokio" ,rust-tokio-1)
        ("rust-serde" ,rust-serde-1)
        ("rust-serde-json" ,rust-serde-json-1)
        ("rust-toml" ,rust-toml-0.8)
        ("rust-clap" ,rust-clap-4)
        ("rust-tracing" ,rust-tracing-0.1)
        ("rust-tracing-subscriber" ,rust-tracing-subscriber-0.3)
        ("rust-thiserror" ,rust-thiserror-1)
        ("rust-anyhow" ,rust-anyhow-1)
        ("rust-native-tls" ,rust-native-tls-0.2))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'chdir-to-core
           (lambda _
             (chdir "vext-core")
             #t)))))
    (native-inputs
     (list pkg-config))
    (inputs
     (list openssl))
    (synopsis "High-performance IRC notification daemon for version control")
    (description "Vext is the Rhodium Standard Edition of irker - a high-performance
async IRC notification daemon for version control systems.  Written in Rust with
Tokio for maximum performance, it implements RFC 1459 IRC protocol with TLS support,
connection pooling, and rate limiting.")
    (home-page "https://github.com/hyperpolymath/vext")
    (license (list license:expat license:agpl3+))))

;; Return package for guix shell
vext
