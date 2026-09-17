// 自测页：英译汉 / 汉译英 / 默写三模式，4 选项随机打乱，错题回写复习调度
import { AppConstants } from '../common/AppConstants';
import { AppTheme } from '../common/AppTheme';
import { WordItem, createWord } from '../model/WordModel';
import {
  QUIZ_MODE_CN_TO_EN,
  QUIZ_MODE_DICTATION,
  QUIZ_MODE_EN_TO_CN,
  QuizResult,
  QuizService,
} from '../service/QuizService';
import { ReviewSchedulerService } from '../service/ReviewSchedulerService';
import { TtsService } from '../service/TtsService';
import { WordBookService } from '../service/WordBookService';

interface ModeTab {
  mode: number;
  label: string;
}

interface CountTab {
  count: number;
  label: string;
}

@Component
export struct QuizPage {
  @Prop fontScale: number = 1.0;
  @Prop @Watch('onBookChanged') currentBookId: string = '';
  onDataChanged: () => void = () => {};

  // phase: 0 配置 1 答题 2 结果
  @State phase: number = 0;
  @State mode: number = QUIZ_MODE_EN_TO_CN;
  @State quizCount: number = 5;
  @State options: string[] = [];
  @State selectedOption: string = '';
  @State answered: boolean = false;
  @State lastCorrect: boolean = false;
  @State correctCount: number = 0;
  @State wrongCount: number = 0;
  @State dictationInput: string = '';
  @State quizError: string = '';
  @State resultTotal: number = 0;
  @State resultCorrect: number = 0;
  @State resultWrong: number = 0;
  @State resultWrongWords: WordItem[] = [];
  @State quizProcessing: boolean = false;
  @State questionIndex: number = 0;
  @State currentWordState: WordItem = createWord('', '', '', '暂无单词', '');

  private modeTabs: ModeTab[] = [
    { mode: QUIZ_MODE_EN_TO_CN, label: '英译汉' },
    { mode: QUIZ_MODE_CN_TO_EN, label: '汉译英' },
    { mode: QUIZ_MODE_DICTATION, label: '默写' },
  ];
  private countTabs: CountTab[] = [
    { count: 5, label: '5题' },
    { count: 10, label: '10题' },
    { count: 20, label: '20题' },
  ];

  aboutToAppear(): void {
  }

  onBookChanged(): void {
    this.phase = 0;
    this.quizError = '';
  }

  private modeLabel(): string {
    if (this.mode === QUIZ_MODE_EN_TO_CN) {
      return '看词选义';
    }
    if (this.mode === QUIZ_MODE_CN_TO_EN) {
      return '看义选词';
    }
    return '默写挑战';
  }

  private correctAnswer(): string {
    return this.mode === QUIZ_MODE_EN_TO_CN ? this.currentWordState.meaning : this.currentWordState.word;
  }

  private dictationHint(): string {
    const word: string = this.currentWordState.word;
    if (word.length === 0) {
      return '';
    }
    const firstLetter: string = word.charAt(0);
    const remaining: number = word.length - 1;
    let hint: string = firstLetter;
    for (let i: number = 0; i < remaining; i++) {
      hint += '_';
    }
    return hint;
  }

  private startQuiz(): void {
    const totalWords: number = WordBookService.getInstance().getBookWords(this.currentBookId).length;
    if (this.mode !== QUIZ_MODE_DICTATION && totalWords > 0 && totalWords < AppConstants.QUIZ_OPTION_COUNT) {
      this.quizError = '选择题需要词书至少 4 个单词，可改用默写模式';
      return;
    }
    QuizService.getInstance().startQuiz(this.currentBookId, this.mode, this.quizCount);
    if (QuizService.getInstance().getTotal() === 0) {
      this.quizError = '当前词书暂无单词，请先切换词书';
      return;
    }
    this.quizError = '';
    this.correctCount = 0;
    this.wrongCount = 0;
    this.answered = false;
    this.selectedOption = '';
    this.dictationInput = '';
    this.resultWrongWords = [];
    this.phase = 1;
    this.questionIndex = QuizService.getInstance().getIndex();
    this.syncQuestion();
  }

  private syncQuestion(): void {
    this.questionIndex = QuizService.getInstance().getIndex();
    const word: WordItem | undefined = QuizService.getInstance().getCurrentWord();
    if (word !== undefined) {
      this.currentWordState = word;
      if (this.mode === QUIZ_MODE_DICTATION) {
        this.options = [];
      } else {
        this.options = QuizService.getInstance().getOptions(this.currentBookId);
      }
    }
  }

