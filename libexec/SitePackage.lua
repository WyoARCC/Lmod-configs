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
software_prefix = "/opt/sw"
help_email = "arcc-help@uwyo.edu"

-- Fancy names on group headers
local mapT = {
    grouped = {
        ["/opt/sw/lmod/lmod/modulefiles/Core"]    = "Core Modules",
        ["/opt/sw/lmod/lmod/modulefiles/openmpi"] = "OpenMPI Dependent",
    },
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

function query_lib_dir(pkg)
    local tbl = {"lib","lib64"}
    local libdir = ""
    for k,v in ipairs(tbl) do
        libdir = pathJoin(pkg.prefix,v)
    	if isDir(libdir) then
            pkg.libdir = libdir
            break
        end
    end
end

function query_inc_dir(pkg)
    local incdir = pathJoin(pkg.prefix,"include")
    if isDir(incdir) then
        pkg.incdir = incdir
    end
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
    prepend_path("PATH",pkg.bindir)
    if not isempty(pkg.libdir) and not pkg.ignore_lib then
        prepend_path("LD_LIBRARY_PATH",pkg.libdir)
    end
    prepend_path("MANPATH",pathJoin(pkg.prefix,"share","man"))
end

function append_vars(pkg)
    append_path("PATH",pkg.bindir)
    if not isempty(pkg.libdir) and not pkg.ignore_lib then
        append_path("LD_LIBRARY_PATH",pkg.libdir)
    end
    append_path("MANPATH",pathJoin(pkg.prefix,"share","man"))
end

function dev_vars(pkg)

    setenv(string.upper(pkg.name).."_ROOT",pkg.prefix)
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
    pkg.bindir       = pathJoin(pkg.prefix,"bin")
    pkg.incdir       = ""
    pkg.libdir       = ""
    query_pkg_dir(pkg)
    query_lib_dir(pkg)
    query_inc_dir(pkg)

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
