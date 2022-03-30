Pod::Spec.new do |spec|
  spec.name = "QRCode"
  spec.version = "0.0.1"
  spec.summary = "Objective-C interface for libqrencode."
  spec.description = <<-DESC
  Generate an objc qrcode instance by libqrencode.
                   DESC

  spec.homepage = "https://github.com/Magic-Unique"
  spec.license = "MIT"
  spec.author = { "冷秋" => "516563564@qq.com" }

  spec.source = { :git => "https://github.com/Magic-Unique/QRCode.git", :tag => "#{spec.version}" }

  spec.source_files = "**/*.{h,m,c}"

  spec.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "HAVE_CONFIG_H" }
end
