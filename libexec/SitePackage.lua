--------------------------------------------------------------------------
-- This is a placeholder for site specific functions.
-- @module SitePackage

require("strict")
require("serializeTbl")
require("myGlobals")
require("string_utils")

local Dbg = require("Dbg")
local dbg = Dbg:dbg()
local hook = require("Hook")
PkgBase = require("PkgBase")

-- Add more global config here
software_prefix = os.getenv("SW_PREFIX") or "/opt/sw"
help_email = "arcc-help@uwyo.edu"

-- Fancy names on group headers
-- Fix this
local mapT = {
    grouped = {
        ["/opt/sw/lmod/lmod/modulefiles/Core"]    = "Core Modules",
        ["/opt/sw/lmod/lmod/modulefiles/openmpi"] = "OpenMPI Dependent",
    },
}

local groupT = {
	["Core"]      = pathJoin(software_prefix,"opt"),
	["gnu"]       = pathJoin(software_prefix,"gnu"),
	["intel"]     = pathJoin(software_prefix,"intel"),
	["pgi"]       = pathJoin(software_prefix,"pgi"),
	["llvm"]      = pathJoin(software_prefix,"llvm"),
	["xl"]        = pathJoin(software_prefix,"xl"),
	["cray"]      = pathJoin(software_prefix,"cray"),
	["pathscale"] = pathJoin(software_prefix,"pathscale"),
}

local libT = {"lib","lib64"}

local pyT = {
    ["2.6"] = "python2.6",
    ["2.7"] = "python2.7",
    ["3.4"] = "python3.4",
    ["3.5"] = "python3.5",
}

-- Updated to reflext the configuration settings
-- above in the variable 'software_prefix'
function site_prefix()
    return software_prefix
end

--
-- Hooks
--
function site_hook()
    return "ARCC"
end

function avail_hook(t)
    dbg.print{"avail hook called\n"}
    local availStyle = masterTbl().availStyle
    local styleT     = mapT[availStyle]
    if (not availStyle or availStyle == "system" or styleT == nil) then
        return
    end

    for k,v in pairs(t) do
        for pat,label in pairs(styleT) do
            if (k:find(pat)) then
                t[k] = label
                break
            elseif (k:find(pat,1,true)) then
                t[k] = label
                break
            end
        end
    end
end

-- Simple helper function
function isempty(s)
    return s == nil or s == ''
end

-- Information Setting
function pkg_info(pkg)
    help(pkg.help)
    whatis("Name        : " .. pkg.display_name)
    whatis("Version     : " .. pkg.version)
    whatis("Description : " .. pkg.description)
    whatis("Category    : " .. pkg.category)
    whatis("Keywords    : " .. pkg.keywords)
    whatis("URL         : " .. pkg.url)
    whatis("Prefix      : " .. pkg.prefix)
    whatis("Include Dir : " .. pkg.incdir)
    whatis("Library Dir : " .. pkg.libdir)
end

-- Verify that the software prefix exist
function query_pkg_dir(pkg)
    if not isDir(pkg.prefix) then
        LmodError("\n"..pkg.name.."/"..pkg.version.." does not exist."
                  .."\nPlease inform the system administrator - "
                  ..help_email.."\n")
    end
end

-- See if we should modify the PATH variable
-- Working on the common UNIX FHS of exes being
-- placed in the subdirectory "bin".
function query_bin_dir(pkg)
    if isempty(pkg.bindir) then
        local bindir = pathJoin(pkg.prefix,"bin")
        if isDir(bindir) then
            pkg.bindir = bindir
        end
    end
end

-- See if we should modify the LD_LIBRARY_PATH
-- variable and set developer flags for libraries
-- by checking "lib" and "lib64" subdirectories.
function query_lib_dir(pkg)
    if isempty(pkg.libdir) then
        local libdir = ""
        for k,v in ipairs(libT) do
            libdir = pathJoin(pkg.prefix,v)
        	if isDir(libdir) then
                pkg.libdir = libdir
                break
            end
        end
    end
end

-- Check if there is an "include" directory to
-- set for the developer flags CPPFLAGS.
function query_inc_dir(pkg)
    if isempty(pkg.incdir) then
        local incdir = pathJoin(pkg.prefix,"include")
        if isDir(incdir) then
            pkg.incdir = incdir
        end
    end
end

-- See if we should modify PKG_CONFIG_PATH.
function query_pkgconfig_dir(pkg)
    local pkgconfig = pathJoin(pkg.libdir,"pkgconfig")
    if isDir(pkgconfig) then
        pkg.pkgconfig = pkgconfig
    end