  private selectOption(option: string): void {
    if (this.answered) {
      return;
    }
    this.answered = true;
    this.selectedOption = option;
    const correct: boolean = QuizService.getInstance().checkAnswer(option);
    this.lastCorrect = correct;
    if (correct) {
      this.correctCount += 1;
    } else {
      this.wrongCount += 1;
    }
  }

  private submitDictation(): void {
    if (this.answered || this.dictationInput.trim().length === 0) {
      return;
    }
    this.answered = true;
    const correct: boolean = QuizService.getInstance().checkAnswer(this.dictationInput);
    this.lastCorrect = correct;
    if (correct) {
      this.correctCount += 1;
    } else {
      this.wrongCount += 1;
    }
  }

  private async processWrongWords(): Promise<void> {
    const wrongWords: WordItem[] = QuizService.getInstance().getResult().wrongWords;
    for (let i: number = 0; i < wrongWords.length; i++) {
      await ReviewSchedulerService.getInstance().processReview(this.currentBookId, wrongWords[i], false);
    }
  }

  private async nextQuestion(): Promise<void> {
    // 重入守卫：错题回写 await 期间禁止连点，防止错题重复 processReview 导致记录虚增
    if (this.quizProcessing) {
      return;
    }
    this.quizProcessing = true;
    try {
      QuizService.getInstance().next();
      if (QuizService.getInstance().isFinished()) {
        await this.processWrongWords();
        await QuizService.getInstance().incrementQuizCount();
        const result: QuizResult = QuizService.getInstance().getResult();
        this.resultTotal = result.total;
        this.resultCorrect = result.correct;
        this.resultWrong = result.wrong;
        this.resultWrongWords = result.wrongWords;
        this.phase = 2;
        this.onDataChanged();
      } else {
        this.answered = false;
        this.selectedOption = '';
        this.dictationInput = '';
        this.syncQuestion();
      }
    } catch (err) {
      // 服务层已记录日志并吞掉异常，此处兜底防止未处理 Promise rejection
    } finally {
      this.quizProcessing = false;
    }
  }

  private backToConfig(): void {
    this.phase = 0;
    this.quizError = '';
    this.questionIndex = 0;
    this.answered = false;
    this.selectedOption = '';
    this.dictationInput = '';
  }

  private optionBackground(option: string): Resource {
    if (!this.answered) {
      return $r('app.color.primary_container');
    }
    if (option === this.correctAnswer()) {
      return $r('app.color.success_container');
    }
    if (option === this.selectedOption) {
      return $r('app.color.danger_container');
    }
    return $r('app.color.input_background');
  }

  private optionFontColor(option: string): Resource {
    if (!this.answered) {
      return $r('app.color.primary');
    }
    if (option === this.correctAnswer()) {
      return $r('app.color.success');
    }
    if (option === this.selectedOption) {
      return $r('app.color.danger');
    }
    return $r('app.color.text_secondary');
  }

  private quizProgress(): number {
    const total: number = QuizService.getInstance().getTotal();
    if (total <= 0) {
      return 0;
    }
    return Math.min(this.questionIndex / total, 1);
  }

  private accuracy(): number {
    if (this.resultTotal === 0) {
      return 0;
    }
    return Math.round((this.resultCorrect / this.resultTotal) * 100);
  }

