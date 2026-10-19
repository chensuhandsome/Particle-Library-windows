# App Store package

- [Metadata](METADATA.md)
- [Screenshots](SCREENSHOTS.md)
- [Privacy policy](PRIVACY.md)
- [App Review notes](REVIEW_NOTES.md)

Build the iOS App Store binary with the App Store product ID so the app can
offer an “Open the App Store” action (never a GitHub download):

```bash
flutter build ipa --release \
  --dart-define=APP_STORE_APP_ID=<your Apple ID>
```

Before submission:

1. Host the privacy policy at a public URL.
2. Capture the required screenshot sizes.
3. Verify that Settings → About no longer links to GitHub updates on iOS.
4. Complete App Privacy as “Data Not Collected”; the project does not plan to
   add analytics or account services.
