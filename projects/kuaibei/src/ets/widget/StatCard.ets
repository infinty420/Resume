// 统计指标卡片：标题、数值、可选进度条，右上角同色系装饰圆
import { AppTheme } from '../common/AppTheme';

@Component
export struct StatCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop hint: string = '';
  @Prop accent: string = 'primary';
  @Prop showProgress: boolean = false;
  @Prop progress: number = 0;
  @Prop fontScale: number = 1.0;

  private accentColor(): Resource {
    if (this.accent === 'success') {
      return $r('app.color.success');
    }
    if (this.accent === 'warning') {
      return $r('app.color.warning');
    }
    if (this.accent === 'danger') {
      return $r('app.color.danger');
    }
    if (this.accent === 'purple') {
      return $r('app.color.accent_purple');
    }
    if (this.accent === 'teal') {
      return $r('app.color.accent_teal');
    }
    if (this.accent === 'pink') {
      return $r('app.color.accent_pink');
    }
    return $r('app.color.primary');
  }

  private trackColor(): Resource {
    if (this.accent === 'success') {
      return $r('app.color.success_container');
    }
    if (this.accent === 'warning') {
      return $r('app.color.warning_container');
    }
    if (this.accent === 'danger') {
      return $r('app.color.danger_container');
    }
    if (this.accent === 'purple') {
      return $r('app.color.accent_purple_container');
    }
    if (this.accent === 'teal') {
      return $r('app.color.accent_teal_container');
    }
    if (this.accent === 'pink') {
      return $r('app.color.accent_pink_container');
    }
    return $r('app.color.primary_container');
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Row({ space: 6 }) {
          Column()
            .width(8)
            .height(8)
            .borderRadius(999)
            .backgroundColor(this.accentColor())
          Text(this.title)
            .fontSize(12 * this.fontScale)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')

        Text(this.value)
          .fontSize(24 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.accentColor())
          .margin({ top: 6 })
        if (this.showProgress) {
          Progress({ value: this.progress, total: 1, type: ProgressType.Linear })
            .margin({ top: 10 })
            .width('100%')
            .height(6)
            .color(this.accentColor())
            .backgroundColor(this.trackColor())
        }
        if (this.hint.length > 0) {
          Text(this.hint)
            .fontSize(11 * this.fontScale)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column()
        .width(40)
        .height(40)
        .borderRadius(999)
        .backgroundColor(this.trackColor())
        .opacity(0.15)
        .margin({ top: -8, right: -8 })
        .hitTestBehavior(HitTestMode.None)
    }
    .width('31%')
    .padding(14)
    .borderRadius(AppTheme.CARD_RADIUS)
    .backgroundColor($r('app.color.card_background'))
    .shadow(AppTheme.cardShadow())
    .clip(true)
  }
}
