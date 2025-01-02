{ pkgs, ... }:
# lua
''
  local uv = vim.loop

  local function copy_file(src, dest)
    local src_fd = assert(uv.fs_open(src, "r", 438)) -- 438 is octal 0666
    local stat = assert(uv.fs_fstat(src_fd))
    local data = assert(uv.fs_read(src_fd, stat.size, 0))
    assert(uv.fs_close(src_fd))

    local dest_fd = assert(uv.fs_open(dest, "w", stat.mode))
    assert(uv.fs_write(dest_fd, data, 0))
    assert(uv.fs_close(dest_fd))
  end

  local function copy_folder(src, dest)
    -- Ensure the destination directory exists
    uv.fs_mkdir(dest, 511) -- 511 is octal 0777

    local dir = assert(uv.fs_scandir(src))
    while true do
      local name, file_type = uv.fs_scandir_next(dir)
      if not name then break end

      local src_path = src .. "/" .. name
      local dest_path = dest .. "/" .. name

      if file_type == "directory" then
        copy_folder(src_path, dest_path)
      else
        copy_file(src_path, dest_path)
      end
    end
  end


  local function folder_exists(path)
    local stat = uv.fs_stat(path)
    return stat and stat.type == "directory"
  end

  local jdtls = require('jdtls')

  local java_lsp_path = "${pkgs.jdt-language-server}/share/java/jdtls"
  local java_dap_path = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug"
  local java_test_path = "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test"
  local lombok_path = "${pkgs.lombok}/share/java"

  vim.print(java_lsp_path)
  vim.print(java_test_path)
  vim.print(java_dap_path)

  local bundles = {
    vim.fn.glob(java_dap_path .. '/server/com.microsoft.java.debug.plugin-*.jar', true),
  }
  vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. '/server/*.jar', true), '\n'))

  vim.print(vim.inspect(bundles))

  -- NOTE: Decrease the amount of files to improve speed(Experimental).
  -- INFO: It's annoying to edit the version again and again.
  local equinox_path = vim.split(vim.fn.glob(java_lsp_path .. '/plugins/*jar'), '\n')

  local equinox_launcher = ""

  for _, file in pairs(equinox_path) do
    if file:match('launcher_') then
      equinox_launcher = file
      break
    end
  end

  local workspace_path = vim.fn.stdpath('data') .. '/jdtls-workspace'

  local os_name = ""
  if vim.fn.has('mac') == 1 then
    os_name = 'mac'
  elseif vim.fn.has('unix') == 1 then
    os_name = 'linux'
  elseif vim.fn.has('win32') == 1 then
    os_name = 'win'
  else
    vim.notify('Unsupported OS', vim.log.levels.WARN, { title = 'Jdtls' })
  end

  local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
  local workspace_dir = workspace_path .. '/' .. project_name
  local config_dir = vim.fn.stdpath('data') .. '/jdtls-config'
  -- local config_dir = java_lsp_path .. '/config_' .. os_name 

  -- WARN: IMPORTANT! The folder of a config for equinox must be writeable!
  if not folder_exists(config_dir) then
    copy_folder(java_lsp_path .. '/config_' .. os_name, config_dir)
  end

  local capabilities = require('blink.cmp').get_lsp_capabilities()
  local extendedClientCapabilities = require('jdtls').extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  local config = {
    cmd = {
      'java',
      '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      '-Dosgi.bundles.defaultStartLevel=4',
      '-Declipse.product=org.eclipse.jdt.ls.core.product',
      '-Dlog.protocol=true',
      '-Dlog.level=ALL',
      '-javaagent:' .. lombok_path .. '/lombok.jar',
      '-Xms1g',
      '--add-modules=ALL-SYSTEM',
      '--add-opens',
      'java.base/java.util=ALL-UNNAMED',
      '--add-opens',
      'java.base/java.lang=ALL-UNNAMED',
      '-jar',
      equinox_launcher,
      '-configuration',
      config_dir,
      '-data',
      workspace_dir,
    },
    capabilities = capabilities,
    -- 💀
    -- This is the default if not provided, you can remove it. Or adjust as needed.
    -- One dedicated LSP server & client will be started per unique root_dir
    root_dir = require('jdtls.setup').find_root(root_markers),
    init_options = {
      bundles = bundles,
      extendedClientCapabilities = extendedClientCapabilities,
    },
    java = {
      settings = {
        format = {
          enable = false -- Delegate formatting to conform-nvim plugin
        },
        eclipse = {
          downloadSources = true,
        },
        maven = {
          downloadSources = true,
        },
        implementationsCodeLens = {
          enabled = true,
        },
        references = {
          includeDecompiledSources = true,
        },
        signatureHelp = { enabled = true },
        -- Use the fernflower decompiler when using the javap command to decompile byte code back to java code
        contentProvider = {
            preferred = "fernflower"
        },
        -- Setup automatical package import oranization on file save
        saveActions = {
            organizeImports = true
        },
        -- Customize completion options
        completion = {
            -- When using an unimported static method, how should the LSP rank possible places to import the static method from
            favoriteStaticMembers = {
                "org.hamcrest.MatcherAssert.assertThat",
                "org.hamcrest.Matchers.*",
                "org.hamcrest.CoreMatchers.*",
                "org.junit.jupiter.api.Assertions.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.mockito.Mockito.*",
            },
            -- Try not to suggest imports from these packages in the code action window
            filteredTypes = {
                "com.sun.*",
                "io.micrometer.shaded.*",
                "java.awt.*",
                "jdk.*",
                "sun.*",
            },
            -- Set the order in which the language server should organize imports
            importOrder = {
                "java",
                "jakarta",
                "javax",
                "com",
                "org",
            }
        },
        sources = {
            -- How many classes from a specific package should be imported before automatic imports combine them all into a single import
            organizeImports = {
                starThreshold = 9999,
                staticThreshold = 9999
            }
        },
        -- How should different pieces of code be generated?
        codeGeneration = {
            -- When generating toString use a json format
            toString = {
                template = "''${object.className}{''${member.name()}=''${member.value}, ''${otherMembers}}"
            },
            -- When generating hashCode and equals methods use the java 7 objects method
            hashCodeEquals = {
                useJava7Objects = true
            },
            -- When generating code use code blocks
            useBlocks = true
        },
         -- If changes to the project will require the developer to update the projects configuration advise the developer before accepting the change
        configuration = {
            updateBuildConfiguration = "interactive"
        },
        -- enable code lens in the lsp
        referencesCodeLens = {
            enabled = true
        },
        -- enable inlay hints for parameter names,
        inlayHints = {
            parameterNames = {
                enabled = "all"
            }
        }
      }
    },
    flags = {
      allow_incremental_sync = true,
    },
  }

  jdtls.start_or_attach(config)
''
