# Node Version Manager
# Implemented as a fish function
# To use source this file from your fish config
#
# Originally implemented by Tim Caswell <tim@creationix.com>
# with much bash help from Matthew Ranney
# Ported to fish by Alexey Komarov <alex7kom@gmail.com>

# Auto detect the NVM_DIR
if not test -d "$NVM_DIR"
    set NVM_DIR (dirname (status --current-filename))
end

function nvm_has
    type $argv[1] > /dev/null 2>&1
    return $status
end

# Setup mirror location if not already set
if not test -d "$NVM_NODEJS_ORG_MIRROR"
    set NVM_NODEJS_ORG_MIRROR "http://nodejs.org/dist"
end

# Traverse up in directory tree to find containing folder
function nvm_find_up
    set -l path (pwd)
    set -l file $argv[1]
    while begin; test "$path" != ""; and not test -e "$path/$file"; end
        set path (echo "$path" | sed -e 's/\/[^\/]*$//')
    end
    echo "$path"
end

function nvm_find_nvmrc
    set -l dir (nvm_find_up ".nvmrc")
    if test -e "$dir/.nvmrc"
        echo "$dir/.nvmrc"
    end
end

# Obtain nvm version from rc file
function nvm_rc_version
    set -l NVMRC_PATH (nvm_find_nvmrc)
    if test -e "$NVMRC_PATH"
        set NVM_RC_VERSION (cat "$NVMRC_PATH" | head -n 1)
        echo "Found '$NVMRC_PATH' with version <$NVM_RC_VERSION>"
    end
end

# Expand a version using the version cache
function nvm_version
    set -l PATTERN $argv[1]
    # The default version is the current one
    if test -z "$PATTERN"
        set PATTERN 'current'
    end

    set -l VERSION (nvm_ls "$PATTERN" | tail -n1)
    echo $VERSION

    if test "$VERSION" = 'N/A'
        return
    end
    return 0
end

function nvm_remote_version
    set -l PATTERN $argv[1]
    set -l VERSION (nvm_ls_remote "$PATTERN" | tail -n1)
    echo $VERSION

    if test "$VERSION" = 'N/A'
        return
    end
    return 0
end

function nvm_normalize_version
    echo "$argv[1]" | sed -e 's/^v//' | awk -F. '{ printf("%d%03d%03d\n", $1,$2,$3); }'
end

function nvm_format_version
    set -l PATTERN $argv[1]
    echo "$PATTERN" | sed -e 's/^\([0-9]\)/v\1/g'
end

function nvm_binary_available
    # binaries started with node 0.8.6
    set -l MINIMAL "0.8.6"
    set -l VERSION $argv[1]
    test (nvm_normalize_version $VERSION) -ge (nvm_normalize_version $MINIMAL)
    return $status
end

function nvm_ls
    set -l PATTERN $argv[1]
    set -l VERSIONS ''
    set -l GREP_OPTIONS ''

    if test "$PATTERN" = 'current';
        if test (which node 2>/dev/null)
            echo (node -v 2>/dev/null)
        end
        return
    end

    if test -f "$NVM_DIR/alias/$PATTERN"
        nvm_version (cat "$NVM_DIR/alias/$PATTERN")
        return
    end

    # If it looks like an explicit version, don't do anything funny
    if test (echo "$PATTERN" | grep 'v?*.?*.?*')
        set VERSIONS "$PATTERN"
    else
        set -l format (nvm_format_version $PATTERN)
        set VERSIONS (find "$NVM_DIR/" -maxdepth 1 -type d -name "$format*" -exec basename '{}' ';' | sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n | grep -v '^ *\.')
    end

    if test -z "$VERSIONS"
        echo "N/A"
        return
    end
    echo "$VERSIONS" | sed -e 's/ /\
/g'
    return
end

