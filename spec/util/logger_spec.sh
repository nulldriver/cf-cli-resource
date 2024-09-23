#!/usr/bin/env shellspec

set -euo pipefail

Describe 'logger.sh'
    Include resource/lib/logger.sh

    unset NO_COLOR
    logger::export_colors

    It 'prints info message with blue color'
        When call logger::info "This is an info message with #yellow(%s) and #green(%s)." "text (with) parenthesis" "(another) text"
        The output should equal "${GREEN}INFO${RESET} This is an info message with ${YELLOW}text (with) parenthesis${RESET} and ${GREEN}(another) text${RESET}."
    End

    It 'prints warn message with red color'
        When call logger::warn "This is an info message with #yellow(%s) and #green(%s)." "text (with) parenthesis" "(another) text"
        The output should equal "${RED}WARN${RESET} This is an info message with ${YELLOW}text (with) parenthesis${RESET} and ${GREEN}(another) text${RESET}."
    End

    It 'prints error message with bold red color'
        When call logger::error "This is an info message with #yellow(%s) and #green(%s)." "text (with) parenthesis" "(another) text"
        The output should equal "${BOLD_RED}ERROR${RESET} This is an info message with ${YELLOW}text (with) parenthesis${RESET} and ${GREEN}(another) text${RESET}."
    End
End
