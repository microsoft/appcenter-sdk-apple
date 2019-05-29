on run
    set activeService to first paragraph of (read "active.txt")
    do shell script "./attach.sh " & activeService & " 127.0.0.1 8888 on 127.0.0.1 8888 on" with administrator privileges
end run