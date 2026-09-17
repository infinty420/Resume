// 背词页：艾宾浩斯学习队列（到期复习优先 + 新词补足），卡片翻转与判定
import { AppTheme } from '../common/AppTheme';
import { WordItem, createWord } from '../model/WordModel';
import { ReviewSchedulerService } from '../service/ReviewSchedulerService';
import { TtsService } from '../service/TtsService';
import { WordCard } from '../widget/WordCard';

@Component
export struct StudyPage {
  @Prop fontScale: number = 1.0;
  @Prop dailyTarget: number = 20;
  @Prop @Watch('onBookChanged') currentBookId: string = '';
  @Prop @Watch('onTickChanged') refreshTick: number = 0;
  onDataChanged: () => void = () => {};

  @State queue: WordItem[] = [];
  @State currentIndex: number = 0;
  @State showAnswer: boolean = false;
  @State finished: boolean = false;
  @State sessionLearned: number = 0;
  @State processing: boolean = false;
  @State currentWordState: WordItem = createWord('', '', '', '暂无单词', '');

  aboutToAppear(): void {
    this.loadQueue();
  }

  onBookChanged(): void {
    this.loadQueue();
  }

  // 数据刷新时，仅在尚未开始本组学习时重建队列；学习中途与完成态均不自动重载，
  // 避免完成总结页被刷新冲掉、学习进度被重置
  onTickChanged(): void {
    if (!this.finished && this.sessionLearned === 0) {
      this.loadQueue();
    }
  }

  private loadQueue(): void {
    this.queue = ReviewSchedulerService.getInstance().getStudyQueue(this.currentBookId, this.dailyTarget);
    this.currentIndex = 0;
    this.showAnswer = false;
    this.finished = false;
    this.sessionLearned = 0;
    this.processing = false;
    this.syncCurrentWord();
  }

  private syncCurrentWord(): void {
    if (this.queue.length > 0 && this.currentIndex < this.queue.length) {
      this.currentWordState = this.queue[this.currentIndex];
    } else {
      this.currentWordState = createWord('', '', '', '暂无单词', '');
    }
  }

  private speakWord(): void {
    if (this.currentWordState.word.length > 0) {
      TtsService.getInstance().speak(this.currentWordState.word);
    }
  }

  private async markWord(wasCorrect: boolean): Promise<void> {
    // 重入守卫：持久化 await 期间禁止重复点击，防止同词处理两次导致等级污染与跳词
    if (this.processing || this.finished || this.currentWordState.word.length === 0) {
      return;
    }
    this.processing = true;
    try {
      await ReviewSchedulerService.getInstance()
        .processReview(this.currentBookId, this.currentWordState, wasCorrect);
      this.sessionLearned += 1;
      this.showAnswer = false;
      if (this.currentIndex + 1 >= this.queue.length) {
        this.finished = true;
        this.syncCurrentWord();
      } else {
        this.currentIndex += 1;
        this.syncCurrentWord();
      }
      this.onDataChanged();
    } catch (err) {
      // 服务层已记录日志并吞掉异常，此处兜底防止未处理 Promise rejection
    } finally {
      this.processing = false;
    }
  }

  private progressValue(): number {
    return this.queue.length === 0 ? 0 : Math.min(this.currentIndex / this.queue.length, 1);
  }

  @Builder
  buildFinished() {
    Stack() {
      Column()
        .width(80)
        .height(80)
        .borderRadius(999)
        .backgroundColor(this.sessionLearned === 0
          ? $r('app.color.primary_container') : $r('app.color.warning_container'))
        .opacity(0.18)
        .position({ x: -24, y: -26 })
        .hitTestBehavior(HitTestMode.None)
      Column()
        .width(54)
        .height(54)
        .borderRadius(999)
        .backgroundColor(this.sessionLearned === 0
          ? $r('app.color.accent_teal_container') : $r('app.color.success_container'))
        .opacity(0.18)
        .position({ x: 268, y: 150 })
        .hitTestBehavior(HitTestMode.None)

      Column() {
        Column() {
          Image(this.sessionLearned === 0 ? $r('app.media.mascot_owl') : $r('app.media.mascot_trophy'))
            .width(64)
            .height(64)
        }
        .width(96)
        .height(96)
        .borderRadius(999)
        .backgroundColor(this.sessionLearned === 0
          ? $r('app.color.primary_container') : $r('app.color.warning_container'))
        .justifyContent(FlexAlign.Center)

        Text(this.sessionLearned === 0 ? '当前没有待学单词' : '本组学习完成')
          .fontSize(26 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
          .margin({ top: 16 })
        Text(this.sessionLearned === 0
          ? '当前词书单词已全部掌握，或词书为空，请切换词书'
          : `本轮共学习 ${this.sessionLearned} 个单词，继续保持！`)
          .fontSize(14 * this.fontScale)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 10 })
        Row({ space: AppTheme.SPACE_NORMAL }) {
          Button('再来一组')
            .layoutWeight(1)
            .height(44)
            .backgroundColor($r('app.color.primary'))
            .fontColor($r('app.color.on_primary'))
            .onClick(() => {
              this.loadQueue();
            })
        }
        .width('100%')
        .margin({ top: 20 })
      }
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .borderRadius(AppTheme.CARD_RADIUS)
    .backgroundColor($r('app.color.card_background'))
    .shadow(AppTheme.cardShadow())
    .clip(true)
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text('卡片式背词')
            .fontSize(22 * this.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_main'))
          Text('复习词优先，认识升级 / 不认识当日重现')
            .fontSize(13 * this.fontScale)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(`${Math.min(this.currentIndex + 1, this.queue.length)}/${this.queue.length}`)
          .fontSize(12 * this.fontScale)
          .fontColor($r('app.color.primary'))
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(999)
          .backgroundColor($r('app.color.primary_container'))
      }
      .width('100%')
      .margin({ bottom: 16 })

      Progress({ value: this.progressValue(), total: 1, type: ProgressType.Linear })
        .width('100%')
        .height(7)
        .color($r('app.color.primary'))
        .backgroundColor($r('app.color.primary_container'))
        .borderRadius(999)
        .margin({ bottom: 14 })

      if (this.finished || this.queue.length === 0) {
        Column() {
          this.buildFinished()
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        Column() {
          WordCard({
            word: this.currentWordState.word,
            phonetic: this.currentWordState.phonetic,
            meaning: this.currentWordState.meaning,
            example: this.currentWordState.example,
            showAnswer: this.showAnswer,
            fontScale: this.fontScale,
            onFlip: () => {
              this.showAnswer = !this.showAnswer;
            },
            onSpeak: () => {
              this.speakWord();
            },
          })

          Row({ space: AppTheme.SPACE_NORMAL }) {
            Button('不认识')
              .layoutWeight(1)
              .height(48)
              .fontSize(16 * this.fontScale)
              .backgroundColor($r('app.color.danger_container'))
              .fontColor($r('app.color.danger'))
              .enabled(!this.processing)
              .onClick(() => {
                this.markWord(false);
              })
            Button('认识')
              .layoutWeight(1)
              .height(48)
              .fontSize(16 * this.fontScale)
              .backgroundColor($r('app.color.success_container'))
              .fontColor($r('app.color.success'))
              .enabled(!this.processing)
              .onClick(() => {
                this.markWord(true);
              })
          }
          .width('100%')
          .margin({ top: 16 })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding(AppTheme.PAGE_PADDING)
    .backgroundColor($r('app.color.page_background'))
  }
}
