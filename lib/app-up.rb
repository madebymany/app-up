require 'singleton'
require 'pathname'
require 'fog'
require "erb"
require "cgi"
require 'active_support/inflector'

class AppUp

  include Singleton
  include ActiveSupport::Inflector

  attr_accessor :settings, :fog_connection, :bucket, :urls

  DEFAULT_YAML_SETTINGS = {
    s3: {
      access_key_id: 'replaceme',
      secret_access_key: 'replaceme',
      region: 'eu-west-1',
      bucket: 'apps'
    },
    app_name: 'YourAppName',
    version: '0.0.1',
    bundle_identifier: 'com.example.your-app-name',
    ios: {
      available: true
    },
    andriod: {
      available: true
    },
    icon: {
      regular: 'image_57x57.png',
      retina:  'image_512x512.png'
    }
  }

  def get_binding
    binding
  end

  def self.load_settings(path = 'app-up.yaml')
    AppUp.instance.settings ||= 
        File.open(path) { |yf| YAML::load( yf ) }
  end

  def self.upload_icons
    settings = AppUp.load_settings
    icons = [settings[:icon][:regular], settings[:icon][:retina]]
    icons.each do |icon|
      upload_file icon, path_with_name(icon)
    end
  end

  def self.apk_link
    path = filepath_with_version(instance.settings[:version], nil, '.apk')
    instance.bucket.files.new(key: path).url(Time.new.to_i + 60*60*24)
  end

  def self.upload_app(app_path, version)
    s3_connect
    new_path = path_with_name filepath_with_version(version, app_path)
    upload_file app_path, new_path
  end

  def self.generate_manifest
    s3_connect
    instance.urls = {
      regular: CGI.escapeHTML(instance.bucket.files.new(
           key: path_with_name(instance.settings[:icon][:regular]))
                .url(Time.new.to_i + 60*60*24)),
      retina: CGI.escapeHTML(instance.bucket.files.new(
           key: path_with_name(instance.settings[:icon][:retina])
           )
                .url(Time.new.to_i + 60*60*24)),
      app: CGI.escapeHTML(instance.bucket.files.new(
           key: path_with_name(
                  filepath_with_version(instance.settings[:version])
                ).url(Time.new.to_i + 60*60*24)
           ),
    }

    template = File.read(File.dirname(__FILE__) + "/manifest.plist.erb")
    ERB.new(template).result(instance.get_binding)
  end

  def self.s3_connect
    settings = load_settings

    instance.fog_connection ||= Fog::Storage.new({
      :provider                 => 'AWS',
      :aws_access_key_id        => settings[:s3][:access_key_id],
      :aws_secret_access_key    => settings[:s3][:secret_access_key],
      :region                   => settings[:s3][:region]
    })

    AppUp.instance.bucket ||=
      instance.fog_connection.directories.get(settings[:s3][:bucket])
  end

  def self.upload_file(path, new_filename)
    s3_connect
    puts "Uploading #{new_filename}"
    AppUp.instance.bucket.files.create(
      :key    => new_filename,
      :body   => File.open(path),
      :public => false
    )
  end

  def self.filepath_with_version(version, path = nil, extention = 'ipa')
    if path
      extention = Pathname.new(path).basename.to_s.split('.').last 
    end

    "#{instance.settings[:app_name].parameterize}-#{version}.#{extention}"
  end

  def self.paramed_app_name
    load_settings[:app_name].parameterize
  end

  def self.path_with_name(name)
    "#{paramed_app_name}/#{name}"
  end

  def self.exit_with_error(message)
    puts "Error: #{message}"
    exit
  end

end
