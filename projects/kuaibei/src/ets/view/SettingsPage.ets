// 设置页：主题三态、字体与目标、词书导入、数据重置
import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../common/AppConstants';
import { AppTheme } from '../common/AppTheme';
import { UserSettings } from '../model/WordModel';
import { StorageService } from '../service/StorageService';
import { WordBookService, ImportedBookData } from '../service/WordBookService';

const LOG_DOMAIN: number = 0x0006;
const TAG: string = 'SettingsPage';

interface ThemeTab {
  mode: number;
  label: string;
}

interface ImportModeTab {
  mode: number;
  label: string;
}

@Component
export struct SettingsPage {
  @Prop currentBookId: string = '';
  @Prop @Watch('syncFromProps') themeMode: number = 0;
  @Prop @Watch('syncFromProps') fontScale: number = 1.0;
  @Prop @Watch('syncFromProps') dailyTarget: number = 20;
  onSettingsChanged: (settings: UserSettings) => void = (settings: UserSettings) => {};
  onBooksChanged: () => void = () => {};
  onDataReset: () => void = () => {};

  @State themeModeLocal: number = 0;
  @State fontScaleLocal: number = 1.0;
  @State dailyTargetLocal: number = 20;
  @State importName: string = '';
  @State importDescription: string = '';
  @State importText: string = '';
  @State importMode: number = 0;
  @State importError: string = '';
  @State importPreviewCount: number = 0;

  private themeTabs: ThemeTab[] = [
    { mode: 0, label: '跟随系统' },
    { mode: 1, label: '浅色' },
    { mode: 2, label: '深色' },
  ];
  private importModeTabs: ImportModeTab[] = [
    { mode: 0, label: 'TXT' },
    { mode: 1, label: 'JSON' },
  ];

  aboutToAppear(): void {
    this.syncFromProps();
  }

  syncFromProps(): void {
    this.themeModeLocal = this.themeMode;
    this.fontScaleLocal = this.fontScale;
    this.dailyTargetLocal = this.dailyTarget;
  }

  private persistSettings(): void {
    const settings: UserSettings = {
      themeMode: this.themeModeLocal,
      fontScale: this.fontScaleLocal,
      dailyTarget: this.dailyTargetLocal,
      currentBookId: this.currentBookId,
    };
    this.onSettingsChanged(settings);
  }

