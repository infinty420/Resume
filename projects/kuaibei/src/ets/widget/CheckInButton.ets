// 签到按钮：未签到可点击，已签到显示成功态
@Component
export struct CheckInButton {
  @Prop checkedIn: boolean = false;
  @Prop fontScale: number = 1.0;
  onCheckIn: () => void = () => {};

  build() {
    Button(this.checkedIn ? '已签到' : '签到')
      .layoutWeight(1)
      .height(44)
      .fontSize(15 * this.fontScale)
      .fontWeight(this.checkedIn ? FontWeight.Bold : FontWeight.Normal)
      .fontColor($r('app.color.on_primary'))
      .backgroundColor(this.checkedIn ? $r('app.color.success') : $r('app.color.accent_orange'))
      .padding({ left: 8, right: 8 })
      .enabled(!this.checkedIn)
      .onClick(() => {
        this.onCheckIn();
      })
  }
}
