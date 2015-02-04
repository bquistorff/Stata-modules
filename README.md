Stata-modules
=============

A collection of small Stata modules utilities dealing with them. The modules include forks of existing modules: latabstat-simple, matrixsort, outtable-simple, sutex-env, usepackage_simple, synth (allows returning precise weights and speeds up small runs). There are also ones pulled from the Stata list, and new ones.

Install
=======

To install a module 'package' whose name begins with letter 'p' you can do the following with Stata v13.

```
. net install <package>, from(https://raw.github.com/bquistorff/Stata-modules/master/<p>/) replace
```

For Stata 12 or below (that can't handle the https of github) download as zip, unzip, and then 

```
. net install <package>, from(full_local_path_to_files/<p>/) replace
```

Bash scripts can just be downloaded.

Forks of SSC packages
---------------------
Same named (when overriding an installation for a package from a new source, -ado uninstall- the previous one): ivreg2out, matsave

New named (original name): latabstat_simple (latabstat), outtable_simple (outtable), sutex_env (sutex), usepackage_simple (usepackage)

Why not SSC?
=======

While I'm not opposed to having modules on BC's SSC for convenience, that archive has several limitations:
* It doesn't allow access to previous versions of files (which is essential for replication). 
* It doesn't facilitate noting bugs or other comments (which reduces errors)
* It doesn't facilitate collaborative editing such as submitting bug fixes or tracking forks (which speeds development).


Author
=======
Brian Quistorff - quistorff (at) econ.umd.edu
I welcome comments (or pull-requests).
