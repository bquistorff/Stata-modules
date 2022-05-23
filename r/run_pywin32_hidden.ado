program run_pywin32_hidden
    * Deal with weirdness where if cmd sees something with
    loc 0 = strtrim(`"`0'"')
    loc 0_len = strlen(`"`0'"')
    loc 0_rest = substr(`"`0'"', 9, `=`0_len'-9')
    if substr(`"`0'"', 1, 8)==`"cmd /c ""' & substr(`"`0'"', `0_len', 1)==`"""' & strpos(`"`0_rest'"',`"""')>0 {
        loc 0 `"cmd /c ""`0_rest'"""'
    }
    qui findfile run_pywin32_hidden.py
    python script "`r(fn)'", args(`"`0'"')
end
