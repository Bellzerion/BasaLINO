# BasaLINO AR Readiness

## Recommendation

Use [`ar_flutter_plugin_plus`](https://pub.dev/packages/ar_flutter_plugin_plus) for
the Android Mount Mayon showcase. Version 1.1.3 exposes ARCore horizontal-plane
detection, plane hit tests, anchors, and local glTF 2.0 scene nodes. Its example
demonstrates tapping a detected plane and attaching content to the resulting
anchor. The plugin also declares ARCore optional, so the rest of BasaLINO remains
available on devices without AR support.

The app only advertises the AR entry point on Android devices that report the
`android.hardware.camera.ar` feature. The AR view requests camera permission
when opened and the plugin requests/updates Google Play Services for AR as
needed. AR remains outside reading progression, quizzes, and XP.

## Package comparison

| Package | Plane detection and placement | Android | Maintenance and documentation | Decision |
| --- | --- | --- | --- | --- |
| `ar_flutter_plugin_plus` 1.1.3 | Horizontal/vertical plane configuration, plane hit tests, plane anchors, and local GLTF2 nodes; examples cover tap-to-place | ARCore | Pub.dev lists a January 2026 release, Android/iOS support, README, API reference, and plane-placement examples. The package warns that some ARCore devices may track less smoothly in debuggable builds. | **Selected**: closest match to this optional, single-scene Android prototype. Validate the defense build on the target phone; prefer a release build for physical-device tracking checks. |
| `ar_flutter_plugin` 0.7.3 | Plane detection, hit tests, anchors, and local models | ARCore | Pub.dev lists its latest release in November 2022. Its README and examples are useful, but it is the older upstream package. | Not selected: the plus fork has a more recent release and preserves the same core placement workflow. |
| `arkit_plugin` 1.5.0 | ARKit tracking and placement | iOS only | Recently updated and documented, but does not support Android. | Not suitable for the Android defense target. |
| `flutter_unity_widget` 2022.2.1 | Unity embedding can host AR content but requires a Unity project and an additional build pipeline | Android and iOS | Pub.dev marks it discontinued and points users to a replacement. | Rejected: disproportionate to one illustrated placement and conflicts with the no-complex-3D-pipeline goal. |

## Android requirements and limitations

- ARCore features require a compatible Android device, camera permission, and
  Google Play Services for AR. The app declares AR optional; AR support does not
  gate installation or normal reading.
- The selected plugin has Android `minSdk` 24, so BasaLINO's Android minimum is
  set to API 24.
- The Mayon illustration is a lightweight, local glTF billboard attached to a
  horizontal ARCore plane anchor. It is not a marker, QR code, or remote asset.
- The plugin documents a tracking issue on some devices in debuggable builds.
  Device-level tracking and camera-permission behavior must therefore be
  checked on the actual demonstration phone, ideally with a release APK.
- Browser, desktop, and iOS devices do not expose the AR entry point in this
  phase. No backend, cloud anchor, Firebase, sync, authentication, quiz, XP, or
  progression behavior is involved.

## Sources

- [ar_flutter_plugin_plus on pub.dev](https://pub.dev/packages/ar_flutter_plugin_plus)
- [ar_flutter_plugin_plus plane placement example](https://github.com/FranzGraaf/ar_flutter_plugin_plus/blob/main/example/lib/examples/objectsonplanesexample.dart)
- [ar_flutter_plugin on pub.dev](https://pub.dev/packages/ar_flutter_plugin)
- [arkit_plugin on pub.dev](https://pub.dev/packages/arkit_plugin)
- [flutter_unity_widget on pub.dev](https://pub.dev/packages/flutter_unity_widget)
- [Google ARCore Android app setup](https://developers.google.com/ar/develop/java/enable-arcore)
