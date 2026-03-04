function .
    set -l input $argv[1]
    if echo $input | grep -q '^[1-9][0-9]*$'
        set -l levels $input
        for i in (seq $levels)
            cd ..
        end
    else
        echo "Invalid input format. Please use '<number>' to go back a specific number of directories."
    end
end
