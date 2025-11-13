#!/bin/bash

# Supabase Development Helper Script
# This script helps manage the local Supabase development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Supabase CLI is installed
check_supabase_cli() {
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI is not installed. Please install it with:"
        echo "npm install -g supabase"
        exit 1
    fi
}

# Check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Initialize Supabase project
init_supabase() {
    print_status "Initializing Supabase project..."
    if [ ! -d "supabase" ]; then
        supabase init
        print_success "Supabase project initialized"
    else
        print_warning "Supabase project already initialized"
    fi
}

# Start local Supabase services
start_services() {
    print_status "Starting local Supabase services..."
    supabase start
    print_success "Local Supabase services started"
    
    # Show connection info
    print_status "Connection Information:"
    echo "  Studio URL: $(supabase status | grep 'Studio URL' | cut -d' ' -f3)"
    echo "  DB URL: $(supabase status | grep 'DB URL' | cut -d' ' -f3)"
    echo "  Anon Key: $(supabase status | grep 'anon key' | cut -d' ' -f3)"
    echo "  Service Role Key: $(supabase status | grep 'service_role key' | cut -d' ' -f4)"
}

# Stop local Supabase services
stop_services() {
    print_status "Stopping local Supabase services..."
    supabase stop
    print_success "Local Supabase services stopped"
}

# Reset database
reset_database() {
    print_status "Resetting database..."
    supabase db reset
    print_success "Database reset complete"
}

# Apply migrations
apply_migrations() {
    print_status "Applying migrations..."
    supabase db push
    print_success "Migrations applied"
}

# Create new migration
create_migration() {
    if [ -z "$1" ]; then
        print_error "Please provide a migration name"
        echo "Usage: ./supabase_dev.sh create <migration_name>"
        exit 1
    fi
    
    print_status "Creating new migration: $1"
    supabase migration new "$1"
    print_success "Migration created: supabase/migrations/$(ls -t supabase/migrations/ | head -1)"
}

# Show migration status
migration_status() {
    print_status "Migration status:"
    supabase migration list
}

# Generate types
generate_types() {
    print_status "Generating TypeScript types..."
    supabase gen types typescript --local > lib/types/supabase.ts
    print_success "Types generated: lib/types/supabase.ts"
}

# Open database shell
open_shell() {
    print_status "Opening database shell..."
    supabase db shell
}

# Show help
show_help() {
    echo "Supabase Development Helper"
    echo ""
    echo "Usage: ./supabase_dev.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init                 Initialize Supabase project"
    echo "  start                Start local services"
    echo "  stop                 Stop local services"
    echo "  reset                Reset database"
    echo "  migrate              Apply migrations"
    echo "  create <name>        Create new migration"
    echo "  status               Show migration status"
    echo "  types                Generate TypeScript types"
    echo "  shell                Open database shell"
    echo "  help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./supabase_dev.sh init"
    echo "  ./supabase_dev.sh start"
    echo "  ./supabase_dev.sh create add_user_avatar"
    echo "  ./supabase_dev.sh migrate"
    echo "  ./supabase_dev.sh reset"
}

# Main script logic
case "$1" in
    init)
        check_supabase_cli
        check_docker
        init_supabase
        ;;
    start)
        check_supabase_cli
        check_docker
        init_supabase
        start_services
        ;;
    stop)
        check_supabase_cli
        stop_services
        ;;
    reset)
        check_supabase_cli
        reset_database
        ;;
    migrate)
        check_supabase_cli
        apply_migrations
        ;;
    create)
        check_supabase_cli
        create_migration "$2"
        ;;
    status)
        check_supabase_cli
        migration_status
        ;;
    types)
        check_supabase_cli
        generate_types
        ;;
    shell)
        check_supabase_cli
        open_shell
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac