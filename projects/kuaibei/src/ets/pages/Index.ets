// 应用入口页：异步初始化 + 底部 Tab 容器，一级页面均为自定义组件
import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../common/AppConstants';
import { AppTheme } from '../common/AppTheme';
import { UserSettings, WordBookItem } from '../model/WordModel';
import { AchievementDef } from '../model/AchievementModel';
import { AchievementService } from '../service/AchievementService';
import { CheckInService } from '../service/CheckInService';
import { QuizService } from '../service/QuizService';
import { ReviewSchedulerService } from '../service/ReviewSchedulerService';
import { StorageService } from '../service/StorageService';
import { TtsService } from '../service/TtsService';
import { WordBookService } from '../service/WordBookService';
import { HomePage } from '../view/HomePage';
import { QuizPage } from '../view/QuizPage';
import { SettingsPage } from '../view/SettingsPage';
import { StatsPage } from '../view/StatsPage';
import { StudyPage } from '../view/StudyPage';

const LOG_DOMAIN: number = 0x0000;
const TAG: string = 'Index';

@Entry
@Component
struct Index {
  @State ready: boolean = false;
  @State initError: string = '';
  @State currentTab: number = 0;
  @State books: WordBookItem[] = [];
  @State currentBookId: string = '';
  @State fontScale: number = AppConstants.DEFAULT_FONT_SCALE;
  @State themeMode: number = 0;
  @State dailyTarget: number = AppConstants.DEFAULT_DAILY_TARGET;
  @State refreshTick: number = 0;
  @State achievementPopup: string = '';

  private tabController: TabsController = new TabsController();

  aboutToAppear(): void {
    this.initApp();
  }

  private async initApp(): Promise<void> {
    try {
      const context: common.UIAbilityContext =
        this.getUIContext().getHostContext() as common.UIAbilityContext;
      await StorageService.getInstance().init(context);
      await WordBookService.getInstance().init(context);
      await CheckInService.getInstance().init();
      await ReviewSchedulerService.getInstance().init();
      await AchievementService.getInstance().init();
      await QuizService.getInstance().init();
      // TTS 初始化含音色下载，放后台不阻塞启动；speak 内部会检查 ready 状态
      TtsService.getInstance().init().catch((err: Error) => {
        hilog.error(0x0000, 'Index', 'tts init background failed: %{public}s', err.message);
      });

      const settings: UserSettings = await StorageService.getInstance().loadSettings();
      this.applyThemeMode(settings.themeMode, context);

      let bookId: string = settings.currentBookId;
      if (WordBookService.getInstance().getBook(bookId) === undefined) {
        bookId = AppConstants.BUILT_IN_BOOKS[0].id;
      }
      this.books = WordBookService.getInstance().getAllBooks();
      this.currentBookId = bookId;
      this.fontScale = settings.fontScale;
      this.themeMode = settings.themeMode;
      this.dailyTarget = settings.dailyTarget;
      this.initError = '';
      this.ready = true;
      hilog.info(LOG_DOMAIN, TAG, 'app initialized, books: %{public}d', this.books.length);
    } catch (err) {
      this.initError = err instanceof Error ? err.message : '应用初始化失败，请重试';
      hilog.error(LOG_DOMAIN, TAG, 'init failed: %{public}s', JSON.stringify(err));
    }
  }

