# 🩸 BIGGY NIGHTMARE — Godot 4 FPS Horror

> *"ронен... gg, мальчик... gg..."*

---

## 📁 מבנה הפרויקט

```
biggy-nightmare/
├── project.godot              ← פתח עם Godot 4.3+
├── scripts/
│   ├── Player.gd              ← שחקן FPS + מנגנוני RE9
│   ├── Biggy.gd               ← AI אויב (stalker)
│   ├── GameManager.gd         ← HUD, ווינייט, מוזיקה דינמית
│   ├── Key.gd                 ← פריט מפתח
│   ├── Door.gd                ← דלת יציאה
│   └── CreepyNPC.gd           ← NPC מפחיד (Silent Hill style)
├── assets/
│   └── shaders/
│       └── damage_vignette.gdshader  ← מסך אדום כשנפגעים
└── scenes/
    └── Main.tscn              ← סצנה ראשית (לבנות ב-Godot)
```

---

## 🎮 מקשי שליטה

| מקש | פעולה | למה זה הכי נוח |
|-----|--------|----------------|
| **W A S D** | תנועה | סטנדרט FPS אוניברסלי |
| **עכבר** | הסתכלות | מדויק ומהיר |
| **Shift שמאלי** | ריצה (מרוקן סטמינה) | אצבע קטנה — טבעי |
| **C** | כריעה (stealth) | קרוב ל-WASD |
| **E** | אינטראקט / איסוף | אינדקס — קרוב ל-W |
| **F** | פנס ON/OFF | אמצע — גישה מהירה |
| **Q** | הסתכלות מאחור | שמאל ל-W — רגע בהלה |
| **ESC** | הפסקה / תפריט | סטנדרט |
| **עכבר שמאל** | לחיצה על כפתורים | — |

---

## 🔴 מנגנוני RE9 Requiem שהוטמעו

### 1. מסך אדום כשנפגעים
- **`damage_vignette.gdshader`** — וינייט אדום בשולי המסך
- מתחזק ומתעמעם לפי כמות הנזק
- כולל **chromatic aberration** (עיוות צבע) כשחיים נמוכים מאוד
- פולסציה בקצב דופק הלב

### 2. ידיים רועדות (RE9: Grace Ashcroft mechanic)
- ידי השחקן רועדות כשהאויב קרוב
- מתחזק ככל שה-health יורד
- נראה בהחזקת פנס / חפצים

### 3. מוזיקה דינמית (3 שכבות)
- **Calm** — כשביגי רחוק
- **Tense** — ביגי מתקרב (30-65% danger)
- **Chase** — ביגי צמוד (65%+ danger)
- מעברים חלקים כמו RE9

### 4. Head Bob מותאם
- עוצמה עולה כשנבהלים (RE9: comfort mode)
- תדר שונה בהליכה vs ריצה
- נעצר חלק כשעומדים

### 5. Stamina System
- ריצה מרוקנת סטמינה
- התאוששות אוטומטית
- ביגי מאיץ = לחץ לרוץ = מסוכן

### 6. Ambient Horror Events (RE9 style)
| סוג | תיאור | תדירות |
|-----|--------|---------|
| 🎙️ **סבתא רוסית** | קול + טקסט מפחיד | כל 12-28 שניות |
| 💥 **רעש רחוק** | thud עמוק מחדר סמוך | אקראי |
| 🔦 **פנס נכבה** | 0.6-1.2 שניות חושך | אקראי |
| 👁️ **Jumpscare** | תמונה + צרחה | כל 30-65 שניות |

### 7. AI ביגי — Stalker Mode (כמו "The Girl" ב-RE9)
- **שומע** ריצה מ-9 מטר
- **רואה** מ-16 מטר
- **זוכר** מיקום אחרון (לא מטפש!)
- **מאיץ** ככל שהמרדף מתמשך
- **Rage Mode** אחרי 18 שניות של מרדף

---

## 👤 רשימת דמויות

### 🧍 השחקן (ללא שם — POV)
- גוף: לא נראה (FPS)
- ידיים: כהות, רועדות כשנבהל
- פנס: ספוט לייט לבן, מהבהב כשביגי קרוב
- גובה: 1.8 מ' (capsule collider)
- נשימה: מאיצה עם סכנה

### 👹 BIGGY (האתיופי הגדול)
- גוף: ענק, כהה, מהיר
- פנים: עגולות, עיניים אדומות (צהובות ב-Rage)
- בגדים: חולצה כהה, ג'ינס
- קול: צרחות רוסיות
- Sprite 3D על הפנים (texture: enemy.jpg מהפרויקט המקורי)

### 👁️ ה-NPC המפחיד (ה"ילדה")
- מופיע פתאום בפתחים
- עומד ומסתכל — לא תוקף
- נעלם אחרי 2-3 שניות
- אומר משפטים בסגנון Silent Hill:
  - *"ты видишь меня?"*
  - *"беги."*
  - *"РОНЕН"*

