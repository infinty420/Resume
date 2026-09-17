// 公共样式常量：间距、圆角、阴影、渐变与多色彩统一管理
export class AppTheme {
  static readonly PAGE_PADDING: number = 16;
  static readonly CARD_RADIUS: number = 18;
  static readonly BUTTON_RADIUS: number = 14;
  static readonly SPACE_SMALL: number = 8;
  static readonly SPACE_NORMAL: number = 12;
  static readonly SPACE_LARGE: number = 16;

  static cardShadow(): ShadowOptions {
    const shadow: ShadowOptions = {
      radius: 12,
      color: $r('app.color.card_shadow'),
      offsetX: 0,
      offsetY: 4,
    };
    return shadow;
  }

  // 主色渐变：用于首页欢迎卡等强调区域
  static primaryGradient(): LinearGradientOptions {
    const stops: [ResourceColor, number][] = [
      [$r('app.color.primary_gradient_start'), 0],
      [$r('app.color.primary_gradient_end'), 1],
    ];
    const options: LinearGradientOptions = {
      angle: 135,
      colors: stops,
    };
    return options;
  }

  // 底部五个 Tab 各自的强调色
  static tabAccent(index: number): Resource {
    if (index === 1) {
      return $r('app.color.success');
    }
    if (index === 2) {
      return $r('app.color.accent_orange');
    }
    if (index === 3) {
      return $r('app.color.accent_purple');
    }
    if (index === 4) {
      return $r('app.color.accent_teal');
    }
    return $r('app.color.primary');
  }

  static tabContainer(index: number): Resource {
    if (index === 1) {
      return $r('app.color.success_container');
    }
    if (index === 2) {
      return $r('app.color.accent_orange_container');
    }
    if (index === 3) {
      return $r('app.color.accent_purple_container');
    }
    if (index === 4) {
      return $r('app.color.accent_teal_container');
    }
    return $r('app.color.primary_container');
  }

  // 自测三种模式选中色：蓝 / 紫 / 橙
  static modeAccent(mode: number): Resource {
    if (mode === 1) {
      return $r('app.color.accent_purple');
    }
    if (mode === 2) {
      return $r('app.color.accent_orange');
    }
    return $r('app.color.primary');
  }
}
