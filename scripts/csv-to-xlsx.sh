#!/usr/bin/env bash

# convert_csv_to_xlsx.sh
# Usage:
#   ./convert_csv_to_xlsx.sh /path/to/folder
#   ./convert_csv_to_xlsx.sh /path/to/file.csv

set -euo pipefail

# ── argument validation ───────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
  echo "ERROR: No path provided." >&2
  echo "Usage: $0 <folder|file.csv>" >&2
  exit 1
fi

TARGET="$1"

if [[ ! -e "$TARGET" ]]; then
  echo "ERROR: Path does not exist: $TARGET" >&2
  exit 1
fi

target_lower="$(printf '%s' "$TARGET" | tr '[:upper:]' '[:lower:]')"
if [[ -f "$TARGET" && "$target_lower" != *.csv ]]; then
  echo "ERROR: File is not a CSV: $TARGET" >&2
  exit 1
fi

if [[ ! -f "$TARGET" && ! -d "$TARGET" ]]; then
  echo "ERROR: Path is neither a file nor a directory: $TARGET" >&2
  exit 1
fi

# ── dependency check ──────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 is required but not found." >&2
  exit 1
fi

run_with_privilege() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null; then
    sudo "$@"
  else
    echo "ERROR: Need root privileges to install packages, but 'sudo' is not available." >&2
    return 1
  fi
}

# Install openpyxl if missing
if ! python3 -c "import openpyxl" 2>/dev/null; then
  echo "Installing openpyxl…"
  if [[ "$(uname)" == "Darwin" ]]; then
    python3 -m pip install --user openpyxl
  elif command -v pacman &>/dev/null; then
    run_with_privilege pacman -S --needed --noconfirm python-openpyxl
  elif command -v apt-get &>/dev/null; then
    run_with_privilege apt-get install -y -qq python3-openpyxl
  elif command -v apt &>/dev/null; then
    run_with_privilege apt install -y -qq python3-openpyxl
  else
    echo "ERROR: Cannot install openpyxl automatically. Please run one of:" >&2
    echo "  python3 -m pip install --user openpyxl" >&2
    echo "  sudo pacman -S --needed python-openpyxl" >&2
    echo "  sudo apt install python3-openpyxl" >&2
    exit 1
  fi
  if ! python3 -c "import openpyxl" 2>/dev/null; then
    echo "ERROR: openpyxl installation failed." >&2
    exit 1
  fi
  echo "openpyxl installed successfully."
fi

# ── Python converter (inline) ─────────────────────────────────────────────────
CONVERTER=$(cat <<'PYEOF'
import sys, csv, openpyxl
from openpyxl.styles import Font, Alignment

csv_path  = sys.argv[1]
xlsx_path = sys.argv[2]

# ── detect encoding ──────────────────────────────────────────────────────────
encodings = ["utf-8-sig", "utf-8", "cp1256", "iso-8859-6"]
raw_text = None
for enc in encodings:
    try:
        with open(csv_path, encoding=enc) as f:
            raw_text = f.read()
        break
    except (UnicodeDecodeError, LookupError):
        continue

if raw_text is None:
    print(f"  SKIP (could not decode): {csv_path}", file=sys.stderr)
    sys.exit(1)

# ── detect delimiter ─────────────────────────────────────────────────────────
try:
    dialect = csv.Sniffer().sniff(raw_text[:4096], delimiters=',\t;|')
    delimiter = dialect.delimiter
except csv.Error:
    delimiter = ','

# ── parse CSV ────────────────────────────────────────────────────────────────
import io
rows = list(csv.reader(io.StringIO(raw_text), delimiter=delimiter))

# ── build XLSX ───────────────────────────────────────────────────────────────
wb = openpyxl.Workbook()
ws = wb.active
ws.sheet_view.rightToLeft = True

for r_idx, row in enumerate(rows, start=1):
    for c_idx, value in enumerate(row, start=1):
        cell = ws.cell(row=r_idx, column=c_idx, value=value)
        cell.font      = Font(name="Arial", size=11)
        cell.alignment = Alignment(
            horizontal="right",
            vertical="center",
            wrap_text=True
        )

for col in ws.columns:
    max_len = max((len(str(c.value or "")) for c in col), default=10)
    ws.column_dimensions[col[0].column_letter].width = min(max_len + 4, 60)

wb.save(xlsx_path)
PYEOF
)

# ── find and convert ──────────────────────────────────────────────────────────
convert_file() {
  local csv_file="$1"
  local xlsx_file="${csv_file%.csv}.xlsx"
  echo "  Converting: $csv_file"
  if python3 -c "$CONVERTER" "$csv_file" "$xlsx_file"; then
    echo "           → $xlsx_file"
    return 0
  else
    echo "  FAILED: $csv_file" >&2
    return 1
  fi
}

CONVERTED=0
FAILED=0

if [[ -f "$TARGET" ]]; then
  # Single file mode
  echo "────────────────────────────────────────"
  if convert_file "$TARGET"; then
    CONVERTED=1
  else
    FAILED=1
  fi
else
  # Directory mode
  echo "Scanning: $TARGET"
  echo "────────────────────────────────────────"
  while IFS= read -r -d '' csv_file; do
    if convert_file "$csv_file"; then
      (( CONVERTED++ )) || true
    else
      (( FAILED++ )) || true
    fi
  done < <(find "$TARGET" -type f -iname "*.csv" -print0)
fi

echo "────────────────────────────────────────"
echo "Done.  Converted: $CONVERTED  |  Failed: $FAILED"