  private applyThemeMode(mode: number): void {
    this.themeModeLocal = mode;
    try {
      const context: common.UIAbilityContext =
        this.getUIContext().getHostContext() as common.UIAbilityContext;
      const appContext: common.ApplicationContext = context.getApplicationContext();
      if (mode === 1) {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      } else if (mode === 2) {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      } else {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      }
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'setColorMode failed: %{public}s', JSON.stringify(err));
    }
    this.persistSettings();
  }

  private parseImport(): ImportedBookData | undefined {
    if (this.importText.trim().length === 0) {
      return undefined;
    }
    const service: WordBookService = WordBookService.getInstance();
    const id: string = service.sanitizeBookId(this.importName);
    const name: string = this.importName.trim().length > 0 ? this.importName.trim() : '导入词书';
    const description: string = this.importDescription.trim().length > 0
      ? this.importDescription.trim() : '用户导入词表';
    if (this.importMode === 0) {
      return service.parseImportedText(this.importText, id, name, description);
    }
    return service.parseImportedJson(this.importText, id, name, description);
  }

  private updateImportPreview(): void {
    try {
      const data: ImportedBookData | undefined = this.parseImport();
      this.importPreviewCount = data ? data.words.length : 0;
      this.importError = data && data.words.length > 0 ? '' : '未解析到任何单词，请检查格式';
    } catch (err) {
      this.importPreviewCount = 0;
      this.importError = '解析失败，请检查文本或 JSON 格式';
    }
  }

  private async confirmImport(): Promise<void> {
    try {
      const data: ImportedBookData | undefined = this.parseImport();
      if (!data || data.words.length === 0) {
        this.importError = '未解析到任何单词，请检查格式';
        return;
      }
      await WordBookService.getInstance().addImportedBook(data);
      this.importError = '';
      this.importText = '';
      this.importName = '';
      this.importDescription = '';
      this.importPreviewCount = 0;
      this.onBooksChanged();
    } catch (err) {
      this.importError = err instanceof Error ? err.message : '导入失败，请检查格式';
    }
  }

  private confirmReset(): void {
    this.getUIContext().showAlertDialog({
      title: '重置学习数据',
      message: '将清空全部学习进度、签到记录与导入词书，且不可恢复，确定继续吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        },
      },
      secondaryButton: {
        value: '确定重置',
        fontColor: $r('app.color.danger'),
        action: () => {
          this.doReset();
        },
      },
    });
  }

  private async doReset(): Promise<void> {
    const ok: boolean = await StorageService.getInstance().resetAll();
    if (!ok) {
      this.getUIContext().showAlertDialog({
        title: '重置失败',
        message: '数据清空失败，请稍后重试',
        confirm: {
          value: '知道了',
          action: () => {
          },
        },
      });
      return;
    }
    this.onDataReset();
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Column() {
          Text('基础设置')
            .fontSize(22 * this.fontScaleLocal)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_main'))
            .width('100%')
          Text('所有设置本地保存，重启后自动恢复')
            .fontSize(13 * this.fontScaleLocal)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4, bottom: 14 })
            .width('100%')

          Row({ space: AppTheme.SPACE_SMALL }) {
            ForEach(this.themeTabs, (tab: ThemeTab) => {
              Button(tab.label)
                .layoutWeight(1)
                .height(40)
                .fontSize(14 * this.fontScaleLocal)
                .backgroundColor(this.themeModeLocal === tab.mode
                  ? $r('app.color.primary') : $r('app.color.input_background'))
                .fontColor(this.themeModeLocal === tab.mode
                  ? $r('app.color.on_primary') : $r('app.color.text_main'))
                .onClick(() => {
                  this.applyThemeMode(tab.mode);
                })
            }, (tab: ThemeTab) => tab.label)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .borderRadius(AppTheme.CARD_RADIUS)
        .backgroundColor($r('app.color.card_background'))
        .shadow(AppTheme.cardShadow())

        Column() {
          Row() {
            Text('字体大小')
              .fontSize(15 * this.fontScaleLocal)
              .fontColor($r('app.color.text_main'))
              .layoutWeight(1)
            Text(this.fontScaleLocal.toFixed(1))
              .fontSize(14 * this.fontScaleLocal)
              .fontColor($r('app.color.primary'))
          }
          .width('100%')
          Slider({
            value: this.fontScaleLocal,
            min: AppConstants.MIN_FONT_SCALE,
            max: AppConstants.MAX_FONT_SCALE,
            step: 0.1,
          })
            .blockColor($r('app.color.primary'))
            .selectedColor($r('app.color.primary'))
            .onChange((value: number) => {
              this.fontScaleLocal = Math.round(value * 10) / 10;
              this.persistSettings();
            })
        }
        .width('100%')
        .padding(16)
        .borderRadius(AppTheme.CARD_RADIUS)
        .backgroundColor($r('app.color.card_background'))
        .shadow(AppTheme.cardShadow())

        Column() {
          Row() {
            Text('每日目标词数')
              .fontSize(15 * this.fontScaleLocal)
              .fontColor($r('app.color.text_main'))
              .layoutWeight(1)
            Text(`${this.dailyTargetLocal}`)
              .fontSize(14 * this.fontScaleLocal)
              .fontColor($r('app.color.primary'))
          }
          .width('100%')
          Slider({
            value: this.dailyTargetLocal,
            min: 1,
            max: AppConstants.MAX_DAILY_TARGET,
            step: 1,
          })
            .blockColor($r('app.color.primary'))
            .selectedColor($r('app.color.primary'))
            .onChange((value: number) => {
              this.dailyTargetLocal = Math.round(value);
              this.persistSettings();
            })
          Text('学习队列将按目标数安排复习词与新词')
            .fontSize(12 * this.fontScaleLocal)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6 })
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .borderRadius(AppTheme.CARD_RADIUS)
        .backgroundColor($r('app.color.card_background'))
        .shadow(AppTheme.cardShadow())

        Column() {
          Text('导入词书')
            .fontSize(16 * this.fontScaleLocal)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_main'))
            .width('100%')
          Text('TXT 每行一条：word-meaning-phonetic-example；也支持 JSON 单词数组')
            .fontSize(12 * this.fontScaleLocal)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6, bottom: 10 })
            .width('100%')

          Row({ space: AppTheme.SPACE_SMALL }) {
            ForEach(this.importModeTabs, (tab: ImportModeTab) => {
              Button(tab.label)
                .layoutWeight(1)
                .height(38)
                .fontSize(14 * this.fontScaleLocal)
                .backgroundColor(this.importMode === tab.mode
                  ? $r('app.color.primary') : $r('app.color.input_background'))
                .fontColor(this.importMode === tab.mode
                  ? $r('app.color.on_primary') : $r('app.color.text_main'))
                .onClick(() => {
                  this.importMode = tab.mode;
                  this.importError = '';
                  this.updateImportPreview();
                })
            }, (tab: ImportModeTab) => tab.label)
          }
          .width('100%')
          .margin({ bottom: 10 })

          TextInput({ placeholder: '词书名称（可选）', text: this.importName })
            .width('100%')
            .height(44)
            .fontSize(14 * this.fontScaleLocal)
            .backgroundColor($r('app.color.input_background'))
            .fontColor($r('app.color.text_main'))
            .placeholderColor($r('app.color.text_muted'))
            .borderRadius(12)
            .margin({ bottom: 8 })
            .onChange((value: string) => {
              this.importName = value;
            })
          TextInput({ placeholder: '词书说明（可选）', text: this.importDescription })
            .width('100%')
            .height(44)
            .fontSize(14 * this.fontScaleLocal)
            .backgroundColor($r('app.color.input_background'))
            .fontColor($r('app.color.text_main'))
            .placeholderColor($r('app.color.text_muted'))
            .borderRadius(12)
            .margin({ bottom: 8 })
            .onChange((value: string) => {
              this.importDescription = value;
            })
          TextArea({
            placeholder: this.importMode === 0
              ? '每行一条：word-meaning-phonetic-example'
              : '[{"word":"...","meaning":"..."}]',
            text: this.importText,
          })
            .width('100%')
            .height(120)
            .fontSize(14 * this.fontScaleLocal)
            .backgroundColor($r('app.color.input_background'))
            .fontColor($r('app.color.text_main'))
            .placeholderColor($r('app.color.text_muted'))
            .borderRadius(12)
            .onChange((value: string) => {
              this.importText = value;
              this.updateImportPreview();
            })

          Row() {
            Text(`预览解析：${this.importPreviewCount} 词`)
              .fontSize(12 * this.fontScaleLocal)
              .fontColor($r('app.color.text_secondary'))
              .layoutWeight(1)
            if (this.importError.length > 0) {
              Text(this.importError)
                .fontSize(12 * this.fontScaleLocal)
                .fontColor($r('app.color.danger'))
            }
          }
          .width('100%')
          .margin({ top: 8 })

          Button('导入并保存词书')
            .width('100%')
            .height(44)
            .margin({ top: 12 })
            .fontSize(15 * this.fontScaleLocal)
            .backgroundColor($r('app.color.primary'))
            .fontColor($r('app.color.on_primary'))
            .onClick(() => {
              this.confirmImport();
            })
        }
        .width('100%')
        .padding(16)
        .borderRadius(AppTheme.CARD_RADIUS)
        .backgroundColor($r('app.color.card_background'))
        .shadow(AppTheme.cardShadow())

        Button('重置全部学习数据')
          .width('100%')
          .height(46)
          .fontSize(15 * this.fontScaleLocal)
          .backgroundColor($r('app.color.danger_container'))
          .fontColor($r('app.color.danger'))
          .onClick(() => {
            this.confirmReset();
          })
      }
      .width('100%')
      .padding(AppTheme.PAGE_PADDING)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .align(Alignment.Top)
  }
}