### 👵 הסבתא הרוסית (קולי בלבד)
- **לא נראית** — רק שומעים
- קול: tremolo synth (מדומה בקוד)
- מדברת אל השחקן ישירות:
  - *"ронен... ронен, приди домой..."*
  - *"gg, мальчик... gg..."*
  - *"беги быстрее, глупый..."*

---

## 🛠️ הגדרת הפרויקט ב-Godot 4

### שלב 1 — פתיחה
```
1. פתח Godot 4.3+
2. Import → בחר את תיקיית biggy-nightmare
3. פתח project.godot
```

### שלב 2 — סצנת Player
```
CharacterBody3D (Player.gd)
├── CollisionShape3D (CapsuleShape — height:1.8, radius:0.4)
├── Camera3D
│   ├── SpotLight3D (flashlight — range:12, angle:30)
│   └── HandMesh (MeshInstance3D — hand model)
├── FlickerTimer (Timer — one_shot:false)
├── FootstepPlayer (AudioStreamPlayer3D)
├── BreathPlayer (AudioStreamPlayer3D)
└── HeartbeatPlayer (AudioStreamPlayer3D)
```

### שלב 3 — סצנת Biggy
```
CharacterBody3D (Biggy.gd)
├── CollisionShape3D (CapsuleShape)
├── NavigationAgent3D
├── SpeechBubble (Node3D)
│   └── Label3D
├── FaceSprite3D (Sprite3D — enemy.jpg)
├── SpeechTimer (Timer)
├── FootstepAudio (AudioStreamPlayer3D)
└── GrowlAudio (AudioStreamPlayer3D)
```

### שלב 4 — סצנת HUD (CanvasLayer)
```
CanvasLayer
├── DamageVignette (ColorRect — full screen, shader: damage_vignette.gdshader)
├── DangerVignette (ColorRect — red edges)
├── WhiteFlash (ColorRect — white, full screen)
├── HealthBar (ProgressBar — bottom left)
├── StaminaBar (ProgressBar — under health)
├── KeyLabel (Label — top center)
├── ObjectiveLabel (Label — bottom left)
├── InteractLabel (Label — center bottom)
├── GrandmaLabel (Label — bottom right, italic)
├── JumpscareOverlay (Control)
│   ├── JumpscareImage (TextureRect — jumpscare.jpg)
│   └── Label (Creepster font, huge)
├── GameOverScreen (Control)
└── WinScreen (Control)
```

### שלב 5 — קבצי אודיו נדרשים
```
assets/audio/
├── footstep_concrete.ogg    ← freesound.org — "footstep hospital"
├── breath_fast.ogg          ← freesound.org — "breathing scared"
├── heartbeat.ogg            ← freesound.org — "heartbeat loop"
├── jumpscare_screech.ogg    ← freesound.org — "jumpscare scream"
├── grandma_voice.ogg        ← *(אופציונלי — ElevenLabs TTS)*
├── ambient_thud.ogg         ← freesound.org — "distant thud horror"
├── key_collect.ogg          ← freesound.org — "item pickup"
├── door_creak.ogg           ← freesound.org — "door creak"
├── music_calm.ogg           ← freesound.org — "horror ambient drone"
├── music_tense.ogg          ← freesound.org — "horror tension loop"
└── music_chase.ogg          ← freesound.org — "horror chase music"
```

---

## 🎯 GitHub — הוספה לפרויקט קיים

```bash
# ב-terminal / Git Bash:
cd hospital-horror          # תיקיית הפרויקט הקיים
mkdir -p project/scripts project/assets/shaders

# העתק את כל הסקריפטים החדשים לתוך הפרויקט
cp biggy-fps/scripts/*.gd project/scripts/
cp biggy-fps/assets/shaders/*.gdshader project/assets/shaders/
cp biggy-fps/project.godot project/project.godot

git add .
git commit -m "feat: RE9-inspired FPS horror — damage vignette, Biggy AI, ambient events"
git push
```

---

## 📐 מפת החדרים (hospital layout)

```
┌──────────────┬──────────┬──────────────┐
│   WARD A     │ SURGERY  │     ICU      │
│  (spawn)     │          │   (key #2)   │
├──────┬───────┴──┬───────┴──────────────┤
│      │          │         X-RAY        │
│MORGU │   LAB    │       (key #3)       │
│E     │ (key #1) │                      │
│      │          ├──────────────────────┤
├──────┴──────────┤    EXIT HALL         │
│    STORAGE      │   🚪 ← EXIT DOOR    │
│                 │   (needs 3 keys)     │
├─────────────────┤                      │
│     CHAPEL      ├──────────────────────┘
│   (Biggy spawn) │
└─────────────────┘
```

---

*Built with Godot 4.3 • Inspired by Resident Evil Requiem (2026)*
*"BIGGY NUMBER ONE!!!" — BIGGY, 2026*
