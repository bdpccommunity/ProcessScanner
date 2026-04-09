# Process Security Scanner
## EXE বানানোর নির্দেশাবলী

### ফাইলগুলো কী কী:
- `ProcessScanner.ps1` → মূল script (API key input box সহ)
- `Build_EXE.bat` → স্বয়ংক্রিয়ভাবে EXE বানাবে
- `README.md` → এই ফাইল

---

## ✅ EXE বানানোর সহজ পদ্ধতি

### পদ্ধতি ১ — Build_EXE.bat দিয়ে (সবচেয়ে সহজ)
1. `Build_EXE.bat` ফাইলে **Right Click → Run as Administrator**
2. এটি নিজেই `ps2exe` install করবে এবং EXE বানাবে
3. একই ফোল্ডারে `ProcessScanner.exe` তৈরি হবে

---

### পদ্ধতি ২ — নিজে PowerShell দিয়ে
PowerShell **Admin** হিসেবে খুলুন এবং চালান:

```powershell
# ধাপ ১: ps2exe install করুন
Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber

# ধাপ ২: EXE বানান
Invoke-ps2exe -InputFile "ProcessScanner.ps1" -OutputFile "ProcessScanner.exe" -RequireAdmin
```

---

## 🔧 Tool কীভাবে কাজ করে

1. **`ProcessScanner.exe`** চালু করুন
2. একটি **API Key Input Box** আসবে
3. আপনার **VirusTotal API Key** দিন
   - Free API Key পেতে: https://www.virustotal.com (Register করুন)
4. **"SCAN শুরু করুন"** বাটনে ক্লিক করুন
5. Console এ সব result দেখাবে
6. Scan শেষে একটি **Summary popup** আসবে
7. Log file স্বয়ংক্রিয়ভাবে save হবে

---

## ⚠️ গুরুত্বপূর্ণ নোট

- **Admin হিসেবে run করুন** — বেশি process দেখা যাবে
- VirusTotal Free API তে **rate limit** আছে (4 req/min)
- Log file একই ফোল্ডারে `ProcessScan_DATE_TIME.log` নামে save হয়

---

## 🔑 API Key কোথায় পাবেন

1. https://www.virustotal.com যান
2. Free account খুলুন
3. Profile → API Key থেকে copy করুন
