file "#{Webruby.build_dir}/gem_library.js" => :gen_gems_config
file "#{Webruby.build_dir}/gem_append.js" => :gen_gems_config
file "#{Webruby.build_dir}/gem_test_library.js" => :gen_gems_config
file "#{Webruby.build_dir}/gem_test_append.js" => :gen_gems_config

task :gen_gems_config do |t|
  sh "ruby #{SCRIPT_GEN_POST} #{Webruby::App.config.loading_mode} #{Webruby.build_dir}/js_api.js"
  sh "ruby #{SCRIPT_GEN_GEMS_CONFIG} #{Webruby.build_config} #{Webruby.build_dir}/js_api.js #{Webruby.build_dir}/gem_library.js #{Webruby.build_dir}/gem_append.js #{Webruby.build_dir}/gem_test_library.js #{Webruby.build_dir}/gem_test_append.js #{Webruby.build_dir}/functions #{Webruby.full_build_dir}/mruby/emscripten"
end

file "#{Webruby.build_dir}/rbcode.c" => [Webruby.entrypoint_file,
                                         :libmruby,
                                         Webruby.build_dir] +
                                        Webruby.rb_files do |t|
  if Webruby::App.config.source_processor == :gen_require
    ENV["MRBC"] = "#{Webruby.full_build_dir}/#{MRBC}"
    sh "ruby #{SCRIPT_GEN_REQUIRE} #{File.expand_path(Webruby.entrypoint_file)} #{Webruby.full_build_dir}/rbcode.c"
  else
    sh "ruby #{MRUBYMIX} #{Webruby.entrypoint_file} #{Webruby.build_dir}/rbcode.rb"
    sh "#{Webruby.build_dir}/#{MRBC} -Bapp_irep -o#{Webruby.build_dir}/rbcode.c #{Webruby.build_dir}/rbcode.rb"
    sh "rm #{Webruby.build_dir}/rbcode.rb"
  end
end

file "#{Webruby.build_dir}/app.c" => ["#{Webruby.build_dir}/rbcode.c",
                                      "#{DRIVER_DIR}/driver.c"] do |t|
  sh "cat #{DRIVER_DIR}/driver.c #{Webruby.build_dir}/rbcode.c > #{Webruby.build_dir}/app.c"
end

file "#{Webruby.build_dir}/app.o" => "#{Webruby.build_dir}/app.c" do |t|
  require_flag = (Webruby::App.config.source_processor == :gen_require) ? ("-DHAS_REQUIRE") : ("")
  sh "#{EMCC} #{EMCC_CFLAGS} #{require_flag} #{Webruby::App.config.cflags.join(' ')} #{Webruby.build_dir}/app.c -o #{Webruby.build_dir}/app.o"
end

file "#{Webruby.build_dir}/#{Webruby::App.config.output_name}" =>
     ["#{Webruby.build_dir}/app.o", :libmruby] + Webruby.gem_js_files do |t|
  func_arg = Webruby.get_exported_arg("#{Webruby.build_dir}/functions",
                                      Webruby::App.config.loading_mode,
                                      [])
  runner_arg = Webruby::App.config.append_file ? "--post-js #{Webruby::App.config.append_file}" : ""

  sh "#{EMLD} #{'-s WASM=1' if ENV['WASM']} #{Webruby.build_dir}/app.o #{Webruby.object_files.join(' ')} #{Webruby::App.config.static_libs.join(' ')} -o #{Webruby.build_dir}/#{Webruby::App.config.output_name} #{Webruby.gem_js_flags} #{func_arg} #{Webruby::App.config.ldflags.join(' ')} #{Webruby::App.config.optimization_flag} #{runner_arg}"
end

file "#{Webruby.build_dir}/mrbtest.js" =>
  [:libmruby_test] + Webruby.gem_test_js_files do |t|
  # loading mode 0 is necessary for mrbtest
  func_arg = Webruby.get_exported_arg("#{Webruby.build_dir}/functions",
                                      0, ['main'])

  sh "#{EMLD} #{Webruby.test_object_files.join(' ')} #{Webruby.object_files.join(' ')} #{Webruby::App.config.static_libs.join(' ')} -o #{Webruby.build_dir}/mrbtest.js -s TOTAL_MEMORY=33554432 #{Webruby.gem_test_js_flags} #{func_arg} #{Webruby::App.config.ldflags.join(' ')} #{Webruby::App.config.optimization_flag}"
end
