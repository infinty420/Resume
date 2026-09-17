// 单词翻转卡片：正面显示单词与音标，反面显示释义与例句
import { AppTheme } from '../common/AppTheme';

@Component
export struct WordCard {
  @Prop word: string = '';
  @Prop phonetic: string = '';
  @Prop meaning: string = '';
  @Prop example: string = '';
  @Prop showAnswer: boolean = false;
  @Prop fontScale: number = 1.0;
  onFlip: () => void = () => {};
  onSpeak: () => void = () => {};

  build() {
    Column() {
      if (this.showAnswer) {
        Row()
          .width(36)
          .height(4)
          .borderRadius(999)
          .backgroundColor($r('app.color.success'))
          .margin({ bottom: 14 })
        Text(this.meaning)
          .fontSize(28 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .fontColor($r('app.color.success'))
        Text(this.example)
          .fontSize(13 * this.fontScale)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 14 })
          .textAlign(TextAlign.Center)
        Text('点击卡片返回单词')
          .fontSize(12 * this.fontScale)
          .fontColor($r('app.color.text_muted'))
          .margin({ top: 16 })
      } else {
        Row({ space: 5 }) {
          Column()
            .width(7)
            .height(7)
            .borderRadius(999)
            .backgroundColor($r('app.color.accent_teal'))
          Column()
            .width(7)
            .height(7)
            .borderRadius(999)
            .backgroundColor($r('app.color.accent_orange'))
          Column()
            .width(7)
            .height(7)
            .borderRadius(999)
            .backgroundColor($r('app.color.accent_pink'))
        }
        .width('100%')
        .margin({ bottom: 12 })
        .justifyContent(FlexAlign.Start)

        Row() {
          Text(this.word)
            .fontSize(30 * this.fontScale)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_main'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Button('朗读')
            .fontSize(12 * this.fontScale)
            .height(32)
            .padding({ left: 10, right: 10 })
            .backgroundColor($r('app.color.primary_container'))
            .fontColor($r('app.color.primary'))
            .hitTestBehavior(HitTestMode.Block)
            .onClick(() => {
              this.onSpeak();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Text(this.phonetic)
          .fontSize(14 * this.fontScale)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 8 })
        Text('点击卡片查看释义')
          .fontSize(13 * this.fontScale)
          .fontColor($r('app.color.text_muted'))
          .margin({ top: 14 })
      }
    }
    .width('100%')
    .padding(24)
    .borderRadius(22)
    .backgroundColor($r('app.color.card_background'))
    .shadow(AppTheme.cardShadow())
    .onClick(() => {
      this.onFlip();
    })
  }
}
