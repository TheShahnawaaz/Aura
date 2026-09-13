# Setting Up Apple Developer ID Signing & Notarization in GitHub Actions

This guide explains how to export your Apple Developer credentials once and add them to your GitHub repository secrets. Once configured, **GitHub Actions will automatically sign, notarize, staple, and publish zero-warning `.dmg` releases** whenever you push a version tag (e.g. `git tag v1.0.0 && git push origin v1.0.0`).

---

## 1. Prerequisites (Paid Apple Developer Account)

You will need:
1. An active **Apple Developer Program** membership ($99/year).
2. A **Developer ID Application** certificate.
3. An **App Store Connect API Key** (or App-Specific Password).

---

## 2. Step 1: Create & Export "Developer ID Application" Certificate

1. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list).
2. Click the **`+`** (Create a Certificate) button.
3. Under **Software**, select **Developer ID Application** and click **Continue**.
4. Upload your Certificate Signing Request (CSR from Keychain Access) and download the generated `.cer` file.
5. Double-click the downloaded `.cer` to install it into your macOS **Keychain Access**.
6. Open **Keychain Access**, find your **Developer ID Application: Your Name (TEAMID)** certificate:
   - Expand it to ensure the private key is attached underneath.
   - Right-click the certificate and select **Export "Developer ID Application..."**.
   - Choose format **Personal Information Exchange (.p12)**.
   - Set a strong password (remember this password for `APPLE_CERTIFICATE_PASSWORD`).
   - Save it as `DeveloperID.p12`.
7. Base64 encode the `.p12` file to copy it to your clipboard:
   ```bash
   base64 -i DeveloperID.p12 | pbcopy
   ```

---

## 3. Step 2: Create App Store Connect API Key (for `notarytool`)

1. Go to [App Store Connect -> Users and Access -> Integrations -> Keys](https://appstoreconnect.apple.com/access/integrations/api).
2. Click **`+`** to generate a new API Key:
   - **Name**: `Aura Notarization Key`
   - **Access**: `Developer` (or `Admin`)
3. Note the following three items:
   - **Key ID**: (e.g. `2X9R4HXF34`) -> this is `APPLE_API_KEY_ID`.
   - **Issuer ID**: Found at the top of the page (e.g. `57246542-96fe-1a63-e053-0824d011072a`) -> this is `APPLE_API_ISSUER`.
   - Download the `.p8` private key file (e.g. `AuthKey_2X9R4HXF34.p8`). Note: Apple only allows downloading this file once!
4. Base64 encode the `.p8` file to copy it to your clipboard:
   ```bash
   base64 -i AuthKey_*.p8 | pbcopy
   ```

---

## 4. Step 3: Add the 4 Secrets to GitHub

You can add them directly using the GitHub CLI (`gh`) in your terminal or via GitHub Web (**Settings -> Secrets and variables -> Actions**):

### Using Terminal (`gh secret set`):

```bash
# 1. Base64-encoded Developer ID .p12
gh secret set APPLE_CERTIFICATE_BASE64 < DeveloperID.p12.base64

# 2. Password used when exporting the .p12
gh secret set APPLE_CERTIFICATE_PASSWORD

# 3. Base64-encoded App Store Connect API Key (.p8)
gh secret set APPLE_API_KEY_BASE64 < AuthKey.p8.base64

# 4. Key ID (e.g. 2X9R4HXF34)
gh secret set APPLE_API_KEY_ID -b "YOUR_KEY_ID"

# 5. Issuer ID (e.g. 57246542-96fe-1a63-e053-0824d011072a)
gh secret set APPLE_API_ISSUER -b "YOUR_ISSUER_UUID"
```

---

## 5. Step 4: Trigger Your First Release!

Whenever you are ready to publish a new release:

```bash
# 1. Bump version and sync all files
./Scripts/bump_version.sh 1.0.0 1

# 2. Commit and push changes
git commit -am "chore(release): prepare v1.0.0"
git push origin main

# 3. Tag and push release tag
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically:
1. Spin up a free Apple Silicon macOS runner.
2. Import your Developer ID certificate.
3. Build the universal production binary.
4. Sign `Aura.app` with hardened runtime.
5. Create `Aura.dmg` with `/Applications` drag-and-drop link.
6. Submit to Apple Notary API and staple the notarization ticket.
7. Publish the release on GitHub with `Aura.dmg` attached!
