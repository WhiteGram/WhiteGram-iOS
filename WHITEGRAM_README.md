## WhiteGram

WhiteGram is an unofficial Telegram client for iOS, based on the Telegram source code for iOS. The project retains the main features of Telegram, while adding customization of the interface, including chats, channels, stories, translation, transcriptions, as well as automatic proxy processing.

## Main functions

- WhiteGram settings section inside the app.

- Chat and channel settings.

- Channel options for displaying the bottom panel, wide posts, swipe behavior, reactions and double-tap actions on messages and posts

- Story options for hiding stories, disabling story creation, disabling swipe recording, and requesting confirmation before viewing a story.

- Automatic download of MTProxy from the list of public proxies.

- Faster proxy update and logic for switching to a backup server when the proxy is unavailable or slow.

- Custom application icons and WhiteGram brand symbols.

## Proxy behavior

WhiteGram can automatically receive MTProxy servers from a remote source and keep the list up to date while the application is running. The proxy download process checks potential servers, saves available proxies, and switches to unavailable or slow-connecting servers when auto-connectivity is enabled. It also removes unused proxies from a remote source.


## Build an IPA

The following release build command is currently in use:

```bash
./build-input/bazel-8.4.2-darwin-x86_64 build Telegram/Telegram \
  --announce_rc \
  --features=swift.use_global_module_cache \
  --verbose_failures \
  --remote_cache_async \
  --define=buildNumber=1 \
  --disk_cache="$HOME/telegram-bazel-cache" \
  -c opt \
  --ios_multi_cpus=arm64 \
  --watchos_cpus=arm64_32 \
  --//Telegram:disableExtensions \
  --@build_bazel_rules_swift//swift:copt="-j" \
  --@build_bazel_rules_swift//swift:copt="6"
```

The resulting IPA file is generated at:

```text
bazel-bin/Telegram/Telegram.ipa
```

For a convenient local copy:

```bash
mkdir -p build-artifacts/release-ipa
cp -f bazel-bin/Telegram/Telegram.ipa build-artifacts/release-ipa/Telegram.ipa
```

## Installation notes from third-party sources

The IPA file can be installed using tools such as Sideloadly. If the app is signed with a free Apple ID, it is expected that push notifications will not work because iOS requires the `aps-environment` permission from the provisioning profile with push notifications enabled.

For reliable push notifications, the IPA must be signed using a provisioning profile that includes:

```text
aps-environment
```

## Disclaimer of liability

WhiteGram is an unofficial Telegram client. Telegram is a trademark of Telegram FZ-LLC. This project is not affiliated with Telegram and is not supported by it.
