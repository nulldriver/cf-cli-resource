#!/usr/bin/env shellspec

set -euo pipefail

Describe 'logger.sh'
  Include resource/lib/logger.sh
  Include resource/lib/color.sh

  BeforeAll 'unset NO_COLOR'

  Describe 'logger::set_level'
    It 'sets the log level to DEBUG'
      When call logger::set_level DEBUG
      The variable LOGGER_LEVEL should equal 0
    End

    It 'sets the log level to INFO'
      When call logger::set_level INFO
      The variable LOGGER_LEVEL should equal 1
    End

    It 'sets the log level to WARN'
      When call logger::set_level WARN
      The variable LOGGER_LEVEL should equal 2
    End

    It 'sets the log level to ERROR'
      When call logger::set_level ERROR
      The variable LOGGER_LEVEL should equal 3
    End

    It 'returns an error for an unknown log level'
      When run logger::set_level UNKNOWN
      The status should be failure
      The output should include 'Unknown log level: UNKNOWN'
    End
  End

  Describe 'logger::debug'
    It 'logs a debug message'
      BeforeCall 'logger::set_level "DEBUG"'
      When call logger::debug "This is a debug message"
      The output should eq "${COLOR_FG_BOLD_BLUE}DEBUG${COLOR_RESET} This is a debug message"
    End

    It 'does not log a debug message when the log level is INFO'
      BeforeCall 'logger::set_level "INFO"'
      When call logger::debug "This is a debug message"
      The output should eq ""
    End
  End

  Describe 'logger::info'
    It 'logs an info message'
      When call logger::info "This is an info message"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is an info message"
    End

    It 'does not log an info message when the log level is WARN'
      BeforeCall 'logger::set_level "WARN"'
      When call logger::info "This is an info message"
      The output should eq ""
    End
  End

  Describe 'logger::warn'
    It 'logs a warn message'
      When call logger::warn "This is a warn message"
      The output should eq "${COLOR_FG_BOLD_YELLOW}WARN${COLOR_RESET} This is a warn message"
    End

    It 'does not log a warn message when the log level is ERROR'
      BeforeCall 'logger::set_level "ERROR"'
      When call logger::warn "This is a warn message"
      The output should eq ""
    End
  End

  Describe 'logger::error'
    It 'logs an error message'
      When call logger::error "This is an error message"
      The output should eq "${COLOR_FG_BOLD_RED}ERROR${COLOR_RESET} This is an error message"
    End
  End

  Describe 'log colorization'
    It 'colorizes a message with black text'
      When call logger::info "This is a #black(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BLACK}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with red text'
      When call logger::info "This is a #red(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_RED}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with green text'
      When call logger::info "This is a #green(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_GREEN}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with yellow text'
      When call logger::info "This is a #yellow(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_YELLOW}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with blue text'
      When call logger::info "This is a #blue(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BLUE}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with magenta text'
      When call logger::info "This is a #magenta(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_MAGENTA}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with cyan text'
      When call logger::info "This is a #cyan(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_CYAN}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with white text'
      When call logger::info "This is a #white(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_WHITE}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with bold black text'
      When call logger::info "This is a #boldBlack(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BOLD_BLACK}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with bold red text'
      When call logger::info "This is a #boldRed(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BOLD_RED}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with bold green text'
      When call logger::info "This is a #boldGreen(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BOLD_GREEN}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with bold yellow text'
      When call logger::info "This is a #boldYellow(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BOLD_YELLOW}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with bold blue text'
      When call logger::info "This is a #boldBlue(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BOLD_BLUE}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with bold magenta text'
      When call logger::info "This is a #boldMagenta(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BOLD_MAGENTA}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with bold cyan text'
      When call logger::info "This is a #boldCyan(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BOLD_CYAN}colorized${COLOR_RESET} message"
    End
    It 'colorizes a message with bold white text'
      When call logger::info "This is a #boldWhite(%s) message" "colorized"
      The output should eq "${COLOR_FG_BOLD_GREEN}INFO${COLOR_RESET} This is a ${COLOR_FG_BOLD_WHITE}colorized${COLOR_RESET} message"
    End
  End

End
