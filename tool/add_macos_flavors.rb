#!/usr/bin/env ruby
# Add Flutter flavor support to the macOS Runner project so that
# `flutter run -d macos` works with `default-flavor: dev` (or prod).
#
# Creates build configurations:
#   Debug-dev, Release-dev, Profile-dev, Debug-prod, Release-prod, Profile-prod
# and shared Xcode schemes: "dev" and "prod".
#
# The flavor build configurations reuse the same xcconfig chain as their base
# configuration (no per-flavor CocoaPods targets are needed for macOS).

require 'xcodeproj'

project_path = File.join(__dir__, '..', 'macos', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

flavors = ['dev', 'prod']
base_configs = {
  'Debug' => :debug,
  'Release' => :release,
  'Profile' => :release
}

added = false

flavors.each do |flavor|
  base_configs.each do |base_name, type|
    config_name = "#{base_name}-#{flavor}"

    # Project-level configuration
    project_base = project.build_configurations.find { |c| c.name == base_name }
    next unless project_base
    unless project.build_configurations.any? { |c| c.name == config_name }
      project_config = project.add_build_configuration(config_name, type)
      project_config.build_settings = project_base.build_settings.clone
      project_config.base_configuration_reference = project_base.base_configuration_reference
      added = true
    end

    # Every target must get the same set of configurations, otherwise CocoaPods
    # resolves SWIFT_VERSION inconsistently (project-level flavor configs are
    # inherited by targets that lack their own copy).
    project.targets.each do |target|
      target_base = target.build_configurations.find { |c| c.name == base_name }
      next unless target_base
      unless target.build_configurations.any? { |c| c.name == config_name }
        target_config = target.add_build_configuration(config_name, type)
        target_config.build_settings = target_base.build_settings.clone
        target_config.base_configuration_reference = target_base.base_configuration_reference
        added = true
      end
    end
  end
end

project.save
puts "Build configurations: #{project.build_configurations.map(&:name).join(', ')}"

# Create shared schemes "dev" and "prod" from the existing Runner scheme.
schemes_dir = File.join(project_path, 'xcshareddata', 'xcschemes')
runner_scheme_path = File.join(schemes_dir, 'Runner.xcscheme')
abort "Runner.xcscheme not found at #{runner_scheme_path}" unless File.exist?(runner_scheme_path)

runner_scheme = File.read(runner_scheme_path)

flavors.each do |flavor|
  scheme = runner_scheme.dup
  scheme = scheme.gsub('buildConfiguration = "Debug"', "buildConfiguration = \"Debug-#{flavor}\"")
  scheme = scheme.gsub('buildConfiguration = "Release"', "buildConfiguration = \"Release-#{flavor}\"")
  scheme = scheme.gsub('buildConfiguration = "Profile"', "buildConfiguration = \"Profile-#{flavor}\"")
  File.write(File.join(schemes_dir, "#{flavor}.xcscheme"), scheme)
  puts "Created scheme: #{flavor}"
end

puts added ? "\n✅ Added macOS flavor configurations." : "\nFlavor configurations already exist. Skipped."
