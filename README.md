Stata-modules
=============

A collection of small Stata modules and utilities dealing with them. The modules include forks of existing modules (from SSC and the mailing list), reimplementations of existing modules, and stuff I've made for myself. For a full list, see [pkg_list.txt](pkg_list.txt).

Install
---------------------

To install a module `package` whose name begins with letter `p` you can do the following with Stata >= v13.

```
net install <package>, from(https://raw.github.com/bquistorff/Stata-modules/master/<p>/) replace
```

Note that when overriding an installation for a package with the same name from a new source, `ado uninstall` the previous one.

The whole repo can also be cloned and the base directory added to `$S_ADO`.

Bash scripts can just be downloaded.


Forks
---------------------
Much thanks is given to the original authors of packages that I've forked. 
- Forks of SSC packages (New named [original name]): `latabstat_simple` [`latabstat`], `matsave_simple` [`matsave`], `outtable_simple` [`outtable`], `sutex_env` [`sutex`], `synth` (in development), `usepackage_simple` [`usepackage`], `bchardel` [`chardel`]
- Forks of base functions/packages: `adoupdate` (`adoupdate`), `b_file_ops` (several), `b_var_ops` (several), 
- Some other packages are taken from the Stata mailing list. 


Development
---------------------
When adding new packages, see `file_reqs.txt`. There are checks and utilities in `makefile`. Old to do's in `to do.txt`.

Author
---------------------
Brian Quistorff - bquistorff (at) gmail (dot) com. I welcome comments (or pull-requests). Please use GitHub issues.