function nvm_ls_remote
    set -l PATTERN $argv[1]
    set -l VERSIONS
    set -l GREP_OPTIONS ''
    if test -n "$PATTERN"
        set PATTERN (nvm_format_version "$PATTERN")
    else
        set PATTERN '.*'
    end

    set VERSIONS (curl -s $NVM_NODEJS_ORG_MIRROR/ \
        | egrep -o 'v[0-9]+\.[0-9]+\.[0-9]+' \
        | grep -w "$PATTERN" \
        | sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n)
    if test -z "$VERSIONS"
        echo 'N/A'
        return
    end
    echo "$VERSIONS" | sed -e 's/ /\
/g'
    return
end

function nvm_checksum
    set -l checksum
    if nvm_has shasum
        set checksum (shasum $argv[1] | awk '{print $1}')
    else if nvm_has sha1
        set checksum (sha1 -q $argv[1])
    else
        set checksum (sha1sum $argv[1] | awk '{print $1}')
    end

    if test "$checksum" = "$argv[2]"
        return
    else if test -z $argv[2]
        echo 'Checksums empty' #missing in raspberry pi binary
        return
    else
        echo 'Checksums do not match.'
        return 1
    end
end

function nvm_print_versions
    set -l VERSIONS $argv
    set -l FORMAT
    set -l CURRENT (nvm_version current)
    for VERSION in $VERSIONS
        if test "$VERSION" = "$CURRENT"
            set FORMAT '\033[0;32m-> %9s\033[0m'
        else if test -d "$NVM_DIR/$VERSION"
            set FORMAT '\033[0;34m%12s\033[0m'
        else
            set FORMAT '%12s'
        end
        printf "$FORMAT\n" $VERSION
    end
end

