# 🩸 BIGGY NIGHTMARE — הוראות העלאה ל-GitHub

---

## שלב 1 — התקן Git (אם אין לך)

הורד מ: https://git-scm.com/download/win
התקן עם כל הגדרות ברירת המחדל.

---

## שלב 2 — צור חשבון GitHub

1. לך ל: https://github.com
2. לחץ **Sign up**
3. צור חשבון חינמי

---

## שלב 3 — צור Repository חדש

1. לאחר הכניסה, לחץ על **+** למעלה ← **New repository**
2. **Repository name:** `biggy-nightmare`
3. **Description:** `🩸 FPS Horror Game in Godot 4`
4. בחר **Public** (ציבורי, בחינם)
5. **אל תסמן** את "Add a README file"
6. לחץ **Create repository**

---

## שלב 4 — הורד את קבצי הפרויקט

הורד את ה-ZIP מהצ'אט ← חלץ לתיקייה בשם `biggy-nightmare`

---

## שלב 5 — העלה ל-GitHub (2 אפשרויות)

### אפשרות א׳ — דרך אתר GitHub (הכי קל!)

1. נכנס לרפוזיטורי החדש שלך
2. לחץ על **uploading an existing file**
3. גרור את כל הקבצים מתוך תיקיית `biggy-nightmare`
4. למטה כתוב: `Initial commit — Biggy Nightmare FPS`
5. לחץ **Commit changes**

### אפשרות ב׳ — דרך Terminal / Git Bash

```bash
# פתח Git Bash בתיקיית הפרויקט
cd C:/path/to/biggy-nightmare

# אתחל Git
git init
git add .
git commit -m "Initial commit — Biggy Nightmare FPS Horror"

# חבר לGitHub (החלף YOUR_USERNAME בשם שלך)
git remote add origin https://github.com/YOUR_USERNAME/biggy-nightmare.git
git branch -M main
git push -u origin main
```

---

## שלב 6 — פתיחה ב-Godot

1. הורד Godot 4.3: https://godotengine.org/download
2. פתח Godot ← **Import**
3. בחר את קובץ `project/project.godot`
4. לחץ **Import & Edit**

---

## מבנה תיקיות שצריך להיות ב-GitHub

```
biggy-nightmare/
├── .github/
│   └── workflows/
│       └── build.yml          ← בניה אוטומטית
├── project/
│   ├── project.godot          ← קובץ הפרויקט הראשי
│   ├── export_presets.cfg
│   ├── scripts/
│   │   ├── Player.gd
│   │   ├── Biggy.gd
│   │   ├── GameManager.gd
│   │   ├── Key.gd
│   │   ├── Door.gd
│   │   └── CreepyNPC.gd
│   └── assets/
│       └── shaders/
│           └── damage_vignette.gdshader
├── .gitignore
└── README.md
```

---

## שלב 7 — בדוק שהפרויקט עלה

לך ל: `https://github.com/YOUR_USERNAME/biggy-nightmare`

אתה אמור לראות את כל הקבצים שם! ✅

---

## טיפים נוספים

- כל פעם שתשנה קוד, עשה `git add . && git commit -m "תיאור שינוי" && git push`
- הקבצים `*.ogg` (אודיו) — העלה אותם לתיקייה `project/assets/audio/`
- ניתן לשתף את הלינק עם חברים כדי שיוכלו לראות את הקוד
