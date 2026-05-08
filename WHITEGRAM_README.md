# WhiteGram

WhiteGram is an unofficial Telegram iOS client based on Telegram iOS source code. The project keeps the core Telegram experience, while adding practical customization options, automatic proxy handling, interface tweaks, and controls for channels, chats, stories, and web behavior.

## Main Features

- WhiteGram settings section inside the app.
- Chat and channel customization controls.
- Channel options for bottom panel visibility, wide posts, swipe behavior, reactions, and double-tap actions.
- Story options for hiding stories, disabling story creation, disabling recording swipe, and asking before story viewing.
- Automatic MTProxy bootstrap from a remote proxy list.
- Faster proxy refresh and failover logic for unavailable or slow-connecting proxies.
- Web and browser behavior tweaks.
- Custom app icons and WhiteGram branding.
- Sideload-friendly startup fallback when App Groups are unavailable.

## Proxy Behavior

WhiteGram can fetch MTProxy servers automatically from a remote source and keep the list updated while the app is running. The proxy bootstrap checks candidate servers, stores available proxies, and switches away from unavailable or slow-connecting servers when auto-connect is enabled.

## Building IPA

The currently used release build command is:

```bash
./build-input/bazel-8.4.2-darwin-x86_64 build Telegram/Telegram \
  --announce_rc \
  --features=swift.use_global_module_cache \
  --verbose_failures \
  --remote_cache_async \
  --define=buildNumber=100005 \
  --disk_cache=/private/tmp/telegram-bazel-cache \
  -c opt \
  --ios_multi_cpus=arm64 \
  --watchos_cpus=arm64_32 \
  --apple_generate_dsym \
  --output_groups=+dsyms \
  --features=swift.opt_uses_wmo \
  --features=swift.opt_uses_osize \
  --features=dead_strip \
  --objc_enable_binary_stripping \
  --//Telegram:disableExtensions
```

The resulting IPA is generated at:

```text
bazel-bin/Telegram/Telegram.ipa
```

For a convenient local copy:

```bash
mkdir -p build-artifacts/release-ipa
cp -f bazel-bin/Telegram/Telegram.ipa build-artifacts/release-ipa/Telegram.ipa
```

## Sideloading Notes

The IPA can be installed with tools such as Sideloadly. If the app is signed with a free Apple ID, Push Notifications are not expected to work because iOS requires the `aps-environment` entitlement from a provisioning profile with Push Notifications enabled.

For reliable push notifications, the IPA must be signed with a provisioning profile that includes:

```text
aps-environment
```

## Disclaimer

WhiteGram is an unofficial Telegram client. Telegram is a trademark of Telegram FZ-LLC. This project is not affiliated with or endorsed by Telegram.
