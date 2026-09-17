// 首页：学习指标、今日任务、每日一词、词书切换、签到
import { AppTheme } from '../common/AppTheme';
import { todayKey } from '../common/DateUtils';
import { BookItemCard } from '../widget/BookItemCard';
import { CheckInButton } from '../widget/CheckInButton';
import { StatCard } from '../widget/StatCard';
import { WordBookItem, WordItem, createWord } from '../model/WordModel';
import { CheckInService } from '../service/CheckInService';
import { ReviewSchedulerService } from '../service/ReviewSchedulerService';
import { TtsService } from '../service/TtsService';
import { WordBookService } from '../service/WordBookService';

interface BookViewData {
  id: string;
  name: string;
  description: string;
  wordCount: number;
  masteredCount: number;
}

@Component
export struct HomePage {
  @Prop fontScale: number = 1.0;
  @Prop currentBookId: string = '';
  @Prop dailyTarget: number = 20;
  @Prop @Watch('onRefreshTick') refreshTick: number = 0;
  onSwitchBook: (bookId: string) => void = (bookId: string) => {};
  onGoStudy: () => void = () => {};
  onGoQuiz: () => void = () => {};
  onDataChanged: () => void = () => {};

  @State books: BookViewData[] = [];
  @State checkedIn: boolean = false;
  @State streak: number = 0;
  @State todayLearned: number = 0;
  @State masteredCount: number = 0;
  @State dueCount: number = 0;
  @State newWordCount: number = 0;
  @State learningCount: number = 0;
  @State currentBookWordCount: number = 0;
  @State dailyWord: WordItem = createWord('', '', '', '', '');

  aboutToAppear(): void {
    this.loadData();
  }

  onRefreshTick(): void {
    this.loadData();
  }

  private loadData(): void {
    const scheduler: ReviewSchedulerService = ReviewSchedulerService.getInstance();
    const allBooks: WordBookItem[] = WordBookService.getInstance().getAllBooks();
    const viewData: BookViewData[] = [];
    for (let i: number = 0; i < allBooks.length; i++) {
      const item: BookViewData = {
        id: allBooks[i].id,
        name: allBooks[i].name,
        description: allBooks[i].description,
        wordCount: allBooks[i].words.length,
        masteredCount: scheduler.getMasteredCount(allBooks[i].id),
      };
      viewData.push(item);
    }
    this.books = viewData;
    this.checkedIn = CheckInService.getInstance().hasCheckedInToday();
    this.streak = CheckInService.getInstance().getCurrentStreak();
    this.todayLearned = scheduler.getTodayLearnedCount();
    this.masteredCount = scheduler.getMasteredCount(this.currentBookId);
    this.dueCount = scheduler.getDueCount(this.currentBookId);
    this.newWordCount = scheduler.getNewWordCount(this.currentBookId);
    this.learningCount = scheduler.getLearningCount(this.currentBookId) + this.masteredCount;
    this.currentBookWordCount = 0;
    for (let i: number = 0; i < viewData.length; i++) {
      if (viewData[i].id === this.currentBookId) {
        this.currentBookWordCount = viewData[i].wordCount;
        break;
      }
    }
    const daily: WordItem | undefined = WordBookService.getInstance().getDailyWord(this.currentBookId, todayKey());
    this.dailyWord = daily !== undefined ? daily : createWord('', '', '', '暂无单词', '');
    // 今日已签到时，把最新学习量回写签到记录快照（保存内部已吞异常）
    if (this.checkedIn) {
      CheckInService.getInstance().updateTodayLearned(this.todayLearned);
    }
  }

  private async doCheckIn(): Promise<void> {
    const learned: number = ReviewSchedulerService.getInstance().getTodayLearnedCount();
    const ok: boolean = await CheckInService.getInstance().checkIn(learned);
    if (ok) {
      this.loadData();
      this.onDataChanged();
    }
  }

  private dailyProgress(): number {
    return this.dailyTarget <= 0 ? 0 : Math.min(this.todayLearned / this.dailyTarget, 1);
  }

