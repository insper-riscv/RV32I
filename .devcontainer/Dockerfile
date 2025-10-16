# ------------------------------------------------------------
# Minimal, portable sim image (works on amd64/arm64)
# + RISC-V GCC toolchain (rv32i) built from source
# ------------------------------------------------------------


# ============================================================
# --------------------- Builder stage ------------------------
# ============================================================
FROM ubuntu:24.04 AS riscv-builder
ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies (from riscv-gnu-toolchain README)
RUN apt-get update && apt-get install -y --no-install-recommends \
  git build-essential gawk bison flex texinfo gperf libtool patchutils \
  libgmp-dev libmpfr-dev libmpc-dev libisl-dev zlib1g-dev libexpat1-dev \
  python3 curl wget cmake ninja-build ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Installation target and default toolchain parameters
ARG PREFIX=/opt/riscv32i
ARG TARGET=riscv32-unknown-elf
# Allow tuning parallelism at build-time (fallback to 2 to avoid OOM)
ARG MAKE_JOBS=2

WORKDIR /tmp

# --- Clone the official riscv-gnu-toolchain repo
RUN git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git

# --- Fetch only the submodules needed for a bare-metal (newlib) build ---
RUN set -eux; \
    cd /tmp/riscv-gnu-toolchain; \
    git submodule sync --recursive; \
    if ! git submodule update --init --jobs 8 gcc binutils newlib; then \
      echo "Pinned SHAs missing; trying remote heads for required submodules..."; \
      git submodule update --init --jobs 8 --remote gcc binutils newlib; \
    fi

# --- Configure for RV32I-only (ilp32), no multilib, newlib runtime ---
#     Also: build C only (skip C++), disable LTO to reduce RAM pressure.
RUN mkdir -p /build && cd /build && \
  /tmp/riscv-gnu-toolchain/configure \
    --target=${TARGET} \
    --prefix=${PREFIX} \
    --with-newlib \
    --disable-multilib \
    --with-arch=rv32i \
    --with-abi=ilp32 \
    --disable-nls \
    --enable-languages=c \
    --disable-lto

# --- Build the bare-metal toolchain (reduced parallelism to avoid OOM) ---
RUN make -C /build -j"${MAKE_JOBS}" newlib



# ============================================================
# ---------------------- Final image -------------------------
# ============================================================
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# --- Core runtime tools (Python, GHDL, GTKWave, build tools) ---
# Add python3-dev + build-essential so pip can build wheels (e.g., cocotb).
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    build-essential \
    make git pkg-config \
    gnat ghdl \
    gtkwave \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# --- Python environment setup (isolated & future-proof) -----
# ------------------------------------------------------------
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python dependencies in the venv
COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# ------------------------------------------------------------
# --- Add the built RISC-V toolchain to PATH -----------------
# ------------------------------------------------------------
COPY --from=riscv-builder /opt/riscv32i /opt/riscv32i
ENV PATH="/opt/riscv32i/bin:${PATH}"

# Optional short alias (quality-of-life)
RUN ln -sf /opt/riscv32i/bin/riscv32-unknown-elf-gcc /usr/local/bin/riscv-gcc

# ------------------------------------------------------------
# --- Create non-root dev user for VSCode devcontainer -------
# ------------------------------------------------------------
RUN useradd -ms /bin/bash dev
USER dev
WORKDIR /work
