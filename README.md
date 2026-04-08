# 🔐 File Hash Generator

> Scan any folder and generate **SHA-256 hashes** for all files — saved neatly into a `file_hashes.csv`.  
> Works on **Windows** (`.bat` / `.ps1`) and **Linux/macOS** (`.sh`).

---

## 📌 What It Does

Place the script inside any folder and run it. It will:

- 🔍 **Recursively scan** all files in the folder and subfolders
- 🔑 **Generate SHA-256 hash** for each file
- 📁 **Capture metadata** — file name, relative path, extension, size (MB), created & modified dates (IST)
- 📄 **Export everything** to `file_hashes.csv` in the same folder
- 📊 **Show live progress** while processing

### Output: `file_hashes.csv`

| FileName | RelativePath | Extension | FileSize | DateCreated | DateModified | SHA256Hash |
|----------|-------------|-----------|----------|-------------|--------------|------------|
| report.pdf | docs\report.pdf | .pdf | 2.3456 MB | 08-Apr-2026 10:30 AM | 08-Apr-2026 11:00 AM | `a3f9...` |

---

## 📂 Files

| File | Platform | Tool Used |
|------|----------|-----------|
| `hash_files.bat` | Windows (CMD) | `certutil` + PowerShell for dates |
| `hash_files.ps1` | Windows (PowerShell) | `Get-FileHash` |
| `hash_files.sh` | Linux / macOS | `sha256sum` + `stat` |

---

## 🚀 How to Run

### ✅ Windows — CMD (`.bat`)
1. Copy `hash_files.bat` into your target folder
2. Double-click it  
   **OR** open CMD and run:
   ```cmd
   hash_files.bat
   ```

---

### ✅ Windows — PowerShell (`.ps1`)

**Option 1 — Right-click method:**
> Right-click `hash_files.ps1` → **"Run with PowerShell"**

**Option 2 — Terminal:**
```powershell
powershell -ExecutionPolicy Bypass -File .\hash_files.ps1
```

> ⚠️ If you get a red error about scripts being disabled, see [Troubleshooting → PowerShell Execution Policy](#-powershell-execution-policy-blocked) below.

---

### ✅ Linux / macOS (`.sh`)

1. Copy `hash_files.sh` into your target folder
2. Open terminal in that folder and run:
   ```bash
   bash hash_files.sh
   ```

**Optional — Make it directly executable:**
```bash
chmod +x hash_files.sh
./hash_files.sh
```

---

## 🛠️ Troubleshooting

### 🔴 PowerShell Execution Policy Blocked
**Error:** `cannot be loaded because running scripts is disabled`

**Fix (recommended — temporary):**
```powershell
powershell -ExecutionPolicy Bypass -File .\hash_files.ps1
```

**Fix (permanent — run as Admin):**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### 🔴 Linux: Permission Denied
**Error:** `Permission denied` when running `.sh`

**Fix:**
```bash
chmod +x hash_files.sh
bash hash_files.sh
```

---

### 🔴 Linux: `sha256sum` Not Found (macOS)
macOS uses `shasum` instead. Replace in the script:
```bash
# Change this line:
hash=$(sha256sum "$file" | awk '{print $1}')

# To:
hash=$(shasum -a 256 "$file" | awk '{print $1}')
```

---

### 🔴 Linux: Date Shows `0` (No Birth Time)
Some Linux filesystems (ext4) don't store file creation time.  
The script **automatically falls back** to the last status change time (`ctime`) — no action needed.

---

### 🔴 Windows CMD: Output CSV Is Empty
Make sure you are **not running the `.bat` from a read-only folder** (e.g., `C:\Windows\`).  
Move the script to a regular folder like `C:\Users\YourName\Documents\`.

---

## 💡 Recommendations

- 📁 **Place the script directly in the root folder** you want to scan — it uses its own location as the base directory
- 🔁 **Re-running** the script will **overwrite** the existing `file_hashes.csv` — back it up if needed
- 🚫 The script **automatically skips itself** and the output CSV to avoid recursion
- 🗂️ Works great for **evidence folders, legal document bundles, submission packages, and backups**
- 🕐 All timestamps are captured in **IST (India Standard Time, UTC+5:30)**

---

## ⚙️ Requirements

| Platform | Requirement |
|----------|-------------|
| Windows CMD | Windows 7+ (certutil built-in) |
| Windows PowerShell | PowerShell 5.0+ (pre-installed on Win10/11) |
| Linux | bash, `sha256sum`, `stat`, `awk` (standard on most distros) |
| macOS | bash, `shasum` (use `-a 256` flag) |

---

## 📃 License
MIT — Free to use, modify, and distribute.
