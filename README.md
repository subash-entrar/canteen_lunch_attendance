# Canteen Lunch Attendance

Android Flutter app for RUH school canteen lunch attendance.

## Flow

```
Splash → Home
  ├── Attendance (today)
  │     ├── Load students → get_student_list.php
  │     ├── NFC scan OR tap student → mark_lunch_attendance.php
  │     └── On success → update local is_lunch_attended (no reload)
  └── Reports
        ├── Monthly → get_monthly_lunch_report.php
        └── Daily detail → get_daily_lunch_report.php
```

## Stack

- Provider state management
- Dio HTTP (`application/x-www-form-urlencoded`)
- `flutter_nfc_kit` for NFC
- RUH theme (navy / yellow / teal)

## API base

`https://entrar.in/RUHCTNAa8024205482ca3a9ccd5838d2acefd/`

## Run

```bash
cd canteen_lunch_attendance
flutter pub get
flutter run
```

## Notes

- No login — splash routes straight to home
- Marking is for **today only**
- Marking is one-way (no unmark)
- NFC payload matched against `student_id` or `admission_no` in the loaded list
- Success feedback: vibration + beep + toast