  @Builder
  buildConfig() {
    Column() {
      Row() {
        Column() {
          Text('自测题库')
            .fontSize(22 * this.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_main'))
          Text('英译汉、汉译英、默写三种模式，答错单词将安排明日复习')
            .fontSize(13 * this.fontScale)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          Image($r('app.media.mascot_owl'))
            .width(30)
            .height(30)
        }
        .width(44)
        .height(44)
        .borderRadius(999)
        .backgroundColor($r('app.color.accent_orange_container'))
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row({ space: AppTheme.SPACE_SMALL }) {
        ForEach(this.modeTabs, (tab: ModeTab) => {
          Button(tab.label)
            .layoutWeight(1)
            .height(42)
            .fontSize(14 * this.fontScale)
            .backgroundColor(this.mode === tab.mode
              ? AppTheme.modeAccent(tab.mode) : $r('app.color.card_background'))
            .fontColor(this.mode === tab.mode ? $r('app.color.on_primary') : $r('app.color.text_main'))
            .onClick(() => {
              this.mode = tab.mode;
              this.quizError = '';
            })
        }, (tab: ModeTab) => tab.label)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Row({ space: AppTheme.SPACE_SMALL }) {
        ForEach(this.countTabs, (tab: CountTab) => {
          Button(tab.label)
            .layoutWeight(1)
            .height(42)
            .fontSize(14 * this.fontScale)
            .backgroundColor(this.quizCount === tab.count ? $r('app.color.primary') : $r('app.color.card_background'))
            .fontColor(this.quizCount === tab.count ? $r('app.color.on_primary') : $r('app.color.text_main'))
            .onClick(() => {
              this.quizCount = tab.count;
            })
        }, (tab: CountTab) => tab.label)
      }
      .width('100%')
      .margin({ bottom: 20 })

      if (this.quizError.length > 0) {
        Text(this.quizError)
          .fontSize(13 * this.fontScale)
          .fontColor($r('app.color.danger'))
          .width('100%')
          .margin({ bottom: 12 })
      }

      Button('开始自测')
        .width('100%')
        .height(48)
        .fontSize(16 * this.fontScale)
        .backgroundColor($r('app.color.primary'))
        .fontColor($r('app.color.on_primary'))
        .onClick(() => {
          this.startQuiz();
        })
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppTheme.CARD_RADIUS)
    .backgroundColor($r('app.color.card_background'))
    .shadow(AppTheme.cardShadow())
  }

  @Builder
  buildQuestion() {
    Column() {
      Row() {
        Text(`第 ${this.questionIndex + 1} 题`)
          .fontSize(13 * this.fontScale)
          .fontColor($r('app.color.text_secondary'))
        Text(this.modeLabel())
          .fontSize(12 * this.fontScale)
          .fontColor($r('app.color.primary'))
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(999)
          .backgroundColor($r('app.color.primary_container'))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 })

      Column() {
        Text(this.mode === QUIZ_MODE_EN_TO_CN ? this.currentWordState.word : this.currentWordState.meaning)
          .fontSize(28 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
          .textAlign(TextAlign.Center)
        if (this.mode === QUIZ_MODE_EN_TO_CN) {
          Text(this.currentWordState.phonetic)
            .fontSize(14 * this.fontScale)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6 })
        }
        Button('朗读单词')
          .fontSize(12 * this.fontScale)
          .height(32)
          .margin({ top: 10 })
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.primary_container'))
          .fontColor($r('app.color.primary'))
          .onClick(() => {
            TtsService.getInstance().speak(this.currentWordState.word);
          })
      }
      .width('100%')
      .padding(16)
      .borderRadius(16)
      .backgroundColor($r('app.color.input_background'))
      .margin({ bottom: 14 })

      if (this.mode === QUIZ_MODE_DICTATION) {
        Row() {
          Text('字母提示')
            .fontSize(12 * this.fontScale)
            .fontColor($r('app.color.text_muted'))
          Text(this.dictationHint())
            .fontSize(20 * this.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.primary'))
            .margin({ left: 8 })
            .letterSpacing(2)
        }
        .width('100%')
        .margin({ bottom: 10 })

        TextInput({ placeholder: '请输入英文单词，忽略大小写', text: this.dictationInput })
          .width('100%')
          .height(48)
          .fontSize(16 * this.fontScale)
          .backgroundColor($r('app.color.input_background'))
          .fontColor($r('app.color.text_main'))
          .placeholderColor($r('app.color.text_muted'))
          .borderRadius(AppTheme.BUTTON_RADIUS)
          .enabled(!this.answered)
          .onChange((value: string) => {
            this.dictationInput = value;
          })
        if (!this.answered) {
          Button('提交答案')
            .width('100%')
            .height(46)
            .margin({ top: 12 })
            .fontSize(15 * this.fontScale)
            .backgroundColor($r('app.color.primary'))
            .fontColor($r('app.color.on_primary'))
            .onClick(() => {
              this.submitDictation();
            })
        }
      } else {
        Column({ space: 10 }) {
          ForEach(this.options, (option: string, optionIndex: number) => {
            Button() {
              Text(`${String.fromCharCode(65 + optionIndex)}. ${option}`)
                .width('100%')
                .fontSize(15 * this.fontScale)
                .fontColor(this.optionFontColor(option))
                .textAlign(TextAlign.Start)
            }
              .width('100%')
              .height(48)
              .padding({ left: 16, right: 16 })
              .backgroundColor(this.optionBackground(option))
              .borderRadius(AppTheme.BUTTON_RADIUS)
              .onClick(() => {
                this.selectOption(option);
              })
          }, (option: string, optionIndex: number) => `${optionIndex}_${option}`)
        }
        .width('100%')
      }

      if (this.answered) {
        Row() {
          Text(this.lastCorrect ? '回答正确' : `回答错误，正确答案：${this.correctAnswer()}`)
            .fontSize(14 * this.fontScale)
            .fontColor(this.lastCorrect ? $r('app.color.success') : $r('app.color.danger'))
            .layoutWeight(1)
          Button(QuizService.getInstance().isLastQuestion() ? '查看结果' : '下一题')
            .height(40)
            .fontSize(14 * this.fontScale)
            .backgroundColor($r('app.color.primary'))
            .fontColor($r('app.color.on_primary'))
            .enabled(!this.quizProcessing)
            .onClick(() => {
              this.nextQuestion();
            })
        }
        .width('100%')
        .margin({ top: 14 })
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppTheme.CARD_RADIUS)
    .backgroundColor($r('app.color.card_background'))
    .shadow(AppTheme.cardShadow())
  }

  @Builder
  buildResult() {
    Stack() {
      Column()
        .width(70)
        .height(70)
        .borderRadius(999)
        .backgroundColor($r('app.color.warning_container'))
        .opacity(0.18)
        .position({ x: -20, y: -22 })
        .hitTestBehavior(HitTestMode.None)
      Column()
        .width(48)
        .height(48)
        .borderRadius(999)
        .backgroundColor($r('app.color.accent_purple_container'))
        .opacity(0.18)
        .position({ x: 286, y: 128 })
        .hitTestBehavior(HitTestMode.None)

      Column() {
        Column() {
          Image($r('app.media.mascot_trophy'))
            .width(56)
            .height(56)
        }
        .width(84)
        .height(84)
        .borderRadius(999)
        .backgroundColor($r('app.color.warning_container'))
        .justifyContent(FlexAlign.Center)

        Text('自测完成')
          .fontSize(24 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
          .margin({ top: 14 })
      Text(`正确率 ${this.accuracy()}%`)
        .fontSize(18 * this.fontScale)
        .fontColor($r('app.color.primary'))
        .margin({ top: 8 })
      Row() {
        Text(`正确 ${this.resultCorrect} 题`)
          .fontSize(14 * this.fontScale)
          .fontColor($r('app.color.success'))
          .layoutWeight(1)
        Text(`错误 ${this.resultWrong} 题`)
          .fontSize(14 * this.fontScale)
          .fontColor($r('app.color.danger'))
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 12 })

      if (this.resultWrongWords.length > 0) {
        Text('错题回顾（已安排明日复习）')
          .fontSize(14 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
          .width('100%')
          .margin({ top: 16, bottom: 8 })
        List({ space: 8 }) {
          ForEach(this.resultWrongWords, (word: WordItem) => {
            ListItem() {
              Row() {
                Text(word.word)
                  .fontSize(15 * this.fontScale)
                  .fontColor($r('app.color.danger'))
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                Text(word.meaning)
                  .fontSize(13 * this.fontScale)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .padding(12)
              .borderRadius(12)
              .backgroundColor($r('app.color.danger_container'))
            }
          }, (word: WordItem) => word.id)
        }
        .layoutWeight(1)
        .width('100%')
      }

      Row({ space: AppTheme.SPACE_NORMAL }) {
        Button('返回设置')
          .layoutWeight(1)
          .height(46)
          .fontSize(15 * this.fontScale)
          .backgroundColor($r('app.color.input_background'))
          .fontColor($r('app.color.text_main'))
          .onClick(() => {
            this.backToConfig();
          })
        Button('再来一组')
          .layoutWeight(1)
          .height(46)
          .fontSize(15 * this.fontScale)
          .backgroundColor($r('app.color.primary'))
          .fontColor($r('app.color.on_primary'))
          .onClick(() => {
            this.startQuiz();
          })
      }
      .width('100%')
      .margin({ top: 16 })
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .borderRadius(AppTheme.CARD_RADIUS)
    .backgroundColor($r('app.color.card_background'))
    .shadow(AppTheme.cardShadow())
    .clip(true)
  }

  build() {
    Column() {
      if (this.phase === 0) {
        this.buildConfig()
      } else if (this.phase === 1) {
        Column() {
          Progress({ value: this.quizProgress(), total: 1, type: ProgressType.Linear })
            .width('100%')
            .height(7)
            .color($r('app.color.primary'))
            .backgroundColor($r('app.color.primary_container'))
            .borderRadius(999)
            .margin({ bottom: 14 })
          Scroll() {
            this.buildQuestion()
          }
          .layoutWeight(1)
          .width('100%')
          .align(Alignment.Top)
        }
        .width('100%')
        .height('100%')
      } else {
        this.buildResult()
      }
    }
    .width('100%')
    .height('100%')
    .padding(AppTheme.PAGE_PADDING)
    .backgroundColor($r('app.color.page_background'))
  }
}
