# Poster-style collage of a movie, season or show: collage [PATH] [options]

function collage --description 'Collage of frames from a movie file, season folder or show folder (default: current folder)'
    if test (count $argv) -eq 0
        set argv .
    else if string match -q -- '-*' $argv[1]
        set argv . $argv
    end
    mpv-collage $argv
end
