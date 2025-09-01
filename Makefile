.PHONY: help setup clean build test lint format generate run-dev run-prod deps install upgrade analyze doctor icons splash env-setup run-cors check-fvm \
		build-android build-android-bundle build-ios build-web run-web devices l10n assets outdated security logs emulator simulator \
		ci pre-commit deploy-android deploy-ios deploy-web reset profile debug-android debug-ios performance size-analyze \
		api-check schema build-all dev-setup dev-start dev-test dev-full update-deps fix-deps backup-env info

# Terra Allwert Flutter App Makefile
# Use FVM for Flutter version management
FLUTTER := fvm flutter
DART := fvm dart
FVM_VERSION := 3.32.5

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Show this help message
	@echo '$(BLUE)Terra Allwert Flutter App$(NC)'
	@echo '$(YELLOW)Usage: make [target]$(NC)'
	@echo ''
	@echo '$(GREEN)Available targets:$(NC)'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-fvm: ## Check FVM installation and Flutter version
	@echo "$(YELLOW)🔍 Checking FVM and Flutter setup...$(NC)"
	@if ! command -v fvm > /dev/null 2>&1; then \
		echo "$(RED)❌ FVM not found. Install with: dart pub global activate fvm$(NC)"; \
		exit 1; \
	fi
	@if ! fvm list | grep -q "$(FVM_VERSION)"; then \
		echo "$(YELLOW)⬇️ Installing Flutter $(FVM_VERSION)...$(NC)"; \
		fvm install $(FVM_VERSION); \
	fi
	@if ! fvm list | grep -q "$(FVM_VERSION) (active)"; then \
		echo "$(YELLOW)🔄 Using Flutter $(FVM_VERSION)...$(NC)"; \
		fvm use $(FVM_VERSION); \
	fi
	@echo "$(GREEN)✅ FVM setup complete$(NC)"

setup: check-fvm env-setup deps generate ## Complete project setup
	@echo "$(GREEN)🎉 Terra Allwert project setup complete!$(NC)"

env-setup: ## Setup environment files
	@echo "$(YELLOW)📝 Setting up environment files...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(YELLOW)⚠️  Please update .env with your configuration$(NC)"; \
	else \
		echo "$(GREEN)✅ .env already exists$(NC)"; \
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
	@echo "$(YELLOW)🔬 Running static analysis...$(NC)"
	$(DART) analyze --fatal-infos
	@echo "$(GREEN)✅ Analysis complete$(NC)"

doctor: ## Run flutter doctor
	@echo "$(YELLOW)🩺 Running flutter doctor...$(NC)"
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
	@echo "$(BLUE)🚀 Running Terra Allwert in development mode...$(NC)"
	$(FLUTTER) run --debug

run-prod: ## Run in production mode
	@echo "$(BLUE)🚀 Running Terra Allwert in production mode...$(NC)"
	$(FLUTTER) run --release

run-web: ## Run on web
	@echo "$(BLUE)🌐 Running Terra Allwert on web...$(NC)"
	$(FLUTTER) run -d chrome --web-port 3001

run-cors: ## Run with CORS disabled (development only)
	@echo "$(YELLOW)🚀 Running Terra Allwert with CORS disabled...$(NC)"
	@echo "$(YELLOW)📋 Desabilitando CORS no Chrome para desenvolvimento local$(NC)"
	@echo "$(RED)⚠️  ATENÇÃO: Use apenas para desenvolvimento!$(NC)"
	@echo "$(YELLOW)🔄 Matando instâncias antigas do Chrome com CORS desabilitado...$(NC)"
	@pkill -f "Chrome.*--disable-web-security" 2>/dev/null || true
	@echo "$(BLUE)▶️  Executando Flutter com Chrome e CORS desabilitado...$(NC)"
	$(FLUTTER) run -d chrome \
		--web-port 3001 \
		--dart-define=FLUTTER_WEB_USE_SKIA=true \
		--web-browser-flag="--disable-web-security" \
		--web-browser-flag="--disable-features=VizDisplayCompositor" \
		--web-browser-flag="--user-data-dir=/tmp/chrome_dev_profile"
	@echo "$(GREEN)✅ Aplicação finalizada$(NC)"

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

# Terra Allwert specific commands
api-check: ## Check if API is running
	@echo "$(YELLOW)🔍 Checking API connection...$(NC)"
	@if curl -s http://127.0.0.1:3000/graphql > /dev/null; then \
		echo "$(GREEN)✅ API is running on localhost:3000$(NC)"; \
	else \
		echo "$(RED)❌ API is not running on localhost:3000$(NC)"; \
		echo "$(YELLOW)💡 Start the API server first$(NC)"; \
		exit 1; \
	fi

