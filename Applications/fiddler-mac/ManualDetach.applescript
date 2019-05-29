on run
    set proxyInfo to read "proxyinfo.conf"
    try
        do shell script "./attach.sh " & proxyInfo with administrator privileges
    on error
        return
    end try
    do shell script "rm proxyinfo.conf"
    do shell script "rm proxyinfo.xml"
    do shell script "rm services.xml"
end run