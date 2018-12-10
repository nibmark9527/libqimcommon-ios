
Pod::Spec.new do |s|

  s.name         = "QIMCommon"
  s.version      = "0.0.1"
  s.summary      = "Qunar chat App 6.0+ version QIMCommon"
  s.description  = <<-DESC
                   Qunar QIMCommon解决方案

                   DESC

  s.homepage     = "https://im.qunar.com"
  s.license      = "Copyright 2018 im.qunar.com"
  s.author        = { "Qunar IM" => "qtalk@qunar.com" }

  s.source       = { :git => "git@gitlab.corp.qunar.com:qchat/libQIMCommon-iOS.git", :tag=> s.version.to_s}

  s.ios.deployment_target   = '9.0'
  s.resource_bundles = {'QIMCommonResource' => ['QIMCommon/QIMKitCommonResource/*.{png,aac,caf,pem}']}
  s.subspec 'PublicCommon' do |pc|

    pc.platform     = :ios, "9.0"

    pc.public_header_files = "QIMCommon/QIMKit/**/*.{h}", "QIMCommon/NoArc/**/*.{h}"

    pc.source_files = "QIMCommon/3rdPart&tools/*.{h,m,c}", "QIMCommon/Source/**/*.{h,m,c}", "QIMCommon/QIMKit/**/*.{h,m,c}", "QIMCommon/NoArc/**/*.{h,m}"
    pc.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'DEBUGLOG=1'}

    pc.requires_arc = false  
    pc.requires_arc = ['QIMCommon/3rdPart&tools/*','QIMCommon/Source/**/*','QIMCommon/QIMSDKUI/**/*.{h,m,c}']

  end

  s.subspec 'PrivateCommon' do |sc|

    sc.source_files = "QIMCommon/PrivateCommon/**/*.{h,m,c}"
    sc.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'DEBUGLOG=1'}
    sc.public_header_files = "QIMCommon/PrivateCommon/**/*.{h}"

  end
  
    s.dependency 'ASIHTTPRequest'
    s.dependency 'YYCache'
    s.dependency 'YYModel'
    s.dependency 'ProtocolBuffers'
    s.dependency 'CocoaAsyncSocket'
    s.dependency 'UICKeyChainStore'
    # 避免崩溃
    s.dependency 'AvoidCrash'
    
    s.dependency 'CocoaLumberjack'
    
    # s.dependency 'QIMOpenSSL'
    s.dependency 'QIMKitVendor'
    s.dependency 'QIMCommonCategories'
    s.dependency 'QIMDataBase'
    s.dependency 'QIMPublicRedefineHeader'

    s.frameworks = 'Foundation', 'CoreTelephony', 'SystemConfiguration', 'AudioToolbox', 'AVFoundation', 'UserNotifications', 'CoreTelephony','QuartzCore', 'CoreGraphics', 'Security'
    s.libraries = 'sqlite3.0', 'stdc++', 'bz2'

end