function nvm
    if test (count $argv) -lt 1
        nvm help
        return 127
    end

    # Try to figure out the os and arch for binary fetching
    set -l uname (uname -a)
    set -l os
    set -l arch (uname -m)
    set -l GREP_OPTIONS ''

    switch $uname
        case 'Linux *'
            set os 'linux'
        case 'Darwin *'
            set os 'darwin'
        case 'SunOS *'
            set os 'sunos'
        case 'FreeBSD *'
            set os 'frebsd'
    end
    switch $uname
        case '*x86_64*'
            set arch 'x64'
        case '*i*86*'
            set arch 'x86'
        case '*armv6l*'
            set arch 'arm-pi'
    end

    # initialize local variables
    set -l VERSION
    set -l ADDITIONAL_PARAMETERS
    set -l ALIAS

    set -l cur 1
    
    switch $argv[$cur]
        case 'help'
            echo
            echo "Node Version Manager"
            echo
            echo "Usage:"
            echo "    nvm help                    Show this message"
            echo "    nvm --version               Print out the latest released version of nvm"
            echo "    nvm install [-s] <version>  Download and install a <version>, [-s] from source. Uses .nvmrc if available"
            echo "    nvm uninstall <version>     Uninstall a version"
            echo "    nvm use <version>           Modify PATH to use <version>. Uses .nvmrc if available"
            echo "    nvm run <version> [<args>]  Run <version> with <args> as arguments. Uses .nvmrc if available for <version>"
            echo "    nvm current                 Display currently activated version"
            echo "    nvm ls                      List installed versions"
            echo "    nvm ls <version>            List versions matching a given description"
            echo "    nvm ls-remote               List remote versions available for install"
            echo "    nvm deactivate              Undo effects of NVM on current shell"
            echo "    nvm alias [<pattern>]       Show all aliases beginning with <pattern>"
            echo "    nvm alias <name> <version>  Set an alias named <name> pointing to <version>"
            echo "    nvm unalias <name>          Deletes the alias named <name>"
            echo "    nvm copy-packages <version> Install global NPM packages contained in <version> to current version"
            echo
            echo "Example:"
            echo "    nvm install v0.10.24        Install a specific version number"
            echo "    nvm use 0.10                Use the latest available v0.10.x release"
            echo "    nvm run 0.10.24 myApp.js    Run myApp.js using node v0.10.23"
            echo "    nvm alias default 0.10.24   Set default node version on a shell"
            echo
            echo "Note:"
            echo "    to remove, delete or uninstall nvm - just remove ~/.nvm-fish, ~/.npm and ~/.bower folders"
            echo

        case 'install'
            set -l binavail
            set -l t
            set -l url
            set -l sum
            set -l tarball
            set -l nobinary
            set -l version_not_provided 0
            set -l provided_version

            if not nvm_has curl
                echo 'NVM Needs curl to proceed.' >&2
                return 1
            end


            if test (count $argv) -lt 2
                set version_not_provided 1
                nvm_rc_version
                if test -z "$NVM_RC_VERSION"
                    nvm help
                    return 127
                end
            end

            set cur (math $cur + 1)
            set nobinary 0

            if test $argv[$cur] = '-s'
                set nobinary 1
                set cur (math $cur + 1)
            end

            if test $os = 'freebsd'
                set nobinary 1
            end

            set provided_version $argv[$cur]
            if test -z "$provided_version"
                if test $version_not_provided -ne 1 
                    nvm_rc_version
                end
                set provided_version "$NVM_RC_VERSION"
            end
            if test -d $NVM_DIR/$provided_version
                echo $provided_version is already installed.
                return
            end

            set VERSION (nvm_remote_version $provided_version)
            set ADDITIONAL_PARAMETERS ''

            set cur (math $cur + 1)

            while test $cur -lt (math (count $argv) + 1)
                set ADDITIONAL_PARAMETERS $ADDITIONAL_PARAMETERS $argv[$cur]
                set cur (math $cur + 1)
            end

            if test -d $NVM_DIR/$VERSION
                echo $VERSION is already installed.
                nvm use "$VERSION"
                return $status
            end

            if test "$VERSION" = "N/A"
                echo "Version '$provided_version' not found - try `nvm ls-remote` to browse available versions."
                return 3
            end

            # skip binary install if no binary option specified.
            if test $nobinary -ne 1
                # shortcut - try the binary if possible.
                if test -n $os
                    if nvm_binary_available "$VERSION"
                        set -l t $VERSION-$os-$arch
                        set -l url $NVM_NODEJS_ORG_MIRROR/$VERSION/node-$t.tar.gz
                        set -l sum (curl -s $NVM_NODEJS_ORG_MIRROR/$VERSION/SHASUMS.txt | grep node-$t.tar.gz | awk '{print $1}')
                        set -l tmpdir $NVM_DIR/bin/node-$t
                        set -l tmptarball $tmpdir/node-$t.tar.gz
                        mkdir -p "$tmpdir"; and \
                            curl -L -C - --progress-bar $url -o "$tmptarball"; and \
                            nvm_checksum "$tmptarball" $sum; and \
                            tar -xzf "$tmptarball" -C $tmpdir --strip-components 1; and \
                            rm -f "$tmptarball"; and \
                            mv "$tmpdir" "$NVM_DIR/$VERSION"
                        if test $status = 0
                            nvm use $VERSION
                            return
                        else
                            echo "Binary download failed, trying source." >&2
                            rm -rf "$tmptarball" "$tmpdir"
                        end
                    end
                end
            end

            echo Additional options while compiling: $ADDITIONAL_PARAMETERS

            set -l tarball ''
            set -l sum ''

            set -l make make
            set -l MAKE_CXX
            if test $os = "freebsd"
                set make gmake
                set MAKE_CXX "CXX=c++"
            end
            
            set -l tmpdir $NVM_DIR/src
            set -l tmptarball $tmpdir/node-$VERSION.tar.gz

            if test -z (curl -Is "$NVM_NODEJS_ORG_MIRROR/$VERSION/node-$VERSION.tar.gz" | grep '404 Not Found')
                set tarball $NVM_NODEJS_ORG_MIRROR/$VERSION/node-$VERSION.tar.gz
                set sum (curl -s $NVM_NODEJS_ORG_MIRROR/$VERSION/SHASUMS.txt | grep node-$VERSION.tar.gz | awk '{print $1}')
            else if test -z (curl -Is "$NVM_NODEJS_ORG_MIRROR/node-$VERSION.tar.gz" | grep '404 Not Found')
                set tarball $NVM_NODEJS_ORG_MIRROR/node-$VERSION.tar.gz
            end
            
            test -n "$tarball" ; and \
            mkdir -p "$tmpdir" ; and \
            curl -L --progress-bar $tarball -o "$tmptarball"; and \
            nvm_checksum "$tmptarball" $sum; and \
            tar -xzf "$tmptarball" -C "$tmpdir" ; and \
            cd "$tmpdir/node-$VERSION" ; and \
            ./configure --prefix="$NVM_DIR/$VERSION" $ADDITIONAL_PARAMETERS ; and \
            eval $make $MAKE_CXX; and \
            rm -f "$NVM_DIR/$VERSION" 2>/dev/null ; and \
            eval $make $MAKE_CXX install
            if test $status = 0
                nvm use $VERSION
                if not nvm_has npm
                    echo "Installing npm..."
                    if test (echo $VERSION | egrep 'v0\.1\.')
                        echo "npm requires node v0.2.3 or higher"
                    else if test (echo $VERSION | egrep '^v0\.2\.')
                        if test (echo $VERSION | egrep '^v0\.2\.[0-2]$')
                            echo "npm requires node v0.2.3 or higher"
                        else
                            set -x clean yes
                            set -x npm_install 0.2.19
                            curl https://npmjs.org/install.sh | sh
                        end
                    else
                        set -x clean yes
                        curl https://npmjs.org/install.sh | sh
                    end
                end
            else
                echo "nvm: install $VERSION failed!" >&2
                return 1
            end
        case 'uninstall'
            test (count $argv) -ne 2; and nvm help; and return 127
            set -l PATTERN (nvm_format_version $argv[2])
            if test $PATTERN = (nvm_version)
                echo "nvm: Cannot uninstall currently-active node version, $PATTERN."
                return 1
            end

            set -l VERSION (nvm_version $PATTERN)
            if not test -d "$NVM_DIR/$VERSION"
                echo "$VERSION version is not installed..."
                return
            end

            set -l t "$VERSION-$os-$arch"

            # Delete all files related to target version.
            rm -rf "$NVM_DIR/src/node-$VERSION" \
                "$NVM_DIR/src/node-$VERSION.tar.gz" \
                "$NVM_DIR/bin/node-$t" \
                "$NVM_DIR/bin/node-$t.tar.gz" \
                "$NVM_DIR/$VERSION" 2>/dev/null

            echo "Uninstalled node $VERSION"

            for ALIAS in (grep -l $VERSION $NVM_DIR/alias/* 2>/dev/null)
                nvm unalias (basename $ALIAS)
            end
        case 'deactivate'
            if not test -z (echo $PATH | grep "$NVM_DIR/[^\/]*/bin")
                set -l ncur 1
                while test $ncur -lt (math (count $PATH) + 1)
                    if not test -z (echo $PATH[$ncur] | grep "$NVM_DIR/[^\/]*/bin")
                        set -e PATH[$ncur]
                        break
                    end
                    set ncur (math $ncur + 1)
                end
                echo "$NVM_DIR/*/bin removed from \$PATH"
            else
                echo "Could not find $NVM_DIR/*/bin in \$PATH"
            end
            if not test -z (echo $MANPATH | grep "$NVM_DIR/[^\/]*/share/man")
                set -l ncur 1
                while test $ncur -lt (math (count $MANPATH) + 1)
                    if not test -z (echo $MANPATH[$ncur] | grep "$NVM_DIR/[^\/]*/share/man")
                        set -e MANPATH[$ncur]
                        break
                    end
                    set ncur (math $ncur + 1)
                end
                echo "$NVM_DIR/*/share/man removed from \$MANPATH"
            else
                echo "Could not find $NVM_DIR/*/share/man in \$MANPATH"
            end
            if not test -z (echo $NODE_PATH | grep "$NVM_DIR/[^\/]*/lib/node_modules")
                set -l ncur 1
                while test $ncur -lt (math (count $NODE_PATH) + 1)
                    if not test -z (echo $NODE_PATH[$ncur] | grep "$NVM_DIR/[^\/]*/lib/node_modules")
                        set -e NODE_PATH[$ncur]
                        break
                    end
                    set ncur (math $ncur + 1)
                end
                echo "$NVM_DIR/*/lib/node_modules removed from \$NODE_PATH"
            else
                echo "Could not find $NVM_DIR/*/lib/node_modules in \$NODE_PATH"
            end
        case 'use'
            set -l VERSION
            if test (count $argv) -eq 1
                nvm_rc_version
                if test -n $NVM_RC_VERSION
                    set VERSION (nvm_version $NVM_RC_VERSION)
                end
            else
                set VERSION (nvm_version $argv[2])
            end
            if test -z $VERSION
                nvm help
                return 127
            end
            if not test -d "$NVM_DIR/$VERSION"
                echo "$VERSION version is not installed yet"
                return 1
            end

            set -l ncur 1
            while test $ncur -lt (math (count $PATH) + 1)
                if not test -z (echo $PATH[$ncur] | grep "$NVM_DIR/[^\/]*/bin")
                    set -e PATH[$ncur]
                    break
                end
                set ncur (math $ncur + 1)
            end
            set -g -x PATH $NVM_DIR/$VERSION/bin $PATH

            set -l ncur 1
            while test $ncur -lt (math (count $MANPATH) + 1)
                if not test -z (echo $MANPATH[$ncur] | grep "$NVM_DIR/[^\/]*/share/man")
                    set -e MANPATH[$ncur]
                    break
                end
                set ncur (math $ncur + 1)
            end
            set -g -x MANPATH $NVM_DIR/$VERSION/share/man:$MANPATH

            set -l ncur 1
            while test $ncur -lt (math (count $NODE_PATH) + 1)
                if not test -z (echo $NODE_PATH[$ncur] | grep "$NVM_DIR/[^\/]*/lib/node_modules")
                    set -e NODE_PATH[$ncur]
                    break
                end
                set ncur (math $ncur + 1)
            end
            set -g -x NODE_PATH $NVM_DIR/$VERSION/lib/node_modules $NODE_PATH

            set -g -x NVM_PATH "$NVM_DIR/$VERSION/lib/node"
            set -g -x NVM_BIN "$NVM_DIR/$VERSION/bin"
            echo "Now using node $VERSION"
        case 'run'
            set -l provided_version
            set -l has_checked_nvmrc 0
            # run given version of node
            if test (count $argv) -lt 2
                nvm_rc_version; and set has_checked_nvmrc 1
                if test -n "$NVM_RC_VERSION"
                    set VERSION (nvm_version $NVM_RC_VERSION)
                else
                    set VERSION 'N/A'
                end
                if test "$VERSION" = "N/A"
                    nvm help
                    return 127
                end
            end

            set provided_version $argv[2]
            if test -n "$provided_version"
                set VERSION (nvm_version $provided_version)
                if test "$VERSION" = "N/A"
                    set provided_version ''
                    if test $has_checked_nvmrc -ne 1
                        nvm_rc_version; and set has_checked_nvmrc 1
                    end
                    set VERSION (nvm_version $NVM_RC_VERSION)
                else
                    set cur (math $cur + 1)
                end
            end

            if not test -d "$NVM_DIR/$VERSION"
                echo "$VERSION version is not installed yet"
                return
            end

            set -l PREVIOUS_NODE_PATH $NODE_PATH
            set -l ncur 1
            while test $ncur -lt (math (count $NODE_PATH) + 1)
                if not test -z (echo $NODE_PATH[$ncur] | grep "$NVM_DIR/[^\/]*/lib/node_modules")
                    set -e NODE_PATH[$ncur]
                    break
                end
                set ncur (math $ncur + 1)
            end
            set -g -x NODE_PATH $NVM_DIR/$VERSION/lib/node_modules:$NODE_PATH

            echo "Running node $VERSION"
            set -l argv_count (count $argv)
            set cur (math $cur + 1)
            if test $argv_count -ge $cur
                eval $NVM_DIR/$VERSION/bin/node $argv[$cur..$argv_count]
            else
                eval $NVM_DIR/$VERSION/bin/node
            end
            set -g -x NODE_PATH $PREVIOUS_NODE_PATH
        case 'ls' 'list'
            if test (count $argv) -eq 1
                nvm_print_versions (nvm_ls)
                nvm alias
            else
                nvm_print_versions (nvm_ls $argv[2])
            end
            return
        case 'ls-remote' 'list-remote'
            if test (count $argv) -eq 1
                nvm_print_versions (nvm_ls_remote)
            else
                nvm_print_versions (nvm_ls_remote $argv[2])
            end
            return
        case 'current'
            nvm_version current
        case 'alias'
            mkdir -p "$NVM_DIR/alias"
            if test (count $argv) -le 2
                if test (count $argv) -eq 2
                    set -l ARG $argv[2]
                else
                    set -l ARG ''
                end

                for ALIAS in (find "$NVM_DIR/alias" -maxdepth 1 -type f -name "$ARG"\*)
                    set -l DEST (cat $ALIAS)
                    set -l VERSION (nvm_version $DEST)
                    set -l ALIAS_BASE (basename $ALIAS)
                    if test "$DEST" = "$VERSION"
                        echo "$ALIAS_BASE -> $DEST"
                    else
                        echo "$ALIAS_BASE -> $DEST (-> $VERSION)"
                    end
                end
                return 0
            end
            if test "$argv[3]" = ""
                rm -f "$NVM_DIR/alias/$argv[2]"
                echo "$argv[2] -> *poof*"
                return
            end

            set -l VERSION (nvm_version $argv[3])
            if test $status != 0
                echo "! WARNING: Version '$argv[3]' does not exist." >&2
            end
            echo $argv[3] > "$NVM_DIR/alias/$argv[2]"
            if not test "$argv[3]" = $VERSION
                echo "$argv[2] -> $argv[3] (-> $VERSION)"
            else
                echo "$argv[2] -> $argv[3]"
            end
        case 'unalias'
            mkdir -p "$NVM_DIR/alias"
            test (count $argv) -ne 2; and nvm help; and return 127
            not test -f "$NVM_DIR/alias/$argv[2]"; and echo "Alias $argv[2] doesn't exist!"; and return
            rm -f "$NVM_DIR/alias/$argv[2]"
            echo "Deleted alias $argv[2]"
        case 'copy-packages'
            test (count $argv) -ne 2; and nvm help; and return 127
            set -l CURVER (nvm_version)
            set -l VERSION (nvm_version $argv[2])
            nvm use $VERSION >/dev/null
            set -l ROOT (npm -g root)
            set -l ROOTDEPTH (math (echo $ROOT | sed 's/[^\/]//g'|wc -m) + 1)
            set -l INSTALLS (npm -g -p ll | grep "$ROOT\/[^\/]\+\$" | cut -d '/' -f $ROOTDEPTH | cut -d ":" -f 2 | grep -v npm | tr "\n" " ")
            nvm use $CURVER > /dev/null; and eval "npm install -g $INSTALLS"
        case 'clear-cache'
            rm -f "$NVM_DIR/v"* 2>/dev/null
            echo "Cache cleared."
        case 'version'
            if test (count $argv) -lt 2
                nvm_version
            else
                nvm_version $argv[2]
            end
        case '--version'
            echo "nvm v0.7.0"
        case '*'
            nvm help
    end
end

nvm ls default >/dev/null; and nvm use default >/dev/null; or true