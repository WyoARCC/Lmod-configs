# -*- lua -*-
propT = {
   state = {
      validT = { experimental = 1, testing = 1, obsolete = 1 },
      displayT = {
         experimental  = { short = "(E)",  long = "(E)",     color = "blue",  doc = "Experimental", },
         testing       = { short = "(T)",  long = "(T)",     color = "green", doc = "Testing", },
         obsolete      = { short = "(O)",  long = "(O)",     color = "red",   doc = "Obsolete", },
      },
   },
   lmod = {
      validT = { sticky = 1 },
      displayT = {
         sticky = { short = "(S)",  long = "(S)",   color = "red",    doc = "Module is Sticky, requires --force to unload or purge",  },
      },
   },
   arch = {
      validT = { mic = 1, offload = 1, gpu = 1, },
      displayT = {
         ["mic:offload"]     = { short = "(*)",  long = "(m,o)",   color = "blue", doc = "built for host, native MIC and offload to the MIC",  },
         ["mic"]             = { short = "(m)",  long = "(m)",     color = "blue", doc = "built for host and native MIC", },
         ["offload"]         = { short = "(o)",  long = "(o)",     color = "blue", doc = "built for offload to the MIC only",},
         ["gpu"]             = { short = "(g)",  long = "(g)",     color = "red" , doc = "built for GPU",},
         ["gpu:mic"]         = { short = "(gm)", long = "(g,m)",   color = "red" , doc = "built natively for MIC and GPU",},
         ["gpu:mic:offload"] = { short = "(@)",  long = "(g,m,o)", color = "red" , doc = "built natively for MIC and GPU and offload to the MIC",},
      },
   },
   status = {
      validT = { active = 1, },
      displayT = {
        active        = { short = "(L)",  long = "(L)",     color = "yellow", doc = "Module is loaded", },
     },
   },

   pkgtype = {
	validT = { dev = 1, script = 1, mpi = 1, viz = 1, io = 1, },
	displayT = {
           ["dev"]     = { short = "(dev)", long = "(dev)",  color = "blue",    doc = "Development Application / Library", },
           ["script"]  = { short = "(sc)",  long = "(sc)",   color = "yellow",  doc = "Scripting Language", },
           ["mpi"]     = { short = "(M)",   long = "(mpi)",  color = "cyan",    doc = "MPI Implementation", },
           ["viz"]     = { short = "(V)",   long = "(viz)",  color = "magenta", doc = "Visualization Package", },
           ["io"]      = { short = "(io)",  long = "(io)",   color = "blue",    doc = "Input/Output Library", },
       },
   },

   scitype = {
       validT = { math = 1, atm = 1, gen = 1, bio = 1, eng = 1, chem = 1, phys = 1, geo = 1 },
       displayT = {
           ["math"]   = { short = "(M)", long = "(math)", color = "blue",    doc = "Math related software", },
           ["atm"]    = { short = "(A)", long = "(atm)",  color = "cyan",    doc = "Atmospheric science software", },
           ["gen"]    = { short = "(G)", long = "(gen)",  color = "red",     doc = "Genomic science related", },
           ["bio"]    = { short = "(B)", long = "(bio)",  color = "green",   doc = "Biology related software", },
           ["eng"]    = { short = "(E)", long = "(eng)",  color = "yellow",  doc = "Engineering related software", },
           ["chem"]   = { short = "(C)", long = "(chem)", color = "magenta", doc = "Chemistry related software", },
           ["phys"]   = { short = "(P)", long = "(phys)", color = "white",   doc = "Physics related software", },
           ["geo"]    = { short = "(G)", long = "(geo)",  color = "yellow",  doc = "Geology / Geophysics related software", },
       },
   },
}
