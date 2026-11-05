# icondia — Image Registration iPhone app

A SwiftUI iPhone app for completing the Guernsey Intellectual Property Office
**"Application to register an image" (form IR)** on your phone.

## Fields captured (same numbering as the paper form)

| # | Field | Required |
|---|-------|----------|
| 1 | Registration/application no. of personality | ✅ |
| 2 | Name of personality | ✅ |
| 3 | Complex image / Series image | — |
| 4 | Number of images to be registered | ✅ (must match images attached) |
| 5 | Number in series (if series image) | ✅ if series |
| 6 | Full name of proprietor | ✅ |
| 7 | Address of proprietor (including postcode) | ✅ |
| 8 | If a company, where incorporated | — |
| 9 | Name of agent / agent ref number | — |
| 10 | Signature of applicant (drawn with finger) | ✅ |
| 11 | Date of signature (not in the future) | ✅ |
| 12 | Your reference | optional |
| — | Image(s) to register (from Photos) | ✅ |
| — | Number of sheets attached | — |
| — | "I have completed all of the above" checklist | ✅ |

The declarations and completion checklist text from the form are shown in the app.

## What it does

- Saves your progress automatically on the device (encrypted at rest via iOS file protection).
- **Review & Submit** lists anything still missing, then builds an A4 PDF laid out like
  the IR form, with each attached image on its own page.
- Email the PDF straight to `ipo@guernseyregistry.com`, or share/save it via the share sheet.

## Building in Xcode

Requires **Xcode 16 or later** and iOS 17+.

1. Open `ImageRegistration.xcodeproj`.
2. Select the **ImageRegistration** target → *Signing & Capabilities* → choose your Team,
   and change the bundle identifier from `com.example.ImageRegistration` to your own.
3. Pick an iPhone simulator or device and press **Run** (⌘R).

The `ImageRegistration/` folder is a synchronized folder, so new Swift files you add
there are picked up automatically.

## Project layout

```
ImageRegistration/
  ImageRegistrationApp.swift          App entry point
  Models/ImageRegistrationApplication.swift   Form fields + validation
  Services/DraftStore.swift           Auto-saves the draft to disk
  Services/ApplicationPDFRenderer.swift  Builds the submission PDF
  Services/MailComposer.swift         Email to the IPO
  Views/ApplicationFormView.swift     The form screen
  Views/ReviewView.swift              Validation, PDF and submit
  Views/SignaturePad.swift            Finger signature capture
```

## Notes

- Payment of the filing fee isn't handled in the app; follow the IPO fee schedule.
- Add a 1024×1024 PNG to `Assets.xcassets/AppIcon` before shipping.
