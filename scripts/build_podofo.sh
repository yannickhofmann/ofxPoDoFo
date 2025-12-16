#!/usr/bin/env bash
# Build static PoDoFo into this addon (linux64 / osx).
# Prereqs: cmake, a C++17 compiler, and system deps
# (zlib, openssl, freetype, fontconfig, libpng, libjpeg, libtiff, libxml2).

set -euo pipefail

# --- Prereq Checks ---

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# ----------------------------
# Linux (Debian/Ubuntu)
# ----------------------------
check_linux_deps() {
	echo "--> Checking Linux dependencies..."
	local missing_deps=()

	declare -A deps
	deps=(
		["libxml2-dev"]="libxml-2.0"
		["libfreetype6-dev"]="freetype2"
		["libfontconfig1-dev"]="fontconfig"
		["libpng-dev"]="libpng"
		["libjpeg-dev"]="libjpeg"
		["libtiff-dev"]="libtiff-4"
		["zlib1g-dev"]="zlib"
		["libssl-dev"]="openssl"
	)

	if ! command_exists pkg-config; then
		echo "Error: 'pkg-config' is not installed." >&2
		exit 1
	fi

	for pkg_name in "${!deps[@]}"; do
		pc_file="${deps[$pkg_name]}"
		if ! pkg-config --exists "${pc_file}"; then
			missing_deps+=("${pkg_name}")
		fi
	done

	if [ ${#missing_deps[@]} -gt 0 ]; then
		echo "Error: Missing required system libraries:" >&2
		echo "  sudo apt-get install ${missing_deps[*]}" >&2
		exit 1
	fi

	echo "--> All Linux dependencies are met."
}

# ----------------------------
# macOS (Homebrew)
# ----------------------------
check_osx_deps() {
	echo "--> Checking macOS dependencies..."

	if ! command_exists brew; then
		echo "Error: Homebrew is not installed." >&2
		echo "  See: https://brew.sh/" >&2
		exit 1
	fi

	local missing_deps=()
	local deps=(
		libxml2
		freetype
		fontconfig
		libpng
		jpeg
		libtiff
		openssl@3
	)

	for dep in "${deps[@]}"; do
		if ! brew list "$dep" >/dev/null 2>&1; then
			missing_deps+=("$dep")
		fi
	done

	if [ ${#missing_deps[@]} -gt 0 ]; then
		echo "Error: Missing required Homebrew packages:" >&2
		echo "  brew install ${missing_deps[*]}" >&2
		exit 1
	fi

	echo "--> All macOS dependencies are met."
}

# ----------------------------
# Platform detection
# ----------------------------
VERSION="${PODOFO_VERSION:-1.0.3}"
ADDON_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="${ADDON_ROOT}/scripts/podofo_src"

unameOut="$(uname -s)"
case "${unameOut}" in
	Darwin*)
		ARCH="osx"
		check_osx_deps
		;;
	Linux*)
		ARCH="linux64"
		check_linux_deps
		;;
	*)
		echo "Unsupported platform: ${unameOut}" >&2
		exit 1
		;;
esac

# ----------------------------
# Paths & URLs
# ----------------------------
URL="https://github.com/podofo/podofo/archive/refs/tags/${VERSION}.tar.gz"
TARBALL="${SRC_ROOT}/podofo-${VERSION}.tar.gz"
SRC_DIR="${SRC_ROOT}/podofo-${VERSION}"
BUILD_DIR="${SRC_ROOT}/build-${ARCH}"
INSTALL_DIR="${ADDON_ROOT}/libs/PoDoFo/install/${ARCH}"

mkdir -p "${SRC_ROOT}"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# ----------------------------
# Fetch source
# ----------------------------
echo "==> Fetching PoDoFo ${VERSION}"
if [[ ! -f "${TARBALL}" ]]; then
	curl -L "${URL}" -o "${TARBALL}"
fi

rm -rf "${SRC_DIR}"
tar -xzf "${TARBALL}" -C "${SRC_ROOT}"

if [ "${ARCH}" = "osx" ]; then
	echo "==> Applying patches for osx"
	patch -p1 -d "${SRC_DIR}" <<'EOF'
--- a/src/podofo/private/charconv_compat.h
+++ b/src/podofo/private/charconv_compat.h
@@ -65,7 +65,8 @@
 
 #ifdef WANT_TO_CHARS
 
-namespace std
+namespace std {
+namespace compat
 {
     inline to_chars_result to_chars(char* first, char* last,
         double value, chars_format fmt, int precision) noexcept
@@ -94,6 +95,7 @@
             return to_chars_result{ first + ret.size, errc{} };
     }
 }
+}
 
 #endif // WANT_TO_CHARS
 
