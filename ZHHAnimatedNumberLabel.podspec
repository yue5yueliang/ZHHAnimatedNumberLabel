Pod::Spec.new do |s|
  s.name             = 'ZHHAnimatedNumberLabel'
  s.version          = '0.0.1'
  s.summary          = '一个优雅流畅地展示数字变化动画的 UILabel 子类。'

  s.description      = <<-DESC
  ZHHAnimatedNumberLabel 是一个轻量级、可高度自定义的 UILabel 子类，用于实现数字在变化过程中的平滑动画展示。
  它支持多种动画样式，例如线性、缓入、缓出以及弹跳效果。

  非常适合用于计数器、得分展示、金融类应用、运营数据看板等任何涉及数字变动的用户界面。
  DESC

  s.homepage         = 'https://github.com/yue5yueliang/ZHHAnimatedNumberLabel'
  # You can uncomment and replace with real screenshots if available
  # s.screenshots    = 'https://github.com/yue5yueliang/ZHHAnimatedNumberLabel/raw/main/Screenshots/1.png'

  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '桃色三岁' => '136769890@qq.com' }
  s.source           = { :git => 'https://github.com/yue5yueliang/ZHHAnimatedNumberLabel.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  # 默认子模块：核心功能
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'ZHHAnimatedNumberLabel/Classes/**/*'
    core.frameworks   = 'UIKit', 'Foundation'
  end

  # 若将来有资源文件，可启用以下配置
  # s.resource_bundles = {
  #   'ZHHAnimatedNumberLabel' => ['ZHHAnimatedNumberLabel/Assets/*.png']
  # }

  # 如需对外公开头文件，可以指定
  # s.public_header_files = 'ZHHAnimatedNumberLabel/Classes/**/*.h'

  # 如有依赖第三方库，可配置如下
  # s.dependency 'SomeOtherPod', '~> 1.0'

end
