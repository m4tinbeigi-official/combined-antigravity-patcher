<!-- DevSponsors Badges -->
<p align="center">
  <a href="https://devsponsors.github.io"><img src="https://img.shields.io/badge/DevSponsors-Verified_OSS-6366f1?style=for-the-badge&logo=github" alt="DevSponsors Verified"></a>
  <a href="https://devsponsors.github.io"><img src="https://img.shields.io/badge/Sponsor-DevSponsors_Hub-emerald?style=for-the-badge&logo=github-sponsors" alt="DevSponsors Sponsor"></a>
  <a href="https://devsponsors.github.io/mediakit.html"><img src="https://img.shields.io/badge/Infrastructure-DevSponsors_Cloud-ec4899?style=for-the-badge&logo=server" alt="DevSponsors Cloud"></a>
</p>

# Combined Antigravity Patcher

> **یک اسکریپت واحد و مستقل برای رفع مشکل Authorization و حذف محدودیت‌های جغرافیایی در Google Antigravity**

این ریپازیتوری مجموعه‌ای از **اسکریپت‌های PowerShell مستقل (Self-contained)** برای **macOS** و **Windows** ارائه می‌دهد که به‌صورت خودکار دو پچ جامعه‌ای Antigravity را اعمال می‌کنند:

1. **antigravity‑patch** – رفع مشکل Authorization برای کاربرانی که پشت پروکسی هستند.
2. **open‑antigravity‑patcher** – حذف محدودیت‌های جغرافیایی (مثلاً برای کاربران در ایران یا روسیه).

---

## ✨ ویژگی‌ها

- 🔄 **ترکیب دو پچ** در یک اسکریپت واحد
- 💻 **پشتیبانی کامل از macOS و Windows** با اسکریپت‌های مجزا
- 🛡️ **بدون جمع‌آوری داده** – بدون تله‌متری، بدون آنالیتیکس
- 🔙 **قابلیت بازگردانی** – بازگشت به حالت اولیه با اجرای اسکریپت Uninstall
- 📦 **دانلود خودکار** آخرین نسخه از مخازن اصلی
- 🍺 **نصب خودکار وابستگی‌ها** (مانند Homebrew و Wine در مک)
- 🎨 **خروجی رنگی و خوانا** با نمایش وضعیت هر مرحله

---

## 📋 پیش‌نیازها

### برای کاربران macOS:
| ابزار | توضیح |
|-------|-------|
| macOS 12+ | سیستم‌عامل هدف |
| PowerShell 7+ | نصب با `brew install --cask powershell` |
| Homebrew | مدیریت بسته‌ها (در صورت نیاز اسکریپت خودکار نصب می‌کند) |
| Wine | جهت اجرای پچ ویندوزی (در صورت نیاز اسکریپت خودکار نصب می‌کند) |

### برای کاربران Windows:
| ابزار | توضیح |
|-------|-------|
| Windows 10/11 | سیستم‌عامل هدف |
| PowerShell 5+ | به‌صورت پیش‌فرض روی ویندوز نصب است |

---

## 🚀 نحوه استفاده

### سیستم‌عامل macOS (مک)
برای اجرای پچ‌ها، ترمینال را باز کرده و یکی از حالت‌های زیر را اجرا کنید:

```powershell
# ۱. نصب کامل (هر دو پچ ورود و ریجن)
pwsh ./install-antigravity-patch.ps1

# ۲. فقط پچ ریجن (بایپس محدودیت جغرافیایی)
pwsh ./install-antigravity-patch.ps1 -RegionOnly

# ۳. فقط پچ احراز هویت (ورود/پروکسی)
pwsh ./install-antigravity-patch.ps1 -AuthOnly
```

برای لغو پچ‌ها و بازگردانی به حالت اول:
```powershell
pwsh ./uninstall-antigravity-patch.ps1
```

### سیستم‌عامل Windows (ویندوز)
**مهم:** ابتدا PowerShell را در حالت **Run as Administrator** (اجرا به عنوان مدیر) باز کنید.
سپس یکی از حالت‌های زیر را اجرا کنید:

