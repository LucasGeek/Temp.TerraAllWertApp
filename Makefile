.PHONY: help setup clean build test lint format generate run-dev run-prod deps install upgrade analyze doctor icons splash env-setup

FLUTTER := flutter
DART := dart

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: env-setup deps generate ## Complete project setup
	@echo "✅ Project setup complete!"

env-setup: ## Setup environment files
	@if [ ! -f .env ]; then \
		echo "📝 Creating .env from .env.example..."; \
		cp .env.example .env; \
		echo "⚠️  Please update .env with your configuration"; \
	else \
		echo "✅ .env already exists"; \
	fi

clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	$(FLUTTER) clean

deps: ## Get dependencies
	@echo "📦 Getting dependencies..."
	$(FLUTTER) pub get

install: deps ## Alias for deps

upgrade: ## Upgrade dependencies
	@echo "⬆️  Upgrading dependencies..."
	$(FLUTTER) pub upgrade

generate: ## Generate code (build_runner)
	@echo "🔄 Generating code..."
	$(DART) run build_runner build --delete-conflicting-outputs

watch: ## Watch for changes and generate code
	@echo "👀 Watching for changes..."
	$(DART) run build_runner watch --delete-conflicting-outputs

test: ## Run tests
	@echo "🧪 Running tests..."
	$(FLUTTER) test

test-coverage: ## Run tests with coverage
	@echo "🧪 Running tests with coverage..."
	$(FLUTTER) test --coverage
	genhtml coverage/lcov.info -o coverage/html

lint: ## Run linter
	@echo "🔍 Running linter..."
	$(DART) analyze

format: ## Format code
	@echo "💅 Formatting code..."
	$(DART) format --fix .

format-check: ## Check code formatting
	@echo "💅 Checking code formatting..."
	$(DART) format --set-exit-if-changed .

analyze: ## Run static analysis
	@echo "🔬 Running static analysis..."
	$(DART) analyze --fatal-infos

doctor: ## Run flutter doctor
	@echo "🩺 Running flutter doctor..."
	$(FLUTTER) doctor -v

build-android: ## Build Android APK
	@echo "🏗️  Building Android APK..."
	$(FLUTTER) build apk --release

build-android-bundle: ## Build Android Bundle
	@echo "🏗️  Building Android Bundle..."
	$(FLUTTER) build appbundle --release

build-ios: ## Build iOS
	@echo "🏗️  Building iOS..."
	$(FLUTTER) build ios --release

build-web: ## Build Web
	@echo "🏗️  Building Web..."
	$(FLUTTER) build web --release

run-dev: ## Run in development mode
	@echo "🚀 Running in development mode..."
	$(FLUTTER) run --debug

run-prod: ## Run in production mode
	@echo "🚀 Running in production mode..."
	$(FLUTTER) run --release

run-web: ## Run on web
	@echo "🌐 Running on web..."
	$(FLUTTER) run -d chrome

devices: ## List available devices
	@echo "📱 Available devices:"
	$(FLUTTER) devices

icons: ## Generate app icons
	@echo "🎨 Generating app icons..."
	$(DART) run flutter_launcher_icons

splash: ## Generate splash screen
	@echo "💧 Generating splash screen..."
	$(DART) run flutter_native_splash:create

l10n: ## Generate localizations
	@echo "🌍 Generating localizations..."
	$(FLUTTER) gen-l10n

assets: ## Generate assets
	@echo "🖼️  Generating assets..."
	$(FLUTTER) packages pub run build_runner build

outdated: ## Check for outdated packages
	@echo "📊 Checking for outdated packages..."
	$(FLUTTER) pub outdated

security: ## Security audit
	@echo "🔒 Running security audit..."
	$(DART) pub deps

logs: ## Show logs
	@echo "📋 Showing logs..."
	$(FLUTTER) logs

emulator: ## Start Android emulator
	@echo "📱 Starting Android emulator..."
	emulator -avd @flutter_emulator &

simulator: ## Start iOS simulator (macOS only)
	@echo "📱 Starting iOS simulator..."
	open -a Simulator

ci: clean deps generate format-check analyze test ## Run CI pipeline
	@echo "✅ CI pipeline completed successfully!"

pre-commit: format lint test ## Run pre-commit checks
	@echo "✅ Pre-commit checks passed!"

deploy-android: build-android ## Deploy to Android
	@echo "🚀 Deploying to Android..."
	@echo "Upload the APK from build/app/outputs/flutter-apk/app-release.apk"

deploy-ios: build-ios ## Deploy to iOS
	@echo "🚀 Deploying to iOS..."
	@echo "Use Xcode or Application Loader to upload to App Store"

deploy-web: build-web ## Deploy to Web
	@echo "🚀 Building for web deployment..."
	@echo "Deploy the contents of build/web/"

reset: clean ## Reset project (clean + get deps + generate)
	$(MAKE) setup
	@echo "♻️  Project reset complete!"

profile: ## Run in profile mode
	@echo "📊 Running in profile mode..."
	$(FLUTTER) run --profile

debug-android: ## Debug Android app
	@echo "🐛 Debugging Android app..."
	$(FLUTTER) run --debug

debug-ios: ## Debug iOS app  
	@echo "🐛 Debugging iOS app..."
	$(FLUTTER) run --debug -d ios

performance: ## Profile app performance
	@echo "📊 Profiling app performance..."
	$(FLUTTER) run --profile --trace-startup

size-analyze: ## Analyze app size
	@echo "📏 Analyzing app size..."
	$(FLUTTER) build apk --analyze-size
	$(FLUTTER) build appbundle --analyze-size