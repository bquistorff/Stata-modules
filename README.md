Stata-modules
=============

A collection of small Stata utilities. Minimal documenation for now.

Install
=======

To install to install 'package' whose name begins with letter 'p' you can do the following with Stata v13.

```
. net install <package>, from(https://raw.githubusercontent.com/bquistorff/Stata-modules/<p>/master/) replace
```

For Stata 12 or below (that can't handle the https of github) download as zip, unzip, and then 

```
. net install <package>, from(full_local_path_to_files/<p>/) replace
```


Author
=======
Brian Quistorff - quistorff (at) econ.umd.edu
I welcome and comments (or pull-requests).
