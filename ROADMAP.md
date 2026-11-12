# BabyDaily — Product Roadmap & Competitive Feature Plan (v1.2.0)

## Benchmark Overview (vs. Huckleberry, Nara Baby, Cubtale, Solid Starts, Glow Baby)

| Feature Area | Previous (`v0.1.7+8`) | Released (`v1.2.0`) |
| :--- | :--- | :--- |
| **Sleep & Wake Windows** | Live Sleep Ticker, Age-Bracket Sweet-Spot Wake Windows, Native Phone Alarms | + Built-in White Noise / Lullaby Player, Auto-Adjusting Multi-Nap Schedule Builder |
| **Feeding & Nutrition** | Nursing Timers, Bottle (ml/oz), Basic Solids | + **Pumping Dual Timer**, **Fridge/Freezer Milk Stash Inventory**, **100 First Foods & Top 9 Allergen Tracker** |
| **AI & Hands-Free** | DeepSeek AI Routine Advisor, Daily Email Digest | + **Voice / Natural Language Logging** (*"Liam drank 150ml 20m ago"*), Shift Handoff Summary |
| **Growth & Health** | Weight, Height, Head logs, Medicine & Vaccine tag | + **Interactive WHO Growth Percentile Curves**, Pediatrician Visit Pack & Vaccine Checklist |
| **Milestones & Activities** | Notes & Photo attachments | + **Tummy Time Goal Ring**, Activity Timer (Bath, Walk), **CDC/WHO Milestones & Mental Leaps** |
| **Mobile & Web Experience** | Material 3 Pastel UI, Swipe Timeline, 4 Languages (EN, HE, RU, ES) | + **3 AM Red-Light Night-Shift Mode**, Caregiver Shift Handoff Card |

---

## Version 1.2.0 Checklist (Sprint 1.2.0 — Completed)

- [x] **1. [AL-116] Pumping & Breast Milk Stash Manager (`PUMP` + `MilkStash`)**
  - Dual Left/Right pumping timer and volume log (`leftMl`, `rightMl`, `totalMl`).
  - Fridge (4-day) and Freezer (6-month) milk bag inventory with expiration alerts and FIFO bottle deduction (`GET /babies/:babyId/milk-stash`, `POST /babies/:babyId/milk-stash/:entryId/consume`).
- [x] **2. [AL-117] 100 First Foods & Allergen Reaction Tracker**
  - Interactive checklist of 100 nutritious first foods before age 1 (`GET /babies/:babyId/solids-summary`).
  - Top 9 allergens tracker (Egg, Dairy, Peanut, Tree Nuts, Soy, Wheat, Fish, Shellfish, Sesame) with reaction severity and preference badges (`loved`, `neutral`, `disliked`).
- [x] **3. [AL-118] Tummy Time, Activities & Developmental Milestones (`ACTIVITY` + `Milestone`)**
  - Stopwatch and daily goal ring for Tummy Time, Bath, Story Time, Skin-to-Skin, and Outdoor Walks (`GET /babies/:babyId/milestones`).
  - Age-calibrated CDC/WHO milestone checklist & developmental leap alerts with photo memories.
- [x] **4. [AL-119] Interactive WHO Growth Percentile Curves & Doctor Visit Pack**
  - Visual WHO 3rd–97th percentile curves for Weight, Height, and Head Circumference (`GET /babies/:babyId/growth-percentiles`).
  - Immunization schedule checklist (`HepB`, `DTaP`, `RV`, `PCV13`, `IPV`, `MMR`).
- [x] **5. [AL-120] Hands-Free AI Voice & Natural Language Logging**
  - Speak or type natural sentences (e.g., *"Liam drank 150ml formula 20m ago and had a wet diaper"*) to auto-create structured timeline entries (`POST /babies/:babyId/ai/parse-entry`).
- [x] **6. [AL-121] Built-In Soothing White Noise & Sleep Sound Machine**
  - Web Audio synthesizer player (White Noise, Pink Rain, Womb Heartbeat) built directly into the Dashboard.
- [x] **7. [AL-122] 3 AM Red-Light Night-Shift Mode & Caregiver Shift Handoff Card**
  - 1-Tap Caregiver Shift Handoff summary (`GET /babies/:babyId/handoff`) + eye-friendly 3 AM red/amber night-shift mode.