end

-- See if we should modify CMAKE_PREFIX_PATH.
function query_cmake_dir(pkg)
    local cmake = pathJoin(pkg.libdir,"cmake")
    if isDir(cmake) then
        pkg.cmake = cmake
    end
end

-- See if we should modify PYTHONPATH appropriately
function query_python_dir(pkg)
    if "python" ~= pkg.family and isempty(pkg.python) then
        local pydir = ""
        for k,v in pairs(pyT) do
            pydir = pathJoin(pkg.libdir,v)
            if isDir(pydir) then
                pkg.python = pathJoin(pydir,"site-packages")
                break
            end
        end
    end
end

-- See if we should modify PERL5LIB appropriately
function query_perl5_dir(pkg)
    if "perl" ~= pkg.family and isempty(pkg.perl5) then
        local perl5 = pathJoin(pkg.libdir,"perl5")
        if isDir(perl5) then
            pkg.perl5 = perl5
        end
    end
end

-- Meta function to query directories
function query_pkg_dirs(pkg)
    query_pkg_dir(pkg)
    query_bin_dir(pkg)
    query_lib_dir(pkg)
    query_inc_dir(pkg)
    query_pkgconfig_dir(pkg)
    query_cmake_dir(pkg)
    query_python_dir(pkg)
    query_perl5_dir(pkg)
end

-- Module available functions
function prepend_modulepath(subdir)
    local mroot = os.getenv("MODULEPATH_ROOT")
    local mdir  = pathJoin(mroot,subdir)
    prepend_path("MODULEPATH",mdir)
end

function append_modulepath(subdir)
    local mroot = os.getenv("MODULEPATH_ROOT")
    local mdir  = pathJoin(mroot,subdir)
    append_path("MODULEPATH",mdir)
end

-- Prepend Stuff
-- Should pkgconfig and cmake variable ever be
-- prepended or only appended?
function prepend_vars(pkg)
    if not isempty(pkg.bindir) and isDir(pkg.bindir) then
        prepend_path("PATH",pkg.bindir)
    end

    if not isempty(pkg.libdir) and not pkg.ignore_lib then
        prepend_path("LD_LIBRARY_PATH",pkg.libdir)
        
        if not isempty(pkg.pkgconfig) then
            prepend_path("PKG_CONFIG_PATH",pkg.pkgconfig)
        end
        
        if not isempty(pkg.cmake) then
            prepend_path("CMAKE_MODULE_PATH",pkg.cmake)
            --prepend_path("CMAKE_PREFIX_PATH",pkg.prefix)
        end
        -- Outside conditional
        prepend_path("CMAKE_PREFIX_PATH",pkg.prefix)

        if not isempty(pkg.python) and "python" ~= pkg.family then
            prepend_path("PYTHONPATH",pkg.python)
        end

        if not isempty(pkg.perl5) and "perl" ~= pkg.family then
            prepend_path("PERL5LIB",pkg.perl5)
        end
    end
    prepend_path("MANPATH",pathJoin(pkg.prefix,"share","man"))
end

-- Append environment variables appropriately
function append_vars(pkg)
    if not isempty(pkg.bindir) and isDir(pkg.bindir) then
        append_path("PATH",pkg.bindir)
    end

    if not isempty(pkg.libdir) and not pkg.ignore_lib then
        append_path("LD_LIBRARY_PATH",pkg.libdir)

        if not isempty(pkg.pkgconfig) then
            append_path("PKG_CONFIG_PATH",pkg.pkgconfig)
        end

        if not isempty(pkg.cmake) then
            append_path("CMAKE_MODULE_PATH",pkg.cmake)
            --append_path("CMAKE_PREFIX_PATH",pkg.prefix)
        end
        -- Outside conditional
        append_path("CMAKE_PREFIX_PATH",pkg.prefix)

        if not isempty(pkg.python) then
            append_path("PYTHONPATH",pkg.python)
        end

        if not isempty(pkg.perl5) then
            append_path("PERL5LIB",pkg.perl5)
        end
    end
    append_path("MANPATH",pathJoin(pkg.prefix,"share","man"))
end

-- Does dev vars need prepend mode? Doubtful
function dev_vars(pkg)
    setenv(string.upper(pkg.name).."_ROOT",pkg.prefix)
    setenv(string.upper(pkg.name).."_DIR",pkg.prefix)
    setenv(string.upper(pkg.name).."_VERSION",pkg.version)
    if not isempty(pkg.incdir) and not pkg.ignore_inc then
        local inc = pathJoin("-I",pkg.incdir)
        append_path("CPPFLAGS",inc," ")
        setenv(string.upper(pkg.name).."_INC",inc," ")
    end

    if not isempty(pkg.libdir) and not pkg.ignore_lib then
        local lib = pathJoin("-L",pkg.libdir)
                    .. " " 
                    .. pathJoin("-Wl,-rpath,",pkg.libdir)
        append_path("LDFLAGS",lib," ")
        setenv(string.upper(pkg.name).."_LIB",lib)
    end
