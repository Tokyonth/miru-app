import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/javascript_runtime.dart';
import 'package:html/parser.dart';
import 'package:miru_app/data/services/database_service.dart';
import 'package:miru_app/data/services/runtime_helper.dart';
import 'package:miru_app/utils/extension.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/request.dart';
import 'extension_jscore_plugin.dart';
import 'package:html/dom.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

import 'package:flutter_js/flutter_js.dart';
import 'package:miru_app/models/index.dart';

class RuntimeHandle {
  RuntimeHandle(this.runtime, this.extension, this.className);

  JavascriptRuntime runtime;
  Extension extension;
  String className;

  void attachHandleBridge() {
    runtime.onMessage('getSetting', (dynamic args) => jsGetMessage(args));
    // 日志
    runtime.onMessage('moruLog', (args) => jsLog(args));
    // 请求
    runtime.onMessage('request', (args) => jsRequest(args));
    // 设置
    runtime.onMessage('registerSetting', (args) => jsRegisterSetting(args));
    // 清理扩展设置
    runtime.onMessage('cleanSettings', (dynamic args) => jsCleanSettings(args));
    // xpath 选择器
    runtime.onMessage('queryXPath', (arg) => jsQueryXPath(arg));
    runtime.onMessage('removeSelector', (args) => jsRemoveSelector(args));
    // 获取标签属性
    runtime.onMessage('getAttributeText', (args) => jsGetAttributeText(args));
    runtime.onMessage(
        'querySelectorAll', (dynamic args) => jsQuerySelectorAll(args));
    // css 选择器
    runtime.onMessage('querySelector', (arg) => jsQuerySelector(arg));
    if (Platform.isLinux || Platform.isIOS) {
      var jsBridge = JsBridge(jsRuntime: runtime);
      handleDartBridge(String channelName, Function fn) {
        jsBridge.setHandler(channelName, (message) async {
          final args = jsonDecode(message);
          final result = await fn(args);
          await jsBridge.sendMessage(channelName, result);
        });
      }

      handleDartBridge('moruLog', jsLog);
      handleDartBridge('cleanSettings$className', jsCleanSettings);
      handleDartBridge('request$className', jsRequest);
      handleDartBridge('queryXPath$className', jsQueryXPath);
      handleDartBridge('removeSelector$className', jsRemoveSelector);
      handleDartBridge("getAttributeText$className", jsGetAttributeText);
      handleDartBridge('querySelectorAll$className', jsQuerySelectorAll);
      handleDartBridge('querySelector$className', jsQuerySelector);
      handleDartBridge('registerSetting$className', jsRegisterSetting);
      handleDartBridge('getSetting$className', jsGetMessage);
    }
  }

  jsLog(dynamic args) {
    logger.info(args[0]);
    ExtensionUtils.addLog(
      extension,
      ExtensionLogLevel.info,
      args[0],
    );
  }

  jsRequest(dynamic args) async {
    RuntimeHelper.instance.currentRequestUrl = args[0];
    final headers = args[1]['headers'] ?? {};
    if (headers['User-Agent'] == null) {
      headers['User-Agent'] = MiruStorage.getUASetting();
    }

    final url = args[0];
    final method = args[1]['method'] ?? 'get';
    final requestBody = args[1]['data'];

    final log = ExtensionNetworkLog(
      extension: extension,
      url: args[0],
      method: method,
      requestHeaders: headers,
    );
    final key = UniqueKey().toString();
    ExtensionUtils.addNetworkLog(
      key,
      log,
    );

    try {
      final res = await dio.request<String>(
        url,
        data: requestBody,
        queryParameters: args[1]['queryParameters'] ?? {},
        options: Options(
          headers: headers,
          method: method,
        ),
      );
      log.requestHeaders = res.requestOptions.headers;
      log.responseBody = res.data;
      log.responseHeaders = res.headers.map.map(
        (key, value) => MapEntry(
          key,
          value.join(';'),
        ),
      );
      log.statusCode = res.statusCode;

      ExtensionUtils.addNetworkLog(
        key,
        log,
      );
      return res.data;
    } on DioException catch (e) {
      log.url = e.requestOptions.uri.toString();
      log.requestHeaders = e.requestOptions.headers;
      log.responseBody = e.response?.data;
      log.responseHeaders = e.response?.headers.map.map(
        (key, value) => MapEntry(
          key,
          value.join(';'),
        ),
      );
      log.statusCode = e.response?.statusCode;
      ExtensionUtils.addNetworkLog(
        key,
        log,
      );
      rethrow;
    }
  }

  jsRegisterSetting(dynamic args) async {
    args[0]['package'] = extension.package;

    return DatabaseService.registerExtensionSetting(
      ExtensionSetting()
        ..package = extension.package
        ..title = args[0]['title']
        ..key = args[0]['key']
        ..value = args[0]['value']
        ..type = ExtensionSetting.stringToType(args[0]['type'])
        ..description = args[0]['description']
        ..defaultValue = args[0]['defaultValue']
        ..options = jsonEncode(args[0]['options']),
    );
  }

  jsGetMessage(dynamic args) async {
    final setting =
        await DatabaseService.getExtensionSetting(extension.package, args[0]);
    return setting!.value ?? setting.defaultValue;
  }

  jsCleanSettings(dynamic args) async {
    // debugPrint('cleanSettings: ${args[0]}');
    return DatabaseService.cleanExtensionSettings(
        extension.package, List<String>.from(args[0]));
  }

  jsQuerySelector(dynamic args) {
    final content = args[0];
    final selector = args[1];
    final fun = args[2];

    final doc = parse(content).querySelector(selector);
    String result = '';
    switch (fun) {
      case 'text':
        result = doc?.text ?? '';
      case 'outerHTML':
        result = doc?.outerHtml ?? '';
      case 'innerHTML':
        result = doc?.innerHtml ?? '';
      default:
        result = doc?.outerHtml ?? '';
    }
    return result;
  }

  jsQueryXPath(args) {
    final content = args[0];
    final selector = args[1];
    final fun = args[2];

    final xpath = HtmlXPath.html(content);
    final result = xpath.queryXPath(selector);
    String returnVal = '';
    switch (fun) {
      case 'attr':
        returnVal = result.attr ?? '';
      case 'attrs':
        returnVal = jsonEncode(result.attrs);
      case 'text':
        returnVal = result.node?.text ?? '';
      case 'allHTML':
        returnVal = result.nodes
            .map((e) => (e.node as Element).outerHtml)
            .toList()
            .toString();
      case 'outerHTML':
        returnVal = (result.node?.node as Element).outerHtml;
      default:
        returnVal = result.node?.text ?? "";
    }
    return returnVal;
  }

  jsRemoveSelector(dynamic args) {
    final content = args[0];
    final selector = args[1];
    final doc = parse(content);
    doc.querySelectorAll(selector).forEach((element) {
      element.remove();
    });
    return doc.outerHtml;
  }

  jsGetAttributeText(args) {
    final content = args[0];
    final selector = args[1];
    final attr = args[2];
    final doc = parse(content).querySelector(selector);
    return doc?.attributes[attr];
  }

  jsQuerySelectorAll(dynamic args) async {
    final content = args["content"];
    final selector = args["selector"];
    final doc = parse(content).querySelectorAll(selector);
    final elements = jsonEncode(doc.map((e) {
      return e.outerHtml;
    }).toList());
    return elements;
  }
}
