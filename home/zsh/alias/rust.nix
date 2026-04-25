{ ... }:

{
  programs.zsh.shellAliases = {
    # cargo
    cb = "cargo build";
    cbb = "cargo build --bin";
    cbe = "cargo build --examples";
    cbr = "cargo build --release";
    cbw = "cargo build --workspace";
    cbrm = "cargo build --release --target=x86_64-unknown-linux-musl";
    cbaf = "cargo build --all-features";
    cbn = "cargo bench";
    cbnaf = "cargo bench --all-features";
    cbnat = "cargo bench --all-targets";
    ct = "cargo test";
    ctl = "cargo test --lib";
    ctw = "cargo test --workspace";
    ctaf = "cargo test --all-features";
    ctlaf = "cargo test --lib --all-features";
    ctnc = "cargo test -- --nocapture";
    ctafnc = "cargo test --all-features -- --nocapture";
    ctlafnc = "cargo test --lib --all-features -- --nocapture";
    ccln = "cargo clean";
    cdoc = "cargo doc";
    cdoco = "cargo doc --open";
    cn = "cargo new";
    cr = "cargo run";
    crb = "cargo run --bin";
    cre = "cargo run --example";
    crp = "cargo run --package";
    crr = "cargo run --release";
    crrb = "cargo run --release --bin";
    crrp = "cargo run --release --package";
    cck = "cargo check";
    cckaf = "cargo check --all-features";
    cckat = "cargo check --all-targets";
    cckaft = "cargo check --all-features --all-targets --workspace";
    cckw = "cargo check --workspace";
    ccl = "cargo clippy";
    cclaf = "cargo clippy --all-features -- -Dwarnings -Drust-2018-idioms";
    cclat = "cargo clippy --all-targets";
    cclaft = "cargo clippy --all-features --all-targets --workspace";
    cclw = "cargo clippy --workspace";
    cclww = "cargo clippy --workspace -- -D warnings";
    cup = "cargo update";
    cupp = "cargo update --package";
    csr = "cargo search";
    cin = "cargo install";
    cinf = "cargo install --force";
    cinp = "cargo install --path";
    cinpd = "cargo install --path .";
    cun = "cargo uninstall";
    cx = "cargo expand";
    cxb = "cargo expand --bin";
    cxl = "cargo expand --lib";
    cxaf = "cargo expand --all-features";
    cod = "cargo outdated";
    codr = "cargo outdated --root-deps-only";

    # cargo nextest
    cnt = "cargo nextest run";
    cntw = "cargo nextest run --workspace";
    cntaf = "cargo nextest run --all-features";
    cntr = "cargo nextest run --release";
    cntnf = "cargo nextest run --no-fail-fast";
    cntl = "cargo nextest list";

    # cargo +nightly
    cnyb = "cargo +nightly build";
    cnybr = "cargo +nightly build --release";
    cnybaf = "cargo +nightly build --all-features";
    cnybc = "cargo +nightly bench";
    cnybcaf = "cargo +nightly bench --all-features";
    cnyt = "cargo +nightly test";
    cnytaf = "cargo +nightly test --all-features";
    cnyn = "cargo +nightly new";
    cnyr = "cargo +nightly run";
    cnyin = "cargo +nightly install";
    cnyun = "cargo +nightly uninstall";

    # rustup
    ru = "rustup";
    rus = "rustup show";
    ruup = "rustup update";
    rusup = "rustup self update";
    rud = "rustup default";
    rutc = "rustup toolchain";
    rutcl = "rustup toolchain list";
    rutcin = "rustup toolchain install";
    rutcun = "rustup toolchain uninstall";
    ruta = "rustup target";
    rutal = "rustup target list";
    rutaa = "rustup target add";
    rutar = "rustup target remove";
    rucl = "rustup component list";
    ruca = "rustup component add";
    rucr = "rustup component remove";
    ruo = "rustup override";
    ruol = "rustup override list";
    ruos = "rustup override set";
    ruou = "rustup override unset";
    rur = "rustup run";
    ruw = "rustup which";
    rudoc = "rustup doc";
    ruh = "rustup help";
    rusp = "rustup set profile";
    ruspm = "rustup set profile minimal";
    ruspd = "rustup set profile default";
    ruspc = "rustup set profile complete";
  };
}
