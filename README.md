Stata-modules
=============

A collection of small Stata modules utilities dealing with them. The modules include forks of existing modules (from SSC and the mailing list), reimplementations of existing modules, and stuff I've made for myself.

Install
---------------------

To install a module 'package' whose name begins with letter 'p' you can do the following with Stata v13.

```
net install <package>, from(https://raw.github.com/bquistorff/Stata-modules/master/<p>/) replace
```

For Stata 12 or below (that can't handle the https of github) download as zip, unzip, and then 

```
net install <package>, from(full_local_path_to_files/<p>/) replace
```

Bash scripts can just be downloaded.

If you would like to get older version, then you should clone the repository and then use rev-list as noted [here](http://stackoverflow.com/questions/6990484/git-checkout-by-date).

Forks
---------------------
Forks of SSC packages (New named [original name]): latabstat_simple [latabstat], matsave_simple [matsave], outtable_simple [outtable], sutex_env [sutex], synth (in development), usepackage_simple [usepackage], bchardel [chardel]
Forks of base functions/packages: adoupdate (adoupdate), b_file_ops (several), b_var_ops (several), 

Some other packages are taken from the Stata mailing list. 

Note that when overriding an installation for a package with the same name from a new source, -ado uninstall- the previous one

Why not SSC?
---------------------

While I'm not opposed to having modules on BC's SSC for convenience, that archive has several limitations:
* It doesn't allow access to previous versions of files (which is essential for replication). 
* It doesn't facilitate noting bugs or other comments (which reduces errors)
* It doesn't facilitate collaborative editing such as submitting bug fixes or tracking forks (which speeds development).


Author
---------------------
Brian Quistorff - bquistorff (at) gmail (dot) com. I welcome comments (or pull-requests).
