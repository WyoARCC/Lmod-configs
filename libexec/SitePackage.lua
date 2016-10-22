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
local mapT = {
    grouped = {
        ["/opt/sw/lmod/lmod/modulefiles/Core"]    = "Core Modules",
        ["/opt/sw/lmod/lmod/modulefiles/openmpi"] = "OpenMPI Dependent",
    },
}

local libT = {"lib","lib64"}

local pyT = {
    ["2.6"] = "python2.6",
    ["2.7"] = "python2.7",
    ["3.4"] = "python3.4",
    ["3.5"] = "python3.5",
}

function site_prefix()
    return "/opt/sw"
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

function isempty(s)
    return s == nil or s == ''
end

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

function query_pkg_dir(pkg)
    if not isDir(pkg.prefix) then
        LmodError("\n"..pkg.name.."/"..pkg.version.." does not exist."
                  .."\nPlease inform the system administrator - "
                  ..help_email.."\n")
    end
end

function query_bin_dir(pkg)
    if isempty(pkg.bindir) then
        local bindir = pathJoin(pkg.prefix,"bin")
        if isDir(bindir) then
            pkg.bindir = bindir
        end
    end
end

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

function query_inc_dir(pkg)
    if isempty(pkg.incdir) then
        local incdir = pathJoin(pkg.prefix,"include")
        if isDir(incdir) then
            pkg.incdir = incdir
        end
    end
end

function query_pkgconfig_dir(pkg)
    local pkgconfig = pathJoin(pkg.libdir,"pkgconfig")
    if isDir(pkgconfig) then
        pkg.pkgconfig = pkgconfig
    end
end

function query_cmake_dir(pkg)
    local cmake = pathJoin(pkg.libdir,"cmake")
    if isDir(cmake) then
        pkg.cmake = cmake
    end
end

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

--
-- Module available functions
--
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
        end

        if not isempty(pkg.python) and "python" ~= pkg.family then
            prepend_path("PYTHONPATH",pkg.python)
        end

        if not isempty(pkg.perl5) and "perl" ~= pkg.family then
            prepend_path("PERL5LIB",pkg.perl5)
        end
    end
    prepend_path("MANPATH",pathJoin(pkg.prefix,"share","man"))
end

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
        end

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

function pkg_init(arg)
    local mode = arg.mode

    local pkg = {}
    local status
    local msg
    
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

    pkg.prefix       = pathJoin(software_prefix,pkg.name,pkg.version)
    pkg.bindir       = arg.bindir or "" 
    pkg.incdir       = arg.incdir or ""
    pkg.libdir       = arg.libdir or ""
    pkg.pkgconfig    = arg.pkgconfig or ""
    pkg.cmake        = arg.cmake or ""
    pkg.python       = arg.python or ""
    pkg.perl5        = arg.perl5 or ""

    -- Can the ^query lines below be combined well?
    query_pkg_dirs(pkg)


    -- Start Setting Environment
    if not isempty(pkg.family) then
        family(pkg.family)
    end

    dev_vars(pkg)

    if mode == nil or string.lower(mode) == "append" then
        append_vars(pkg)
    elseif string.lower(mode) == "prepend" then
        prepend_vars(pkg)
    end

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