--- a/src/podofo/private/PdfDeclarationsPrivate.cpp
+++ b/src/podofo/private/PdfDeclarationsPrivate.cpp
@@ -1344,21 +1344,21 @@
     // The default size should be large enough to format all
     // numbers with fixed notation. See https://stackoverflow.com/a/52045523/213871
     str.resize(FloatFormatDefaultSize);
-    auto result = std::to_chars(str.data(), str.data() + FloatFormatDefaultSize, value, chars_format::fixed, precision);
+    auto result = std::compat::to_chars(str.data(), str.data() + FloatFormatDefaultSize, value, chars_format::fixed, precision);
     removeTrailingZeroes(str, result.ptr - str.data());
 }
 
 void utls::FormatTo(string& str, double value, unsigned short precision)
 {
     str.resize(FloatFormatDefaultSize);
-    auto result = std::to_chars(str.data(), str.data() + FloatFormatDefaultSize, value, chars_format::fixed, precision);
+    auto result = std::compat::to_chars(str.data(), str.data() + FloatFormatDefaultSize, value, chars_format::fixed, precision);
     if (result.ec == errc::value_too_large)
     {
         // See https://stackoverflow.com/a/52045523/213871
         // 24 recommended - 5 (unnecessary) exponent = 19
         constexpr unsigned DoubleFormatDefaultSize = 19;
         str.resize(DoubleFormatDefaultSize);
-        result = std::to_chars(str.data(), str.data() + DoubleFormatDefaultSize, value, chars_format::fixed, precision);
+        result = std::compat::to_chars(str.data(), str.data() + DoubleFormatDefaultSize, value, chars_format::fixed, precision);
     }
     removeTrailingZeroes(str, result.ptr - str.data());
 }
EOF
fi

# ----------------------------
# Configure
# ----------------------------
echo "==> Configuring (arch: ${ARCH})"
cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" \
	-DCMAKE_BUILD_TYPE=Release \
	-DPODOFO_BUILD_STATIC=ON \
	-DPODOFO_BUILD_EXAMPLES=OFF \
	-DPODOFO_BUILD_TEST=OFF \
	-DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
	-DCMAKE_OSX_DEPLOYMENT_TARGET=13.2

# ----------------------------
# Build & install
# ----------------------------
echo "==> Building"
cmake --build "${BUILD_DIR}" \
	--config Release \
	--target install \
	-- -j"$(getconf _NPROCESSORS_ONLN || echo 4)"

# ----------------------------
# Stage headers & libs
# ----------------------------
echo "==> Staging headers and libraries"
INSTALL_INCLUDE="${INSTALL_DIR}/include"
INSTALL_LIB="${INSTALL_DIR}/lib"
DEST_INCLUDE="${ADDON_ROOT}/libs/PoDoFo/include"
DEST_LIB="${ADDON_ROOT}/libs/PoDoFo/lib/${ARCH}"

mkdir -p "${DEST_LIB}"

rm -rf "${DEST_INCLUDE}"
cp -R "${INSTALL_INCLUDE}" "${DEST_INCLUDE}"

find "${DEST_LIB}" -maxdepth 1 -type f -name 'libpodofo*' -delete || true
cp "${INSTALL_LIB}"/libpodofo*.a "${DEST_LIB}/"

# ----------------------------
# Cleanup
# ----------------------------
echo "==> Cleaning up build files"
rm -rf "${SRC_ROOT}"

echo "==> Done. Libraries staged in ${DEST_LIB}"