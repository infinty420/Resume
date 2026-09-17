// 统计页：签到月历、近 7 天学习柱状图、核心学习指标、成就徽章
import { AppTheme } from '../common/AppTheme';
import {
  CalendarCell,
  DayLearnCount,
  buildMonthCalendar,
  currentBeijingYearMonth,
  todayKey,
} from '../common/DateUtils';
import { WordBookItem } from '../model/WordModel';
import { AchievementView } from '../service/AchievementService';
import { AchievementService } from '../service/AchievementService';
import { CheckInService } from '../service/CheckInService';
import { ReviewSchedulerService } from '../service/ReviewSchedulerService';
import { WordBookService } from '../service/WordBookService';
import { StatCard } from '../widget/StatCard';

interface WeekDay {
  label: string;
}

@Component
export struct StatsPage {
  @Prop fontScale: number = 1.0;
  @Prop currentBookId: string = '';
  @Prop @Watch('onRefreshTick') refreshTick: number = 0;

  @State year: number = 2026;
  @State month: number = 0;
  @State monthCells: CalendarCell[] = [];
  @State checkInKeys: string[] = [];
  @State recent7: DayLearnCount[] = [];
  @State totalCheckIns: number = 0;
  @State streak: number = 0;
  @State todayLearned: number = 0;
  @State masteredCount: number = 0;
  @State learningCount: number = 0;
  @State dueCount: number = 0;
  @State forgottenCount: number = 0;
  @State totalWords: number = 0;
  @State accuracyRate: number = 0;
  @State totalReviews: number = 0;
  @State bestStreak: number = 0;
  @State avgPerDay: number = 0;
  @State achievements: AchievementView[] = [];
  @State unlockedCount: number = 0;

  private weekDays: WeekDay[] = [
    { label: '日' }, { label: '一' }, { label: '二' }, { label: '三' },
    { label: '四' }, { label: '五' }, { label: '六' },
  ];

  aboutToAppear(): void {
    this.loadData();
  }

  onRefreshTick(): void {
    this.loadData();
  }

  private loadData(): void {
    const scheduler: ReviewSchedulerService = ReviewSchedulerService.getInstance();
    const ym: number[] = currentBeijingYearMonth();
    this.year = ym[0];
    this.month = ym[1];
    this.reloadMonth();
    this.recent7 = scheduler.getRecent7DaysCounts();
    this.totalCheckIns = CheckInService.getInstance().getTotalCheckInDays();
    this.streak = CheckInService.getInstance().getCurrentStreak();
    this.todayLearned = ReviewSchedulerService.getInstance().getTodayLearnedCount();
    this.masteredCount = ReviewSchedulerService.getInstance().getMasteredCount(this.currentBookId);
    this.learningCount = scheduler.getLearningCount(this.currentBookId) + this.masteredCount;
    this.dueCount = ReviewSchedulerService.getInstance().getDueCount(this.currentBookId);
    this.forgottenCount = ReviewSchedulerService.getInstance().getForgottenCount(this.currentBookId);
    const book: WordBookItem | undefined = WordBookService.getInstance().getBook(this.currentBookId);
    this.totalWords = book ? book.words.length : 0;
    this.accuracyRate = scheduler.getAccuracyRate();
    this.totalReviews = scheduler.getTotalReviewCount();
    this.bestStreak = CheckInService.getInstance().getBestStreak();
    this.avgPerDay = scheduler.getAveragePerDay();
    this.achievements = AchievementService.getInstance().getAllAchievements();
    this.unlockedCount = AchievementService.getInstance().getUnlockedCount();
  }

  private reloadMonth(): void {
    this.monthCells = buildMonthCalendar(this.year, this.month);
    this.checkInKeys = CheckInService.getInstance().getMonthCheckInKeys(this.year, this.month);
  }

  private shiftMonth(delta: number): void {
    let nextMonth: number = this.month + delta;
    let nextYear: number = this.year;
    if (nextMonth < 0) {
      nextMonth = 11;
      nextYear -= 1;
    } else if (nextMonth > 11) {
      nextMonth = 0;
      nextYear += 1;
    }
    this.month = nextMonth;
    this.year = nextYear;
    this.reloadMonth();
  }