end

-- Process Compiler Table
function comp_vars(pkg)
   for k,v in pairs(arg.compilers) do
       -- set absolute path if requested
       local val = v:gsub("{bindir}",pkg.bindir)

       -- Provide messages if needed, can remove later
       if "load" == mode() then
           LmodMessage(
             string.format("setting %5s to \"%s\"",k,val)
           )
       else
          LmodMessage(
            string.format("Putting %5s to previous value.",k)
          )
       end
       
       -- Push the values to the given defined keys
       pushenv(k,val)
   end
end

-- Process any extras provided
function extra_vars(pkg)
    for k,v in pairs(arg.extras) do
        -- figure out a way to provide substitutions like below.
        local val = v:gsub("{bindir}",pkg.bindir)
        if "load" == mode() then
            LmodMessage(
              string.format("setting %5s to \"%s\"",k,val)
            )
        else
           LmodMessage(
             string.format("Putting %5s to previous value.",k)
           )
        end
        pushenv(k,val)
    end
end

-- This is the main routine that should called in a modulefile
-- which can initialize the environment provided that the
-- installation provides standard UNIX FHS
function pkg_init(arg)
    local vmode = arg.mode

    local pkg = {}
    local status
    local msg
    
    -- Package Metadata
    pkg.name         = myModuleName()
    pkg.version      = myModuleVersion()
    pkg.family       = arg.family or ""
    pkg.mf           = myFileName()
    pkg.display_name = arg.display_name or ""
    pkg.url          = arg.url or ""
    pkg.category     = arg.category or ""
    pkg.keywords     = arg.keywords or ""
    pkg.description  = arg.description or ""
    pkg.help         = arg.help or ""
    pkg.ignore_inc   = arg.ignore_inc or false
    pkg.ignore_lib   = arg.ignore_lib or false
    pkg.ignore_dev   = arg.ignore_dev or false

    if pkg.ignore_dev then
        pkg.ignore_inc = true
        pkg.ignore_lib = true
    end

    -- Package data
    pkg.prefix       = arg.prefix or ""
    pkg.bindir       = arg.bindir or "" 
    pkg.incdir       = arg.incdir or ""
    pkg.libdir       = arg.libdir or ""
    pkg.pkgconfig    = arg.pkgconfig or ""
    pkg.cmake        = arg.cmake or ""
    pkg.python       = arg.python or ""
    pkg.perl5        = arg.perl5 or ""
    pkg.compilers    = arg.compilers or nil
    pkg.extras       = arg.extras or nil

    -- How can we best try to determine the installation prefix
    -- based on the module location? Then we can either be
    -- provided with the prefix in the modulefile or determine
    -- its position in the heirarchy.
    -- TMP fix
    if isempty(pkg.prefix) then
        pkg.prefix = pathJoin(software_prefix,pkg.name,pkg.version)
    end
    LmodMessage(pkg.mf)

    if groupT[pkg.name] then
	    append_modulepath(pkg.name)
    end

    -- Start looking for common directories
    query_pkg_dirs(pkg)

    -- Start Setting Environment
    -- Set the module family to enable autoswapping
    if not isempty(pkg.family) then
        family(pkg.family)
    end

    -- Set the common environment variables.
    if string.lower(vmode) == "prepend" then
        prepend_vars(pkg)
    else
        append_vars(pkg)
    end

    -- if vmode == nil or string.lower(vmode) == "append" then
    --     append_vars(pkg)
    -- elseif string.lower(vmode) == "prepend" then
    --     prepend_vars(pkg)
    -- end

    -- Set the development variables
    dev_vars(pkg)
    if pkg.compilers then
        comp_vars(pkg)
    end

    -- Process any extras provided
    if pkg.extras then
        extra_vars(pkg)
    end
  
    -- Set the package information 
    pkg_info(pkg)

    return pkg
end

-- Hooks must be registered
hook.register("SiteName",site_hook)
hook.register("avail",avail_hook)

-- Functions used in modules require sandbox registration
sandbox_registration {
    Pkg                = Pkg,
    pkg_init           = pkg_init,
    prepend_modulepath = prepend_modulepath,
    append_modulepath  = append_modulepath,
}
