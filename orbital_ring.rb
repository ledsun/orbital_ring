require 'js'
require 'js/require_remote'
require 'erb'

class OrbitalRing
  include Singleton

  def dir = 'app_root'

  class Loader
    def self.setup
      new.setup OrbitalRing.instance.dir
    end

    def setup(dir)
      Loader.define_const_missing dir, Object
    end

    private

    # const_missingを定義して、見つからない定数をリモートから読み込む
    def self.define_const_missing(dir, mod)
      mod.define_singleton_method(:const_missing) do |id|
        # 定数名をスネークケースに変換して、リモートから読み込む
        feature_name = Util.to_snake_case(id)
        JS::RequireRemote.instance.load("#{dir}/#{feature_name}")

        # 読み込んだモジュールにconst_missingを定義する
        loaded_module = const_get(id)
        Loader.define_const_missing dir, loaded_module
        loaded_module
      end
    end
  end

  module Renderer
    def self.included(base)
      # テンプレートをキャッシュする変数を定義
      base.define_method(:tempaltes_cache) { @tempaltes_cache ||= {} }
    end

    def render(template_name, locals)
      tempaltes_cache[template_name] = load_template(template_name) unless tempaltes_cache[template_name]

      if(locals[:collection])
        # コレクションを渡してテンプレートを呼び出すと
        # テンプレートからは、テンプレートと同じ名前の変数を経由してコレクションの個別のメンバーにアクセスできます。
        locals[:collection].map do
           render_one template_name,
                      { template_name.to_s => _1 }
        end.join
      else
        render_one(template_name, locals)
      end
    end

    private

    def load_template(template_name)
      # テンプレート名から、ファイル名を決定します。
      feature_name = "#{Util.to_snake_case(template_name)}.html.erb"
      path = "#{OrbitalRing.instance.dir}/templates"
      url = "#{path}/#{feature_name}"
      response = JS.global.fetch(url).await
      raise "Failed to fetch template: #{url}" unless response[:status].to_i == 200

      ERB.new(response.text().await.to_s)
    end

    def render_one(template_name, locals)
      # テンプレート内でrenderメソッドを使えるようにするために
      # このメソッドのbindingを指定します。
      b = binding
      locals.each { |key, value| b.local_variable_set key, value }
      tempaltes_cache[template_name].result b
    end
  end

  class Routes
    Events = ['click', 'change', 'input']

    def self.draw(&block)
      instance = self.new
      instance.instance_eval(&block)
    end

    def initialize
      Events.each do |event_name|
        define_event event_name
      end
    end

    private

    def define_event(event_name)
      self.class.define_method(event_name) do |selectors, options|
        root.addEventListener event_name do |event|
          if event[:target].closest(selectors) != JS::Null
            options[:to].call event, options[:params]
          end
        end
      end
    end

    def root
      document = JS.global[:document]
      document.getElementById OrbitalRing.instance.dir
    end
  end

  module Util
    def self.to_snake_case(symbol)
      symbol.to_s
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .downcase
    end
  end
end
