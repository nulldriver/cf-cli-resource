#!/usr/bin/env shellspec

set -euo pipefail

Describe 'config'
  Include resource/lib/error-codes.sh

  get_path_without_cf_binaries() {
    cd $(mktemp -d "$TMPDIR/usr_local_bin.XXXXXX")
    ln -s $(which jq) "$PWD/jq"
    ln -s $(which yq) "$PWD/yq"
    echo "/bin:/usr/bin:$PWD"
  }

  It can 'error if default cf cli (v6) not found'
    put_without_default_cf_binary_found() {
      local config=$(
        %text
        #|source:
      )
      PATH=$(get_path_without_cf_binaries)
      CCR_CF_CLI_VERSION=6
      put "$config"
    }
    When call put_without_default_cf_binary_found
    The status should eq $E_CF_CLI_BINARY_NOT_FOUND
    The error should include "cf cli v6 not found: Please ensure the v6 executable is named 'cf' and is available on the PATH"
  End

  It can 'error if cf cli v6 not found'
    put_without_cf_v6_binary_found() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 6
      )
      PATH=$(get_path_without_cf_binaries)
      put "$config"
    }
    When call put_without_cf_v6_binary_found
    The status should eq $E_CF_CLI_BINARY_NOT_FOUND
    The error should include "cf cli v6 not found: Please ensure the v6 executable is named 'cf' and is available on the PATH"
  End

  It can 'error if cf cli v7 not found'
    put_without_cf_v7_binary_found() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 7
      )
      PATH=$(get_path_without_cf_binaries)
      put "$config"
    }
    When call put_without_cf_v7_binary_found
    The status should eq $E_CF_CLI_BINARY_NOT_FOUND
    The error should include "cf cli v7 not found: Please ensure the v7 executable is named 'cf7' and is available on the PATH"
  End

  It can 'error if cf cli v8 not found'
    put_without_cf_v8_binary_found() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 8
      )
      PATH=$(get_path_without_cf_binaries)
      put "$config"
    }
    When call put_without_cf_v8_binary_found
    The status should eq $E_CF_CLI_BINARY_NOT_FOUND
    The error should include "cf cli v8 not found: Please ensure the v8 executable is named 'cf8' and is available on the PATH"
  End

  It can 'error if unsupported cf cli version specified'
    put_with_unsupported_cf_binary_specified() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 0
      )
      put "$config"
    }
    When call put_with_unsupported_cf_binary_specified
    The status should eq $E_UNSUPPORTED_CF_CLI_VERSION
    The error should end with "unsupported cf cli version: 0"
  End

  It can 'default to cf cli v6'
    put_using_cf_v6_binary_as_default() {
      local config=$(
        %text
        #|source:
      )
      CCR_CF_CLI_VERSION=6
      put "$config"
    }
    When call put_using_cf_v6_binary_as_default
    The status should be failure
    The error should include "cf version 6"
  End

  It can 'use cf cli v6'
    put_using_cf_v6_binary() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 6
      )
      put "$config"
    }
    When call put_using_cf_v6_binary
    The status should be failure
    The error should include "cf version 6"
  End

  It can 'use cf cli v7'
    put_using_cf_v7_binary() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 7
      )
      put "$config"
    }
    When call put_using_cf_v7_binary
    The status should be failure
    The error should include "cf7 version 7"
  End

  It can 'use cf cli v8'
    put_using_cf_v8_binary() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 8
      )
      put "$config"
    }
    When call put_using_cf_v8_binary
    The status should be failure
    The error should include "cf8 version 8"
  End

  It can 'mock cf cli v6'
    Mock cf
      echo "cf version 6 (mock)"
    End
    put_using_cf_v6_binary() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 6
      )
      put "$config"
    }
    When call put_using_cf_v6_binary
    The status should be failure
    The error should include "cf version 6 (mock)"
  End

  It can 'mock cf cli v7'
    Mock cf7
      echo "cf version 7 (mock)"
    End
    put_using_cf_v7_binary() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 7
      )
      put "$config"
    }
    When call put_using_cf_v7_binary
    The status should be failure
    The error should include "cf version 7 (mock)"
  End

  It can 'mock cf cli v8'
    Mock cf8
      echo "cf version 8 (mock)"
    End
    put_using_cf_v8_binary() {
      local config=$(
        %text
        #|source:
        #|  cf_cli_version: 8
      )
      put "$config"
    }
    When call put_using_cf_v8_binary
    The status should be failure
    The error should include "cf version 8 (mock)"
  End
End