```powershell
# اجازه اجرای اسکریپت‌های محلی
Set-ExecutionPolicy Bypass -Scope Process -Force

# ۱. نصب کامل (هر دو پچ ورود و ریجن)
pwsh ./install-antigravity-patch-windows.ps1

# ۲. فقط پچ ریجن (بایپس محدودیت جغرافیایی)
pwsh ./install-antigravity-patch-windows.ps1 -RegionOnly

# ۳. فقط پچ احراز هویت (ورود/پروکسی)
pwsh ./install-antigravity-patch-windows.ps1 -AuthOnly
```

برای لغو پچ‌ها و بازگردانی به حالت اول در ویندوز:
```powershell
pwsh ./uninstall-antigravity-patch-windows.ps1
```

---

## 🔧 مراحل کار اسکریپت‌ها

```
┌─────────────────────────────────────────┐
│  1. بررسی محیط (سازگاری سیستم‌عامل)      │
├─────────────────────────────────────────┤
│  2. بررسی و نصب وابستگی‌ها (مخصوص مک)    │
├─────────────────────────────────────────┤
│  3. پشتیبان‌گیری از فایل‌های اصلی       │
├─────────────────────────────────────────┤
│  4. پچ ۱: antigravity‑patch            │
│     ↳ دانلود version.dll               │
│     ↳ کپی به مسیر نصب Antigravity      │
├─────────────────────────────────────────┤
│  5. پچ ۲: open‑antigravity‑patcher     │
│     ↳ دانلود Open.AG.Patcher.exe       │
│     ↳ اجرا (مستقیم یا از طریق Wine)    │
├─────────────────────────────────────────┤
│  6. گزارش نتیجه و پاکسازی فایل‌های موقت  │
└─────────────────────────────────────────┘
```

---

## 📁 ساختار پروژه

```
combined-antigravity-patcher/
├── README.md                           # این فایل راهنما
├── LICENSE                             # مجوز MIT
├── install-antigravity-patch.ps1       # اسکریپت نصب مخصوص مک
├── uninstall-antigravity-patch.ps1     # اسکریپت حذف مخصوص مک
├── install-antigravity-patch-windows.ps1 # اسکریپت نصب مخصوص ویندوز
├── uninstall-antigravity-patch-windows.ps1 # اسکریپت حذف مخصوص ویندوز
└── docs/
    ├── index.html                      # صفحه فرود GitHub Pages
    └── hero.jpg                        # تصویر هدر پروژه
```

---

## 🌐 نحوه راه‌اندازی GitHub Pages
برای فعال‌سازی صفحه وب اختصاصی این پروژه روی گیتهاب:
1. پروژه را به اکانت گیت‌هاب خود push کنید.
2. در تنظیمات مخزن (Repository Settings) به بخش **Pages** بروید.
3. در بخش Build and deployment، منبع (Source) را روی **Deploy from a branch** بگذارید.
4. شاخه اصلی (main یا master) را انتخاب کرده و پوشه را روی `/docs` تنظیم کنید.
5. دکمه **Save** را بزنید. صفحه شما پس از چند دقیقه در دسترس خواهد بود.

---

## ⚠️ هشدارها

> [!WARNING]
> این اسکریپت فایل‌های باینری Antigravity را تغییر می‌دهد. اسکریپت به‌صورت خودکار پشتیبان‌گیری می‌کند، اما حتماً قبل از اجرا احتیاط لازم را داشته باشید.

> [!CAUTION]
> استفاده از پچ‌ها برای دور زدن محدودیت‌های نرم‌افزاری ممکن است **شرایط استفاده از سرویس Antigravity را نقض کند**. مسئولیت استفاده بر عهدهٔ خود کاربر است.

---

## 🙏 اعتبارات و منابع الهام

این پروژه بدون تلاش‌ها و زحمات سازندگان دو پروژهٔ اصلی ممکن نبود:

| پروژه | سازنده | توضیح | لینک |
|-------|--------|-------|------|
| **antigravity‑patch** | kakajan | رفع مشکل Authorization پشت پروکسی | [GitHub](https://github.com/kakajan/antigravity-patch) |
| **open‑antigravity‑patcher** | AvenCores | حذف محدودیت‌های جغرافیایی | [GitHub](https://github.com/AvenCores/open-antigravity-patcher) |

---

## 📄 مجوز

اسکریپت‌های این ریپازیتوری تحت **مجوز MIT** منتشر شده‌اند. پچ‌های اصلی تحت مجوزهای خود منتشر شده‌اند؛ برای جزئیات به ریپازیتوری‌های مربوطه مراجعه کنید.
