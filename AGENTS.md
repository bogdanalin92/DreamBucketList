# DreamBucket Development Rules

## Scope

- Develop only features and fixes that support the existing DreamBucket app: bucket-list management, user accounts, local storage, Firebase synchronization, sharing, privacy settings, images, QR features, themes, and ads.
- Preserve the existing Flutter, Provider, service, repository, and Firebase architecture unless a change is necessary to make it safer, more stable, or easier to maintain.
- Do not add unrelated products, services, trackers, or speculative features.

## Stability

- Keep Android and iOS builds working. Treat web and desktop as unsupported until their Firebase and platform integrations are explicitly configured.
- Do not change persisted bucket-list data formats, Firestore document fields, or synchronization behavior without a backward-compatible migration strategy.
- Maintain offline use: local storage must continue working when the device has no network connection.
- Make synchronization failures recoverable. Never discard local user data because a Firebase request, connectivity check, or App Check request fails.
- Handle loading, empty, error, permission-denied, and offline states in user-facing screens.
- Add or update tests for changes to models, local storage, synchronization, authentication, and privacy behavior.
- Run formatting, static analysis, and relevant tests before considering work complete. Do not suppress analyzer warnings without a project-specific reason.

## Privacy and Security

- Follow the user's privacy choices. Only synchronize data that the existing sharing and privacy rules permit.
- Enforce authorization in Firebase Security Rules and application services; client-side checks alone are not a security boundary.
- Do not log authentication tokens, App Check tokens, passwords, full user identifiers, private bucket-list content, or image paths containing sensitive data.
- Keep secrets, signing credentials, Firebase configuration values, and ad configuration out of source control when a secure configuration mechanism is available. Do not introduce new hard-coded credentials.
- Request camera, photo, and storage permissions only when the user initiates the related feature. Explain a denied permission and keep the rest of the app usable.
- Preserve account, privacy-consent, and data-sharing behavior when changing authentication or profile flows.

## Functionality

- Keep local storage and Firestore data consistent for create, update, delete, completion, tags, images, shareability, and last-modified state.
- Preserve anonymous-user behavior and ensure sign-in or sign-up does not silently lose existing local bucket-list data.
- Validate user input at the UI boundary and in service/model layers where invalid data could affect storage or synchronization.
- Keep QR generation and scanning scoped to the current sharing workflow; validate scanned data before use.
- Keep ads isolated from core navigation, storage, authentication, privacy, and sharing flows. An ad failure must not prevent a user action.

## Responsive Flutter UI

- Use Flutter layout constraints, `SafeArea`, flexible sizing, scrolling, and text overflow handling so screens remain usable on small phones, large phones, and different text-scale settings.
- Support the existing light and dark themes. Do not hard-code colors where theme colors are appropriate.
- Maintain accessible touch targets, readable contrast, semantic labels for interactive controls, and clear loading/error feedback.
- Avoid blocking the UI thread with storage, image, Firebase, QR, or ad work. Surface progress for operations that may take noticeable time.
- Preserve the portrait-only experience unless orientation support is intentionally designed, implemented, and tested.

## Change Discipline

- Prefer small, reviewable changes that have a clear user benefit.
- Reuse existing services, providers, widgets, and interfaces before adding parallel implementations.
- Update documentation when behavior, setup, permissions, dependencies, or supported platforms change.
- Do not modify generated platform files, Firebase options, or dependency versions unless the requested change requires it and the impact is verified.
