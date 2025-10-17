# ------------------------------------------------------------
# Minimal, portable sim image (amd64/arm64)
# + RISC-V GCC toolchain (rv32i) built from source (newlib)
# + Python venv for cocotb/pytest
# + GHDL (package) and optional GTKWave
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

# Installation target and defaults
ARG PREFIX=/opt/riscv32i
ARG TARGET=riscv32-unknown-elf

# Use all host CPUs by default; allow override: --build-arg MAKE_JOBS=8
ARG MAKE_JOBS
ENV MAKE_JOBS=${MAKE_JOBS:-$(nproc)}
ENV MAKEFLAGS="-pipe"

WORKDIR /tmp

# Shallow clone to speed up & be cache-friendly
RUN git clone --depth=1 https://github.com/riscv-collab/riscv-gnu-toolchain.git

# Fetch only needed submodules (shallow)
RUN cd /tmp/riscv-gnu-toolchain && \
    git submodule update --init --depth=1 gcc binutils newlib

# Configure: RV32I only, newlib, C-only, no multilib, no LTO
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

# Build with retry (helps on intermittent QEMU/IO hiccups)
RUN make -C /build -j"${MAKE_JOBS}" newlib || \
    (echo "Retrying with fewer jobs..." && make -C /build -j"$(( (${MAKE_JOBS} > 1 ? ${MAKE_JOBS} : 2)/2 ))" newlib)

# (Optional) strip binaries to reduce size; ignore failures
RUN find ${PREFIX} -type f -perm -111 -exec strip --strip-unneeded {} + || true


# ============================================================
# ---------------------- Final image -------------------------
# ============================================================
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Core runtime tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    build-essential make git pkg-config \
    ghdl gnat \
    gtkwave \
 && rm -rf /var/lib/apt/lists/*

# Python venv for project tools (cocotb, pytest, etc.)
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python deps (adjust path/filename if needed)
COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# Add the RISC-V toolchain
COPY --from=riscv-builder /opt/riscv32i /opt/riscv32i
ENV PATH="/opt/riscv32i/bin:${PATH}"
RUN ln -sf /opt/riscv32i/bin/riscv32-unknown-elf-gcc /usr/local/bin/riscv-gcc

# Non-root user for Dev Containers
RUN useradd -ms /bin/bash dev
USER dev
WORKDIR /work
