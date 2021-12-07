

# The cfmfame command has a limitation that INPUT doesn't work.
# Also, the maximum string length is 2^20.
# So, we parse the command string for INPUT and substitute the file contents.

function deINPUTcmd(cmd::AbstractString)::String
    pat = r"(?:^|;|\n)[ \t]*input[ \t]+(?<file>file[ \t]*\([ \t]*)?(?<value>.*?)(?(file)\))[ \t]*(?:$|;|\n)"i
    function repl(str::AbstractString)
        m = match(pat, str)
        havefile = m.captures[1] !== nothing
        filename = strip(m.captures[2])
        if havefile && !(startswith(filename, '"') && endswith(filename, '"'))
            error("Cannot handle INPUT FILE() with computed argument $filename. Use EXECUTE instead.")
        end
        if (startswith(filename, '"') && endswith(filename, '"'))
            filename = filename[2:end-1]
        end
        if endswith(filename, '!')
            filename = filename[1:end-1]
        else
            fn, ext = splitext(filename)
            if isempty(ext)
                filename *= ".inp"
            end
        end
        if isfile(filename)
            return '\n' * deINPUTcmd(join(readlines(filename), '\n')) * '\n'
        else
            error("File $filename does not exist.")
        end
    end
    return replace(cmd, pat => repl)
end


function cfmfame(str::AbstractString)
    @cfm_call_check(cfmfame, (Cstring,), str)
    return nothing
end


export fame
function fame(cmd::AbstractString; quiet::Bool=false)
     fn = tempname()
     cfmfame("output file(\"$(fn)!\")")
     cfmfame(deINPUTcmd(cmd))
     cfmfame("output terminal")
     if !quiet
        foreach(println, readlines(fn))
     end
     Base.Filesystem.rm(fn)
     nothing
end


export @fame_str
macro fame_str(cmd, flags...)
    if !isempty(flags) && 'q' ∈ flags[1]
        return :(fame($cmd; quiet=true))
    else
        return :(fame($cmd; quiet=false))
    end
end