schema: ## Generate GraphQL schema
	@echo "$(YELLOW)🔄 Generating GraphQL schema...$(NC)"
	@if [ ! -d "lib/infra/graphql/generated" ]; then mkdir -p lib/infra/graphql/generated; fi
	@curl -s http://127.0.0.1:3000/graphql \
		-H 'Content-Type: application/json' \
		-d '{"query":"query IntrospectionQuery { __schema { queryType { name } mutationType { name } subscriptionType { name } types { ...FullType } directives { name description locations args { ...InputValue } } } } fragment FullType on __Type { kind name description fields(includeDeprecated: true) { name description args { ...InputValue } type { ...TypeRef } isDeprecated deprecationReason } inputFields { ...InputValue } interfaces { ...TypeRef } enumValues(includeDeprecated: true) { name description isDeprecated deprecationReason } possibleTypes { ...TypeRef } } fragment InputValue on __InputValue { name description type { ...TypeRef } defaultValue } fragment TypeRef on __Type { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name } } } } } } } }"}' \
		| jq '.data' > lib/infra/graphql/generated/schema.json || echo "$(RED)❌ Failed to fetch schema$(NC)"

build-all: build-android build-ios build-web ## Build for all platforms
	@echo "$(GREEN)🎉 All platform builds complete!$(NC)"

ci: clean deps generate format-check analyze test ## Run CI pipeline
	@echo "$(GREEN)✅ CI pipeline completed successfully!$(NC)"

pre-commit: format lint test ## Run pre-commit checks
	@echo "$(GREEN)✅ Pre-commit checks passed!$(NC)"

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
	@echo "$(GREEN)♻️  Terra Allwert project reset complete!$(NC)"

profile: ## Run in profile mode
	@echo "$(BLUE)📊 Running Terra Allwert in profile mode...$(NC)"
	$(FLUTTER) run --profile

debug-android: ## Debug Android app
	@echo "$(BLUE)🐛 Debugging Terra Allwert Android app...$(NC)"
	$(FLUTTER) run --debug

debug-ios: ## Debug iOS app  
	@echo "$(BLUE)🐛 Debugging Terra Allwert iOS app...$(NC)"
	$(FLUTTER) run --debug -d ios

performance: ## Profile app performance
	@echo "$(YELLOW)📊 Profiling Terra Allwert performance...$(NC)"
	$(FLUTTER) run --profile --trace-startup

size-analyze: ## Analyze app size
	@echo "$(YELLOW)📏 Analyzing Terra Allwert app size...$(NC)"
	$(FLUTTER) build apk --analyze-size
	$(FLUTTER) build appbundle --analyze-size

# Development workflow shortcuts
dev-setup: check-fvm env-setup deps ## Quick development setup
	@echo "$(GREEN)🚀 Terra Allwert dev setup complete!$(NC)"

dev-start: api-check run-cors ## Start development with API check and CORS disabled

dev-test: format analyze test ## Full development testing pipeline
	@echo "$(GREEN)✅ Development tests passed!$(NC)"

dev-full: clean dev-setup generate dev-test ## Complete development workflow
	@echo "$(GREEN)🎉 Full development workflow complete!$(NC)"

# Maintenance commands
update-deps: ## Update and audit dependencies
	@echo "$(YELLOW)⬆️ Updating dependencies...$(NC)"
	$(FLUTTER) pub upgrade --major-versions
	$(MAKE) outdated

fix-deps: ## Fix dependency issues
	@echo "$(YELLOW)🔧 Fixing dependency issues...$(NC)"
	$(FLUTTER) pub deps
	$(FLUTTER) pub get

# Backup commands  
backup-env: ## Backup environment files
	@echo "$(YELLOW)💾 Backing up environment files...$(NC)"
	@cp .env .env.backup.$(shell date +%Y%m%d_%H%M%S) 2>/dev/null || echo "No .env file to backup"

# Information commands
info: ## Show project information
	@echo "$(BLUE)📋 Terra Allwert Project Information$(NC)"
	@echo "Flutter Version: $(shell $(FLUTTER) --version | head -1)"
	@echo "Dart Version: $(shell $(DART) --version)"
	@echo "FVM Version: $(shell fvm --version 2>/dev/null || echo 'Not installed')"
	@echo "Project Directory: $(shell pwd)"
	@echo "API Endpoint: http://127.0.0.1:3000/graphql"