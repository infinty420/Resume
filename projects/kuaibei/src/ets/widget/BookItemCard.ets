// 词书条目卡片：名称、说明、词数与掌握进度、选中态
import { AppTheme } from '../common/AppTheme';

@Component
export struct BookItemCard {
  @Prop bookName: string = '';
  @Prop description: string = '';
  @Prop wordCount: number = 0;
  @Prop masteredCount: number = 0;
  @Prop isSelected: boolean = false;
  @Prop fontScale: number = 1.0;
  onSelect: () => void = () => {};

  private progressValue(): number {
    return this.wordCount === 0 ? 0 : Math.min(this.masteredCount / this.wordCount, 1);
  }

  build() {
    Row({ space: 12 }) {
      Column() {
        Image($r('app.media.icon_book'))
          .width(26)
          .height(26)
      }
      .width(46)
      .height(46)
      .borderRadius(14)
      .backgroundColor(this.isSelected ? $r('app.color.accent_purple_container') : $r('app.color.primary_container'))
      .justifyContent(FlexAlign.Center)

      Column() {
        Text(this.bookName)
          .fontSize(15 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
        Text(this.description)
          .fontSize(12 * this.fontScale)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 2 })
        Row() {
          Text(`共 ${this.wordCount} 词 · 已掌握 ${this.masteredCount}`)
            .fontSize(11 * this.fontScale)
            .fontColor($r('app.color.text_muted'))
            .layoutWeight(1)
          Text(this.isSelected ? '当前使用' : '点击切换')
            .fontSize(12 * this.fontScale)
            .fontColor(this.isSelected ? $r('app.color.primary') : $r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ top: 8 })
        Progress({ value: this.progressValue(), total: 1, type: ProgressType.Linear })
          .margin({ top: 6 })
          .height(4)
          .color($r('app.color.success'))
          .backgroundColor($r('app.color.divider'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .padding(14)
    .margin({ bottom: AppTheme.SPACE_NORMAL })
    .borderRadius(16)
    .backgroundColor(this.isSelected ? $r('app.color.primary_container') : $r('app.color.card_background'))
    .shadow(AppTheme.cardShadow())
    .onClick(() => {
      this.onSelect();
    })
  }
}
