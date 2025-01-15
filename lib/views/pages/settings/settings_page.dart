import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:miru_app/base/widget/get_save_state_widget.dart';
import 'package:miru_app/data/providers/tmdb_provider.dart';
import 'package:miru_app/controllers/application_controller.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/request.dart';
import 'package:miru_app/utils/theme_utils.dart';
import 'package:miru_app/views/dialogs/bt_dialog.dart';
import 'package:miru_app/controllers/extension/extension_repo_controller.dart';
import 'package:miru_app/controllers/settings_controller.dart';
import 'package:miru_app/views/pages/about/about_page.dart';
import 'package:miru_app/views/pages/settings/settings_accent_color_widget.dart';
import 'package:miru_app/views/pages/tracking/anilist_tracking_page.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_input_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_radios_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_switch_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_numberbox_button.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/application.dart';
import 'package:miru_app/views/widgets/list_title.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tmdb_api/tmdb_api.dart';

class SettingsPage extends GetSaveWidget<SettingsController> {
  const SettingsPage({super.key});

  @override
  Bindings? binding() {
    return BindingsBuilder(() {
      Get.lazyPut(() => SettingsController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuildWidget(
      mobileBuilder: _buildMobile,
      desktopBuilder: (context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        children: _buildContent(context),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    return [
      if (!Platform.isAndroid && !Platform.isIOS) ...[
        Text(
          'common.settings'.i18n,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
      ],
      Container(
        height: 180,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/image/settings_head.png',
              fit: BoxFit.fill,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Moru",
                    style: TextStyle(
                      color: context.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Version: 1.0.1",
                    style: TextStyle(
                      color: context.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Align(
                    heightFactor: 4.2,
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      child: Text(
                        "${"settings.about".i18n} Moru",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: context.primaryColor,
                          color: context.primaryColor,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        Get.to(() => const AboutPage());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // 常规设置
      SettingsExpanderTile(
        icon: fluent.FluentIcons.developer_tools,
        androidIcon: Icons.construction,
        title: 'settings.general'.i18n,
        subTitle: 'settings.general-subtitle'.i18n,
        content: Column(
          children: [
            // 语言设置
            SettingsRadiosTile(
              title: 'settings.language'.i18n,
              itemNameValue: controller.lang,
              buildSubtitle: () {
                var saveLang = MiruStorage.getSetting(SettingKey.language);
                var find = controller.lang.entries
                    .firstWhere((element) => element.value == saveLang);
                return find.key;
              },
              applyValue: (value) {
                MiruStorage.setSetting(SettingKey.language, value);
                I18nUtils.changeLanguage(value);
              },
              buildGroupValue: () {
                return MiruStorage.getSetting(SettingKey.language);
              },
            ),
            // 主题设置
            SettingsRadiosTile(
              title: 'settings.theme'.i18n,
              itemNameValue: () {
                final map = {
                  'settings.theme-system'.i18n: 'system',
                  'settings.theme-light'.i18n: 'light',
                  'settings.theme-dark'.i18n: 'dark',
                };
                return map;
              }(),
              buildSubtitle: () {
                var theme = MiruStorage.getSetting(SettingKey.theme);
                switch (theme) {
                  case "light":
                    return 'settings.theme-light'.i18n;
                  case "black":
                  case "dark":
                    return 'settings.theme-dark'.i18n;
                  default:
                    return 'settings.theme-system'.i18n;
                }
              },
              applyValue: (value) {
                Get.find<ApplicationController>().changeTheme(value);
              },
              buildGroupValue: () {
                var theme = Get.find<ApplicationController>().themeText;
                if (theme == "dark" || theme == "black") {
                  return "dark";
                } else {
                  return "light";
                }
              },
            ),
            if (Platform.isAndroid || Platform.isIOS)
              const SettingsAccentColorWidget(),
            SettingsSwitchTile(
              title: 'settings.pure-black-mode'.i18n,
              buildSubtitle: () => 'settings.pure-black-mode-subtitle'.i18n,
              buildValue: () {
                var theme = MiruStorage.getSetting(SettingKey.theme);
                return theme == "black";
              },
              onChanged: (value) {
                if (value) {
                  Get.find<ApplicationController>().changeTheme("black");
                } else {
                  Get.find<ApplicationController>().changeTheme("dark");
                }
              },
            ),
            // 启动检查更新
            SettingsSwitchTile(
              title: 'settings.auto-check-update'.i18n,
              buildSubtitle: () => 'settings.auto-check-update-subtitle'.i18n,
              buildValue: () =>
                  MiruStorage.getSetting(SettingKey.autoCheckUpdate),
              onChanged: (value) {
                MiruStorage.setSetting(SettingKey.autoCheckUpdate, value);
              },
            ),
            // NSFW
            SettingsSwitchTile(
              title: 'settings.nsfw'.i18n,
              buildSubtitle: () => "settings.nsfw-subtitle".i18n,
              buildValue: () {
                return MiruStorage.getSetting(SettingKey.enableNSFW);
              },
              onChanged: (value) {
                MiruStorage.setSetting(SettingKey.enableNSFW, value);
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      // 扩展仓库
      SettingsExpanderTile(
        icon: fluent.FluentIcons.repo,
        androidIcon: Icons.extension,
        title: 'settings.extension'.i18n,
        subTitle: 'settings.extension-subtitle'.i18n,
        content: Column(
          children: [
            SettingsIntpuTile(
              title: 'settings.repo-url'.i18n,
              buildSubtitle: () {
                if (!Platform.isAndroid && !Platform.isIOS) {
                  return 'settings.repo-url-subtitle'.i18n;
                }
                return MiruStorage.getSetting(SettingKey.miruRepoUrl);
              },
              onChanged: (value) {
                MiruStorage.setSetting(SettingKey.miruRepoUrl, value);
                Get.find<ExtensionRepoPageController>().onRefresh();
              },
              buildText: () {
                return MiruStorage.getSetting(SettingKey.miruRepoUrl);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      const SizedBox(height: 10),
      // 视频播放器
      SettingsExpanderTile(
        icon: fluent.FluentIcons.play,
        androidIcon: Icons.play_arrow,
        title: 'settings.video-player'.i18n,
        subTitle: 'settings.video-player-subtitle'.i18n,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsTile(
              title: 'settings.bt-server'.i18n,
              buildSubtitle: () => "settings.bt-server-subtitle".i18n,
              trailing: PlatformWidget(
                mobileWidget: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const BTDialog(),
                    );
                  },
                  child: Text('settings.bt-server-manager'.i18n),
                ),
                desktopWidget: fluent.FilledButton(
                  onPressed: () {
                    fluent.showDialog(
                      context: context,
                      builder: (context) => const BTDialog(),
                    );
                  },
                  child: Text('settings.bt-server-manager'.i18n),
                ),
              ),
            ),
            SettingsRadiosTile(
              title: 'settings.external-player'.i18n,
              itemNameValue: () {
                return controller.getPlayer();
              }(),
              buildSubtitle: () {
                var player = controller.getPlayer();
                var save = MiruStorage.getSetting(SettingKey.videoPlayer);
                var find = player.entries
                    .firstWhere((element) => element.value == save);
                return FlutterI18n.translate(
                  context,
                  'settings.external-player-subtitle',
                  translationParams: {
                    'player': find.key,
                  },
                );
              },
              applyValue: (value) {
                MiruStorage.setSetting(SettingKey.videoPlayer, value);
              },
              buildGroupValue: () {
                return MiruStorage.getSetting(SettingKey.videoPlayer);
              },
            ),
            const SizedBox(height: 10),
            if (!Platform.isAndroid && !Platform.isIOS) ...[
              Text("settings.skip-interval".i18n),
              const SizedBox(height: 2),
              Text(
                "settings.skip-interval-subtitle".i18n,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 15),
              Column(
                children: [
                  Row(children: [
                    Expanded(
                        child: SettingNumboxButton(
                      title: "key I",
                      button1text: "1s",
                      button2text: "0.1s",
                      onChanged: (value) {
                        MiruStorage.setSetting(
                            SettingKey.keyI, value ??= -10.0);
                      },
                      numberBoxvalue:
                          MiruStorage.getSetting(SettingKey.keyI) ?? -10.0,
                    )),
                    const SizedBox(width: 30),
                    Expanded(
                        child: SettingNumboxButton(
                      title: "key J",
                      button1text: "1s",
                      button2text: "0.1s",
                      onChanged: (value) {
                        MiruStorage.setSetting(SettingKey.keyJ, value ??= 10.0);
                      },
                      numberBoxvalue:
                          MiruStorage.getSetting(SettingKey.keyJ) ?? 10.0,
                    ))
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: SettingNumboxButton(
                        title: "arrow left",
                        icon: const Icon(fluent.FluentIcons.chevron_left_med),
                        button1text: "1s",
                        button2text: "0.1s",
                        numberBoxvalue:
                            MiruStorage.getSetting(SettingKey.arrowLeft) ??
                                10.0,
                        onChanged: (value) {
                          MiruStorage.setSetting(
                              SettingKey.arrowLeft, value ??= -2.0);
                        },
                      )),
                      const SizedBox(width: 30),
                      Expanded(
                          child: SettingNumboxButton(
                        title: "arrow right",
                        icon: const Icon(fluent.FluentIcons.chevron_right_med),
                        button1text: "1s",
                        button2text: "0.1s",
                        onChanged: (value) {
                          MiruStorage.setSetting(
                              SettingKey.arrowRight, value ??= 2);
                        },
                        numberBoxvalue:
                            MiruStorage.getSetting(SettingKey.arrowRight) ??
                                10.0,
                      ))
                    ],
                  )
                ],
              ),
            ]
          ],
        ),
      ),
      const SizedBox(height: 10),
      // 漫画阅读器设置
      SettingsExpanderTile(
        icon: fluent.FluentIcons.reading_mode,
        androidIcon: Icons.image,
        title: 'settings.comic-reader'.i18n,
        subTitle: 'settings.comic-reader-subtitle'.i18n,
        content: Column(
          children: [
            SettingsRadiosTile(
              title: 'settings.default-reader-mode'.i18n,
              itemNameValue: () {
                return controller.comic;
              }(),
              buildSubtitle: () {
                var mode = MiruStorage.getSetting(SettingKey.readingMode);
                var find = controller.comic.entries
                    .firstWhere((element) => element.value == mode);
                return find.key;
              },
              applyValue: (value) {
                MiruStorage.setSetting(SettingKey.readingMode, value);
              },
              buildGroupValue: () {
                return MiruStorage.getSetting(SettingKey.readingMode);
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      // 同步数据
      SettingsExpanderTile(
        icon: fluent.FluentIcons.sync,
        androidIcon: Icons.sync,
        content: Column(
          children: [
            // TMDB KEY 设置
            SettingsIntpuTile(
              title: 'settings.tmdb-key'.i18n,
              buildSubtitle: () {
                if (!Platform.isAndroid && !Platform.isIOS) {
                  return 'settings.tmdb-key-subtitle'.i18n;
                }
                final key =
                    MiruStorage.getSetting(SettingKey.tmdbKey) as String;
                if (key.isEmpty) {
                  return 'common.unset'.i18n;
                }
                // 替换为*号
                return key.replaceAll(RegExp(r"."), '*');
              },
              onChanged: (value) {
                MiruStorage.setSetting(SettingKey.tmdbKey, value);
                TmdbApi.tmdb = TMDB(
                  ApiKeys(value, ''),
                  defaultLanguage: MiruStorage.getSetting(SettingKey.language),
                );
              },
              buildText: () {
                return MiruStorage.getSetting(SettingKey.tmdbKey);
              },
            ),
            SettingsSwitchTile(
              title: 'settings.auto-tracking'.i18n,
              buildSubtitle: () => 'settings.auto-tracking-subtitle'.i18n,
              buildValue: () {
                return MiruStorage.getSetting(SettingKey.autoTracking);
              },
              onChanged: (value) {
                MiruStorage.setSetting(SettingKey.autoTracking, value);
              },
            ),
            const SizedBox(height: 10),
            SettingsTile(
              isCard: true,
              icon: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/icon/anilist.jpg'),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: 'Anilist',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (!Platform.isAndroid && !Platform.isIOS) {
                  router.push('/settings/anilist');
                } else {
                  Get.to(() => const AniListTrackingPage());
                }
              },
            ),
          ],
        ),
        title: 'settings.tracking'.i18n,
        subTitle: 'settings.tracking-subtitle'.i18n,
      ),
      const SizedBox(height: 20),
      // 高级
      ListTitle(title: 'settings.advanced'.i18n),
      const SizedBox(height: 20),
      SettingsExpanderTile(
        icon: fluent.FluentIcons.download,
        androidIcon: Icons.download,
        title: 'common.download'.i18n,
        subTitle: 'settings.download-manager'.i18n,
        content: const Column(
          children: [],
        ),
      ),
      const SizedBox(height: 10),
      // 网络设置
      SettingsExpanderTile(
        content: Column(
          children: [
            // UA
            SettingsIntpuTile(
              title: 'settings.network-ua'.i18n,
              buildSubtitle: () {
                if (!Platform.isAndroid && !Platform.isIOS) {
                  return 'settings.network-ua-subtitle'.i18n;
                }
                return MiruStorage.getUASetting();
              },
              onChanged: (value) {
                MiruStorage.setUASetting(value);
              },
              buildText: () {
                return MiruStorage.getUASetting();
              },
            ),
            SettingsRadiosTile(
              title: 'settings.proxy-type'.i18n,
              itemNameValue: controller.net,
              buildSubtitle: () {
                var save = MiruStorage.getSetting(SettingKey.proxyType);
                var find = controller.net.entries
                    .firstWhere((element) => element.value == save);
                return find.key;
                //'settings.proxy-type-subtitle'.i18n
              },
              applyValue: (value) {
                MiruStorage.setSetting(SettingKey.proxyType, value);
                MiruRequest.refreshProxy();
              },
              buildGroupValue: () {
                return MiruStorage.getSetting(SettingKey.proxyType);
              },
            ),
            const SizedBox(height: 10),
            SettingsIntpuTile(
              title: 'settings.proxy'.i18n,
              buildSubtitle: () {
                var save = MiruStorage.getSetting(SettingKey.proxy);
                if (save == '') {
                  return 'settings.proxy-subtitle'.i18n;
                } else {
                  return save;
                }
              },
              onChanged: (value) {
                MiruStorage.setSetting(SettingKey.proxy, value);
                MiruRequest.refreshProxy();
              },
              buildText: () {
                return MiruStorage.getSetting(SettingKey.proxy);
              },
            ),
          ],
        ),
        title: "settings.network".i18n,
        subTitle: "settings.network-subtitle".i18n,
        icon: fluent.FluentIcons.globe,
        androidIcon: Icons.network_wifi,
      ),
      const SizedBox(height: 10),
      // Debug
      SettingsExpanderTile(
        title: "settings.log".i18n,
        subTitle: 'settings.log-subtitle'.i18n,
        androidIcon: Icons.report,
        icon: fluent.FluentIcons.report_alert,
        content: Column(
          children: [
            SettingsSwitchTile(
              title: 'settings.save-log'.i18n,
              buildSubtitle: () => 'settings.save-log-subtitle'.i18n,
              buildValue: () {
                return MiruStorage.getSetting(SettingKey.saveLog);
              },
              onChanged: (value) {
                MiruStorage.setSetting(SettingKey.saveLog, value);
              },
            ),
            const SizedBox(height: 10),
            // 导出日志
            SettingsTile(
              title: 'settings.export-log'.i18n,
              buildSubtitle: () => 'settings.export-log-subtitle'.i18n,
              trailing: PlatformWidget(
                mobileWidget: TextButton(
                  onPressed: () {
                    Share.shareXFiles([XFile(MiruLog.logFilePath)]);
                  },
                  child: Text('common.export'.i18n),
                ),
                desktopWidget: fluent.FilledButton(
                  onPressed: () async {
                    final path = await FilePicker.platform.saveFile(
                      type: FileType.custom,
                      allowedExtensions: ['log'],
                      fileName: 'miru.log',
                    );
                    if (path != null) {
                      File(MiruLog.logFilePath).copy(path);
                    }
                  },
                  child: Text('common.export'.i18n),
                ),
              ),
            ),
          ],
        ),
      ),
      if (!Platform.isAndroid && !Platform.isIOS) ...[
        const SizedBox(height: 10),
        Obx(
          () {
            final value = controller.extensionLogWindowId.value != -1;
            return SettingsSwitchTile(
              icon: const Icon(
                fluent.FluentIcons.bug,
                size: 24,
              ),
              title: 'settings.extension-log'.i18n,
              buildSubtitle: () => 'settings.extension-log-subtitle'.i18n,
              buildValue: () => value,
              onChanged: (value) {
                controller.toggleExtensionLogWindow(value);
              },
              isCard: true,
            );
          },
        )
      ],
      // 关于
      const SizedBox(height: 20),
      ListTitle(title: 'settings.update'.i18n),
      const SizedBox(height: 20),
      SettingsTile(
        isCard: true,
        icon: const PlatformWidget(
          mobileWidget: Icon(Icons.update),
          desktopWidget: Icon(fluent.FluentIcons.update_restore, size: 24),
        ),
        title: 'settings.upgrade'.i18n,
        buildSubtitle: () => FlutterI18n.translate(
          context,
          'settings.upgrade-subtitle',
          translationParams: {
            'version': packageInfo.version,
          },
        ),
        trailing: PlatformWidget(
          mobileWidget: TextButton(
            onPressed: () {
              ApplicationUtils.checkUpdate(
                context,
                showSnackbar: true,
              );
            },
            child: Text('settings.upgrade-training'.i18n),
          ),
          desktopWidget: fluent.FilledButton(
            onPressed: () {
              ApplicationUtils.checkUpdate(
                context,
                showSnackbar: true,
              );
            },
            child: Text('settings.upgrade-training'.i18n),
          ),
        ),
      ),
      const SizedBox(height: 10),
    ];
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('common.settings'.i18n),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: _buildContent(context),
      ),
    );
  }
}