  private isCheckedIn(cell: CalendarCell): boolean {
    return this.checkInKeys.indexOf(cell.dateKey) >= 0;
  }

  private maxRecentCount(): number {
    let max: number = 0;
    for (let i: number = 0; i < this.recent7.length; i++) {
      if (this.recent7[i].count > max) {
        max = this.recent7[i].count;
      }
    }
    return max;
  }

  private barHeight(count: number): number {
    const max: number = this.maxRecentCount();
    if (max <= 0) {
      return 4;
    }
    const height: number = (count / max) * 90;
    return height < 4 ? 4 : height;
  }

  private masteredProgress(): number {
    return this.totalWords === 0 ? 0 : Math.min(this.learningCount / this.totalWords, 1);
  }

  @Builder
  buildCalendarCell(cell: CalendarCell) {
    Column() {
      Text(`${cell.day}`)
        .fontSize(13 * this.fontScale)
        .fontColor(!cell.inMonth ? $r('app.color.text_muted') :
          (this.isCheckedIn(cell) ? $r('app.color.success') :
            (cell.isToday ? $r('app.color.primary') : $r('app.color.text_main'))))
        .fontWeight(cell.isToday || this.isCheckedIn(cell) ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .aspectRatio(1.4)
    .justifyContent(FlexAlign.Center)
    .borderRadius(8)
    .backgroundColor(this.isCheckedIn(cell) ? $r('app.color.success_container') :
      (cell.isToday ? $r('app.color.primary_container') : Color.Transparent))
    .border({
      width: cell.isToday ? 1 : 0,
      color: $r('app.color.primary'),
    })
  }

  build() {
    Scroll() {
      Column() {
      Row() {
        Column() {
          Text('学习数据看板')
            .fontSize(22 * this.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_main'))
          Text('打卡日历、学习趋势与词书掌握情况')
            .fontSize(13 * this.fontScale)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          Image($r('app.media.mascot_owl'))
            .width(34)
            .height(34)
        }
        .width(48)
        .height(48)
        .borderRadius(999)
        .backgroundColor($r('app.color.accent_purple_container'))
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 14 })

        Row() {
          StatCard({
            title: '累计签到',
            value: `${this.totalCheckIns}`,
            hint: '天',
            accent: 'purple',
            fontScale: this.fontScale,
          })
          StatCard({
            title: '连续签到',
            value: `${this.streak}`,
            hint: '天',
            accent: 'success',
            fontScale: this.fontScale,
          })
          StatCard({
            title: '今日学习',
            value: `${this.todayLearned}`,
            hint: '词',
            accent: 'teal',
            fontScale: this.fontScale,
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 12 })

        Row() {
          StatCard({
            title: '已学习',
            value: `${this.learningCount}`,
            hint: `共 ${this.totalWords} 词`,
            accent: 'success',
            showProgress: true,
            progress: this.masteredProgress(),
            fontScale: this.fontScale,
          })
          StatCard({
            title: '待复习',
            value: `${this.dueCount}`,
            hint: '今日到期',
            accent: 'danger',
            fontScale: this.fontScale,
          })
          StatCard({
            title: '遗忘词',
            value: `${this.forgottenCount}`,
            hint: '超7天未复习',
            accent: 'pink',
            fontScale: this.fontScale,
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 14 })

        Row() {
          StatCard({
            title: '正确率',
            value: `${this.accuracyRate}%`,
            hint: '复习判定准确率',
            accent: 'teal',
            fontScale: this.fontScale,
          })
          StatCard({
            title: '累计复习',
            value: `${this.totalReviews}`,
            hint: '次',
            accent: 'purple',
            fontScale: this.fontScale,
          })
          StatCard({
            title: '最高连续',
            value: `${this.bestStreak}`,
            hint: `日均 ${this.avgPerDay} 词`,
            accent: 'warning',
            fontScale: this.fontScale,
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 14 })

        Column() {
          Row() {
            Button('<')
              .fontSize(14 * this.fontScale)
              .height(32)
              .width(44)
              .backgroundColor($r('app.color.input_background'))
              .fontColor($r('app.color.text_main'))
              .onClick(() => {
                this.shiftMonth(-1);
              })
            Text(`${this.year} 年 ${this.month + 1} 月`)
              .fontSize(16 * this.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_main'))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Button('>')
              .fontSize(14 * this.fontScale)
              .height(32)
              .width(44)
              .backgroundColor($r('app.color.input_background'))
              .fontColor($r('app.color.text_main'))
              .onClick(() => {
                this.shiftMonth(1);
              })
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            ForEach(this.weekDays, (day: WeekDay) => {
              Text(day.label)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .fontSize(12 * this.fontScale)
                .fontColor($r('app.color.text_muted'))
            }, (day: WeekDay) => day.label)
          }
          .width('100%')
          .margin({ bottom: 6 })

          Grid() {
            ForEach(this.monthCells, (cell: CalendarCell) => {
              GridItem() {
                this.buildCalendarCell(cell)
              }
            }, (cell: CalendarCell) => cell.dateKey)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
          .columnsGap(4)
          .rowsGap(4)
          .width('100%')
          .height(240)
        }
        .width('100%')
        .padding(16)
        .borderRadius(AppTheme.CARD_RADIUS)
        .backgroundColor($r('app.color.card_background'))
        .shadow(AppTheme.cardShadow())
        .margin({ bottom: 14 })

        Column() {
          Text('近 7 天学习量')
            .fontSize(16 * this.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_main'))
            .width('100%')
            .margin({ bottom: 14 })
          Row() {
            ForEach(this.recent7, (day: DayLearnCount) => {
              Column() {
                Text(`${day.count}`)
                  .fontSize(11 * this.fontScale)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: 4 })
                Column()
                  .width(22)
                  .height(this.barHeight(day.count))
                  .borderRadius(6)
                  .backgroundColor(day.dateKey === todayKey()
                    ? $r('app.color.primary')
                    : (day.count > 0 ? $r('app.color.chart_bar_alt') : $r('app.color.chart_bar')))
                Text(day.label)
                  .fontSize(11 * this.fontScale)
                  .fontColor($r('app.color.text_muted'))
                  .margin({ top: 6 })
              }
              .layoutWeight(1)
              .height(130)
              .justifyContent(FlexAlign.End)
            }, (day: DayLearnCount) => day.dateKey)
          }
          .width('100%')
          .height(130)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(16)
        .borderRadius(AppTheme.CARD_RADIUS)
        .backgroundColor($r('app.color.card_background'))
        .shadow(AppTheme.cardShadow())
        .margin({ bottom: 14 })

        Column() {
          Row() {
            Text('成就徽章')
              .fontSize(16 * this.fontScale)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_main'))
              .layoutWeight(1)
            Text(`${this.unlockedCount}/${this.achievements.length}`)
              .fontSize(13 * this.fontScale)
              .fontColor($r('app.color.accent_purple'))
          }
          .width('100%')
          .margin({ bottom: 12 })

          Grid() {
            ForEach(this.achievements, (item: AchievementView) => {
              GridItem() {
                Column({ space: 6 }) {
                  Text(item.def.icon)
                    .fontSize(28)
                  Text(item.def.title)
                    .fontSize(11 * this.fontScale)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(item.unlocked
                      ? $r('app.color.text_main') : $r('app.color.text_muted'))
                  Text(item.def.description)
                    .fontSize(9 * this.fontScale)
                    .fontColor(item.unlocked
                      ? $r('app.color.text_secondary') : $r('app.color.text_muted'))
                }
                .width('100%')
                .padding({ top: 10, bottom: 10, left: 4, right: 4 })
                .borderRadius(14)
                .backgroundColor(item.unlocked
                  ? $r('app.color.accent_purple_container') : $r('app.color.input_background'))
                .opacity(item.unlocked ? 1 : 0.5)
              }
            }, (item: AchievementView) => item.def.id)
          }
          .columnsTemplate('1fr 1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .borderRadius(AppTheme.CARD_RADIUS)
        .backgroundColor($r('app.color.card_background'))
        .shadow(AppTheme.cardShadow())
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
