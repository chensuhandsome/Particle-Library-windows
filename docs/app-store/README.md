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

1. Create the non-consumable Supporter product in App Store Connect.
2. Host the privacy policy at a public URL.
3. Capture the required screenshot sizes.
4. Verify that Settings → About no longer links to GitHub updates on iOS.
5. Complete App Privacy as “Data Not Collected” unless you add a service that
   changes that answer.
