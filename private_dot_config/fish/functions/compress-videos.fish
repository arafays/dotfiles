function compress-videos --description "Compress all videos in folder using GPU (H.265 VAAPI)"
    set dir "."
    set quality 18
    set preset fast

    for arg in $argv
        switch "$arg"
            case -h --help
                echo "Usage: compress-videos [DIR] [-q QUALITY] [-p PRESET]"
                echo ""
                echo "Options:"
                echo "  DIR           Folder to scan (default: .)"
                echo "  -q QUALITY    H.265 quality 0-51, lower=better (default: 18)"
                echo "  -p PRESET     VAAPI preset: veryfast, fast, medium, slow (default: fast)"
                echo "  -h, --help    Show this help"
                echo ""
                echo "Examples:"
                echo "  compress-videos"
                echo "  compress-videos ~/Videos -q 20"
                return
            case -q
                set quality $argv[(math (contains -i -- $arg $argv) + 1)]
            case -p
                set preset $argv[(math (contains -i -- $arg $argv) + 1)]
            case '*'
                set dir $arg
        end
    end

    QUALITY=$quality PRESET=$preset ~/scripts/compress_videos.sh "$dir"
end