  private applyThemeMode(mode: number, context: common.UIAbilityContext): void {
    try {
      const appContext: common.ApplicationContext = context.getApplicationContext();
      if (mode === 1) {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      } else if (mode === 2) {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      } else {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      }
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'applyThemeMode failed: %{public}s', JSON.stringify(err));
    }
  }

  private switchTab(index: number): void {
    this.currentTab = index;
    this.tabController.changeIndex(index);
    this.notifyDataChanged();
  }

  private notifyDataChanged(): void {
    this.refreshTick += 1;
    this.checkAchievements();
  }

  private async checkAchievements(): Promise<void> {
    const scheduler: ReviewSchedulerService = ReviewSchedulerService.getInstance();
    const mastered: number = scheduler.getMasteredCount(this.currentBookId);
    const streak: number = CheckInService.getInstance().getCurrentStreak();
    const reviews: number = scheduler.getTotalReviewCount();
    const quizzes: number = QuizService.getInstance().getQuizCount();
    await AchievementService.getInstance().checkAndUnlock(mastered, streak, reviews, quizzes);
    const newly: AchievementDef[] = AchievementService.getInstance().popNewlyUnlocked();
    if (newly.length > 0) {
      const first: AchievementDef = newly[0];
      this.achievementPopup = `${first.icon} 解锁成就：${first.title}`;
    }
  }

  private async persistSettings(): Promise<void> {
    const settings: UserSettings = {
      themeMode: this.themeMode,
      fontScale: this.fontScale,
      dailyTarget: this.dailyTarget,
      currentBookId: this.currentBookId,
    };
    await StorageService.getInstance().saveSettings(settings);
  }

  private async switchBook(bookId: string): Promise<void> {
    this.currentBookId = bookId;
    await this.persistSettings();
    this.notifyDataChanged();
  }

  private async onSettingsChanged(settings: UserSettings): Promise<void> {
    this.themeMode = settings.themeMode;
    this.fontScale = settings.fontScale;
    this.dailyTarget = settings.dailyTarget;
    if (settings.currentBookId.length > 0) {
      this.currentBookId = settings.currentBookId;
    }
    await StorageService.getInstance().saveSettings(settings);
    this.notifyDataChanged();
  }

  private onBooksChanged(): void {
    this.books = WordBookService.getInstance().getAllBooks();
    // 主动驱动首页词书列表刷新，不依赖 Tab 切换兜底
    this.notifyDataChanged();
  }

  private async onDataReset(): Promise<void> {
    this.ready = false;
    this.initError = '';
    await this.initApp();
  }

  private retry(): void {
    this.initError = '';
    this.initApp();
  }

  @Builder
  buildTabBar(title: string, index: number) {
    Column() {
      Column() {
        Row({ space: 5 }) {
          if (this.currentTab === index) {
            Column()
              .width(6)
              .height(6)
              .borderRadius(999)
              .backgroundColor(AppTheme.tabAccent(index))
          }
          Text(title)
            .fontSize(13)
            .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTab === index
              ? AppTheme.tabAccent(index) : $r('app.color.text_secondary'))
        }
      }
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(999)
      .backgroundColor(this.currentTab === index
        ? AppTheme.tabContainer(index) : Color.Transparent)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.nav_background'))
  }

  @Builder
  buildLoading() {
    Column({ space: 14 }) {
      LoadingProgress()
        .width(52)
        .height(52)
        .color($r('app.color.primary'))
      Text('正在加载词书与学习数据…')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildError() {
    Column({ space: 14 }) {
      Text('加载失败')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_main'))
      Text(this.initError)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })
      Button('重试')
        .width(160)
        .height(44)
        .backgroundColor($r('app.color.primary'))
        .fontColor($r('app.color.on_primary'))
        .onClick(() => {
          this.retry();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildMain() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
      TabContent() {
        HomePage({
          fontScale: this.fontScale,
          currentBookId: this.currentBookId,
          dailyTarget: this.dailyTarget,
          refreshTick: this.refreshTick,
          onSwitchBook: (bookId: string) => {
            this.switchBook(bookId);
          },
          onGoStudy: () => {
            this.switchTab(1);
          },
          onGoQuiz: () => {
            this.switchTab(2);
          },
          onDataChanged: () => {
            this.notifyDataChanged();
          },
        })
      }
      .tabBar(this.buildTabBar('首页', 0))

      TabContent() {
        StudyPage({
          fontScale: this.fontScale,
          dailyTarget: this.dailyTarget,
          currentBookId: this.currentBookId,
          refreshTick: this.refreshTick,
          onDataChanged: () => {
            this.notifyDataChanged();
          },
        })
      }
      .tabBar(this.buildTabBar('背词', 1))

      TabContent() {
        QuizPage({
          fontScale: this.fontScale,
          currentBookId: this.currentBookId,
          onDataChanged: () => {
            this.notifyDataChanged();
          },
        })
      }
      .tabBar(this.buildTabBar('自测', 2))

      TabContent() {
        StatsPage({
          fontScale: this.fontScale,
          currentBookId: this.currentBookId,
          refreshTick: this.refreshTick,
        })
      }
      .tabBar(this.buildTabBar('统计', 3))

      TabContent() {
        SettingsPage({
          currentBookId: this.currentBookId,
          themeMode: this.themeMode,
          fontScale: this.fontScale,
          dailyTarget: this.dailyTarget,
          onSettingsChanged: (settings: UserSettings) => {
            this.onSettingsChanged(settings);
          },
          onBooksChanged: () => {
            this.onBooksChanged();
          },
          onDataReset: () => {
            this.onDataReset();
          },
        })
      }
      .tabBar(this.buildTabBar('设置', 4))
    }
    .scrollable(false)
    .barHeight(56)
    .barMode(BarMode.Fixed)
    .backgroundColor($r('app.color.page_background'))
    .onChange((index: number) => {
      this.currentTab = index;
      this.notifyDataChanged();
    })
  }

  build() {
    Stack() {
      Column() {
        if (this.ready) {
          this.buildMain()
        } else if (this.initError.length > 0) {
          this.buildError()
        } else {
          this.buildLoading()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))

      if (this.achievementPopup.length > 0) {
        Row({ space: 8 }) {
          Text(this.achievementPopup)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_on_color'))
        }
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
        .borderRadius(999)
        .backgroundColor($r('app.color.accent_purple'))
        .shadow(AppTheme.cardShadow())
        .margin({ top: 48 })
        .onClick(() => {
          this.achievementPopup = '';
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