  build() {
    Column() {
      Stack() {
        Column()
          .width(96)
          .height(96)
          .borderRadius(999)
          .backgroundColor($r('app.color.color_chip_background'))
          .position({ x: -28, y: -30 })
          .hitTestBehavior(HitTestMode.None)
        Column()
          .width(64)
          .height(64)
          .borderRadius(999)
          .backgroundColor($r('app.color.color_chip_background'))
          .position({ x: 220, y: 86 })
          .hitTestBehavior(HitTestMode.None)

        Row() {
          Column() {
            Text('✦ 每日进步一点点')
              .fontSize(11 * this.fontScale)
              .fontColor($r('app.color.text_on_color'))
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(999)
              .backgroundColor($r('app.color.color_chip_background'))
            Text('离线背单词')
              .fontSize(24 * this.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_on_color'))
              .margin({ top: 10 })
            Text('艾宾浩斯复习 · 签到打卡 · 完全离线')
              .fontSize(12 * this.fontScale)
              .fontColor($r('app.color.text_on_color_muted'))
              .margin({ top: 5 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column() {
            Image($r('app.media.mascot_owl'))
              .width(68)
              .height(68)
          }
          .width(82)
          .height(82)
          .borderRadius(999)
          .backgroundColor($r('app.color.color_chip_background'))
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
      }
      .width('100%')
      .padding(18)
      .borderRadius(22)
      .linearGradient(AppTheme.primaryGradient())
      .clip(true)
      .margin({ bottom: 14 })

      Row() {
        StatCard({
          title: '今日学习',
          value: `${this.todayLearned}`,
          hint: `计划 ${this.dailyTarget} 词`,
          accent: 'primary',
          showProgress: true,
          progress: this.dailyProgress(),
          fontScale: this.fontScale,
        })
        StatCard({
          title: '连续签到',
          value: `${this.streak}`,
          hint: this.checkedIn ? '今日已签到' : '今日未签到',
          accent: 'success',
          showProgress: true,
          progress: Math.min(this.streak / 30, 1),
          fontScale: this.fontScale,
        })
        StatCard({
          title: '已学习',
          value: `${this.learningCount}`,
          hint: '当前词书学习进度',
          accent: 'warning',
          showProgress: true,
          progress: this.books.length > 0 && this.currentBookWordCount > 0
            ? Math.min(this.learningCount / this.currentBookWordCount, 1) : 0,
          fontScale: this.fontScale,
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 })

      if (this.dailyWord.word.length > 0) {
        Row() {
          Column() {
            Row() {
              Text('每日一词')
                .fontSize(11 * this.fontScale)
                .fontColor($r('app.color.text_on_color'))
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .borderRadius(999)
                .backgroundColor($r('app.color.color_chip_background'))
              Text(this.dailyWord.word)
                .fontSize(20 * this.fontScale)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_on_color'))
                .margin({ left: 8 })
                .layoutWeight(1)
              Button('朗读')
                .fontSize(11 * this.fontScale)
                .height(28)
                .padding({ left: 10, right: 10 })
                .backgroundColor($r('app.color.color_chip_background'))
                .fontColor($r('app.color.text_on_color'))
                .onClick(() => {
                  TtsService.getInstance().speak(this.dailyWord.word);
                })
            }
            .width('100%')
            Text(this.dailyWord.meaning)
              .fontSize(13 * this.fontScale)
              .fontColor($r('app.color.text_on_color_muted'))
              .margin({ top: 6 })
              .width('100%')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(14)
        .borderRadius(AppTheme.CARD_RADIUS)
        .linearGradient(AppTheme.primaryGradient())
        .clip(true)
        .margin({ bottom: 12 })
      }

      Column() {
        Row() {
          Row({ space: 8 }) {
            Column() {
              Text('复')
                .fontSize(14 * this.fontScale)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.danger'))
            }
            .width(34)
            .height(34)
            .borderRadius(12)
            .backgroundColor($r('app.color.danger_container'))
            .justifyContent(FlexAlign.Center)

            Column() {
              Text('今日待复习')
                .fontSize(12 * this.fontScale)
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.dueCount}`)
                .fontSize(22 * this.fontScale)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.danger'))
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)

          Row({ space: 8 }) {
            Column() {
              Text('新')
                .fontSize(14 * this.fontScale)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.accent_teal'))
            }
            .width(34)
            .height(34)
            .borderRadius(12)
            .backgroundColor($r('app.color.accent_teal_container'))
            .justifyContent(FlexAlign.Center)

            Column() {
              Text('待学新词')
                .fontSize(12 * this.fontScale)
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.newWordCount}`)
                .fontSize(22 * this.fontScale)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.accent_teal'))
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)

          Button('开始背词')
            .height(40)
            .fontSize(14 * this.fontScale)
            .backgroundColor($r('app.color.primary'))
            .fontColor($r('app.color.on_primary'))
            .onClick(() => {
              this.onGoStudy();
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .borderRadius(AppTheme.CARD_RADIUS)
      .backgroundColor($r('app.color.card_background'))
      .shadow(AppTheme.cardShadow())
      .margin({ bottom: 14 })

      Row({ space: 8 }) {
        Column()
          .width(4)
          .height(16)
          .borderRadius(999)
          .backgroundColor($r('app.color.accent_purple'))
        Text('词书切换')
          .fontSize(16 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
      }
      .width('100%')
      .margin({ bottom: 8 })

      List({ space: 0 }) {
        ForEach(this.books, (book: BookViewData) => {
          ListItem() {
            BookItemCard({
              bookName: book.name,
              description: book.description,
              wordCount: book.wordCount,
              masteredCount: book.masteredCount,
              isSelected: this.currentBookId === book.id,
              fontScale: this.fontScale,
              onSelect: () => {
                this.onSwitchBook(book.id);
              },
            })
          }
        }, (book: BookViewData) => book.id)
      }
      .layoutWeight(1)
      .width('100%')

      Row({ space: AppTheme.SPACE_NORMAL }) {
        CheckInButton({
          checkedIn: this.checkedIn,
          fontScale: this.fontScale,
          onCheckIn: () => {
            this.doCheckIn();
          },
        })
        Button('背词')
          .layoutWeight(1)
          .height(44)
          .fontSize(15 * this.fontScale)
          .backgroundColor($r('app.color.accent_teal_container'))
          .fontColor($r('app.color.accent_teal'))
          .onClick(() => {
            this.onGoStudy();
          })
        Button('自测')
          .layoutWeight(1)
          .height(44)
          .fontSize(15 * this.fontScale)
          .backgroundColor($r('app.color.accent_purple_container'))
          .fontColor($r('app.color.accent_purple'))
          .onClick(() => {
            this.onGoQuiz();
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .padding(AppTheme.PAGE_PADDING)
    .backgroundColor($r('app.color.page_background'))
  }
}
